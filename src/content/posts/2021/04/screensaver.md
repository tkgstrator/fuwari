---
title: SwiftUIで一定時間無操作スクリーンセーバーを出す方法
published: 2021-04-26
description: スクリーンセーバー機能をSwiftUIで実装する方法のまとめ
category: Programming
tags: [Swift]
---

## スクリーンセーバーとは

スクリーンセーバーとは長時間同じ画面を表示し続けると画面が焼き付きを起こしてしまうため、それを防ぐために一定時間操作がないと別のアニメーションを表示するような仕組みのことを指す。

最近のモニタはそもそも焼き付きを起こしにくい上、一定時間の無操作で勝手に画面がオフになるためスクリーンセーバーが必要とされる場面は少ない。

また、モバイル向けアプリであれば長時間ずっと画面がついているとそれこそバッテリーの無駄なのでシステム的にしばらく操作しないでいると勝手に画面がオフになる。したがって、モバイルアプリでスクリーンセーバーが必要になる場面は基本的には考えられない。

### 情報を調べてみる

そもそも必要とされていないだけあって、情報が殆ど見つからなかった。

[ScreenSaverView](https://developer.apple.com/documentation/screensaver/screensaverview)というクラス自体は存在するようなのだが、macOS 向けであり iOS 向けには実装されていない。

そもそも、スクリーンセーバーを実装するためには「N 秒間操作されていない」という情報を持っていなければいけない。スクリーンセーバーの実装ためだけにわざわざ何もしなくていい時間にそういったコードが裏で動いていなければいけないのだ。

うーん、やはりスクリーンセーバーを実装するメリットはないように感じますね。

が、電源挿しっぱなしでなにかの情報を表示し続けるようなアプリであればスクリーンセーバー的な機能が欲しくなるのもまた理解できます。

ここは、なんとかして実装することを考えてみましょう。

## 実装してみよう

調べてみたところ愚直に Timer を使う方法と、Combine を使ってちょっとそれっぽく書く方法があるようです。

今回はどちらのコードも調べ、等価なプログラムを書いてみることにしました。

### Timer を利用する

まず簡単に実装できそうな Timer を利用してみます。Timer の使い方自体はよくわかっていないのですが、[HACKING WITH SWIFT](https://www.hackingwithswift.com/quick-start/swiftui/how-to-use-a-timer-with-swiftui)のページのチュートリアルがわかりやすいと思います。

```swift
struct ContentView: View {
    @State var timeRemaining = 10
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text("\(timeRemaining)")
            .onReceive(timer) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                }
            }
    }
}
```

Timer は 1 秒おきに publish で更新をかけ、`onReceive`で Timer の値が変化したときに何らかの操作を行なうわけです。

このチュートリアルの場合ではテキストの値を変更しているので、テキストの中身である`timeRemainig`が`@State`になっているわけですね。

ちなみに publish されている値は`2021-04-25 23:55:24 +0000`のような値になります。日付を表示したいのであればこのデータをそのまま利用するのもありかもしれません。

### Playground 向けコード

Playground でテストコードを書くなら以下のようにするのがスマートかもしれません。

timer は 1 秒おきにカウントを 1 ずつ減らしていくのですが、`onTapGesture`を使い、どこかがタップされたとき（操作されたとき）にカウントを 10 まで戻すという処理をするのです。

これなら無操作で N 秒（今回の場合は 10 秒）経過した場合に onReceive 内で何らかの操作（スクリーンセーバーを表示する）が可能になるというわけです。

```swift
import SwiftUI
import PlaygroundSupport

struct ContentView: View {
    @State var timeRemaining = 10
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text("\(timeRemaining)")
            .onReceive(timer) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                }
            }
            .onTapGesture {
                timeRemaining = 10
            }
    }
}

PlaygroundPage.current.liveView = UIHostingController(rootView: ContentView())
```

## Timer + Combine

そういえば以前に時計アプリを作りたくて[clock-swiftui-sample](https://github.com/ivicamil/clock-swiftui-sample)を参考にしたのですが、ここで不思議なタイマーの使い方をしていたことを思い出したのでついでに学習することにしました。

```swift
import SwiftUI
import Combine

struct ClockModel {
    let hours: Int
    let minutes: Int
    let seconds: Int

    init(published: Date) {
        let calendar = Calendar.current
        let now = Date()
        let hours = calendar.component(.hour, from: now)
        self.hours = hours <= 12 ? hours : hours - 12
        minutes = calendar.component(.minute, from: now)
        seconds = calendar.component(.second, from: now)
    }
}

struct ClockView : View {

    @State(initialValue: ClockModel(published: Date()))
    private var time: ClockModel

    @State
    private var timerSubscription: Cancellable? = nil
    private let hourPointerBaseRadius: CGFloat = 0.1
    private let secondPointerBaseRadius: CGFloat = 0.05

    var body: some View {
        ZStack {
            Circle().stroke(Color.primary)
            ClockMarks()
            ClockIndicator(type: .hour, time: time)
            ClockIndicator(type: .minute, time: time)
            ClockIndicator(type: .second, time: time)
        }
        .padding()
        .aspectRatio(1, contentMode: .fit)
        .onAppear { self.subscribe() }
        .onDisappear { self.unsubscribe() }
    }

    private func subscribe() {
        timerSubscription =
            Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .map(ClockModel.init)
            .assign(to: \.time, on: self)
    }

    private func unsubscribe() {
        timerSubscription?.cancel()
    }
}
```

ここで気になるのは`private func subscribe()`の内容です。また、Combine をインポートしている点も気になります（単に Timer を使うだけなら Combine は不要のため）

```swift
private func subscribe() {
    timerSubscription =
        Timer.publish(every: 1, on: .main, in: .common)
        .autoconnect()
        .map(ClockModel.init)
        .assign(to: \.time, on: self)
}
```

このコードの意味が完全に理解できない限り、コーディングを進めることは不可能でしょう。

何故なら、例えば「該当するビューが表示されていない間はスクリーンセーバの判定をしない」というようなコードであってもこのような単純なコードでは Timer が動き続けてしまうことが考えられるからです。

ビューが表示されなくなったら Timer は破棄する、といった柔軟なコードにしたいわけです。

### Timer を利用したコード

単純に Timer を利用しただけのコードが以下になります。

めんどくさかったので Timer が publish している値（Date 型）の description（String 型）をとって表示しただけのものです。

```swift
import SwiftUI
import PlaygroundSupport

struct ContentView: View {
    @State var currentTime: Date = Date()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Text(currentTime.description)
            .onReceive(timer) { value in
                currentTime = value.description
            }
    }
}
PlaygroundPage.current.liveView = UIHostingController(rootView: ContentView())
```

### Combine を利用したコード

ではこのコードを Combine を使って書き直すことを考えます。

```swift
import SwiftUI
import Combine

struct ContentView: View {
    @State var currentTime: Date = Date()
    @State private var cancelable: AnyCancellable?

    var body: some View {
        Text(currentTime.description)
            .onAppear { subscribe() }
            .onDisappear { unsubscribe() }
    }

    private func subscribe() {
        cancelable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentTime, on: self)
    }

    private func unsubscribe() {
        cancelable?.cancel()
    }
}
```

`receive(on: DispatchQueue.main)`はどのスレッドで動作させるかを選択します。全部メインスレッドで実行するとメインスレッドが固まってしまうような場合が考えられるからです。

今回は軽い動作なのでメインスレッドで実行していますが、`DispatchQueue.global()`などを指定してもよいのではないかと思います。

こちら
](https://qiita.com/shiz/items/9dc8e9a96f399b6c7246)の記事が大変参考になりました。

単純に Timer だけを使うコードに比べて少し長いコードになりましたが、非表示になったときに unsubscribe が呼ばれるので利便性の高いコードになったのではないでしょうか。

`assign`は Timer が publish したデータを受け取る変数を指定します。Timer は Date 型を publish しているので Date 型の変数である`currentTime`で受け取っています。

```swift
private var time: ClockModel

private func subscribe() {
    timerSubscription =
        Timer.publish(every: 1, on: .main, in: .common)
        .autoconnect()
        .map(ClockModel.init) // map{ ClockModel($0) }でもOK
        .assign(to: \.time, on: self)
}
```

ここでデモコードを見てみると`assign`が Date 型ではない ClockModel 型の time に値を渡していることがわかります。なぜこのようなことが可能なのでしょうか。

実はその前の`map(ClockModel.init)`がカギになっており、ここで本来受け渡されるはずの Date 型を ClockModel 型に変換しているのです。

`map`の本来の使い方を考えれば`map{ ClockModel($0) }`という書き方が思いつくのですが、これらは同値なのでどちらの書き方でも正しく動作します。

## スクリーンセーバを作成する

ここまでの調査でなんとなく Timer や Combine の使い方がわかったので実際にコードにしてみましょう。

仕組みとしては以下のような感じで実装できます。

```swift
import SwiftUI
import Combine

struct ContentView: View {
    @State var currentTime: Date = Date()
    @State private var lastTappedTime: Int = Int(Date().timeIntervalSince1970)
    @State private var screenSaver: Date = Date()
    @State private var cancelable: AnyCancellable?

    var body: some View {
        ClockView()
            .frame(width: 150, height: 150, alignment: .center)
            .opacity(Int(screenSaver.timeIntervalSince1970) >= lastTappedTime + 10 ? 0.0 : 1.0)
            .onAppear { subscribe() }
            .onDisappear { unsubscribe() }
            .onTapGesture {
                lastTappedTime = Int(Date().timeIntervalSince1970)
            }
    }

    private func subscribe() {
        cancelable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .assign(to: \.screenSaver, on: self)
    }

    private func unsubscribe() {
        cancelable?.cancel()
    }
}
```

最後にタップした時間を`lastTappedTime`として保存しておき、`subscribe()`で一秒ごとに`screenSaver`の中身を更新し、それの timestamp を求めて lastTappedTime よりも 10 秒以上経過していたら透明度を変更して`ClockView()`を表示させるような内容になっています。

最初は lastTappedTime を持つ構造体をつくってそれにマッピングしようかとも思ったのですが毎回初期化されてしまうため意味がありませんでした。

上のコードをそれっぽく直したものが以下のものになります。

```swift
import SwiftUI
import Combine

struct ScreenSaver {
    var opacity: Double = 0.0

    init(from published: Date, lastTappedTime: Date) {
        if date.timeIntervalSince1970 >= lastTappedTime.timeIntervalSince1970 + 10 {
            withAnimation {
                opacity = 1.0
            }
        }
    }
    init() {}
}

struct ContentView: View {
    @State var currentTime: Date = Date()
    @State private var cancellable: AnyCancellable?
    @State private var lastTappedTime: Date = Date()
    @State private var screenSaver: ScreenSaver = ScreenSaver()
    @State private var cancelable: AnyCancellable?

    var body: some View {
        ClockView()
            .frame(width: 150, height: 150, alignment: .center)
            .opacity(screenSaver.opacity)
            .onAppear { subscribe() }
            .onDisappear { unsubscribe() }
            .onTapGesture {
                lastTappedTime = Date()
            }
    }

    private func subscribe() {
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .map{ ScreenSaver(from: $0, lastTappedTime: lastTappedTime)}
            .assign(to: \.screenSaver, on: self)
    }

    private func unsubscribe() {
        cancellable?.cancel()
    }
}
```

ScreenSaver の構造体が引数からビューを非表示にするかどうかの変数`opacity`を計算してくれるわけです。

が、よく考えたらこれは普通に computed property でもいいのではないかという気がしてきました。

```swift
struct ScreenSaver {
    var published: Date = Date()
    var lastTappedTime: Date = Date()
    var opacity: Double {
        if date.timeIntervalSince1970 >= lastTappedTime.timeIntervalSince1970 + 10 {
            return 1.0
        } else {
            return 0.0
        }
    }

    init(from published: Date, lastTappedTime: Date) {
        self.date = date
        self.lastTappedTime = lastTappedTime
    }

    init() {}
}
```

つまり、こう書けるということなのですがこうなってしまうとわざわざ構造体にマッピングする必要があったのかという疑問が生じます。

動作こそするものの、もっと上手な書き方がある気がしますね。

## 使ってみた感想

Timer の方が実装が楽である反面、Combine を使った方法の方がコードとしてはしっくりきている印象を受けた。

ただ、[`receive(on: Publisher)`](<https://developer.apple.com/documentation/combine/fail/receive(on:options:)>)の仕組みをしっかりと理解できていないためもやもやが残っていないかと言われると嘘になる。
