---
title: プロトコルの準拠とその罠について
published: 2021-06-18
description: プロトコルを学ぶとコーディングがとても便利になります
category: Programming
tags: [Swift, SwiftUI]
---

# プロトコルとは

プロトコルとはそのプロトコルに準拠しているクラスや構造体に対して共通のルールを設定するものです。

感覚としてはジェネリクスに近いのでまずはジェネリクスの例から考えてみます。

## ジェネリクスの考え方

例えば、二つの入力された整数の積を計算する関数を考えます。

```swift
import SwiftUI

print(multiple(10, 5)) // 50

func multiple(_ a: Int, _ b: Int) -> Int {
    return a * b
}
```

すると計算結果として正しく 50 を得ることができます。

ただ、これだと整数同士での掛け算にしか対応していません。もし次のように実数同士を引数に与えると型が違うので計算できないと言われてしまいます。

```swift
print(multiple(10.0, 5.0)) // Cannot convert value of type 'Double' to exptected argument type 'Int'
```

それでは困るので「実数同士」でも計算できるようにしてみます。

Swift は関数のオーバーロードに対応しているので、全く同じ関数名でも引数が少し違えば定義可能です。

```swift
import SwiftUI

print(multiple(10, 5))
print(multiple(10.0, 5.0))

func multiple(_ a: Int, _ b: Int) -> Int {
    return a * b
}

func multiple(_ a: Double, _ b: Double) -> Double {
    return a * b
}
```

しかし、よく考えるとこの実装方法は愚直であることに気付きます。一方だけが`Int`のときや、型が`CGFlaot`のときなどありとあらゆるパターンを考えていると関数の定義だけがどんどん増えてしまうからです。

そこで任意の型を引数にとれるように関数自体を改良します。

```swift
func multiple<T>(_ a: T, _ b: T) -> T {
    return a * b
}
```

というわけで、任意の型である`T`を引数としてとり、その結果として型`T`を返す関数に改良しました。

が、これはそのままではコンパイルエラーが発生します。

というのも、計算式の途中にある`a * b`が計算可能であるためには`T`が掛け算可能な型である必要があるためです。なので、`T`は単なる「任意の型」ではなく「任意の掛け算可能な型」として再定義します。

```swift
func multiple<T: Numeric>(_ a: T, _ b: T) -> T {
    return a * b
}
```

掛け算可能な型であることを明示するためには`T`が`Numeric`に準拠させればよいです。`FloatingPoint`に準拠させても同様の処理は可能ですが、`FloatingPoint`は実数であることを前提としているので返り値も必ず実数になってしまいます。

整数同士での計算は整数で返したいのでこの場合は`Numeric`の方が良いでしょう。



## 算術プロトコル

算術プロトコルにはたくさんあるのですが、まあとりあえず以下の三つがよく出てきます。

|     プロトコル     | 加算 | 減算 | 乗算 | 除算 |
| :----------------: | :--: | :--: | :--: | :--: |
| AdditiveArithmetic | YES  | YES  |  -   |  -   |
|      Numeric       | YES  | YES  | YES  |  -   |
|   FloatingPoint    | YES  | YES  | YES  | YES  |

除算までサポートしようとすると FloatingPoint を利用する必要があるわけですね。

そこで、二つの数を引数にとって`a / b`の値を返す`divide()`の関数を以下のようにつくります。

```swift
func divide<T: FloatingPoint>(_ a: T, _ b: T) -> T {
    return a / b
}
```

これはこれで別に問題なく動作するのですが、整数型同士で計算した場合少し違和感があります。

```swift
print(10/5)             // 2
print(divide(10, 5))    // 2.0
```

というのも単に整数型同士で除算した場合は、計算結果も整数になるのに対して、`divide()`を利用した場合は返り値が`FloatingPoint`型のために必ず実数で出力されてしまうという点です。

また、`Int`型は`FloatinPoint`に準拠していないため以下のコードのように変数の型を明示してしまうとコンパイルエラーが発生してしまいます。

```swift
let a: Int = 10
let b: Int = 5

print(divide(a, b)) // Global function 'divide' requires that 'Int' conform to 'FloatingPoint'
```

### 暫定処置

`FloatingPoint`と`Int`に互換性がない以上は一つの関数で処理するのは難しそうなので以下のようにコードを改良するのが一つの手ではあります。

