#!/bin/bash

# TODO make simple

if [ "$1" = "init" ]; then
    docker build -t redux_remote . -f ./Dockerfile.redux_remote

    docker run -p 8000:8000 -d --name redux_remote redux_remote

    exit $?
fi

if [ "$1" = "up" ]; then
    docker start redux_remote
    

    exit $?
fi


if [ "$1" = "down" ]; then
    docker stop redux_remote

    exit $?
fi

if [ "$1" = "clean" ]; then
    docker rm -vf redux_remote
    docker rmi -f redux_remote

    exit $?
fi

if [ "$1" = "clean_all" ]; then
    docker rm -vf $(docker ps -a -q)
    docker rmi -f $(docker images -a -q)

    exit $?
fi

echo "./start.sh COMMAND
        init        - first init remote service
        up          - start remote service
        down        - stop remote service
        clean       - clean remote service
"
