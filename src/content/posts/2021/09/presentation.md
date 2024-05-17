---
title: 自作ModalWindowがとじれないのでアップデートしてみた
published: 2021-09-08
description: SwiftyUIで自作Modalを作成したのは良いのですが、一部の機能が使えないので修正しました
category: Programming
tags: [SwiftUI, Swift]
---

# [SwiftyUI](https://github.com/tkgstrator/SwiftyUI)

自作 ModalWindow がつくれるライブラリ SwiftyUI なのですが、利用していた新たなバグが見つかったのでその原因を調べようと思います。

|                  |      sheet       |  fullScreenCover   |     present      |
| :--------------: | :--------------: | :----------------: | :--------------: |
| モーダルデザイン |  PageSheet のみ  |  FullScreen のみ   |       任意       |
|      閉じ方      | 画面外タップなど | 専用のボタンが必須 | 画面外タップなど |
|     サポート     |      iOS13       |       iOS14        |     SwiftyUI     |



## ModalWindow を複数用意するときの注意

```swift
import SwiftUI
import SwiftyUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            List {
                ForEach(Range(0...10)) { index in
                    ButtonView(id: index)
                }
            }
            .navigationTitle("Presentation Demo")
        }
    }
}
```

例えば、上のようになんの変哲もないリスト内に 10 個のボタンを表示するような View を考えます。

```swift
import SwiftUI

struct ButtonView: View {
    let id: Int
    @State var isPresented: Bool = false

    var body: some View {
        Button(action: {
            isPresented.toggle()
        }, label: {
            Text("OPEN \(id)")
        })
        .sheet(isPresented: $isPresented, content: {
            UserView(id: id)
        })
    }
}
```

そしてそれぞれのボタンには`isPresented`と`sheet`を紐つけておきます。

