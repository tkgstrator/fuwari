---
title: SnapでDockerをUbuntu Serverにインストールする
published: 2024-02-12
description: Ubuntu ServerをMinimumでインストールしたときのDockerセットアップ方法 
category: Tech
tags: [Ubuntu, Ubuntu Server, Docker, Snap]
---

## 概要

インストールしようとしたらちょっと詰まったので備忘録として残しておく。

```zsh
sudo snap install docker
```

でインストールできるはずなのだが、

```zsh
error: cannot install "docker": snap "docker" assumes unsupported features: snapd2.59.1 (try to refresh snapd)
```

と表示される。`sudo snap refresh snapd`としても何も変わらない。

### 原因

Ubuntu Serverを最小構成でインストールされると`snap core`もインストールされていないのが原因。

```zsh
sudo snap refresh core
```

を実行してみて`error: snap "core" is not installed`と表示されたらビンゴ。

```zsh
sudo snap install core snapd
sudo snap install docker
```

まず`core`と`snapd`をインストールしよう。

その後でdockerをインストールすると問題なくインストール完了するはずです。

### `sudo`なしで実行

このままだと`docker info`を実行すると、

```zsh
Client:
 Version:    24.0.5
 Context:    default
 Debug Mode: false
 Plugins:
  buildx: Docker Buildx (Docker Inc.)
    Version:  v0.11.2
    Path:     /usr/libexec/docker/cli-plugins/docker-buildx
  compose: Docker Compose (Docker Inc.)
    Version:  v2.20.3
    Path:     /usr/libexec/docker/cli-plugins/docker-compose

Server:
ERROR: permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get "http://%2Fvar%2Frun%2Fdocker.sock/v1.24/info": dial unix /var/run/docker.sock: connect: permission denied
errors pretty printing info
```

みたいに表示されて都合が悪いので`sudo`なしで実行できるようにします。

```zsh
sudo groupadd docker
sudo usermod -aG docker
newgrp docker
sudo chmod 666 /var/run/docker.sock
```

上のコマンドを実行すれば権限の問題が解消されます。

> [Docker 一般ユーザーでのdockerコマンドの利用](https://timesaving.hatenablog.com/entry/2022/06/25/150000)

記事は以上。