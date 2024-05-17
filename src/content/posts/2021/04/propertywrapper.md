---
title: Property Wrapperを便利に使ってみる
published: 2021-04-19
description: Swift5.1で導入されたProperty Wrapperを使うと何が便利なのか調べてみました
category: Programming
tags: [Swift]
---

## Property Wrapper とは

そもそも Property Wrapper がいったいなんなのかよくわかっていなかったので調べてみました。

[こちらの記事](https://qiita.com/favolabo/items/67308dbcf88f3bc1d65f)が参考になったので載せておきます。

これによると「変数をラッピングして get や set を制御するための仕組み」とあります。しかし、Swift では普通に get や set を実行できるので、わざわざ Property Wrapper を使う必要がないような気もします。

一体、これを使うとどのように便利になるのかを調べていきましょう。

### サンプルコード

例えば、以下のような構造体を考えます。

```swift
import SwiftUI

struct HelloWorld {
    private var text: String

    init() {
        text = ""
    }

    var wrappedValue: String {
        get { return text }
        set { text = "Hello, \(newValue)" }
    }
}
```

この構造体は外部から参照できない内部プロパティ`text`を保持しており、その値は最初は空文字です。そして、`text`自体にはアクセスできないものの計算プロパティである`wrappedValue`を介して間接的に`text`の中身を参照できます。

単に参照（get）した場合は`text`の中身は空文字のままなので空文字が返ってきますが、`wrappedValue`に一度でも値を代入した場合は`text`の値が書き換えられます。

```swift
var world = HelloWorld()
world.wrappedValue = "world!"
print(world.wrappedValue) // -> Hello, world!
```

よって、上のコードを実行した場合には`Hello, world!`が出力されるというわけです。

これだけでも別に不満はないのですが、いちいち構造体を宣言してインスタンスをつくったり、値を代入するコードを書いたりというめんどくささがあります。

Property Wrapper はこの煩わしさを解消するための仕組みなのです。

### Property Wrapper を適用する

Property Wrapper は Class、Struct、Enum に対して使えるとのことです。

使い方も簡単で宣言の前に`@propertyWrapper`と書くだけです。

```swift
import SwiftUI

@propertyWrapper
struct HelloWorld {
    private var text: String

    init() {
        text = ""
    }

    var wrappedValue: String {
        get { return text }
        set { text = "Hello, \(newValue)" }
    }
}
```

Property Wrapper は必ず`wrappedValue`というプロパティをもたなければいけません。

また、`wrappedValue`とは別に`projectedValue`というプロパティをもたせることもできます。

Property Wrapper を使えば先程のコードは以下のように書き直せます。こっちのほうがスッキリしていて書きやすいですね。

```swift
@HelloWorld var message: String
message = "world!"
print(message) // -> Hello, world!
```

## AppStorage のようなクラスを作成する

`AppStorage`は UserDefaults を Property Wrapper 拡張したようなもので、簡単に UserDefaults の値を使えるという点では便利でした。

ただ、`AppStorage`は常に文字列型のリテラルを代入しなければならず、値を再利用したいときなどには Typo してしまうなどの問題点がありました。

そこで、これを解決するために UserDefaults + AppStorage のいいとこ取りをしたような UserStorage の Property Wrapper を作成しました。

なお、コーディングに関しては AppStorage を iOS13 に移植するコードである[AppStorage](https://github.com/xavierLowmiller/AppStorage)を大いに参考にさせていただきました。

## 文字列型 Enum 全てを許容する

```swift
// UserStorage.swift
import SwiftUI
import Foundation

@usableFromInline
final class Storage<Value>: NSObject, ObservableObject {
    @Published var value: Value
    private let defaultValue: Value
    private let store: UserDefaults
    private let keyPath: String
    private let transform: (Any?) -> Value?

    init(value: Value, store: UserDefaults, key: String, transform: @escaping (Any?) -> Value?) {
        self.value = value
        self.defaultValue = value
        self.store = store
        self.keyPath = key
        self.transform = transform
        super.init()

        store.addObserver(self, forKeyPath: key, options: [.new], context: nil)
    }

    deinit {
        store.removeObserver(self, forKeyPath: keyPath)
    }

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {

        value = change?[.newKey].flatMap(transform) ?? defaultValue
    }
}

@frozen @propertyWrapper public struct UserStorage<Value>: DynamicProperty {
    @ObservedObject private var value: Storage<Value>
    private let saveValue: (Value) -> Void

    private init(value: Value, store: UserDefaults, key: String, transform: @escaping (Any?) -> Value?, saveValue: @escaping (Value) -> Void) {

        self.value = Storage(value: value, store: store, key: key, transform: transform)
        self.saveValue = saveValue
    }

    public var wrappedValue: Value {
        get { value.value }
        nonmutating set {
            saveValue(newValue)
            value.value = newValue
        }
    }

    public var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
}

extension UserStorage where Value == Bool {
    public init<T: RawRepresentable>(wrappedValue: Value, _ key: T, store: UserDefaults? = nil) where T.RawValue == String {
        let store = (store ?? .standard)
        let initialValue = store.value(forKey: key.rawValue) as? Value ?? wrappedValue
        self.init(value: initialValue, store: store, key: key.rawValue, transform: { $0 as? Value }, saveValue: { newValue in
            store.setValue(newValue, forKey: key.rawValue)
        })
    }
}
```

上半分は難しいのでおいておくとして、大事なのは最後の Extension です。これは UserDefaults に保存する値が Bool の場合のものですが、Int や Double も保存したければこの Extension をまるまるコピペして`Value == XXX`の`XXX`の部分を置き換えれば動作します。

例えば、整数を保存したい場合は次のような Extension を追記してください。

```swift
extension UserStorage where Value == Int {
    public init<T: RawRepresentable>(wrappedValue: Value, _ key: T, store: UserDefaults? = nil) where T.RawValue == String {
        let store = (store ?? .standard)
        let initialValue = store.value(forKey: key.rawValue) as? Value ?? wrappedValue
        self.init(value: initialValue, store: store, key: key.rawValue, transform: { $0 as? Value }, saveValue: { newValue in
            store.setValue(newValue, forKey: key.rawValue)
        })
    }
}
```

ただ、保存先が UserDefaults である以上、UserDefaults に保存できないデータはアプリがクラッシュするので使うことができません。

UserDefaults に保存できるのは、Bool, Int, Double, String, Data, Date, Array, Dictionary に限られます。ただ、本系の AppStorage では Array は保存することができないので、こっちのコードのほうが少し便利かもしれません。

### 使い方

初回起動かどうか、起動回数が何回かを UserDefaults に保存したい場合を考えます。

```swift
public enum UserDefaultsKey: String, CaseIterable {
    case isFirstLaunch
    case launchCount
}
```

その時、上のような Enum を定義します。`CaseIterable`に準拠する必要はありませんが、`String`には準拠する必要があります。そうでないと`rawValue`が使えず、UserDefaults のキー指定ができないためです。

```swift
@UserStorage(UserDefaultsKey.isFirstLaunch) var isFirstLaunch: Bool = false
@UserStorage(UserDefaultsKey.isSecurityLock) var isSecurityLock: Int = 0
```

あとはこのように宣言すれば`AppStorage`と全く同じように使えます。

## 一つの Enum しか使わない場合

さっきのコードは String を継承した Enum であれば何でも指定できましたが、実際にそのような場面は少ないかと思います。

何故なら UserDefaults はキーが文字列しかないため、キーが被るという可能性が非常に高いからです。

```swift
public enum UserKey: String, CaseIterable {
    case contractId
}

public enum CompanyKey: String, CaseIterable {
    case contractId
}
```

例えばこのように UserKey と CompanyKey のようなものを作成し、UserDefaults に保存しようとすると`contractId`の値が重複してしまいデータが上書きされてしまいます。

```swift
public enum UserKey: String, CaseIterable {
    case contractId = "userContractId"
}

public enum CompanyKey: String, CaseIterable {
    case contractId = "companyContractId"
}
```

というように変数名そのままではないリテラルを与えればこの問題は回避できますが、結局これはどことどこで名前衝突が起こっているかがわかっていないとこういう対策はできません。

第一、こういう対策は抜本的ではないです。

こういう名前衝突が起こるのはそもそものプロジェクトの仕様の問題であり、UserDefaults ではなくデータベースや Core Data を使用するように変更すべきでしょう。

なので、複数の Enum がこの UserStorage を使うことはないだろうと考えます。

そうであれば先程のコードは少し短くなります。さっきまではジェネリクスで判定をしていましたがそれが不要になるわけです。

```swift
extension UserStorage where Value == Bool {
    public init(wrappedValue: Value, _ key: UserDefaultsKey, store: UserDefaults? = nil) {
        let store = (store ?? .standard)
        let initialValue = store.value(forKey: key.rawValue) as? Value ?? wrappedValue
        self.init(value: initialValue, store: store, key: key.rawValue, transform: { $0 as? Value }, saveValue: { newValue in
            store.setValue(newValue, forKey: key.rawValue)
        })
    }
}
```
