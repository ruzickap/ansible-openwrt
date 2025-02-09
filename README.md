# ansible-openwrt

Ansible playbooks configuring Openwrt devices (Wi-Fi routers)

> 💡 Always build your own OpenWrt Firmware with installed packages (it will
> save disk space)

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
/dev/root                 4.0M      4.0M         0 100% /rom
tmpfs                   121.2M    188.0K    121.0M   0% /tmp
/dev/mtdblock14          20.6M      8.6M     11.9M  42% /overlay
overlayfs:/overlay       20.6M      8.6M     11.9M  42% /
tmpfs                   512.0K         0    512.0K   0% /dev
```
