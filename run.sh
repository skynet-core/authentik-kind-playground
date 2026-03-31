#!/usr/bin/env sh

set -e

DIR="$(dirname "$(realpath "$0")")"

for env_file in $(find . -maxdepth 1 -type f -iname "*.env" -print | sort); do
	set -a
	# shellcheck disable=SC1090
	. "$env_file"
	set +a
done

"$DIR/forward.sh" &
pid="$?!"
trap 'kill -9 $pid' EXIT INT TERM

find . -maxdepth 1 -type d ! -name '.*' -print | sort | while read -r line; do
	dir="$(realpath "$DIR/$line")"
	if [ -f "$dir/create.sh" ]; then
		printf "\033[32m Executing %s/create.sh ... \033[0m\n" "$dir"
		"$dir/create.sh"
	fi
done

wait $pid || true

echo "Finished"
