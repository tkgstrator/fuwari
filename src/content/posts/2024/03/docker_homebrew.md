---
title: Linuxbrew+DockerでRubyが動作するコンテナを作る
published: 2024-03-08
description: 最初からHomebrewが入ったDockerイメージを使いたい件
category: Tech
tags: [VSCode, DevContainer, Homebrew, Docker]
---

## 目標

1. コンテナに入ったらすぐに`brew`コマンドが叩けること
2. `which ruby`で`rbenv`でインストールしたrubyが指定されること

デフォルトで入っているRubyはシステム領域に書き込んだりしてヤバめな存在なので利用しません。

よって、RubyのDockerイメージが色々存在しますがそれも利用しません。

### 前任者

調べてみるとちょくちょくDockerfileの中でbrewをインストールしている記事を見かけます。

> [DockerイメージにLinuxbrewをDockerfileでインストールする](https://qiita.com/beeeyan/items/ef72532701bb8219bc55)

しかしながら何だか長くてめんどくさそうです。

> [How to install brew into a Dockerfile (`brew: not found`)](https://stackoverflow.com/questions/73757217/how-to-install-brew-into-a-dockerfile-brew-not-found)

しかもやればわかるのですがDockerfile内で`brew: not found`と表示されます。

それでは困るのでこの方法は諦めることにしました。

### 公式のイメージ

調べてみると公式のDockerのイメージ[homebrew/brew](https://hub.docker.com/r/homebrew/brew/tags)が転がっていました。

これで良さそうな気がするのですが、サイズを見ると1.04GBもあり無駄に大きいです。

開発用なので別に大きくても問題はないといえばないのですが[Ubuntu](https://hub.docker.com/_/ubuntu/tags)の最軽量のものだと30MBくらいしかないので、余計なものがいっぱい入っているのだろうことは想像が付きます。

なんで今回は可能な限り軽量なイメージを作成することを心がけます。

とはいえ、既にHomebrewがインストールされているイメージは有効活用したいですよね。

### 解決策

```dockerfile
FROM ubuntu:focal-20240216
COPY --from=homebrew/brew:4.2.11 /home/linuxbrew/.linuxbrew /home/linuxbrew/.linuxbrew

ENV PATH="$PATH:/home/linuxbrew/.linuxbrew/bin"
RUN apt-get update
RUN apt-get -y install git curl
RUN apt-get -y autoremove
RUN apt-get -y clean
RUN rm -rf /var/lib/apt/lists/*
```

というわけで実際にbrewがインストールされている`/home/linuxbrew/.linuxbrew`だけを公式のイメージからパクってくることにします。

このとき、homebrew/brewはlinux/amd64しかサポートしていないのでApple Siliconで動作させる場合には`--platform=linux/amd64`の指定が必須になります。

ベースのイメージはubuntu:focalを利用しているので非常に軽量です。