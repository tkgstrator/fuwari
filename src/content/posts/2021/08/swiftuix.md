---
title: SwiftUIXの実力を確かめてみた
published: 2021-08-25
description: SwiftUIの拡張ライブラリであるSwiftUIXを実際に使ってみました
category: Programming
tags: [Swift, SwiftUI]
---

# SwiftUIX

SwiftUI で不足している機能やコンポーネントを補完するためのプロジェクトです。

細かいドキュメントは[Wiki](https://github.com/SwiftUIX/SwiftUIX/wiki)にあるそうなのですが、正直読んでも全然わかりません。

明らかに内容が足りていないです。



## コンポーネント

いろいろ便利なコンポーネントがあるのですが、個人的には SearchBar と PaginationView が便利だと思います。

### LinkPresentationView

Safari で指定された URL を開きます。

```swift
import SwiftUI
import SwiftUIX

struct ContentView: View {
    var body: some View {
        LinkPresentationView(url: URL(string: "https://tkgstrator.work/")!)
    }
}
```

BetterSafariView の方が便利なので使うことはないと思います。

### ActivityIndicator

```swift
import SwiftUI
import SwiftUIX

struct ContentView: View {
    var body: some View {
        ActivityIndicator()
    }
}
```

ローディング中の画面を表示します。

ただし、SwiftUI2.0 では`ProgressView()`があるのでこれを利用することは少ないかと。

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        ProgressView()
    }
}
```

### Appearance

`visible()`という ViewModifier が追加されており、Bool 値を使って View の表示/非表示を切り替えられます。

```swift
import SwiftUI
import SwiftUIX

struct ContentView: View {
    @State var isVisible: Bool = true

    var body: some View {
        VStack {
            Button(action: { isVisible.toggle() }, label: {
                Text(isVisible ? "Show" : "Hide")
            })
            Text("Hello, World!")
                .visible(isVisible)
        }
    }
}
```

SwiftUI2.0 では`hidden()`しかなく、この属性は Bool 値で切り替えできなかったので`visible()`は便利だと思います。

### PaginationView

ページ送りの View を実装します。

似たようなものに TabView があるのですが、これはなぜか必ず八番目までの View のイニシャライザが呼ばれてしまうという仕様があり、一つ一つの View が重い場合には表示にやたらと時間がかかって不便でした。

PaginationView では常に表示している View のイニシャライザしか呼ばれないので重くなりません。

SwiftUIX でいまのところ一番便利な機能なのではないかと思っています。

```swift
import SwiftUI
import SwiftUIX

struct ContentView: View {
    @State var isVisible: Bool = true

    var body: some View {
        PaginationView(axis: .horizontal, transitionStyle: .scroll, showsIndicators: true, content: {
            ForEach(Range(0...100)) { index in
                Text("Hello, World \(index)!")
            }
        })
        .currentPageIndicatorTintColor(.primary)
    }
}
```

### SearchBar

![](https://pbs.twimg.com/media/E9nGzFAUUAA9Yfn?format=jpg&name=large)

SwiftUI では標準の検索フォームがないのでこれは非常に助かります。

```swift
import SwiftUI
import SwiftUIX

struct ContentView: View {
    @State var inputText: String?

    var body: some View {
        SearchBar("Input", text: $inputText)
    }
}
```

これだけでも便利なのですが、SearchBar を NavigationView に埋め込む ViewModifier があります。

![](https://pbs.twimg.com/media/E9nGzfLVoAcIaOy?format=jpg&name=large)

```swift
import SwiftUI
import SwiftUIX

struct ContentView: View {
    @State var inputText: String?

    var body: some View {
        NavigationView {
            Text("Hello, world!")
                .navigationSearchBar {
                    SearchBar("Input", text: $inputText)
                }
                .navigationTitle("SwiftUIX Demo")
        }
    }
}
```

![](https://pbs.twimg.com/media/E9nGz4OVoAAN5j2?format=jpg&name=large)

ただ、Form と組み合わせると表示が乱れることがあるようです。

![](https://pbs.twimg.com/media/E9nG0zLUUAAaXB-?format=jpg&name=large)

### VisualEffectBlurView

![](https://pbs.twimg.com/media/E9nG1eTVEAAQCS7?format=jpg&name=large)

すりガラス的な効果を提供する View です。

利用できる効果はたくさんあるので[Apple のドキュメント](https://developer.apple.com/documentation/uikit/uiblureffect/style)を見てください。

### PresentationView

使い方は NavigationView に近い、Modal を表示するための View です。

とりあえずルート View に対して属性を付けておきます。こうしないと`@Environment`がとってこれないので。

```swift
// SwiftUIXDemoApp.swift
import SwiftUI
import SwiftUIX

@main
struct SwiftUIXDemoApp: App {
    var body: some Scene {
        WindowGroup {
            PresentationView {
                ContentView()
            }
        }
    }
}
```

次に、Modal を表示したい View で`@Environment`を宣言して、以下のようにコーディングします。

```swift
import SwiftUI
import SwiftUIX

struct ContentView: View {
    @Environment(\.presenter) var presenter

    var body: some View {
        Button(action: present, label: {
            Text("Modal View")
        })
    }

    func present() {
        presenter?.present(
            PresentationView {
                ChildView()
                    .dismissDisabled(true)
            }
        )
    }
}

struct ChildView: View {
    @Environment(\.presenter) var presenter

    var body: some View {
        Button(action: dismiss) {
            Text("Dismiss")
        }
    }

    func dismiss() {
        presenter?.dismissSelf()
    }
}
```

ただ、画面を回転させるとサイズがバグる問題があるのと、`.modalPresentationStyle()`が全然効きません。

なのでぼくが開発した[SwiftyUI](https://github.com/tkgstrator/SwiftyUI)の方がまだまともに動くのではないかと思います（自画自賛）

## Enum

SwiftUI では直接アクセスするのがめんどくさい Enum も完備されています。

### Screen

デバイスの Screen のサイズをとってこれます。

```swift
// SwiftUI
UIScreen.main.bounds.size.width

// SwiftUIX
Screen.size.width
```

ちょっとだけ楽にかけます。

### UserInterfaceIdiom

アプリが起動しているデバイスの Enum を取得します。

```swift
// SwiftUI
UIDevice.current.userInterfaceIdiom

// SwiftUIX
UserInterfaceIdiom.current
```

### Orientation

```swift
// SwiftUI
UIDevice.current.orientation
UIApplication.shared.windows.first?.windowScene?.interfaceOrientation

// SwiftUIX
UserInterfaceOrientation.current
```

このとき注意しないといけないのは`UIDevice.current.orientation`は起動直後には`.unknown`という値が入っていて全く役に立たないということです。

なので SwiftUIX を使ったほうがいいですね。

記事は以上。


