---
title: EC2のボリュームサイズを変更する　 
published: 2024-04-16
description: インスタンスの種類によってはボリュームサイズが小さいのでそれを拡張します
category: Tech
tags: [AWS]
---

## 概要

まずはインスタンスのタイプを変更する方法から、まとめます。

インスタンスが動いていると種類を変えられないので、一度止めます。

インスタンスを止めるのはTerminateではなくStopです、いいね？

止めたら**Actions > INstance settings > Change instance type**からインスタンスの種類を変更します、簡単です。

### ボリュームサイズの変更

EC2インスタンスの主催を見ているときに**Storage > Block devices**から紐付けられているVolumeを見ます。

ここでサイズが8GBだったので、とりあえず32GBくらいに拡張しましょう。

どれがどう違うのか欲わからないのですがGeneral Purpose SSDで32GBに変更します。

### システム側の変更

```zsh
$ sudo lsblk
NAME         MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
loop0          7:0    0  24.9M  1 loop /snap/amazon-ssm-agent/7628
loop1          7:1    0  25.2M  1 loop /snap/amazon-ssm-agent/7983
loop2          7:2    0   104M  1 loop /snap/core/16928
loop3          7:3    0  55.7M  1 loop /snap/core18/2812
loop4          7:4    0  63.9M  1 loop /snap/core20/2182
loop5          7:5    0  63.9M  1 loop /snap/core20/2264
loop6          7:6    0  74.2M  1 loop /snap/core22/1122
loop7          7:7    0 130.1M  1 loop /snap/docker/2915
loop8          7:8    0    87M  1 loop /snap/lxd/27037
loop9          7:9    0    87M  1 loop /snap/lxd/27948
loop10         7:10   0  40.4M  1 loop /snap/snapd/20671
loop11         7:11   0  39.1M  1 loop /snap/snapd/21184
nvme0n1      259:0    0    32G  0 disk 
├─nvme0n1p1  259:1    0   7.9G  0 part /
├─nvme0n1p14 259:2    0     4M  0 part 
└─nvme0n1p15 259:3    0   106M  0 part /boot/efi
```

以下のコマンドを利用してUbuntuが認識できるシステム領域を拡張します。

```zsh
$ sudo growpart /dev/nvme0n1 1
CHANGED: partition=1 start=227328 old: size=16549855 end=16777183 new: size=66881503 end=67108831
```

すると、

```zsh
NAME         MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
loop0          7:0    0  24.9M  1 loop /snap/amazon-ssm-agent/7628
loop1          7:1    0  25.2M  1 loop /snap/amazon-ssm-agent/7983
loop2          7:2    0   104M  1 loop /snap/core/16928
loop3          7:3    0  55.7M  1 loop /snap/core18/2812
loop4          7:4    0  63.9M  1 loop /snap/core20/2182
loop5          7:5    0  63.9M  1 loop /snap/core20/2264
loop6          7:6    0  74.2M  1 loop /snap/core22/1122
loop7          7:7    0 130.1M  1 loop /snap/docker/2915
loop8          7:8    0    87M  1 loop /snap/lxd/27037
loop9          7:9    0    87M  1 loop /snap/lxd/27948
loop10         7:10   0  40.4M  1 loop /snap/snapd/20671
loop11         7:11   0  39.1M  1 loop /snap/snapd/21184
nvme0n1      259:0    0    32G  0 disk 
├─nvme0n1p1  259:1    0  31.9G  0 part /
├─nvme0n1p14 259:2    0     4M  0 part 
└─nvme0n1p15 259:3    0   106M  0 part /boot/efi
```

無事に32GB認識していることが確認できました。

### 割当

ところがこれだけで終わりではありません。

```zsh
$ df
Filesystem      1K-blocks    Used Available Use% Mounted on
/dev/root         7941576 5767644   2157548  73% /
tmpfs             3999540       0   3999540   0% /dev/shm
tmpfs             1599820    1012   1598808   1% /run
tmpfs                5120       0      5120   0% /run/lock
efivarfs              128       4       120   4% /sys/firmware/efi/efivars
/dev/nvme0n1p15    106832    6186    100646   6% /boot/efi
tmpfs              799908       4    799904   1% /run/user/1000
```

`df`コマンドを実行すればわかるのですが`/dev/root`には8GBしか割り当てられていません。

ここでファイルシステムの種類のよって実行するコマンドが異なるのですが、ext4を使っている場合には、

```zsh
$ sudo resize2fs /dev/nvme0n1p1
resize2fs 1.46.5 (30-Dec-2021)
Filesystem at /dev/nvme0n1p1 is mounted on /; on-line resizing required
old_desc_blocks = 1, new_desc_blocks = 4
The filesystem on /dev/nvme0n1p1 is now 8360187 (4k) blocks long.
```

を実行すれば正しく割り当てられます。

もしもxfsを使っている場合には代わりに`sudo xfs_growfs -d /`を実行してみてください。

詳しいドキュメントについては[ここ](https://docs.aws.amazon.com/ebs/latest/userguide/recognize-expanded-volume-linux.html)に載っています。

記事は以上。