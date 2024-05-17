---
title: アプリがインストールされているかをチェックする方法
published: 2024-04-30
description: iOSで別のアプリと連携するような際に必要になるので調べてみました 
category: Programming
tags: [Swift, Xcode]
---

## 概要

あるアプリXが別のアプリYと連携することを目的とした場合、Yが既にインストールされているかをチェックする必要があります。

XとYの開発者が同じであればApp Groupsなどを使って解決できる可能性がありますが、サードパーティのアプリの場合そのような連携は期待できません。

ということで別の手段でYが既にインストールされているかどうかをチェックする必要があります。

> [特定のアプリがインストール済みかチェックする](https://qiita.com/star__hoshi/items/f3daa809b36b5f91d653)

### canOpenURL()

Swiftには`canOpenURL`というメソッドがあり、これを使えばそのURLが開けるかどうかを確認することができます。

ここで注意しなければならないのは`canOpenURL`は単に与えられたURLについてチェックするだけで遷移先のURLがステータス200を返すかどうかは一切考慮しません。

なのでHTTPやHTTPSのURLを渡せばそれがURLに変換できる文字列である限り(そうでない場合はURLのイニシャライザが`nil`を返します)`canOpenURL`は常に`true`を返します。

> [iOS14でcanOpenURLがfalseになる](https://qiita.com/tsuruken/items/58d1a5827262e629b03d)iOS14からは返さなくなったようだ

よって、ここで渡すべきはURLスキーマであるということです。

> [canOpenURL](https://developer.apple.com/documentation/uikit/uiapplication/1622952-canopenurl)

### Nintendo Switch Online

例えばNintendo Switch Onlineが既にインストールされているかを調べたいとしましょう。

このとき、もしもNintendo Switch OnlineがURLスキーマを持っていなければチェックすることはできません。

URLスキーマはURL TypesとしてInfo.plistに書き込まれているので、アプリのバンドルを復号してInfo.plistの中身を見ればどのようなスキーマが定義されているかチェックすることができます。

すると`npf71b963c1b7b6d119`と`com.nintendo.znca`の二つが定義されていることがわかります。

前者はWebViewからアカウント連携をするために必要ですので、今回のケースではこちらは利用できません。

よって後者を利用して、

```swift
if canOpenURL(URL(string: "com.nintendo.znca://")!) { 
}
```

とでも書けばアプリが存在するかどうかのチェックができそうです。

ところが、実はこれだけではアプリが存在するかどうかのチェックはできません。

何故ならXのアプリが`com.nintendo.znca`を正しくURLスキーマとして認識できないからです(ここで引っかかっていた

よって、現時点でこのメソッドは常に`false`を返します。

なのでXのInfo.plistに`com.nintendo.znca`がURLスキーマであるということを書き込む必要があるのですが、ここで誤って`URL Types`に書いてしまうとXのアプリ自身にURLスキーマの定義が書き込まれてしまうので`canOpneURL`は常に`true`を返すようになり更に`openURL`を実行すると自分自身が開いてしまいます。

ここで想定しているような動作を実現するためには`LSApplicationQueriesSchemes`を利用する必要があります。

## まとめ

| X                           | Y                | canOpenURL | openURL    | 
| :-------------------------: | :--------------: | :--------: | :--------: | 
| なし                        | 未インストール   | false      | 動作しない | 
| なし                        | インストール済み | false      | Yが開く    | 
| URL Types                   | 未インストール   | true       | Xが開く    | 
| URL Types                   | インストール済み | true       | Xが開く    | 
| LSApplicationQueriesSchemes | 未インストール   | false      | 動作しない | 
| LSApplicationQueriesSchemes | インストール済み | true       | Yが開く    | 

これを利用すればURLスキーマとして認識できるようになり、開けるかどうかが正しく返るようになります。

また、YがインストールされていればXではなくYを開くことができます。

### 備忘録

URLスキーマとして開くこともできるが、[バンドルIDを利用して](https://github.com/kishikawakatsumi/AUCapture/blob/30831a882703798078058df3c00b80cf8650f0b0/AUCapture/ViewController.swift#L152)開くこともできるらしい。

```swift
@discardableResult
private func launchApp(with bundleIdentifier: String) -> Bool {
    guard let obj = objc_getClass(["Workspace", "Application", "LS"].reversed().joined()) as? NSObject else { return false }
    let workspace = obj.perform(Selector((["Workspace", "default"].reversed().joined())))?.takeUnretainedValue() as? NSObject
    return workspace?.perform(Selector(([":", "ID", "Bundle", "With", "Application", "open"].reversed().joined())), with: bundleIdentifier) != nil
}
```

記事は以上。