---
title: "5.4.0を解析する"
published: 2021-02-24
category: Nintendo
tags: [Splatoon2, Salmon Run, IPSwitch]
---

## 基本情報

暇だったのでたかはる氏と Yajii2 さんとコード移植をしていました。

```
@nsobid-32A8F031861B76DF3D1080E6A52FE0B0
#Splatoon 2 5.4.0
#You could be banned by using these hacks, use it at your own risk
################################################
#Proudly ported by Takaharu, Yajii2 and tkgling#
################################################

@flag offset_shift 0x100
```

### コードの配布場所

[スプラトゥーン 2 チートコード](https://takaharu422.github.io/Splatoon2.github.io/ja.html)

### パッチの使い方

[[Hack] IPSwitch の使い方](https://tkgstrator.work/posts/2019/04/01/ipswitch.html)

## おまけ

オンラインで使っても意味がないコードを紹介します。

```
// Coop Online LanPlay [tkgling]
@disabled
014C821C E87D00D0
014C8220 081D2E91
014C824C ACE0FF97
```

BCAT から読み込んだデータでサーモンランのマッチング画面に遷移します。

3.1.0 等であればワンオペでもゲームが始まったのですが、5.4.0 ではワンオペコードを入れていてもゲームを開始できませんでした。

これは LanPlay でも LocalPlay でも同じだったので、別の問題の気がしています。

```
// Coop Online LanPlay [tkgling]
@disabled
0072ED84 E0031FAA
```

これも不完全なコードで、サーモンランを始めると虚無状態でスタートします。

上手くやれば BCAT のデータで遊べると思うのですが、残念。

## 自動ジェネレータ

```
# -*- coding: utf-8 -*-
import os

INFILE = "531.pchtxt"
OUTFILE = "540.pchtxt"

if __name__ == "__main__":
try:
INPUT = os.getcwd() + "/" + os.path.basename(INFILE)
OUTPUT = os.getcwd() + "/" + os.path.basename(OUTFILE)

with open(OUTPUT, mode="w") as fw:
with open(INPUT, mode="r") as f:
for line in f:
code = line.split(" ")
try:
if int(code[0[, 16) >= int("0x00DCA814", 16) and int(code[0[, 16) < int("0x01493350", 16):
data = hex(int(code[0[, 16) - int("0x10C", 16))[2:[.upper()
address = data.zfill(8) + " " + line[9:[
fw.write(address)
else:
fw.write(line)
except:
fw.write(line)

except FileNotFoundError:
print("Not found input file")
```

5.3.1 向けのコードを 5.4.0 に自動で移植してくれます。

範囲を指定してその間のアドレスを 0x10C ズラしているだけなので失敗する場合もありますがだいたいうまくいきます。動かないときは範囲を自分で設定してみてください。
