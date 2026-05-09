# ansible-openwrt

Ansible playbooks configuring OpenWrt devices (Wi-Fi routers)

> 💡 Always [build](https://firmware-selector.openwrt.org/) your own OpenWrt
> Firmware with installed packages (it will save disk space)

## [ASUS RT-AX53U](https://openwrt.org/toh/asus/rt-ax53u) - gate.xvx.cz

* [Firmware](https://firmware-selector.openwrt.org/?version=24.10.0&target=ramips%2Fmt7621&id=asus_rt-ax53u)

Build custom firmware using the OpenWrt Sysupgrade API:

```bash
mise run build-firmware
```

## [ZyXEL NBG6617](https://openwrt.org/toh/zyxel/nbg6617)

* [Firmware](https://firmware-selector.openwrt.org/?version=24.10.0&target=ipq40xx%2Fgeneric&id=zyxel_nbg6617)

---

## Notes

### Flash router and allow SSH access to the router form the WAN

```bash
# Set root password
passwd

# Enable SSH access from the WAN
wget https://github.com/ruzickap.keys -O /etc/dropbear/authorized_keys

cat >> /etc/config/firewall << 'EOF'

config rule
	option name 'Allow-SSH'
	option src 'wan'
	option target 'ACCEPT'
	option proto 'tcp'
	option dest_port '22'

config redirect
	option name 'Allow-SSH-22222'
	option src 'wan'
	option proto 'tcp'
	option src_dport '22222'
	option dest 'lan'
	option dest_port '22'
EOF

/etc/init.d/firewall restart
```
