---
title: SwiftUIでのモーダル表示はおとなしく公式を使うのが無難である件について
published: 2023-03-27
description: SwiftUIでモーダル表示をしたい場合、候補がsheetかfullScreenCoverしかありませんがこれらを使うのが無難であることの解説をします
category: Programming
tags: [Swift, SwiftUI]
---

## SwiftUI でのモーダル表示

さて、当ブログでは今まで SwiftUI でモーダル表示を実行する場合の方法について色々解説してきました。

で、よくある方法として`UIViewControllerRepresentable`を使ってサイズが 0 の View でオーバーレイするみたいな記事があったりなかったりするのですが、結論として言えばこれはバグを生みやすいので避けたほうが良いという結論です。

### よくあるバグ

- 表示されていないにも関わらず初期化される
- `Binding`の値が切り替わったことが正しく検知されない

概ねここです。初期化されることについては`.overlay`している以上致し方ないのですが、`Binding`の値が切り替わったことが正しく検知されないのは困ります。

例えば、画面を回転させると`isPresented`の値が変わったと判定されて実装方法によっては勝手にモーダルが閉じてしまいます。

なので結局公式が提供している`fullScreenCover`や`sheet`を使うのが無難であるということになります。

では、何故そもそもこれらの公式のモディファイアを使わずに自作しようとしていたのかという話になるわけです。

## 自作モディファイアが求められた理由

個人的に自作モディファイアが求められたのは以下の理由によります。

### UIModalPresentationStyle で利用できないものがある

| UIModalPresentationStyle |     SwiftUI      |
| :----------------------: | :--------------: |
|       .fullScreen        | .fullScreenCover |
|        .pageSheet        |      .sheet      |
|        .formSheet        |        -         |
|     .currentContext      |        -         |
|     .overFullScreen      |        -         |
|   .overCurrentContext    |        -         |

UIKit では提供されている六つのスタイルのうち、たった二つしか SwiftUI では利用できません。

### UIModalTransitionStyle で利用できないものがある

| UIModalTransitionStyle | SwiftUI |
| :--------------------: | :-----: |
|     .coverVertical     |   OK    |
|     .crossDissolve     |    -    |
|    .flipHorizontal     |    -    |
|      partialCurl       |    -    |

SwiftUI では`coverVertical`しかサポートされておらず、変更もできません。

## デモアプリ

SwiftUI の標準機能だけでモーダルとフルスクリーンを実装すると以下のような感じになります。

モーダルは引っ張って閉じることができるので`dismiss`は不要ですが、フルスクリーンは閉じることができないので`dismiss`を実装しておく必要があります。

```swift
import SwiftUI

/// コンテンツビュー
struct ContentView: View {
    var body: some View {
        List(content: {
            SheetButton()
            FullScreenButton()
        })
    }
}

/// モーダル表示用のボタン
struct SheetButton: View {
    @State private var isPresented: Bool = false

    var body: some View {
        Button(action: {
            isPresented.toggle()
        }, label: {
            Text("Sheet")
        })
        .sheet(isPresented: $isPresented, content: {
            ModalView()
        })
    }
}

/// フルスクリーン表示用のボタン
struct FullScreenButton: View {
    @State private var isPresented: Bool = false

    var body: some View {
        Button(action: {
            isPresented.toggle()
        }, label: {
            Text("FullScreen")
        })
        .fullScreenCover(isPresented: $isPresented, content: {
            ModalView()
        })
    }
}

/// 表示されるモーダル
struct ModalView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        GroupBox(content: {
            Button(action: {
                dismiss()
            }, label: {
                Text("Close")
            })
        })
    }
}
```

### Introspect を利用する

SwiftUI の裏側で動いている UIKit を直接弄ることができる Introspect というライブラリを使って標準機能のモーダルとフルスクリーンをカスタマイズできます。

|        プロパティ        |         意味         |  変更  |
| :----------------------: | :------------------: | :----: |
| UIModalPresentationStyle |       表示方法       |  不可  |
|  UIModalTransitionStyle  |       表示方法       | 一部可 |
|  isModalInPresentation   | 閉じることができるか |   可   |
|     backgroundColor      |        背景色        |   可   |

手元で少しいじってみたところ、いくつかのプロパティについては変更することができました。

標準機能ではない「シートを閉じることができないようにする」という機能が簡単に実装できたのは大きな成果だったように思います。

モーダルやフルスクリーンを表示するという機能は、内部的には SwiftUI の View を`UIHostingController`を使って UIKit のコンポーネントとして利用しているので、`Introspect`を使って`UIHostingController`にさえアクセスできればこれらをカスタマイズすることができます。

