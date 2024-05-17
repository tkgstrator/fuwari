---
title: JSON + Codableで面倒なJSONを一発変換
published: 2021-04-08
description: JSONで受け取ったデータをCodableで変換するためのチュートリアル
category: Programming
tags: [Swift]
---

## 変数名とキーが一致している場合

```json
{
  "id": 100,
  "name": "tkgling",
  "email": "tkgling@sample.com"
}
```

こういう値を返す JSON を考える。例えばユーザ名を指定してそのユーザの情報を返すような API が想定されるだろう。

「変数名とキーが一致している」としたのは JSON 側ではスネークケースであることが多いのに対して、Swift ではキャメルケースでの命名規則が推奨されているためだ。つまり JSON 側では`user_name`というキーがあれば、その値は Swift 側では`userName`として取得したいのである。

が、今回の API ではたまたまアンダーバーがなくそのような変換が不要だと想定する。

```swift
struct UserInfo: Decodable {
    let id: Int
    let name: String
    let email: String
}

do {
    let decoder = JSONDecoder()
    // SwiftyJSONを利用した場合
    let user: UserInfo = try decoder.decode(UserInfo.self, from: json.rawData())
    // Dictionary<String, Any>の場合
    let user: UserInfo = try decoder.decode(UserInfo.self, from: json.rawData())

} catch {
    // エラー処理
}
```

## 変数名とキーが一致していない場合

変数名とキーが一致していない場合、いくつかの対応がある。

- 手動で変数とキーの対応表である CodingKey を書く
  - 最もめんどくさく、最も推奨しない
  - キーが多く、ネストが深い JSON だと対応表だけで数百行になる
- キーと変数名に一定の規則がある場合
  - `JSONDecoder()`の自動変換機能が使える
  - キーの命名規則がスネークケースでないとめんどくさいのが難点
- 変数名をキーから決める
  - 確実に一意にはなるが、自分が使いたい変数名にならない場合がある

### 自分で対応表を書く場合

例えば以下のような JSON を扱うことを考えます。

```json
{
  "user_id": 100,
  "user_name": "tkgling",
  "user_email": "tkgling@sample.com"
}
```

これは先程の考えを推し進めれば次のように構造体をつくれば Decodable で一発で変換できる。

```swift
struct UserInfo: Decodable {
    let user_id: Int
    let user_name: String
    let user_email: String
}
```

しかし、Swift はキャメルケースが命名規則なので、この変数名は正直センスがない。別の言い方をすればイカしていないのである。

Swift の命名規則に従えばこれらの変数は以下のように定義されるべきである。スネークケースからキャメルケースの変換は簡単で、アンダーバーを削除してアンダーバーの最初のアルファベットを大文字にするだけである。

```swift
struct UserInfo: Decodable {
    let userId: Int
    let userName: String
    let userEmail: String
}
```

ただ、これではそのままデコードできないのでそこを繋げるための対応表を書く。

```swift
private let UserInfoKeys: String, CodingKey {
    case userId     = "user_id"
    case userName   = "user_name"
    case userEmail  = "user_email"
}
```

Enum の名前は今回は変数名と揃えたが、区別がつくなら別に何でも良い。ただし、rawValue だけはキーと一致させる必要がある。

最後に構造体のイニシャライザを書いたらそれらをくっつけるだけである。

```swift
struct UserInfo: Decodable {
   let userId: Int
   let userName: String
   let userEmail: String

   private let UserInfoKeys: String, CodingKey {
   case userId     = "user_id"
   case userName   = "user_name"
   case userEmail  = "user_email"
   }

   init(from decoder: Decoder) throws {
       let container = try decoder.container(keyedBy: UserInfoKeys.self)
       // 処理を書く
   }
}
```

これは Playground で簡単に再現できるのでやってみましょう。

```swift
import Foundation

// JSONファイルを定義
let json = """
{
    "user_id": 0,
    "user_name": "tkgling",
    "user_email": "tkgling@gmail.com"
}
"""

let decoder = JSONDecoder()
let data = try decoder.decode(UserInfo.self, from: Data(json.utf8))
print(data)

// UserInfoの定義
struct UserInfo: Decodable {
    let userId: Int
    let userName: String
    let userEmail: String

    // プロパティとキーの対応
    private enum UserInfoKeys: String, CodingKey {
        case userId = "user_id"
        case userName = "user_name"
        case userEmail = "user_email"
    }

    // イニシャライザ
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: UserInfoKeys.self)

        userId = try container.decode(Int.self, forKey: .userId)
        userName = try container.decode(String.self, forKey: .userName)
        userEmail = try container.decode(String.self, forKey: .userEmail)
    }
}
```

