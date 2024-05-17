---
title: 動的なキーをもつJSONをCoodableで扱う
published: 2021-07-19
description: 動的なキーをもつJSONをCodableでデコードする方法について解説します
category: Programming
tags: [Swift, JSON]
---

# 動的なキーをもつ JSON を扱う

## コーディング

### 受け取るレスポンス

受け取る JSON は次のようなものを考える。

ユーザのデータを取得する API を叩いたときにユーザの ID と共に直近の成績が日付をキーとして返ってくるようなケースである。

```json
{
  "user_id": 0,
  "results": {
    "2022-07-01": {
      "value": 100
    },
    "2022-07-02": {
      "value": 50
    }
  }
}
```

これをそのまま Codale で実装することはできない。何故ならキーが動的であるからだ。Codable ではキー名と変数名が一致しないといけない。

そのような構造体は宣言不可能なのでデコードすることができないというわけだ。

そこで、便宜的に上の JSON を以下のように扱う。

```json
{
    "user_id": 0,
    "results": [
        {
            "date": "2022-07-01"
            "value": 100
        },
        {
            "date": "2022-07-02"
            "value": 50
        }
    ]
}
```

こうすれば、`results`はある特定の構造体の配列とみなすことができるので、

```swift
struct UserInfo: Codable {
    let userId: Int
    let results: [UserResult]

    struct Result: Codable {
        let published: String
        let value: Int
    }
}
```

のような構造体を定義することで変換することができる。要するに、ネストを一つ減らすことで対応しようというわけである。

### イニシャライザの追加

`UserInfo.UserResult`が受け取る JSON レスポンスの構造とは変わってしまっているので独自にイニシャライザを定義します。

```swift
struct UserInfo: Codable {
    let userId: Int
    let results: [Result]

    struct Result: Codable {
        let published: String
        let value: Int

        // イニシャライザの追加
        init(published: String, value: Int) {
            self.date = date
            self.value = value
        }
    }
}
```

### コーディングキーの追加

手動で変換するのでコーディングキーを定義しなければいけません。

`struct`と`enum`の二つの定義があってややこしい気がするのですが、オブジェクトから配列に変換したいプロパティをもつ構造体に対しては`struct`で定義すればよいです。

今回の場合ですと、手動で変換したいのは`results`なのでそれをもつ`UserInfo`構造体は`struct`でコーディングキーを定義します。

```swift
private struct UserInfoKey: CodingKey {
    var stringValue: String

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int?

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    static let userId = UserInfoKey(stringValue: "userId")!
    static let results = UserInfoKey(stringValue: "results")!
}

private enum ResultKey: String, CodingKey {
    case value
}
```

`.convertFromSnakeCase`を指定している場合は`CodingKey`で受け取った時点で変換が完了しているのでキー名を間違えないようにしましょう。

### UserInfo のイニシャライザ

最後に手動で変換するためのイニシャライザを定義します。

```swift
init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: UserInfoKey.self)
    self.userId = try container.decode(Int.self, forKey: .userId)

    let resultContainer = try container.nestedContainer(keyedBy: UserInfoKey.self, forKey: .results)
    // resultsが持つ全てのキーについてループ
    self.results = resultContainer.allKeys.map({
        let resultContainer = try! resultContainer.nestedContainer(keyedBy: ResultKey.self, forKey: UserInfoKey(stringValue: $0.stringValue)!)
        let value = try! resultContainer.decode(Int.self, forKey: ResultKey.value)
        return UserInfo.Result(published: $0.stringValue, value: value)
    })
}
```

### 実行してみた

```swift
let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
}()
let data = try decoder.decode(UserInfo.self, from: Data(json.utf8))
print(data) // -> UserInfo(userId: 0, results: [UserInfo.Result(published: "2022-07-01", value: 100), UserInfo.Result(published: "2022-07-02", value: 50)])
```

## 二層構造の場合

先程のコードはネストが 1 だったのだが、動的なキーのネストが 2 の場合はどうするのか考えてみる。

つまり、以下のような JSON レスポンスを想定するわけである。

```json
{
  "user_count": 2,
  "results": {
    "0": {
      "2022-07-01": {
        "value": 100
      },
      "2022-07-02": {
        "value": 50
      }
    },
    "1": {
      "2022-07-03": {
        "value": 50
      },
      "2022-07-04": {
        "value": 25
      }
    }
  }
}
```

