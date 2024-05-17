---
title: "[非脱獄] Twitter公式アプリの広告を非表示にする"
published: 2021-01-11
description: No description
category: Hack
tags: []
---

## AltServer

やりたいことは Twitter の公式アプリの広告を非表示にしたいだけなのだが、いろいろと手順が長い。

しかし、一度やってしまえばあとは自動で全部やってくれるので楽である。

### 必要なもの

Windows を使っている前提で解説していきます。

以下を読んでよくわからんかった人は画像付きでインストール手順を載せてくれている[GIGAZINE さんの記事](https://gigazine.net/news/20201115-altstore/)を読みましょう。

- [iTunes](https://www.apple.com/itunes/)
- [iCloud](https://support.apple.com/en-us/HT204283)

まず最初にこれらをインストールすること。Microsoft Store からインストールした iTunes などはサポートされていないので、一度アンインストールするなりしよう。

インストールしたら iCloud を起動して、自分が使っている Apple ID でログインします。

- [AltServer](https://altstore.io/)

ログインができたら AltServer をダウンロードします。

setup.exe を起動するとインストールが始まり、iTunes と iCloud がインストールされていればなんの苦労もなく完了するはず。

インストールできたらデバイスとパソコンを有線で接続して（一応 Wi-Fi 経由でもできるが、こちらのほうが確実）、Install AltStore からデバイスを選択。

![](https://pbs.twimg.com/media/ErWBZCwUYAEXKMW?format=png)

Apple ID でのログインを求められるので入力すると、デバイス側に AltStore がインストールされる。

ここまでできたら完了。AltServer はアプリの署名をするために必要なので、起動しっぱなしにしておくこと。

## 非公式アプリたち

[IPA Library](https://iosninja.io/ipa-library)

公式アプリに byld を追加して機能を強化した改造アプリとでも呼ぶべきアプリたちが公開されているのがこの iOS Ninja である。

一応このサイトからでもダウンロードはできるのだが、ダウンロードしてから「AltStore でひらく」という手順を踏まねばならずめんどくさい。

URLScheme を利用して GitHub のリリースページを使えばいいのに、っていうことでボタン一つでインストールできるようにしてみた。

AltServer で署名を行うので AltServer を起動しているパソコンと同一のネットワークに繋がっていなければいけないことに注意。

### Twitter Owl (2020/12/02)

- 動画保存
- 広告無し
- いいねをつける前に確認ダイアログ表示
- Face ID による認証

[Twitter Owl v8.44.1](altstore://install?url=https://github.com/tkgstrator/Pleiades/releases/download/IPAs/Twitter.8.44.1.Owl.1.5.ipa)

広告がブロックできるのでとりあえずこれ使っておけばいいのでは感があります。

### Twitter++ (2019/4/19)

- 動画保存
- Youtube の動画保存
- デフォルトブラウザでリンクを開く
- 投稿画面からメディア選択時にキーボードを表示
- 140 文字以上のツイートが投稿可能（画像として自動でツイートしてくれる）
- いいねをつける前に確認ダイアログ表示
- フルスクリーン表示
- ブロックしている人の動画ツイートが見れる

最後のアップデートが 2019 年 4 月と二年近く前なのでこっちはスルーでいいかも。

[Twitter++ v7.47](altstore://install?url=https://github.com/tkgstrator/Pleiades/releases/download/IPAs/TwitterPlus_v7.47_T1.2r-82.ipa)

### Twitch++ (2020/8/11)

- クリップを保存
- 広告を無効化

Twitch++ v9.3.1

## まとめ

非脱獄でアプリに自己署名が行える点はものすごく便利。

URLScheme を利用することでブラウザからパッとインストールできてしまうのも画期的だが、やはり同一ネットワークに繋がっていなければならず Sideload が有効期限が七日しかないのがネック。

せっかくデベロッパーアカウントを持っているのに、なぜか Free Developer Account でしかログインできないのがさっぱりわからない。Cydia Impactor だとデベロッパーアカウントか個人アカウントかをログイン時に選べたのでそこはめんどくさいなあって。

っというか、やっていることは THEOS を使ってバイナリ込みのアプリを作成しているだけのように思う。以前、自分も同じようにやってみたのだが、なぜかアプリがちゃんと動作しなかった。

やり方が悪かったのかなあ......

記事は以上。
