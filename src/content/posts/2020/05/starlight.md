---
title: "[Hack] Starlight + Docker Install Guide"
published: 2020-05-19
description: Dockerを用いたStarlightの導入ガイドです
category: Hack
tags: [Starlight, Ubuntu, Docker]
---

## Starlight をアプデした

[Starlight](https://github.com/tkgstrator/Starlight)

### 変更点

- ビルド環境を構築済みの Docker に依存するように変更。
  - ソースコードにエラーがなければ必ずビルドに成功します。
  - keystone や keystone-engine の構築に失敗することなし。
  - devkitpro のアプデに悩まされることなし。
  - python のバージョンに悩まされることなし。
  - 簡単に言うとビルドが死ぬほど簡単。
- デフォルトでぼくのソースコードをビルドできる。
  - サーモンランの解析は捗る！
- WSL2 の利用が（多分）必須。
  - WSL2 自体はまだベータ機能なのでちょっと導入が面倒かも。
  - まあそれでもビルド環境つくるよりは簡単。
- Ubuntu は 18.04 を推奨。
  - 16.04 だとデフォルトで python3 が入ってない。
  - 20.04 はシンタックスがなんか変。

まあ、導入がめっちゃ楽になったと思ってもらえればダイジョブ。

## 導入方法

まず最初に WSL2 で Ubuntu18.04 の環境を用意する必要があります。

WSL1 だと Docker は Hyper-V でしかサポートされておらず、Windows 10 Home だと Hyper-V が有効化できないからです。

WSL2 では WSL2 distro という謎システムで Hyper-V を使わずに Docker を使える仕組みが整備されています。

WSL2 で Ubuntu18.04 をインストールしつつ、Docker 環境を整える方法は以下の記事がわかりやすいです！

[Windows Subsystem for Linux 2 で Docker for WSL2 を使う](https://dev.to/birdsea/windows-subsystem-for-linux-2-docker-for-wsl2-3dpm)

で、無事に Docker がインストールできたとしましょう。

### Docker の設定

`docker info`と入力して、どんな反応が返ってくるか調べます。

![](https://pbs.twimg.com/media/EYWJbYvWAAAaOLL?format=png)

`docker info`失敗例です。

ズラーッとよくわからんログが表示されれば良いですが、デフォルトだと docker コマンドは sudo 権限でしか動かないので`permission denied`と怒られると思います。

```
sudo gpasswd -a $USER docker
exit
```

なので上のコマンドを入力して、exit で一度 Ubuntu を再起動（Windows は再起動しなくて OK）して設定を有効化します。

これは docker コマンドを sudo 権限で動かせるようにするのだ。

![](https://pbs.twimg.com/media/EYWJzoJX0AAhFLD?format=png)

`docker info`成功例です。

再起動後に再び`docker info`と入力すれば、無事に Docker にアクセスできます。

あと、初期状態だと`make`もインストールされていない可能性が高いのでインストールしましょう。

```
sudo apt update
sudo apt upgrade
sudo apt install -y python3 make
```

### Starlight の導入

ここからはものすごく簡単です。

```
git clone https://github.com/tkgstrator/Starlight.git
cd Starlight
make
```

詳しいことは Starlight のレポジトリの[README](https://github.com/tkgstrator/Starlight/blob/master/README_JP.md)に書いてあるのでそれを読んでもらえば大丈夫かと。

もしわからないことがあれば以下のリンクから Discord サーバに参加して、直接きいていただければ返事します。

[LanPlay-JP](https://discord.gg/vUVBJFAKvZ)

## おまけ

@[youtube](https://www.youtube.com/watch?v=q23Pkyddjb4)

解説動画をつくってみたので、参考にしてください。

記事は以上。
