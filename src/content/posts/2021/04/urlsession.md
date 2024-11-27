---
title: URLRequestを理解する
published: 2021-04-08
description: Alamofireのソースコードから理解を深めよう
category: Programming
tags: [Swift]
---

## URLRequest はいいぞ

URLRequest は Swift で HTTP 通信をするための標準ライブラリである。が、実際にアプリを組むとなると簡単で高機能な Alamofire を使ってしまいがちであった。

ただ、作りたい自作ライブラリが HTTP 通信を必要とし、そのライブラリを使いたいアプリも HTTP 通信が必要になるとライブラリにもアプリにも Alamofire を導入せねばならず、なんとなく気持ち悪い印象を受ける。

複雑怪奇なライブラリならさておき、SplatNet2 程度のライブラリなら GET と POST がリクエストできれば良いので Alamofire のような高機能ライブラリも、それを受け取るための SwiftyJSON も不要なはずなのだ。

よって、今回は原点回帰をして外部ライブラリなしに API を叩いて通信するためのコードを書いていく。

## Swift のクラスの理解を深める

Swift でライブラリをつくる際は`public class`にしなければ呼び出せないことが知られている。

例えば`OAuth`クラスをライブラリ化したいのであれば以下のように書かなければいけない。

```swift
// OK
public class OAuth {
}

// OK
open class OAuth {
}

// NG
class OAuth {
}
```

なお、`public`に代えて上のように`open`を指定することもできる。`public`ではできない別モジュールからの継承が`open`では可能になるようだが、具体的な使いみちはいまのところ思いつかない。

### クラス変数とクラス関数

クラス直下に書いた変数はクラス変数として扱われる。

```swift
public class OAuth {

    let version: String = "1.10.0"

    // OK
    public func getVersion1() {
        print(version)
    }

    // NG
    public class func getVersion2() {
        print(version)
    }
}
```

この場合バージョン情報として定義した`version`がクラス変数になり、そのバージョンを取得する`getVersion()`という関数を考えよう。

このとき関数は`public func`か`public class func`のように定義できるのだが、この違いをわかっておかないとのちのちめんどくさいことになる。

```swift
// public func
let oauth: OAuth = OAuth()
oauth.getVersion1()
```

`public func`の場合はクラス関数なのでクラスを実体化させてからでないと使うことができない。

```swift
// public class func
OAuth.getVersion2()
```

それに対して`public class func`は OAuth クラスのクラス関数なので使いたいクラス自体を明示すれば使うことができる。

ここで重要になるのは`version`がただのクラス変数であり、クラスがインスタンス化されるまで取得できないということだ。よって、`getVersion2`ではまだ実体化していない version を取得することができない。このプログラムはコンパイルエラーを返すのである。

これを防ぐためには`version`の値をクラスが常に保存しておくようにする。プログラミング言語等によってはクラス変数化する`class let version = "1.10.0"`のような書き方ができるが、Swift ではできない。その代わり`static`が用意されているのでそちらを利用する。

```swift
public class OAuth {

    static let version: String = "1.10.0"

    // NG
    public func getVersion1() {
        print(version)
    }

    // OK
    public class func getVersion2() {
        print(version)
    }
}
```

ただし、こうすると今度は`getVersion1()`が正しく値をとってこれなくなる。値をとってこれるようにするためには、

```swift
public func getVersion1() {
    print(OAuth.version)
}
```

のように OAuth クラスの変数を呼び出すようにコードを変えなければいけない。

## HTTPHeaders と HTTPHeader を定義しよう

HTTPHeaders と HTTPHeader はどちらも Alamofire で使われる構造体である。非常に便利なので同じテクニックを使わせてもらうことにした。

HTTPHeaders のソースコードは[ここ](https://github.com/Alamofire/Alamofire/blob/097e1f03166d49b31f824507fb85ad843b14fc13/Source/HTTPHeaders.swift)にあるが、今回はすべてを利用するわけではないので便利そうなところだけ参考にさせていただいた。

```swift
// HTTPHeader.swift
public struct HTTPHeader: Hashable {
    public let name: String
    public let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

extension Array where Element == HTTPHeader {
    func index(of name: String) -> Int? {
        let name = name.lowercased()
        return firstIndex { $0.name.lowercased() == name }
    }
}
```

HTTPHeader は単一のヘッダー情報を持つ構造体で、それをまとめたものが HTTPHeaders である。

```swift
public struct HTTPHeaders {
    // HTTPHeaderの配列
    private var headers: [HTTPHeader] = []
    public init() {}

    // 重複してないか調べて追加する関数
    public mutating func update(name: String, value: String) {
        update(HTTPHeader(name: name, value: value))
    }

    public mutating func update(_ header: HTTPHeader) {
        // 重複していなければ追加
        guard let index = headers.index(of: header.name) else {
            headers.append(header)
            return
        }
        // 重複していれば値を更新
        headers.replaceSubrange(index...index, with: [header])
    }
}

extension HTTPHeaders: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, String)...) {
        self.init()
        elements.forEach{ update(name: $0.0, value: $0.1) }
    }
}
```

そしてここで重要なのがこの`ExpressibleByDictionaryLiteral`で、これを利用することでなんと辞書型から直接 HTTPHeaders のインスタンスをつくることができるようになる。

つまり、下のように辞書をそのまま指定するだけで簡単に HTTPHeader 型に変換できるのだ、すごい。

```swift
let header: HTTPHeaders = [
    "User-Agent": "USER_AGENT"
]
```

### HTTPMethod を定義しよう

```swift
public struct HTTPMethod: RawRepresentable, Equatable, Hashable {
    public static let delete    = HTTPMethod(rawValue: "DELETE")
    public static let get       = HTTPMethod(rawValue: "GET")
    public static let post      = HTTPMethod(rawValue: "POST")
    public static let put       = HTTPMethod(rawValue: "PUT")

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
```

Alamofire ではたくさんのメソッドが対応しているが、この四つがあれば基本的には何でもできるだろうということでこの四つにのみ対応した。

## GET しよう

## POST しよう

POST ではデータを送信する必要があり、多くの API は`application/json`を受け取るようになっているが、たまに頭のおかしい API は`application/x-www-form-urlencoded`のような`Content-Type`を要求してくる。`application/form-data`のような更におかしなものも存在するが、ここではこの二つだけに絞ろう。

Alamofire であればこれの対応は簡単で`parameters`のエンコーディングで`JSONEncoding.default`を指定すれば`JSON`形式でパラメータを変換でき、`URLEncoding.default`を指定すれば`x-www-form-urlencoded`に対応できる。

### JSON を POST しよう

```swift

```
