---
title: OAuth認証のための手順
published: 2021-04-08
description: SwiftでOAuthの認証のためのコードを書くためのチュートリアル
category: Programming
tags: [Swift]
---

## OAuth 認証のための手順

### Verifier と Challenge

S256 という認証システムを使う場合、Verifier と Challenge の関係は以下のようになる。

`Challenge = BASE64URL-ENCODE(SHA256(ASCII(Verifier)))`

ここで注意しなければいけないのは ASCII から SHA256 に変換する際に一度文字列を経由するとバグってしまうということだ。ここで詰まると無限に時間を消費するので気をつけてほしい。単なる SHA256 ハッシュと S256 アルゴリズムで使うハッシュ生成は全く異なるのだ。

```swift
import CryptoKit
import Fundation
```

暗号化ライブラリを使うので CryptoKit を、Data 型を扱うので Fundation を import しておこう。

### ランダム文字列: Verifier

OAuth で認証するためには Verifier と Challenge と呼ばれる二つのパラメータが必要になってくる。Verifier はある程度長い（64 や 128 が推奨されているようだ）ランダム文字列であり、Challenge は Verifier の SHA256 のハッシュとなっている。

SHA256 は Swift の場合 CryptoKit と呼ばれる iOS13 から解禁された標準ライブラリが使える。iOS13 未満の場合は CryptoSwift や Objective-C の機能である CommonCrypto を使うことになるだろう。今回は CryptoKit を用いた場合のコーディングについて解説する。

```swift
extension String {
    static func randomString(_ length: Int = 128) -> String {
        let base: [String] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~".map({String($0)})
        var random: String = ""
        for _ in Range(1...length) {
            random += base.randomElement()!
        }
        return random
    }
}
```

上のコードはランダム文字列を生成するため Extension である。Swift4.2 以前は arc4random といった C 言語から引っ張ってきた関数を使う必要があったのだが、現在では標準乱数生成メソッドが使えるのでそれを利用する。

ポイントとしては予め使われる可能性のある文字を文字列にしておき、そこから一文字区切りの配列をつくるという点である。そしてその配列からランダムに 128 回値を選び、それらを結合するというわけである。単に map を使うと String 型ではなく Character 型の配列になってしまうので型変換をする。

文字列から配列をつくるにあたって、[こちらのコード](https://qiita.com/rondine-jumpei/items/a298bf4e0612166e5dd5)が大変参考になりました。

128 回ループして結合するというコードはとりあえず For 文で書いたのだがとてもダサいのでなんとかしたい所存である。

気になる点としては暗号論的に安全な乱数になっているかというところであるが、まあ気にしなくても多分大丈夫だろう、多分。もしも`randomElement()`に何らかの偏りがある場合、Verifier を推察される可能性があり、危険である。

## SHA256: Challenge

次にこのランダム文字列を SHA256 に変換する。CryptoKit の SHA256 でハッシュを求めるアルゴリズムは引数が Data 型であり String 型ではないので、文字列を Data 型に変換する必要がある。

```swift
// OK
extension String {
    var sha256: SHA256.Digest {
        return SHA256.hash(data: Data(self.utf8))
    }
}
```

というわけで、String 型の Extension を拡張してそれ自身の SHA256 ハッシュを返せるようにした。

```swift
// NG
extension String {
    var sha256: String {
        return SHA256.hash(data: Data(self.utf8)).compactMap{String(format: "%02x", $0)}.joined()
    }
}
```

ちなみに、上のようなコードを書くと文字列を経由してしまい失敗する。こちらは単に SHA256 のハッシュが欲しい場合に使うと良い。

SHA256 ハッシュ作成に関しては[こちらのページ](https://rono23.com/posts/pkec-code-challenge/)が大変参考になりました。

## Base64Encode: Challenge

実は Challenge は単なる SHA256 ハッシュではなく、そのハッシュを Base64 エンコードしたものとなっている。なぜ二回ハッシュを計算するのかわからないが（しかも Base64 は安全なハッシュとは言えない）、仕様書でそうなっているのでそうするしかない。

SHA256 のハッシュから直接 Base64 を返したいので標準ライブラリを用いて以下のように実装した。PKCE では Base64 の値のうち「=」、「+」、「/」の三つについては正しくエスケープしないといけない。

```swift
extension SHA256.Digest {
    var base64EncodedString: String {
        return Data(self).base64EncodedString()
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
    }
}
```

なので非常に冗長になるが、`base64EncodedString()`を拡張して PKCE 用の Base64 文字列を返すようにした。

この状態で`E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM`を Verifier として設定し、Challenge を計算すると正しく`E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM`を得ることができた。
