---
title: "[Hack] Hekate-Toolboxで変更できる項目を増やそう"
published: 2020-06-19
description: 自分で追加したモジュールのオンオフの切り替えの仕方について
category: Nintendo
tags: [Nintendo Switch, Emulator]
---

## [Hekate-Toolbox](https://github.com/WerWolv/Hekate-Toolbox)

Hekate-Toolbox または DeepSea-Toolbox からモジュールの切り替えができるのがすごく便利なのですが、よくよく考えたら自分で追加したモジュールのオンオフの切り替えも Hekate-Toolbox でできたら便利じゃないですか？

## DeepSea 既存のモジュール

### [emuiibo](https://github.com/XorTroll/emuiibo)

アミーボ機能をエミュレートするモジュール。

この機能を使うためには amiibo をダンプし、そのデータを emuiibo 用に変換するなど非常にめんどくさい作業が伴う。普通に amiibo カードを作成するか、そのまま amiibo 読み込んだほうが早い。

というか、この機能使っている人間の 99%は海賊行為をしているだろうと勝手に決めつけているので、emuiibo についての解説はなし。当 HP で emuiibo のトピックを扱っていないのもそれが理由。

### [Tesla-Menu](https://github.com/WerWolv/Tesla-Menu)

ニンテンドースイッチでオーバーレイを使ってチートの有効化などを行えるモジュール。

「L + 十字キー下ボタン + 右スティック押し込み」のコマンドでメニューを表示し、いろいろいじることができます。便利そうですが、使えるメモリが 4MB しかないので何でもできるわけではないことに注意。

### [nx-ovlloader](ttps://github.com/WerWolv/nx-ovlloader)

OVL ファイルを読み込むためのモジュール。

Tesla-Menu などはこのモジュールが必要です。

### [Status-Monitor-Overlay](https://github.com/masagrator/Status-Monitor-Overlay)

ハードウェアをリアルタイムで監視するモジュール。

FPS Counter を使用すると、一部のゲームではロード画面が動かなくなったり、音声が飛んだりすることがあるそうですが、めったにないとのことです。

### [sys-clk](https://github.com/retronx-team/sys-clk)

ニンテンドースイッチをオーバークロックできる機能で、本来はドックに挿している TV モードが一番スペックを高くできるのだが、その制限を解除して携帯モードとかテーブルモードでも CPU のクロック数を上げられるモジュール。

使ったことがないので基本はオフで問題ない。

### [sys-con](https://github.com/cathery/sys-con)

純正品以外のサードパーティコントローラを扱うためのモジュール。

使わないのであればずっとオフで問題ない。

### [MissionController](https://github.com/ndeadly/MissionControl)

ニンテンドースイッチ以外の Wii、WiiU、PS4、PS5、Xbox などのコントローラを扱うためのモジュール。

使わないのであればずっとオフで問題ない。

### [sys-ftpd-light](https://github.com/cathery/sys-ftpd-light)

ニンテンドースイッチでポート 5000 を利用して FTP 通信を有効化するモジュールである sys-ftpd の軽量版。メモリ消費量が抑えられているのが特徴。

ドキュメントによると 7MB 程度消費していたメモリが 1MB 程度にまで抑えられるのだとか。

モジュールが利用できるメモリの合計値は結構カツカツなので、こういう軽量化は非常にありがたい。よほどのことがない限り、常時オンで問題ない。

### [ldn_mitm](https://github.com/spacemeowx2/ldn_mitm)

LanPlay に対応していないゲームの LocalPlay（アドホックモード）を強制的に LanPlay（LAN モード）に切り替えるモジュール。

スプラトゥーン 2 ではこれを無効化するとイカッチャで LocalPlay（LanPlay は遊べる）が遊べなくなってしまう。

スプラトゥーンで遊ぶ限りは基本はオンで問題ない。

## 追加すると便利そうなモジュール一覧

