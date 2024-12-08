---
title: Ubuntu+MirakurunでPX-S1UDを動かそう
published: 2024-12-08
description: 自宅にTV録画サーバーを立ててみました
category: Tech
tags: [Mirakurun, Docker]
---

## 概要

ネットの海を探すとラズパイ+Mirakurun+Dockerの記事はたくさん見かけるのですが、うちはミニPCが余っているのでそれを利用しました。

N100のデバイスはいくつかあるのですが、それだと少々非力な可能性があったので手持ちの中で一番スペックの高そうなU5700搭載のマシンで実行してみることにしました。

### 必要なもの

- Ubuntu 22.04.5 LTS(U5700)
- PX-S1UD v2.0
- Mirakurun
- EPGStation
- SCR3310/v2.0
- B-CASカード(赤)

どれもありふれたものなので簡単に手に入ると思います。

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

