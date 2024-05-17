---
title: ジェネリクス全然わからん
published: 2021-04-10
description: ジェネリクスの使い方を学ぶ
category: Programming
tags: [Swift]
---

## ジェネリクスを学ぼう

Salmonia3 を開発していてよく使うのがオプショナルの数値を文字列に変換する処理である。

要するに、データがないならばないことを意味する`-`を返し、そうでないならその値をそのまま文字列にして返してほしいのである。ただし、Double 型の場合は小数点が延々と続いては困るので小数第二位で区切ることとする。

これを extension を使うと以下のようにかける。

```swift
extension Optional where Wrapped == Int {
    var stringValue: String {
        guard let value = self else { return "-" }
        return String(self as! Int)
    }
}

extension Optional where Wrapped == Double {
    var stringValue: String {
        guard let value = self else { return "-" }
        return String(Double(Int(self as! Double * 100)) / 100)
    }
}
```

本当は「数値であれば～」という処理にしたかったので、

```swift
extension Optional where Wrapped == Numeric {
    var stringValue: String {
        guard let value = self else { return "-" }
        switch self {
        case is Int:
            return String(self as! Int)
        case is Double:
            return String(Double(Int(self as! Double * 100)) / 100)
        default:
            return "-"
        }
    }
}
```

こういうふうにかければいいのだが、書けなかった。なんでなのん。

## ジェネリクスを書いてみる

ここまでできたら、次は SwiftUI で文字列型とオプショナル型を受け付ける関数を書いてみる。

作りたいのはこういうのである。要するにオプショナル型で値を受け取って文字列に直して「パラメータ名 -> 値」というビューである。

```swift
struct ContentView: View {

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}
```

じゃあ当然これのイニシャライザが必要になる。やりたいことは以下のようなコードである。だが、これはうまくいかない。なぜなら value は`Optional<Any>`であり`Optional<Int>`や`Optional<Double>`ではないからだ。

```swift
var title: String
var value: String

init(title: String, value: Optional<Any>) {
    self.title = title
    self.value = value.stringValue
}
```

ではどうすればいいかを考えてみよう。

### Optional\<Int\>

こう書けば`Int?`に対しては正しく処理ができる。

```swift
init(title: String, value: Optional<Int>) {
    self.title = title
    self.value = value.stringValue
}
```

また、これはジェネリクスを使って以下のようにも書ける。

```swift
init<T: Optional<Any>>(title: String, value: T) where Wrapped == Int {
    self.title = title
    self.value = value.stringValue
}
```

ジェネリクスは`Optional<Any>`を許可しているが、その次の`Wrapped == Int`によってアンラップしたら Int 型でなければいけないという制約をつけているのである。

この二つによって、実質的に引数は`Int?`しか許容されなくなる。

### 何故か書けない書き方

いけそうなのに何故か書けないジェネリクスたちを供養として載せておきます。

```swift
init<T: Int>(title: String, value: Optional<T>) {
    self.title = title
    self.value = value.stringValue
}

init<T: Optional>(title: String, value: T<Int>) {
    self.title = title
    self.value = value.stringValue
}

init<T: Optional<Int>>(title: String, value: T) {
    self.title = title
    self.value = value.stringValue
}
```

Int が書ければ Double は同じように書ける。が、必要なのはそこではない。Double も Int もとってこれるようにしたいのである。

## こういうのも書けない

```swift
init<T: Optional<Any>>(title: String, value: T) where Wrapped == Int, Double {
    self.title = title
    self.value = value.stringValue
}
```

なのでこれらを組み合わせた以下のようなコードを書く。

これしかないのかなあという気持ち。結局ジェネリクス使ってないし何だこれ。

```swift
init(title: String, value: Optional<Any>)
{
    self.title = title
    self.value = value.stringValue
}

extension Optional {
    var stringValue: String {
        switch self {
        case is Int:
            guard let value = self else { return "-" }
            return String(self as! Int)
        case is Double:
            guard let value = self else { return "-" }
            return String(Double(Int(self as! Double * 100)) / 100)
        default:
            return "-"
        }
    }
}
```
