---
title: サーモンランのWAVE内容を先読みする方法と解説
published: 2021-01-22
description: No description
category: Nintendo
tags: [Salmon Run]
---

## WAVE 内容とは

サーモンランでは少なくとも以下の九つの内容がバイト開始時に決定されています。

1. 各 WAVE の潮位
2. 各 WAVE のイベント内容
3. 各 WAVE のシャケの湧き方向
4. 各 WAVE の出現するオオモノシャケの種類
5. キンシャケ探しイベントでのアタリ位置
6. 霧イベントでのキンシャケのドロップ数
7. ラッシュイベントでの最初にヒカリバエがつくプレイヤー
8. ランダム時に支給されるブキ
9. 支給されるスペシャルウェポン

これらの内容を WAVE 中のプレイヤーの行動などで変化させることは絶対にできません。

### サーモンラン通信プロトコル

サーモンランはバイト開始時に`Cnet::PacketSeqEventCoopSetting::PacketSeqEventCoopSetting()`という関数が呼び出され、ホストが接続しているクライアントに対して設定されたパラメータを送信します。

送信される内容は以下の通り。

- 初期シード（サーモンランのゲームの全てを司る値）
- インクの色（イカちゃんチームの色のみ変更可能）
- BGM の種類（通常用とランダム用があるみたい）
- 遊ぶステージ（ナワバリのステージなどを選ぶとクラッシュする）

ここで大事になるのが初期シードであり、これが先程述べた九つの WAVE 内容全てを決定する値になります。

## 各パラメータの計算アルゴリズム

アルゴリズム自体は C++、Python、Javascript などに移植しているのですが、今回は最もわかりやすいと思われる Python のコードを紹介します。

### 初期シードから擬似乱数生成

```python
class NSRandom:
mSeed1 = 0x00000000
mSeed2 = 0x00000000
mSeed3 = 0x00000000
mSeed4 = 0x00000000

    def __init__(self):
        pass

    def init(self, seed):
        self.mSeed1 = 0xFFFFFFFF & (0x6C078965 * (seed ^ (seed >> 30)) + 1)
        self.mSeed2 = 0xFFFFFFFF & (0x6C078965 * (self.mSeed1 ^ (self.mSeed1 >> 30)) + 2)
        self.mSeed3 = 0xFFFFFFFF & (0x6C078965 * (self.mSeed2 ^ (self.mSeed2 >> 30)) + 3)
        self.mSeed4 = 0xFFFFFFFF & (0x6C078965 * (self.mSeed3 ^ (self.mSeed3 >> 30)) + 4)

    def getU32(self):
        n = self.mSeed1 ^ (0xFFFFFFFF & self.mSeed1 << 11)
        self.mSeed1 = self.mSeed2
        self.mSeed2 = self.mSeed3
        self.mSeed3 = self.mSeed4
        self.mSeed4 = (n ^ (n >> 8) ^ self.mSeed4 ^ (self.mSeed4 >> 19))

        return self.mSeed4
```

乱数生成器は初期シードで初期化され、その後`getU32()`を呼び出すことで乱数を生成します。

ここで大事なことは、初期シードさえわかればその後生成される全ての乱数は予測可能だということです。

### 潮位・イベント決定アルゴリズム

```python
def getWaveInfo(self):
mEventProb = [18, 1, 1, 1, 1, 1, 1]
mTideProb = [1, 3, 1]
self.rnd.init(self.mGameSeed)

    for wave in range(3):
        sum = 0
        for event in range(7):
            if (
                (wave > 0)
                and (self.mEvent[wave - 1] != 0)
                and (self.mEvent[wave - 1] == event)
            ):
                continue
            sum += mEventProb[event]
            if (self.rnd.getU32() * sum >> 0x20) < mEventProb[event]:
                self.mEvent[wave] = event
        sum = 0
        for tide in range(3):
            if tide == 0 and 1 <= self.mEvent[wave] and self.mEvent[wave] <= 3:
                continue
            sum += mTideProb[tide]
            if (self.rnd.getU32() * sum >> 0x20) < mTideProb[tide]:
                self.mTide[wave] = 0 if self.mEvent[wave] == 6 else tide
```

