#!/usr/bin/env sh

set -e

DIR="$(dirname "$(realpath "$0")")"
if [ -z "$GITHUB_REGISTRY_PAT" ]; then
    echo "GITHUB_REGISTRY_PAT environment variable is not set. Please set it to a valid GitHub Personal Access Token with permissions to read packages from ghcr.io."
    exit 1
fi

if [ -z "$DOCKER_REGISTRY_PAT" ]; then
    echo "DOCKER_REGISTRY_PAT environment variable is not set. Please set it to a valid Docker Personal Access Token with permissions to read packages from docker.io."
    exit 1
fi

NAME="${NAME:-authentik}"

if [ "$(kind get clusters | grep -c "$NAME")" -gt 0 ]; then
	echo "Deleting cluster $NAME ..."
	kind delete cluster --name "$NAME" || true
fi

kind create cluster --name "$NAME" --config "$DIR/cluster.yaml"

echo -e "\033[32m Cluster $NAME created successfully! \033[0m"
kubectl config use-context "kind-$NAME"

echo "Creating temporary docker client config directory ..."
DOCKER_CONFIG="$(mktemp -d)"
export DOCKER_CONFIG
trap 'echo "Removing ${DOCKER_CONFIG}/*" && rm -rf ${DOCKER_CONFIG:?}' EXIT

echo "Creating a temporary config.json"
cat <<EOF >"${DOCKER_CONFIG}/config.json"
{
 "auths": { "gcr.io": {} }
}
EOF

echo "Login to docker.io ..."
echo "$DOCKER_REGISTRY_PAT" | docker login -u smartcoder --password-stdin
echo "Login to gcr.io ..."
echo "$GITHUB_REGISTRY_PAT" | docker login ghcr.io -u skynet-core --password-stdin
echo "Moving credentials to kind cluster name='${NAME}' nodes ..."
for node in $(kind get nodes --name "${NAME}"); do
  # the -oname format is kind/name (so node/name) we just want name
  node_name=${node#node/}
  # copy the config to where kubelet will look
  docker cp "${DOCKER_CONFIG}/config.json" "${node_name}:/var/lib/kubelet/config.json"
  # restart kubelet to pick up the config
  docker exec "${node_name}" systemctl restart kubelet.service
done

echo "Done!"
