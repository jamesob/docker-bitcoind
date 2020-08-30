#!/usr/bin/env bash

# Included as a workaround to address https://github.com/jamesob/docker-bitcoind/pull/16
#
echo "$@" >> /etc/hosts
