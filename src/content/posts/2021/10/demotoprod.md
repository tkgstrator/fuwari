---
title: スプラ体験版を製品版に変更しよう
published: 2021-10-02
description: スプラトゥーンのリージョンを強制変更して体験版を製品版として遊ぶためのチュートリアルです
category: Hack
tags: [Splatoon2]
---

# [スプラ'20 体験版](https://ec.nintendo.com/JP/ja/titles/70010000030995)

4 月 30 日～ 5 月 6 日までの一週間、スプラトゥーンの体験版が任天堂 eShop から無料でダウンロードできます。

基本的には七日制限がある以外は製品版と同じように遊べるのですが、体験版にはいくつかの制限があります。

- ヒーローモードで遊べない
- イカッチャで遊べない
- 5 月 6 日以降オンラインに繋げない

要するに、オフラインでも遊べる機能が無効化されているわけです。

まあオフライン機能を無効化しておかないと、体験期間が終わってからも遊べてしまうので仕方ないですよね。

ということで、スプラの体験版は 5 月 6 日以降も起動はできるのですがインターネット接続ができずオフラインモードで遊べないということは実質遊べないのと同じなわけです。

で、その制限を取っ払ってしまおうというのが今回の目的です。



## 体験版の中身

スプラ体験版はスプラトゥーン 1.0.0 の基本データに 5.2.0 のアップデータが適応されたものが配布されています。

なので、データとしては完全に 5.2.0 と同一なのです。ではどうして体験版としての制限がかかっているかというと、あるファイルによってリージョンが決められているからです。

### RegionLangMask.txt

`romfs/System/RegionLangMask.txt`こそがスプラトゥーンのリージョンを決定しているファイルです。

| コード  | 意味            |
| ------- | --------------- |
| JPja    | JP 版日本語     |
| USen    | NA 版英語       |
| USes    | NA 版スペイン語 |
| USfr    | NA 版フランス語 |
| EUen    | EU 版英語       |
| EUes    | EU 版スペイン語 |
| EUfr    | EU 版フランス語 |
| EUde    | EU 版ドイツ語   |
| EUit    | EU 版イタリア語 |
| EUnl    | EU 版オランダ語 |
| EUru    | EU 版ロシア語   |
| TrialJP | JP 体験版       |
| TrialUS | NA 体験版       |
| TrialEU | EU 体験版       |

NA 版を EU 版、JP 版を EU 版といったように違うリージョンには変更できないのですが、同じリージョンであれば自由に変更できます。

つまり、TrialUS を USen に変更することは可能だということです。

## NXDumpTool を使った方法

NXDumpTool を使うには Lockpick で prod.keys を習得する必要があるので、先にやっておきましょう。

![](https://pbs.twimg.com/media/EW6B9RLX0AAp1K-?format=jpg&name=large)

スプラの体験版はゲームカードではないので「Dump installed SD card / eMMC content」を選択。

![](https://pbs.twimg.com/media/EW6B9jGXQAAzEz5?format=jpg&name=large)

インストールされているスプラの体験版を選択。

![](https://pbs.twimg.com/media/EW6B91PX0AAGsm4?format=jpg&name=large)

「RomFS options」を選択。

![](https://pbs.twimg.com/media/EW6B-DHXQAAr02x?format=jpg&name=large)

「Save data to CFW directory (LayeredFS)」は Yes にしておいた方が自動でフォルダつくってくれるので多分楽です。

Yes に変更したら「Browse RomFS section」を選択します。

![](https://pbs.twimg.com/media/EW6B-o3XYAQ4fzT?format=jpg&name=large)

一番下の「System」を選択します。

![](https://pbs.twimg.com/media/EW6Dd7NWsAwz2U0?format=jpg&name=large)

「RegionLangMask.txt」を選択します。

![](https://pbs.twimg.com/media/EW6B--wWAAA7EUQ?format=jpg&name=large)

出力できたらおしまいです。

### RegionLangMask.txt の編集

FTP でファイルを転送して編集して上書き保存すれば反映されます。

記事は以上。


