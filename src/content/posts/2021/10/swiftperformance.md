---
title: Swift-Benchmarkで実行速度を調査する
published: 2021-10-18
category: Programming
tags: [Swift]
---

# Swift Benchmark

Google が開発した Swift 用のベンチマークライブラリ。下手に自分で書くより、Google 謹製のライブラリを使ったほうが便利そうなので使ってみました。

## Random

現在開発中の Ocean ライブラリがあまりにも遅いのでいろいろ改良してみることにしました

Ocean ライブラリでは乱数を何度も生成するので、乱数生成が遅いとそれだけでボトルネックになってしまいます。ちなみに、オリジナルのコードは以下のような感じになっています。

```swift
import Foundation

final class Random {
    private(set) var mSeed1: Int64 = 0
    private(set) var mSeed2: Int64 = 0
    private(set) var mSeed3: Int64 = 0
    private(set) var mSeed4: Int64 = 0

    init() {}

    init(seed: Int64) {
        self.mSeed1 = 0xFFFFFFFF & (0x6C078965 * (seed   ^ (seed   >> 30)) + 1)
        self.mSeed2 = 0xFFFFFFFF & (0x6C078965 * (mSeed1 ^ (mSeed1 >> 30)) + 2)
        self.mSeed3 = 0xFFFFFFFF & (0x6C078965 * (mSeed2 ^ (mSeed2 >> 30)) + 3)
        self.mSeed4 = 0xFFFFFFFF & (0x6C078965 * (mSeed3 ^ (mSeed3 >> 30)) + 4)
    }

    @discardableResult
    func getU32() -> Int64 {
        let n = mSeed1 ^ (0xFFFFFFFF & mSeed1 << 11);

        mSeed1 = mSeed2;
        mSeed2 = mSeed3;
        mSeed3 = mSeed4;
        mSeed4 = n ^ (n >> 8) ^ mSeed4 ^ (mSeed4 >> 19);

        return mSeed4;
    }
}
```

スプラトゥーンの疑似乱数生成器自体は非常にシンプルです。

計算結果を UInt32 に落とし込むために`0xFFFFFFFF`で論理和をとっていますがこれがまずなんか遅そうです。仮に論理和計算が 1 クロックで実行できたとしてもインスタンス実行のたびに 4 クロック余計に消費してしまいます。

ただ、そのまま UInt32 で定義するとオーバーフローでエラーが発生して`0x6C078965`との演算ができないという問題がありました。

### オーバーフロー演算子を使う

調べてみたところ、デフォルトでは Swift はオーバーフローをエラーとして返すようなのですが、オーバーフローを許容するオーバーフロー演算子なるものがあり、それを使えば C のようにオーバーフローを利用した計算が可能になるようなのです。

```swift
final class Random {
    private(set) var mSeed1: UInt32 = 0
    private(set) var mSeed2: UInt32 = 0
    private(set) var mSeed3: UInt32 = 0
    private(set) var mSeed4: UInt32 = 0

    init() {}

    init(seed: UInt32) {
        self.mSeed1 = (0x6C078965 &* (seed   ^ (seed   >> 30)) + 1)
        self.mSeed2 = (0x6C078965 &* (mSeed1 ^ (mSeed1 >> 30)) + 2)
        self.mSeed3 = (0x6C078965 &* (mSeed2 ^ (mSeed2 >> 30)) + 3)
        self.mSeed4 = (0x6C078965 &* (mSeed3 ^ (mSeed3 >> 30)) + 4)
    }

    @discardableResult
    func getU32() -> UInt32 {
        let n = mSeed1 ^ (mSeed1 << 11);

        mSeed1 = mSeed2;
        mSeed2 = mSeed3;
        mSeed3 = mSeed4;
        mSeed4 = n ^ (n >> 8) ^ mSeed4 ^ (mSeed4 >> 19);

        return mSeed4;
    }
}
```

というわけでオーバーフロー演算子を利用して純粋な UInt32 だけで計算できるように`Random`クラスを書き直しました。

### パフォーマンスを調べる

試しに Swift 謹製の`measure`を使って計測した結果がこちら。

