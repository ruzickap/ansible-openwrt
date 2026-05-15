# ansible-openwrt

Ansible playbooks configuring OpenWrt devices (Wi-Fi routers)

> 💡 Always [build](https://firmware-selector.openwrt.org/) your own OpenWrt
> Firmware with installed packages (it will save disk space)

## [ASUS RT-AX53U](https://openwrt.org/toh/asus/rt-ax53u) - gate.xvx.cz

* [Firmware](https://firmware-selector.openwrt.org/?version=24.10.0&target=ramips%2Fmt7621&id=asus_rt-ax53u)

Build custom firmware using the OpenWrt Sysupgrade API:

```bash
mise run build-firmware:gate-xvx-cz
```

Build firmware, flash, and configure using Ansible:

```bash
mise run run-ansible-firmware:gate-xvx-cz
```

Run Ansible playbook (without firmware build):

```bash
mise run run-ansible:gate-xvx-cz
```

## [ZyXEL NBG6617](https://openwrt.org/toh/zyxel/nbg6617) - gate-bracha.xvx.cz

* [Firmware](https://firmware-selector.openwrt.org/?version=24.10.0&target=ipq40xx%2Fgeneric&id=zyxel_nbg6617)

Build custom firmware using the OpenWrt Sysupgrade API:

```bash
mise run build-firmware:gate-bracha-xvx-cz
```

Build firmware, flash, and configure using Ansible:

```bash
mise run run-ansible-firmware:gate-bracha-xvx-cz
```

Run Ansible playbook (without firmware build):

```bash
mise run run-ansible:gate-bracha-xvx-cz
```
