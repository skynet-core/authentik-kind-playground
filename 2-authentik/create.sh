#!/usr/bin/env sh

set -e

DIR="$(dirname "$(realpath "$0")")"

printf "\033[32m #1 Deploying RBACs ... \033[0m\n"
kubectl apply -f "$DIR/rbac.yaml"

printf "\033[32m Create postgres Configmap ... \033[0m\n"
POSTGRES_USER="authentik"
POSTGRES_DB="authentik"
kubectl create configmap postgresql-envs \
  --namespace default \
  --from-literal=POSTGRES_USER="$POSTGRES_USER" \
  --from-literal=POSTGRES_DB="$POSTGRES_DB" \
  --dry-run=client -o yaml > "$DIR/postgresql-envs-configmap.yaml"

kubectl apply -f "$DIR/postgresql-envs-configmap.yaml"
kubectl apply -f "$DIR/postgresql-configmap.yaml"

printf "\033[32m #1 Generate Postgresql password ... \033[0m\n"
POSTGRES_PASSWORD="$(openssl rand 20 | base32 -w 0)"
echo "$POSTGRES_PASSWORD" > "$DIR/postgres.secret"
kubectl create secret generic postgresql-password \
  --namespace default \
  --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD"

printf "\033[32m #2 Deploying Postgresql ... \033[0m\n"
kubectl apply -f "$DIR/postgresql-deployment.yaml"

kubectl wait --timeout=5m -n default \
 	deployment.apps/authentik-postgresql --for=condition=Available

printf "\033[32m #2 Deploying Postgresql Service ... \033[0m\n"
kubectl apply -f "$DIR/postgresql-svc.yaml"

echo -e "\033[32m Deploying CORS middlewares ... \033[0m"
kubectl apply -f "$DIR/middleware.yaml"

echo -e "\033[32m Deploying Authentik Common Config ... \033[0m"
kubectl apply -f "$DIR/authentik-common-configmap.yaml"

printf "\033[32m #1 Generate Authentik secrets ... \033[0m\n"
# NOTE: must be more the 50 chars
SECRET_KEY="$(openssl rand 40 | base32 -w 0)"
ADMIN_PASSWORD="$(openssl rand 20 | base32 -w 0)"
ADMIN_TOKEN="$(openssl rand 30 | base32 -w 0)"
echo "$SECRET_KEY" > "$DIR/authentik-secret-key.secret"
echo "$ADMIN_PASSWORD" > "$DIR/authentik-admin-password.secret"
echo "$ADMIN_TOKEN" > "$DIR/authentik-admin-token.secret"
kubectl create secret generic authentik-password \
  --namespace default \
  --from-literal=AUTHENTIK_BOOTSTRAP_PASSWORD="$ADMIN_PASSWORD" \
  --from-literal=AUTHENTIK_BOOTSTRAP_TOKEN="$ADMIN_TOKEN" \
  --from-literal=AUTHENTIK_SECRET_KEY="$SECRET_KEY" \
  --from-literal=AUTHENTIK_BOOTSTRAP_EMAIL="skynet.vasyl@gmail.com" \
  --from-literal=AUTHENTIK_POSTGRESQL__PASSWORD="$POSTGRES_PASSWORD"

printf "\033[32m Create Authentik configmap ... \033[0m\n"
kubectl create configmap authentik-postgresql-envs \
  --namespace default \
  --from-literal=AUTHENTIK_POSTGRESQL__HOST="authentik-postgresql" \
  --from-literal=AUTHENTIK_POSTGRESQL__NAME="$POSTGRES_DB" \
  --from-literal=AUTHENTIK_POSTGRESQL__PORT="5432" \
  --from-literal=AUTHENTIK_POSTGRESQL__USER="$POSTGRES_USER" \
  --dry-run=client -o yaml > "$DIR/authentik-postgresql-envs-configmap.yaml"
kubectl apply -f "$DIR/authentik-postgresql-envs-configmap.yaml"

printf "\033[32m #2 Deploying Authentik Service ... \033[0m\n"
kubectl apply -f "$DIR/authentik-svc.yaml"

printf "\033[32m #2 Deploying Authentik Server ... \033[0m\n"
kubectl apply -f "$DIR/authentik-server-deployment.yaml"

kubectl wait --timeout=5m -n default \
 	deployment.apps/authentik-server --for=condition=Available

printf "\033[32m #2 Deploying Authentik Worker ... \033[0m\n"
kubectl apply -f "$DIR/authentik-worker-deployment.yaml"

kubectl wait --timeout=5m -n default \
 	deployment.apps/authentik-worker --for=condition=Available

printf "\033[32m #2 Deploying Authentik Ingress ... \033[0m\n"
kubectl apply -f "$DIR/authentik-ingress.yaml"
