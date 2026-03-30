#!/usr/bin/env sh

find . -type f -maxdepth 1 -iname "*.env" -print | sort | while read -r env_file; do
    . "$env_file"
done

if [ -z "$SSH_USER" ] || [ -z "$PUBLIC_HOST" ] || [ -z "$LOCAL_HTTP_PORT" ] || [ -z "$LOCAL_HTTPS_PORT" ]; then
    echo "Error: Missing required environment variables. Please ensure SSH_USER, PUBLIC_HOST, LOCAL_HTTP_PORT, and LOCAL_HTTPS_PORT are set."
    exit 1
fi

printf "Forwarding local ports %d (HTTP) and %d (HTTPS) to %s@%s...\n" "$LOCAL_HTTP_PORT" "$LOCAL_HTTPS_PORT" "$SSH_USER" "$PUBLIC_HOST"
ssh -T -R 80:127.0.0.1:$LOCAL_HTTP_PORT \
    -R 443:127.0.0.1:$LOCAL_HTTPS_PORT \
        $SSH_USER@$PUBLIC_HOST
