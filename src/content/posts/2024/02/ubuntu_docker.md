---
title: Ubuntu Serverで一発目にDockerが効かない話
published: 2024-02-05
description: Dockerが効かないときに困ったのでその対応方法
category: Tech
tags: [Ubuntu, Docker]
---

## 概要

Ubuntu Serverインストール時にdockerをついでにインストールするとインストール自体はされているのだが使い勝手が悪い。

なのでその対応策。

### 対応策

以下のコードを上から順番に実行、最後だけパスワードが必要。

```zsh
sudo groupadd docker
sudo usermod -aG docker $USER
sudo chmod 666 /var/run/docker.sock # 再起動だけで済むかもしれない
```

> [Docker 一般ユーザーでのdockerコマンドの利用](https://timesaving.hatenablog.com/entry/2022/06/25/150000)

記事は以上。

びっくりするほどに記事が短い。