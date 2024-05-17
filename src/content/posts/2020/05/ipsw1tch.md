---
title: "[Hack] IPSwitchコード作成を楽にするIPSw1tchつくった"
published: 2020-05-20
description: IPSwitchのコード開発における面倒な手順をやってくれるツールです
category: Nintendo
tags: [IPSwitch]
---

## IPSwitch とは

ニンテンドースイッチのゲームの実行ファイルにあてるパッチを作成してくれる神ツール。

スイッチ本体に当てたいパッチのリストを送っておいて、それを HB から IPSwitch を起動して好きなものを有効化するという仕組みです。

### IPSwitch の問題点

コードを有効化・無効化するという点では全くケチのつけようがない IPSwitch なのですが、コードを検証する側としては若干めんどくさい場面がいくつかありました。

たとえば、SeedHack などであれば 3.1.0 向けのコードは以下のような感じでした。

```
// SeedHack 000000(7) [tkgling]
@disabled
00208C74 E00080D2
```

このコードはシード値として 7 を設定し、その結果として称号がいちにんまえ以上であれば三つの WAVE すべてで干潮イベントなしという WAVE が発生するコードです。

で、次に例えばシード値として 0xB1A6 を使いたくなったとしましょう。このとき、コードを変更するというのが大変に煩わしかったのです。

- まず、SeedHack.exe で求めたい WAVE のシードを出力
  - ここでは仮にそれが 0xB1A6 とする
- HEX to ARM で E00080D2 を ARM 命令に変換する
  - MOVZ X0, #0x7 という ARM 命令を得る
- ARM to HEX で MOVZ X0, #0xB1A6 を HEX に変換する
  - C03496D2 という HEX を得る

こういう手順を踏んでようやく、

```
// SeedHack 212421(B1A6) [tkgling]
@disabled
00208C74 C03496D2
```

こういう IPSwitch 形式のコードを作成することができました。でもこれ、正直めんどくさいんですよね。

まず、HEX は機械語で人間が読みやすいようにできていません。それに対して ARM は低級ではありますが可読性はありますし、どんな命令が実行されているかもわかるので値を変更することも楽なんですよね。

例えば以下のコードは 5.4.0 で動作するサーモンランの 1WAVE の長さを変更するコードなのですが、00C28152 を見て一体これが秒数をいくらにするかさっぱりわかりませんよね？

```
// Change Wave Total Frame in SR [tkgling]
@disabled
007302A0 00C28152
```

で、秒数を変えたいなってなったときにまたさっきのようなめんどくさい手順をとらないといけないのです。

## IPSw1tch について

結局のところ IPSwitch の問題点はインラインアセンブラが書けないということに尽きます。これがかければアドレスとアセンブラを書いておしまいなんです。

あれ、でもよく考えたらインラインアセンブラが書ける便利なツールがアリましたよね？そう、Starlight です。

```
[version=310, target=main]
gsys::SystemTask::invokeDrawTV*+284 NOP // enable display debug stuff (which is used for hook)
gsys::SystemTask::invokeDrawTV*+390:
MOV X1, X0
MOV X0, X25
ADRP X2, #0x29A4000                     // CoopSetting
LDR X2, [X2, #0xE08]
LDR X2, [X2]
ADRP X3, #0x29AB000                     // EventDiretor
LDR X3, [X3, #0xBC0]
LDR X3, [X3]
ADRP X4, #0x29A9000                     // PlayerDirector
LDR X4, [X4, #0xDB8]
LDR X4, [X4]
BL renderEntrypoint
B #0x294
```

Starlight ではこのように codehook.slpatch にアセンブラを書いておくことで python ライブラリの一つである keystone を使って HEX をすっとばして直接 IPS 形式のパッチをつくることができました。

で、本来であればこのような仕組みにするのがベストなんですが keystone の環境をつくるのが死ぬほどめんどくさいんです。なので今回は keystone を使わずにインラインアセンブラが書けるうまい仕組みを考えました。

### [Online ARM to HEX Converter](https://armconverter.com/)

コード開発においてものすごくお世話になっている Online ARM to HEX Converter なのですが、なぜかここ数日繋がらない状況が続いていました。

サービス終了だったら代替サービスがなくて困るなあと思っていたのですが、それは杞憂だったらしくなんとなんとアップデートされてかえってきました！

地味に SSL に対応してる！

そしてアプデされた Online ARM to HEX Converter を開発者ツールで眺めているときに気付いたのです。

![](https://pbs.twimg.com/media/EYdcKMHWkAI-gkZ?format=png)

convert...？

これ、変換用の API があるのでは...？

![](https://pbs.twimg.com/media/EYdcrpcXkAEpcyR?format=png)

これがまさにビンゴで convert という（内部？）API があることがわかりました。

開発者ツールではどんなリクエストを送っているのかはわかりませんが、レスポンスとして ARM64 の HEX が JSON 形式で返ってきているのがわかります。リクエスト自体は Fiddler などのパケットキャプチャソフトを使えば調べるのは簡単です。

調べたところ、POST に必要なヘッダーは Content-Length と Host だけでした。

### 完成したもの

[IPSw1tch](https://github.com/tkgstrator/IPSw1tch)

そこまでわかれば Python ライブラリの一つである requests を使って簡単に API を叩けます。おおっぴらに API が公開されているわけではないのでなんか怪しい気もしますが...

<video controls src="https://video.twimg.com/ext_tw_video/1263068293675573248/pu/vid/1280x720/a9fKImH-qNJ77QME.mp4"></video>

ARM 命令を HEX に変換して IPSwitch 用のパッチができているのがわかりますね！

## 今後の展望

現在は ARM to HEX しかサポートしていないのですが、HEX to ARM もサポートできればいいなと考えています。あとはインスタンス呼び出す際になにか特殊なコマンドを考えて一発で出せるようにしたら楽しいかななんて思ったり。

まあこれもそれも API のおかげです、さまさまです。

記事は以上。
