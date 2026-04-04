# Authentik + Traefik

## Prerequisites

1. Docker CE installed on your machine.
2. Kind (Kubernetes IN Docker) installed on your machine.
3. Remote VPS with public IP address and SSH access.
4. Domain name pointing to your VPS's public IP address.

## Configuration

Clone the repository:

```bash
git clone https://github.com/skynet-core/authentik-kind-playground
cd authentik-kind-playground
```

Create .env file with the following content:

```bash
# .env
GITHUB_REGISTRY_PAT="<YOUR_GITHUB_PAT>"
DOCKER_REGISTRY_PAT="<YOUR_DOCKER_PAT>"
PUBLIC_HOST="<YOUR_PUBLIC_HOST_IP_OR_DOMAIN>"
SSH_USER="<YOUR_SSH_USERNAME>"
LOCAL_HTTP_PORT="<YOUR_LOCAL_HTTP_PORT>"
LOCAL_HTTPS_PORT="<YOUR_LOCAL_HTTPS_PORT>"
```

Run cluster

```bash
./run.sh
```
