#! /usr/bin/env bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "${DIR}/../environment/environment"
cd "${DIR}/.."
ROOT="${PWD}"

echo Setting up data directories

if [ ! -d "${COMMITMENTS_ROOT}" ]; then
  mkdir -p "${COMMITMENTS_ROOT}"
fi
if [ ! -d "${NOTIFY_ROOT}" ]; then
  mkdir -p "${NOTIFY_ROOT}"
fi
if [ ! -d "${TOKEN_ROOT}" ]; then
  mkdir -p "${TOKEN_ROOT}"
fi
if [ ! -d "${USER_ROOT}" ]; then
  mkdir -p "${USER_ROOT}"
fi
token init
notify init
commitments init

echo Setting up superforker runtime executables

if [ -d "${ROOT}/server_runtime" ]; then
  rm -rf "${ROOT}/server_runtime"
fi
mkdir -p "${ROOT}/server_runtime"
ls "${ROOT}/node_modules/.bin" \
  | xargs -I % ln -s "${ROOT}/node_modules/.bin/%" "${ROOT}/server_runtime/%"
ls "${ROOT}/server" \
  | xargs -I % ln -s "${ROOT}/server/%" "${ROOT}/server_runtime/%"

echo Links complete

superwatcher init
superwatcher watch "${ROOT}"
superwatcher environment "${ROOT}/environment/environment"
superwatcher main superforker 8080 "${ROOT}/server_runtime" "${ROOT}/client"
superwatcher info
