---
title: Stable DiffusionをDockerで動かすチュートリアル
published: 2023-05-12
description: 環境を汚さないようにDockerで動かしたい人のための解説記事です
category: Tech
tags: [Stable Diffusion, Docker]
---

## 環境

必要なものは以下の三つです。ちなみに環境は Ubuntu 22.04 です。

- CUDA
- Docker
- Docker Compose

### CUDA

```zsh
$ nvidia-smi
+---------------------------------------------------------------------------------------+
| NVIDIA-SMI 530.41.03              Driver Version: 530.41.03    CUDA Version: 12.1     |
|-----------------------------------------+----------------------+----------------------+
| GPU  Name                  Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf            Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                                         |                      |               MIG M. |
|=========================================+======================+======================|
|   0  NVIDIA GeForce RTX 4070 Ti      Off| 00000000:01:00.0 Off |                  N/A |
|  0%   33C    P8                9W / 285W|   3043MiB / 12282MiB |      0%      Default |
|                                         |                      |                  N/A |
+-----------------------------------------+----------------------+----------------------+

+---------------------------------------------------------------------------------------+
| Processes:                                                                            |
|  GPU   GI   CI        PID   Type   Process name                            GPU Memory |
|        ID   ID                                                             Usage      |
|=======================================================================================|
|    0   N/A  N/A      1156      G   /usr/lib/xorg/Xorg                          475MiB |
|    0   N/A  N/A      1376      G   /usr/bin/gnome-shell                         45MiB |
|    0   N/A  N/A      4887      C   python                                     2518MiB |
+---------------------------------------------------------------------------------------+
```

ドライバー自体は Ubuntu の Software Updater から導入しました。このままでは Docker のコンテナ内から CUDA が利用できないので、[NVIDIA container toolkit を使って、docker のコンテナ上で cuda を動かす](https://qiita.com/Hiroaki-K4/items/c1be8adba18b9f0b4cef)の記事を参考に NVIDIA container toolkit を導入してください。

### Docker

```zsh
$ docker -v
Docker version 23.0.6, build ef23cbc
```

### Docker Compose

```zsh
$ docker compose version
Docker Compose version v2.10.2
```

## [Stable Diffusion WebUI Docker](https://github.com/AbdBarho/stable-diffusion-webui-docker)

GitHub で公開されているのでこれを利用します。

```zsh
git clone https://github.com/AbdBarho/stable-diffusion-webui-docker
cd stable-diffusion-webui-docker
```

ここに既に`docker-compose.yml`があるのでこれを利用します。

```zsh
docker compose --profile auto up --build
```

とすれば AUTOMATIC1111 版の Stable Diffusion WebUI が起動します。他にもいろいろ UI があるのですが、とりあえずこれでいいと思います。

するとビルドから何まですべてやってくれます。container toolkit を入れ忘れているとここでなんかエラーが出ます。

で、このままだと`localhost:7860`でしかアクセスできないので、外からアクセスできるようにします。ルーターのポートフォワードなどは各自やっているものとします。

#### docker-compose.yml

以下の内容を`docker-compose.yml`に追記します。いつも使っている`nginx-proxy`と`letsencrypt-nginx-proxy-companion`の組み合わせです。

TSL が必須でなければ後者は不要です。

また`auto`のところをちょっと変えます。`ports`が本当に必要かどうかはわからないので、有識者教えて下さい。

`CLI_ARGS`で実行時に渡されるオプションを変えられるので、`xformers`をとりあえず有効化しておきます（多分デフォルトで有効です）。

これを有効にすると速度がちょっと速くなる代わりに同一シードでの完全な再現性がなくなります。なのでお好みで。

```yml
  auto: &automatic
    <<: *base_service
    profiles: ["auto"]
    build: ./services/AUTOMATIC1111
    image: sd-auto:55
    ports:
      - '7860:7860'
    environment:
      VIRTUAL_HOST: $LETSENCRYPT_HOST
      VIRTUAL_POST: 7860
      LETSENCRYPT_HOST: $LETSENCRYPT_HOST
      LETSENCRYPT_EMAIL: $LETSENCRYPT_EMAIL
      CLI_ARGS: --allow-code --enable-insecure-extension-access --api --xformers --opt-sdp-attention --no-half-vae

  nginx-proxy:
    image: jwilder/nginx-proxy
    container_name: nginx-proxy
    profiles: ["external"]
    ports:
      - 80:80
      - 443:443
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
      - ./certs:/etc/nginx/certs:ro
      - /etc/nginx/vhost.d
      - /usr/share/nginx/html
    restart: always
    logging:
      driver: none

  letsencrypt:
    image: jrcs/letsencrypt-nginx-proxy-companion
    container_name: letsencrypt
    profiles: ["external"]
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./certs:/etc/nginx/certs:rw
    volumes_from:
      - nginx-proxy
    restart: always
```

環境変数から値を読み取っているので`.env`を作成してください。

```
LETSENCRYPT_HOST=
LETSENCRYPT_EMAIL=
```

二つだけ指定しておけば大丈夫です。

#### Makefile

自分は何度もコマンドを打つのがめんどくさかったので Makefile 化しました。

ローカルで動かしたいときなら`make up`、外部からも使えるようにしたいときは`make start`という感じです。

```makefile
.PHONY: up
up:
	docker compose --profile auto up --build

.PHONY: start
start:
	docker compose --profile auto --profile external up --build -d

.PHONY: down
down:
	docker compose down
```

VScode であれば SSH で繋げばそのへんもよしなにやってくれるので実は外部に公開しなくても SSH で繋げばローカル扱いでアクセスできます。

なのでこれは完全に第三者に公開するためのものです。

ここまで書いてあれですが、第三者に公開する必要がないならここまでの手順は全部要らないです。Docker で動かして終わりです。

記事は以上。
