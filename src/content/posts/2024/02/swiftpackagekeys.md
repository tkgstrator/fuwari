---
title: SwiftPackageKeysを使ってみた 
published: 2024-02-25
description: SwiftPackageKeysで比較的安全に環境変数をXcodeで利用する方法について
category: Programming
tags: [Swift, Swift Package, Xcode]
---

## SwiftPackageKeys

パッケージは[GitHub](https://github.com/MasamiYamate/SwiftPackageKeys)で公開されているのでそれを利用します。

```zsh
SwiftPackageKeysDemo/
├── SwiftPackageKeysDemo/
│   ├── Assets.xcassets/
│   ├── Preview Content/
│   ├── ContentView.swift
│   └── SwiftPackageKeysDemoApp.swift
├── SwiftPackageKeysDemo.xcodeproj/
└── .env
```

適当にSwiftPackageKeysDemoというアプリを作成して、ディレクトリの直下に`.env`を配置します。ここは`.env.json`でJSON形式も利用できるそうなのですが、慣れているので今回は`.env`を使います。

```zsh
APP_SECRET_KEY=559603377072552A1E4B5F300451F883
```

内容には適当に32文字のHEX文字列を定義しました。

で、アプリをビルドします。すると、以下のような感じで読み込んだ環境変数を`SwiftPackageKeys.appSecretKey.value`で取得することができます、簡単ですね。

```swift
import SwiftUI
import SwiftPackageKeys

struct ContentView: View {
    var body: some View {
        VStack(content: {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text(SwiftPackageKeys.appSecretKey.value ?? "-")
        })
        .padding()
    }
}
```

## Realm Encryption Key

で、例えば暗号化のための鍵を.envに定義したい場合があります、ありますよね？

iOS向けのデータベースライブラリとして有名な[Realm](https://github.com/realm/realm-swift?tab=readme-ov-file#fully-encrypted)は暗号化に対応しているのですが、

```swift
var key = Data(count: 64)
_ = key.withUnsafeMutableBytes { bytes in
    SecRandomCopyBytes(kSecRandomDefault, 64, bytes)
}
```

とあるように鍵は長さが64である必要があります。

```zsh
APP_SECRET_KEY=71ADA0092BAC5543D3205444DC1062B09C9D5F7161720FA49C64648175887767
```

というわけで`APP_SECRET_KEY`を64文字にしてビルドすると、

```zsh
Swift/ContiguousArrayBuffer.swift:600: Fatal error: Index out of range
```

と表示されてコケてしまいます。

色々長さを変えてチェックしてみると33文字以上になるとこのエラーが出るようです。鍵の長さが32文字というのは少し短い気もするのでここはなんとか対応したい感じです。

単に32文字の定義を二つ用意して結合することもできるのですが、それはあんまりなのでソースコードを改良して33文字以上の文字列を設定できるようにしましょう。

### 調査

- 32文字以下の文字列は正しく変換できる
- 33文字以上の文字列は`Fatal error: Index out of range`が表示される

ここで気になるのはエラー自体がソースコード内で起きているわけではなく`Swift/ContiguousArrayBuffer.swift:600`とあるようにSwiftの標準ライブラリ内で発生していることです。

```zsh
KeyGenerator/
└── Sources/
    ├── Constants/
    │   ├── Template/
    │   └── KeyGenerateError.swift
    ├── Extensions/
    │   ├── EnvironmentKey+Extension.swift
    │   └── String+Extension.swift
    ├── Models/
    │   ├── EnvironmentItem.swift
    │   └── EnvironmentKey.swift
    ├── Encryption.swift
    ├── EncryptionCodeGenerator.swift
    ├── EnvLoader.swift
    ├── KeyGenerateArguments.swift
    ├── KeyValueGenerator.swift
    └── main.swift
```

ビルド時に発生しているのでバイナリではなくどこかのファイルでエラーが発生していると考えられます。

```swift
func main() throws {
    Encryption.shared.encryptionKey = UUID().uuidString.replacingOccurrences(of: "-", with: "")
}
```

すると`main.swift`に上のようなコードを見つけました。

UUIDはハイフンを除けば全部で32文字なので`Encryption.shared.encryptionKey`は最大で32文字までしか割り当てられないということになります。

```swift
func encrypt(_ input: String) -> String {
    let inputValueBytes = [UInt8](input.utf8)
    let encryptionKeyBytes = self.encryptionKeyBytes
    let encryptedBytes: [UInt8] = inputValueBytes.enumerated().map { byte in
        byte.element ^ encryptionKeyBytes[byte.offset]
    }
    ...
}
```

更に実際に暗号化を施すところでは`encrptionKeyBytes`が`inputValueBytes`よりも長いことを前提としたコードになっています。

`inputValueBytes`はUUIDで初期化されていて32文字しかないので、33文字以上の値を暗号化しようとするとインデックス外参照で落ちてしまうというわけですね。

正直、32文字もあれば鍵の長さとしては十分なのですが、このライブラリは暗号化と復号にXORを使っており、更に鍵の長さが入力値よりも長いことを前提としているコードになっているので、入力値が32文字以下というのは大きな制約になります。

例えば先ほど紹介したRealmは暗号化鍵として64文字の文字列を割り当てる仕様になっています。

SwiftPackageKeysは、

- XORを利用していること
- 鍵の長さ>平文の長さを前提とした設計であること
- 鍵の長さが128bitしかないこと

からRealmの暗号鍵を暗号化して保存することができない仕様になっています。これ、なんとかしたいですよね？

これの解決法としては鍵を単純にXORして利用するのをやめてブロック暗号に切り替えるなどといった方法が考えられます。

> ブロック暗号を利用するためにCryptoKitなどを使えば逆にリバースエンジニアリングで解読されやすくなってしまうのだが......

とはいえ、そこまでの強度が必要でないのであれば(どうせ逆アセされるとバレるので)単に鍵を長くしてしまえば良いということになります。

正直、無意味に鍵を長くするのは好みではないのですが、ブロック暗号を実装するのもめんどくさかったのでこの方法を採用しました。

## 追記

なんとSwiftPackageKeysが[CryptoKitに対応して任意の長さの文字列に対応](https://github.com/MasamiYamate/SwiftPackageKeys/pull/14)してくれるそうです！！

正直、自分の実装はカスだったのでこうやって対応していただけるのはとてもありがたかったりします。

記事は以上。
