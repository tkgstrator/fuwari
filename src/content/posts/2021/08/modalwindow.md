---
title: SwiftUIでModalWindowをカスタマイズする話
published: 2021-08-13
description: SwiftUIのモーダルは二種類しかないのですが、変更することはできるかどうかを解説
category: Programming
tags: [SwiftUI, Swift]
---

# ModalWindow

ModalWindow とは通称モーダルと言われ、メインのウィンドウとは別に画面にホバーしてくるウィンドウのこと。

どういうものなのかは見ていただいたほうが早いので GIF 動画を載せておきます。

## SwiftUI での二つの実装方法

SwiftUI のデフォルトでは`sheet`と`fullScreenCover`が使えます。このうち、`fullScreenCover`は iOS14 以降でないと使えないのでそれだけ気をつけてください。



### Sheet

```swift
struct ContentView: View {
    @State var isPresented: Bool = false

    var body: some View {
        Button(action: { isPresented.toggle() }, label: { Text("Open") })
            .sheet(isPresented: $isPresented) {
                Text("Hello, World")
            }
    }
}
```

### FullScreenCover

```swift
struct ContentView: View {
    @State var isPresented: Bool = false

    var body: some View {
        Button(action: { isPresented.toggle() }, label: { Text("Open") })
            .fullScreenCover(isPresented: $isPresented) {
                Text("Hello, World")
            }
    }
}
```

## Modal 表示時のアニメーション

ModalWindow のアニメーションには次の 4 つがあります。

|                |    見た目    | SwiftUI | UIKit |
| :------------: | :----------: | :-----: | :---: |
| CoverVertical  |  下から表示  |   OK    |  OK   |
| CrossDissolve  | フェードイン |    -    |  OK   |
| FlipHorizontal |   フリップ   |    -    |  OK   |
|  PartialCurl   | ページめくり |    -    |  OK   |

このうち、SwiftUI でデフォルト実装されているのは`CoverVertical`だけで、それ以外は利用できません。

それぞれどんなアニメーションなのかを紹介します。ただ、`PartialCurl`はフルスクリーンでないと利用できないので今回作成したライブラリには含めていません。

### CoverVertical

![](https://github.com/tkgstrator/SwiftyUI/raw/master/Docs/GIF/01.gif)

下から出現する SwiftUI デフォルトのアニメーションです。

### CrossDissolve

![](https://github.com/tkgstrator/SwiftyUI/raw/master/Docs/GIF/03.gif)

浮かび上がるようなアニメーションです。

### FlipHorizontal

![](https://github.com/tkgstrator/SwiftyUI/raw/master/Docs/GIF/02.gif)

扉が開くようなアニメーションです。

### PartialCurl

元のビューが FullScreen で表示されていないとクラッシュします。



## Modal 表示スタイル

アニメーションとは別に、表示スタイルを切り替えることができます。

### automatic

> The default presentation style chosen by the system.

![](https://pbs.twimg.com/media/E8rXnVDVIAcr-sz?format=jpg&name=large)

SwiftUI のデフォルトの`sheet`と同じに見えます。

### none

> A presentation style that indicates no adaptations should be made.

クラッシュします。

### fullScreen

> A presentation style in which the presented view covers the screen.

![](https://pbs.twimg.com/media/E8rXnVDVcAIpSb1?format=jpg&name=large)

SwiftUI のデフォルトの`fullScreenCover`と同じです。

### pageSheet

> A presentation style that partially covers the underlying content.

![](https://pbs.twimg.com/media/E8rXnVDVIAcr-sz?format=jpg&name=large)

SwiftUI のデフォルトの`sheet`と同じです。

### formSheet

> A presentation style that displays the content centered in the screen.

![](https://pbs.twimg.com/media/E8rXnVHVcAMKbVW?format=jpg&name=large)

自由にサイズを選べる便利なモードです。何もしなければ 540x620 で表示されます。

### currentContext

> A presentation style where the content is displayed over another view controller’s content.

ModalWindow を呼び出したビューの上に表示します。

が、バグが多そうなので今回は利用していません。

### custom

> A custom view presentation style that is managed by a custom presentation controller and one or more custom animator objects.

いろいろいじれそうなのですが、弄り方がわからなかったので割愛。

### overFullScreen

> A view presentation style in which the presented view covers the screen.

ただの`FullScreen`との違いがわからなかったので割愛。

### overCurerntContext

> A presentation style where the content is displayed over another view controller’s content.

ただの`currentContext`との違いがわからなかったので割愛。

### popover

> A presentation style where the content is displayed in a popover view.

これを利用するにはいろいろ別のパラメータ設定が必要なので、ライブラリでは使えないようにしてあります。

## [SwiftyUI](https://github.com/tkgstrator/SwiftyUI)

```swift
struct ContentView: View {
    @State var isPresented: Bool = false

    var body: some View {
        Button(action: { isPresented.toggle() }, label: { Text("Open") })
            .present(isPresented: $isPresented, transitionStyle: .coverVertical, presentationStyle: .pageSheet, isModalInPresentation: false)
    }
}
```

このモーダルの使い方は`sheet`や`fullScreenCover`とほとんど同じです。与えるパラメータは`transitionStyle`, `presentationStyle`, `isModalInPresentation`, `contentSize`の四つです。

`contentSize`は`presentationStyle`が`formSheet`の場合でしか効かないので、設定すると強制的に`formSheet`になるようにしてあります。

`isModalInPresentation`は有効化すると画面外タッチやモーダルを下に引っ張って消すことができなくなります(iOS12 までのスタイルになります)

ユーザビリティ的には違和感があると思うので、誤タッチ等で消されたくない場合を除いて`false`(デフォルト値)で良いと思います。

記事は以上。