アルゴリズムではまず最初にイベントを決定します。

WAVE1 のイベントは完全にランダムに選ばれますが、WAVE2 以降は「一つ前の WAVE と同じイベントではない」「一つ前の WAVE はイベントなしではない」という条件が付きます。

なので、連続して同じイベントが発生することは絶対にありません。

イベントが決まったあとに潮位を決定しますが、初期状態は通常潮位に設定されています。

ここで潮位を計算するのですが、潮位が干潮になった場合「イベントがキンシャケ探しかグリルかラッシュ」ならその計算をなかったことにします。そして、ドスコイ大量発生の場合はどんな潮位であっても強制的に干潮に変化します。

まあこれはコードを読んだ方がわかりやすいですね。

### 各 WAVE シード生成アルゴリズム

サーモンランには最も基本となる初期シードの他に、WAVE ごとの細かいパラメータを決定する WAVE シードがあります。WAVE は三つ存在するので、WAVE シードは三つあるわけです。

そして、大事なことは全ての WAVE シードは初期シードから生成されるということです。

なので、初期シードが決まった時点で WAVE シードも予測可能になります。

```python
def setWaveMgr(self):
self.rnd.init(self.mGameSeed)
self.rnd.getU32()
self.mWaveMgr = [
WaveMgr(0, self.mGameSeed),
WaveMgr(1, self.rnd.getU32()),
WaveMgr(2, self.rnd.getU32()),
]
```

興味深いのは WAVE1 の WAVE シードは初期シードであるということです。

そして WAVE2 は初期シードから二回目に生成された乱数が使われます。何故一回、乱数をむだうちしているのかはわかりません。

### キンシャケ探しアタリ位置計算アルゴリズム

```python
def getGeyserPos(self):
self.rnd.init(self.mWaveSeed)
mReuse = [False, False, False, False]
mPos = ["D", "E", "F", "G"]
mSucc = []

for idx in range(15):
for sel in range(len(mPos) - 1, 0, -1):
index = (self.rnd.getU32() * (sel + 1)) >> 0x20
mPos[sel], mPos[index] = mPos[index], mPos[sel]
mReuse[sel], mReuse[index] = mReuse[index], mReuse[sel]
mSucc += mPos[0]
if mReuse[0]:
self.rnd.getU32()
return mSucc
```

キンシャケ探しのアタリ位置を計算するためには「キンシャケ探しのアタリ位置候補」と「乱数消費フラグ」の二つが必要になります。

今回は朽ちた方舟ポラリスの満潮時のアタリ位置を計算するコードをご紹介します。

乱数消費フラグがなんのためにあるかと言うと、アタリ位置に対してゴール候補が二箇所以上ある場合はどちらのゴールに向かうかを計算するために一回余計に乱数が消費されるためです。

満潮ポラリスは常にゴール候補が一つしかないので、全てのアタリ位置に対して乱数消費フラグは False になっています。

### 湧き方向計算アルゴリズム

```python
def getEnemyAppearId(self, previousId):
mArray = [1, 2, 3]
mIndex = 0
w6 = 3
x6 = 3
v5 = previousId
w7 = mArray
if not (id & 0x80000000):
w8 = w6 - 1
while True:
v17 = w8
w9 = w7[mIndex]
if w9 < id:
break
w6 -= w9 == id
if w9 == id:
break
w8 = v17 - 1
mIndex += 1
if not v17:
break

    mIndex = 0
    x7 = mArray
    x8 = 0xFFFFFFFF & (self.rnd.getU32() * w6 >> 0x20)

    while True:
        x9 = x7[mIndex]
        x10 = 0 if x8 == 0 else x8 - 1
        x11 = x9 if x8 == 0 else v5
        x12 = 5 if x9 == v5 else x8 == 0
        if x9 != v5:
            x8 = 0xFFFFFFFF & x10
            id = x11
        if (x12 & 7) != 5 and (x12 & 7):
            break
        x6 -= 1
        mIndex += 1
        if not x6:
            return v5
    return id
```

