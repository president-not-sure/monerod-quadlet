# monerod Quadlet

A Tor secured monerod client managed by Podman Quadlet.

## Features

- All monerod traffic must go through Tor
  - host_ip:18081:18081 <- monerod container -> Internal network -> Tor proxy container -> External network (internet)
- Automatically rebuilds images from upstream:
  - monerod: weekly
  - Tor: daily
- Automatically restarts when a new image is built
- Automatically starts/stops on reboot
- No updates required unless upstream introduces breaking changes
- Minimal image size:
  - monerod: ~275MB
  - Tor: ~160MB

## Requirements

- Linux
- Podman
- 100GB+

## Install

### Clone

```bash
git clone --recurse-submodules https://github.com/president-not-sure/monerod-quadlet.git
cd monerod-quadlet
```

### Quadlet

In order to connect to the node externally, it is required to modify `PublishPort=127.0.0.1:18081:18081` of the `monerod/monerod.container` file to the external host IP address.

> [!WARNING]
> If the host runs a DNS server on all interfaces, add `DisableDNS=true` under the `[Network]` section of each `.network` unit file to prevent port conflicts.

```bash
podman quadlet install --replace tor-quadlet/tor
podman quadlet install --replace monerod
install -vD -m 644 -t ~/.config/systemd/user \
    tor-quadlet/timers/tor-build.timer \
    timers/monerod-build.timer
systemctl --user daemon-reload
systemctl --user enable --now \
    tor-build.timer \
    monerod-build.timer \
    podman-auto-update.timer
sudo loginctl enable-linger $USER
```

## Usage

`systemctl --user start monerod.service` to start the quadlet without having to reboot.

> [!NOTE]
> The first run will take more time because it needs to build the first image. `journalctl --user -f -u monerod-build.service` to see build progress.


`podman logs --follow monerod` or any Podman GUI for monerod logs.

## Uninstall

```bash
systemctl --user stop monerod.service
podman quadlet rm --force .tor.app
podman quadlet rm --force .monerod.app
systemctl --user disable --now tor-build.timer monerod-build.timer
rm -rfv \
    ~/.config/systemd/user/monerod-build.timer \
    ~/.config/systemd/user/tor-build.timer
systemctl --user daemon-reload
```
