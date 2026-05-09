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

RANDOM_SUFFIX=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 10 || true)
ROOT_PASSWORD="${HOSTNAME}12345${RANDOM_SUFFIX}"
echo "🔑 Root password: ${ROOT_PASSWORD}"

DEFAULTS="# Configure WiFi
uci delete wireless.default_radio1.disabled
uci set wireless.default_radio1.ssid='${WIFI_SSID} 5 GHz'
uci set wireless.default_radio1.encryption='sae-mixed'
uci set wireless.default_radio1.key='${WIFI_PASSWORD}'
uci commit wireless

# Set random root password
echo 'root:${ROOT_PASSWORD}' | chpasswd

# Allow SSH on WAN
uci add firewall rule
uci set firewall.@rule[-1].name='Allow-SSH-WAN'
uci set firewall.@rule[-1].src='wan'
uci set firewall.@rule[-1].dest_port='22'
uci set firewall.@rule[-1].proto='tcp'
uci set firewall.@rule[-1].target='ACCEPT'
uci commit firewall

# Add GitHub SSH public key for ruzickap
mkdir -p /etc/dropbear
wget -q -O /etc/dropbear/authorized_keys https://github.com/ruzickap.keys
chmod 600 /etc/dropbear/authorized_keys"

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
echo "Build status JSON: https://sysupgrade.openwrt.org/api/v1/build/${REQUEST_HASH}"
echo "🚀 sysupgrade -v -n -p ${IMAGE_URL}"
