---
title: Ubuntu+MirakcでPX-S1UDを動かそう
published: 2024-12-08
description: 自宅にTV録画サーバーを立ててみました
category: Tech
tags: [Mirakurun, Docker]
---

## 概要

自宅にテレビをどこからも見れるいわゆるロケフリ環境をUbuntu+PX-S1UD v2.0で作成しました。

### 必要なもの

- Ubuntu 22.04.5 LTS
- PX-S1UD v2.0
- GTX 1070
- SCR3310/v2.0
  - B-CAS

どれもありふれたものなので簡単に手に入ると思います。

グラフィックボードはハードウェアエンコードを利用するために使っていますが、NVEncは同時に処理できるストリームが二つという制限があるとかないとかという話をきいたので、QSVの方がひょっとしたら便利かもしれません。

ただ、画質面と速度ではNVEncの方がちょっといいともきいたので、ちょうどうちに余っていた7000円くらいで買ったGTX 1070を利用することにしました。

```zsh
$ lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 22.04.5 LTS
Release:        22.04
Codename:       jammy
```

ちなみにUbuntuのバージョンは22.04.5でした。

PX-S1UDは地上デジタル放送にしか対応していないのでBSやCSは見ることができません。

### ISDBScanner

ラズパイでなければ基本はamd64だと思いますのでそちらの方法だけ載せておきます。

```zsh
wget https://github.com/kazuki0824/recisdb-rs/releases/download/1.2.2/recisdb_1.2.2-1_amd64.deb
sudo apt-get install ./recisdb_1.2.2-1_amd64.deb
rm ./recisdb_1.2.2-1_amd64.deb
```

としてresicdbをインストールします。

```zsh
sudo wget https://github.com/tsukumijima/ISDBScanner/releases/download/v1.2.0/isdb-scanner -O /usr/local/bin/isdb-scanner
sudo chmod +x /usr/local/bin/isdb-scanner
```

これで実行権限がついたisdb-scannerがインストールされます。

```zsh
$ isdb-scanner
========================================================================= ISDBScanner version 1.2.0 =========================================================================
Scanning ISDB-T (Terrestrial) channels...
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Failed to open tuner device: [Errno 13] Permission denied: '/dev/dvb/adapter0/frontend0'
Failed to open tuner device: [Errno 13] Permission denied: '/dev/dvb/adapter0/frontend0'
No ISDB-T tuner found.
Please connect an ISDB-T tuner and try again.
=============================================================================================================================================================================
Scanning ISDB-S (Satellite) channels...
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Failed to open tuner device: [Errno 13] Permission denied: '/dev/dvb/adapter0/frontend0'
Failed to open tuner device: [Errno 13] Permission denied: '/dev/dvb/adapter0/frontend0'
No ISDB-S tuner found.
Please connect an ISDB-S tuner and try again.
Failed to open tuner device: [Errno 13] Permission denied: '/dev/dvb/adapter0/frontend0'
Failed to open tuner device: [Errno 13] Permission denied: '/dev/dvb/adapter0/frontend0'
Failed to open tuner device: [Errno 13] Permission denied: '/dev/dvb/adapter0/frontend0'
=============================================================================================================================================================================
Finished in 0.02 seconds.
```

単純に実行しようとするとデバイスへのアクセス権限がなくて怒られます。なので`sudo`をつけて実行しましょう。

するとscannedディレクトリの以下に次のようなファイルが作成されます。

今回使うのは`config.yml`になります。

```bash
scanned/
└── mirakc/
    ├── config_recpt1.yml
    └── config.yml
```

### mirakc

mirakcはMirakurunのクローンでRustで記述された非常に高速で軽量なソフトウェアです。

CPU利用率が低く、メモリ使用量がMirakurunの1/4程度と要求されるスペックも非常に低いのが特徴です。

で、本来はmirakcを動かすにはB-CASカードが必要なのですが物理カードを使ってストリームを復号すると処理速度が足りずにCS放送などではドロップしてしまう問題があるので、B-CASカードをエミュレートできるSoftcasを利用するという方法もあるようです。

ただ、Softcasはいろいろとアレなので一般的に公開はされていないようです。インターネットの広大な海を探して頑張って見つける必要がありそうです。

今回の場合は`PX-S1UD`がそもそもBS/CS放送に対応していないのでSoftcas自体があまり必要になっていないのでここはスキップします。
