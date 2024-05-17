---
title: "[Hack] Nosigpatchを簡単に導入するSigpatch Updaterとは"
published: 2021-06-10
description: Sigpatch Updaterの使い方です
category: Hack
tags: [CFW]
---

# Sigpatch とは

> この記事は以前公開していたものを加筆・修正したものになります

当ブログでも再三に渡って説明しているのだが、Atmosphere には海賊版対策として署名のない NSP はインストールも起動もできない仕組みが備わっています。

コレ自体はとても良い機能なのですが、この機能があると自分でカートリッジから NSP をダンプした場合にも署名を保存しておかないとインストールできなくなってしまいます。

Tinfoil のような非公式アプリを Applet Mode 以外で起動させるにも Sigpatch が必要になってきますので、使いたい方は導入必須です。

## [Sigpatch Updater](https://github.com/ITotalJustice/sigpatch-updater)

![](https://pbs.twimg.com/media/EmVSlw_WEAIeXEs?format=png)

ダウンロードした NRO を switch フォルダ以下にコピーするだけです。

![](https://github.com/ITotalJustice/sigpatch-updater/blob/master/images/example.jpg?raw=true)

Kosmos/DeepSea/Hekate ユーザは上から二番目の`Update Sigpatches (For Hekate / Kosmos Users)`を選択しましょう。

GitHub のレポジトリから Sigpatch をダウンロードして SD カード内に展開してくれます。

### Sigpatch を有効化しよう

ここまでの手順では Sigpatch を SD カード内に展開して「利用できる状態」にしてくれるだけなので、実際にそれを読み込んで有効化する必要があります。

SD カード内の`hekate_ipl.ini`を編集して読み込むようにしましょう。

また、このときに CFW(SysNAND)を無効化しておくことを強く推奨します。

```ini
[config]
autoboot=0
autoboot_list=0
bootwait=1
verification=1
backlight=100
autohosoff=0
autonogc=1

{AtlasNX/Kosmos w/ nosigchk}
{}
{Discord: discord.teamatlasnx.com}
{Github: git.teamatlasnx.com}
{Patreon: patreon.teamatlasnx.com}
{Pegascape DNS: pegascape.sdsetup.com}
{}

{--- Custom Firmware ---}
# SYSNAND無効化の時はこの項目を削除
[CFW (SYSNAND)]
emummc_force_disable=1
fss0=atmosphere/fusee-secondary.bin
kip1patch=nosigchk
atmosphere=1
logopath=bootloader/bootlogo.bmp
icon=bootloader/res/icon_payload.bmp
kip1=atmosphere/kips/*
{}
# ここまでを削除

[CFW (EMUMMC)]
fss0=atmosphere/fusee-secondary.bin
kip1patch=nosigchk
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

::: danger 何故 CFW(SysNAND)を無効化するのか

EmuMMC を利用している多くの方は OFW を SysNAND で動かしてオンラインプレイを遊び、CFW は EmuMMC で動かして遊んでいるという方が多いと思います。

オンラインプレイで遊ぶためには 90DNS を設定できないので（設定するとオンラインにつながらない）、SysNAND では 90DNS を設定していないことになります。その状態で誤って CFW で起動してしまうと「オンラインに繋げる=即 BAN」となってしまうため「誤って CFW(SysNAND)を選択すること」が即座に BAN に直結してしまいます。

このようなたった一つのミスで BAN されることを防ぐためにも、SysNAND で CFW を読み込むような設定はオフにすべきです。

:::

## [AIO-Switch-Updater](https://github.com/HamletDuFromage/aio-switch-updater)

hekate_ipl.ini を編集するのがめんどくさい方向けに AIO-Switch-Updater というものがリリースされています。

![](https://user-images.githubusercontent.com/61667930/107124480-7a41f400-68a4-11eb-9a01-d7b3c9f3e828.jpg)

このツールは、

- Atmosphere のアップデート
- CFW のアップデート
- Sigpatch のアップデート
- Firmware のダウンロード
- チートコードのダウンロード

に対応しています。要するに、これだけあれば大体なんでもできます。

めんどくさがりな方はこっちでも良いかもしれません。

## Sigpatch を使いたくない方のために

いちいち Sigpatch を使うのがめんどくさいという方はそもそも NSP をダンプするときに証明書（Ticket）付きでダンプすれば良いです。

ゲームのバックアップを NSP で保存するためには[NXDumpTool](https://github.com/DarkMatterCore/nxdumptool)というツールを使うのが最も手っ取り早いです。

NXDumpTool の使い方に関しては[この記事](https://tkgstrator.work/posts/2021/06/10/nxdumptool.html)で解説しているのでどうぞ。
