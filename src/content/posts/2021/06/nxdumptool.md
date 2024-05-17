---
title: "[Hack] NXDumpToolでNSPをバックアップしよう"
published: 2021-06-10
description: NXDumpToolの使い方です
category: Hack
tags: [CFW]
---

# [NXDumpTool](https://github.com/DarkMatterCore/nxdumptool)

> この記事は以前公開していたものを加筆・修正したものになります

ニンテンドースイッチ本体のみでゲームカートリッジやアップデータからデータを抽出することができるツールです。

利用にあたっては事前に[LockPick_RCM](https://github.com/shchmue/Lockpick_RCM)で title.key 及び prod.key を取得する必要があるのでやっておきましょう。スイッチ上で実行するだけでよくて、特にファイルを移動させたりする必要はありません。

LockPick_RCM の使い方については[この記事]()を参考にしてください。

> 現在加筆・修正中になります

## Ticket（証明書）

Ticket はゲームカードごとに固有のものであり、ゲームのインストール時に本体に保存されます。

固有のものであるということは、同時に二つの Ticket を持つ NSP がオンラインプレイをしていれば一方がコピーされたものであることがわかります。つまり、海賊行為は容易に任天堂に BAN されます。

![](https://pbs.twimg.com/media/EW5mDtsX0AM4y6P?format=png)

Goldleaf の場合、インストール時に`The NSP has a ticket to be imported`とあれば取り込むための証明書が NSP に含まれていることを意味します。

![](https://pbs.twimg.com/media/EW5mDYIXkAAJ5Kt?format=png)

証明書が NSP に含まれていない場合、`The NSP doesn't have a ticket`と表示されます。

このような NSP は Sigpatch と呼ばれる特別なパッチを当てていない限り、インストールすることはできません。

## BASE のダンプ

カートリッジに書き込まれているゲームデータは（おそらく大半が）BASE と呼ばれるアップデータが適応されていない初期バージョン（v0）になります。

このバージョンのことを BASE といい、アップデートされたゲームで遊ぶためには必ず BASE と遊びたいバージョンの UPD（アップデータ）が必要になります。

つまり、カートリッジを使わないのであれば BASE のダンプは必ず必要になります。

::: tip

カートリッジ版のオリジナルを持っている場合は、カートリッジ（BASE）+ UPD という組み合わせでも起動できます。

が、今回は完全にカートリッジレスな環境をつくることを目的としたため BASE も NSP としてインストールすることを考えます。

:::

![](https://pbs.twimg.com/media/E3fAbbsUUAEK7Bc?format=png)

起動するとこんな画面がでてくると思います。カートリッジからダンプしたい場合は`Dump gamecard content`を選択します。ダウンロード版の場合は`Dump installed SD card / eMMC content`を選択します。

今回はダウンロード版の場合の解説をしますが、カートリッジ版とほとんど同じです。

![](https://pbs.twimg.com/media/E3fAbbuVEAATtBj?format=png)

ではスプラトゥーンの BASE をダンプしてみましょう。

![](https://pbs.twimg.com/media/E3fAbcFVcAA2cwK?format=png)

選択するとこのような画面が表示されると思うのですが`Nintendo Submission Package (NSP) dump`を選択します。

![](https://pbs.twimg.com/media/E3fAcoVVUAETe6y?format=png)

ここで、もし BASE も UPD もインストールされている場合は選択肢が表示されます。

- `Dump base application NSP`
  - BASE のダンプ
- `Dump installed update NSP`
  - UPD/DLC のダンプ

今回は BASE をダンプするので上の`Dump base application NSP`を選択します。

### 設定項目

![](https://pbs.twimg.com/media/E3fAco9VEAE04i1?format=png)

::: warning BASE のダンプについて

紫色の字で`Dump base application NSP`と表示されていることを確認してください。

:::

ここでいろいろオプションがあってわかりにくいと思うのでそれぞれ解説します。

- `Start NSP dump process`
  - NSP のダンプを開始します
- `Split outpuot dump (FAT32 support)`
  - SD カードが FAT32 でフォーマットされている場合、4GB 以上のファイルは保存できないのでファイルを分割して保存するオプションです
- `Verify dump using No-Intro database`
  - NSP が正しくダンプできているかをチェックするオプションです
- `Remove console specific data`
  - コンソール固有データを削除します
  - より具体的には personalized ticket を common ticket に切り替えます
  - よくわからない人は Yes にしておけば大丈夫です
- `Generage ticket-less dump`
  - `Remove console specific data`を Yes にすると表示されます
  - Ticket を含まない NSP を出力します
  - よくわからない人はで No にしておけば大丈夫です
- `Change NPDM RSA key/sig in Program NCA`
  - どんな CFW でも NSP が正しく動作するためのオプション
  - 無効化すると追加で ACID パッチが必要になる
  - よくわからない人は Yes にしておけば大丈夫です
- `Dump delta fragments`
  - `Remove console specific data`を Yes にすると表示されます
  - よくわからないんですが、多分 No で大丈夫です
- `Base application to dump`
  - 弄れないので大丈夫
- `Output naming scheme`
  - 出力ファイルの命名規則
  - 特にいじらなくて大丈夫です

それぞれ設定できたら`Start NSP dump process`でダンプを開始しましょう。

## UPD/DLC のダンプ

BASE をダンプするときとほとんど同じです。

![](https://pbs.twimg.com/media/E3fGlXgVcAIPDmR?format=png)

設定は変えなくて良いでしょう。

::: warning アップデータのダンプについて

紫色の字で`Dump installed update NSP`と表示されていることを確認してください。

:::

## ダンプしてみた

ダンプしたデータは`/switch/NXDumpTool/NSP`内にありますので確認してみてください。

あとはこのデータ FTP なり直接 SD カードを PC に接続するなりでパソコン内のストレージに保存しておけばよいでしょう。

### NSZ との比較

NSZ とは NSP を圧縮したパッケージファイルであり、実質的には NSP と同じものです。

NSP を NSZ にすることでだいたい 10 ~ 20%ほどの容量を節約することができますが、その代償としてインストール時に圧縮状態を解除する必要があるため余計に時間がかかります。

要するに、時間と容量のトレードオフ関係ということです。昨今はストレージの大容量化が進んでいるため、NSP をわざわざ NSZ に圧縮する必要はないと考えています。

@[youtube](https://www.youtube.com/watch?v=UEq7PZuhoSI)

記事は以上。
