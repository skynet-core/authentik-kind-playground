#!/usr/bin/env sh

set -e

DIR="$(dirname "$(realpath "$0")")"

find . -type f -maxdepth 1 -iname "*.env" -print | sort | while read -r env_file; do
    . "$env_file"
done

find . -maxdepth 1 -type d ! -name '.*' -print | sort | while read -r line; do
    dir="$(realpath "$DIR/$line")"
    if [ -f "$dir/create.sh" ]; then
        printf "\033[32m Executing %s/create.sh ... \033[0m\n" "$dir"
        "$dir/create.sh"
    fi
done
