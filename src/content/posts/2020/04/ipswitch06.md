---
title: "誰でもできるコード開発 #6"
published: 2020-04-30
description: ナイスやカモンを上書きしてリアルタイムイクラ取得をする方法について解説しています
category: Nintendo
tags: [IPSwitch]
---

# 誰でもできるコード開発 #6

## はじめに

今回の内容は以下の記事の続きになります。

[誰でもできるコード開発 #5](https://tkgstrator.work/posts/2019/09/12/ipswitch05.html)

この記事を読むにあたって必ず目を通して理解しておいてください。

## Hook の仕組み

今回はナイスの動作を Hook して別の割り当てにしてしまおうという試みです。

Hook というのが自分でもよくわかってないのですが、本来の動作の命令を上書きして任意の関数を呼び出したりそういうのが Hook なんじゃないかとおもっています、違ったらごめんなさい。

まず、Hook するコードを書くために必要なことは三つです。

- Hook したい関数のアドレス

今回はナイスの動作を Hook したいのでそのアドレスを調べる必要があります。

これはバージョンごとに異なるので、アップデートのたびに更新しなければいけません。

- 目的のインスタンスのアドレス

インスタンスのポインタを習得する必要があるので、インスタンスのアドレスが必要になります。

今回は、サーモンランにおけるプレイヤー情報をナイスを使って操作することを考えてみましょう。

これもバージョンごとに異なるので、アップデートのたびに更新する必要があります。

- 目的のインスタンスの構造体

一番難しいのがこれで、仮に上の二つをクリアしたとしてもどこに何のデータが入っているのかがわからなければデータを使うことができません。

今回は目的のインスタンスの構造体はわかっているものとして話を進めます。

### Hook したい関数のアドレス

ナイスを押したときに呼び出される関数は`Game::PlayerCloneHandle::sendSignalEvent()`で、これはアドレス 00E797FC にかかれています。

見ればわかるのですが、`sendSignalEvent()`自体は命令長が 17 の関数です。

17 もあるということはたくさん上書きしても大丈夫ということですね。

最後に RET 命令を必ず書かなければいけないので、実質 16 命令書くことができます。

というわけで、一つ目の目標であった「Hook したい関数のアドレス」はわかったことになります。

### 目的のインスタンスのアドレス

今回はサーモンランのプレイヤー情報を弄りたいのですが、それらを制御するクラスは`Game::Coop::PlayerDirector`です。

このクラスがどこでインスタンスを生成しているか調べれば良いのです。

```
005A6154                 ADRP            X8, #off_4165DB8@PAGE
005A6158                 LDR             X8, [X8,#off_4165DB8@PAGEOFF]
005A615C                 STR             XZR, [X8] ; Cmn::Singleton<Game::Coop::PlayerDirector>::GetInstance_(void)::sInstance
```

調べると、こんな感じで 005A615C 付近に見つかり、04165DB8 からインスタンスのアドレスを読み込んでいることがわかります。

よって、インスタンスのアドレスは 04165DB8 ということがわかりました。

### インスタンスの構造体

「インスタンスのポインタがわかれば何が便利なのか」ということなんですが、それは一言でいうと「インスタンスの構造がわかっていればポインタ（先頭アドレス）がわかれば好きなデータにアクセスできる」ということに尽きます。

例えば、サーモンランにおけるプレイヤー情報は以下のようになっています。

```
struct Game::Coop::PlayerDirector
{
  _BYTE gap[0x370];
  Game::Coop::Player player[4];
};

struct Game::Coop::Player
{
  uint32_t mRoundBankedPowerIkuraNum;
  uint32_t mGotGoldenIkuraNum;
  uint32_t mRoundBankedGoldenIkuraNum;
  uint32_t mTotalBankedGoldenIkuraNum;
}
```

これはかなり大雑把な構造なので、実際にはもっといろんな要素がある。

つまり、`PlayerDirector`のポインタを見つけたら先頭から 370 バイトまでは何が入っているかわからないが、その後に四人分のプレイヤー情報が入っていることがわかるのです。

正確には先頭の 880 バイトには`Cmn::Actor`と`sead::IDisposer`が入っていますが、今回は使わないので無視します。

### Game::Coop::PlayerDirector

よって、`Game::Coop::PlayerDirector`の構造体をまとめると以下のようになります。

```
Game::Coop::PlayerDirector
  0x000 Cmn::Actor actor
  0x348 sead::IDisposer
  0x368 char char0x368
  0x370 Game::Coop::Player player[0]
    0x370 mRoundBankedPowerIkuraNum
    0x374 mGotGoldenIkuraNum
    0x378 mRoundBankedGoldenIkuraNum
    0x37C mTotalBankedGoldenIkuraNum
  0x470 Game::Coop::Player player[1]
    0x470 mRoundBankedPowerIkuraNum
    0x474 mGotGoldenIkuraNum
    0x478 mRoundBankedGoldenIkuraNum
    0x47C mTotalBankedGoldenIkuraNum
  0x570 Game::Coop::Player player[2]
    0x570 mRoundBankedPowerIkuraNum
    0x574 mGotGoldenIkuraNum
    0x578 mRoundBankedGoldenIkuraNum
    0x57C mTotalBankedGoldenIkuraNum
  0x670 Game::Coop::Player player[3]
    0x670 mRoundBankedPowerIkuraNum
    0x674 mGotGoldenIkuraNum
    0x678 mRoundBankedGoldenIkuraNum
    0x67C mTotalBankedGoldenIkuraNum
```

つまり、`Game::Coop::PlayerDirector`のインスタンスのポインタが分かればそこから 370 バイト後ろにズラしたところに一人目のプレイヤーの`mRoundBankedPowerIkuraNum`のデータが入っています。

二人目なら 470 という感じで、先頭さえわかればすべてのデータに自由にアクセスできます。

## アセンブラを書こう

IPSwitch 向けコードを書くといっても最終的に機械語に翻訳する作業が必要なだけで、元々のコードはアセンブラで書く必要があります。

いきなりアセンブラを考えると難しいのでゆっくり解説していきます。

| Game::Coop::PlayerDirector | sendSignalEvent() |
| :------------------------: | :---------------: |
|          04165DB8          |     00E797FC      |

### インスタンスのアドレスを読み込む

まず最初にやらないといけないのはインスタンスを読み込むということです。

「どうすればいいんだ？」って思うかもしれませんが、どんなインスタンスを読み込む場合にも以下の三つの命令があれば読み込めます。

```
ADRP X0, #0xXXXXX000
LDR X0, [X0, #0xYYY]
LDR X0, [X0]
```

今回は X0 レジスタを使っても問題ないですが、Hook する関数によっては X1 や X2 など好きなレジスタを使ってください。

その際は全部 X0 から X1 や X2 などに置き換えること！

- XXXXX の求め方

目的アドレスと Hook アドレスの下三桁無くした、目的アドレス - Hook アドレスの計算結果が XXXXX になります。

$04165-00E79=032EC$

これは Windows 標準の電卓で簡単に計算することができます。

- YYY の求め方

目的アドレスの下三桁なので DB8 になります。

### データを取得する

さて、XXXXX と YYY の値がわかったので先程のテンプレの命令に当てはめると以下のようになります。

```
ADRP X0, #0x32EC000
LDR X0, [X0, #0xDB8]
LDR X0, [X0]
```

実はこれで正しく`PlayerDirector`のポインタが取得できており、その値が X0 レジスタに入っています。

ではさっそく、データを習得するコードを書いてみましょう。

実はデータ取得に必要なコードはたった一種類なので、使い方さえ覚えてしまえば非常に簡単です。

```
LDR X1, [X0, #0x370] // X1 = mRoundBankedPowerIkuraNum
```

それがこの LDR 命令で、これは X0 レジスタ（今回の場合は`PlayerDirecotr`のポインタ）から 370 ズラしたところにあるデータを X1 レジスタにコピーするという命令です。

370 ズラしたところには先ほど説明したように一人目のプレイヤーの赤イクラ数が入っています。

つまり、これだけでデータの読み込みができてしまうのです。

### データの変更

ただ、これだと読み込んだだけで使いみちがないので、その値を更新したいと思います。

演算に使える命令はたくさんありますが、よく使うのはこの辺りでしょう。

| 命令 |     意味     |
| :--: | :----------: |
| MOV  |     代入     |
| ADD  |     加算     |
| SUB  |     減算     |
| MUL  |     乗算     |
| AND  |    論理積    |
| ORR  |    論理和    |
| EOR  | 排他的論理和 |

除算はあんまり使わないかな、多分。

### ARM 命令の書き方一覧

今回は読み込んだ赤イクラ取得数を 9999 増やすコードを書いてみます。

Windows のプログラマモードの電卓で 9999 を 16 進数に直すと 270F であることがわかります。

```
LDR X1, [X0, #0x370] // X1 = mRoundBankedPowerIkuraNum
MOV X1, #0x270F      // X1 = 0x270F
```

元々の値を 9999 に代入します。

### データの書き込み

さて、ここまではテンプレの三命令でインスタンスのポインタを読み込み、LDR 命令で赤イクラ数を習得し、9999 を足すところまで書くことができました。

でもこれだとただ計算をしただけなので、その結果を返さなければいけません。

データを戻す命令は STR 命令で、使い方は LDR 命令と全く同じです。

```
STR X1, [X0, #0x370] // X1 = mRoundBankedPowerIkuraNum
```

## コード化する

今までの三工程をまとめると以下のようになります。

最後の RET 命令はおまじないのようなもので、Hook する関数にも依りますが基本的には必要になってきます。

```
ADRP X0, #0x32EC000
LDR X0, [X0, #0xDB8]
LDR X0, [X0]
LDR X1, [X0, #0x370] // X1 = mRoundBankedPowerIkuraNum
MOV X1, #0x270F      // X1 = 0x270F
STR X1, [X0, #0x370] // X1 = mRoundBankedPowerIkuraNum
RET
```

命令の長さは全部で 8 となり、`sendSignalEvent()`の長さである 17 以下で収めることができました。

あとはこのアセンブラを[Online ARM to HEX Converter](https://armconverter.com/)で変換するだけです。

このとき出力される ARM HEX という値が今回欲しかったコードになります。

BL 命令はまとめて変換するとオフセットがズレるバグがあるので、BL 命令の箇所だけは必ず個別に変換してください。

```
60970190
00DC46F9
000040F9
01B841F9
E1E184D2
01B801F9
C0035FD6
```

あとはこれを IPSwitch 形式に書き換えれば作業は終了です。

### IPSwitch 形式に書き換え

`sendSignalEvent()`の先頭からドンドン上書きするだけなので以下のようになります。

```
// Get 9999 Power Eggs by Signal (3.1.0) [tkgling]
@disabled
00E797FC 60970190 // ADRP X0, #0x32EC000
00E79800 00DC46F9 // LDR X0, [X0, #0xDB8]
00E79804 000040F9 // LDR X0, [X0]
00E79808 01B841F9 // LDR X1, [X0, #0x370]
00E7980C E1E184D2 // MOV X1, #0x270F
00E79810 01B801F9 // STR X1, [X0, #0x370]
00E79814 C0035FD6 // RET

// Get 9999 Power Eggs by Signal (5.4.0) [tkgling]
@disabled
0104C94C 00E60090 // ADRP X0, #0x1CC0000
0104C950 007047F9 // LDR X0, [X0, #0xEE0]
0104C954 000040F9 // LDR X0, [X0]
0104C958 01B841F9 // LDR X1, [X0, #0x370]
0104C95C E1E184D2 // MOV X1, #0x270F
0104C960 01B801F9 // STR X1, [X0, #0x370]
0104C964 C0035FD6 // RET
```

### 演習問題

ナイスを押すと一人目のプレイヤー（player[0]）の`mRoundBankedGoldenIkuraNum`の数が 999 になるコードを書いてください。

player[0] の`mRoundBankedGoldenIkuraNum`が先頭からいくらズレているかをチェックすれば難しくないはず。

ナイスを押した瞬間に納品数が 999 になるのでクリアできます。

ただ、何らかのチェックが働いているのか、リザルト画面でのスコアには正しく反映されません。

記事は以上。