これもやはりこのままではデコードできないので、次のように考えてみる。

```json
{
  "user_counts": 2,
  "results": [
    {
      "user_id": 0,
      "results": [
        {
          "date": "2022-07-01",
          "value": 100
        },
        {
          "date": "2022-07-02",
          "value": 50
        }
      ]
    },
    {
      "user_id": 0,
      "results": [
        {
          "date": "2022-07-01",
          "value": 100
        },
        {
          "date": "2022-07-02",
          "value": 50
        }
      ]
    }
  ]
}
```

こうであれば先程の考えをそのまま利用して

```swift
// 構造体の定義
struct Response: Codable {
    let userCount: Int
    let results: [UserInfo]

    struct UserInfo: Codable {
        let userId: Int
        let results: [Result]

        struct Result: Codable {
            let published: String
            let value: Int
        }
    }
}
```

の配列が返ってくると考えれば良いことになる。一見すると難しそうな気がするが、動的なキーの処理を二重ループにするだけである。

いや、まあそれがめんどくさいんですけど。

### コーディングキーの定義

ネストが一つ増えたので、コーディングキーも一つ増えます。

今回は最もネストが浅いキーを`ResponseKey`としました。

```swift
// 追加
private struct ResponseKey: CodingKey {
    var stringValue: String

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int?

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    static let userCounts = ResponseKey(stringValue: "userCounts")!
    static let results = ResponseKey(stringValue: "results")!
}

// 以下は前のものを流用
private struct UserInfoKey: CodingKey {
    var stringValue: String

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int?

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
    static let value = ResponseKey(stringValue: "value")!
}

private enum ResultKey: String, CodingKey {
    case value
}
```

### イニシャライザの定義

最後に`Response`構造体のイニシャライザを定義します。

```swift
// Responseのイニシャライザ
init(from decoder: Decoder) throws {
    // コーディングキーを読み込む
    let containter = try decoder.container(keyedBy: ResponseKey.self)
    // UserCountsはそのまま利用できるので何もしない
    self.userCount = try containter.decode(Int.self, forKey: .userCounts)
    // Resultsが持つオブジェクトを扱うコンテナを定義する
    let userContainer = try containter.nestedContainer(keyedBy: ResponseKey.self, forKey: .results)
    // Resultsが持つキー(userId)をInt型に変換してソートして配列として保存
    let userList: [Int] = userContainer.allKeys.compactMap({ Int($0.stringValue) }).sorted(by: <) // -> [0, 1]

    // ユーザごとにループを回す
    // めんどくさいのでcompactMapで配列を返す
    self.results = try userList.compactMap({
        // 指定されたuserIdがもつオブジェクトを扱うコンテナを定義する
        let resultContainer = try userContainer.nestedContainer(keyedBy: UserInfoKey.self, forKey: ResponseKey(intValue: $0)!)
        // 指定されたuserIdが持つキー(date)をString型に変換して配列として保存
        let resultList: [String] = resultContainer.allKeys.compactMap({ $0.stringValue })
        // そのキーが持つデータを読み込んでUserInfo型で返し、配列としてresultsに保存する
        let results: [UserInfo.Result] = try resultList.compactMap({
            let container = try resultContainer.nestedContainer(keyedBy: ResultKey.self, forKey: UserInfoKey(stringValue: $0)!)
            let value = try container.decode(Int.self, forKey: ResultKey.value)
            return UserInfo.Result(published: $0, value: value)
        })
        // 返ってきた[UserInfo]にIdの情報をつけて返す
        return UserInfo(userId: $0, results: results)
    })
}
```

### 二層構造+配列

```json
{
  "user_counts": 2,
  "results": {
    "0": {
      "2022-07-01": [
        {
          "value": 100
        },
        {
          "value": 30
        }
      ],
      "2022-07-02": [
        {
          "value": 70
        },
        {
          "value": 35
        }
      ]
    },
    "1": {
      "2022-07-02": [
        {
          "value": 120
        },
        {
          "value": 60
        }
      ],
      "2022-07-03": [
        {
          "value": 80
        },
        {
          "value": 40
        }
      ]
    }
  }
}
```