それか、引数に代入するときに`Double`や`CGFloat`などにキャストします。もっと上手い解決策がありそうなのですが、わからなかったのでとりあえずこれで対応しています。

```swift
func divide<T: FloatingPoint>(_ a: T, _ b: T) -> T {
    return a / b
}

func divide(_ a: Int, _ b: Int) -> Int {
    return a / b
}
```

## プロトコルを型として利用する

さて、ここまでの話はプロトコルを使って変数の引数を柔軟に扱おうという話でした。

ここからは更に一方進んでプロトコルに準拠したクラスや構造体をつくり、それらを変数として扱いたい場合を考えます。

話がややこしいので具体例を出します。例えば Dog クラスと Cat クラスを作成し、プロパティとして名前をもたせるとします。

```swift
class Dog {
    let name: String
}

class Cat {
    let name: String
}
```

そして、次に飼い主のクラスを作成します。愚直に書くと以下のようになります。

猫を飼っている人がいるかも知れませんし、犬を買っている人がいるかも知れないので犬と猫のどちらもプロパティにもつ必要があります。

```swift
class Person {
    let cats: [Cat]
    let dogs: [Dog]
}
```

ここで問題になるのは、動物の種類が増えるとプロパティ名が無数に増えていってしまい可読性が低下するという点です。

### プロトコルで解決する

そこで、犬と猫をどちらも一括で扱えるような`Animal`プロトコルを作成します。

```swift
protocol Animal {
    var name: String { get } // Required
}

class Dog: Animal {
    var name: String // Required
}

class Cat: Animal {
    var name: String // Required
}
```

```swift
class Person {
    let animals: [Animal]
}
```

### イニシャライザを定義する

このままだとわかりにくいのでイニシャライザをつけてコンパイルが通るようにします。

プロトコルで設定されている変数や関数は必ずそのプロトコルを準拠するクラスなどでは宣言しなければいけません。変数の場合はそのままかけばいいのですが、イニシャライザの場合は`required`とつけてプロトコルの準拠のために必要であることを明示する必要があります。

```swift
import SwiftUI

protocol Animal {
    var name: String { get } // Required
    init(name: String)
}

class Dog: Animal {
    var name: String // Required

    required init(name: String) { // Required
        self.name = name
    }
}

class Cat: Animal {
    required init(name: String) { // Required
        self.name = name
    }

    var name: String // Required
}

class Person {
    var animals: [Animal]

    init(animals: [Animal] = []) {
        self.animals = animals
    }
}
```

### サンプルコード

```swift
let mike: Cat = Cat(name: "Mike")
let nike: Dog = Dog(name: "Nike")

let tom = Person(animals: [mike, nike])

for animal in tom.animals {
    print(animal.name) // Mike, Nike
}
```

For 文の中でそれぞれ異なるクラスのオブジェクトをループさせているのに`animal.name`で名前を呼び出せるのは、`animal`が`Animal`プロトコルに準拠しており、必ず`name`のプロパティを持っていることが担保されているためです。

```swift
protocol Animal {
    var name: String { get } // <- Required
    init(name: String)
}
```

もしここでこの行をコメントアウトすると`Value of type 'Animal' has no member 'name'`とコンパイルエラーが表示されます。

## プロトコルに準拠した Enum を作成する

今回考えて悩んだのはここでした。

いまネットワーク系のライブラリを作成しているのですが、そのライブラリは通信が失敗した際にはエラーを返します。ここではそのライブラリが返すエラーは`APIErrorA`という`Enum`だとします。

そして仮にエラーの種類が二種類しかないとすると、次のように定義すれば良いわけです。

```swift
enum APIErrorA: Error {
    case forbidden
    case invalid
}
```

そして次にそのライブラリを使用するアプリを考えてみます。アプリは基本的にはこの`APIErrorA`を使ってエラーを表示すれば良いのですが、エラーを更に細分化したい場合があります。

例えば、ある XXX というエンドポイントを叩いて`invalid`が返ってきた場合には`invalidXXX`, YYY というエンドポイントの場合は`invalidYYY`という具合です。

ライブラリ側に追加すればそれはそれで解決なのですが、アクセスするエンドポイント名ごとに Enum を増やしていてはほとんどの人は使わない無意味な`case`がライブラリに組み込まれてしまいます。

そのような定義はライブラリではなくアプリ側で実装すべきです。

```swift
// コンパイルエラー
extension APIErrorA {
    case invalidXXX
    case invalidYYY
}
```

