---
title: クラスのプロパティを取得する
published: 2021-07-26
description: クラスのプロパティをコードで取得して利用するようなプログラムを考えます
category: Programming
tags: [Swift]
---

# クラス/構造体のプロパティ

さて、今回次のような仕様を持つアプリを作りたいとする。

- いくつかの API をコールしてレスポンスを取得する
- 取得したレスポンスを表示する
- コールする API のパラメータを設定できる

これだけだと非常に簡単である。API ごとにパラメータ設定のビューを作成し、そのビューでパラメータを設定したあとで何らかのボタンを押せばリクエストが投げられるようにすれば良い。

ただし、この愚直な方法が有効なのは API の数がたかが知れている場合のみである。もしも API のエンドポイントが 100 や 200 になればそれぞれのエンドポイントのためだけにビューを作成するのは手間がかかるし無駄である。

一つのビューだけで様々な API に対して対応できるようなオブジェクティブ指向のプログラミングがより相応しい。

問題を簡単にするため、今回は二つのエンドポイントに対応するビューを構成することを考えた。

## 二つのエンドポイント

まず、A というエンドポイントで指定された時間内のリザルトの`resultId`を返す。

そして、B というエンドポイントで`resultId`を指定してそのデータの詳細にアクセスするような仕組みである。

```sh
# A
- endpoint # /results
- userId
- startTime
- endTime

# B
- endpoint # /result/{resultId}
- userId
- resultId
```

これらをコード化すると大雑把に以下のようになる。

```swift
class UserResultList: Codable {
    var path: String = "/results"
    let userId: String
    let startTime: Date
    let endTime: Date

    init(userId: String, startTime: Date, endTime: Date) {
        self.userId = userId
        self.startTime = startTime
        self.endTime = endTime
    }
}

class UserResult: Codable {
    let path: String
    let userId: String

    init(userId: String, resultId: Int) {
        self.path = "/result/\(resultId)"
        self.userId = userId
    }
}
```

## クラスのプロパティを取得する

クラスのプロパティを取得するには色々方法があるのだが、一つは`Mirror`を利用するものです。

### Mirror を利用する方法

