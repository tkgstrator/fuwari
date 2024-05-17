---
title: Macを初期化して最初にやったこと
published: 2023-05-31
description: Macを初期化してやったことまとめ
category: Tech
tags: [macOS]
---

## Mac Studio を初期化した

一年以上同じ環境を使い続けてきてめんどくさくなったので心機一転しました。

## アプリ

### [Google Chrome](https://www.google.com/chrome/)

必須。Safari の最初で最後の仕事。

### [Google IME](https://www.google.co.jp/ime/)

必須。Google Chrome 最初の仕事。

### [Xcodes](https://www.xcodes.app/)

いろんなバージョンの Xcode をインストールできる優れもの。

### [VScode](https://code.visualstudio.com/)

必須。詳細は割愛。

### [Fig](https://fig.io/)

ターミナル補助。コマンドとかを表示してくれて助かります。

### [Docker Desktop](https://www.docker.com/products/docker-desktop/)

もはや必須。

### [Sourcetree](https://www.sourcetreeapp.com/)

Git クライアントです、基本的に便利。

[バグ](https://qiita.com/katzueno/items/97222296337827f81ab0)で Keychain のアクセスか何かで爆熱になる。

根本的な解決法は何なんだろう？

## ツール

コマンドでインストールしていく系を紹介していきます。

### [Homebrew](https://brew.sh/)

必須。

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### [Yarn](https://yarnpkg.com/)

```
$ brew install yarn
$ yarn -v
1.22.19
```

### [nvm](https://github.com/nvm-sh/nvm)

Node Version manager

```
$ curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash=
$ source ~/.zshrc
```

Homebrew を使わずに直接`curl`で導入するのが良いとされています。

### [deno](https://deno.com/)

```
$ brew install deno
```

### [fastlane](https://fastlane.tools/)

```
$ brew install fastlane
```

### [rbenv]()

`gem`を使おうとすると`permission denied`と怒られるのでこれを使う。

```
$ brew install rbenv ruby-build
$ rbenv install -l
$ rbenv install 3.2.2
$ rbenv global 3.2.2
$ rbenv versions
  system
* 3.2.2 (set by /Users/devonly/.rbenv/version)
```

このあと、`~/.zshrc`を編集してユーザー領域の Ruby を利用するように変更

```zsh
[[ -d ~/.rbenv  ]] && \
  export PATH=${HOME}/.rbenv/bin:${PATH} && \
  eval "$(rbenv init -)"
```

```
$ which ruby
/Users/devonly/.rbenv/shims/ruby
```

無事にユーザー領域の Ruby が利用できるようになった。
