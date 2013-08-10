#!/bin/bash

set -e

NAME=$1
REPO_DIR=$2
cd $REPO_DIR
COMMIT_ID=$3
BUILD_ID=$4

BASE="ubuntu:precise"

banner() {
  echo "=========| $1 |========"
}

indent() {
  sed -e 's/^/# /'
}

banner pull
docker pull $BASE

git archive $COMMIT_ID > /dev/null

banner prepare $COMMIT_ID
# TODO: Make a git checkout instead
# TODO: Use the mount option
ID=$(git archive $COMMIT_ID | docker run -i -a stdin "$BASE" /bin/sh -c "mkdir -p /cache /build && tar -x -C /build")
docker wait $ID >/dev/null
ID=$(docker commit $ID)


banner build $ID
ID=$(docker run -d $ID /bin/sh -c "/build/script/slugify /cache /app/deploy")
docker attach $ID | indent
ID=$(docker commit $ID)

banner export $ID
ID=$(docker run -d $ID -i -a stdout /bin/sh -c "cd /app/deploy && tar czf - ." > ../$BUILD_ID.tar.gz)

