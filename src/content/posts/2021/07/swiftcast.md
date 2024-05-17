---
title: Swiftでの型のキャストを理解せよ
published: 2021-07-28
description: キャスト
category: Programming
tags: [Swift]
---

# キャストとは

キャストとは型を変換すること。相互変換できる型だったり、できない型だったりがある。

キャストの方法はいろいろあるのですが、自分の理解が不十分だったため今回 Playground を使って理解を深めていこうと思います。

## イニシャライザ

いくつかの型はイニシャライザを使ってキャストができます。

### Int to String

```swift
let intValue: Int = 10 // Int
let stringValue: String = String(intValue) // Int to String

print(stringValue, type(of: stringValue)) // -> 10 String
```

この方法のキャストは必ず`String`が返ってくるのでそのまま`String`で受けることができます。

### String to Int

一方、`String`から`Int`へのキャストは必ず成功するとは限りません。

当たり前ですが、整数型に変換できない文字列が存在するためです。よって、以下のコードは書けません。

```swift
let stringValue: String = "10" // String
let intValue: Int = Int(stringValue) // Value of optional type 'Int?' must be unwrapped to a value of type 'Int'
```

ここで大事なのは仮に変換可能な文字列が`stringValue`に代入されていたとしてもコンパイラはこのエラーを出力するということです。つまり、実行時エラーではなくてコンパイルエラーとなるわけです。

`Int()`を使った`String`からのキャストは`Optional<Int>`が返り、変換不可能な場合は`nil`が入っています。

#### Optional をそのまま利用する場合

```swift
let stringValue: String = "10" // String
let intValue: Int? = Int(stringValue) // String to Int

print(intValue, type(of: intValue)) // -> Optional(10) Optional<Int>
```

#### 強制アンラップする場合

```swift
let stringValue: String = "10" // String
let intValue: Int = Int(stringValue)! // String to Int

print(intValue, type(of: intValue)) // ->10 Int
```

この方法は`stringValue`にキャストできない文字列が含まれていると実行時にクラッシュします。

#### デフォルト値を利用する場合

```swift
let stringValue: String = "10" // String
let intValue: Int = Int(stringValue) ?? 0 // String to Int

print(intValue, type(of: intValue)) // ->10 Int
```

`??`を使い、後ろにデフォルト値を設定すれば`nil`が返ってきた場合にその値が利用されます。

クラッシュはしないのですが、逆に言えばクラッシュしないのでどこでエラーが発生しているのかがわかりにくくなります。

#### エラーを返す場合

```swift
let stringValue: String = "10" // Int
guard let intValue: Int = Int(stringValue) else { throw fatalError() }

print(intValue, type(of: intValue)) // -> 10 Int
```

`guard let else {}`を利用すれば安全にオプショナルを外し、エラーを返すことができます。

#### 任意の処理を行う場合

```swift
let stringValue: String = "10" // Int
if let intValue: Int = Int(stringValue) {
    // nilでないとき
    print(intValue, type(of: intValue)) // -> 10 Int
} else {
    // nilのとき
    print("Input value does not cast as Int")
}
```

分岐をしたいときに`if intValue == nil`のように書くこともできますが、こちらの方がスマートで良いと思います。

個人的にですが、`nil`というのを単純に比較演算子で比較したくないですね。`isNil`みたいなメソッドがほしいですね。

### Any to String

文字列型は基本的にどんな型がきてもキャストすることができます。

```swift
let intValue: Int = 10
let optionalIntValue: Int? = 10

print(String(intValue))
print(String(optionalIntValue)) // Value of optional type 'Int?' must be unwrapped to a value of type 'Int'
```

ただし`String()`ではオプショナルや構造体、クラスなどはキャストできません。

```swift
let optionalIntValue: Int? = 10

print(String(describing: optionalIntValue)) // -> Optional(10)
```

そこで`String(describing: )`を使います。これは基本的に何でもキャストできます。

```swift
struct UserInfo {
    var userId: Int = 0
    var userName: String = "tkgling"
}

print(String(describing: UserInfo())) // -> UserInfo(userId: 0, userName: "tkgling")
```

このように構造体も文字列型にキャストできます。

## キャスト演算子

Swift には`as`、`as?`、`as!`の三つのキャスト演算子があります。

これの使い方がよくわかっていなかったので今回は学習しました。

また、キャストにはダウンキャストとアップキャストの二つがあります。その違いについてもまずは理解しましょう。

### ダウンキャスト

### アップキャスト

### as

キャストして失敗したらエラーが発生します。

```swift
let intValue: Int = 10
let stringValue: String = intValue as String

print(stringValue) // Cannot convert value of type 'Int' to type 'String' in coercion
```

### as?

キャストして失敗したら`nil`が返ります。

### as!

キャストして失敗したらエラーが発生し、そのままクラッシュします。


