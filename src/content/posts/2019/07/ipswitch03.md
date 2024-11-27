---
title: "誰でもできるコード開発 #3"
published: 2019-07-02
description: 関数の返り値自体を変更して、イカッチャのナゾの声をクマサンに変更する方法を解説しています
category: Nintendo
tags: [Splatoon2, IPSwitch, IDA Pro]
---

# 誰でもできるコード開発 #3

## はじめに

今回の内容は以下の記事の続きになります。

[誰でもできるコード開発 #2](https://tkgstrator.work/posts/2019/05/09/ipswitch02.html)

この記事を読むにあたって必ず目を通して理解しておいてください。

## 関数の返り値を調べる

今回は関数の返り値を変えることで、動作やモードを切り換えるコードの開発について学びます。

ぶっちゃけると関数の返り値を変えるというのはリターンする値を上書きしてしまえばいいのですが、どこをどう変えればどのように変わるのかよくわからなかったので復習という感じです。

### BL 命令

BL 命令とは条件分岐した後で、値をリターンする命令です。

擬似コードで書くとこのような感じになります

```
if(x0 == 1){
    // 何かしらの処理
    return 1;
} else {
    // 何かしらの処理
    return 0;
}
```

要するに、BL 命令はレジスタをいろいろいじった後で最終的になにかの値を返す命令なのです。

さて、ここで疑問「アセンブラってどうやって値を返すの？」って思った人もいると思います、素晴らしい疑問です。

自分もここがずっと引っかかっていたのですが、

**X0/W0 レジスタに必ず返り値がセットされているらしい**

という事に気付きました。

つまり、BL 命令は分岐先で何か処理をしたあとで X0/W0 レジスタに値をセットする命令だということです。

## \_ZN4Game4Coop3Utl7GetRuleEv

さて、BL 命令について理解したら`_ZN4Game4Coop3Utl7GetRuleEv`というサブルーチンに注目してみましょう。

この`Game4Coop3Utl7GetRuleEv`（以下、`GetRule()`と省略する）というなんだか長くてややこしいサブルーチンですが全体を見ると面白いことに気付きます。

```
005C3368                 ADRP            X8, #off_4156130@PAGE
005C336C                 LDR             X8, [X8,#off_4156130@PAGEOFF]
005C3370                 LDR             X8, [X8] ; Cmn::StaticMem::sInstance
005C3374                 CBZ             X8, loc_5C3380
005C3378                 LDR             W0, [X8,#0x72C]
005C337C                 RET
```

最終的に RET 命令で値をリターンしていることはわかり、さらにサブルーチンの定義から \_\_int64 型（64 ビット整数）を返していることがわかります。

ではこのサブルーチンがどのように使われているかを調べます。

::: tip

IDA Pro があるならサブルーチン名を右クリックして Jump to xref to operand を選択すると`GetRule()`が使われている関数をすべて調べることができます。

:::

すると例えば以下のようなコードが見つかります。

```
00568C04                 BL              _ZN4Game4Coop3Utl7GetRuleEv ; Game::Coop::Utl::GetRule(void)
00568C08                 LDR             X26, [X24,#8]
00568C0C                 CMP             W0, #2
00568C10                 ADD             X0, SP, #0x3D0+var_3C0 ; this
00568C14                 MOV             W8, #7
```

これだけだとわかりにくいと思うので、擬似コードに変換すると次のようになります。

```
v12 = Game::Coop::Utl::GetRule(result);
v13 = *(_QWORD *)(v7 + 8);
  if ( v12 == 2 )
    v14 = 8;
  else
    v14 = 7;
```

`GetRule()`で何かしらを計算をして「その値が 2 だったら v14 に 8 を、そうでなければ v14 に 7 を代入しろ」という命令になっているわけです。

つまり、返り値として 2 は存在することがわかるのですが他にどんな値を返すパターンがあるのでしょう？

実はこの`GetRule()`は遊んでいるサーモンランの種類によって返り値が異なります。

|      種類      | GetRule() |  機械語  |
| :------------: | :-------: | :------: |
|   オンライン   |     1     | 20008052 |
|   イカッチャ   |     2     | 40008052 |
| チュートリアル |     3     | 60008052 |

例えばオンラインで遊んでいるかのようにデータをいじりたいときは、W0 の値を 1 にするような命令で`GetRule()`を上書きすれば良いことになります。

### GetRule() が使われるサブルーチン

本当はもっといっぱいあるけど、面白そうなやつだけを列挙してみました。

引数がすっごい多いやつもあるのでここでは引数は省略します。

|                サブルーチン                | アドレス |
| :----------------------------------------: | :------: |
| Game::Coop::GuideDirector::showMessage\_() | 00568C04 |
|     Game::Coop::Moderator::Moderator()     | 005960CC |
|    Game::SeqCoopResult::SeqCoopResult()    | 005B3F6C |
|        Game::Coop::Setting::reset()        | 005C11CC |

さて、それぞれ弄るとどんな結果になるのか見てましょう。

**showMessage\_()**

ここを弄ると...！！

```
// Raspy Voice (3.1.0) [tkgling]
@disabled
00568C04 20008052 // MOV W0, #1

// Raspy Voice (5.4.0) [tkgling]
@disabled
006FF3AC 20008052 // MOV W0, #1
```

どうなるかは自分で実際にコードを動かして試してみましょう！

**Moderator()**

モデレータっていうのは（恐らく）サーモンランを司る一番大きな要素です。

1 にすると`NormalRuleModerator()`でオンラインモードが呼び出されるはずですが、何故かブキが強制的にボールドになります。

どのブキを選んでも必ずボールドに変えられてしまいます、なんじゃそりゃ...

:::tip

恐らくオンラインの情報から現在支給されるブキ情報をとってくるんだけど、オンラインに一回も繋いでいないのでブキデータがなく、初期値 0 のボールドマーカーが使われているんだと思います。

:::

```
// Force Splash-o-matic (3.1.0)
@disabled
005960CC 20008052 // MOV W0, #1

// Force Splash-o-matic (5.4.0)
@disabled
0072ED84 20008052 // MOV W0, #1
```

変な値（2 とか）にすると何ももってないまま棒立ちするイカちゃんが見れます。

**SeqCoopResult()**

返り値を 1 にすると`Game::Coop::OnlineResultPlayReport()`が呼び出されるはず。

```
// SeqCoopResult (3.1.0)
@disabled
005B3F6C 20008052 // MOV W0, #1

// SeqCoopResult (5.4.0)
@disabled
0074EB5C 20008052 // MOV W0, #1
```

なのですが、特に何も変わりませんでした。

**reset()**

値が 1 のときだけ`Cmn::Def::Coop::CalcOnlineEvalPoint()`というオンラインのクマサンポイントを計算するサブルーチンが呼び出されます。

```
// CalcOnlineEvalPoint (3.1.0)
@disabled
005C11CC 20008052 // MOV W0, #1

// CalcOnlineEvalPoint (5.4.0)
@disabled
0075BF7C 20008052 // MOV W0, #1
```

が、特になにか変わったような感じもしませんでした。

ここはオンラインもオフラインも似たようなことをしているみたいです。

## \_ZNK2Lp3Utl9ByamlIter14tryGetIntByKeyEPiPKc

次もいろいろなことに使えそうなサブルーチンを紹介します。

このサブルーチンは`Lp::Utl::ByamlIter::tryGetIntByKey()`という別名をもっており、その内容は次のようになります。

```
01A56ED0                 STR             X21, [SP,#-0x10+var_20]!
01A56ED4                 STP             X20, X19, [SP,#0x20+var_10]
01A56ED8                 STP             X29, X30, [SP,#0x20+var_s0]
01A56EDC                 ADD             X29, SP, #0x20
01A56EE0                 MOV             X21, X0
01A56EE4                 ADD             X0, SP, #0x20+var_18 ; this
01A56EE8                 MOV             X20, X2
01A56EEC                 MOV             X19, X1
01A56EF0                 BL              _ZN2Lp3Utl9ByamlDataC2Ev ; Lp::Utl::ByamlData::ByamlData(void)
01A56EF4                 ADD             X1, SP, #0x20+var_18 ; Lp::Utl::ByamlData *
01A56EF8                 MOV             X0, X21 ; this
01A56EFC                 MOV             X2, X20 ; char *
01A56F00                 BL              _ZNK2Lp3Utl9ByamlIter17getByamlDataByKeyEPNS0_9ByamlDataEPKc ; Lp::Utl::ByamlIter::getByamlDataByKey(Lp::Utl::ByamlData *,char const*)
01A56F04                 TBZ             W0, #0, loc_1A56F44
01A56F08                 ADD             X0, SP, #0x20+var_18 ; this
01A56F0C                 BL              _ZNK2Lp3Utl9ByamlData7getTypeEv ; Lp::Utl::ByamlData::getType(void)
01A56F10                 AND             W8, W0, #0xFF
01A56F14                 CMP             W8, #0xFF
01A56F18                 B.EQ            loc_1A56F44
01A56F1C                 ADD             X0, SP, #0x20+var_18 ; this
01A56F20                 BL              _ZNK2Lp3Utl9ByamlData7getTypeEv ; Lp::Utl::ByamlData::getType(void)
01A56F24                 AND             W8, W0, #0xFF
01A56F28                 CMP             W8, #0xD1
01A56F2C                 B.NE            loc_1A56F44
01A56F30                 ADD             X0, SP, #0x20+var_18 ; this
01A56F34                 BL              _ZNK2Lp3Utl9ByamlData8getValueEv ; Lp::Utl::ByamlData::getValue(void)
01A56F38                 STR             W0, [X19]
01A56F3C                 MOV             W0, #1
01A56F40                 B               loc_1A56F48
01A56F44                 MOV             W0, WZR
01A56F48                 LDP             X29, X30, [SP,#0x20+var_s0]
01A56F4C                 LDP             X20, X19, [SP,#0x20+var_10]
01A56F50                 LDR             X21, [SP+0x20+var_20],#0x30
01A56F54                 RET
```

読むのめんどくせえなあって思った方は正解です。

スーパーハカーならこれを読んで意味が理解できると思うのですが、ぼくにはちんぷんかんぷんです。

ですが、サブルーチン名からおおよその予想は付きます。

これは Byaml ファイル（ブキのパラメータなどが設定されている xml）を読み込んで、その値を返す関数です。

そして、このサブルーチンは以下のように使われます。

```
0004A59C                 ADRP            X2, #aAppversion@PAGE ; "AppVersion"
0004A5A0                 ADD             X0, SP, #0xA0+var_70 ; this
0004A5A4                 MOV             X1, X24 ; int *
0004A5A8                 ADD             X2, X2, #aAppversion@PAGEOFF ; "AppVersion"
0004A5AC                 BL              _ZNK2Lp3Utl9ByamlIter14tryGetIntByKeyEPiPKc ; Lp::Utl::ByamlIter::tryGetIntByKey(int *,char const*)
```

これは UnlockGearInfo.byml を読み込んで、そこに書かれている`AppVersion`の値を取得する関数です。

もしも「あるギア X の`UnlockVersion`が現在のスプラのバージョンよりも低ければ開放する」という仕組みですね。

じゃあ「さっきと同じように BL 命令を上書きして適当に 0（True）を返すようにすればいいんじゃないの？」と思うのですが、それではいけません。

擬似コードを読めば何故ダメなのかわかります。

```
if ( !(result & 1) )
          return result;
        if ( *((unsigned int *)v2 + 2) <= v10 )
          v12 = (int *)*((_QWORD *)v2 + 2);
        else
          v12 = (int *)(*((_QWORD *)v2 + 2) + 12 * v10);
        Lp::Utl::ByamlIter::tryGetIntByKey((Lp::Utl::ByamlIter *)&v43, v12, "AppVersion");;
```

そう、このサブルーチン`tryGetIntByKey()`は返り値をレジスタに代入していないのです。

えっ「じゃあ返り値どこにいったんだ？」となるのですが、これはアドレスがレジスタに入っているのです。

つまり、以前スペシャルの値を 0 にしたときと同じくレジスタが参照するアドレスが保持する値を 0 にすればいいことになります。

よって前回と同じように以下のようなコードで実現できます。

```
STR WZR, [X1]
```

なんで [X0] じゃなくて [X1] なのかはよくわかってませんが、まあとりあえず [X1] を指定しておけばいいと思います。

## まとめ

本当はもっと書きたかったのですが、これ以上書くとあまりに長くなりすぎるので今回はここまでとしました。

金イクラドロップ数変更を最後になかなかコードを探す機会がなかったのですが今回新しくコードを見つけられて面白かったです。

こういうコードを探す系の記事はまあぶっちゃけると人気がないのですが、需要があり続ける限りちまちま書いていこうと思います。

記事は以上。
