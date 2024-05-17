---
title: SwiftUIでループ途中の経過を返す方法
published: 2021-09-13
description: SwiftUIで作業の進行具合を返す方法を考えてみました
category: Programming
tags: [Swift, SwiftUI]
---

# 処理の途中で値を返す

さて、見出しからして若干意味不明な感じがしないでもない。

というのも、プログラミングにおいて処理の途中で値を返すことになんの意味もないからである。例えば、1 から与えられた任意の数までの和を求めるコードを愚直に書いたとして、与えられた数が 100 なら結果は 5050 になるのだが、10 まで足したときの値 55 を返してもなんの意味もないからである。

受け取る側としては「55 が返ってきたけど、それがどうした」となるわけである。

しかし、これはこのプログラムが非常に高速に動作するためにそのような違和感をおぼえるのであって、もっともっと長い時間がかかるプログラムとなると話は別である。

## 処理が重いコード

さっきのコードであればどんなに大きい数字が与えられてもビットシフト一回（二で割る処理である）と足し算一回と掛け算一回で結果が得られる。ビットシフトは一クロックあればできるし、足し算一回も非常に高速に求められる。唯一時間がかかるのは掛け算の処理だが高々一回しか行わないので、このプログラム自体は軽い。

つまり、結果を待っているという時間が存在しない。

では、もっと時間がかかるコードだとどうだろう？例えばコンテンツ ID を指定するとその ID の画像またはテキストをを逐次ダウンロードするようなものである。

```swift
func getDownloadContents(contentId: Int) -> () {
    // ダウンロード処理
}
```

この際、コードの内容はどうでも良いのだが上のようにコンテンツ ID を指定してその中身をダウンロードするような処理だと考えよう。

返り値は処理成功の`Result`型でも良いし、単に`Bool`型でも良い。なんならコンテンツ自体を返してもよい（そんなことはめったに無いだろうが）。ここで問題となるのはこのコード自体は外から見れば「コンテンツの大きさもわからない」し「どこまで処理が進んでいるかもわからない」ということである。

つまり、プログレスバーで進捗を表現することができず、処理が終わるまで延々と`ProgressView`のようなものをくるくる回し続けるだけになる。

これではユーザが「あとどのくらい待てばよいか」すらもわからないのである。

### プログレスバーに対応する

とはいえ、自作のコードであれば対応するのは難しくない。

```swift
@State var currentValue: Int = 0
@State var maxValue: Int = 0

func getDownloadContents(contentId: Int) -> () {
    maxValue = 100
    // ダウンロード処理
    for content in contents {
        currentValue += 1
    }
}
```

たとえあ上のように View 自体が`@State`として変数をもっておき、ループ前とループ中に値を更新すれば View が再レンダリングされるため、ユーザからは全部でダウンロードするコンテンツがいくつあるのか、どのくらい進んでいるのかがわかる。

ただし、これにはいろいろとデメリットがある。

- `getDownloadContents()`が`@State`にアクセス可能である必要がある
- ループ内でいちいち処理を書かなければいけない

1 に関しては実装の目的次第では気にならないのだが、2 に関しては割と気になってしまう。

というのも、この関数はただ単にコンテンツをダウンロードすべき処理を実行すべきで、UI 部分である View の更新とは切り離して考えるべきだからだ。

このままだと UI か処理かのどちらかの仕様を変えると`getDownloadContents`自体を書き換えないといけなくなってしまう。

### ライブラリから利用する場合

先程の例でいうと、ループをする関数が常に`@State`にアクセスできないとプログレスバーを実装できない。

全部自分で書いたコードであればそれでいいが、ライブラリ化するような場合には問題が発生する。何故ならライブラリは View 側がどのようなプロパティを持っているかを全く考慮しないからである。

つまり、メソッド側から UI を更新するためのプロパティ（変数）を更新するのは無理であり、処理が終わったまたはある程度進んだという進捗具合をメソッド側が値を返すのが正しい仕様になる。

しかしながら、処理の途中で値を返すようなそんな実装方法はない。`return`をすればそれはメソッド自体を抜けてしまうし、`completion`にしても一回しか送ることができない。

ではどうすればよいかということで、考えてみた。

## [NotificationCenter](https://developer.apple.com/documentation/foundation/notificationcenter)

`NotificationCenter`とはその名の通り通知を司る iOS 標準のコンポーネントである。SNS のアプリなどでメッセージを受け取ったときにバイブレーションやサウンドで受け取ったことが「通知」されると思うが、あれはこの機能を利用している。

今回の件とは関係ないかのように思えるが、あれは「通知」の機能の一つであり、根本的にはもっと低レベルな処理を行うことができる。

### デバイスの回転

例えば、SwiftUI でデバイスが回転したときに何らかの処理を実行したいというケースを考えよう。

これはゴリゴリと自分で実装してもよいのだが、実はもっと効率的なコーディングができる。

というのも、デバイスは回転すると`UIDevice.orientationDidChangeNotification`という通知が自動的に`post`されています。この通知を受け取るような設定にしておけばアプリ側は全く何もコードを書かなくても「デバイスが回転した」という情報を知ることができるのです。

