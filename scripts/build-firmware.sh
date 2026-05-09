#!/usr/bin/env bash
# Build custom OpenWrt firmware using the Sysupgrade API
# Usage: build-firmware.sh <target> <profile> <host_vars_file> <defaults>

set -euxo pipefail

TARGET="${1:?Usage: build-firmware.sh <target> <profile> <host_vars_file> <defaults>}"
PROFILE="${2:?}"
HOST_VARS="${3:?}"
DEFAULTS="${4:?}"

PACKAGES_JSON=$(yq -o=json '.openwrt_packages' "${HOST_VARS}")
LATEST_STABLE=$(curl -sL --compressed https://sysupgrade.openwrt.org/api/v1/latest |
  jq -r '.latest[] | select(test("-rc[0-9]+$") | not) | select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))' |
  sort -V | tail -n 1)
echo "Latest stable: ${LATEST_STABLE}"

BUILD_RESPONSE=$(curl -s --compressed -X POST https://sysupgrade.openwrt.org/api/v1/build \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg target "${TARGET}" \
    --arg profile "${PROFILE}" \
    --arg version "${LATEST_STABLE}" \
    --argjson packages "${PACKAGES_JSON}" \
    --arg defaults "${DEFAULTS}" \
    '{target: $target, profile: $profile, version: $version, packages: $packages, diff_packages: false, defaults: $defaults}')")

REQUEST_HASH=$(jq -r '.request_hash' <<< "${BUILD_RESPONSE}")
if [[ "${REQUEST_HASH}" == "null" ]]; then
  echo "Build request failed:"
  jq . <<< "${BUILD_RESPONSE}"
  exit 1
fi
echo "Request hash: ${REQUEST_HASH}"

while true; do
  HTTP_CODE=$(curl -s --compressed -o /tmp/build_status.json -w '%{http_code}' \
    "https://sysupgrade.openwrt.org/api/v1/build/${REQUEST_HASH}")
  echo "Build status: ${HTTP_CODE}"
  if [[ "${HTTP_CODE}" == "200" ]]; then
    break
  elif [[ "${HTTP_CODE}" == "202" ]]; then
    sleep 10
  else
    echo "Build failed (HTTP ${HTTP_CODE}):"
    jq . /tmp/build_status.json
    exit 1
  fi
done

BIN_DIR=$(jq -r '.bin_dir' /tmp/build_status.json)
IMAGE_NAME=$(jq -r '.images[] | select(.type == "sysupgrade") | .name' /tmp/build_status.json)
IMAGE_URL="https://sysupgrade.openwrt.org/store/${BIN_DIR}/${IMAGE_NAME}"
echo "Build status JSON: https://sysupgrade.openwrt.org/api/v1/build/${REQUEST_HASH}"
echo "sysupgrade -v -n -p ${IMAGE_URL}"
