---
title: SwiftUIでアニメーションを実装してみる
published: 2021-06-14
category: Programming
tags: [Swift, SwiftUI]
---

# SwiftUI でのアニメーション

SwiftUI では View に視覚効果を付ける Modifier があります。

視覚効果には大雑把に分けて`animation`と`transition`の二つがあります。それぞれ何が違うのかということなのですが、`animation`はプロパティの値が変わる際に視覚効果が発生するのに対して、`transition`は View の表示と非表示が切り替わる際にしか発生しないということです。

## Transition 発生のタイミング

では「表示と非表示」のタイミングとはどういうことなのかを考えてみます。

ぱっと思った感じでは`onAppear`か`onDisapper`のどちらかが呼ばれるタイミングの気がしますが、ひょっとしたら`scenePhase`の切り替えタイミングでも呼ばれるかもしれません。

考えても仕方がないので、実際にコードを書いて確かめてみることにします。

デモコードについてはカピバラ通信さんの[【SwiftUI】トランジション（transition）の使い方](https://capibara1969.com/2442/)を参考にさせていただきました。

```swift
// 期待通りの動作をしないコード
import SwiftUI

struct ContentView: View {
    @State private var transition: Bool = false

    var body: some View {
        VStack {
            Button(action: {
                transition.toggle()
            }, label: { Text("TRANSITION") })
            if transition {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 100, height: 100, alignment: .center)
                    .transition(.slide)
            }
        }
    }
}
```

さて、上のコードはボタンをタップすると`@State`の値が変わり、`@State`の値が変わったことでビューが再描画され、青い円が表示されたり非表示になったりを繰り返します。

そして、`transition`はビューの「表示/非表示」の切り替わりのタイミングで視覚効果を発生させるので、青い円が表示されるときや消えるときには`slide`が発生するはずなのですが、このコードでは発生しません。何故か。

もう一度、何故青い円が視覚効果を引き起こすのか、考えてみましょう。

1. ボタンをタップする
2. `transition`の値が切り替わる
3. ビューが再レンダリングされる
4. `Circle`の表示と非表示が切り替わる
5. `transision(.slide)`が実行される

つまり、結局はボタンを押して`transition.toggle()`が実行されることが視覚効果を引き起こしています。そして、`transition`での視覚効果を発生させるには「その原因となるプロパティの値の変更を`withAnimation`のクロージャ内で発生させる」ということが必要になってきます。

要するに「このプロパティの変更で何らかの視覚効果が発生するよ」ということを SwiftUI フレームワークに対して明示しなければいけません。

::: warning 必ずしも明示する必要はないらしい

「明示しなければいけない」と書いたが、必ずしも明示する必要はないらしい。が、まあ念の為に明示することを心がけたほうが良いだろう。

:::

```swift
// 正常に動作するコード
import SwiftUI

struct ContentView: View {
    @State private var transition: Bool = false

    var body: some View {
        VStack {
            Button(action: {
                withAnimation {
                    transition.toggle()
                }
            }, label: { Text("TRANSITION") })
            if transition {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 100, height: 100, alignment: .center)
                    .transition(.slide)
            }
        }
    }
}
```

するとボタンを押すと左から青い円が現れて、もう一度ボタンを押すと右に消えていく視覚効果を発生させることができました。

### Transition の種類

今回は左から現れて右に消えていく視覚効果でしたが、逆に右から現れて左に消えていく視覚効果を実装したい場合にはどうすれば良いでしょうか。

実は Transition には次の六種類しか存在しません。`slide`は常に左から現れて右に消えるため、右から現れて左に消すことはできないということです。

| Transition |                   視覚効果                   |
| :--------: | :------------------------------------------: |
|   slide    |            左から現れて右に消える            |
|    move    |  指定した方向から現れて指定した方向に消える  |
|  opacity   | 透明度が徐々に上がり現れ、徐々に下がり消える |
|   scale    | 徐々に大きくなり現れ、徐々に小さくなり消える |
|   offset   |   指定された位置に移動しながら表示/非表示    |
|  identity  |             視覚効果を利用しない             |

`move`は`slide`と同じような視覚効果を持ちますが、現れた方向に消えていってしまうため右から表示させると右に消えていってしまいます。

じゃあどうすればいいかというと表示時と非表示時の視覚効果を変えればよいのです。

## Transition の非対称化

`transition`を非対称にするには`.asymmetric(insertion:, removal:)`が利用できます。

さっき説明したように、表示時と非表示時の視覚効果を切り替えることができるので、これを利用すれば右から出現して左に消えていく視覚効果を実装することができます。

```swift
// 右から現れて左に消えていくtransitionの実装
import SwiftUI

struct ContentView: View {
    @State private var transition: Bool = false

    var body: some View {
        VStack {
            Button(action: {
                withAnimation {
                    transition.toggle()
                }
            }, label: { Text("TRANSITION") })
            if transition {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 100, height: 100, alignment: .center)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
            }
        }
    }
}
```

### Transition の合成

`transition`は複数組み合わせることもできます。

```swift
// 不透明度を変えながらスライドするアニメーション
import SwiftUI

struct ContentView: View {
    @State private var transition: Bool = false

    var body: some View {
        VStack {
            Button(action: {
                withAnimation {
                    transition.toggle()
                }
            }, label: { Text("TRANSITION") })
            if transition {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 100, height: 100, alignment: .center)
                    .transition(AnyTransition.slide.combined(with: .opacity))
            }
        }
    }
}
```

この場合、`AnyTransition`を指定しなければコンパイルエラーが発生します。

## Transition が呼ばれるタイミング

### TabView の場合

```swift
import SwiftUI

struct ContentView: View {
    @State private var selection: Int = 0

    var body: some View {
        TabView(selection: $selection) {
            Circle()
                .fill(Color.blue)
                .frame(width: 100, height: 100, alignment: .center)
                .transition(.slide)
                .tabItem { Image(systemName: "1.circle") }
                .tag(0)
            Circle()
                .fill(Color.blue)
                .frame(width: 100, height: 100, alignment: .center)
                .transition(.scale)
                .tabItem { Image(systemName: "2.circle") }
                .tag(1)
        }
    }
}
```

タブが切り替わるたびにアニメーションが発生するかと思ったが、実際には全く発生しなかった。

おそらく、`selection`の値が変わったときに`withAnimation`が呼ばれていないのが原因だと思われる。

これらを解決する方法がいくつかありそうなのだが、あまりにめんどくさいのでここでは触れないことにする。

> [SwiftUI: How to animate a TabView selection?](https://stackoverflow.com/questions/61827496/swiftui-how-to-animate-a-tabview-selection)
>
> [SwiftUI: Animate Tab bar tab switch with a CrossDissolve slide?](https://prafullkumar77.medium.com/swiftui-animate-tab-bar-tab-switch-with-a-crossdissolve-slide-38e23bc77e0d)

### NavigationView の場合

```swift
import SwiftUI

struct ContentView: View {

    var body: some View {
        NavigationView {
            NavigationLink(destination: circle, label: { Text("Circle") })
        }
    }

    var circle: some View {
        Circle()
            .fill(Color.blue)
            .frame(width: 100, height: 100, alignment: .center)
            .transition(.slide)
    }
}
```

表示されたときに視覚効果が発生するならこれならいけるのではと思ったのですが、いけませんでした。

### 解決方法

直接的に`transition`を利用する方法ではないが、View が表示されるたびに TabView でも NavigationView でも`transition`のような効果を発揮する Extension を作成した。

```swift
extension View {
    func transitionScale(_ animation: Animation? = nil, scale: Binding<CGFloat>) -> some View {
        onAppear {
            withAnimation(animation) {
                scale.wrappedValue = 1.0
            }
        }
        .onDisappear {
            withAnimation(animation) {
                scale.wrappedValue = 0.0
            }
        }
        .scaleEffect(scale.wrappedValue)
    }

    func transitionScale(_ animation: Animation? = nil, opacity: Binding<Double>) -> some View {
        onAppear {
            withAnimation(animation) {
                opacity.wrappedValue = 1.0
            }
        }
        .onDisappear {
            withAnimation(animation) {
                opacity.wrappedValue = 0.0
            }
        }
        .opacity(opacity.wrappedValue)
    }
}
```

例えばこういう Extension を書けばそのオブジェクトが表示されるたびにこのメソッドが呼ばれるので、あたかも`transition`のように振る舞うことができる。
