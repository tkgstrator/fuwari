---
title: RealmOptionalがRealmPropertyになっていた
published: 2021-06-30
description: RealmSwiftのバージョンv10.8.0から仕様が変わっていました
category: Programming
tags: [Swift, Realm]
---

# [RealmSwift](https://github.com/realm/realm-cocoa/releases/tag/v10.8.1)

最近 RealmSwift のバージョンが上がったらしく、それに伴ってデータベースに保存するオプショナル型の扱いが変わりました。

調べてもドキュメントは 10.5.0 くらいまでしか対応してなかったので自分で新しいコーディング方法を調べました。

## RealmProperty

今まで`RealmOptional`を使っていたものが`RealmProperty`に変わりました。それだけでなく、ちょっとだけ宣言の方法も変わったのでそれもご紹介。

```swift
// Deprecated
let zipcode = RealmOptional<Int>()

// Modern
let zipcode = RealProperty<Int?>()
```

要するに`RealmOptional`を`RealmProperty`に書き換えて、明示的にオプショナルであることを宣言するようにすれば良い。

`Int`だけじゃなくて`Bool`にも使える、便利。

`Optional`だけじゃなくて他にもアップデートがあって、`UUID`や`NSUUID`も新たに保存できるようになったようです。

## Extension の書き方

型が`Int`ではなくなったので Extension の書き方も変わりました。

例えば、強制的にアンラップするような以下のコードは次のように書き換えられます。

```swift
// Deprecated
extension RealmOptional where Value == Int {
    var intValue: Int {
        guard let value: Int = self.value else { return 0 }
        return value
    }
}

// Modern
extension RealmProperty where Value == Int? {
    var intValue: Int {
        guard let value: Int = self.value else { return 0 }
        return value
    }
}
```

まあそれだけで特に面白いところはなかったのですが。

記事は以上。