という風に Extension で追加できれば良いのですが、実は Extension を使って Enum の case を追加することは不可能です。

となれば新たにエラーのクラスを作成するしかありません。

```swift
enum APIErrorB: Error {
    case invalidXXX
    case invalidYYY
}
```

こうすれば実装はできるのですが、利用する上で大変不便です。

何故なら、ライブラリは`APIErrorA`の Enum で返してくるので当然受け取る側の変数も`let error: APIErrorA`のように`APIErrorA`型であることを明示しなければなりませんが、こうなるとアプリが返してくるはずの`APIErrorB`のエラーを受け取れないからです。

エラーを受け取る変数を二つ用意すればいいのですが、それをやると先程の動物の例と同じように冗長なコードになってしまいます。

そこでライブラリ側にはエラーの拡張を許すようにプロトコルを使ってエラーを定義します。

```swift
// ライブラリ
protocol PlatformError: LocalizedError { }

enum APIError: PlatformError {
    case forbidden
    case invalid
}

// ライブラリを利用するアプリ
enum APPError: PlatformError {
    case invalidXXX
    case invalidYYY
}
```

今回はプロトコルに準拠させるだけなので別にプロトコル内には何も書かなくて大丈夫です。

このようにプロトコルに何も特別なことを書かない場合は簡単に利用することができます。

### プロトコルの罠

ところが、`PlatformError`を`LocalizedError`だけでなく`Identifiable`にも準拠させるとコンパイルエラーが発生します。

```swift
protocol PlatformError: LocalizedError, Identifiable {
    var id: String { get }
}

let errors: [PlatformError] = [APIError.forbidden, APPError.change] // Protocol 'PlatformError' can only be used as a generic nostraint because it has Self or associated type requirements
```

コンパイルエラーを読むと「プロトコルが`associated type`の要件を持っているから」とあります。

ここで`Identifiable`プロトコルの[ドキュメント](https://developer.apple.com/documentation/swift/identifiable)を読んでみると、

::: tip Identifiable

associatedtype ID

A type representing the stable identity of the entity associated with an instance.

Required

:::

と書いており`Identifiable`に準拠したことで`assosiated type`が要件に加わり、そのためにコンパイルエラーが発生したことがわかります。

[Swift のジェネリックなプロトコルの変数はなぜ作れないのか、コンパイル後の中間言語を見て考えた](https://qiita.com/omochimetaru/items/b41e7699ea25a324aefa)にもあるように、

::: tip 導入

Swift では通常のプロトコルは変数の型として使用することができますが、

型パラメータ(associated type)を持つジェネリックなプロトコルの変数は作れません。

:::

とあるように、プロトコルを`Identifiable`準拠にした段階でプロトコルを変数の型として利用することができなくなってしまうのです。

また、`Identifiable`でなくても`associatedtype`をプロトコル内に書いた段階で変数の型としては利用できなくなります。

## Enum + CaseIterable

`Identifaible`に準拠させてしまうとめんどくさいことはわかりましたが、`CaseIterable`はどうでしょうか？

調べてみると[ドキュメント](https://developer.apple.com/documentation/swift/caseiterable)には次のようにあります。

```
static var allCases: Self.AllCases
    A collection of all values of this type.
    Required.
associatedtype AllCases
    A type that can represent a collection of all values of this type.
    Required.
```

つまり、CaseIterable に準拠させると`associatedtype`が設定されるので変数としてはプロトコルを指定できないことになります。

よって、アプリとライブラリのエラーを全て一括で配列にする`PlatformError.allCases`は利用できないということになります。

まあでもプロトコルには適応できないというだけであって、それぞれの Enum に対して`CaseIterable`準拠させれば似たようなことはできます。

```swift
// サンプルコード
import SwiftUI

protocol PlatformError: LocalizedError {
    var rawValue: String { get }
}

enum APIError: String, PlatformError, CaseIterable {
    case forbidden
}

enum APPError: String, PlatformError, CaseIterable {
    case change
}

class ErrorTypeList {
    var errors: [PlatformError]

    init(errors: [PlatformError]) {
        self.errors = errors
    }
}

let errorType = ErrorTypeList(errors: (APPError.allCases + APIError.allCases))

for error in errorType.errors {
    print(error.rawValue) // -> chnage, forbidden
}
```

## まとめ

プロトコルにプロトコルを準拠させる時は`associatedtype`がついているか気をつけようね！！！


