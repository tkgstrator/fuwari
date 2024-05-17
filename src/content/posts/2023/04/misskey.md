---
title: Misskeyの自鯖を建てるための解説
published: 2023-04-12
description: これだけ読んでおけば大丈夫な解説内容にしたい
category: Tech
tags: [Docker]
---

## Twitter is dead

Twitter は死んだ、開発者用 API にとんでもない制限がついてもはや無料でできることは何もなくなってしまった。

結局、SNS を盛り上げるためにはサードパティのアプリだったり外部連携だったりが充実していなければいけないので、それがなくなったということはすなわち Twitter は SNS としてお亡くなりになってしまったということを意味する。

正直、他人の投稿を見るだけなら Twitter である必要はないし、課金しても広告が半分しか消えないというイミフな現状には正直辟易している。

じゃあいっそのこと別のプラットフォームに移ろうかということになった。

## 別のプラットフォーム

じゃあ別のプラットフォームとして何を選ぶのかとなったときに、真っ先に浮かんだのは Mastodon でした。

が、なんかこれは特に理由もなく好きじゃなかった。なんでかはわからないけれど。

他には Twitter の後継とも言える Bluesky などもあったのですが、これはベータユーザーしか使えませんでした。

若干 SNS とは違うのですが Discord の OSS 版っぽい Mattermost も候補に上がったのですが、今回選ばれたのは Misskey でした。何故なら Docker で簡単に導入できると書いてあったから。

が、いろいろな理由で導入にはちょっと時間がかかりました。

なので解決方法などについて備忘録的にメモしておこうと思います。

## 導入方法

見ればわかるのですがスペックはガチ目に必要最低限です。

- Ubuntu 22.04LTS
- 1 CPU
- 1GB RAM
- 512MB Swap
- Tokyo Region
- 25GB SSD

でもこれで月々$5 なので、1000 円以下でサーバーが運営できるかと思えば安いものです。別にこれ以外にも利用方法はありますし。

> 注意点としてはメモリが 1GB しかないのでイメージをビルドしようとするとパッケージインストールでコケます

### 必要なもの

- Docker
- docker-compose

それぞれバージョンを調べてみたら以下のような感じでした。

今リリースされている最新のものを使えば間違いはないと思います。

```
$ docker -v
Docker version 23.0.3, build 3e7cbfd
$ docker-compose -v
docker-compose version 1.29.2, build 5becea4c
```

#### Docker 導入

[ここのサイト](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-22-04)が超わかりやすいので、上から順番にコピペして下さい。

```
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
apt-cache policy docker-ce
sudo apt install docker-ce
```

#### docker-compose 導入

[ここのサイト](https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-compose-on-ubuntu-22-04)が超わかりやすいので、上から順番にコピペしてください。

```
mkdir -p ~/.docker/cli-plugins/
curl -SL https://github.com/docker/compose/releases/download/v2.3.3/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose
```

#### 一般ユーザーで Docker を利用可能にする

現状だと`sudo`をつけないと`docker`が使えないので、パリピでも使えるようにします。

以下のコマンドを入力して一度ログインし直せばおｋ。

```
sudo usermod -aG docker $USER
```

再ログイン後`docker info`とでもやればわかります。

```
$ docker info
Client:
Context: default
Debug Mode: false
Plugins:
buildx: Docker Buildx (Docker Inc.)
Version: v0.10.4
Path: /usr/libexec/docker/cli-plugins/docker-buildx
compose: Docker Compose (Docker Inc.)
Version: v2.17.2
Path: /usr/libexec/docker/cli-plugins/docker-compose

Server:
Containers: 5
Running: 5
Paused: 0
Stopped: 0
Images: 5
Server Version: 23.0.3
Storage Driver: overlay2
Backing Filesystem: extfs
Supports d_type: true
Using metacopy: false
Native Overlay Diff: true
userxattr: false
Logging Driver: json-file
Cgroup Driver: systemd
Cgroup Version: 2
Plugins:
Volume: local
Network: bridge host ipvlan macvlan null overlay
Log: awslogs fluentd gcplogs gelf journald json-file local logentries splunk syslog
Swarm: inactive
Runtimes: io.containerd.runc.v2 runc
Default Runtime: runc
Init Binary: docker-init
containerd version: 2806fc1057397dbaeefbea0e4e17bddfbd388f38
runc version: v1.1.5-0-gf19387a
init version: de40ad0
Security Options:
apparmor
seccomp
Profile: builtin
cgroupns
Kernel Version: 5.15.0-60-generic
Operating System: Ubuntu 22.04.2 LTS
OSType: linux
Architecture: x86_64
CPUs: 1
Total Memory: 969.4MiB
Name: localhost
ID: 892f4fe0-6a00-40b5-ba29-d491cd1ddec3
Docker Root Dir: /var/lib/docker
Debug Mode: false
Registry: https://index.docker.io/v1/
Experimental: false
Insecure Registries:
127.0.0.0/8
Live Restore Enabled: false
```

### サーバーを立てよう

公式サイトにある導入手順のようにビルドしようとするとコケるので、ビルド済みのイメージを利用します。

デフォルトだとポート 3000 でアクセスしなきゃだったりとめんどくさいので、`nginx-proxy`と`letsencrypt-nginx-proxy-companion`を導入して自動で HTTPS かつ TSL がかかるようにしておきます。

ドメイン登録は自分は Cloudflare を使いましたが、各自何でも好きなのを選べば良いと思います。

#### ソースコードの取得

まずはソースコードをとってきます。

```
git clone -b master https://github.com/misskey-dev/misskey.git
cd misskey
git checkout master
```