[【Swift 5.x】クラス/構造体のプロパティ名を取得する](https://inon29.hateblo.jp/entry/2020/05/03/102307)が大変参考になりました。

- インスタンスが必要

```swift
import Foundation

class UserResultList: Codable {
    var path: String = "/results"
    let userId: String
    let startTime: Date
    let endTime: Date

    init(userId: String, startTime: Date, endTime: Date) {
        self.userId = userId
        self.startTime = startTime
        self.endTime = endTime
    }

    // Mirror.Childrenを辞書に変換
    var properties: [String: String] {
        Mirror(reflecting: self).children
            .filter({ $0.label != .none })
            .reduce(into: [:]) {
                $0[$1.label!] = $1.value as? String
            }
            .compactMapValues({ $0 })
    }
}
```

注意点としてはインスタンスがないと`Mirror`は利用できないという点です。つまり`static var`や`class var`は利用できません。

## 再利用性を高める

このままだと`UserResultList`と`UserResult`のどちらにも`properties`を定義しなければいけずめんどくさいのでプロトコルを使ってこれを解消します。

```swift
protocol RequestType: Codable {
}

extension RequestType {
    var properties: [(key: String, value: Any)] {
        return Mirror(reflecting: self).children
            .filter({ $0.label != .none })
            .reduce(into: [:]) {
                $0[$1.label!] = $1.value
            }
            .compactMapValues({ $0 })
            .sorted(by: { $0.0 > $1.0 })
    }
}
```

まず、`RequestType`プロトコルを作成し`UserResult`と`UserResultList`がこのプロトコルに適合するようにします。

```swift
class UserResultList: RequestType {
}

class UserResult: RequestType {
}
```

こうすることでどちらのクラスでも`properties`のプロパティが使えるようになりました。

### プロパティを表示するビュー

ただ定義しただけではどのように動いているかわからないので、中身を表示するように以下のようなプロパティビューワーを作成します。

```swift
struct PropertyView: View {
    @State var request: RequestType
    @State var toggle: Bool = false
    @State var stepper: Int = 0

    var body: some View {
        ForEach(request.properties, id:\.key) { key, value in
            HStack {
                Text(key)
                Spacer()
                Text(value as? String ?? "-")
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

::: warning 型の問題

クラスのプロパティは単に`String`型だけではなく`Int`型や`Date`型や`Bool`型など様々なものが考えられる。

それら全てに本来は対応しなければいけないのだが、今回はとりあえず`String`型のみ考え、`String`型にキャストできないプロパティについては`-`で表示することとした。

:::

これを利用すれば`ContentView`を次のように定義できます。

```swift
struct ContentView: View {
    @State var requests: [RequestType] = [
        UserResultList(userId: "tkgling", startTime: Date(), endTime: Date()),
        UserResult(userId: "tkgling", resultId: 0)
    ]

    var body: some View {
        Form {
            ForEach(requests, id:\.path) { request in
                Section(header: Text(String(describing: type(of: request)))) {
                    PropertyView(request: request)
                }
            }
        }
    }
}
```

::: warning プロトコルの配列を ForEach する

プロトコルの配列はそのままでは ForEach でループさせることができない。何故なら、プロトコルの配列は順序というものが定義できず、一意性が保証されないためだ。基本的には`Identifiable`に適合させる必要があるのだが、`Identifiable`に適合すると`typeAlias`が必要になり今度はプロトコルを適合したインスタンスを配列にできなくなる。

よって`Identifiable`に適合させずに ForEach を利用する方法を考えなければいけない。このときに利用できるのが`id`でこれを使ってユニークなプロパティを指定して一意性を強制的に保証する。今回の場合だと`path`は必ず全ての`RequestType`適合のクラスで異なるはずなのでこれを指定した。

:::

### 値を変更できるようにする

とはいえ、このままでは単にインスタンスに設定されている値を表示しているだけなのでその値を変更できるようにしましょう。

SwiftUI は構造体なので単に変数を指定しても値を更新することができません。よって値を SwiftUI フレームワークで管轄できるように`State`の Property Wrapper を設定する必要があります。

ところがここで気になるのは`PrpertyView`が受け取ったリクエストによってどんなパラメータを設定するかが異なるという点です。つまり、予め「String 型のプロパティが 5 つあるから、5 つの変数を用意しておこう」といったことができません。

更に困ったことに`RequestType`は`userId`と`path`しか定義していないため`request.startTime`のようにアクセスすることができません。

そこで`@DynamicMemberLookup`という機能を使ってみます。

## DynamicMemberLookup

`DynamicMemberLookup`は簡単に言えば`KeyPath`を使ってクラスや構造体が持つプロパティのプロパティにアクセスする方法を指します。

```swift
protocol UserType {
    var id: Int { get set }
    var userName: String { get set }
    var rank: UserRank { get set }
}

class UserRank {
    var rankId: Int = Int.random(0 ... 100)
    var rankName: String = "Intern"

    init() {}
    init(rankId: Int, rankName: String) {
        self.rankId = rankId
        self.rankName = rankName
    }
}

class UserInfo: UserType {
    var rank: UserRank = UserRank()
    var id: Int = 17
    var userName: String = "tkgling"
    var isMembership: Bool = false

    init() {}
    init(id: Int, userName: String, isMemebership: Bool) {
        self.id = id
        self.userName = userName
        self.isMembership = isMemebership
    }
}
```

便利さを実感するために、まずは`UserInfo`クラスに追加で`UserRank`のインスタンスをもたせます。

ここで、それぞれのユーザの`UserRank`のプロパティにアクセスする場合には、例えば次のようにしなければいけません。

```swift
for user in users {
    print(user.rank.rankId) // -> 71, 30
}
```

で、これはネストが深くなれば深くなるほどプロパティの参照が続いてコードとして美しくなくなってしまいます。

### 使い方

やることは簡単で、まずは適用したいクラス、構造体、プロトコルに対して`@dynamicMemberLookup`をつけます。

```swift
@dynamicMemberLookup
protocol UserType {
    var id: Int { get set }
    var userName: String { get set }
    var rank: UserRank { get set }
}

extension UserType {
    subscript<T>(dynamicMember keyPath: KeyPath<UserRank, T>) -> T {
        rank[keyPath: keyPath]
    }
}
```

そして`Extension`で`subscript`を定義します。これがないとコンパイルエラーが発生します。

`subscipt`はいろいろな定義ができるのですが、

```swift
subscript<T>(dynamicMember keyPath: KeyPath<XXXXXXXX, T>) -> T {
    YYYYYYYY[keyPath: keyPath] // XXXXXXXX型のプロパティYYYYYYYYを指定
}
```

の書き方が良いかと思います。

注意点としては`YYYYYYYY`は存在するプロパティでないとだめだということです。

#### 実行してみる

```swift
var users: [UserType] = [UserInfo(), PlayerInfo()]
for user in users {
    print(user.rankId) // user.rank.rankIdにアクセスしているのと同等
}
```

すると今度は`user.rankId`だけで`user.rank.rankId`にアクセスできてしまいました。

ここで大事になるのは`user.rankId`というのはどこにも定義されていないということです。本来であれば Swift は静的解析を行なうのでこのような書き方はコンパイルエラーが発生するのですが、`@DynamicMemberLookup`をつけることでそのようなエラーが発生しないようにしているというわけです。

ちょっぴり黒魔術っぽい感じがしますね。

### 注意点

```swift
@dynamicMemberLookup
protocol UserType {
    var id: Int { get set }
    var userName: String { get set }
    var rank: UserRank { get set }
    var colorType: Color { get set }
}

extension UserType {
    subscript<T>(dynamicMember keyPath: KeyPath<UserRank, T>) -> T {
        rank[keyPath: keyPath]
    }
    subscript<T>(dynamicMember keyPath: KeyPath<Color, T>) -> T {
        colorType[keyPath: keyPath]
    }
}
```

このように複数の`subscript`を定義することもできます。

このとき注意しないといけないのは`UserRank`と`Color`のプロパティ名が被ってしまうと`DynamicMemberLookup`が使えなくなることです。

```swift
class UserRank {
    var rankId: Int = Int.random(in: 0 ... 100)
    var rankName: String = "Intern"
    var description: String = "UserRank Class" // 追加　

    init() {}
    init(rankId: Int, rankName: String) {
        self.rankId = rankId
        self.rankName = rankName
    }
}
```

例えば、`UserRank`クラスに新たなプロパティ`description`を追加します。実はこのプロパティは`Color`クラスにも存在するので、

```swift
var users: [UserType] = [UserInfo(), PlayerInfo()]
for user in users {
    print(user.rankId)
    print(user.description) // Ambiguous use of 'subscript(dynamicMember)'
}
```

というエラーが発生し「どちらの subscript を使えばよいかわからない」という内容が表示されます。

プロパティ名は被らないようにするか、被ったときにはちょっとめんどくさいですが`user.rank.description`のようにどちらかを明示するようにしましょう。

### 計算プロパティ

```swift
@dynamicMemberLookup
protocol UserType {
    var id: Int { get set }
    var rank: UserRank { get set }
}

extension UserType {
    var colorType: Color {
        Color.yellow
    }

    subscript<T>(dynamicMember keyPath: KeyPath<Color, T>) -> T {
        colorType[keyPath: keyPath]
    }
}
```

このように計算プロパティであっても正しく動作します。

### 配列で利用する

配列はオブジェクトではないため直接利用できないのですが、いろいろと奇妙な振る舞いが楽しめます。

```swift
@dynamicMemberLookup
protocol UserType {
    var id: Int { get set }
    var userName: String { get set }
    var colorType: [Color] { get set }
}

extension UserType {
    subscript<T>(dynamicMember keyPath: WritableKeyPath<[Color], T>) -> T {
        return colorType[keyPath: keyPath]
    }
}
```

このような感じで定義して、適当に値を代入してみると、

```swift
var users: [UserType] = [UserInfo(), PlayerInfo()]
for user in users {
    print(user.colorType) // -> [red, blue, gray]
    print(user[0]) // -> red
}
```

なんと`user[0]`にアクセスすると`user.colorType[0]`と同じ扱いになるので`.red`が表示されました！
