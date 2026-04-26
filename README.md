# ansible-openwrt

Ansible playbooks configuring OpenWrt devices (Wi-Fi routers)

> 💡 Always [build](https://firmware-selector.openwrt.org/) your own OpenWrt
> Firmware with installed packages (it will save disk space)

## [ASUS RT-AX53U](https://openwrt.org/toh/asus/rt-ax53u)

* [Firmware](https://firmware-selector.openwrt.org/?version=24.10.0&target=ramips%2Fmt7621&id=asus_rt-ax53u)

Build custom firmware using the OpenWrt Sysupgrade API:

```bash
PACKAGES_JSON=$(yq -o=json '.openwrt_packages' ansible/host_vars/gate.xvx.cz)
LATEST_STABLE=$(curl -s --compressed https://sysupgrade.openwrt.org/api/v1/latest | jq -r '.latest[] | select(test("-rc[0-9]+$") | not) | select(test("^[0-9]+\\.[0-9]+\\.[0-9]+$"))' | sort -V | tail -n 1)
echo "Latest stable: ${LATEST_STABLE}"

BUILD_RESPONSE=$(curl -s --compressed -X POST https://sysupgrade.openwrt.org/api/v1/build \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg target "ramips/mt7621" \
    --arg profile "asus_rt-ax53u" \
    --arg version "${LATEST_STABLE}" \
    --argjson packages "${PACKAGES_JSON}" \
    '{target: $target, profile: $profile, version: $version, packages: $packages, diff_packages: false}')")

REQUEST_HASH=$(jq -r '.request_hash' <<< "${BUILD_RESPONSE}")
echo "Request hash: ${REQUEST_HASH}"

while true; do
  HTTP_CODE=$(curl -s --compressed -o /tmp/build_status.json -w '%{http_code}' "https://sysupgrade.openwrt.org/api/v1/build/${REQUEST_HASH}")
  echo "Build status: ${HTTP_CODE}"
  if [[ "${HTTP_CODE}" == "200" ]]; then
    break
  fi
  sleep 10
done

BIN_DIR=$(jq -r '.bin_dir' /tmp/build_status.json)
IMAGE_NAME=$(jq -r '.images[] | select(.type == "sysupgrade") | .name' /tmp/build_status.json)
IMAGE_URL="https://sysupgrade.openwrt.org/store/${BIN_DIR}/${IMAGE_NAME}"
echo "👉 sysupgrade -v -n -p ${IMAGE_URL}"
```

## [ZyXEL NBG6617](https://openwrt.org/toh/zyxel/nbg6617)

* [Firmware](https://firmware-selector.openwrt.org/?version=24.10.0&target=ipq40xx%2Fgeneric&id=zyxel_nbg6617)

---

## Notes

### Flash router and allow SSH access to the router form the WAN

```bash
# Flash OpenWrt firmware
sysupgrade -p -n -v https://sysupgrade.openwrt.org/store/834d5261fadfab7d4f781ca4aefc8c9d8a9492bfd832365b4f1bcb0bea0de956/openwrt-24.10.0-0a8242515cd3-ipq40xx-generic-zyxel_nbg6617-squashfs-sysupgrade.bin

# Set root password
passwd

# Enable SSH access from the WAN
wget https://github.com/ruzickap.keys -O /etc/dropbear/authorized_keys

uci add firewall rule
uci set firewall.@rule[-1].name=Allow-SSH
uci set firewall.@rule[-1].src=wan
uci set firewall.@rule[-1].target=ACCEPT
uci set firewall.@rule[-1].proto=tcp
uci set firewall.@rule[-1].dest_port=22

uci add firewall redirect
uci set firewall.@redirect[-1].name=Allow-SSH-22222
uci set firewall.@redirect[-1].src=wan
uci set firewall.@redirect[-1].proto=tcp
uci set firewall.@redirect[-1].src_dport=22222
uci set firewall.@redirect[-1].dest=lan
uci set firewall.@redirect[-1].dest_port=22
uci commit
/etc/init.d/firewall restart
```
