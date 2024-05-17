---
title: 脱獄Tweakを作成できるTHEOSのセットアップ方法
published: 2021-06-21
description: THEOSは脱獄Tweakを作成できるのですが、そのセットアップ方法をまとめました
category: Programming
tags: [Swift]
---

# THEOS

THEOS は脱獄 Tweak を作成するためのプラットフォームです。

単なる広告非表示 Tweak から GUI も整った高度な脱獄アプリまで何でもつくることができます。

## THEOS のセットアップ

THEOS は Windows、iOS、macOS、Linux のプラットフォームをサポートしているようですが、とりあえず macOS を利用するのが簡単です。

iOS でも開発はできるので macOS を持っていない方は脱獄した iOS に環境を作り、SSH 接続して PC でコードを書くことになると思います。Windows や Linux はめんどくさいので今回は割愛します。

### 必要なもの

- macOS
  - Mavericks(10.9)以上であれば問題ないようです
- Xcode
  - とりあえず最新のものをインストールしておけばよいです
- Objective-C、Swift への情熱
  - 最低限のプログラミングスキルは必須
- エラーにもくじけない心

::: warning セットアップについて

すべてのコマンドは必ずユーザ権限で実行するようにしてください。要するに、`root`で実行してはダメだし、`sudo`をつけてもダメだということです。

:::

### Homebrew のインストール

以下のコマンドでインストールします。

```zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

それなりに時間がかかるのでじっくり待ちます。

### ldid、xz のインストール

```zsh
brew install ldid xz
```

これも同様に待ちます。

### 環境変数の設定

```zsh
# Catalina(macOS 10.15) 以上の方
echo "export THEOS=~/theos" >> ~/.zprofile
source ~/.zprofile
```

```zsh
# Catalina(macOS 10.14) 未満の方
echo "export THEOS=~/theos" >> ~/.profile
source ~/.profile
```

::: tip おまけ

[@p1atdev](https://twitter.com/p1atdev)氏の[記事](https://zenn.dev/platina/articles/cc2dcfa20711e2)にもあるように、コマンド一発で theos を呼び出せるようにしておくと良いかもしれません。

```zsh
vi ~/.zprofile
```

でファイルをひらき、`alias theos="$THEOS/bin/nic.pl"`を追記して保存。
:::

### THEOS のインストール

インストールといっても GitHub からクローンしてくるだけです、簡単。

```zsh
git clone --recursive https://github.com/theos/theos.git $THEOS
```

### SDK のインストール

```zsh
curl -LO https://github.com/theos/sdks/archive/master.zip
TMP=$(mktemp -d)
unzip master.zip -d $TMP
mv $TMP/sdks-master/*.sdk $THEOS/sdks
rm -r master.zip $TMP
```

これを全部一気にターミナルにコピーして実行。iOS14.4 までの SDK しかないので、それ以上のものが使いたい場合は各自手に入れよう。

### 実行してみる

`$THEOS/bin/nic.pl`と実行して以下のように表示されれば成功

![](https://pbs.twimg.com/media/E4VdYyqVgAY6fgM?format=png)

## THEOS JAILED のセットアップ

脱獄していなくても動作させられる Tweak を作成できる神ツール。

一時期はやった Sideload などで使われている。興味がある人は是非追加してみよう。

```zsh
git clone --recursive https://github.com/kabiroberai/theos-jailed
cd theos-jailed
./install
```

こうすると標準の THEOS に入獄用 Tweak 作成のテンプレートが追加される。

`$THEOS/bin/nic.pl`と実行して以下のように表示されれば成功

![](https://pbs.twimg.com/media/E4Vh6K_UUAAH3Kg?format=png)

さっきまでの結果と比べて`[8.] iphone/jailed`という項目が追加されているのがわかります。

ここまでできればセットアップは完了です。
