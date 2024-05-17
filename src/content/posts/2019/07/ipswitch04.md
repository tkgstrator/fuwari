---
title: "誰でもできるコード開発 #4"
published: 2019-07-07
description: BYAMLなどの暗号化されたXMLのデータを読み取ってその値を変更する方法について解説しています
category: Nintendo
tags: [Splatoon2, IPSwitch]
---

# 誰でもできるコード開発 #4

## はじめに

今回の内容は以下の記事の続きになります。

[誰でもできるコード開発 #3](https://tkgstrator.work/posts/2019/07/02/ipswitch03.html)

この記事を読むにあたって必ず目を通して理解しておいてください。

## BYML の値を読み取る

今回は BYML の値を読み取ってパラメータを設定するところを弄りたいと思います。

スプラトゥーンのパラメータは基本的に Byml で制御されているのでそういったサブルーチンはかなりの頻度で呼び出されます。

|   型   |  サブルーチン名   | 使用数 |
| :----: | :---------------: | :----: |
| 真理数 |  tryGetBoolByKey  |  318   |
|  整数  |  tryGetIntByKey   |  451   |
| 文字列 | tryGetStringByKey |  357   |

少なくとも 1000 回は BYML を読み込んでいることがわかりますね。

では、実際にチャレンジしてみましょう。

## Lp::Utl::ByamlIter::tryGetStringByKey

以下はブキがロックされているかどうかを調べるサブルーチンです。

さて、気になるのは整数型ではなく文字列型を調べるというところですね。

これは別名、`Lp::Utl::ByamlIter::tryGetStringByKey`と呼ばれるサブルーチンで Key が Byml のどこにあるのかを検索してくれるものです。

整数で指定するものは値段、ランク、ダメージなど整数で扱えるもの、文字列で指定するのはスペシャルの種類、ブキの名前などですね。

`tryGetIntByKey`に関しては前回の記事で解説したので説明は不要でしょう。

さて、今回は文字列型を取得してそれをなんか計算して何かしらの値を返すサブルーチンである`tryGetStringByKey()`を使ってブキの開放を行なってみましょう。

### ブキ情報パラメータ

ブキがブキチのところで買えるかどうかは WeaponInfo_Main.byml で制御されています。

どんなパラメータが存在するかというのは以下参照。

|   パラメータ   |              意味              |
| :------------: | :----------------------------: |
|    Addition    |      リリース済みかどうか      |
|  CoopAddition  | 0 以上だとサーモンランで使用可 |
| IsPressRelease |              不明              |
|     Price      |              値段              |
|      Rank      |        解放されるランク        |
|    Special     |           スペシャル           |
|  SpecialCost   |        スペシャル必要量        |
|      Sub       |          サブウェポン          |

本当はもっとあるのですが、最低限このくらい控えておけば大丈夫でしょう。

Lock というところでブキが販売されているかどうかのチェックをおこなっているので、ここがどんな値を取りうるかを調べます。

| パラメータ  |         意味         |
| :---------: | :------------------: |
|    None     |      ロックなし      |
|    Bcat     |     Bcat で解放      |
| NotForeSale |       販売なし       |
|   Mission   | ミッション達成で開放 |
|    Other    |         不明         |

要するに全てのブキに対して None を返せばロックが外れるという仕組みです。

ただし、Rank 制限はこれとはまた別に引っかかってくるのでこちらも解除する必要があります。

```
00038EA4                 ADRP            X2, #aLock@PAGE ; "Lock"
00038EA8                 SUB             X0, X29, #-var_C8 ; this
00038EAC                 ADD             X1, SP, #0x630+src ; char **
00038EB0                 ADD             X2, X2, #aLock@PAGEOFF ; "Lock"
00038EB4                 STR             WZR, [SP,#0x630+var_20C]
00038EB8                 BL              _ZNK2Lp3Utl9ByamlIter17tryGetStringByKeyEPPKcS3_ ; Lp::Utl::ByamlIter::tryGetStringByKey(char const**,char const*)
00038EBC                 MOV             W21, WZR
```

このコードがどのように動いているかを考えましょう。

```
Lp::Utl::ByamlIter::tryGetIntByKey((Lp::Utl::ByamlIter *)&v269, (int *)&v260, "SpecialCost");
v263 = 0;
Lp::Utl::ByamlIter::tryGetStringByKey((Lp::Utl::ByamlIter *)&v269, (const char **)&v239, "Lock");
v120 = 0;
```

擬似コードだとこのようになっているので、何かの変数に値を代入しているわけではありません。

こういう場合は前回も説明したように X1 レジスタが示すアドレスに値を格納していることが多いです。

つまり、大雑把にいえば以下のようなコードを書きたいわけです。

```
STR "None", [X1]
```

ところがレジスタに文字列は代入できません、できるのは文字列があるポインタを代入することくらいです。

これは困りましたね...

### Enum とは

さてここで使われるのが Enum という仕組みです。

Enum というのはこれまた大雑把にいうと配列のようなものです（正確には列挙型というらしい）

文字列のイテレータ（ポインタ）が Enum の何番目にあるのかを返して、それに対してパラメータを設定するわけです。

つまり、最初の`Lp::Utl::ByamlIter::tryGetStringByKey`は指定した文字列があるポインタを返し、そのポインタが参照している値が Enum の配列の何番目にあるのかを返すサブルーチンがまた別にあるということです。

この辺、解釈超適当なので大幅に間違っている可能性アリ。

「そんな都合がいいサブルーチンある？」と思うかもしれませんが、あります。

### Cmn::WeaponData::LockType::text\_(int)

直後にあるこのサブルーチンがポインタから値を設定するサブルーチンです。

このサブルーチン、あまりに長いので省略しますが次のような箇所を見てみるとたしかに Enum を使って TextPtr（テキストポインタ）を操作していそうなことがわかります。

```
00053DFC                 BL              _ZN4sead8EnumUtil10parseText_EPPcS1_i ; sead::EnumUtil::parseText_(char **,char *,int)
00053E00                 STR             X21, [X24] ; Cmn::WeaponData::LockType::text_(int)::spTextPtr
```

ここでの各自のパラメータにおける Enum の値（これが正しい書き方なのかわからん）は以下のとおりです。

| パラメータ  | Enum |
| :---------: | :--: |
|    None     |  0   |
|    Bcat     |  1   |
| NotForSale  |  2   |
|   Mission   |  3   |
| MissionBcat |  4   |
|    Other    |  5   |

None が 0 なのがいいですね、0 に設定するのは楽なので。

## 擬似コード

さて、ここまでの話をまとめると`tryGetStringBykey()`は文字列があるポインタを返すのでそのままでは上手く値を上書きできないということでした。

ところが、そのポインタを使って Enum（配列）のイテレータを返す`LockType::text()`というサブルーチンがあり、これを利用することで値を設定できそうという流れでした。

```
Lp::Utl::ByamlIter::tryGetStringByKey((Lp::Utl::ByamlIter *)&v269, (const char **)&v239, "Lock");
v120 = 0;
while (1)
{
    v224 = off_3DFE3D8;
    v225 = v239;
    v121 = (char *)Cmn::WeaponData::LockType::text_((Cmn::WeaponData::LockType *)v120);
    v222 = off_3DFE3D8;
    v223 = v121;
    ((void(__fastcall *)(__int64(__fastcall ***)()))v224[3])(&v224);
    ((void(__fastcall *)(__int64(__fastcall ***)()))v224[3])(&v224);
    v122 = v225;
    ((void(__fastcall *)(__int64(__fastcall ***)()))v222[3])(&v222);
    if (v122 == v223)
        break;
    v123 = 0LL;
    v124 = v223 + 1;
    do
    {
        v125 = (unsigned __int8)v225[v123];
        if (v125 != (unsigned __int8)v223[v123])
            break;
        if (v125 == (unsigned __int8)sead::SafeStringBase<char>::cNullChar)
            goto LABEL_244;
        v126 = (unsigned __int8)v225[v123 + 1];
        if (v126 != (unsigned __int8)v124[v123])
            break;
        if (v126 == (unsigned __int8)sead::SafeStringBase<char>::cNullChar)
            goto LABEL_244;
        v127 = (unsigned __int8)v225[v123 + 2];
        if (v127 != (unsigned __int8)v124[v123 + 1])
            break;
        if (v127 == (unsigned __int8)sead::SafeStringBase<char>::cNullChar)
            goto LABEL_244;
        v123 += 3LL;
    } while (v123 < 524289);
    if ((signed int)++v120 >= 6)
        goto LABEL_245;
}
LABEL_244 : v263 = v120;
```

さて、このサブルーチンをどういじっていいのかわからないと思いますが（ここを解析するのにすっごい時間がかかった）

最終的に goto LABEL_244 に到達して v263=v120 という処理をおこなっていることに注目すれば何となく分かると思います。

ここでは v120 は W21 レジスタで、v263 は [SP, #0x424] を意味しています。

つまり、W21 レジスタの中身を "わざわざ" メモリにコピーしているということです。

本来は W21 レジスタの中身をコピーしているところを None（Enum だと 0）をコピーすればいいのでゼロレジスタを使います。

```
//  Before
STR W21, [SP,#0x424]

// After
STR WZR, [SP,#0x424]
```

さて、これで常に Lock の値として None を返すコードが書けます。

```
// Unlock Weapon (3.1.0) [tkgling]
@disabled
00038F98 FF2704B9 // STR WZR, [SP, #0x424]

// Unlock Weapon (5.4.0) [tkgling]
@disabled
000865E8 FF2704B9 // STR WZR, [SP, #0x424]
```

ところがこれはランクが足りない場合には購入できません。

ランクによるロックは以下のアセンブリで与えられます。

ついでなので値段も変更してしまいましょう。

```
00038D1C                 LDR             X1, [SP,#0x630+var_5C8] ; int *
00038D20                 ADRP            X2, #aPrice@PAGE ; "Price"
00038D24                 SUB             X0, X29, #-var_C8 ; this
00038D28                 ADD             X2, X2, #aPrice@PAGEOFF ; "Price"
00038D2C                 BL              _ZNK2Lp3Utl9ByamlIter14tryGetIntByKeyEPiPKc ; Lp::Utl::ByamlIter::tryGetIntByKey(int *,char const*)
00038D30                 LDR             X1, [SP,#0x630+var_5D0] ; int *
00038D34                 ADRP            X2, #aRank@PAGE ; "Rank"
00038D38                 SUB             X0, X29, #-var_C8 ; this
00038D3C                 ADD             X2, X2, #aRank@PAGEOFF ; "Rank"
00038D40                 BL              _ZNK2Lp3Utl9ByamlIter14tryGetIntByKeyEPiPKc ; Lp::Utl::ByamlIter::tryGetIntByKey(int *,char const*)
```

以下のようにどちらも値をレジスタに直接代入していないので、[X1] レジスタにコピーするコードを書きましょう。

```
Lp::Utl::ByamlIter::tryGetIntByKey((Lp::Utl::ByamlIter *)&v269, &v261, "Price");
Lp::Utl::ByamlIter::tryGetIntByKey((Lp::Utl::ByamlIter *)&v269, &v262, "Rank");
```

やることが同じなのでどちらも同じコードが書けます、違うのはアドレスだけです。

```
// Free Weapon
STR WZR, [X1]
```

```
// Unlock All Weapon
STR WZR, [X1]
```

これを ARM to HEX で変換してアドレスを追加して IPSwitch で使える形式にします。

```
// Free Weapon (3.1.0) [tkgling]
@disabled
00038D2C 3F0000B9 // STR WZR, [X1]

// Free Weapon (5.4.0) [tkgling]
@disabled
0008637C 3F0000B9 // STR WZR, [X1]
```

```
// Unlock All Weapon (3.1.0) [tkgling]
@disabled
00038D40 3F0000B9 // STR WZR, [X1]

// Unlock All Weapon (5.4.0) [tkgling]
@disabled
00086390 3F0000B9 // STR WZR, [X1]
```

## 全ブキ開放

やろうと思ったのですが、クマブキやその他の未リリースブキの開放のためのパラメータがわかんなかったので中途半端になっちゃいました。

一応別のコードを使って全ブキをデバッグ状態っぽく開放すれば購入はできるのですが、いろいろバグっているので公開は控えます。

```
// Unlock All Weapon (3.1.0) [tkgling]
@disabled
00038D2C 3F0000B9 // STR WZR, [X1]
00038D40 3F0000B9 // STR WZR, [X1]
00038F98 FF2704B9 // STR WZR, [SP, #0x424]

// Unlock All Weapon (5.4.0) [tkgling]
@disabled
0008637C 3F0000B9 // STR WZR, [X1]
00086390 3F0000B9 // STR WZR, [X1]
000865E8 FF2704B9 // STR WZR, [SP, #0x424]
```

というわけで、とりあえずクマブキやその他のヘンテコなブキ以外は全部開放できるコードをつくりました。

ランクが低くても全てのブキが購入でき、未リリースブキも買えます。

記事は以上。