```swift
import SwiftUI
import Introspect

/// モーダル表示用のボタン
struct SheetButton: View {
    @State private var isPresented: Bool = false

    var body: some View {
        Button(action: {
            isPresented.toggle()
        }, label: {
            Text("Sheet")
        })
        .sheet(isPresented: $isPresented, content: {
            ModalView()
              .introspectViewController(customize: { controller in
                    /// UIHostingController
                    /// 引っ張って閉じれないようにする
                    controller.isModalInPresentation = true
                    /// 背景色を透明にする
                    controller.view.backgroundColor = .clear
                })
        })
    }
}
```

上のようにコードを書けば`UIHostingController`が`controller`として読み込まれるので、これに対してカスタマイズを行うことで色々と弄ることができます。

> fullScreenCover の場合も全く同じコードで実装できます

この方法の良いところは SwiftUI の裏で UIHostingController として UIKit が動いているという仕組みがアップデートで変わらない限り使えるというところ。UIKit のプロパティをいじっているだけなので安全であるというところ。更に SwiftUI の公式のモディファイアである sheet と fullScreenCover を使っているのでバグが発生しにくいというところです。

### 一部の効かないプロパティについて

ただ、この方法の最大の欠点は`Introspect`を使って`UIHostingController`にアクセスできるのが`UIHostingController`が`present`されたタイミングである、ということです。

既に表示されかかっているので今更`UIModalPresentationStyle`や`UIModalTransitionStyle`を変更しても間に合っていない。

となれば`UIHostingController`のメソッドを`override`するかということになるのですが、やろうとすると Objective-C のプロパティが含まれているとかでオーバーライドできない。継承クラスは使えるのだが`sheet`や`fullScreenCover`は`UIHostingController`を内部的に使っているので継承クラスを作ったところで意味がない。

さて、どうしようとなるわけですね。

## UIApplication を利用してモディファイアを作成する

いろいろ考えたのだが、結局この方法しか思いつかなかった。ただ、これはサイズが 0 の View を利用しないので初期化が何度もされてしまうという問題は発生しない（と思われる）

```swift
extension UIApplication {
    @available(iOS 15.0, *)
    var keyWindow: UIWindow? {
        return self.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })?
            .windows
            .first(where: { $0.isKeyWindow })
    }

    @available(iOS 15.0, *)
    var rootViewController: UIViewController? {
        return self.keyWindow?.rootViewController
    }

    @available(iOS 15.0, *)
    public var presentedViewController: UIViewController? {
        keyWindow?.makeKeyAndVisible()

        guard let rootViewController = keyWindow?.rootViewController
        else {
            return nil
        }

        var presentedViewController: UIViewController? = rootViewController
        while let controller: UIViewController = presentedViewController?.presentedViewController {
            presentedViewController = controller
        }
        return presentedViewController
    }
}
```

まず最初に、最も全面に表示されているの UIViewController を取得するコードを書く。このあたりは iOS13 と iOS15 で非推奨になったコードが含まれるので上のように警告を回避しつつ`keyWindow`を取得するように変更する。

ルートから順に下っていって、それ以上子を持たない UIViewController を返すわけである。

```swift
extension View {
    func fullScreen<Content: View>(
        isPresented: Binding<Bool>,
        modalPresentationStyle: UIModalPresentationStyle = .fullScreen,
        modalTransitionStyle: UIModalTransitionStyle = .coverVertical,
        isModalInPresentation: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        if isPresented.wrappedValue {
            let controller: UIHostingController = UIHostingController(rootView: content())
            controller.modalPresentationStyle = modalPresentationStyle
            controller.modalTransitionStyle = modalTransitionStyle
            controller.isModalInPresentation = isModalInPresentation
            UIApplication.shared.presentedViewController?.present(controller, animated: true, completion: {
                DispatchQueue.main.async(execute: {
                    isPresented.wrappedValue.toggle()
                })
            })
        }
        return self
    }
}
```

で、次に上のような View に対する拡張メソッドを書く。ぶっちゃけると、なんで`completion`の中で`isPresented.wrappedValue.toggle()`を呼んでいるのかわからないのだが、これをしないと閉じたときに値が逆になっているのでボタンを押しても一回無反応というよくわからないことが起きます。

[参考にしたコード](https://medium.com/@cuongnguyenhuu/how-to-present-a-screen-with-modalpresentationstyle-in-swiftui-like-uikit-fe9b53e09d72)だと 0.1 秒後にトグルを切り替えるという謎なコードになっていたので、とりあえず普通に表示完了後に切り替えるようにしました。こっちのほうが確実のはず、多分。

これを動かすとたしかにモーダルが自在に表示できて、バグも少なさそうなコードになりました。
