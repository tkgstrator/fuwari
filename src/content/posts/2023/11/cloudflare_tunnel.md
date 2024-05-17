---
title: Cloudflare Tunnelでもっと簡単にサーバーを立てよう
published: 2023-11-17
description: いままではnginx proxyを利用していましたが、それすらも不要なことがわかったのでそれについて解説
category: Tech
tags: [Cloudflare]
---

## 背景

[リバースプロキシを利用した何も考えずに TLS 対応のサーバーを立てる方法](/article/2023/10/nginx_proxy.html)という記事を以前書いていたのですが、知人から「それ、Cloudflare Tunnel 使えばもっと楽だよ」と教えていただいたので、実際に使ってみることにしました。

感想としては、神でした。

背景としては前回と同じで、

1. ウェブアプリが NodeJS でポート 3030 で起動中(ポート自体は何でも良い)
2. HTTP に対応してポート(80)でウェブアプリにアクセスできるようにしたい
3. TLS に対応して HTTPS(ポート 443)でウェブアプリにアクセスできるようにしたい
4. TLS の更新に Cloudflare の SSL/TLS を利用したい
5. IP アドレスが変更されたときに DDNS で自動的に対応したい

という内容です。

| タスク | 新手法             | 以前の記事       | 従来            |
| ------ | ------------------ | ---------------- | --------------- |
| 1      | NodeJS             | NodeJS           | NodeJS          |
| 2      | Cloudflare Tunnel  | Nginx            | Nginx           |
| 3      | Cloudflare Tunnel  | Nginx            | Nginx           |
| 4      | Cloudflare SSL/TLS | Cloudflare Proxy | Let's encrypt   |
| 5      | Cloudflare Tunnel  | Cloudflare DDNS  | Cloudflare DDNS |

今回の変更により TLS 対応はウェブ上から Cloudflare SSL/TLS で Full(strict)を選ぶだけで TLS 対応可能、アプリ以外は Cludflare Tunnel に丸投げできるというとてつもなく単純化できることがわかりました。

自宅でサーバーを立てている人なら外部からのアクセスに対してポートフォワードを設定している人もいたと思うのですが、それすらも不要。もはや詰まる所がないと言っても過言ではありません。

## Cloudflare Tunnel

Cloudflare のダッシュボードから`Access>Launch Zero Trust`を選択して別のサイトを開きます。

すると何やらまた似たようなサイトが開くので`Access>Tunnels`を開きます。開いたらそこから`Create a tunnel`を選択します。

作成したいトンネル名を決めたら何やら設定画面が表示されます。今回は Docker で動作させることを目的としているので Docker のアイコンをクリックします。

```zsh
docker run cloudflare/cloudflared:latest tunnel --no-autoupdate run --token XXXXXXXXXXXXXXXX
```

みたいな内容が表示されます。ただ、これだと Docker でしか使えないのでこれを Docker compose で使える形に直します。

```yaml
version: "3.9"

services:
  app:
    image: tkgling/salmon_stats_app:latest
    container_name: salmon_stats_app
    restart: unless-stopped
    ports:
      - 3000:3000

  cloudflare_tunnel:
    restart: always
    image: cloudflare/cloudflared
    command: tunnel run
    environment:
      TUNNEL_TOKEN: $TUNNEL_TOKEN
```

> .env に`TUNNEL_TOKEN`の値を記載しておきましょう

このように書けば Cloudflare Tunnel が`docker compose up`で立ち上がり、自動的にポートフォワードをしてくれます。

どのポートをどのポートにとばすかは Web 上で決めます。

今回は[https://api.splatnet3.com](https://api.splatnet3.com)でサービスを公開することを考えます。

### 設定

設定できるのは以下の五つですので、下のように設定します。ドメインに関しては Cloudflare に登録されているものしか使えないので、使いたいドメインが未登録の場合は先に登録しましょう。

| パラメータ |      値       |
| :--------: | :-----------: |
| Subdomain  |      api      |
|   Domain   | splatnet3.com |
|    Path    |       -       |
|    Type    |     HTTP      |
|    URL     |   app:3000    |

> 別の方法で既にサブドメインが登録されている場合は同じサブドメインが登録できないので事前に前の設定を消去しなさいとの警告がでます

Path に関してはルートに設定するのであれば空っぽで大丈夫です。

URL のところが結構大事で、Cloudflare Tunnel 自体が Docker の中で動いているので`localhost`は使えず、サービス名で指定することになります。

```yaml
version: "3.9"

services:
  app: #ここが大事
    image: tkgling/salmon_stats_app:latest
    container_name: salmon_stats_app
    restart: unless-stopped
    ports:
      - 3000:3000 #ここも大事
```

今回、アプリはサービス名が`app`で外部に公開しているポートが`3000`なので HTTP://app:3030 となるように修正します。

> と思ったけれど、Docker compose の中で完結しているのであれば Dockerfile 内で EXPOSE 3000 しているのであれば ports で 3000 は公開する必要がないのでは......とも思ったのであった

あとはこれで`docker compose up -d`を実行すればサーバーが立ち上がります。余計なことは一切不要です。

記事は以上。
