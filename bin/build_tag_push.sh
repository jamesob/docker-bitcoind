#!/bin/bash

set -eu

VERSIONS=$(./bin/get-bitcoin.sh 2>&1 | grep '^  0' | tr -d '  ')

docker login

for ver in $VERSIONS; do
  echo "--- building bitcoin $ver"
  echo
  echo
  docker build -t "jamesob/bitcoind:${ver}" --build-arg "VERSION=${ver}" .
  # read -p "Push? (y/N): " confirm && [[ $confirm == [yY] ]] && \
  docker push "jamesob/bitcoind:${ver}"
done
