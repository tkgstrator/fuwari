---
title: RealmSwiftをSwiftPackageに対応させる
published: 2021-08-10
description: RealmSwiftをSPM経由でプロジェクトに対応させるのは簡単なのですが、SPにRealmSwiftを対応させることは可能なのでしょうか
category: Programming
tags: [Swift, RealmSwift]
---

# [RealmSwift](https://github.com/realm/realm-cocoa)

RealmSwift で定義したモデルケースを SwiftPackage でフレームワーク化しようとしたらちょっと詰まったので掲載。

というか、今調べたら普通に日本語ドキュメント出てきてぼくは泣きました。

ほとんど全く同じことを[[SwiftPM][Realm] Swift Package の Package.swift の記述方法 Realm に依存するケース](https://software.small-desk.com/development/2020/09/19/spmrealm-swift-package-for-package-depends-on-realm/)で書かれているので、オチが気になる人は先にこっちを読んでしまっても良いです。

## Package.swift

本来であればそのまま必要なライブラリの情報を`Package.swift`に書けばよいのですが、`realm-cocoa`で提供されているパッケージ名は`Realm`なので`RealmSwift`をそのまま取り込むことができません。

> (1), (2) の行がポイントです。
> 特に、(2) の Package "Realm" 内で定義されている Product "RealmSwift" を記述しないと RealmSwift が見つからずコンパイルエラーが発生します。

```swift
dependencies: [
    .package(name: "Realm", url: "https://github.com/realm/realm-cocoa.git", from: "10.12.0"),
],
```

なので、単なる`dependencies`には次のように名前を指定して読み込み、

```swift
dependencies: ["Realm", .product(name: "RealmSwift", package: "Realm")]),
```

実際に利用するところでは`Realm`に加えて`RealmSwift`も利用するということを明記しなければいけません。

これでライブラリ側から`RealmSwift`が利用でき、コンパイルエラーも発生しなくなります。

## RealmSwift のおまけ

`AppDelegate`に次のようにシミュレータビルド時には Realm のディレクトリを表示するようにしておくとちょっと便利です。

```swift
// シミュレータビルド時にはディレクトリを表示
#if targetEnvironment(simulator)
print(Realm.Configuration.defaultConfiguration.fileURL!.path)
#endif
```

以下のようなものが表示されるので Finder でパパっと目的のファイルをひらくことができます。

`/Users/devonly/Library/Developer/CoreSimulator/Devices/827DB7C3-CBCE-4D0F-857C-01ADFE8B216A/data/Containers/Data/Application/51452190-6D80-4887-9C93-A05F5B18C5C5/Documents/default.realm`