このコードで正しく、次のような結果を得ることができます。

```swift
// 実行結果
UserInfo(userId: 0, userName: "tkgling", userEmail: "tkgling@gmail.com")
```

が、やってみればわかるのですが途方もなくめんどくさいです。プロパティが 10 くらいならやる気もおきますが、それを超えるとめんどうなだけです。

### スネークケースからキャメルケースへの変換

単にスネークケースからキャメルケースに変換するだけであれば JSONDecoder の`convertFromSnakeCase`のプロパティが使えます。

```swift
import Foundation

let json = """
{
    "user_id": 0,
    "user_name": "tkgling",
    "user_email": "tkgling@gmail.com"
}
"""

let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
}()
let data = try decoder.decode(UserInfo.self, from: Data(json.utf8))
print(data)

struct UserInfo: Decodable {
    let userId: Int
    let userName: String
    let userEmail: String
}
```

これは JSONDecoder のプロパティに予め`.convertFromSnakeCase`を適用させた状態で使っているため、JSON を読み込んだ段階でキーが全てキャメルケースに変換されています。

よって、対応表を書かなくとも一発でデータを取得することができます。

### JSON のキーをプロパティ名にする

こちらは Swift での命名規則よりも JSON 側の命名規則を優先する場合、または JSON 側がキャメルケースになっている場合などに使えます。

```swift
import Foundation

let json = """
{
    "user_id": 0,
    "user_name": "tkgling",
    "user_email": "tkgling@gmail.com"
}
"""

let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .useDefaultKeys
    return decoder
}()
let data = try decoder.decode(UserInfo.self, from: Data(json.utf8))
print(data)

struct UserInfo: Decodable {
    let user_id: Int
    let user_name: String
    let user_email: String
}
```

## 自動で型変換しよう

JSON が持っている型と、Swift で扱いたい型が違う場合があります。その際には`DateEncodingStrategy`と`DateDecodingStrategy`を使えば簡単に相互変換ができます。

```json
{
  "user_id": 100,
  "user_name": "tkgling",
  "user_email": "tkgling@sample.com",
  "created_at": 1617267600
}
```

アカウントが作成された時間が UnixTimestamp で保存されているのですが、これを Date 型に変換したい場合などが考えられます。

```swift
let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .secondsSince1970
    return decoder
}()
```

このときはこのように JSONDecoder を拡張してやれば Date 型に自動で変換してくれます。

```swift
// 実行結果
UserInfo(userId: 0, userName: "tkgling", userEmail: "tkgling@gmail.com", createdAt: 2021-04-01 09:00:00 +0000)
```

このデコード方式はいまのところ以下のものが対応している様子でした。

- ISO8601 形式(.iso8601)
  - 万能かつ最強
  - これを使っていればとりあえず怒られることはない
  - 昔は使えなかったっぽいのだが、いつの間にか対応していた
- 標準フォーマット(.secondsSince1970)
  - `yyyy-mm-dd HH:mm:ss`形式のやつ
- 標準フォーマット(.millisecondsSince1970)
  - 上のやつのミリ秒まで使えるパターン

ただ、Realm などは Date 型にプライマリキーをつけられないなどの制約があるので、データベースに保存するつもりならわざわざ Date 型に変換する意味はないような気もします。

## いろいろな構造の JSON に対する対応

### 配列

ではちょっと複雑化したネスト付きの JSON を考えよう。

```json
{
  "user_id": 100,
  "user_name": "tkgling",
  "user_email": "tkgling@sample.com",
  "created_at": 1617267600,
  "accounts": ["tkgling", "tkgstrator"]
}
```

このように配列が入っている場合も、構造体のプロパティとして配列を与えてやれば JSONDecoder は自動で変換してくれます。

```swift
struct UserInfo: Decodable {
    let userId: Int
    let userName: String
    let userEmail: String
    let createdAt: Date
    let accounts: [String]
}
```

```swift
// 実行結果
UserInfo(userId: 100, userName: "tkgling", userEmail: "tkgling@sample.com", createdAt: 2021-04-01 09:00:00 +0000, accounts: ["tkgling", "tkgstrator"])
```

ちなみに今回は String 型で単純に受け取っていますが、以下のように好きな構造体を割り当てることもできます。

