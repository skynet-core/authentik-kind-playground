#!/usr/bin/env sh

set -e

DIR="$(dirname "$(realpath "$0")")"

mkdir -p "$DIR/tls" || true
keys="$DIR/tls"
# ISSUE: cert-manager requires Gateway API to be installed,
# from other side we need to have self signed certificate to get websecure listener enabled
if [ ! -f "$keys/private.pem" ] || [ ! -f "$keys/public.pem" ]; then
    echo -e "\033[32m Generating self-signed certificate for Traefik... \033[0m"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    	-keyout "$keys/private.pem" -out "$keys/public.pem" \
    	-subj "/CN=*.tradingpulse.ai"
fi
kubectl create secret tls authentik-tls \
	--cert="$keys/public.pem" --key="$keys/private.pem"

echo -e "\033[32m Deploying Traefik CRD ... \033[0m"
kubectl apply -f "$DIR/crds.yaml"

echo -e "\033[32m Deploying ServiceAccount, ClusterRole and ClusterRoleBinding for Traefik ... \033[0m"
kubectl apply -f "$DIR/rbac.yaml"

echo -e "\033[32m Persistent volume... \033[0m"
kubectl apply -f "$DIR/pvc.yaml"

echo -e "\033[32m Deploying Traefik Service... \033[0m"
kubectl apply -f "$DIR/svc.yaml"

echo -e "\033[32m Deploying Traefik Gateway... \033[0m"
kubectl apply -f "$DIR/gateway.yaml"

echo -e "\033[32m Deploying Traefik... \033[0m"
kubectl apply -f "$DIR/deployment.yaml"

kubectl wait --timeout=5m -n default \
	deployment.apps/traefik --for=condition=Available

printf "\033[32m #1 Generate Dashboard secret ... \033[0m\n"
AUTH_SECRET="$(openssl rand 10 | base32 -w 0)"
echo "$AUTH_SECRET" > "$DIR/dashboard-auth.secret"
kubectl create secret generic dashboard-auth-secret \
  --namespace default \
  --type=kubernetes.io/basic-auth \
  --from-literal=password="$AUTH_SECRET" \
  --from-literal=username=admin

echo -e "\033[32m Deploying Traefik Dashboard... \033[0m"
kubectl apply -f "$DIR/dashboard.yaml"
