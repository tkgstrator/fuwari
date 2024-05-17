---
title: "[決定版] Goldleafの使い方"
published: 2021-10-02
description: NSPインストーラであるGoldleafの使い方について解説します
category: Hack
tags: [Switch, CFW]
---

## [Goldleaf](https://github.com/XorTroll/Goldleaf/releases)

簡単にいえばバックアップしたゲームをニンテンドースイッチにインストールするためのツールです。 DeepSea を利用しているのであればデフォルトで入っていると思うので追加で Hb App Store からダウンロードしたりする必要はありません。



## 機能一覧

![](https://pbs.twimg.com/media/EZ3naBOXYAEnet6?format=jpg&name=large)

Goldleaf は非常に多機能なのですが、エンドユーザが使うのは上の二つである Explore content と Manage console contents が多いのではないでしょうか。

### Explore content

ファイルの編集・NSP のインストールなどが行なえます。ファイル編集機能はそこまで高機能ではないので、ファイル削除やコピー程度だと考えていただいで結構です。

### Manage console contents

インストールしているアップデータの削除、アンインストールなどが行なえます。Ticket の削除機能などもあるのですが、削除するとゲームが起動しなくなるので使う場面は少ないかと思います。

## Goldleaf の導入

パソコンとスイッチで並行作業を行う必要があります。

### [JDK11.0.12'](https://download.oracle.com/otn/java/jdk/11.0.12+8/f411702ca7704a54a79ead0c2e0942a3/jdk-11.0.12_windows-x64_bin.exe)

PC からスイッチにデータ転送をするためのツールである Quark.jar は Java がインストールされていないと動きません。

### [Quark.jar](https://github.com/XorTroll/Goldleaf/releases)

PC から Goldleaf にデータを転送する専用ツールである Quark.jar をダウンロードする必要があります。

![](https://pbs.twimg.com/media/EZ3R8_VWkAAXEcV?format=jpg&name=large)

### [ドライバ](https://zadig.akeo.ie/)のインストール

Goldtree の接続がどうしても上手くいかないときは以下の手順でドライバをインストールしてみてください。

::: tip Zadig について

基本的には不要なはずだけど、もし上手くいかないときは試してほしい。

:::

Zadig をダウンロードしたら起動しましょう。

> Nintendo Switch が表示されないときは Optinons から List All Devices にチェックを入れましょう。

> libusbK（v3.0.7.0）ドライバをインストールします。

## Nintendo Switch 側の操作

![](https://pbs.twimg.com/media/EZ3TNHLWoAYbyLH?format=jpg&name=large)

Homebrew から Goldeleaf を起動します。

### NSP のインストール

![](https://pbs.twimg.com/media/EZ3TQBqWAAAQKzG?format=jpg&name=large)

Explore content を選択します。

![](https://pbs.twimg.com/media/EZ3TQmBXkAUUoo9?format=jpg&name=large)

SD カードに NSP がコピーされている場合は SD card、PC に NSP があってインストールしたい場合は Remote PC(via USB)を選択します。

今回は PC からインストールしたいので Remote PC(via USB)を選択するぞ。

Switch のドライバがちゃんとインストールされていれば Remote PC(via USB)を選択するとフリーズしたような状態になります。

![](https://pbs.twimg.com/media/EZ3kkMqX0AA9L_l?format=jpg&name=large)

この状態になったら PC 側で Quark.jar を起動しましょう。

> Goldleaf は NSP にしか対応しておらず、圧縮形式の NSZ などはインストールすることができません。NSZ をインストールしたい場合には Tinleaf Installer などを使う必要があります。

![](https://pbs.twimg.com/media/EZ3kke4X0AIim8v?format=jpg&name=large)

どちらを選んでもインストールは楽ですが、Select file from PC の方が楽かなと個人的には思います。

### PC 側での操作

![](https://pbs.twimg.com/media/EZ3VUHhWkAAYaP1?format=jpg&name=large)

Switch 側で Select file from PC を選択すると、ファイル選択ダイアログが表示されます。

![](https://pbs.twimg.com/media/EZ3Va9QWsAAMbFJ?format=jpg&name=large)

ここで自分の PC からインストールしたい NSP を選択します。今回はスプラトゥーンの体験版をインストールしようと思います。

![](https://pbs.twimg.com/media/EZ3hWu5X0AAPky8?format=png&name=large)

ここまでできれば PC 側での操作は完了です。

### Switch での NSP インストール

![](https://pbs.twimg.com/media/EZ3knEuXQAIc_Ik?format=jpg&name=large)

PC で NSP を選択すると Switch 側にインストール画面が表示されます。

![](https://pbs.twimg.com/media/EZ3knlAX0Ak-wze?format=jpg&name=large)

インストール先は SD Card か Console memory が選択できますが、当 HP では SD カードへのインストールを推奨しています。

本体メモリにインストールしてしまうと何かあったときに本体の初期化からやり直さなくてはならないため、面倒になります。

![](https://pbs.twimg.com/media/EZ3koqXXkAAtYBL?format=jpg&name=large)

選択された NSP のインストール最終チェックです。ちゃんと自分で Ticket 付きでダンプしたので nosigpatch をあてていなくてもインストールできます。

タイトルが文字化けするのは Goldleaf が日本語対応していないので仕様ですね。

![](https://pbs.twimg.com/media/EZ3m2huX0AAg5pc?format=jpg&name=large)

無事に NSP インストールに成功！

記事は以上。


