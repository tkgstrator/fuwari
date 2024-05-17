---
title: DevkitProをmacOSで動かそう
published: 2021-11-02
description: DevkitProは通常Ubuntuなどでビルドするのですが、macOSでビルドできるかチャレンジしてみました
category: Programming
tags: [Nintendo Switch]
---

# DevkitPro

Nintendo Switch 用の Homebrew アプリを作成するのに必須の SDK 管理用のパッケージマネージャでこれをインストールしないとまず始まらない。

Ubuntu または WSL2 を用いた Ubuntu 仮想環境での導入方法についてはたくさん触れられているので、今回は macOS で動作させる方法について解説していく。

ちなみに、うちの環境は以下の通り。

- Mac mini(M1, 2020)
  - Chip Apple M1
  - Memory 8GB
  - macOS Big Sur
- Xcode 13.0 (13A233)

## DevkitPro のインストール

[このページ](https://github.com/devkitPro/pacman/releases/tag/v1.0.2)で解説しているとおりに進める。

```sh
wget https://github.com/devkitPro/pacman/releases/download/v1.0.2/devkitpro-pacman-installer.pkg
sudo installer -pkg /path/to/devkitpro-pacman-installer.pkg -target /
```

折角なのでダウンロード用のコマンドも載せておきました。

## SDK のインストール

今回は Nintendo Switch 向けのアプリを開発したいので以下のコマンドを入力します。

```sh
sudo dkp-pacman -Sy
sudo dkp-pacman -Syu
sudo dkp-pacman -S switch-dev
```

パスワードを入力すると以下のような画面が出るはずなので、何も考えずにエンターキーを押します。

```sh
:: There are 12 members in group switch-dev:
:: Repository dkp-libs
   1) deko3d  2) devkita64-cmake  3) libnx  4) switch-cmake  5) switch-examples  6) switch-pkg-config
:: Repository dkp-osx
   7) devkitA64  8) devkitA64-gdb  9) general-tools  10) pkg-config  11) switch-tools  12) uam

Enter a selection (default=all):
```

## 環境変数の設定

自分の環境では`.zshrc`を使っていたのですが、ここでは各自あわせてファイルを適時変更してください。

```sh
# .zshrc
export DEVKITPRO=/opt/devkitpro
export DEVKITARM=/opt/devkitpro/devkitARM
export DEVKITPPC=/opt/devkitpro/devkitPPC
```

これらを記述するか、単にコマンドから入力しておけば大丈夫です。

## ビルドしてみよう

テンプレートファイルがあるのでそれを利用します。

::: warning 記事との違い

[このメモ](https://gist.github.com/iGlitch/e2c97e2284760c7526ddd50374772e34)では`simple`というディレクトリがあることになっているが、実際には`application`というものにバージョンアップで変更されている。

:::

```sh
cd ~
git clone https://github.com/switchbrew/switch-examples
cd switch-examples/templates/application
mkdir -p exefs_src/a
make
```

```sh
$ make
main.c
linking application.elf
built ... application.nacp
built ... application.nro
```

ビルド自体は 10 秒ほどで終わり、ファイルができていることが確認できる。

```sh
$ ls
Makefile            application.nro		source
application.elf     build
application.nacp	exefs_src
```

あとは`application.nro`をスイッチの SD カードの`switch`フォルダに移動させればアプリケーションとして動作します。

### コードを改造しよう

弄るのは`source/main.c`だけです。

> ってかこれ、C++じゃなくて C なんですね...
