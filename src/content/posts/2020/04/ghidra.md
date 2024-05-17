---
title: "Ghidraでのコード移植"
published: 2020-04-20
description: NSAが公開した逆アセンブラツールであるGhidraを使ってIPSwitchのコードを別バージョンに移植するための手順や注意点について簡単に解説しています
category: Nintendo
tags: [Salmon Run, IPSwitch, Ghidra]
---

## [Ghidra](https://github.com/NationalSecurityAgency/ghidra)

NSA が開発した逆アセンブラツール。

しかも無料というのだから、これまたすごいの一言です。

IDA Pro はものすごく便利なツールですが、ライセンス料が高いので導入のハードルがかなり高いです。

なので、今回は Ghidra でのコード移植のやり方を紹介します。

::: tip

IDA Pro でできることのほとんどが Ghidra でできます。

:::

### JDK

Ghidra の実行には JDK（JAVA）が必要なので、公式サイトからインストールしましょう。

[Java Archive Downloads - Java SE 11](https://www.oracle.com/java/technologies/javase/jdk11-archive-downloads.html)

インストールが終わったら Path を通してください。

### メモリの変更

Ghidra はデフォルトでは 1024MB しかメモリを使ってくれないのですが、これだとメモリが足りずに解析失敗するかもしれないので最低でも 2048MB は確保したほうがいいでしょう。

**ghidraRun.bat**

```
:: Ghidra launch

@echo off
setlocal

:: Maximum heap memory size
:: Default for Windows 32-bit is 768M and 64-bit is 1024M
:: Raising the value too high may cause a silent failure where
:: Ghidra fails to launch.
:: Uncomment MAXMEM setting if non-default value is needed

set MAXMEM=2048M

call "%~dp0support\launch.bat" bg Ghidra "%MAXMEM%" "" ghidra.GhidraRun %*


```

こんな感じでコメントを外して好きな値をいれれば OK。

一応 1024MB でも解析できたけど、余裕があるならそれ以上に設定しておこう。

## Ghidra の使い方

いくつかのパートに分けて Ghidra の使い方を解説していきたいと思います。

### Loader の導入

NSO をそのまま読み込むには Loader が必要なのですが、今現在の最新の[Ghidra-Switch-Loader](https://github.com/Adubbz/Ghidra-Switch-Loader/releases/tag/1.4.0)は[Ghidra 9.1.2](https://github.com/NationalSecurityAgency/ghidra/releases/tag/Ghidra_9.1.2_build)にしか対応していないため、旧バージョンを使う必要があります。

インストール出来たら Ghidra を起動して File -> Install Extension を選択してください。

右上の + ボタンを押して、ダウンロードした zip ファイルを直接指定してください。

Ghidra の再起動が要求されると思うので、再起動しましょう。

::: tip

この作業は ELF を分析する場合は不要です。

復号は[nx2elf](https://github.com/tkgstrator/nx2elf)ですることができます。

:::

### バイナリの分析

まずは実行ファイルである NSO/ELF を分析します。

起動するとプロジェクトを作成するように指示されます。プロジェクト名は適当に決めてしまいましょう。

次に、分析するファイルをドラッグアンドドロップするか、Select File Import からファイルを選択してください。

[ファイル名] has not been analyzed. Would you like to analyze it now?（分析済みではないので分析しますか？）というダイアログが表示されるので Yes を選択します。

Analysis Options はとりあえずデフォルトでチェックが入っているものだけにしました。デフォルトで全く問題なかったので多分これでオッケー。

Analyze をクリックすると分析が始まります。右下の表示で分析中なことがわかりますね。

分析のスピードは使用しているマシンの CPU のスペックに依存します。

i7 6700K で実行したところ約 20 分くらい、MacBook Pro 2019 だと 40 分くらいかかりました。気長に待ちましょう。

## コードの移植

移植に関して言えば基本的に命令部は弄る必要がないので、正しいアドレスの位置さえ指定してあげれば良いことになります。

### バイト検索

長くなるので時間ができたときに書きます。

### 文字列検索

文字列検索を利用するコード移植の例としては試し打ち場の置換などが上げられます。では、その方法を解説しましょう。

```
// ShootingRange Replacements (5.0.0) [AmazingChz]
@disabled
023FCACA "Fld_Crank00_Vss"
```

試し打ち場のパラメータ名は`Fld_ShootingRange_Shr`なのでそれを検索してみましょう。

Search -> Program Text を開きます。

Labels にチェックを入れましょう。

Next と Previous は現在のカーソルからの相対位置で検索し、Search All は全範囲で検索します。

Ghidra で NSO を直接分析した場合にはアドレスが 7100000000 ズレる事がわかっているので、仮に 7102412414 見つかったとしたら、IPSwitch 形式だと 02412414 となるわけです。

```
// ShootingRange Replacements (5.0.1) [AmazingChz]
@disabled
02412414 "Fld_Crank00_Vss"
```

```
Urchin Underpass = Fld_Crank00_Vss
Saltspray Rig = Fld_Seaplant00_Vss
Museum d'Alfonsino = Fld_Pivot00_Vss
Mahi-Mahi Resort = Fld_Hiagari00_Vss
Hammerhead Bridge = Fld_Kaisou00_Vss
Flounder Heights = Fld_Jyoheki00_Vss
Ancho-V-Games = Fld_Office01_Vss
Arowna Mall = Fld_UpDown01_Vss
Blackbelly Skatepark = Fld_SkatePark02_Vss
Camp Triggerfish = Fld_Athletic01_Vss
Goby Arena = Fld_Court00_Vss
Humpback Pump Track = Fld_Wave00_Vss
Inkblot Art Academy = Fld_Upland00_Vss
Kelp Dome = Fld_Maze02_Vss
MakoMart = Fld_Line00_Vss
Manta Maria = Fld_Pillar00_Vss
Moray Towers = Fld_Tuzura00_Vss
Musselforge Fitness = Fld_Unduck00_Vss
Piranha Pit = Fld_Quarry02_Vss
Port Mackerel = Fld_Amida01_Vss
Shellendorf Institute = Fld_Tunnel00_Vss
Snapper Canal = Fld_Kawa01_Vss
Starfish Mainstage = Fld_Venue02_Vss
Sturgeon Shipyard = Fld_Nagasaki00_Vss
The Reef = Fld_Ditch02_Vss
Wahoo World = Fld_Carousel00_Vss
Walleye Warehouse = Fld_Warehouse01_Vss
New Albacore Hotel = Fld_Nakasu00_Vss
Skipper Pavilion = Fld_Mirror00_Vss
Lost Outpost = Fld_Shakehouse00_Cop
Marooner's Bay = Fld_Shakeship00_Cop
Salmonid Smokeyard = Fld_Shakelift00_Cop
Spawning Grounds = Fld_Shakeup01_Cop
Staff Roll = Fld_StaffRoll00_Stf
Tutorial = Fld_Tutorial00_Ttr
Old Starfish Mainstage = Fld_Venue00_Vss
Shifty Station = Fld_Deli_Octa51_Vss
```

## オフセット

逆アセンブラの種類と解析するファイルの種類によって ELF を IDA で解析したときに比べてアドレスがズレるのでその値を覚えて置かなければいけません。

| 逆アセンブラ  |  オフセット   |
| :-----------: | :-----------: |
| GHIDRA (NSO)  | +0x7100000000 |
| GHIDRA (ELF)  | +0x0000100000 |
| IDA Pro (NSO) | +0x7100000000 |
| IDA Pro (ELF) |       0       |

## まとめ

というわけで、今回は Ghidra の使い方やコードの移植のやり方について簡単に解説してみました。

もしわからないことがあれば以下のリンクから Discord サーバに参加して、直接きいていただければ返事します。

[LanPlay-JP](https://discord.gg/vUVBJFAKvZ)

記事は以上。
