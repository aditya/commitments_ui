#! /usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "${DIR}/../environment/environment"
cd "${DIR}/.."
ROOT="${PWD}"

superwatcher logs