通知の受け方は ViewController の場合と SwiftUI の場合とで少し異なりますが、やっていることはほとんど同じです。

```swift
// ViewController
NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)

@objc func orientationChanged() {
    // 処理
}

// SwiftUI
.onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification), perform: { value in
    // 処理
})
```

## SwiftUI で独自通知を実装

### NotificationCenter

執筆にあたり[【Swift】NotificationCenter の使い方](https://qiita.com/ryo-ta/items/2b142361996657463e5f)の記事が大変参考になりました。

まずは以下のように`Notification.Name`を拡張して独自の通知を定義します。

```swift
extension Notification.Name {
    static let notify = Notification.Name("notify")
}
```

### 通知を送る

通知を送る側は以下のコードを書くだけです。

```swift
NotificationCenter.default.post(name: .notify, object: nil)
```

### 通知を受け取る

SwiftUI で受け取るには以下のコードを書きます。

```swift
.onReceive(NotificationCenter.default.publisher(for: .notify), perform: { _ in
    // 処理
})
```

## SwiftUI 版のコード

簡単に実装したいだけであれば以下のように書くことができます。

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Button(action: {
            // 通知の発行
            NotificationCenter.default.post(name: .notify, object: nil)
        }, label: {
            Text("POST")
        })
        .onReceive(NotificationCenter.default.publisher(for: .notify), perform: { _ in
            // 通知の受け取り
            print("RECEIVE")
        })
    }
}

extension Notification.Name {
    static let notify = Notification.Name("notify")
}
```

これだけでボタンを押せば通知が発行されて、それを`onReceive`で受け取るプログラムが書けます。

### 更に拡張する

今回はイカリング 2 へのログインの進捗具合を返すような`Notification`を考えてみます。

```swift
class SplatNet2 {
    init() {}
}

extension SplatNet2 {
    public static let signIn: Notification.Name = Notification.Name("SPLATNET2_SIGNIN")

    public enum SignInState: Int, CaseIterable {
        case sessiontoken       = 0
        case accesstoken        = 1
        case flapgnso           = 2
        case splatoontoken      = 3
        case flapgapp           = 4
        case splatoonacesstoken = 5
        case iksmsession        = 6
    }
}
```

どこまでログインが進んだかは`SignInState`を返して通知するという仕組みです。

#### Object

どの状態までログインが進んだかは、

```swift
public static let signInA: Notification.Name = Notification.Name("SPLATNET2_SIGNIN_A")
public static let signInB: Notification.Name = Notification.Name("SPLATNET2_SIGNIN_B")
public static let signInC: Notification.Name = Notification.Name("SPLATNET2_SIGNIN_C")
```

のように書くこともできるのですが、その分だけ`onReceive`を書かなくてはいけず冗長なコードになってしまいます。

そこで、どこまでログインが進んだかを定義した Enum である`SignInState`を用意します。このとき、型付き Enum でないとオブジェクトにならないので利用できないことに注意します。

`NotificationCenter`は通知の際に`NotificationCenter.default.post(name: .notify, object: nil)`としてオブジェクトを指定することができます。

::: warning Object がダサい

Object が通知できるのは良いのだが、型が指定されておらず`Any?`になっているため受け取る側で何が送られてきたかをチェックしないといけない。

:::

#### userInfo

`Object`とは別に`userInfo`も送信することができます。こちらは辞書型しか対応していません...

なので結局便利に値を送ることはできず、

```swift
NotificationCenter.default.post(name: .notify, object: nil, userInfo: ["username": "tkgling"])
```

として POST したとすると、

```swift
.onReceive(NotificationCenter.default.publisher(for: .notify), perform: { value in
    print(value) // name = notify, object = nil, userInfo = Optional([AnyHashable("username"): "tkgling"])
})
```

というデータを受け取ります。なので、実際の中身を確認するには、

```swift
.onReceive(NotificationCenter.default.publisher(for: SplatNet2.signIn), perform: { value in
    if let userInfo = value.userInfo {
        if let username = userInfo["username"] as? String {
            print(username) // tkgling
        }
    }
})
```

としなければいけません。しかも、これは`userInfo`にどんなキーが含まれているか事前にわかっている必要があります。

本来、どんな値が入っているかはわからないはずなのでこれでは困ってしまいます。

::: tip Codable

Codable を使えば構造体から辞書に変換するのは楽そうだが、結局もとに戻すのがめんどくさかったりどんな構造体を変換したものが送られてきているのかがわからないので意味がない。

:::

### 解決策

- Any?を許容する
  - 自作ライブラリなら中身はわかっているので頑張って対応する
  - エラー落ちさえしなければいいので
- UserInfo の奇妙な仕様を許容する
  - 同文
- [`assign`](<https://developer.apple.com/documentation/combine/just/assign(to:on:)>)を利用する
  - [サンプルコード](https://github.com/russell-archer/SwiftUI-Combine-NotificationDemo)が載っているのでこれを読んでみるといいかも
  - ObservableObject の宣言が余計に必要なのがめんどくさいが...
