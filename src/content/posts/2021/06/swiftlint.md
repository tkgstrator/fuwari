---
title: SwiftLintでコーディング規約に準拠しよう
published: 2021-06-22
description: SwiftLintでプロジェクトのコードを修正していく手順について解説
category: Programming
tags: [Xcode]
---

# [SwiftLint](https://github.com/realm/SwiftLint)

SwiftLint とは realm が開発した GitHub Swift Style Guide に準拠するようにコードを分析して警告やエラーをだしてくれる解析ツールのこと。

割と使う人が多いらしいのだが、個人的にはあんまり好きではない。

が、使うとなったときに設定方法がいまいちわからなかったので設定可能なルールやその内容を解説していく。

## インストール

公式では CocoaPods でのインストール方法が推奨されているが、特に理由がないなら brew を使ってローカルにインストールしてしまうほうが良いと思う。

### CocoaPods

```
pod 'SwiftLint'
```

### Mint

```
mint install realm/SwiftLint
```

### Homebrew

```
brew install swiftlint
```

### Build

ソースコードから直接ビルドする方法もある。この場合、Xcode12 以上が要求されるので注意。

### PKG

公式レポジトリで PKG(`SwiftLint.pkg`)が[配布](https://github.com/realm/SwiftLint/releases/tag/0.43.1)されているのでそれをインストールしてしまっても良い。

## 設定方法

Xcode を開いてプロジェクトを選択したら`Build Phases`を選び、左上の`+`を押して`New Run Script Phase`を作成。

このとき、SwiftLint のインストール方法によって書くコマンドが変わってくるので注意しよう。

```sh
# Mint以外
# Type a script or drag a script file from your workspace to insert its path.
if which swiftlint >/dev/null; then
  swiftlint autocorret --format
  swiftlint
else
  echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
```

```sh
# Mint
# Type a script or drag a script file from your workspace to insert its path.
if which mint >/dev/null; then
  mint run swiftlint swiftlint autocorrect --format
  mint run swiftlint swiftlint
else
  echo "warning: Mint not installed, download from https://github.com/yonaskolb/Mint"
fi
```

## ルール一覧

全部まとめてるとそれだけで時間を無限に消費してしまうので詳しくは[ドキュメント](https://realm.github.io/SwiftLint/rule-directory.html)をみてください。

自分がよく遭遇する警告・エラーについては以下の通り。

### Comma Spacing

カンマは前にスペースがあってはダメで、後ろに一つだけつけるべきだというルール。

```swift
// Good
func abc(a: String, b: String) { }

// Bad
func abc(a: String ,b: String) { }
```

### Colon Spacing

コロンの後にはスペースを一つあけるべきだというルール。

```swift
//Good
let abc: Void

// Bad
let abc:Void
```

### Identifier Name

命名する場合には小文字から始まるか、全て大文字であるべきだというルール。例外として変数名で static 変数か定数の場合は大文字から始まっても良い。また、変数名は短すぎても長すぎてもいけない。

```swift
// Good
let myLet = 0

var myVar = 0

let URL: URL? = nil

// Bad
let MyLet = 0   // 大文字から始まってはいけない

let _myLet = 0  // _から始まってはいけない

var id  = 0     // 短すぎる
```

### Legacy Random

古い擬似乱数生成関数を使うべきではない。

```swift
// Good
Int.random(in: 0..<10)

Double.random(in: 8.6...111.34)

Float.random(in: 0 ..< 1)

// Bad
arc4random(10)

arc4random_uniform(83)

drand48(52)
```

### Type Name

型名は英数字のみで戦闘は大文字、長さは 3-40 の範囲にするべき。

::: tip Type Name について

型名というのはクラス名や構造体名、Enum 名、プロトコル名などが該当する。

また、忘れやすいが`typealias`も Type Name 扱いなので覚えておきたい。

:::

```swift
// Good
class MyType {}

private class _MyType {}

// Bad
class myType {}	    // 小文字から始まってはいけない

class _MyType {}    // _から始まってはいけない
```

### Force Try

`try!`は避けるべきだというルール。

::: tip `try!`について

`try?`と`try!`はどちらもエラーが発生した場合に無視するという点は同じだが、`try!`が即座にクラッシュするのに対して`try?`は`nil`を返してクラッシュしないという違いがある。

返り値を返すタイプの関数に対して`try?`を使うのは当然`nil`に対する処理があるはずなのでバグは発生しない可能性が高い。だが、返り値を返さないタイプの場合は、そこで本来はデータが書き込まれたりしているはずなのにエラーが発生した場合は`try?`の場合はデータが書き込まれずその後の処理でエラーが発生する場合がある。

:::

### Line Length

一行は 120 文字以内にすべきだというルール。120 文字以上だと警告がでて、200 文字以上だとエラーがでます。

## SwiftLint を使わない理由

いろいろ便利そうな SwiftLint なのだが、それを使わない理由もまたあります。

### 静的解析しかできない

一番の問題がこれで、静的解析しかできないのでビルドするまでエラーがでるかどうかわからないというのがあります。

Xcode のデフォルトだとコンパイラが自動でエラー吐いてくれるのでそれと比べると見劣りしてしまいます。

### 自動修正がない

次に、エラーは出すが具体的にどう修正していいかわからないという問題があります。

まあエラーコード読めばわかるんですけど、`id`とか`key`とかが使えないとちょっと不便なんですよね。

### Swift Package Manager に使えない

これも困る問題の一つで、Swift Package Manager では`New Run Script Phase`が使えないので必然的に SwiftLint も動作しません。

同梱したデモアプリなどのプロジェクトから SwiftLint を動かせば動作はするのですが、ちょっとめんどくさいんですよね。

<div class="vuepress-affiliate">
<img src="https://m.media-amazon.com/images/I/51oNaYCeAIL._SL500_.jpg" />
<ul>
<li><a href="https://www.amazon.co.jp/dp/B079YD4FJ1/?tag=tkgstrator0f-22" target="_blank">【食品添加物】ハッカ油P 20ml(アロマ・お風呂・虫よけ)</a></li>
<li class="price">￥409 (￥20 / ミリリットル)</li>
</ul>
</div>
