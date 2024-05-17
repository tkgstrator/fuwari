---
title: "[Hack] 疑似ダウングレード用のファイルを作成する"
published: 2021-01-06
description: No description
category: Nintendo
tags: [Nintendo Switch]
---

## ダウングレードの必要性

ニンテンドースイッチにおいてゲームをダウングレードすることのメリットはあまりありません。

というのも、最新のバージョンでないとオンライン対戦はできませんし、イカッチャなどの LanPlay でさえバージョンが異なるとできないためです。

パッチなども最新のバージョンで動くように日々改良されていっているので、更新が止まっているなどの特殊な場合を除いて最新のバージョンにアップデートして困ることはありません。

では、なぜダウングレードをするのでしょうか？

それは、スプラトゥーンにおいてバージョン 3.1.0 でないと Starlight（Starlion を含む）が動作しないためです。

## 疑似ダウングレードが求められるワケ

しかし、ダウングレード自体は該当するバージョンの NSP を持っていれば難しいことはありません。

Goldleaf や Tinfoil などの NSP インストーラがあれば簡単にバージョンを下げることができます。

なぜ、ここで完全なダウングレードではなく、疑似ダウングレードが求められるのでしょうか？

それは、（ゲームにもよりますが）完全なダウングレードをしてしまうとセーブデータのバージョンの不整合から「最新のアップデータを適応してください」というエラーが表示されて低いバージョンのゲームを起動することができなくなってしまうためです。

例えば、スプラトゥーンの場合ですと今まで起動した中で最も新しいバージョンの情報が NAND に刻まれているために、本体を初期化させるか、Goldleaf などで起動バージョンのリセットなどしない限りダウングレードしたバージョンを起動させることができなくなります。

最新のバージョンで遊ぶのと、古いバージョンで改造を研究するのとを切り替えるために毎回本体を初期化/アップデータの再インストールしていてはめんどくさいことこの上ないわけです。

## 疑似ダウングレード用のファイルの作成

ここではスプラトゥーンのダウングレードを前提に話を進めていきます。

スプラトゥーン以外でも手法としては全く同じなので同様の手順でダウングレードできます。

### 必要なもの

1. 1.0.0 の NSP または NCA
2. ダウングレードしたいバージョンの NSP または NCA
3. 該当する title.keys

絶対に持っていなければいけないのはこの三つです。

ゲームのカートリッジがあれば 1.0.0 は簡単に入手できるので、問題は 3.1.0 の NSP を入手できるかになります。リージョン（JP 版、NA 版、EU 版）は問わないのでどれでも好きなバージョンで構いません。

title.keys に関しては用意した NSP が EU 版であれば EU 版のタイトルキー、NA 版であれば NA 版のタイトルキーが必要になります。

1.0.0 が JP 版、3.1.0 が NA 版といったハイブリットも可能ですが、この場合は JP 版と NA 版の二つのタイトルキーが必要になります。

タイトルキーに関しては Lockpick で抜き出しても良いですが、ググるとインターネットの広大な海にぽつんと落ちていたりするのでそちらでも構いません。

最終的に以下のような形式の title.keys が得られたら大丈夫です。

```
01003BC0000A08000000000000000003 = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
01003C700009C8000000000000000003 = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
0100F8F0000A28000000000000000003 = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```

あとはこの title.keys を.switch というフォルダの中にコピーします。

