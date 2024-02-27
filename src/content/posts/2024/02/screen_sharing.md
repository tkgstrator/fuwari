---
title: Cloudflare Tunnel経由でScreen Sharingを利用しよう
published: 2024-02-27
description: 'macOSのデフォルト機能のScreen Sharingを強制的にリモートから使う計画です'
image: ''
tags: [macOS, Cloudflare, VNC]
category: Tech
draft: false 
---

## Screen Sharing

macOSにはリモートデスクトップ的なScreen Sharingという機能があります。

で、これ非常に快適なのですが何故かローカルネットワークでしか利用できないという大変に致命的な問題があります。

データ通信が重いからとか、レスポンス的な観点からの措置だと思うのですが外部からでも操作できるようにしたいところではあります。

普通、外部からローカルネットワークにアクセスしようとしたらVPNで解決することが多いのではないかと思います。

当初、私もWireguardでVPNを構築していたのですがよくよく考えたらそもそも今回の要件ではVPNはScreen Sharingのためにしか使わない上に、VPNが動作しているサーバーを更に中継することになるのでレスポンスが更に悪化してしまいます。

よって、ローカルネットワークで中継サーバーを挟まずに直接ホストマシンにアクセスする方法が求められました。

これ、Cloudflare Tunnelでなんとかなりませんか？

### Cloudflare Tunnel

調べているとほぼほぼ同様の内容の[Launch your Mac from a browser with Cloudflare](https://blog.samrhea.com/posts/2021/zero-trust-mac-browser)を見つけました。

記事をチラ見したところ、ブラウザ経由でリモートのMacのScreen Sharingを動作させるための方法について解説してあるようです。

なのでこれを参考に実際に構築してみることにしました。

## 手順

- ホストマシン
  - Screen Sharingを有効化してあること
  - Docker Desktop for Macがインストールしてあること

調べているとCloudflaredをホストマシンで直接動かしている記事ばかり見かけるのですが、立ち上げるときの便利さや環境を汚さないことを考えるとDocker一択だと思うのですが何故なのでしょうか（パフォーマンスの問題とか？

### Cloudflare

[Zero Trust](https://one.dash.cloudflare.com/)のダッシュボードにアクセスします。

**Access > Applications**から適当にアプリを作成します。

今回、ドメイン名は[mac.tkgstrator.work](https://mac.tkgstrator.work)にしました。

ポリシーでアクセスできる権限を設定します。

最後に**Settings > Additional settings > Browser rendering**からVNCを有効化します。

#### Tunnel

**Networks > Tunnels**から適当にトンネルを作成します。

設定方法を適当に選んで`TUNNEL_TOKEN`をコピーします。

**Public Hostname**には先ほど設定したドメイン名と同じ**mac.tkgstrator.work**を指定します。

ここで、サービスは**Type=TCP**, **URL=host.docker.internal:5900**を指定します。

CloudflaredがDockerで動いているので**localhost:5900**は何の効果も持ちません、指定しないように。

> ここで普段なら追加でAccessの設定をいれるのですがVNCの場合は不要のようです、有効化すると繋がらなくなります

### Docker

以下のような`docker-compose.yaml`を作成します。

```yaml
version: '3.9'

services:
  cloudflare_tunnel:
    restart: always
    image: cloudflare/cloudflared:latest
    command: tunnel run
    container_name: cloudflared_browser_vnc
    environment:
      TUNNEL_TOKEN: $TUNNEL_TOKEN
    extra_hosts:
      - host.docker.internal:host-gateway
```

人によっては見飽きた設定ですね。`extra_hosts`を指定し忘れると繋がらないので注意すること。コピペでいけます。

```zsh
TUNNEL_TOKEN=YOUR_CLOUDFLARE_TUNNEL_TOKEN
```

同じディレクトリに`.env`を作成して先ほどコピーした`TUNNEL_TOKEN`を貼り付けます。

これで準備は完了です。

## 起動

`docker compose up -d`で立ち上がります。

[サーバーに接続](https://mac.tkgstrator.work/)するとDiscordでの認証が求められます。

認証ができればパスワードログインでブラウザ経由でVNC接続できます。

### 使ってみて

正直遅い、まだVPNで繋いだほうが速い。

設定でどうにかなるのかは未知数、まあでもVNC繋がるのは楽しい。

記事は以上。