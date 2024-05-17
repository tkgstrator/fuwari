---
title: SwiftUIでEnvironmentを使おう
published: 2021-04-13
description: 環境変数を理解することでコーディングが楽になります
category: Programming
tags: [Swift]
---

## EnvironmentValues

[Apple のドキュメント](https://developer.apple.com/documentation/swiftui/environmentvalues)にたくさん載っているのでこれを学んでいきましょう。

### locale

現在のロケールの環境変数。

### timeZone

タイムゾーンを取得する。Swift では`TimeZone.current`で取得することもできるが、環境変数を使うほうが良さそうである。

### lineLimit

テキストで折返しをするかどうかの環境変数。1 だと折り返さず三点リーダで省略される。

### lineSpacing

### multilineTextAlignment

複数行に渡るテキストをどこで揃えるかどうか。

### minimumScaleFactor

テキストにおける指定フォントサイズに対して何%まで小さくすることを認めるかの環境変数。

例えば、0.5 としておいてフォントサイズを 20 と指定すればデバイスや表示したい文字の長さによってフォントサイズを 10 まで小さくする。

### sizeCategory

### truncationMode

### textCase

### font

デフォルトのフォントを指定。

### editMode

編集機能を有効化しているかどうかの環境変数

### isEnabled

ユーザの操作を受け付けるかどうかの環境変数。

### presentationMode

現在のビューが別のビューから呼ばれているかどうかの環境変数。

```swift
// 定義
@Environment(\.presentationMode) var present: Bool

// 現在のビューを閉じる
present.wrappedValue.dismiss()
```

このようにすれば画面を閉じることができる、便利。

### imageScale

画像のサイズを指定できる。`small`、`medium`、`large`の三つがあった気がするが
`large`でも全然大きくなくて困る。

`extraLarge`みたいな Enum が欲しい、実装方法ないのかな。
