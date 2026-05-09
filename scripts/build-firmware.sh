#!/usr/bin/env bash
# Build custom OpenWrt firmware using the Sysupgrade API
# Usage: build-firmware.sh <target> <profile> <hostname>

set -euxo pipefail

TARGET="${1:?Usage: build-firmware.sh <target> <profile> <hostname>}"
PROFILE="${2:?}"
HOSTNAME="${3:?}"

HOST_VARS="ansible/host_vars/${HOSTNAME}"
WIFI_SSID=$(yq '.wifi_ssid' "${HOST_VARS}")
WIFI_PASSWORD_VAR=$(echo "${HOSTNAME}" | tr '[:lower:].-' '[:upper:]__')_WIFI_PASSWORD
WIFI_PASSWORD="${!WIFI_PASSWORD_VAR:?Environment variable ${WIFI_PASSWORD_VAR} is not set}"

DEFAULTS="uci delete wireless.radio0.disabled
uci delete wireless.radio1.disabled
uci set wireless.default_radio1.ssid='${WIFI_SSID} 5 GHz'
uci set wireless.default_radio1.encryption='sae-mixed'
uci set wireless.default_radio1.key='${WIFI_PASSWORD}'
uci commit wireless"

PACKAGES_JSON=$(yq -o=json '.openwrt_packages' "${HOST_VARS}")
LATEST_STABLE=$(curl -sL --compressed https://sysupgrade.openwrt.org/api/v1/latest |
  jq -r '.latest[] | select(test("-rc[0-9]+$") | not) | select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))' |
  sort -V | tail -n 1)
echo "✅ Latest stable: ${LATEST_STABLE}"

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
  echo "❌ Build request failed:"
  jq . <<< "${BUILD_RESPONSE}"
  exit 1
fi
echo "🔑 Request hash: ${REQUEST_HASH}"

while true; do
  HTTP_CODE=$(curl -s --compressed -o /tmp/build_status.json -w '%{http_code}' \
    "https://sysupgrade.openwrt.org/api/v1/build/${REQUEST_HASH}")
  echo "⏳ Build status: ${HTTP_CODE}"
  if [[ "${HTTP_CODE}" == "200" ]]; then
    break
  elif [[ "${HTTP_CODE}" == "202" ]]; then
    sleep 10
  else
    echo "❌ Build failed (HTTP ${HTTP_CODE}):"
    jq . /tmp/build_status.json
    exit 1
  fi
done

BIN_DIR=$(jq -r '.bin_dir' /tmp/build_status.json)
IMAGE_NAME=$(jq -r '.images[] | select(.type == "sysupgrade") | .name' /tmp/build_status.json)
IMAGE_URL="https://sysupgrade.openwrt.org/store/${BIN_DIR}/${IMAGE_NAME}"
echo "📋 Build status JSON: https://sysupgrade.openwrt.org/api/v1/build/${REQUEST_HASH}"
echo "🚀 sysupgrade -v -n -p ${IMAGE_URL}"
