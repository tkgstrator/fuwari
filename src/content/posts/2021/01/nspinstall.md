---
title: "[2021年決定版] CFWにNSPをインストールしよう"
published: 2021-01-17
description: No description
category: Hack
tags: [CFW]
---

## NSP をダンプしよう

どうにもこうにも、まずはインストールするための NSP を手に入れなければいけません。

NSP はゲームのカートリッジ、または eShop からダウンロードしたダウンロード版ゲームや体験版や DLC、または配布されたアップデートなどが該当します。

NSP をゲームから抽出するには[HACGUI](https://github.com/shadowninja108/HACGUI)か[NXDumpTool](https://github.com/DarkMatterCore/nxdumptool)を使うのが基本的な手順となりますが、この際に署名付きでダンプしないとパッチをあてていない CFW ではインストールができないので以下の手順を読んで正しく署名付きで NSP を作成するようにしてください。

HACGUI と NXDumpTool の使い方は上のリンク参照！

### NSP の抽出の手順

以下の表が HACGUI と NXDumpTool の比較表です

|                |      HACGUI      |        NXDumpTool        |
| :------------: | :--------------: | :----------------------: |
| カートリッジ版 |        ×         | △ <br> ※署名にバグあり？ |
| ダウンロード版 | △ <br> ※制限あり | ◯ <br> ※オプションが必須 |
|  アップデータ  |        ◯         |            ◯             |
|      DLC       |        ◯         |            ◯             |

◯ は署名付きで正しくダンプし、パッチをあてていない CFW でインストール可能な NSP が作成できることを意味しています。じゃあ気になる △ はなんなのかということになるわけです。

**NXDumpTool でカートリッジ版をダンプ**

署名付きで正しくダンプしたつもりでも、スプラトゥーンの場合は何故か署名でエラーを吐かれてインストールすることができません。

カートリッジ版を無理やりダウンロード版の NSP として扱っているのが良くない可能性があります。

HACGUI はそもそもカートリッジ版をダンプすることができないので、この問題は発生しません。

**HACGUI でダウンロード版をダンプ**

HACGUI でダウンロード版をダンプすると署名付き NSP ができるのですが、この署名は personalized ticket と呼ばれるチケットでありダンプした NAND でしか効果を発揮しません。

なので、例えば SysNAND で eShop からゲームをダウンロードし、それを EmuNAND にインストールしようとした場合は、一度でも EmuNAND 側で本体の初期化などで内部 ID が変わるような操作をしているとゲームが起動できなくなります。

よっって、このケースでは HACGUI は実際には使い物にならないケースが多いです。

**NXDumpTool でダウンロード版をダンプ**

NXDumpTool にはダウンロード版の personalized ticket を common ticket に変換する機能が備わっています。

この署名変換機能があるおかげで、ダウンロード版のゲームを Sigpatch なしに起動することができるようになります。

## 非署名の NSP をインストールしたい

さて、ここまでを読めばわかると思うのですがどうもカートリッジ版から署名付きの NSP をダンプすることは難しいようです。以前は WEIN DUMPER と呼ばれるカートリッジからダンプする専用のアプリがあったのですが、libnx の更新に対応していないのか最新版の CFW では動作しません。

また、自作アプリでも NRO ではなく NSP として配布しているものがあり、それらは当然任天堂公式の署名がされていないのでインストールすることができません。

そこで、非署名の NSP をインストールする仕組みが考えられました。それが、Sigpatch です。

### [Sigpatch Updater](https://github.com/ITotalJustice/sigpatch-updater)

Sigpatch を GitHub のリリースページから自動で取得してくれるアプリがあります。

それがこの Sigpatch Updater で、これ自体は既に更新が停止してしまっているのですが、パッチは更新されているので常に最新のパッチをあてることができます。

パッチは FW のバージョンと CFW のバージョン（より具体的には Atmosphere のバージョン）で動作するかしないかが決まってくるので、FW や CFW（または DeepSea）などをアップデートした場合には、再度 Sigpatch Updater を起動して最新のパッチをあてるようにしてください。

当然ですが、リリース直後はその FW や CFW に対するパッチに更新されていない場合もあります。

### hekate_ipl.ini

Sigpatch Updater は Sigpatch をダウンロードしてくれますが、有効化はしてくれないのでパッチを読み込むように hekate_ipl.ini を更新する必要があります。

特に難しいことはなくて、以下のように書き換えれば Sigpatch を読み込んでくれます。

```
[config]
autoboot=0
autoboot_list=0
bootwait=3
verification=1
backlight=100
autohosoff=0
autonogc=1
updater2p=1

{DeepSea/DeepSea v1.9.4}
{}
{Discord: invite.sdshrekup.com}
{Github: https://github.com/orgs/Team-Neptune/}
{}

{--- Custom Firmware ---}
[CFW (EMUMMC)]
emummcforce=1
kip1patch=nosigchk
fss0=atmosphere/fusee-secondary.bin
atmosphere=1
logopath=bootloader/bootlogo.bmp
icon=bootloader/res/icon_payload.bmp
kip1=atmosphere/kips/*
{}

{--- Stock ---}
[Stock (SYSNAND)]
emummc_force_disable=1
fss0=atmosphere/fusee-secondary.bin
stock=1
icon=bootloader/res/icon_switch.bmp
{}
```

これは DeepSea 1.9.4 向けの hekate_ipl.ini ですが、他のバージョンでも（極端に hekate のバージョンが低くなければ）同じ書き方で動作すると思います。

## まとめ

ここだけ読めばなんとかなるやろページが完成しました。

正直、Sigpatch ってなんかいろいろ派生があってよく分かってないんですよね。

そういえばこの前海外ドキュメントを読み漁っていたら Atmosphere から最新の Sigpatch を作成するためのコマンドみたいなのも見た気がするんですが、履歴の彼方にとんでいってしまったのでわからなくなってしまいました。

ニンテンドースイッチ向けの自作アプリって今まで一度も作ったことがないのでチャレンジしてみたいんですが、どこかにチュートリアルとかありませんかね？

記事は以上。