![](https://pbs.twimg.com/media/E-ujDpCVQAItVN2?format=jpg&name=large)

イメージとしてはこんな漢字で、10 個のボタンそれぞれに`isPresented`と遷移先の View が割り当てられます。

### 実はこれでも動く

一見するとヤバそうなコードなのですが、これでも動きます。

```swift
import SwiftUI
import SwiftyUI

struct ContentView: View {
    @State var isPresented: Bool = false

    var body: some View {
        NavigationView {
            List {
                ForEach(Range(0...10)) { index in
                    Button(action: {
                        isPresented.toggle()
                    }, label: {
                        Text("OPEN \(index)")
                    })
                }
                .sheet(isPresented: $isPresented, content: {
                    UserView(id: index)
                })
            }
            .navigationTitle("Presentation Demo")
        }
    }
}
```

![](https://pbs.twimg.com/media/E-ujJJeVEAAflZj?format=jpg&name=large)

ContentView 自体が`isPresented`と遷移先の View を持っているため、どのボタンから呼び出されたかわからなくて困るんじゃないかと思うのですが、実はこれで動いてしまいます。そこはきっと Apple か何かの公式に闇の力が働いているんだと思います。

ただし、このコードは SwiftyUI で提供している自作 ModalWindow ではバグが発生して（複数の ModalWindow が同時に呼ばれてしまう）利用することができません。

ちゃんと最初に載せたようにボタンごとに`isPresented`を割り当てるようにしてください。

::: danger この書き方について

この書き方は全く推奨されない。むしろちゃんと動いてしまう`sheet`や`fullScreenCover`の挙動がおかしい。

:::

|                    | sheet | fullScreenCover | present |
| :----------------: | :---: | :-------------: | :-----: |
|     List, Form     |  OK   |       OK        |   NG    |
| VStack, LazyVStack |  NG   |       NG        |   NG    |

いろいろ試したところ`List`や`Form`限定でこの書き方は正しく動作するようで`VStack`や`LazyVStack`などを利用した場合には正しく動作しない。

ここから先は推測になるのだが、`List`や`Form`では各要素が`Identifiable`になっており`tag`などの要素でどのボタンから押されたかを`isPresented`が認識している可能性がある。が、結局 VStack や LazyVStack で動かない以上、このようなコードは書くべきではない。

## PresentationMode

`PresentationMode`というのは SwiftUI で使える環境変数の一つで`そのViewがどこからか遷移してきたか`の情報を持つと書かれている文献が多い。

が、これは考え方によっては少し正しくない（これについては後述する）

例えば`NavigationLink`や`sheet`や`fullScreenCover`で表示された遷移先の View ではこの環境変数の`isPresented`の値は常に`true`になっている。

| PresentationMode | NavigationLink | Sheet | FullScreenCover |
| :--------------: | :------------: | :---: | :-------------: |
|   isPresented    |       OK       |  OK   |       OK        |

調べてはいないのだが他の`Viewを呼び出すModifier`でもそうなっていると思われる。

ではここで先程までのコードを少し変更して`ButtonView`から遷移した先の`UserView`を以下のようにコーディングしてみる。

```swift
import SwiftUI

struct UserView: View {
    let id: Int

    var body: some View {
        Button(action: {
            // 押したらModalWindowを閉じる処理を書く
        }, label: {
            Text("CLOSE \(id)")
        })
    }
}
```

ここまでの UI を大雑把にフローチャートで示すと以下のようになり、List 内の`ButtonView`からそれぞれ`UserView`が呼び出せれるという仕組みになっている。

![](https://pbs.twimg.com/media/E-uuJ3SVEAEHwb2?format=jpg&name=large)

ここには載せていないが`ButtonView`と`UserView`にはそれぞれ`id`が割り当てられているのでどこの`ButtonView`から呼び出されたかがわかるようになっている。

### ModalWindow の dismiss

で、ここで一つ困った問題が生じる。

というのも ModalWindow として表示された`UserView`は自身を閉じる(`dismiss`)する方法を持たないからだ。`UserView`を閉じるには`ButtonView`が持つ`isPresented`の値を`false`にするしかないのだが、`UserView`のイニシャライザに`isPresented`は与えられていないためその値を変更することができない。

#### 非推奨の解決法

全く推奨されない解決策が以下のコードになる。

```swift
import SwiftUI

struct UserView: View {
    @Binding var isPresented: Bool
    let id: Int

    var body: some View {
        Button(action: {
            isPresented.toggle()
            // 押したらModalWindowを閉じる処理を書く
        }, label: {
            Text("CLOSE \(id)")
        })
    }
}
```

これは`UserView`に`isPresented`の値を`Binding<Bool>`として与え、`UserView`内から切り替えられるようにするものである。このコードの問題点は以下の通り。

- イニシャライザに与える引数が増える
- View が階層構造になっていた場合、延々と`Binding`を続けなければいけない

::: tip Binding の理由

賢明な読者の方なら理解されていると思うが、一応補足説明をしておく。SwiftUI の View は`struct`なので内部で値を更新するためには`mutating`をつけなければいけないが、それではコンパイルが通らない。

よって普通は`@State`をつけて SwiftUI フレームワークで値を変更するように委任するわけである。そして SwiftUI フレームワークは`@State`のプロパティが変更されたタイミングで View の再レンダリングを行う。

なので単に`var isPresented: Bool`と書いてしまうと`isPresented.toggle()`の部分でコンパイルエラーがでる。じゃあ`@State var isPresented: Bool`ならいいのではないかと思うかもしれないが、それではダメである。

何故なら`isPresented`の値はそもそも`ButtonView`のプロパティだからである。

`@State`をつけてしまうと SwiftUI は`UserView`に対して`isPresented`の値が変わったときに`UserView`の UI を再レンダリングしてしまう。`ButtonView`が再レンダリングされないと ModalWindow がとじないのでこれでは意味がない。

結論から言えば、`@Binding`属性をつけるというのは「お前もこの変数の値変えてもええで、変わったらわいは UI 更新するわ」という意味なのである。

:::

### 環境変数を利用する

そこで利用できるのが環境変数で、これを使えばイニシャライザに渡さなくても値をとってくることができます。

```swift
import SwiftUI

struct UserView: View {
    // 環境変数読み込み
    @Environment(\.presentationMode) var present
    let id: Int

    var body: some View {
        Button(action: {
            present.wrappedValue.dismisss()
        }, label: {
            Text("CLOSE \(id)")
        })
    }
}
```

で、この`presentationMode`はその View が現在表示されているかどうかのフラグを持っているので、`present.wrappedValue.dismiss()`とすれば何故か View を閉じることができる。

#### 意味

では何故`present.wrappedValue.dismiss()`でとじることができるのかということなのだが、実はこれは`present.wrappedValue=isPresented`になっているからだ。

これだけだとわけがわからないと思うのでコードで書くと次のようになる。

```swift
import SwiftUI

struct ButtonView: View {
    let id: Int
    @State var isPresented: Bool = false

    var body: some View {
        Button(action: {
            isPresented.toggle()
        }, label: {
            Text("OPEN \(id)")
        })
        .sheet(isPresented: $isPresented, content: {
            UserView(id: id)
                .environment(\.presentationMode, $isPresented) // 内部的にこのような処理になっている
        })
    }
}
```

つまり`UserView`に対して内部的に`presentationMode`という環境変数として`$isPresented`が割り当てられているので`presentationMode`の値を変えると`$isPresented`の値が切り替わり、その結果として ModalView がとじるという仕組みになっている。

で、この内部的な処理が SwiftyUI では行われていないので`presentationMode`ではとじることができないのだ。

|        -         | sheet | fullScreenCover | present |
| :--------------: | :---: | :-------------: | :-----: |
| presentationMode |  OK   |       OK        |   NG    |

じゃあ SwiftyUI でも内部的に`presentationMode`の値を割り当てれば良いような気がするのだが、それが何故か上手くいかない。

というのも`PresentationMode`は構造体であり、次のようなコードになっているため。

```swift
public struct PresentationMode {

    /// Indicates whether a view is currently presented.
    public var isPresented: Bool { get }

    /// Dismisses the view if it is currently presented.
    ///
    /// If `isPresented` is false, `dismiss()` is a no-op.
    public mutating func dismiss()
}
```

イニシャライザがないので上手く利用することができなかった。

### 自作環境変数を利用する

上手く`PresentationMode`を利用する方法があればよいのだが、わからなかったので別の方法を試すことにする。

今回は、環境変数として`ModalIsPresentation`というものを作成することにした。

```swift
struct PresentationStyle {
    private(set) var isPresented: Binding<Bool>

    public mutating func dismiss() {
        isPresented.wrappedValue.toggle()
    }

    init(_ isPresented: Binding<Bool>) {
        self.isPresented = isPresented
    }
}

struct ModalIsPresented: EnvironmentKey {

    static var defaultValue: Binding<PresentationStyle> = .constant(PresentationStyle(.constant(false)))

    typealias Value = Binding<PresentationStyle>
}

extension EnvironmentValues {
    var modalIsPresented: Binding<PresentationStyle> {
        get {
            return self[ModalIsPresented.self]
        }
        set {
            self[ModalIsPresented.self] = newValue
        }
    }
}
```

少々ややこしいが`PresentationMode`と同様の機能を取り入れるためにはこのようなコードにならざるを得なかった。

![](https://pbs.twimg.com/media/E-vLJCGVQAMNLWk?format=jpg&name=large)

要するに`modalIsPresented`にアクセスするとそれは結局`Binding<PresentationStyle>`にアクセスしているのと同じで、`PresentationStyle`は`dismiss()`というメソッドを持っており、これを使えば`isPresented`の値が反転するので View がとじるという仕組みである。

また、無理やり`isPresented`の値を変更されないように`private(set) var isPresented: Binding<Bool>`と宣言した。

これによって、`setter`だけが`private`になるので外部から値を変更できないようになるというわけである。

### 課題は残る

で、これでボタンでとじる動作はできるようになったのであるがまだ一つ課題が残ってしまっていた。

というのも、デバイスを傾けた際に`isPresented`が変化したときと同様に`updateUIViewController`が呼ばれてしまうという点である。

そして Form や List を用いずに一つの View に複数の`present`が表示されるような状態だと、デバイスを傾けた際に`dismiss()`が呼ばれてしまいモーダルがとじてしまうのだ。

モーダルを表示したままデバイスを傾けるようなことがないのであればいいのだが、プログラムとしてそういう欠点が残っているのは気がかりである。

## 解決策？

現在は`UIAdaptivePresentationControllerDelegate`を利用するコードに切り替えているが、前に実装していた`UIPopoverPresentationControllerDelegate`でも同様のことが発生するのかは気になるところである。

または`present`の`ViewModifier`を公式の`sheet`と同じように`Identifiable`にできれば解決できるような気はしている。

記事は以上。