### オブジェクト配列

オブジェクトを配列として持っている場合を考える。

このときは先程とは違い、何番目のアカウントの id や created_at に直接アクセスできるような仕組みになっているとありがたいわけである。

```json
{
  "user_id": 100,
  "user_name": "tkgling",
  "user_email": "tkgling@sample.com",
  "created_at": 1617267600,
  "accounts": [
    {
      "id": "tkgling",
      "created_at": 1617267600
    },
    {
      "id": "tkgstrator",
      "created_at": 1617267600
    }
  ]
}
```

この場合はオブジェクトが配列になっているだけなのだから、次のように構造体を定義すれば良い。

```swift
struct UserInfo: Decodable {
    let userId: Int
    let userName: String
    let userEmail: String
    let createdAt: Date
    let accounts: [Account]

    struct Account: Decodable {
        let id: String
        let createdAt: Date
    }
}
```

```swift
UserInfo(userId: 100, userName: "tkgling", userEmail: "tkgling@sample.com", createdAt: 2021-04-01 09:00:00 +0000, accounts: [Page_Contents.UserInfo.Account(id: "tkgling", createdAt: 2021-04-01 09:00:00 +0000), Page_Contents.UserInfo.Account(id: "tkgstrator", createdAt: 2021-04-01 09:00:00 +0000)])
```

### オブジェクト

```json
{
  "user_id": 100,
  "user_name": "tkgling",
  "user_email": "tkgling@sample.com",
  "created_at": 1617267600,
  "accounts": {
    "id": "tkgling",
    "created_at": 1617267600
  }
}
```

ここで少し問題になるのは、ユーザがアカウントを作成していれば確実に情報は入っていますが、アカウントを作成していない場合には`accounts`の中身が想定しているものと変わるケースがあるということです。

```json
// パターン1
// accountsそのものをレスポンスに含まない
{
    "user_id": 100,
    "user_name": "tkgling",
    "user_email": "tkgling@sample.com",
    "created_at": 1617267600,
}

// パターン2
// レスポンスに含むが、ないことを示す
{
    "user_id": 100,
    "user_name": "tkgling",
    "user_email": "tkgling@sample.com",
    "created_at": 1617267600,
    "accounts": null
}

// パターン3
// レスポンスに含めるが、それぞれのパラメータがないことを示す
{
    "user_id": 100,
    "user_name": "tkgling",
    "user_email": "tkgling@sample.com",
    "created_at": 1617267600,
    "accounts": {
        "id": null,
        "created_at": null
    }
}
```

それぞれについて対応策を考えていきますが、結局はどこのパラメータとして`nil`を許容するかという問題になります。

```swift
// パターン1, 2の場合
struct UserInfo: Decodable {
    let userId: Int
    let userName: String
    let userEmail: String
    let createdAt: Date
    let accounts: Account? // オプショナル

    struct Account: Decodable {
        let id: String
        let createdAt: Date
    }
}

// 実行結果
UserInfo(userId: 100, userName: "tkgling", userEmail: "tkgling@sample.com", createdAt: 2021-04-01 09:00:00 +0000, accounts: nil)
```

パターン 2 の場合は`accounts`に`nil`が入る可能性があるため、該当部分をオプショナルに変更します。

ちなみに Swift は変数をもったりもたなかったりというようなことが（多分）できないのでパターン 1 の JSON は強制的にパターン 2 と同じデータに変換されます。

```swift
// パターン3の場合
struct UserInfo: Decodable {
    let userId: Int
    let userName: String
    let userEmail: String
    let createdAt: Date
    let accounts: Account

    struct Account: Decodable {
        let id: String?
        let createdAt: Date?
    }
}

// 実行結果
UserInfo(userId: 100, userName: "tkgling", userEmail: "tkgling@sample.com", createdAt: 2021-04-01 09:00:00 +0000, accounts: Optional(Page_Contents.UserInfo.Account(id: nil, createdAt: nil)))
```

パターン 3 の場合は`accounts`自体はかならずあるが、中身のデータが有るかどうかがわからないのでこうなります。

### オブジェクト

気が狂いそうになるのがこのパターン。Swift は変数名の先頭を数字にできないため、以下のような構造をしていると単純にデータをとってくることができなくなる。

```json
{
  "user_id": 100,
  "user_name": "tkgling",
  "user_email": "tkgling@sample.com",
  "created_at": 1617267600,
  "accounts": {
    "1": "tkgling",
    "2": "tkgstrator"
  }
}
```

