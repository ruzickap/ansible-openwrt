# ansible-openwrt

Ansible playbooks configuring OpenWrt devices (Wi-Fi routers)

> 💡 Always [build](https://firmware-selector.openwrt.org/) your own OpenWrt
> Firmware with installed packages (it will save disk space)

## Flash router and allow SSH access to the router form the WAN

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

## [ASUS RT-AX53U](https://openwrt.org/toh/asus/rt-ax53u)

* [Firmware](https://firmware-selector.openwrt.org/?version=24.10.0&target=ramips%2Fmt7621&id=asus_rt-ax53u)

List of partitions after OpenWRT firmware installation (version 23.05.5) with
packages installed via Ansible:

```console
# df -h
Filesystem                Size      Used Available Use% Mounted on
/dev/root                 4.3M      4.3M         0 100% /rom
tmpfs                   122.2M      5.9M    116.3M   5% /tmp
/dev/ubi0_1              33.0M     29.8M      1.6M  95% /overlay
overlayfs:/overlay       33.0M     29.8M      1.6M  95% /
tmpfs                   512.0K         0    512.0K   0% /dev
```

List of partitions after OpenWRT firmware installation (version 23.05.5):

```console
# df -h
Filesystem                Size      Used Available Use% Mounted on
/dev/root                 4.3M      4.3M         0 100% /rom
tmpfs                   122.2M     80.0K    122.1M   0% /tmp
/dev/ubi0_1              33.0M    160.0K     31.2M   0% /overlay
overlayfs:/overlay       33.0M    160.0K     31.2M   0% /
tmpfs                   512.0K         0    512.0K   0% /dev
```

List of partitions after OpenWRT firmware installation (version 24.10.0):

```console
# df -h
Filesystem                Size      Used Available Use% Mounted on
/dev/root                 4.5M      4.5M         0 100% /rom
tmpfs                   121.6M    284.0K    121.4M   0% /tmp
/dev/ubi0_1              32.7M     48.0K     30.9M   0% /overlay
overlayfs:/overlay       32.7M     48.0K     30.9M   0% /
tmpfs                   512.0K         0    512.0K   0% /dev
```

List of partitions after Customized OpenWRT firmware installation
(version 24.10.0) where packages are part of the firmware image:

```console
# df -h
Filesystem                Size      Used Available Use% Mounted on
/dev/root                25.0M     25.0M         0 100% /rom
tmpfs                   121.6M      1.1M    120.5M   1% /tmp
/dev/ubi0_1              13.6M     60.0K     12.8M   0% /overlay
overlayfs:/overlay       13.6M     60.0K     12.8M   0% /
tmpfs                   512.0K         0    512.0K   0% /dev
```

## [ZyXEL NBG6617](https://openwrt.org/toh/zyxel/nbg6617)

* [Firmware](https://firmware-selector.openwrt.org/?version=24.10.0&target=ipq40xx%2Fgeneric&id=zyxel_nbg6617)

List of partitions after OpenWRT firmware installation (version 23.05.5) with
packages installed via Ansible:

```console
Filesystem                Size      Used Available Use% Mounted on
/dev/root                15.5M     15.5M         0 100% /rom
tmpfs                   120.7M      6.2M    114.5M   5% /tmp
/dev/mtdblock14           9.0M    452.0K      8.6M   5% /overlay
overlayfs:/overlay        9.0M    452.0K      8.6M   5% /
tmpfs                   512.0K         0    512.0K   0% /dev
/dev/sda1                 3.7G      6.9M      3.2G   0% /mnt
```

List of partitions after OpenWRT firmware installation (version 24.10.0):

```console
# df -h
Filesystem                Size      Used Available Use% Mounted on
/dev/root                21.3M     21.3M         0 100% /rom
tmpfs                   120.7M      2.9M    117.8M   2% /tmp
tmpfs                   120.7M    128.0K    120.6M   0% /tmp/root
tmpfs                   512.0K         0    512.0K   0% /dev
/dev/mtdblock14           3.3M    304.0K      3.0M   9% /overlay
overlayfs:/overlay        3.3M    304.0K      3.0M   9% /
```
