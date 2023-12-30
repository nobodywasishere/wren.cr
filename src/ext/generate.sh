#!/usr/bin/env bash

set -e

cd $(dirname "$0")

make download
make all
