---
title: SwiftUIでタップされた座標を取得する方法
published: 2021-05-31
description: SwiftUIでタップイベントを取得する方法について
category: Programming
tags: [Swift, SwiftUI]
---

## SwiftUI でタップイベントを取得する

SwiftUI でタップされたイベントを取得するのであれば適当な View に[`onTapGesture()`](https://developer.apple.com/documentation/swiftui/tapgesture)をつければよいのだが`ontapGesture()`はタップされたときにクロージャ内の処理を実行してくれるが、そのときにどこの座標がタップされたのかは教えてくれない。

例えばお絵かきアプリをリリースしたいとして、タップした場所に円を表示するようなコードを書こうとしたら必ず「タップした場所」の情報が必要になる。

お絵かきアプリだとキャンバスの拡大縮小があったりして「画面の座標」と「キャンバスの座標」の二つを考えなければならず、めちゃくちゃややこしいことになりそうなのだが、今回はそういうことは考えず単に画面のどこがタップされたかを知りたいとしよう。

## タップイベント三兄弟

[Swift：タッチイベントの際にタッチした座標を取得する方法二通り](https://qiita.com/Kyome/items/d86cefa9dbd7bd2d7cf0)によれば Swift では二通りの方法でタップされた座標を取得する方法があるらしい。

検索をかけた段階で SwiftUI ではなく Swift の情報がでてくる時点でちょっと嫌な予感はしたりする。

## 暫定的な対応

[How to detect a tap gesture location in SwiftUI?](https://stackoverflow.com/questions/56513942/how-to-detect-a-tap-gesture-location-in-swiftui)に解決策が載っていて、`TapGesture`を使うことでなんと SwiftUI ネイティブに解決できるという。

```swift
struct ContentView: View {
    var body: some View {
        Color.gray.opacity(0.5)
            .edgesIgnoringSafeArea(.all)
            .gesture(DragGesture(minimumDistance: 0).onEnded({ (value) in
                print(value.location)
            }))
    }
}
```

いろいろ回答が載っているが、これが最もシンプルに動く。これが`DragGesture`を使っているが`minumumDistance`が 0 なので実質タップした位置の座標が取得できる。注意点としては`value`に入っているのは指を離した時点での座標なので、厳密に最初にタップした位置を取得できるわけではない。

まあ、それはそういうものだと割り切ってしまおう。

### Objective-C を利用した解決策

Objective-C を使えばより厳密にタップ位置を取得できる。このコードは`UITapGestureRecognizer`を利用しているので純粋にタップした位置しか取得しない。

タップ以外のジェスチャーは認識しないというのも強みと言えるだろう。

```swift
struct ContentView: View {
    var body: some View {
        Color.gray.opacity(0.5)
            .edgesIgnoringSafeArea(.all)
            .overlay(Background())
    }
}

struct Background: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let uiview = UIView(frame: .zero)
        let gesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.tappedGesture))
        uiview.addGestureRecognizer(gesture)
        return uiview
    }

    class Coordinator: NSObject {
        @objc func tappedGesture(gesture: UITapGestureRecognizer) {
            let point = gesture.location(in: gesture.view)
            // TapGesture
            print(point)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }
}
```

このコードは`Background`のビューで全てを完結させているが、親ビューで処理を行いたい場合もある。

### クロージャで親 View に値を返す場合

```swift
struct ContentView: View {
    var body: some View {
        Color.gray.opacity(0.5)
            .edgesIgnoringSafeArea(.all)
            .overlay(Background { location in
                // TapGesture
                print(location)
            })
    }
}

struct Background: UIViewRepresentable {
    var tappedCallback: ((CGPoint) -> Void)

    func makeUIView(context: Context) -> UIView {
        let uiview = UIView(frame: .zero)
        let gesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.tapped))
        uiview.addGestureRecognizer(gesture)
        return uiview
    }

    class Coordinator: NSObject {
        var tappedCallback: ((CGPoint) -> Void)

        init(tappedCallback: @escaping ((CGPoint) -> Void)) {
            self.tappedCallback = tappedCallback
        }

        @objc func tapped(gesture:UITapGestureRecognizer) {
            let point = gesture.location(in: gesture.view)
            self.tappedCallback(point)
        }
    }

    func makeCoordinator() -> Background.Coordinator {
        return Coordinator(tappedCallback:self.tappedCallback)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }
}
```

## ガチホコカウントビューワ

ガチホコカウントビューワではマップ画像をタップして、その位置でのカウントを表示するようなアプリにしたい。

ただ、どこをタップしかわからないのでは困るので、最後にタップした位置に何かしらのマークを付けておき、その位置でのカウントを表示するようにしたい。

そこで、先程のコードを修正して最後にタップした位置に円のオブジェクトを表示できるようにしてみる。

```swift
struct ContentView: View {
    @State var location: CGPoint?

    var body: some View {
        Color.clear
            .edgesIgnoringSafeArea(.all)
            .overlay(Background { location in
                self.location = location
            })
            .overlay(locationIcon)
    }

    var locationIcon: some View {
        if let location = self.location {
            return AnyView(Circle().fill(Color.blue).frame(width: 30, height: 30).position(x: location.x, y: location.y))
        } else {
            return AnyView(EmptyView())
        }
    }
}
```

コードとしては極めて単純明快で、単にタップしたときに取得した位置を`@State`に保存しておくだけだ。`@State`は値が変わったときにビューの再レンダリングが行われるので、画像のどこかをタップすれば(画像は何でもいいので各自用意してほしい)その位置に青い円が表示されるというわけである。

### ドラッグにも対応したい

が、実際に使ってみるとこれはひどく使い勝手が悪いことがわかる。

位置の細かい調整をしたいときはタップ判定よりもむしろドラッグ判定の方が便利なのだ。よって、画面をタップしてなぞっているときは指の位置に合わせて円がどんどん動いてくるようなシステムの方が望ましいのである。

```swift
struct Background: UIViewRepresentable {
    var tappedCallback: ((CGPoint) -> Void)

    func makeUIView(context: Context) -> UIView {
        let uiview = UIView(frame: .zero)
        let gesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.panned))
        uiview.addGestureRecognizer(gesture)
        return uiview
    }

    class Coordinator: NSObject {
        var tappedCallback: ((CGPoint) -> Void)

        init(tappedCallback: @escaping ((CGPoint) -> Void)) {
            self.tappedCallback = tappedCallback
        }

        @objc func panned(gesture:UIPanGestureRecognizer) {
            if gesture.state == .began || gesture.state == .changed {
                let point = gesture.location(in: gesture.view)
                self.tappedCallback(point)
            }
        }
    }

    func makeCoordinator() -> Background.Coordinator {
        return Coordinator(tappedCallback:self.tappedCallback)
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }
}
```

このようにかけばドラッグ中に円がちゃんと指についてきて理想的な動作が行える。

ただ、`ContentView`の書き方の問題でオブジェクト(この場合は円自体)にはタップ判定がないのが困る。

なので、タップ判定を行うバックグラウンドのビューは必ず最後に`overlay`をするようにしておく。

```swift
struct ContentView: View {
    @State var location: CGPoint?

    var body: some View {
        Color.clear
            .edgesIgnoringSafeArea(.all)
            .overlay(locationIcon) // 修正
            .overlay(Background { location in
                self.location = location
            })
    }

    var locationIcon: some View {
        if let location = self.location {
            return AnyView(Circle().fill(Color.blue).frame(width: 30, height: 30).position(x: location.x, y: location.y))
        } else {
            return AnyView(EmptyView())
        }
    }
}
```

こうすれば円自体にも`TapGesture`が利くので理想的な仕様になる。
