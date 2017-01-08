#!/bin/bash

set -exuo pipefail

TAG=${1:-latest}

docker build --no-cache -t jamesob/bitcoind:${TAG} .
docker login
docker push jamesob/bitcoind:${TAG}
