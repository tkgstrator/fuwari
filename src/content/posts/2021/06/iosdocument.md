---
title: iOSでDocumentsにファイルを保存する方法
published: 2021-06-02
description: SwiftでiOSのDocumentsにファイルを保存するためのコーディングを学びます
category: Programming
tags: [Swift]
---

# Documents にデータを保存する意味

アプリには三つのコンテナがあり、それぞれ`Bundle Container`、`Data Container`、`iCloud Container`と呼ばれています。

この中で iTunes でバックアップできるのは`Data Container`になり、`Data Container`には「Documents」「Library」「Temp」の三つのディレクトリが存在しています。どこのフォルダに何を保存するかはガイドラインで決まっているので、それに従う必要があります。

## Documents

::: tip Documents について

ユーザーが生成したデータを保存するために使います。ファイル共有の機能により、ユーザーはこのディレクトリ以下にアクセスできます。したがって、ユーザーに見せても構わないファイルのみ置いてください。
iTunes および iCloud はこのディレクトリの内容をバックアップします。

:::

## Library

::: tip Library について

これは、ユーザーのデータファイル以外のファイル用の最上位ディレクトリです。通常、標準的なサブディレクトリを用意し、いずれか適当な場所に保存します。iOS アプリケーションは通常、Application Support および Caches というサブディレクトリを使いますが、独自のサブディレクトリを作成しても構いません。

ユーザーに見せたくないファイルは Library サブディレクトリ以下に置いてください。ユーザーデータのファイル保存用に使ってはなりません。

Library ディレクトリの内容は iTunes および iCloud によってバックアップされます（ただし、Caches サブディレクトリは除く）

:::

## Temp

::: tip Temp について

このディレクトリは、アプリケーションを次に起動するまで保持する必要のない一時ファイルを書き込むために使用します。不要になったファイルは削除しなければなりません。もっとも、アプリケーションが動作していないときに、システムがこのディレクトリ以下をすべて消去することがあります。
iTunes または iCloud はこのディレクトリの内容をバックアップしません。

:::

## Documents ディレクトリ

Documents ディレクトリにアクセスしようとしたら、まずパスがわからないといけません。

パスは`String`か`URL`で取得することが多いと思うのですが、結論から言えば`URL`で取得したほうが絶対に楽です。特に制限がなければ`URL`で取得するようにしましょう。

```swift
private var documentDirectoryFileURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
private var documentDirectoryFilePath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
```

URL の場合と String の場合で微妙に取得方法が違うのが面白いですね。これで非オプショナルなパスを取得することができます。

### サブディレクトリ

とはいえ、Documents 直下にファイルをガンガン保存することも少ないと思います。サブディレクトリを作成し、その中にファイルを保存したいという方が多いのではないでしょうか。

```swift
let path = documentDirectoryFileURL.appendingPathComponent("JSON", isDirectory: true)
do {
    try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true, attributes: nil)
} catch(let error) {
    print(error)
}
```

というわけで、今回は Documents 下に JSON というフォルダを作成します。作成できなかった場合はとりあえずエラーを表示していますが、ここは各自ななんか適当な処理を入れてください。`withIntermediateDirectories`というオプションに`true`を入れておけば中間ディレクトリも自動で作成してくれるので便利です。

### データ書き込み

画像の場合は以下のように Data 型に変換して保存します。

```swift
// 画像書き込み
let uiimage: UIImage = UIImage() // なんか適当なUIImageを取得
let image: Data = uiimage.jpegData(compressionQuality: 0.7)! // Data型に変換
let filePath: URL = documentDirectoryFileURL.appendingPathComponent("JSON/default.jpeg")
do {
    try image.write(to: filePath)
} catch(let error) {
    print(error)
}
```

今回は JPEG で保存していますが、PNG で保存したい場合は`let image: Data = uiimage.pngData()!`とすれば良いです。

テキストの場合は`String`であれば標準の書き込みライブラリである`write`が利用できます。

```swift
// テキスト書き込み
let text: String = "Hello, world!"
let filePath: URL = documentDirectoryFileURL.appendingPathComponent("JSON/default.txt")
do {
    try text.write(to: filePath, atomically: true, encoding: .utf8)
} catch(let error) {
    print(error)
}
```

`atomically`オプションは一時フォルダに書き込みを行い、成功すれば指定されたディレクトリにコピーするための保険のようなものです。エンコーディングは特に制限がなければ`.utf8`を利用するのがいいでしょう。

```swift
// JSON書き込み
let json: JSON = JSON()
let jsonString: String = json.description.data(using: String.Encoding.utf8)!
let filePath: URL = documentDirectoryFileURL.appendingPathComponent("JSON/default.json")
do {
    try jsonString.write(to: filePath, atomically: true, encoding: .utf8)
} catch(let error) {
    print(error)
}
```

JSON は結局テキストファイルなのでテキストと同じ書き込み方法が使えます。[SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)であれば上のコードで JSON を String に変換できるのでそれが一番手っ取り早いです。