[HACGUI](https://github.com/shadowninja108/HACGUI)を一度でも使った事があれば既に title.keys が.switch フォルダ内に作られているのでこの作業は不要だったりします。

`C:\Users\<USER NAME>\.switch`

.switch フォルダはミュージックとかピクチャのフォルダがあるところと同じところに作成します。

![](https://pbs.twimg.com/media/Eq_Vy5zVQAAwbqm?format=png)

### 追加で必要なもの

1. [hactool](https://github.com/SciresM/hactool)
2. [hacotoolnet](https://github.com/Thealexbarney/LibHac)
3. [7-Zip](https://sevenzip.osdn.jp/)

NSP を展開するのに hactool を使うので、既に NCA として持っている場合は hactool は不要です。

hacotoolnet は NCA からバイナリファイルを作るために使い、7-Zip はそのバイナリファイルを FAT32 で扱えるように分割するために使います。

![](https://pbs.twimg.com/media/Eq_N-haVkAAxszt?format=png)

とりあえず必要な 7-Zip をインストールした上で、NSP のファイル名を 310.nsp と 100.nsp に変えておきましょう（わかりやすくするためで、必須ではないです）

![](https://pbs.twimg.com/media/Eq_OMZTUwAAsGRI?format=png)

ZIP を解凍して実行ファイルを展開できたら、いよいよダウングレード用のファイルの作成開始です。

### NSP を NCA に展開しよう

hactool を使って NSP から NCA を抽出するためのコマンドを載せておきますので、これを適当な名前のバッチファイルとして保存してください。

```
hactool -t pfs0 --pfs0dir=%~n1 %1
```

あとは、このバッチファイルに NSP をドラッグアンドドロップすれば NCA として抽出してくれます。

![](https://pbs.twimg.com/media/Eq_Rtt9VkAAdnnN?format=png)

抽出した NCA のうち、最も大きなものをそれぞれ 100.nca、310.nca という風にリネームします。

![](https://pbs.twimg.com/media/Eq_R2m3VkAANdK6?format=png)

### 3.1.0 の main を取り出す

コマンドプロンプトを開いて以下のコマンドを入力します。

```
hactool -t nca --exefsdir=exefs 310.nca
```

すると exefs というフォルダの中に 3.1.0 の実行ファイル（main）が展開されます。

![](https://pbs.twimg.com/media/Eq_lUMPVgAAY8fX?format=png)

### NCA からバイナリ作成

```
hactoolnet 310.nca --basenca 100.nca --romfs romfs.bin
```

次に、上のコマンドをコマンドを入力します。

先程 NCA のリネームをしたのはここでダラダラと長いコマンドを打つのがわかりにくかったからです。

![](https://pbs.twimg.com/media/Eq_bhkIUwAEUS5R?format=png)

すると 4GB くらいのバイナリファイルが完成します。

ここで問題となるのは 4.7GB のファイルは FAT32 のフォーマットにコピーできないというところです。

なのでこの romfs.bin を FAT32 で扱えるように分割しなきゃいけないわけです。

### 7-Zip で分割する

7-Zip を起動して romfs.bin をひらきます。

![](https://pbs.twimg.com/media/Eq_cOrqU0AEWvk-?format=png)

romfs.bin に辿り着いたら右クリックから「ファイル分割」を選択します。

![](https://pbs.twimg.com/media/Eq_clnTUYAAUGlP?format=png)

![](https://pbs.twimg.com/media/Eq_cxA0VgAALOse?format=png)

ファイルサイズは「4294901760」を指定します。

![](https://pbs.twimg.com/media/Eq_ddCBVEAAgwn3?format=png)

![](https://pbs.twimg.com/media/Eq_fadLVoAAa3Dq?format=png)

ファイル分割をすると romfs.bin.001 と romfs.bin.002 というファイルができると思うのでこれらをそれぞれ 00 と 01 にリネームします。

![](https://pbs.twimg.com/media/Eq_fjR-U0AAMTcQ?format=png)

リネームができたら romfs.bin を削除した上で romfs.bin という名前のフォルダを作成し、フォルダの中に 00 と 01 のファイルを移動させます。

すると、以下の六つのファイルができているはずです。

```
romfs.bin/00

romfs.bin/01

exefs/main

exefs/main.npdm

exefs/rtld

exefs/sdk
```

### ハッシュチェック

次に、ファイルのハッシュチェックを行います。

ダウングレード用のファイルに少しでもミスがあれば起動しなくなるためです。用意したファイルが正しいものかどうか事前に調べておくことで「ファイルの作成ミス」なのか「ファイルの配置ミス」なのかがわかるというわけです。

今回用意した 00 と 01 のファイルと exefs フォルダ内の各ファイルを右クリックして「CRC SHA」から「SHA-256」を選択します。

```
romfs.bin/00
SHA256: 05D93198CC6E2A00FC44121B108545C5D055C21B3DB4C6079428A4DD5313C79B

romfs.bin/01
SHA256: 8BAC3E94995A71F26A7C9068EEA274B6E58706361023B68B8E9DC766D8554F6F

exefs/main
SHA256: 01D6121F0B4736337F1B8AB6CA51B3EEE74E29B27A88185026BB71E6599D5F72

exefs/main.npdm
SHA256: C714AA2B91D50E9F12DC2EEACA637D3F1D39B0EFAD0E76FC3C0A806132782F41

exefs/rtld
SHA256: 3522D56DDA056D4C7BA6F9508D6D1805D9A751B5A189A8700F9714CE06FB6C5A

exefs/sdk
SHA256: 1AD3BA3CB35303A7C713231F2E49346EF40C42DEB8A7526B6305A0B6358282FD
```

ここの値が異なっている場合はファイルが壊れているか、手順のどこかを間違っている可能性があります。

### アーカイブ化する

このままだと単に romfs.bin というフォルダの中に 00 と 01 というファイルが入っている状態になってしまうので、romfs.bin というフォルダをファイルとして扱えるようにアーカイブ化します。

![](https://pbs.twimg.com/media/Eq_mlG2VkAAr7Kh?format=png)

といってもやることは簡単で、romfs.bin のフォルダを開いてから詳細設定を開いて「アーカイブする」にチェックを入れるだけです。

![](https://pbs.twimg.com/media/Eq_mwhYUwAAEmhj?format=png)

チェックを入れられたら、ダウングレード用のファイルの作成は完了です。

### ファイルのコピー

ここまでできたらあとはダウングレード用のファイルを`sdmc:/atmosphere/contents/titleid`にコピーするだけです。

titleid にはダウングレードしたいスプラトゥーンの ID を入力しましょう。

この手法の便利なところは先ほど作成したダウングレード用のファイルはどのリージョンに対しても使えるということです。

つまり、JP 版の 3.1.0 の NSP から作ったファイルで NA 版や EU 版をダウングレードすることもできます。

しかも、製品版だけでなく体験版でさえもダウングレード可能なので、（中身は 5.2.0 相当）を 3.1.0 にすることもできます。

今回の手順で一番詰まると思うのは romfs.bin が正しくアーカイブとして認識されないことだと思うのですが、Goldleaf でひらいたときに romfs.bin がフォルダではなくファイルとして認識されていればアーカイブ化は成功しています。

![](https://pbs.twimg.com/media/Eq_o_dPVEAEAeQQ?format=png)

記事は以上。
