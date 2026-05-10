#!/usr/bin/env bash
# Build custom OpenWrt firmware using the Sysupgrade API
# Usage: build-firmware.sh <target> <profile> <hostname>

set -euo pipefail

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

SHORT_HOSTNAME="${HOSTNAME%%.*}"

DEFAULTS="exec > /root/uci-defaults.log 2>&1
set -x

# Set hostname
sed -i \"s/option hostname .*/option hostname '${SHORT_HOSTNAME}'/\" /etc/config/system

# Configure WiFi
uci delete wireless.default_radio1.disabled
uci set wireless.default_radio1.ssid='${WIFI_SSID} 5 GHz'
uci set wireless.default_radio1.encryption='sae-mixed'
uci set wireless.default_radio1.key='${WIFI_PASSWORD}'
uci commit wireless

# Set random root password
printf '%s\n%s\n' \"${ROOT_PASSWORD}\" \"${ROOT_PASSWORD}\" | passwd root

# Allow SSH on WAN
cat >> /etc/config/firewall << 'FIREWALL_EOF'

config rule
	option name 'Allow-SSH-WAN'
	option src 'wan'
	option dest_port '22'
	option proto 'tcp'
	option target 'ACCEPT'
FIREWALL_EOF

# Add GitHub SSH public key for ruzickap
mkdir -p /etc/dropbear
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF58juRs3gDSCFXARSXBBSegOmmBxXln9MVk2Zcq3HGh petr.ruzicka@gmail.com' > /etc/dropbear/authorized_keys
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
  echo "⏳ Build status: ${HTTP_CODE} - waiting for build to complete..."
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