### [SysDVR](https://github.com/exelix11/SysDVR)

キャプチャーボードなしで USB または LAN 経由で画面キャプチャーをパソコンに転送できるモジュール。すごい便利なのだが、そこそこメモリを消費するのでゲームの動作が不安定になったりするときがあるのが玉に瑕。

sys-ftpd-light と致命的に相性が悪いので、両方オンにしていると結構落ちてしまうので注意。ただ、ちょくちょくアップデートされてるのでだんだん安定化はしている模様。

ちょっとやってみた感じ、Tesla と組み合わせても相当重かったです。まあこれはモジュールの仕様上仕方がないかもしれません。

使うときだけオンにしておくのが良いでしょう。

### [sys-botbase](https://github.com/olliz0r/sys-botbase)

Wi-Fi 経由でコントローラの入力をエミュレートしたり、ゲームのメモリを読み込んだりできるモジュール。

これも結構重いのでオンにするのは使いたいときだけが良い。

### [USB-Botbase](https://github.com/fishguy6564/USB-Botbase)

sys-botabase をベースとして、USB 経由でコントローラの入力をエミュレートできるモジュール。

めちゃくちゃ重たいので他のモジュールをオフにしていないと安定して動作させるのは難しい。ちゃんとしてないとしょっちゅうモジュールがクラッシュして接続できなくなってします。

そういうときはニンテンドースイッチを再起動する以外に対処できないので注意。

### [sys-netcheat](https://github.com/jakibaki/sys-netcheat)

LAN 経由でチートの検索などができるモジュール。署名無効化パッチ（sigpatch）と干渉してゲームによっては起動しなくなる場合があるそうなので、その際は Common Ticket を Tinfoil のオプションから削除して再起動すると良いそうだ。

使ったことがないのでまあ全然わからんのだが、人によっては便利かもしれない。

### [sys-tune](https://github.com/HookedBehemoth/sys-tune)

Tesla overlay を利用してバックグラウンドで音楽を再生することができるモジュール。ただ、M4A は再生できなかったので汎用性はあんまりないかもしれない（MP3 ならいける）

対応している拡張子は MP3、FLAC、WAV の三つ。なんで FLAC サポートしているのかは謎である。

## モジュールの有効の仕方

モジュールが有効かどうかは`sdmc://atmosphere/contents/[TITLE ID]/flags/boot2.flg`という空ファイルがあるかないかでチェックしているのですが、このファイルを生成したり削除したりを Hekate-Toolbox がやってくれるというわけです。

コンフィグファイルは`sdmc://atmosphere/contents/[TITLE ID]/toolbox.json`に JSON 形式で記述されているので自分でちまちま追加しましょう。

```json
{
  "name": "bootsoundnx",
  "tid": "00FF0000000002AA",
  "requires_reboot": true
}
```

```json
{
  "name": "hid-mitm",
  "tid": "0100000000000FAF",
  "requires_reboot": true
}
```

```json
{
  "name": "nxsh",
  "tid": "43000000000000FF",
  "requires_reboot": false
}
```

```json
{
  "name": "ojds-nx",
  "tid": "0100000000000901",
  "requires_reboot": false
}
```

```json
{
  "name": "sys-botbase",
  "tid": "430000000000000B",
  "requires_reboot": true
}
```

```json
{
  "name": "USB-Botbase",
  "tid": "430000000000000B",
  "requires_reboot": true
}
```

```json
{
  "name": "sys-netcheat",
  "tid": "430000000000000A",
  "requires_reboot": false
}
```

```json
{
  "name": "sys-tune",
  "tid": "4200000000000000",
  "requires_reboot": false
}
```

例えば、SysDVR や sys-botbase を有効化するためには上のように書けば OK です。ただし、Tesla で制御される sys-tune のようなモジュールはこれらの方法で有効化すると CFW がクラッシュするので記述してはいけません。

記事は以上。
