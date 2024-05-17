---
title: Codableでnullが消えてしまう問題に対応する
published: 2021-11-21
description: Codable準拠の構造体をJSONに変換するとき、nilが入っていると正しく変換できない問題に対応します
category: Programming
tags: [Swift]
---

# Codable

Swift には`Codable`という仕組みがあり、これを利用すると構造体を直接 JSON に変換することができる。

やり方は簡単で、単に構造体を`Codable`準拠にさせてやれば良い。

## Codable に準拠したプロトコル

- 常に Codable
  - Int, Double, String, Data, Date, URL
- 条件付き Codable
  - Array, Dictionary, Optional, Enum
    - 中身が`Codable`の場合
  - Struct
    - プロパティが全て`Codable`から構成されている場合

で、自分で受け取るレスポンスに合わせて構造体を書かなければならず、ネストが深い`JSON`だとそれがめんどくさかったりするのだが、それを一括で自動で行ってくれるウェブサービスがある。

### [QuickType](https://app.quicktype.io/)

ここに API のレスポンスを突っ込めばうまい具合に構造体や Enum を生成してくれる。あとは`null`チェックを簡単に済ませれば良い。

::: tip CodingKeys について

このサイトでは自動的に CodingKeys が設定されるが、`Acronym naming style`のオプションで`Camel`を設定すればキーを自動的に`Camel case`に変換してくれる。`JSONDecoder()`にはキーを変換するためのオプションがあるので、これらをどちらも設定すれば`CodingKeys`は不要となる。

:::

## null が消えてしまう問題

例えば、以下のような構造体を考えよう。

```swift
struct User: Codable {
    let id: String
    let nickname: String?
}
```

要はユーザのレスポンスを受け取り、`id`は常にあることが保証されるが、`nickname`は設定している人もいるかもしれないし、設定していない人がいるかも知れないのでオプショナルで受け取りたいということだ。

よって、想定される`JSON`のレスポンスは以下のようになる。

```json
[
  {
    "id": "tkgling",
    "nickname": "me"
  },
  {
    "id": "tkgstrator",
    "nickname": null
  }
]
```

で、これ自体は上述した構造体で簡単に受け取れることができる。そこは問題ない。

問題となるのは構造体から`JSON`を復元しようとした場合である。

```swift
private let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    // キーをCamel caseからSnake caseに変換する
    encoder.keyEncodingStrategy = .convertToSnakeCase
    return encoder
}()

let user: User = User(id: "tkgstrator", nickname: nil)

// Data?型に変換
guard let data = try? encoder.encode(self) else {
    return
}

// JSONに変換
guard let json = try? JSONSerialization.jsonObject(with: data, options: []) else {
    return
}
```

で、これで得られる`JSON`は当然、

```json
{
  "id": "tkgstrator",
  "nickname": null
}
```

となっていて欲しいのだが、そうはならない！

```json
{
  "id": "tkgstrator"
}
```

何故かこのように`null`を値として持つキーがまるごと消えてしまうのである。で、これ自体は`JSONSerialization`のオプションで解決することができない。

## NullCodable

[stack overflow](https://stackoverflow.com/questions/47266862/encode-nil-value-as-null-with-jsonencoder)で同様の質問があり、この問題をスマートに解決する方法が載っていました。

```swift
@propertyWrapper
struct NullEncodable<T>: Encodable where T: Encodable {

    var wrappedValue: T?

    init(wrappedValue: T?) {
        self.wrappedValue = wrappedValue
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch wrappedValue {
        case .some(let value): try container.encode(value)
        case .none: try container.encodeNil()
        }
    }
}
```

その解説では`Encodable`を利用して`container.encodeNil()`で強制的に`nil`を割り当てるわけである。

が、これはこのままでは`Encodable`なだけで`Decodable`に対応できていないので、どちらも対応した`Codable`に準拠させるために改良を行った。

```swift
import Foundation

@propertyWrapper
public struct NullCodable<T>: Codable where T: Codable {
    public var wrappedValue: T?

    public init(wrappedValue: T?) {
        self.wrappedValue = wrappedValue
    }

    // Decodableを追加
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        switch wrappedValue {
            case .some(_):
                self.wrappedValue = try container.decode(T.self)
            case .none:
                self.wrappedValue = nil
        }
    }

    // Encodable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch wrappedValue {
            case .some(let value):
                try container.encode(value)
            case .none:
                try container.encodeNil()
        }
    }
}
```

    case randomGold                 = "-2"
    case randomGreen                = "-1"
    case shooterShort               = "0"
    case shooterFirst               = "10"
    case shooterPrecision           = "20"
    case shooterBlaze               = "30"
    case shooterNormal              = "40"
    case shooterGravity             = "50"
    case shooterQuickMiddle         = "60"
    case shooterExpert              = "70"
    case shooterHeavy               = "80"
    case shooterLong                = "90"
    case shooterBlasterShort        = "200"
    case shooterBlasterMiddle       = "210"
    case shooterBlasterLong         = "220"
    case shooterBlasterLightShort   = "230"
    case shooterBlasterLight        = "240"
    case shooterBlasterLightLong    = "250"
    case shooterTripleQuick         = "300"
    case shooterTripleMiddle        = "310"
    case shooterFlash               = "400"
    case rollerCompact              = "1000"
    case rollerNormal               = "1010"
    case rollerHeavy                = "1020"
    case rollerHunter               = "1030"
    case rollerBrushMini            = "1100"
    case rollerBrushNormal          = "1110"
    case chargerQuick               = "2000"
    case chargerNormal              = "2010"
    case chargerNormalScope         = "2020"
    case chargerLong                = "2030"
    case chargerLongScope           = "2040"
    case chargerLight               = "2050"
    case chargerKeeper              = "2060"
    case slosherStrong              = "3000"
    case slosherDiffusion           = "3010"
    case slosherLauncher            = "3020"
    case slosherBathtub             = "3030"
    case slosherWashtub             = "3040"
    case spinnerQuick               = "4000"
    case spinnerStandard            = "4010"
    case spinnerHyper               = "4020"
    case spinnerDownpour            = "4030"
    case spinnerSerein              = "4040"
    case twinsShort                 = "5000"
    case twinsNormal                = "5010"
    case twinsGallon                = "5020"
    case twinsDual                  = "5030"
    case twinsStepper               = "5040"
    case umbrellaNormal             = "6000"
    case umbrellaWide               = "6010"
    case umbrellaCompact            = "6020"
    case shooterBlasterBurst        = "20000"
    case umbrellaAutoAssault        = "20010"
    case chargerSpark               = "20020"
    case slosherVase                = "20030"
