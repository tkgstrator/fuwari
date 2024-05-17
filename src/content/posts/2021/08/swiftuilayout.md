---
title: SwiftUIでレイアウトを切り替える方法
published: 2021-08-19
description: SwiftUIでデバイスや傾きごとにレイアウトを変更したい場合のコーディングについて学びます
category: Programming
tags: [Swift, SwiftUI]
---

# SwiftUI でのレイアウト

デバイスごとのレイアウトというのは非常に面倒なもので、最近はどちらもで対応できるユニバーサルなデザインも流行っているのではあるが、やはりそれぞれのポテンシャルを最大限に活かすためにはそれぞれに最適なレイアウト・UI を提供すべきだと考えます。

となれば実行しているデバイス・デバイスの傾きで UI を変更する必要があります。

それをどうやったら実現できるかについて考えてみました。

## シミュレータと実機

シミュレータと実機の区別は以下のコマンドが使えます。

```swift
#if targetEnvironment(simulator)
    // Simulator
#else
    // Device
#endif
```

じゃあ`#if targetEnvironment(iPhone)`みたいなのがないのかという話になるのですが、残念ながらありません。

### iPhone と iPad

では iPhone と iPad はどうやって区別するかということなのですが、一つの方法として`UIDevice.current.userInterfaceIdiom`を使うものがあります。

|     Enum     |        意味        |
| :----------: | :----------------: |
|    .phone    | iPhone, iPod Touch |
|     .pad     |        iPad        |
|     .tv      |      Apple TV      |
|   .carPlay   |      CarPlay       |
|     .mac     |       macOS        |
| .unspecified |      それ以外      |

これは`UIUserInterfaceIdiom`という Enum を返し、それぞれ上記の表のような種類があります。

### デバイスの向き

デバイスにはそれぞれ Landscape と Portrait という二つのモードがあります。iPhone と iPad にそれぞれあるので全部で四種類の UI を用意しなければいけないわけです。

ただ、iPhone の Landscape は実装されていないアプリも多いです。Landscape に特化した(例えば動画視聴アプリのようなものを除けば)実際には三種類用意すれば十分と言えるでしょう。

となれば実装すべき組み合わせは以下の通りとなります。

|           |  .phone  |   .pad   |
| :-------: | :------: | :------: |
| portrait  |    -     | Required |
| randscape | Required | Required |

では次に傾きを調べる方法なのですが、`UIDevice.current.orientation`というのがあるのですがこれは利用できないので注意しましょう。

というのも、`UIDevice.current.orientation`はアプリが起動してから傾きが変化するまでの間に意味不明な値が代入されているからです。

なので`UIApplication.shared.windows.first?.windowScene?.interfaceOrientation`を代わりに使うようにしてください。

## View を表示してみる

というわけで、切り替えられるように以下のようなコードを書いたとしましょう。

これは一見するとちゃんと動きそうなのですが、実際には動きません。何故でしょうか？

```swift
struct ContentView: View {

  var body: some View {
    // デバイスと傾きでビューを切り替える
    switch (UIDevice.current.userInterfaceIdiom, UIApplication.shared.windows.first?.windowScene?.interfaceOrientation) {
      case (.pad, .landscapeLeft), (.pad, .landscapeRight):
        padLandscapeView
      case (.pad, .portrait):
        padPortraitView
      default:
        phoneView
    }
  }
}
```

というのも SwiftUI の再レンダリングをするには変数を`State`にする必要があるからです。`UIDevice.current.userInterfaceIdiom`も`UIApplication.shared.windows.first?.windowScene?.interfaceOrientation`も`@State`のプロパティラッパー指定がないためここの値が変わってもビューの再レンダリングが行われないというわけです。

### 通知を受け取れるようにする

これを解決するためには傾き等の情報が更新されたときに SwiftUI が検知できるように`@State`をつければ良いことになります。

ただし、それをいろいろビューで宣言するとややこしくなるだけなので`@ObservableObject`の仕組みを利用しましょう。

`@ObservableObject`は簡単に言うと`@State`をクラス化したものです。似たようなものに`@StateObject`があるのでややこしいですが、ちょっと違います。

### @StateObject と@ObservableObject の違い
