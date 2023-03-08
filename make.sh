#!/bin/sh
set -e

docker_name=zig-tty-test-data
docker_cmd=${1:-""}

case "$docker_cmd" in
	build)
	    # Ensure the docker user has the same UID as the current user.
	    docker_uid="$(id -u)"

	    sudo docker buildx build -t "$docker_name" --no-cache \
	        --build-arg uid="$docker_uid" --progress tty .
		;;
	run)
        sudo docker run --rm --name "$docker_name" -it \
            --mount type=bind,source="$(PWD)"/src,target=/home/zig/src,readonly \
            --mount type=bind,source="$(PWD)"/data,target=/home/zig/data \
            "$docker_name":latest
		;;
	run-sh)
        sudo docker run --rm --name "$docker_name" -it --entrypoint sh \
            "$docker_name":latest
        ;;
    clean):
        rm -f binary binary.o
        ;;
    "")
        printf "$0: error: the command is required\n"
        exit 1
        ;;
    *)
       printf "$0: error: invalid command '%s'.\n" "$docker_cmd"
       exit 1
       ;;

esac
