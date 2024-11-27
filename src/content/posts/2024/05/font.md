---
title: Swiftでアプリにフォントをバンドルせずに利用する方法 
published: 2024-05-04
description: アプリでフォントを利用する方法について解説します
category: Programming
tags: [Swift, SwiftUI]
---

## 概要

まず、アプリからフォントを利用する方法は三つあります。

よく解説されている順番に解説します。

### アプリにバンドルする

最もよく利用されるのが[こちらの方式](https://dev.classmethod.jp/articles/uikit-swiftui-custom-font/)です。

これはアプリ自体にフォントをバンドルするのでフォントをアプリにバンドルして配布する権利を持っている場合のみ利用可能です。

欠点としてはフォントの数が多くなるとアプリ自体が肥大化してしまうことが挙げられます。

## コンテンツデリバリーを利用する

これは今まで一度も利用したことがないのですがサーバーにフォントをアップロードしておいて、それをバンドルとしてダウンロードして利用する機能です。

ソーシャルゲームで起動時にコンテンツをダウンロードします、のタイプのアプリはこれを利用しています。

この場合、サーバーが信頼されているものとしてアプリに認識されているため通常であれば書き込めない領域にデータを書き込むことができます。

### ファイルURLを利用する

そのどれも利用できない場合、この選択肢になります。

これはフォントをURLからアプリのドキュメントフォルダなどにダウンロードし、起動時にフォントを読み込んで反映させる方式です。

仕組みとしては`CTFontManagerCreateFontDescriptorsFromURL`を利用するのですが、流れとしては、

1. URLを読み込む (`URL`)
2. URLをCFURLに変換する (`CFURL`)
3. CTFontManagerCreateFontDescriptorsFromURLを使って変換する (`CFArray`)
4. `[CTFontDescriptor]`に変換する (`[CTFontDescriptor]`)
5. `CTFontDescriptorを読み込む` (`CTFontDescriptor`)

という感じでとてつもなく長い手順を踏む必要があります。

とはいえ、基本的に型変換をするだけなのでExtensionを利用すればこのあたりは自動化できます。

```swift
extension URL {
  var fontDescriptor: UIFontDescriptor {
    guard let array: CFArray = CTFontManagerCreateFontDescriptorsFromURL(self as CFURL),
      let fonts: [CTFontDescriptor] = array as? [CTFontDescriptor],
      let font: CTFontDescriptor = fonts.first
    else {
        return .init()
    }
    return font as UIFontDescriptor
  }
}
```

もしもフォントのファイルのURLがわかっているのであれば上の拡張機能を利用して`fontURL.fontDescriptor`でフォントのデータを読み込むことができます。

フォントは複数のフォントが混ざっている場合があるので(boldとかそういうの)、今回の場合は常に先頭のフォントを利用するようにしていますが、ここは適時変更してください。

#### 問題点

この実装方法には多少問題があります。

というのも、フォント自体がアプリにバンドルされているわけではないのでフォントを読み込もうとするたびに上記の`fontDescriptor`の呼び出しが走ってしまうということです。

この処理自体は重くはないものの、大量のテキストが表示されるような場面やリストを表示するような場面ではドキュメントフォルダへのアクセスが大量に発生するためアプリのパフォーマンスが悪くなります。

そこで`UIFontDescriptor`は一度呼び出されたあとは上記の処理がアプリの再起動が実行されるまでは二度と呼び出されないようにします。

```swift
extension UIFont {
  public enum FontType: String, CaseIterable {
    // フォントへのパス
    case CustomFont = "fonts/0e12b13c359d4803021dc4e17cecc311.woff2"
  
    var fontDescriptor: UIFontDescriptor {
      guard let documentURL: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
            let array: CFArray = CTFontManagerCreateFontDescriptorsFromURL(documentURL.appendingPathComponent(rawValue) as CFURL),
            let fonts: [CTFontDescriptor] = array as? [CTFontDescriptor],
            let font: CTFontDescriptor = fonts.first
      else {
          // フォントがなければデフォルトのフォントを利用する
          return .init()
      }
      return font as UIFontDescriptor
  }

  static let CustomFont: UIFontDescriptor = {
    FontType.CustomFont.fontDescriptor
  }()
}
```

このような感じで`static let`として定義すれば最初の一回以外は処理が走らずにその値が返ってくるのでパフォーマンスがかなり改善されます。

## 応用

この仕様を利用して、SwiftUIでスプラトゥーンのフォントを権利問題をクリアした上で利用できるライブラリを作成しました。

スプラトゥーンのフォントはウェブ上で公開されているので、それをダウンロードすること自体には問題がありません。