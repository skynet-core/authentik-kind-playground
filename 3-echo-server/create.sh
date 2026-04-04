#!/usr/bin/env sh

set -e

DIR="$(dirname "$(realpath "$0")")"

printf "\033[32m #1 Deploying Postgresql ... \033[0m\n"
kubectl apply -f "$DIR/echo-server-deployment.yaml"

kubectl wait --timeout=5m -n default \
	deployment.apps/echo-server --for=condition=Available

printf "\033[32m #2 Echo-server Service  ... \033[0m\n"
kubectl apply -f "$DIR/echo-server-svc.yaml"

printf "\033[32m #3 Deploy Public Route ... \033[0m\n"
kubectl apply -f "$DIR/public-route.yaml"

printf "\033[32m #4 Deploy Private Route ... \033[0m\n"
kubectl apply -f "$DIR/private-route.yaml"

printf "\033[32m #5 Deploy Paid Route ... \033[0m\n"
kubectl apply -f "$DIR/paid-route.yaml"

printf "\033[32m #6 Deploy Home Route ... \033[0m\n"
kubectl apply -f "$DIR/home-route.yaml"