このようなケースでは accounts のキーが必要な場合と不要な場合が存在する。今回のケースではキーは順序を保証するためだけの情報なので（Swift の配列は順序が保証されるので）あってもなくてもいいことになる。

ちなみにただデータを取得したいだけであればこう書ける。

```swift
struct UserInfo: Decodable {
    let userId: Int
    let userName: String
    let userEmail: String
    let createdAt: Date
    let accounts: [Int: String]
}
```

```swift
// 実行結果
UserInfo(userId: 100, userName: "tkgling", userEmail: "tkgling@sample.com", createdAt: 2021-04-01 09:00:00 +0000, accounts: [2: "tkgstrator", 1: "tkgling"])
```

### オブジェクトのオブジェクト

```json
{
  "user_id": 100,
  "user_name": "tkgling",
  "user_email": "tkgling@sample.com",
  "created_at": 1617267600,
  "accounts": {
    "1": {
      "id": "tkgling",
      "created_at": 1617267600
    },
    "2": {
      "id": "tkgstrator",
      "created_at": 1617267600
    }
  }
}
```

さっきのを更に拡張するとこうなります。JSON では順序がないため順序を保持するために辞書に ID を割り振っているケースがあります。

これはやはり辞書のキーが数字のため単純に置き換えることができません。

これ、未だに自動で Decodable な struct に変換するための書き方がわからないです。

### ルートがオブジェクト

最後にこういうパターンの対応作。

```json
[
  {
    "id": "tkgling",
    "created_at": 1617267600
  },
  {
    "id": "tkgstrator",
    "created_at": 1617267600
  }
]
```

単にデータをとってきたいだけなら以下のように書けば良い。

```swift
let data: [UserInfo] = try decoder.decode([UserInfo].self, from: Data(json.utf8))

struct UserInfo: Decodable {
    let id: String
    let createdAt: Date
}
```

```swift
// 実行結果
[Page_Contents.UserInfo(id: "tkgling", createdAt: 2021-04-01 09:00:00 +0000), Page_Contents.UserInfo(id: "tkgstrator", createdAt: 2021-04-01 09:00:00 +0000)]
```

## Codable から Codable へ

例えば、Salmon Stats はシフト統計のデータを取得しようとすると以下のようなレスポンスを返す。

```swift
class ShiftStats: Codable {
    // グローバルのみ対応
    var global: Stats
    struct Stats: Codable {
        var bossAppearance3: Int
        var bossAppearance6: Int
        var bossAppearance9: Int
        var bossAppearance12: Int
        var bossAppearance13: Int
        var bossAppearance14: Int
        var bossAppearance15: Int
        var bossAppearance16: Int
        var bossAppearance21: Int
        var bossAppearanceCount: Int
        var bossElimination3: Int
        var bossElimination6: Int
        var bossElimination9: Int
        var bossElimination12: Int
        var bossElimination13: Int
        var bossElimination14: Int
        var bossElimination15: Int
        var bossElimination16: Int
        var bossElimination21: Int
        var bossEliminationCount: Int
        var clearGames: Int
        var clearWaves: Int
        var games: Int
        var goldenEggs: Int
        var powerEggs: Int
        var rescue: Int
    }
}
```

一応`convertFromSnakeCase`を使えば自動でこの形に変換できるのだが、これをこのまま返すのは如何にもという感じがする。

```swift
class ShiftStats: Codable {
    // グローバルのみ対応
    var global: Stats
    struct Stats: Codable {
        var clearGames: Int
        var clearWaves: Int
        var games: Int
        var goldenEggs: Int
        var powerEggs: Int
        var rescue: Int
        var bossCounts: [Int]
        var bossKillCounts: [Int]
    }
}
```

せめてこういった感じのレスポンスにすべきである。

```swift
static func publish<T: RequestProtocol>(_ request: T) -> Future<T.ResponseType, APIError> {
  Future { promise in
    // 中略
    promise(.success(try decoder.decode(V.self, from: data)))
  }
}
```

ところがデータを処理する関数はジェネリクスを使ってこのように書かれている。

要するにリクエストプロトコル自体に変換したい構造体 ResponseType が指定されており、デコーダはその構造体に自動で変換しているというわけである。

で、ここの処理を変更するわけにはいかない。ここを変えてしまうと Codable で自動変換することができなくなってしまう。よって、一度自動変換してプロパティに突っ込んだデータを人間が読みやすい構造体に変換してから返したいわけである。
