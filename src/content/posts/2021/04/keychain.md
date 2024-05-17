---
title: KeychainAccessでKeychainを簡単に扱おう
published: 2021-04-15
description: Keyhcainではそのままでは扱いにくいのだが、KeychainAccessというライブラリを使えば手軽に扱えます
category: Programming
tags: [Swift]
---

## Keychain

そもそも Keychain を使うメリットは何なのかという事になります。

似たような仕組みに UserDefaults があるのですが、何が違うのかを考えてみましょう。

|                          |      UserDefaults      |       Keychain       |
| :----------------------: | :--------------------: | :------------------: |
|        アプリ削除        |       データ消失       |       消えない       |
|       データ保存先       |        アプリ内        |       Keychain       |
|          暗号化          |        されない        |        される        |
|       データの共有       |          不可          |  条件を満たせば可能  |
| 他アプリからのデータ共有 |          不可          |  条件を満たせば可能  |
|         利用目的         | 非セキュアなデータ保存 | パスコードなどの保存 |

データを共有するかどうかはおいといて、セキュアにデータを保存できるのが Keychain の強みとなります。アプリを削除してもデータが消えないというのは便利な気がしますね。

例えば Salmonia であれば Keychain に iksm_session を保存しておけばアプリを削除しても復活できるのは便利です。

### KeychainAccess

Keychain にアクセスするのはめんどくさいのですが、[KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess)というライブラリを使えば簡単にアクセスできます。

が、これを使っても少し面倒な一面があるのでそれを更に便利にするための Extension を考えます。

```swift
import KeychainAccess

var keychain: Keychain {
    let server = "tkgstrator.work"
    return Keychain(server: server, protocolType: .https)
}

enum KeyType: String, CaseIterable {
    case iksmSession = "iksmSession"
    case sessionToken = "sessionToken"
}

extension Keychain {
    func setValue(value: String, forKey: KeyType) {
        try? keychain.set(value, key: forKey.rawValue)
    }

    func getValue(forKey: KeyType) -> String? {
        return try? keychain.get(forKey.rawValue)
    }

    func remove(forKey: KeyType) {
        try? keychain.set(nil, key: forKey.rawValue)

        // こっちでもいけるかも
        try? keychain.remove(forKey.rawValue)
    }
}
```

例えば上のような Extension を考えます。すると以下のようなコードでデータの読み書きができるようになります。

今回データの読み書きに Enum を使ったのは Typo によるキー指定のミスをなくすためです。キーの数が多ければミスも増えると思うので、Enum を使ったほうが良いかもしれません。

ただ、Enum が多いと書くのが面倒なので一つや二つくらいであれば直接指定でもいいのかも。

```swift
// データ保存
keychain.setValue(value: "IKSM SESSION", forKey: .iksmSession)

// データ取得
let iksmSession = keychain.getValue(forKey: .iksmSession)

// データ削除
keychain.remove(forKey: .iksmSession)
```

NSData や String の保存には対応しているっぽいのですが、Bool や Int の保存は現状できないっぽい感じでしょうか。まあ必要とあらば上手く変換したりすればいけるのではないかと思います。

@[youtube](https://www.youtube.com/watch?v=9fQr8ykquCA)