| コード | 一回目平均 | 二回目平均 | 三回目平均 |
| :----: | :--------: | :--------: | :--------: |
| Int64  |   1.688    |   1.695    |   1.689    |
| UInt32 |   1.716    |   1.753    |   1.783    |

あれ、なんだか逆に遅くなっているんですけど？？？

いや、でもデフォルトのテストではデバッグビルドで最適化されていないために差が生じないのかもしれません。そこで Swift Benchmark を使って再度計測してみました。

#### Swift Benchmark

実行回数を`0xFFFFF=1048575`にして比較してみました。

```
$ swift run -c release
[2/2] Build complete!
running UInt32 Random... done! (1642.54 ms)
running Int64 Random... done! (2400.14 ms)

name          time           std        iterations
--------------------------------------------------
UInt32 Random 2034539.000 ns ±   5.17 %        688
Int64 Random  8984566.000 ns ±   2.43 %        155
```

リリースビルドで測定し直した結果、インスタンス生成の 4.5 倍ほどの高速化に成功しました！

| Initialize Random Instance | オリジナル | 改良版  |
| :------------------------: | :--------: | :-----: |
|        実行時間[ns]        |  8182582   | 1971949 |
|           速度比           |    1.0     |  4.14   |

## 乱数生成

疑似乱数生成には`getU32()`というメソッドを利用するのですが、こちらも Int64 仕様だったため UInt32 仕様に変更しました。

`getU32()`は控えめに数えても 1000 億回くらいは呼ばれるので、ここが高速化されることが最もプログラム全体の高速化に繋がります。

| Generate Random Number | オリジナル | 改良版 |
| :--------------------: | :--------: | :----: |
|      実行時間[ns]      |  5826645   | 937798 |
|         速度比         |    1.0     |  8.73  |

こちらは約 8.7 倍程度高速化できました。

## Ocean

```swift
import Foundation

public final class Ocean {
    public init(mGameSeed: UInt32) {
        self.mGameSeed = mGameSeed
        self.rnd = Random(seed: mGameSeed)
        rnd.getU32()
        self.mWave = [
            Wave(mGameSeed),
            Wave(rnd.getU32()),
            Wave(rnd.getU32()),
        ]
        self.getWaveInfo()
    }

    private let rnd: UInt32Random

    public private(set) var mWave: [Wave]

    public private(set) var mGameSeed: UInt32
}
```

さて、次に疑似乱数生成器を持つ`Ocean`クラスを定義します。オリジナルのコードは上のような感じです。

これも同じように 100 万回インスタンスを生成してみると...

| Initialize Ocean Instance | オリジナル | 改良版 |
| :-----------------------: | :--------: | :----: |
|       実行時間[ns]        | 4294175274 |   -    |
|          速度比           |    1.0     |   -    |

なんとたったの 100 万件のインスタンス生成に 4 秒もかかってしまいました。この調子でやれば全 43 億通りをチェックするにはこの 4096 倍の時間がかかるので 5 時間位かかる計算になります、だめだこりゃ。

### 継承クラスにする

ここで問題になるのは`Ocean`クラスの中で`Random`クラスを呼び出しているという点です。

Ocean クラス一つに対して疑似乱数生成器は一つあればいいので、わざわざプロパティとして持たずに`Ocean`クラス自体に疑似乱数生成機能を持たせてやればよいです。

```swift
import Foundation

public final class Ocean: Random {
    public init(mGameSeed: UInt32) {
        self.mGameSeed = mGameSeed
        super.init(seed: mGameSeed)
        // 無意味に一回消費
         getU32()
         self.mWave = [
             Wave(mGameSeed),
             Wave(getU32()),
             Wave(getU32())
         ]
         self.getWaveInfo()
    }

    public let mGameSeed: UInt32
    public private(set) var mWave: [Wave] = Array<Wave>()
}
```

| Initialize Ocean Instance | オリジナル | 継承クラス |
| :-----------------------: | :--------: | :--------: |
|       実行時間[ns]        | 4294175274 | 2200337563 |
|          速度比           |    1.0     |    1.95    |

### Wave 情報を一回で計算する

次に重そうなのが配列を一回定義しておいて再度代入しているこの無駄な処理です。

一度計算してそれを代入してしたほうが速いのでそのようにコードを修正します。
