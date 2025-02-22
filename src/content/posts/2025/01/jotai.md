---
title: Recoilに代わるJotaiの使い方が何もわからん
published: 2025-01-25
description: Reactにおける状態管理がわかりません
category: Programming
tags: [Vite, React, Jotai]
---

## 背景

TypeScript + React + Viteでウェブアプリを作っているのですが、管理クラスのようなものが必要になりました。

```ts
class Application {
  readonly version: string
  private _theme: 'dark' | 'light'

  get theme(): 'dark' | 'light' {
    return this._theme
  }

  changeTheme = () => {
    this._theme = this._theme === 'dark' ? 'light' : 'dark'
  }
}
```

上は大雑把な感じですが、こういうのを作ったときに`Application`のクラスの何かの要素が変化したときにコンポーネントの再レンダリングをして欲しいわけです。

ところがクラスは参照渡ししかしない上にクラスのプロパティが変化してもReactはクラスのインスタンスが変化したとは検知してくれません。

よって、これは`changeTheme`を呼び出して`this._theme`を変更しても`Application`クラスのインスタンスが変わったと認識してくれないので表示は全く変わりません。

これが困るのでなんとかしたいというわけですね。

### SwiftUIの場合

SwiftUIもReactと同じように宣言型のフレームワークなので同様の問題がありました。

| フレームワーク | 状態管理 | クラス管理  |
| :------------: | :------: | :---------: |
| SwiftUI        | @State   | @Observable |
| React          | useState | -           |
| Jotai          | atom     | -           |

ところがSwiftUIの場合にはクラス自体に`@Observable`を宣言して、プロパティの変化をチェックしたい場合に`@Published`をつけることでクラスのプロパティが変化したことをSwiftUIのフレームワークに通知する仕組みがありました。

ところがReactにはデフォルトでその機能はないようで、この時点で結構困ります。

ログインフォームくらいであればユーザー名とパスワードを管理すればいいだけなので`@State`や`useState`で十分なのですがアプリの設定などであればたくさんのプロパティが必要なので、それらを必要とするコンポーネントで何回も呼び出していると流石にめんどくさいです。

また、クラスの場合にはプロパティAとプロパティBが密結合になっている場合があるので、別の`State`で管理すると表示上の非同期を招きかねません。

> SwiftUIの場合にはより単純なクラスの状態管理として`@Observation`もあったりします

#### @Observableの欠点

じゃあSwiftUIの`@Observable`は便利なのかというとそうではない一面もあります。

というのも、クラス自体を`@Observable`として宣言しないといけないので、外部のライブラリが使っているクラスはラッパーを作るなり拡張クラスを作らないと`Observable`に対応させることができません。この時点で結構めんどくさいです。

まあSwiftUIの愚痴はどうでもいいです、ぶっちゃけそんなに困っていません。困っているのはReactです。

### Jotaiを理解せよ
