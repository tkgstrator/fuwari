---
title: KeychainAccessの理解を深めよう
published: 2021-06-28
description: 前回扱わなかったKeychainAccessの機能について解説していきます
category: Programming
tags: [Swift, SwiftUI]
---

# [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess)

KeychainAccess とは Keychain に簡単にアクセスすることができるライブラリのこと。

ユーザのパスワードのような気密性の高いデータは UserDefaults や DB ではなく Keychain に保存することが推奨されている。

その Keychain は使いにくいことで有名だったのだが、KeychainAccess を使うことで簡単に利用することができる。

[前回の記事](https://tkgstrator.work/posts/2021/04/15/keychain.html)では KeychainAccess を使ってデータ書き込みや読み込みを簡単にするための Extension について解説しました。

## Service と Server

KeychainAccess ではインスタンス生成時に引数をつけることで`Server`か`Service`かのどちらかを選択することができます。

> ちなみに何もつけなかった場合にはアプリのバンドル ID がそのまま使われるみたいです

今までは慣習的に`Server`を利用していたのですが、`Service`との違いは何なのでしょうか？

また、場合によっては一つのサービスについて複数のアカウント情報を保持し、ログイン時などにどちらのアカウントを選択するかユーザに選ばせたいような場合もあります。そのような複数アカウント機能を KeychainAccess で実装するにはどうすればよいでしょうか。

### Server

公式ドキュメントにもあるようにウェブサイトでのパスコードの保存に使う。

例えば、以下のようなコードを書いたとしよう。

```swift
var keychain: Keychain
keychain = Keychain(server: "AAA", protocolType: .https)
keychain["value"] = "AAA"
print(keychain["value"])
// -> AAA

keychain = Keychain(server: "BBB", protocolType: .https)
keychain["value"] = "BBB"
print(keychain["value"])
// -> BBB

keychain = Keychain(server: "AAA", protocolType: .https)
print(keychain["value"])
// -> BBB
```

二つのインスタンスは異なるものなので`AAA`の値は保存されそうなのだが、実は上書きされてしまう。

というのも、この`server`の値には URL に変換可能な文字列を代入する必要があるからだ。`KeychainAccess`ライブラリの内部で`String`から`URL`に変換される際に、変換不可能な倍には`server`には空文字が割り当てられている。

`AAA`も`BBB`も URL に変換不可能なのでどちらも`server=""`が割り当てられているのと同じ状態になり、そのため二つは同一のインスタンスになってしまっている。

そのため、データが上書きされてしまっているのだ。

```swift
var keychain: Keychain
keychain = Keychain(server: URL(string: "https://tkgstrator.work")!, protocolType: .https)
keychain["value"] = "AAA"
print(keychain["value"])
// -> AAA

keychain = Keychain(server: URL(string: "https://tkgstrator.works")!, protocolType: .https)
keychain["value"] = "BBB"
print(keychain["value"])
// -> BBB

keychain = Keychain(server: URL(string: "https://tkgstrator.work")!, protocolType: .https)
print(keychain["value"])
// -> AAA
```

このように URL に変換可能な文字列または直接 URL を指定した場合には正しくデータが保存される。

### Service

基本的には Server と同じなのですが、任意の文字列が利用できるという点が異なります。それ以外は全て同じです。

## Keychain へのデータ保存

ここを勘違いしてしまっていたのですが、Keychain へのデータの保存は辞書型ではないようです。

KeychainAccess のインスタンスの中身は以下のようになっており、これらが配列として保存されています。

|                    |  Server  | Service  |
| :----------------: | :------: | :------: |
| authenticationType |   Enum   |   Enum   |
|   synchronizable   |   Bool   |   Bool   |
|    accessGroup     | BundleID | BundleID |
|       class        |   Enum   |   Enum   |
|        key         |  String  |  String  |
|       value        |   Any    |   Any    |
|   accessibility    |   Enum   |   Enum   |
|      protocol      |   Enum   |    -     |
|       server       |   URL    |    -     |
|      service       |    -     |  String  |

つまり、例えば`keychain["price"] = 100`のようなコードを書いたとしてもどこにも`keychain["price"]`のデータはないということです。

じゃあどうやって保存されているのかというと、以下のように`key`が`price`で`value`が`100`のデータ（正確には上のようにもっといろんなデータが入っているが）が配列に追加されているだけだということです。

```swift
[
    [
        "key": "price",
        "value": "100",
        "server": "tkgstrator.work"
    ],
    [
        "key": "name",
        "value": "apple"
        "server": "tkgstrator.work"
    ],
]
```

これがどう困るかというと、サブアカウントのようなものを利用するときに困ります。

何故なら、このままだとどのアカウントのデータかを区別することができないからです。

値をユニークに保つために、Keychain では同一の`key`をもつことは許されていません。そうすれば単にデータが上書きされてしまうだけです。

```swift
[
    [
        "key": "userId",
        "value": "XXXXXXXX",
        "server": "tkgstrator.work"
    ],
    [
        "key": "userId",
        "value": "YYYYYYYY",
        "server": "tkgstrator.work"
    ]
]
```

単なる配列ならこのようなデータも保存できますが、これは同一のキーなのでどちらか一方しか保存できません。最初に書き込んだ方のデータは失われます。

これの対策として考えられるのが`Server`ないしは`Service`の値を変更することです。こうすれば別のデータとして扱えます。

```swift
var keychain: Keychain
keychain = Keychain(server: URL(string: "https://tkgstrator.work/account01")!, protocolType: .https)
keychain["userId"] = "XXXXXXXX"
print(keychain["value"])

keychain = Keychain(server: URL(string: "https://tkgstrator.work/account02")!, protocolType: .https)
keychain["userId"] = "YYYYYYYY"
print(keychain["value"])
```

つまり、このようにしてしまえば良いわけです。

ただし、この方法は次の観点から実装を見送りました。

- Keychain を切り替えるのがめんどくさい
  - 切り替えるのは良いとして、そのための`Server`などのリストはどうやって保存するのか
  - それも Keychain に入れれば仕様がややこしくなってしまう
- アカウント数が増えたときに切り替えるのがめんどくさい
  　　- アカウント数の分だけ Keychain のインスタンスを用意するのはめんどくさい

## 構造体を Keychain に保存する

そこで考えたのが、`userId = XXXXXXXX`のようなデータを保存するのではなく、キーとしてユーザ固有の値を与え、データにユーザ情報を全部入れてしまえばよいのではないかという方法でした。

```swift
// Before
keychain["userId"] = "XXXXXXXX"
keychain["password"] = "YYYYYYYY"
keychain["balancee"] = "ZZZZZZZZ"

// After
keychain["XXXXXXXX"] = User(password: "YYYYYYYY", balance: "ZZZZZZZZ")
```

しかし、これはこのままではビルドが通りません。Keychain に保存できるのは Data 型が String 型だと決まっているからです。

### Codable を利用する

ですが、Swift には構造体を Data 型に変換するためのプロトコルがあります。

それが当ブログでも何度か取り上げた`Codbale`というプロトコルで、これを使えば構造体を JSONEncoder で Data 型に変換できます。

いちいちデータをエンコードしたりデコードしたりはめんどくさいので、Extension を使ってそれらの部分をうまく処理してやりましょう。

```swift
// Keychianに保存する構造体をCodable準拠にする
struct Account: Codable {
    var userId: String = ""
    var password: String = ""
    var membership: Bool = false

    init() {}
}
```

構造体を Codable にするには単に適合させるだけで良いです。何か特別なことをする必要はありません。

```swift
// Extension
extension Keychain {
    func setValue(forKey: String, account: Account) throws -> () {
        let encoder: JSONEncoder = {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            return encoder
        }()

        let data = try encoder.encode(account)
        try set(data, key: forKey)
    }

    func getValue(forKey: String) throws -> Account {
        let decoder: JSONDecoder = {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return decoder
        }()
        guard let data = try getData(forKey) {
            return try decoder.decode(Account.self, from: data)
        }
        throw fatalError()
    }
}
```

これはエラーを認めてそれを返すようなメソッドですが、ネットワークからレスポンスを受け取っているわけではないので実際にエラーが発生することは（おそらく殆どない）と思われます。

```swift
// エラーを握りつぶす場合
extension Keychain {
    func setValue(forKey: String, account: Account) -> () {
        let encoder: JSONEncoder = {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            return encoder
        }()

        guard let data = try? encoder.encode(account) else { return }
        try? set(data, key: forKey)
    }

    func getValue(forKey: String) -> Account? {
        let decoder: JSONDecoder = {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return decoder
        }()

        guard let data = try? getData(forKey) else { return nil }
        return try? decoder.decode(Account.self, from: data)
    }
}
```

エラーが発生しないようなケースであれば`try?`でエラーを握りつぶしてしまうのもアリです。

自分の場合はエラーが発生しないケースでしたので、後者を選択しました。

```swift
extension Keychain {
    func removeValue(account: Account) {
        try? remove(account.userId)
    }
}
```

最後に、データを削除できるようにしておいても良いかもしれません。

### 使い方

```swift
let keychain = Keychain(service: "work.tkgstrator")

// データ読み込み(ない場合はnilが返ってくる)
guard let account = keychain.getValue(userId: "tkgling") else { return }

// データ書き込み
let account: Account = Account()
keychain.setValue(account: account)
```

### 構造体が Nil を許容する場合

構造体にオプショナル型のプロパティをつけても正しく動作しました。

```swift
struct Account: Codable {
    var userId: String?
    var password: String?
    var membership: Bool

    init() {}
}
```

ただし、キーだけはオプショナルではダメなので、今回のように`userId`をキーにする場合は書き込む前に`userId`が`nil`でないかだけはチェックする必要があります。

```swift
let keychain = Keychain(service: "work.tkgstrator")

var account: Account = Account()
account.userId = "tkgstrator"
keychain.setValue(account: account)

guard let account = keychain.getValue(userId: "tkgstrator") else { return }
print(account)
// Account(userId: Optional("tkgstrator"), password: nil, membership: nil)
```

こうすれば直感的にデータを取得できるので便利でした。
