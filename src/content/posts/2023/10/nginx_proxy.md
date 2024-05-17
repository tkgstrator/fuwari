---
title: リバースプロキシを利用した何も考えずにTLS対応のサーバーを立てる方法
published: 2023-10-23
description: Dockerのイメージを利用して何も考えずにHTTPS対応のサーバーを立てる方法を考えます
category: Tech
tags: [Docker]
---

## 背景

以下のような利用を想定しています。

1. ウェブアプリが NodeJS でポート 3030 で起動中(ポート自体は何でも良い)
2. HTTP に対応してポート(80)でウェブアプリにアクセスできるようにしたい
3. TLS に対応して HTTPS(ポート 443)でウェブアプリにアクセスできるようにしたい
4. TLS の更新に Cloudflare の SSL/TLS を利用したい
5. IP アドレスが変更されたときに DDNS で自動的に対応したい

SSL/TLS 対応は Let's encrypt を使うのが有名ですが、地味にめんどくさいので Cloudflare の機能で代用しようというわけです。

### 必要なもの

SSL/TLS 対応は Docker イメージを利用しないので、必要なものは以下の三つです。ウェブアプリの Docker イメージについては自分で作成してください。

1. [jwilder/nginx-proxy](https://hub.docker.com/r/jwilder/nginx-proxy)
   - リバースプロキシを可能にします
2. [oznu/cloudflare-ddns](https://hub.docker.com/r/oznu/cloudflare-ddns/)
   - 定期的に Cloudflare に DDNS の通知を飛ばします
3. ウェブアプリ

### docker compose

以下のような YAML ファイルを作成します。

```yaml
version: "3.9"

services:
  app:
    image: xxxxxx/xxxxxx:latest
    container_name: app
    ports:
      - $VIRTUAL_PORT:$VIRTUAL_PORT
    environment:
      VIRTUAL_HOST: $VIRTUAL_HOST
    restart: unless-stopped

  nginx_proxy:
    image: jwilder/nginx-proxy
    container_name: nginx_proxy
    ports:
      - 80:80
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
    environment:
      ENABLE_IPV6: true
      TRUST_DOWNSTREAM_PROXY: true

  cloudflare_ddns:
    image: oznu/cloudflare-ddns:latest
    container_name: ddns
    restart: always
    environment:
      API_KEY: $API_KEY
      ZONE: $ZONE
      SUBDOMAIN: $SUBDOMAIN
      PROXIED: $PROXIED
      RRTYPE: $RRTYPE
    network_mode: "host"
    depends_on:
      nginx_proxy:
        condition: service_started
```

必要となる環境変数は以下の通り。

```zsh
# Nginx
VIRTUAL_PORT=
VIRTUAL_HOST=

# Cloudflare DDNS
API_KEY=
ZONE=
SUBDOMAIN=
PROXIED=
RRTYPE=
```

|    キー名    |               意味                |    設定する値の例    |
| :----------: | :-------------------------------: | :------------------: |
| VIRTUAL_PORT |   ウェブアプリが利用するポート    |         3030         |
| VIRTUAL_HOST |       利用したいドメイン名        | docs.tkgstrator.work |
|   API_KEY    |      Cloudflare の API キー       |          -           |
|     ZONE     |             ホスト名              |   tkgstrator.work    |
|  SUBDOMAIN   |           サブドメイン            |         docs         |
|   PROXIED    |       プロクシを利用するか        |  true または false   |
|    RRTYPE    | IPv4 か IPv6 のどちらを利用するか |    A または AAAA     |

ZONE と SUBDOMAIN の値は VIRTUAL_HOST と一致しなければいけません。

設定が正しく反映されているかは`docker compose config`で確認できます。

## 起動

この状態で起動してみます。

```zsh
docker compose up
```

### 動作確認

今回は以下の設定を利用しました。

```zsh
VIRTUAL_PORT=3030
VIRTUAL_HOST=api.splatnet3.com
ZONE=splatnet3.com
SUBDOMAIN=api
API_PROXIED=true
API_RRTYPE=AAAA
```

AAAA(IPv6)に対応させているのは IPv6 では NAT 越えを考えずに単にグローバル ID を指定するだけで良いこと(ルーターでのポートフォワーディングが不要)が理由です。何か制約があるわけではないのであれば AAAA を指定したほうが良いです。

また、Cloudflare による HTTPS 化に対応させるためには`API_PROXIED=true`を指定する必要があります。これを設定することで Cloudflare までのアクセスは HTTPS で保護され、Cloudflare から実際のサーバーまでの通信は Proxy が適用されます。

よって、アクセスして動作確認をする URL は以下の五つです。

> ローカル IP のものは当たり前ですがローカルでしか繋がりません

1. [http://localhost:3030/docs](http://localhost:3030/docs)
   - ウェブアプリの起動確認
2. [http://api.splatnet3.com:3030/docs]([http://api.splatnet3.com:3030/docs)
   - DDNS の動作確認
3. [http://localhost/docs](http://localhost/docs)
   - Nginx Proxy の動作確認
   - 多分これは繋がらないと思う(理由はよくわかっていない)
4. [http://api.splatnet3.com/docs](http://api.splatnet3.com/docs)
   - DDNS + Nginx Proxy の動作確認

4 が繋がったら DDNS と Nginx Proxy が正しく動いているので最後に HTTPS 対応の処理を行います。

Google Chrome などでは自動で HTTPS にリダイレクトされる機能があるかもしれないので何らかの方法で直接プロトコルを指定して叩くと良いかもです。

### Cloudflare の設定

Cloudflare のウェブサイトからドメインを選択し SSL/TLS の項目を変更します。

Overview の項目で Your SSL/TLS encryption mode の設定で、

- Off(not secure)
- Flexible
- Full
- Full(strict)

があると思うのですが`Flexible`を選択します。もしもサーバー自体が SSL/TLS に対応している場合は Full を選択して良いのですが、今回はウェブサーバー自体で SSL を設定していないので Flexible を選択します。

最後に HTTPS に対応した URL を開いて通信が正常に行えることを確認します。

5. [https://api.splatnet3.com/docs](https://api.splatnet3.com/docs)
   - DDNS + Nginx Proxy + TLS の動作確認

記事は以上。
