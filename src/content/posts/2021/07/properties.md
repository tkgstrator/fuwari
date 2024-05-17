---
title: Swiftでのプロパティの種類について
published: 2021-07-05
description: Swiftで利用可能なプロパティについて学びます
category: Programming
tags: [Swift]
---

# 変数プロパティ

Swift におけるプロパティとは、要するに型を構成する要素の一つ。プロパティなんて一つしかないんじゃないかと思うかもしれないが、実際には Swift には以下の五つのプロパティが存在する。

- Stored
- Computed
- Instance
- Static
- Class

それぞれ何が違い、どのようにして利用するかを考えてみよう。

なお、執筆にあたり[【Swift】プロパティについてのまとめ](https://qiita.com/akeome/items/2197a635ac616ab2f8e2)を大変参考にさせていただきました。

## プロパティの分類

1. 再代入可能かどうか
2. 値を保持するかどうか
3. どこに値を保存するか

## 再代入可能かどうか

再代入可能かどうかでプロパティを`let`として定義するか、`var`として定義するかが変わります。

`let`は定数なので一度代入すると、その値を上書きすることはできません。

### let

```swift
let price: Int = 100
price = 200 // NG
```

### var

`var`は再代入可能ですが、`var`を使っているのに再代入をしていないと「その変数は`let`で十分だよね」とコンパイラに警告されます。

```swift
var price: Int = 100
price = 200 // OK
```

## 値を保持するかどうか

さて、次の分類は値を保持するかどうかです。

値を保持するプロパティを`Stored Property`、保持しないプロパティを`Computed Property`といいます。

### Stored

```swift
let price: Int = 100 // Stored
```

これは単なる`Stored Property`で、この書き方が一番馴染むという方が多いと思います。

```swift
let price: Int {
    willSet {
        // 処理
    }
    didSet {
        // 処理
    }
}
```

`Stored Property`はこのように値が書き換えられる直前と直後に何らかの処理を実行することができます。

### Computed

一方、`Computed Property`では値がどこかに保持されているわけではなく別のプロパティから値を計算して返すような場合に使います。

例えば、ある商品とその商品の税込みの値段を計算した場合を考えましょう。

```swift
class Item {
    var price: Int
    var taxIncludedPrice: Int

    init(price: Int) {
        self.price = price
        self.taxIncludedPrice = Int(Double(price) * 1.1)
    }
}

let apple = Item(price: 200)
print(apple.taxIncludedPrice) // -> 220
```

これを`Stored Property`だけを使って実装すると上のようになります。

```swift
class Item {
    var price: Int
    var taxIncludedPrice: Int {
        get {
            Int(Double(self.price) * 1.1)
        }
    }

    init(price: Int) {
        self.price = price
    }
}

let apple = Item(price: 200)
print(apple.taxIncludedPrice) // -> 220
```

これを`Computed Property`を利用すると上のように書けます。要するに、税込価格は常に税抜価格の 1.1 倍なので税抜価格のデータにアクセスするたびに値段を計算して返すという仕様になっているわけです。

値を参照するごとに実際の値を計算するので計算プロパティ(`Computed Property`)と呼ばれているわけです。注意点としては、計算に時間がかかるようなデータを計算プロパティに入れてしまうと、アクセスするたびに計算をしてしまうのでアプリが重くなる原因になります。

`Stored Property`であれば一度値を計算すればその値をメモリに保存しておくので二回目以降は光速にアクセスできます。

`Stored Property`では`willSet`と`didSet`を使うことができましたが、`Computed Property`では`get`と`set`が利用できます。

- get
  その値を読み込んだときに、返すデータを計算する処理を記述する
- set
  その値にデータを代入したときに行う処理を記述する

さきほどのコードには`get`しか書かれていないため、`taxIncludedPrice`に値を代入することはできません。これは`let`と似たような挙動をすることを意味します。

```swift
let apple = Item(price: 200)
print(apple.taxIncludedPrice) // -> 220
apple.taxIncludedPrice = 400 // Cannot assign to property: 'taxIncludedPrice' is get-only peoperty
```

これでも別に不満はないのですが、税込価格を入力すれば自動で税抜価格を計算し直してくれるようにしましょう。

```swift
class Item {
    var price: Int
    var taxIncludedPrice: Int {
        get {
            Int(Double(self.price) * 1.1)
        }
        set {
            self.price = Int(Double(newValue) / 1.1)
        }
    }

    init(price: Int) {
        self.price = price
    }
}

let apple = Item(price: 200)
print(apple.price, apple.taxIncludedPrice) // -> 200, 220
apple.taxIncludedPrice = 330
print(apple.price, apple.taxIncludedPrice) // -> 300, 330
```

すると、`taxIncludedPrice`に代入した時点で`price`の値が更新されました。

::: warning Computed Property について

他の言語の Computed Property と異なり、Swift では自分自身の値をどこかに保存しておくことはできません。

なので、Computed Property の`setter`は別の変数に値を保存するためにあります。

:::

## どこに値を保存するか

### Instance

`Instance Property`はそのインスタンスが保持しているプロパティです。

```swift
class Item {
    var price: Int = 100
}

let apple = Item()
print(apple.price) // -> 100
```

なのでクラスや構造体を一度実体化(インスタンスを作成)しなければ利用することができません。

### Static

`Static Property`は型自身に保存されるプロパティです。

```swift
class Item {
    static var madeIn: String = "Japan"
}

print(Item.madeIn)
```

`Static Property`にすればインスタンス化せずに利用することができます。

### Class

`Class Property`は`Static Property`と同じく、インスタンス化せずに利用できるプロパティです。

どちらも利用方法はほとんど同じなのですが、`Class Property`は軽傷クラスからオーバーライド(定義の上書き)が可能です。

また、`Class Property`は必ず`Computed Property`で宣言しなければいけません。

```swift
class Item {
    class var madeIn: String {
        "Japan"
    }
}

class Apple: Item {
    override class var madeIn: String {
        "Yamanashi"
    }
}

print(Apple.madeIn)
```

## それぞれのプロパティの使い方

利用可能な組み合わせは以下の通り。

要するに`Class Property, Stored Property`の組み合わせだけが利用できないだけで、後は全て使えます。

|          | Instance | Static | Class |
| :------: | :------: | :----: | :---: |
|  Stored  |    OK    |   OK   |   -   |
| Computed |    OK    |   OK   |  OK   |

```swift
class Item {
    var priceA: Int = 100               // Stored + Instance
    var priceB: Int {                   // Computed + Inscance
        get {
            Int(priceA / 2)
        }
        set {
            priceA = Int(newValue * 2)
        }
    }
    static var priceC: Int = 150        // Stored + Static
    static var priceD: Int {            // Computed + Static
        get {
            Int(priceC / 2)
        }
        set {
            priceC = Int(newValue * 2)
        }
    }
    class var priceE: Int {             // Computed + Class
        get {
            Int(priceD / 2)
        }
        set {
            priceD = Int(newValue * 2)
        }
    }
}

class Apple: Item {
    override class var priceE: Int {    // Computed + Class
        get {
            Int(priceD / 3)
        }
        set {
            priceD = Int(newValue * 3)
        }
    }
}

let apple = Apple()
print(apple.priceA, apple.priceB)               // -> 100, 50
print(Apple.priceC, Apple.priceD, Apple.priceE) // -> 150, 75, 25
```

ここでは`Item`では`priceE`の値は`priceD`の 1/2 と定義されているのですが、`Apple`では 1/3 というように再定義しているので、
`150/2/3=25`という値が返ってきています。

## Stored/Computed

さて、ここでよくあるコーディングミスというか、もっと便利に書けるのに的なコードを紹介します。

```swift
class Item {
    var priceA: Int

    init() {
        priceA =
    }
}
```
