#!/bin/sh
set -e

ID=$(id -u)
NAME=zig-tty-test-data
CMD=${1:-build}

case $CMD in
	build)
	    # Ensure the docker user has the same UID as the current user.
	    sudo docker buildx build -t $NAME --no-cache --build-arg uid=$ID \
	        --progress tty .
		;;
	run)
        sudo docker run --rm --name ${NAME} -it \
            --mount type=bind,source="$(pwd)"/src,target=/home/zig/src,readonly \
            --mount type=bind,source="$(pwd)"/data,target=/home/zig/data \
            ${NAME}:latest
		;;
	run-sh)
        sudo docker run --rm --name ${NAME} -it --entrypoint sh ${NAME}:latest
        ;;
    clean):
        rm binary binary.o
        ;;
	*)
	    printf "invalid command: '%s'\n" $CMD
		;;
esac
