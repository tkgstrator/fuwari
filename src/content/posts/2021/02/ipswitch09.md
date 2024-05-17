---
title: "誰でもできるコード開発 #9"
published: 2021-02-14
description: インスタンスを利用するコードの移植方法について解説しています
category: Nintendo
tags: [Salmon Run, IPSwitch]
---

# 誰でもできるコード開発 #9

## はじめに

今回の内容は以下の記事の続きになります。

[誰でもできるコード開発 #8](https://tkgstrator.work/posts/2020/11/02/ipswitch08.html)

この記事を読むにあたって必ず目を通して理解しておいてください。

## インスタンスをコールするコード

IPSwitch 形式のコードには単純に命令を上書きするものと、インスタンスを読み込んで中身を書き換えるものがあります。

前者の一例を挙げるとスペシャルウエポンの塗りポイントを 0 にするようなものが考えられます。

```
// Special Cost 0 (3.1.0) [tkgling]
@disabled
000847B4 3F0000F9 // STR WZR, [X1]
```

本来パラメータファイルから必要な塗りポイントを取得してレジスタに格納している命令が`000864E8`に書かれているのですが、それを上書きするパッチになります。

ゼロレジスタ（XZR）という読み込むと必ず 0 を返す特別なレジスタを使って X1 レジスタが保持するメモリアドレスに 0 というデータを書き込みます。

X1 レジスタはそれぞれのブキのスペシャルウエポン発動に必要な塗りポイントのパラメータを格納する場所なので、このパッチがあれば必要塗りポイントが 0 になるという仕組みです。

このパッチはバージョンを問わず常に命令部`3F0000F9`の値は変わらず、ゲームのバージョンによって実行ファイル内の関数のアドレスがズレるだけなので「アドレスだけを移植すれば動作するコード」ということができるわけです。

それに対してインスタンスを参照するコードは命令部にプログラムのアドレスを参照する内容が書かれているので、アドレス部だけを変えても動作させることはできません。

## インスタンス参照コード

```
// Get 9999 Power Eggs by Signal (3.1.0) [tkgling]
@disabled
0104C94C 60970190 // ADRP X0, #0x32EC000
0104C950 00DC46F9 // LDR X0, [X0, #0xDB8]
0104C954 000040F9 // LDR X0, [X0]         // X0 = PlayerDirector
0104C958 01B841F9 // LDR X1, [X0, #0x370] // X1 = mRoundBankedPowerIkuraNum
0104C95C E1E184D2 // MOV X1, #0x270F      // X1 = 0x270F
0104C960 01B801F9 // STR X1, [X0, #0x370] // mRoundBankedPowerIkuraNum = X1
0104C964 C0035FD6 // RET
```

これはカモンかナイスを押せば赤イクラ取得数が 9999 になるコードですが、最初の二行のコードが`PlayerDirector`のインスタンスを読み込む内容になっています。

で、ここが大事なところでインスタンスのアドレスはスプラトゥーンの実行ファイル内にあり、バージョンが上がるとここの値も変わってしまうということです。

つまり「アドレスと命令（命令内のアドレス）の両方を書き換えないと動かないコード」になるわけです。

バージョン 3.1.0 以降ではプログラム内のデバッグシンボルが削除されているので、インスタンスを探すのはめんどくさかったりします。

誰かが wiki みたいなのつくってインスタンスのまとめつくってくれたら楽なんですけどね。

まあめんどくさいから誰もしないと思います。

## インスタンスを探そう

インスタンスとは要はクラスを実体化したものですので、クラスの数だけインスタンスの種類があることになります。

例えば、サーモンランに関するインスタンスはこれだけあります。

|            クラス            |  3.1.0   |                意味                |
| :--------------------------: | :------: | :--------------------------------: |
|   Game::Coop::RewardConfig   | 04157FB0 |                 -                  |
|    Game::Coop::RuleConfig    | 04158008 |        パラメータを設定する        |
|   Game::Coop::LevelsConfig   | 04160E00 |     詳細なパラメータを設定する     |
|     Game::Coop::Setting      | 04160E08 | キケン度やステージなどの設定を司る |
|  Game::VictoryClamDirector   | 04162050 |                 -                  |
|   Game::Coop::CameraHolder   | 04164DF0 |                 -                  |
|     Game::Coop::GraphMgr     | 04164E40 |         GraphNode を司る？         |
|   Game::Coop::ItemDirector   | 04165738 |                 -                  |
|  Game::Coop::EnemyDirector   | 04165740 |         シャケを司るクラス         |
|  Game::Coop::PlayerDirector  | 04165DB8 | サーモンランのプレイヤー情報を司る |
|  Game::Coop::EventDirector   | 04167BC0 |     夜イベントなどの情報を司る     |
|  Game::Coop::SeaSurfaceMgr   | 04167C20 |          潮位の変化を司る          |
|  Game::Coop::GuideDirector   | 04167E18 |                 -                  |
|    Game::Coop::Moderator     | 04168C78 |        クマサンの挙動を司る        |
| Game::Coop::ResultPlayReport | 04169050 |        リザルトデータを司る        |

### Game::PlayerMgr::sInstance

ナワバリバトルやガチマッチで使うプレイヤーデータを司るクラスです。

チーム変更や、持っているブキやスペシャルを変更したりする場合にはこのクラスを使います。

|              |                3.1.0                |  5.4.0   |
| :----------: | :---------------------------------: | :------: |
|   アドレス   |              04157578               | 02CFDCF8 |
|   検索位置   |              005C5758               | 007605C0 |
| 検索バイナリ | 08 C0 50 39 1F 01 00 71 E0 13 80 9A |    -     |

このインスタンスの見つけ方ですが`Game::Coop::Utl::GetPlayer()`という関数がプレイヤーのデータを取得する際に`Game::PlayerMgr`を呼び出しているので、それを利用します。

```
005C5758                 MOV             W8, W0
005C575C                 TBNZ            W8, #0x1F, loc_5C5794
005C5760                 STP             X29, X30, [SP,#-0x10+var_s0]!
005C5764                 MOV             X29, SP
005C5768                 ADRP            X9, #off_4157578@PAGE
005C576C                 LDR             X9, [X9,#off_4157578@PAGEOFF]
005C5770                 LDR             X0, [X9] ; this
005C5774                 MOV             W1, W8  ; unsigned int
005C5778                 BL              _ZNK4Game9PlayerMgr18getAllKindPlayerAtEj ; Game::PlayerMgr::getAllKindPlayerAt(uint)
005C577C                 LDP             X29, X30, [SP+var_s0],#0x10
005C5780                 CBZ             X0, locret_5C5790
005C5784                 LDRB            W8, [X0,#0x430]
005C5788                 CMP             W8, #0
005C578C                 CSEL            X0, XZR, X0, NE
```

見ると 005C5778 で`_ZNK4Game9PlayerMgr18getAllKindPlayerAtEj`が呼び出されています。

これを[デマングル](http://demangler.com/)すると`Game::PlayerMgr::getAllKindPlayerAt(unsigned int) const`ということがわかります。

`Game::Coop::Utl`クラス内で`Game::PlayerMgr`クラスのメソッドが呼びだされているので、呼び出す前に必ずそのクラスのインスタンスを呼び出していなければいけません。

となると 04157578 が探していた`Game::PlayerMgr`クラスのアドレスであることがわかるのです。

つまり、`Game::PlayerMgr`を探すためには先に`Game::Coop::Utl::GetPlayer()`のサブルーチンを探せば良いことになります。

このサブルーチンは比較的特徴的な命令を持っているので、

```
005C5784                 LDRB            W8, [X0,#0x430]
005C5788                 CMP             W8, #0
005C578C                 CSEL            X0, XZR, X0, NE
```

この三つの命令群をバイナリ検索すれば簡単に見つけられます。

これを ARM64 に変換すると`08 C0 50 39 1F 01 00 71 E0 13 80 9A`になります。

これをバイナリ検索すれば 5.4.0 の場合 007605EC がヒットすると思います。

```
007605C0                 MOV             W8, W0
007605C4                 TBNZ            W8, #0x1F, loc_7605FC
007605C8                 STP             X29, X30, [SP,#-0x10+var_s0]!
007605CC                 MOV             X29, SP
007605D0                 ADRP            X9, #off_2CFDCF8@PAGE
007605D4                 LDR             X9, [X9,#off_2CFDCF8@PAGEOFF]
007605D8                 LDR             X0, [X9]
007605DC                 MOV             W1, W8
007605E0                 BL              sub_10E6CFC
007605E4                 LDP             X29, X30, [SP+var_s0],#0x10
007605E8                 CBZ             X0, locret_7605F8
007605EC                 LDRB            W8, [X0,#0x430]
007605F0                 CMP             W8, #0
007605F4                 CSEL            X0, XZR, X0, NE
```

すると 02CFDCF8 が 5.4.0 における`Game::PlayerMgr`のアドレスだとわかるわけです。

### Game::Coop::PlayerDirector

サーモンランで使うプレイヤーデータを司るクラスです。

金イクラ数や赤イクラ数の変更などをする場合にはこのクラスを使います。

|              |                3.1.0                |  5.4.0   |
| :----------: | :---------------------------------: | :------: |
|   アドレス   |              04165DB8               | 02D0CEE0 |
|   検索位置   |              005A615C               | 0073EC84 |
| 検索バイナリ | F3 03 00 AA 74 22 0D D1 08 41 00 91 |    -     |

このインスタンスは`Game::Coop::PlayerDirector`のでデコンストラクタを使って探すのが楽ではないかと思います。

```
005A6130                 STP             X20, X19, [SP,#-0x10+var_10]!
005A6134                 STP             X29, X30, [SP,#0x10+var_s0]
005A6138                 ADD             X29, SP, #0x10
005A613C                 ADRP            X8, #off_4168FF8@PAGE
005A6140                 LDR             X8, [X8,#off_4168FF8@PAGEOFF]
005A6144                 MOV             X19, X0
005A6148                 SUB             X20, X19, #0x348
005A614C                 ADD             X8, X8, #0x10
005A6150                 STR             X8, [X19]
005A6154                 ADRP            X8, #off_4165DB8@PAGE
005A6158                 LDR             X8, [X8,#off_4165DB8@PAGEOFF]
005A615C                 STR             XZR, [X8] ; Cmn::Singleton<Game::Coop::PlayerDirector>::GetInstance_(void)::sInstance
005A6160                 BL              _ZN4sead9IDisposerD2Ev ; sead::IDisposer::~IDisposer()
005A6164                 ADRP            X8, #off_4156138@PAGE
005A6168                 LDR             X8, [X8,#off_4156138@PAGEOFF]
005A616C                 ADD             X8, X8, #0x10
005A6170                 STR             X8, [X20]
005A6174                 LDP             X29, X30, [SP,#0x10+var_s0]
005A6178                 SUB             X0, X19, #0x230 ; this
005A617C                 LDP             X20, X19, [SP+0x10+var_10],#0x20
005A6180                 B               _ZN4sead3JobD2Ev ; sead::Job::~Job()
```

何が書いてあるかさっぱりだと思うのですが、上から 10 行目の 04165DB8 が`Game::Coop::PlayerDirector`のアドレスになります。

```
005A6144                 MOV             X19, X0
005A6148                 SUB             X20, X19, #0x348
005A614C                 ADD             X8, X8, #0x10
005A6150                 STR             X8, [X19]
```

幸いなことにこのサブルーチンにも特徴的な命令があり、これをバイナリに変換すると`F3 03 00 AA 74 22 0D D1 08 41 00 91 68 02 00 F9`となります。

これは似たようなサブルーチンがいくつかあるので、しっかりと見極めましょう。

5.4.0 の場合はバイナリ検索では次の 12 回のサブルーチンがヒットすると思うのですが、10 回目にヒットするところが`Game::Coop::PlayerDirector`のデコンストラクタのサブルーチンになります。

バージョンによって何回目のサブルーチンなのかは変わる可能性がありますが、候補は 6 つしかないのでそのときは適当に全部試してみてください。

```
006E3310, 006E3364
006F3054, 006F30A8
006FF75C, 006FF7B0
0070A74C, 0070A7A0
0073EC30, 0073EC84
01386678, 013866CC
```

なので 0073EC84 のサブルーチンをチェックします。

```
0073EC84                 STP             X20, X19, [SP,#var_20]!
0073EC88                 STP             X29, X30, [SP,#0x20+var_10]
0073EC8C                 ADD             X29, SP, #0x20+var_10
0073EC90                 ADRP            X8, #off_2D100B8@PAGE
0073EC94                 LDR             X8, [X8,#off_2D100B8@PAGEOFF]
0073EC98                 MOV             X19, X0
0073EC9C                 SUB             X20, X19, #0x348
0073ECA0                 ADD             X8, X8, #0x10
0073ECA4                 STR             X8, [X19]
0073ECA8                 ADRP            X8, #off_2D0CEE0@PAGE
0073ECAC                 LDR             X8, [X8,#off_2D0CEE0@PAGEOFF]
0073ECB0                 STR             XZR, [X8]
0073ECB4                 BL              sub_171A9C8
0073ECB8                 ADRP            X8, #off_2CFCF90@PAGE
0073ECBC                 LDR             X8, [X8,#off_2CFCF90@PAGEOFF]
0073ECC0                 ADD             X8, X8, #0x10
0073ECC4                 SUB             X0, X19, #0x230
0073ECC8                 STR             X8, [X20]
0073ECCC                 BL              nullsub_1290
0073ECD0                 LDP             X29, X30, [SP,#0x20+var_10]
0073ECD4                 MOV             X0, X20 ; void *
0073ECD8                 LDP             X20, X19, [SP+0x20+var_20],#0x20
0073ECDC                 B               _ZdlPv  ; operator delete(void *)
```

同様に上から 10 番目の命令を見ればアドレスが 02D0CEE0 であることがわかります。

## イクラ個数変更コードを移植しよう

イクラの個数変更コードはチーム変更よりも簡単です。

何故なら、`Game::Coop::PlayerDirector`が全てのプレイヤーの情報を持っているため、わざわざ`getControlledPerformer`のような操作しているプレイヤー情報を取得する必要がないのです。

もちろん、もっと複雑なコードにする場合は BL 命令で他のサブルーチンを呼び出す必要があるのでちょっとややこしいことになります。

### イクラ個数変更コードテンプレート

```
ADRP X0, #0xXXXXX000
LDR X0, [X0, #0xYYY]
LDR X0, [X0]
MOV W1, #0x270F
STR W1, [X0, #0x370]
MOV W1, #0x3E7
STR W1, [X0, #0x378]
STR W1, [X0, #0x37C]
RET
```

なんでこういうコードになっているかというと、それは以前のコードを見ていただきたいのですが、その記事が若干わかりにくいので簡単に解説。

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

こんな感じで`Game::Coop::PlayerDirector`クラスは四人分のデータをもっているので、先頭アドレスを調べてそこの値を上書きしてしまう方法が使えます。

自分がホストをしているのであれば、自分の情報は先頭になるので先頭アドレスから 0x370 ズレたところにデータが入っています。

赤イクラの数を変えたいのであれば 0x370 を、金イクラの数を変えたいのであれば 0x378 を変えれば良いとなるわけです。また、保険として 0x37C も変えておけば完璧です。

### テンプレートを完成させよう

同じように`sendSignalEvent`をに上書きをします。

```
0104C94C ADRP X0, #0xXXXXX000
0104C950 LDR X0, [X0, #0xYYY]
0104C954 LDR X0, [X0]
0104C958 MOV W1, #0x270F
0104C95C STR W1, [X0, #0x370]
0104C960 MOV W1, #0x3E7
0104C964 STR W1, [X0, #0x378]
0104C968 STR W1, [X0, #0x37C]
0104C96C RET
```

| パラメータ |                                    意味                                     |
| :--------: | :-------------------------------------------------------------------------: |
|   XXXXX    |                 Game::PlayerMgr のアドレスを使って計算する                  |
|    YYY     | XXXXX000 に対するオフセット <br> Game::PlayerMgr のアドレスを使って計算する |
|  AAAAAAAA  |             Game::PlayerMgr::getControlledPerformer のアドレス              |
|  BBBBBBBB  |                         この命令が書かれるアドレス                          |

$02CD0-0104C=01CC0$

なので XXXXX は 01CC0 となり、YYY は EE0 となります。

```
0104C94C ADRP X0, #0x1CC0000
0104C950 LDR X0, [X0, #0xEE0]
0104C954 LDR X0, [X0]
0104C958 MOV W1, #0x270F
0104C95C STR W1, [X0, #0x370]
0104C960 MOV W1, #0x3E7
0104C964 STR W1, [X0, #0x378]
0104C968 STR W1, [X0, #0x37C]
0104C96C RET
```

これを[Online ARM to HEX Converter](https://armconverter.com/)で変換するとこうなります。

```
// Get 999 Golden Eggs and 9999 Power Eggs by Signal [tkgling]
@disabled
0104C94C 00E60090 // ADRP X0, #0x1CC0000
0104C950 007047F9 // LDR X0, [X0, #0xEE0]
0104C954 000040F9 // LDR X0, [X0]
0104C958 E1E18452 // MOV W1, #0x270F
0104C95C 017003B9 // STR W1, [X0, #0x370]
0104C960 E17C8052 // MOV W1, #0x3E7
0104C964 017803B9 // STR W1, [X0, #0x378]
0104C968 017C03B9 // STR W1, [X0, #0x37C]
0104C96C C0035FD6 // RET
```

というコードが得られます。

### 動作テストをしてみる

<video controls src="https://video.twimg.com/ext_tw_video/1397085846642122756/pu/vid/1280x720/c-eoYIcexoDnhCmi.mp4"></video>

上手くイクラを取得することができました。

ただ、リザルト画面でのスコアに正しく反映されないのは相変わらずです。

ここを直すのも宿題の一つということで！

## チーム変更コードを移植しよう

インスタンスのアドレスが分かったので、あとはコードを移植するだけになります。

全てをそのまま使うことはできないのですが、テンプレートがあるのでそれを使えば空いているところに値を入れるだけで移植ができます。

### チーム変更コードテンプレート

以下は、全てのバージョンで正しく動作するチーム変更コードです。

バージョンによって異なるのは`XXXXX`、`YYY`、`AAAAAAAA`、`BBBBBBBB`の値だけです。つまり、各バージョンにおいてこれら四つの値を突き止めることが移植することに繋がります。

```
STP X29, X30, [SP, #-0x10]!
MOV X29, SP
ADRP X0, #0xXXXXX000
LDR X0, [X0, #0xYYY]
LDR X0, [X0]
BL #0xAAAAAAAA - 0xBBBBBBBB
LDR X1, [X0, #0x328]
EOR X1, X1, #1
STR X1, [X0, #0x328]
LDR X1, [X0, #0x488]
STR X1, [X0, #0x38]
LDP X29, X30, [SP], #0x10
RET
```

それぞれのパラメータの意味をいかに解説します。

| パラメータ |                                    意味                                     |
| :--------: | :-------------------------------------------------------------------------: |
|   XXXXX    |                 Game::PlayerMgr のアドレスを使って計算する                  |
|    YYY     | XXXXX000 に対するオフセット <br> Game::PlayerMgr のアドレスを使って計算する |
|  AAAAAAAA  |             Game::PlayerMgr::getControlledPerformer のアドレス              |
|  BBBBBBBB  |                         この命令が書かれるアドレス                          |

これらの値を計算するためにはあと二つのアドレスがわからなければいけません。

というのも、チーム変更は「自分が操作しているプレイヤー」のチーム情報がわからないといけないからです。

「自分が操作しているプレイヤー」の情報をとってくるには`Game::PlayerMgr`が利用できます。

これは全てのプレイヤーの情報を持っているので、このクラスを利用して「自分が操作してるプレイヤー」の情報だけをとってきます。

自分が操作しているプレイヤーが全プレイヤーの何番目なのかは固定ではないのですが（ホストであれば常に 0 番目であることが保証されます）、`Game::PlayerMgr::getControlledPerformer`というサブルーチンを使えば「自分が操作しているプレイヤー」の情報が取得できます。

よって、まずはこのサブルーチンを呼び出すことを考えます。

サブルーチン呼び出しには「呼び出したいサブルーチンが定義されているアドレス」と「サブルーチンを呼び出すアドレス」の二つが必要です。

「呼び出すアドレス」はコード開発者が自由に決められるのでどうやって決めるかはのちのち解説します。

よって、まずは`Game::PlayerMgr::getControlledPerformer`が定義されているアドレスを探しましょう。

### Game::PlayerMgr::getControlledPerformer

|              サブルーチン               |  3.1.0   |  5.4.0   |
| :-------------------------------------: | :------: | :------: |
| Game::PlayerMgr::getControlledPerformer | 00F07B1C | 010E6D2C |

`getControlledPerformer()`は`Game::PlayerMgr`クラスのサブルーチンなので先程まで探していたアドレス付近にあります。
これもやはり特徴的な命令があるので簡単に見つけられます。

```
00F07B1C                 STR             X19, [SP,#-0x10+var_10]!
00F07B20                 STP             X29, X30, [SP,#0x10+var_s0]
00F07B24                 ADD             X29, SP, #0x10
00F07B28                 LDRSW           X8, [X0,#0x5C8]
00F07B2C                 LDR             W9, [X0,#0x624]
00F07B30                 CMP             W9, W8
00F07B34                 B.LE            loc_F07B64
00F07B38                 LDR             X10, [X0,#0x638]
00F07B3C                 LDR             W9, [X0,#0x630]
00F07B40                 ADD             X11, X10, X8,LSL#3
00F07B44                 CMP             W9, W8
00F07B48                 CSEL            X8, X11, X10, HI
00F07B4C                 LDR             X19, [X8]
00F07B50                 CBZ             X19, loc_F07B68
00F07B54                 LDRB            W8, [X19,#0x430]
00F07B58                 CBZ             W8, loc_F07B68
00F07B5C                 BL              _ZN2Lp3Utl31printStackTraceIfLastWarningAddEv ; Lp::Utl::printStackTraceIfLastWarningAdd(void)
00F07B60                 B               loc_F07B68
```

バイナリ検索で`08 C8 85 B9 09 24 46 B9 3F 01 08 6B 8D 01 00 54`とすれば 010E6D38 がヒットすると思います。

```
010E6D2C                 STR             X19, [SP,#-0x10+var_10]!
010E6D30                 STP             X29, X30, [SP,#0x10+var_s0]
010E6D34                 ADD             X29, SP, #0x10
010E6D38                 LDRSW           X8, [X0,#0x5C8]
010E6D3C                 LDR             W9, [X0,#0x624]
010E6D40                 CMP             W9, W8
010E6D44                 B.LE            loc_10E6D74
010E6D48                 LDR             X10, [X0,#0x638]
010E6D4C                 LDR             W9, [X0,#0x630]
010E6D50                 ADD             X11, X10, X8,LSL#3
010E6D54                 CMP             W9, W8
010E6D58                 CSEL            X8, X11, X10, HI
010E6D5C                 LDR             X19, [X8]
010E6D60                 CBZ             X19, loc_10E6D78
010E6D64                 LDRB            W8, [X19,#0x430]
010E6D68                 CBZ             W8, loc_10E6D78
010E6D6C                 BL              sub_19F8C5C
010E6D70                 B               loc_10E6D78
```

するとやはり一発で見つかります。

サブルーチンのアドレスというのは「サブルーチンの先頭アドレス」を意味するので、この場合は 010E6D2C ということになります。

これで「呼び出したいサブルーチンのアドレス」は分かったので、次は「呼び出すアドレス」を決めます。

「探す」ではなく「決める」と書いたのは、ここまで分かった情報で「好きなアドレスから`Game::PlayerMgr`クラスを読み込み、`getControlledPerformer()`をコールして自分のプレイヤー情報を読み込み、チームを変更する」というコードは書けるからです。

しかし、このままでは自分が好きなタイミングでチームを変更することができません。

要するに、ナイスやカモンを押したタイミングでチームを変えたいので、ナイスやカモンの本来の動作をチーム変更コードに上書きしたいわけです。

なので、今回はナイスやカモンの挙動のうち、上書きしてもゲームの動作に問題ない箇所を探せば良いことになります。

### Game::PlayerCloneHandle::sendSignalEvent

上書きしても大丈夫なナイスやカモンをコールしたときに呼び出されるサブルーチンとしていつも使っているのが`Game::PlayerCloneHandle::sendSignalEvent()`です。

これは別にこのサブルーチンでなくても他のサブルーチンでも代用できます。

|               サブルーチン               |  3.1.0   |  5.4.0   |
| :--------------------------------------: | :------: | :------: |
| Game::PlayerCloneHandle::sendSignalEvent | 00E797FC | 0104C94C |

```
00E797FC                 STR             X19, [SP,#-0x10+var_10]!
00E79800                 STP             X29, X30, [SP,#0x10+var_s0]
00E79804                 ADD             X29, SP, #0x10
00E79808                 STUR            W1, [X29,#var_4]
00E7980C                 LDUR            W8, [X29,#var_4]
00E79810                 MOV             X19, X0
00E79814                 STRB            W8, [SP,#0x10+var_8]
00E79818                 BL              _ZNK4Game15CloneHandleBase14isOfflineSceneEv ; Game::CloneHandleBase::isOfflineScene(void)
00E7981C                 TBZ             W0, #0, loc_E79828
00E79820                 MOV             W0, #1
00E79824                 B               loc_E79834
00E79828                 LDR             X0, [X19,#0x10]
00E7982C                 ADD             X1, SP, #0x10+var_8
00E79830                 BL              _ZN4Game14PlayerCloneObj21pushPlayerSignalEventERKNS_22PlayerSignalCloneEventE ; Game::PlayerCloneObj::pushPlayerSignalEvent
00E79834                 LDP             X29, X30, [SP,#0x10+var_s0]
00E79838                 AND             W0, W0, #1
00E7983C                 LDR             X19, [SP+0x10+var_10],#0x20
00E79840                 RET
```

これも特徴的な命令があるのでバイナリ検索で`FD 43 00 91 A1 C3 1F B8 A8 C3 5F B8 F3 03 00 AA`と検索すれば一発で見つかります。

```
0104C94C                 STR             X19, [SP,#var_20]!
0104C950                 STP             X29, X30, [SP,#0x20+var_10]
0104C954                 ADD             X29, SP, #0x20+var_10
0104C958                 STUR            W1, [X29,#-4]
0104C95C                 LDUR            W8, [X29,#-4]
0104C960                 MOV             X19, X0
0104C964                 STRB            W2, [SP,#0x20+var_17]
0104C968                 STRB            W8, [SP,#0x20+var_18]
0104C96C                 BL              sub_5BC880
0104C970                 TBZ             W0, #0, loc_104C97C
0104C974                 MOV             W0, #1
0104C978                 B               loc_104C988
0104C97C                 LDR             X0, [X19,#0x10]
0104C980                 ADD             X1, SP, #0x20+var_18
0104C984                 BL              sub_104E590
0104C988                 LDP             X29, X30, [SP,#0x20+var_10]
0104C98C                 AND             W0, W0, #1
0104C990                 LDR             X19, [SP+0x20+var_20],#0x20
0104C994                 RET
```

これで命令を呼び出したいアドレスを決めることができました。

### テンプレートを完成させよう

さて、ここで`Game::PlayerCloneHandle::sendSignalEvent`の内容全てをテンプレートで上書きします。

テンプレートの方が命令が少ないので余った部分には何もしないを意味する NOP を埋めておきます。

埋めていなくても RET 命令があるためここの命令は実行されないのですが、解説ではわかりやすさを重視して入れておきます。

```
0104C94C STP X29, X30, [SP, #-0x10]!
0104C94C MOV X29, SP
0104C94C ADRP X0, #0xXXXXX000
0104C94C LDR X0, [X0, #0xYYY]
0104C94C LDR X0, [X0]
0104C94C BL #0xAAAAAAAA - 0xBBBBBBBB
0104C94C LDR X1, [X0, #0x328]
0104C94C EOR X1, X1, #1
0104C94C STR X1, [X0, #0x328]
0104C94C LDR X1, [X0, #0x488]
0104C94C STR X1, [X0, #0x38]
0104C94C LDP X29, X30, [SP], #0x10
0104C94C RET
```

あとはこの四つのパラメータを計算したら終わりです。

| パラメータ |                                    意味                                     |
| :--------: | :-------------------------------------------------------------------------: |
|  XXXXX000  |         下三桁が 0 の値 Game::PlayerMgr のアドレスを使って計算する          |
|    YYY     | XXXXX000 に対するオフセット <br> Game::PlayerMgr のアドレスを使って計算する |
|  AAAAAAAA  |             Game::PlayerMgr::getControlledPerformer のアドレス              |
|  BBBBBBBB  |                         この命令が書かれるアドレス                          |

これらを計算するのに必要なデータも載せます。

| パラメータ |                       求め方                       |    値    |
| :--------: | :------------------------------------------------: | :------: |
|   XXXXX    |                    計算式は後述                    |  01CB1   |
|    YYY     |         Game::PlayerMgr のアドレスの下三桁         |   CF8    |
|  AAAAAAAA  | Game::PlayerMgr::getControlledPerformer のアドレス | 010E6D2C |
|  BBBBBBBB  |             BL 命令が書かれるアドレス              | 0104C960 |

ここで XXXXX 以外の値は簡単にわかります。問題は XXXXX なのですが、これは

`Game::PlayerMgr`のアドレスの上五桁からこの命令（ADRP）が書かれるアドレスの上五桁を引いたものになります。今回の場合ですと、

$02CFD-0104C=01CB1$

となり、XXXXX = 01CB1 となります。

```
0104C94C STP X29, X30, [SP, #-0x10]!
0104C94C MOV X29, SP
0104C94C ADRP X0, #0x1CB1000
0104C94C LDR X0, [X0, #0xCF8]
0104C94C LDR X0, [X0]
0104C94C BL #0x9A3CC
0104C94C LDR X1, [X0, #0x328]
0104C94C EOR X1, X1, #1
0104C94C STR X1, [X0, #0x328]
0104C94C LDR X1, [X0, #0x488]
0104C94C STR X1, [X0, #0x38]
0104C94C LDP X29, X30, [SP], #0x10
0104C94C RET
```

ここまでをまとめるとこうなります。

あとはこれを[Online ARM to HEX Converter](https://armconverter.com/)で変換すれば IPSwitch 形式のコードが得られます。

BL 命令はまとめて変換するとオフセットがズレるバグがあるので、BL 命令の箇所だけは必ず個別に変換してください。

```
// Swap Team Color by Signal (5.4.0) [tkgling]
@disabled
0104C94C FD7BBFA9 // STP X29, X30, [SP, #-0x10]!
0104C94C FD030091 // MOV X29, SP
0104C94C 80E500B0 // ADRP X0, #0x1CB1000
0104C94C 007C46F9 // LDR X0, [X0, #0xCF8]
0104C94C 000040F9 // LDR X0, [X0]
0104C94C F3680294 // BL #0x9A3CC
0104C94C 019441F9 // LDR X1, [X0, #0x328]
0104C94C 210040D2 // EOR X1, X1, #1
0104C94C 019401F9 // STR X1, [X0, #0x328]
0104C94C 014442F9 // LDR X1, [X0, #0x488]
0104C94C 011C00F9 // STR X1, [X0, #0x38]
0104C94C FD7BC1A8 // LDP X29, X30, [SP], #0x10
0104C94C C0035FD6 // RET
```

### 動作テストをしてみる

<video controls src="https://video.twimg.com/ext_tw_video/1397085676164632577/pu/vid/1280x720/vP10raBucY9XVDty.mp4"></video>

記事は以上。
