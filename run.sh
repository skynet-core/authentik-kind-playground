#!/usr/bin/env sh

set -e

DIR="$(dirname "$(realpath "$0")")"

for env_file in $(find . -maxdepth 1 -type f -iname "*.env" -print | sort); do
	set -a
	# shellcheck disable=SC1090
	. "$env_file"
	set +a
done

if [ -z "$SSH_USER" ] || [ -z "$PUBLIC_HOST" ] || [ -z "$LOCAL_HTTP_PORT" ] || [ -z "$LOCAL_HTTPS_PORT" ]; then
	echo "Error: Missing required environment variables. Please ensure SSH_USER, PUBLIC_HOST, LOCAL_HTTP_PORT, and LOCAL_HTTPS_PORT are set."
	exit 1
fi

# make sure connection is possible before send it to background
eval "$(ssh-agent -s)"
ssh -o AddKeysToAgent=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
	"$SSH_USER"@"$PUBLIC_HOST" "exit 0"

printf "Forwarding local ports %d (HTTP) and %d (HTTPS) to %s@%s...\n" "$LOCAL_HTTP_PORT" "$LOCAL_HTTPS_PORT" "$SSH_USER" "$PUBLIC_HOST"
ssh -o AddKeysToAgent=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
	-R 80:127.0.0.1:"$LOCAL_HTTP_PORT" \
	-R 443:127.0.0.1:"$LOCAL_HTTPS_PORT" \
	"$SSH_USER"@"$PUBLIC_HOST" 'sh -c "while true; do sleep 3; echo \$(date); done"'  1>"$DIR/forward.log" 2>&1 &
pid="$!"

trap 'kill -INT $pid' EXIT INT TERM

find . -maxdepth 1 -type d ! -name '.*' -print | sort | while read -r line; do
	dir="$(realpath "$DIR/$line")"
	if [ -f "$dir/create.sh" ]; then
		printf "\033[32m Executing %s/create.sh ... \033[0m\n" "$dir"
		"$dir/create.sh"
	fi
done

wait $pid || true
trap - EXIT INT TERM
echo "Finished"