とってきたら設定ファイルをコピーします。

```
cp .config/docker_example.yml .config/default.yml
cp .config/docker_example.env .config/docker.env
cp ./docker-compose.yml.example ./docker-compose.yml
```

この三つのファイルを編集します。必要になるのは「ユーザー名」「パスワード」「ドメイン名」の三つです。

#### docker-compose.yml

```yaml
version: "3"

services:
  web:
    image: misskey/misskey:latest
    restart: always
    links:
      - db
      - redis
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    ports:
      - "3000:3000"
    networks:
      - internal_network
      - external_network
    volumes:
      - ./files:/misskey/files
      - ./.config:/misskey/.config:ro
    environment:
      VIRTUAL_HOST: { ドメイン名 }
      VIRTUAL_POST: 3000
      LETSENCRYPT_HOST: { ドメイン名 }
      LETSENCRYPT_EMAIL: { メールアドレス }

  redis:
    restart: always
    image: redis:7-alpine
    networks:
      - internal_network
    volumes:
      - ./redis:/data
    healthcheck:
      test: "redis-cli ping"
      interval: 5s
      retries: 20

  db:
    restart: always
    image: postgres:15-alpine
    networks:
      - internal_network
    env_file:
      - .config/docker.env
    volumes:
      - ./db:/var/lib/postgresql/data
    healthcheck:
      test: "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"
      interval: 5s
      retries: 20

  nginx-proxy:
    image: jwilder/nginx-proxy
    container_name: nginx-proxy
    ports:
      - 80:80
      - 443:443
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
      - ./certs:/etc/nginx/certs:ro
      - /etc/nginx/vhost.d
      - /usr/share/nginx/html
    restart: always
    networks:
      - external_network

  letsencrypt:
    image: jrcs/letsencrypt-nginx-proxy-companion
    container_name: letsencrypt
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./certs:/etc/nginx/certs:rw
    volumes_from:
      - nginx-proxy
    restart: always

networks:
  internal_network:
    internal: true
  external_network:
    external: true
```

ここ、無駄に`external_network`を設定しているのですが要らない可能性もあります。ひょっとしたら`docker-compose up`したときになんか怒られるかも知れないので、そのときは表示された推奨コマンド（内容を忘れた）を打ち込んでください。

#### .config/default.yml

ここで設定するユーザー名とパスワードはデータベースを弄る以外では利用しないので、めちゃくちゃ堅いやつにしておくと良いです。

```yaml
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Misskey configuration
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#   ┌─────┐
#───┘ URL └─────────────────────────────────────────────────────

# Final accessible URL seen by a user.
url: https://{ ドメイン名 }

# ONCE YOU HAVE STARTED THE INSTANCE, DO NOT CHANGE THE
# URL SETTINGS AFTER THAT!

#   ┌───────────────────────┐
#───┘ Port and TLS settings └───────────────────────────────────

#
# Misskey requires a reverse proxy to support HTTPS connections.
#
#                 +----- https://example.tld/ ------------+
#   +------+      |+-------------+      +----------------+|
#   | User | ---> || Proxy (443) | ---> | Misskey (3000) ||
#   +------+      |+-------------+      +----------------+|
#                 +---------------------------------------+
#
#   You need to set up a reverse proxy. (e.g. nginx)
#   An encrypted connection with HTTPS is highly recommended
#   because tokens may be transferred in GET requests.

# The port that your Misskey server should listen on.
port: 3000

#   ┌──────────────────────────┐
#───┘ PostgreSQL configuration └────────────────────────────────

db:
  host: db
  port: 5432

  # Database name
  db: misskey

  # Auth
  user: { ユーザー名 }
  pass: { パスワード }

  # Whether disable Caching queries
  #disableCache: true

  # Extra Connection options
  #extra:
  #  ssl: true

dbReplications: false
```

#### .config/docker.env

```
# db settings
POSTGRES_PASSWORD={ パスワード }
POSTGRES_USER={ ユーザー名 }
POSTGRES_DB=misskey
```

### 立ち上げ

```
docker-compose up
```

だけで立ち上がります。うちのサーバーの場合、立つのに一分くらいかかりました。動作チェックをするだけなら、グローバル IP アドレスのポート 3000 でアクセスすればおｋです。

#### DNS 設定

A レコードに追加します。自分の場合は`splatnet3.com`というドメインを持っていたので、それにサブドメインを生やしました。

| Type |  Name  |     Content     | Proxy status | TTL  |
| :--: | :----: | :-------------: | :----------: | :--: |
|  A   | mihari | xxx.xxx.xxx.xxx |   DNS only   | Auto |

上がそのまま設定したやつです。

#### 最適化

で、ここでちょっと引っかかったのですが Cloudflare の最適化である`Auto Minify`が有効化されていると`Vite`のコードが変に最適化されて動かなくなります。

それでは困るので`Page Rules`で指定したウェブサイトでは自動最適化が実行されないようにします。

よくわからない人は`Auto Minify: Off`になるように設定すれば良いです。

詳しいやり方は英語だけど[この辺](https://developers.cloudflare.com/support/speed/optimization-file-size/using-cloudflare-auto-minify/)がわかりやすいです。

#### パーミッション設定

普通に起動すると`~/misskey/files`にアクセス権限がなくて画像のアップロードに失敗します。

```
sudo chmod 777 ~/misskey/files
```

で強引に書き込み権限を付けました。多分もっといい方法があるので緩募。

### 完成

無事に[サーバー](https://mihari.splatnet3.com/@tkgling)が立ち上がりました。嬉しいね。