Python ではポインタが使えないため、アセンブラから上手く復元することができませんでした。

また、これらのコードは最適化できていないため読んでも意味のわからないものになっています。

ちなみに、previousId は一つ前の湧き方向を意味します。何故かはわからないのですが、previousId が 1 だと、この関数は殆どの場合（絶対かもしれない）1 以外を返します。

### 出現オオモノ計算アルゴリズム

```python
def getEnemyId(self):
mRnd = NSRandom.NSRandom()
mRnd.init(self.rnd.getU32())

    mRareId = 0
    for mProb in range(7):
        if not (mRnd.getU32() * (mProb + 1) >> 0x20):
            mRareId = mProb
    return mRareId
```

出現するオオモノは湧き方向に比べて簡単です。

オオモノが出現することが呼び出されるたびに新たに乱数生成器を乱数で初期化し、生成した乱数から計算します。計算方法も単純で、7 で割ったあまりによって出現するオオモノが決まるだけです。

## 未解決アルゴリズム

1. 霧イベントでのキンシャケのドロップ数
2. ラッシュイベントでの最初にヒカリバエがつくプレイヤー
3. ランダム時に支給されるブキ
4. 支給されるスペシャルウェポン

この四つに関しては、未だにアルゴリズムが解析できていないため初期シードから予測することができません。

霧イベントについては、どの関数がドロップ数を決めているかまでは分かっているのですが「どの乱数生成器が使われているか」がわかっていないため、予測することができていません。

まあこれが一番解析しやすそうな気はするので、誰か頼んだ。

## Ocean Calc

[LanPlay Records](https://salmonrun-records.netlify.app/ocean/)

で、今まで紹介した全アルゴリズムを搭載した WAVE 内容予測アプリがこの Ocean Calc です。

計算アルゴリズムはオンラインプレイでも LanPlay でも同じなので、一度遊んだシードを特定することができれば、それ以後の全ての湧き方向やイベント内容を先読みすることができます。

@[youtube](https://www.youtube.com/watch?v=uX9lMgpcrlA)

例えば、ポラリス満潮キンシャケ探しの現在の世界記録である 122 納品を達成したときのシードは`0xFABAD087`であることがわかっています。

[LanPlay Records](https://salmonrun-records.netlify.app/ocean/?seed=0xFABAD087)

上のリンクで実際にどんな WAVE 内容なのかがチェックできるので、ズレていないことを確かめてみてください。

これを利用すればキンシャケ探しで一発でアタリ位置を見つけることが可能ですし、稼げない WAVE だということが始める前からわかるわけです。

## SeedHack とは

ぼくが勝手につくった言葉で、ホストが送信するシードをパッチを使って強制的に変更することで任意の WAVE を呼び出すことができるハックのことです。

イカッチャにおいてもやりたいイベントの組み合わせの WAVE を引くのはとてつもなく低い確率になるので、初期シードを好きなものにすることで確実に毎回同じ WAVE が来るようにするわけです。

SeedHack 自体は初期シードを変更しているだけですので、言ってしまえば乱数調整と同じでそれ自体に納品数を増やしたりパラメータを強化したりする効果は全くありません。好きな WAVE を呼び寄せることができると言うだけです。

で、その呼び寄せたい WAVE はキンシャケ探しのアタリ位置なども事前に計算しているので、一回も外すことなくアタリを当てられるというだけです。

@[youtube](https://www.youtube.com/watch?v=0P9IlQ-9ciM)

自分がアップロードしている多くの LanPlay の動画はこのハックを使って理想の WAVE を呼び寄せています。でないと「いい WAVE」がくるのを待って水没を繰り返すのが時間の無駄だからです。

結論から言えば、SeedHack 自体はパッチを使用してはいるものの完全なチートとは言えません。時間をかければ誰でも同じ状況が再現できます。

ちなみに 404 納品を達成したシードは以下のリンクから見れます。

[LanPlay Records](https://salmonrun-records.netlify.app/ocean/?seed=0xFABAD087)

記事は以上、勝ったなガハハ。
