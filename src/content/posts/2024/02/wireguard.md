---
title: Wireguard+DockerでVPNサーバーを構築する
published: 2024-02-05
description: Cloudflare Tunnelを利用してVPNサーバーをWireguardで立てる方法
category: Tech
tags: [Ubuntu, Wireguard, Cloudflare, Docker, Cloudflare Tunnel]
---

## Wireguard

docker-compose.yamlは以下のものを使う。どうもwireguardは最新版だとちょっとおかしいっぽい。

主に[The docker-compose example for linuxserver/wireguard is not suitable for latest linuxserver/wireguard image ](https://github.com/ngoduykhanh/wireguard-ui/issues/479)が参考になりました。

### docker-compose.yaml

```yaml
version: "3.9"

services:
  wireguard:
    image: linuxserver/wireguard:v1.0.20210914-ls6
    container_name: wireguard
    cap_add:
      - NET_ADMIN
    volumes:
      - ./config:/config
    restart:
      unless-stopped
    ports:
      # port for wireguard-ui. this must be set here as the `wireguard-ui` container joins the network of this container and hasn't its own network over which it could publish the ports
      - 5000:5000
      # port of the wireguard server
      - 51820:51820/udp
    environment:
      - PUID=1000
      - PGID=1000
      - PEERS=3
      - SERVERURL=$SERVERURL
      - SERVERPORT=$SERVERPORT
      - INTERNAL_SUBNET=$INTERNAL_SUBNET
      - ALLOWEDIPS=$ALLOWEDIPS
    healthcheck:
      test: ["CMD", "/config/healthcheck.sh"]
      interval: 5s
      timeout: 10s
      retries: 3

  wireguard-ui:
    image: ngoduykhanh/wireguard-ui:latest
    container_name: wireguard-ui
    depends_on:
      wireguard:
        condition: service_healthy
    cap_add:
      - NET_ADMIN
    # use the network of the 'wireguard' service. this enables to show active clients in the status page
    network_mode: service:wireguard
    environment:
      - SENDGRID_API_KEY
      - EMAIL_FROM_ADDRESS
      - EMAIL_FROM_NAME
      - SESSION_SECRET
      - WGUI_USERNAME=admin
      - WGUI_PASSWORD=$WGUI_PASSWORD
      - WG_CONF_TEMPLATE
      - WGUI_MANAGE_START=true
      - WGUI_MANAGE_RESTART=true
      - WGUI_SERVER_POST_UP_SCRIPT=iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
      - WGUI_SERVER_POST_DOWN_SCRIPT=iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
    logging:
      driver: json-file
      options:
        max-size: 50m
    volumes:
      - ./db:/app/db
      - ./config:/etc/wireguard

  cloudflare_tunnel:
    restart: always
    image: cloudflare/cloudflared
    command: tunnel run
    container_name: cloudflared_wireguard
    environment:
      TUNNEL_TOKEN: $TUNNEL_TOKEN
    depends_on:
      - wireguard-ui
```

不必要ではあるがCloudflaredでWireguard-UIを外部からアクセス可能にしている。

ただ、バカ正直にこれをやると設定ファイルが外部からアクセス可能であるとのエラーが出るので注意されたい。

### .env

読み込んでいる環境変数はこちら。

```zsh
TUNNEL_TOKEN=
WGUI_PASSWORD=
SERVERURL=
SERVERPORT=51820
PEERS=1
PEERDNS=auto
INTERNAL_SUBNET=10.6.0.0/24
ALLOWEDIPS=10.6.0.0/24
```

これで正しいのかどうかもよくわかっていないが、とりあえずこれで動きます。

### healthcheck.sh

いきなり起動するとwireguardのプロセスが完了する前に立ち上がってしまっているとかそんなんだと思うので`healthcheck.sh`で死活監視をします。

これについては[wiregurad fails after Stop/start docker-compose](https://github.com/ngoduykhanh/wireguard-ui/issues/381)が参考になりました。

```zsh
#!/bin/bash

# Check if the WireGuard interface is up
if ip link show wg0 &> /dev/null ; then
    exit 0 # The interface is up, so the container is healthy
else
    exit 1 # The interface is down, so the container is unhealthy
fi
```

このファイルについては`chmod +x healthcheck.sh`で実行権限をつけておくこと。

### ディレクトリ構造

`docker compose up -d`で起動すると以下のように勝手にディレクトリが作成されます。

```zsh
.
├── config/
│   ├── coredns/
│   ├── peer1/
│   ├── peer2/
│   ├── peer3/
│   ├── server/
│   ├── templates/
│   ├── .tonoteditthisfile
│   ├── healthcheck.sh
│   └── wg0.conf
├── db/
│   ├── clients/
│   ├── server/
│   └── users/
├── .env
└── docker-compose.yaml
```

### ポート開放

ポート開放は必須です。

51820がwireguardが起動しているサーバーに対して向くようにポートフォワードしてやりましょう。

## 起動

あとはこの状態で起動すれば`wireguard > wireguard-ui > cloudflared`の順に立ち上がり、`service_healthy`のおかげでwireguardが立ち上がるまでwireguard-uiの起動を待ってくれます。

やったね！

記事は以上。