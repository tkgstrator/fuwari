---
title: SwiftUIでCompletionを使おう
published: 2021-04-13
description: SwiftUIでCompletionを使ったビューのコーディングを学びます
category: Programming
tags: [Swift]
---

## Completion の必要性

正直な話を言うと、SwiftUI で Completion が使えなくてもさほど困らない。困らないのだが、あった方が嬉しいのである。

例えば、イカのような仕様を満たすビューを書きたいとする。

- NavigationLink を踏むとパスコード入力画面を表示
- パスコードが合っていれば別のビューに遷移
- 間違っていればそのままの画面を表示

要するにパスコードチェックを目的のビューとの間にはさもうというわけだ。

これは以下のようなコードを書けば実装することができる。

```swift
@State var isAuthorized: Bool = false
// 中略

ZStack {
    NavigationLink(destination: DestinationView(), isActive: $isAuthorized, label: { EmptyView() })
    PasscodeLock($isAuthorized)
}
```

パスコード認証が通ったかどうかの情報を State で保持しておき、その値を PasscodeLock 内で変化させる。通れば`isAuthorized`が`true`になり、`true`になれば NavigationLink が動作して別のビューに遷移する。

ただ、これをやると`isAuthorized`という変数をビューに渡さなければいけないのがめんどうだし、何より ZStack を使って実装するのが如何にもゴミコードという感じがする。

`PasscodeLock`はパスコードが通ったかどうかだけをチェックしてほしいのである。

```swift
@State var isPresented: Bool = false

Button(action: { isPresented.toggle() }, label: { Text("AUTHORIZE") })
DestinationView()
    .passcodeLock(isPresented: $isPresented) {
        PasscodeLockView() { completion in
            switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print(error)
            }
        }
    }
```

例えばこのような記述ができるとありがたい。パスコードが通ったどうかを completion で返し、その値によって親ビュー側で分岐処理を書きたい。

```swift
@State var isPresented: Bool = false

ZStack {
    NavigationLink(destination: DestinationView(), isActive: $isPresented, label: { EmptyView() })
    PasscodeLockView() { completion in
        switch completion {
            case .finished:
                isPresented.toggle()
            case .failure(let error):
                print(error)
        }
    }
}
```

こういう書き方もできる。が、これは結局 ZStack を使っているのでゴミコード具合はあまり変わっていない気もする。

まあ実際にどうやって使うかはさておき、Completion を返すようなビューは書けるのかどうかが気になるわけである。似たような仕組みを持つものに[BetterSafariView](https://github.com/stleamist/BetterSafariView)があり、これの書き方はかなり参考になる。

```swift
.webAuthenticationSession(isPresented: $startingWebAuthenticationSession) {
    WebAuthenticationSession(
        url: URL(string: "https://github.com/login/oauth/authorize")!,
        callbackURLScheme: "github"
    ) { callbackURL, error in
        print(callbackURL, error)
    }
    .prefersEphemeralWebBrowserSession(false)
}
```

これは要するに`isPresented`の値が true であれば`WebAuthenticationSession()`が呼び出され、それが閉じるときに callBakcURL と error が返ってくるという仕組みになっている。

これはまさに求めていた仕様そのものである。

この部分を実装する[ソースコード](https://github.com/stleamist/BetterSafariView/blob/main/Sources/BetterSafariView/WebAuthenticationSession/WebAuthenticationSession.swift)を読んでみたのだが、正直言ってちんぷんかんぷんだった。

```swift
public init(
    url: URL,
    callbackURLScheme: String?,
    completionHandler: @escaping (_ callbackURL: URL?, _ error: Error?) -> Void
) {
    self.url = url
    self.callbackURLScheme = callbackURLScheme
    self.completionHandler = completionHandler
}
```

重要となるのはここで、イニシャライザで completionHandler を指定しているのがわかる。で、ここまではわかるのだ。

`self.completionHandler`に`completionHandler`をくっつけているのだが、`self.completionHandler`というのがよくわからないのである。

ソースコードを見るとこう書いてある。

```swift
public typealias CompletionHandler = ASWebAuthenticationSession.CompletionHandler // <- CompletionHandler
/// A completion handler for the web authentication session.
public typealias OnCompletion = (_ result: Result<URL, Error>) -> Void

// MARK: Representation Properties

let url: URL
let callbackURLScheme: String?
let completionHandler: CompletionHandler // <- CompletionHandler
```

`typealias`というのは C++でいうところの`define`のようなものだと勝手に思っている。つまり、上のコードは以下のコードと等価ということになる。

```swift
let completionHandler = ASWebAuthenticationSession.CompletionHandler
```

だが困ったことに作ろうとしている`PasscodeLockView`にはこのような completionHandler が存在しない。どうしたらいいのだろうか。

## 発展させる

ここまでの話は単にパスコードを入力するだけの機能を考えた場合の話である。実際にはもっと複雑なリクエストが要求される。

例えば[PasscodeLock](https://github.com/yankodimitrov/SwiftPasscodeLock)では`Enter`、`Set`、`Change`、`Remove`の四つのモードがサポートされている。

これらはそれぞれ

- Enter
  - パスコードを入力して一致するかチェックする
- Set
  - 新たにパスコードを入力する
  - 古いパスコードは要求されない
- Change
  - 設定されたパスコードを変更する
  - 古いパスコードが要求される
- Remove
  - パスコードを入力する
  - キャンセルで処理を中断させられる

といった違いがある。Remove に関しては Enter とほとんど同じなのでここでは無視できるとして、これを SwiftUI に拡張しつつ使いやすさも兼ねたライブラリにするためには、

- Enter
  - 引数
    - 現在のパスコード
    - 生体認証を使うかどうかのフラグ
  - 返り値
    - パスコードと一致したかどうか
- Set
  - 引数なし
  - 返り値
    - 設定された新たなパスコード
- Change
  - 引数
    - 現在のパスコード
  - 返り値
    - 再設定されたパスコード
    - パスコードと一致したかどうか
    - のどちらか（これは Result を使えば対応可能）

というような仕様を満たせば良いことになる。つまり、例えば以下のような実装が考えられる。

```swift
// Enter
PasscodeEnterView(passcode: passcode, withBiometrics: true) { result in
    // 成功したかどうかのフラグresultによって処理を変える
}

PasscodeSetView() { result in
    // resultに新たなパスコードが入っている
}

PasscodeChangeView(passcode: passcode) { result in
    // 成功したかどうかのフラグresultによって処理を変える
}
```

これらはまとめしまっても良いだろう。

```swift
// Enter
PasscodeView(state: .enter, passcode: passcode, withBiometrics: true) { result in
    // 成功したかどうかのフラグresultによって処理を変える
}

// Set
PasscodeView(state: .set) { result in
    // 成功したかどうかのフラグresultによって処理を変える
}

// Change
PasscodeView(state: .change, passcode: passcode) { result in
    // 成功したかどうかのフラグresultによって処理を変える
}
```

`withBiometrics`はオプショナルでデフォルト値をオフにしておけばいいし、`set`では旧パスコードは不要だが無視するようにすればいい。

より良いのはイニシャライザを複数用意することだろう。

が、結局これは完了ハンドラが呼べないと使えない。

## 完了ハンドラを書いてみよう

書き方が合っているのかどうかはわからないんが、一応完了ハンドラ的なものは書けた。

以下はパスコードを入力して設定されたものと同じであれば`Result`として`success`を返し、間違っていれば`failure`を返すようなものである。

```swift
import SwiftUI

struct ContentView: View {

    // 完了ハンドラを決定する
    typealias CompletionHandler = (Result<Bool, Error>) -> Void
    let completionHandler: CompletionHandler

    // パスコードは5にしておく
    private var passcode: Int = 5

    init(completionHandler: @escaping CompletionHandler) {
        self.completionHandler = completionHandler
    }

    var body: some View {
        GeometryReader { geometry in
            LazyVGrid(columns: Array(repeating: .init(.flexible(minimum: 60, maximum: 80), spacing: 0), count: 3), alignment: .center, spacing: 10, pinnedViews: []) {
                ForEach(Range(1...9)) { number in
                    Button(action: { addSign(sender: number)}, label: { Text("\(number)").frame(width: 60, height: 60, alignment: .center) })
                        .overlay(Circle().stroke(Color.blue, lineWidth: 1))
                }
                .buttonStyle(CircleButtonStyle())
                Button(action: { biometricsAuth() }, label: { Image(systemName: "touchid").resizable().frame(width: 40, height: 40, alignment: .center) })
                Button(action: { addSign(sender: 0) }, label: { Text("0").frame(width: 60, height: 60, alignment: .center) })
                    .buttonStyle(CircleButtonStyle())
                Button(action: {}, label: { Text("Delete").frame(width: 60, height: 60, alignment: .center) })
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .edgesIgnoringSafeArea(.all)
        .background(Color.white)
    }

    func addSign(sender: Int) {
        // ボタンを押したときの処理
        if sender == passcode {
            // 一致していればSuccess(True)を返す
            completionHandler(.success(true))
        } else {
            // 一致していなければSuccess(False)を返す
            completionHandler(.success(false))
        }
    }
}

// ボタンをかっこよくするためだけのコード
struct CircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? Color.white : Color.blue)
            .overlay(Circle().stroke(Color.blue, lineWidth: 1))
            .contentShape(Circle()
            .background(Circle().foregroundColor(configuration.isPressed ? Color.blue : Color.clear))
    }
}
```

ここで大事なのは「一致していなければエラーを返す」というわけではないということである。あくまでもエラーというのは想定していない挙動をしたときに返すべきである。

なので、パスコードが一致しなかった場合にはパスコードチェックプロセスは正しく動作したが、パスコードが間違っていたという意味で`success(false)`を返す方が良いのではないかと考えた。

で、めちゃくちゃ話がとぶのだがこのコードを書けるようになるまでに随分苦労した。このような処理が必要になる場面は多々あると思うのだが、"SwiftUI completion"、"SwiftUI closure"などと探しても全く参考文献が見つからないのだ。

まじでこれどうやって書くんだと悩んでいたとき、ふと BetterSafariView のコードを見ていてひらめいたのである。

```swift
public typealias CompletionHandler = ASWebAuthenticationSession.CompletionHandler // <- CompletionHandler
/// A completion handler for the web authentication session.
```

この部分で CompletionHandler を設定しているのだが、`ASWebAuthenticationSession.CompletionHandler`はあくまでも ASWebAuthenticationSession の完了ハンドラなので使えない。が、完了ハンドラ自体を自分で定義すればよいのではないかと。

この完了ハンドラ自体は[Apple のドキュメント](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession/completionhandler)に載っていたのですぐに特定できた。

すると、これは単に以下のコードであることがわかった。要するに、完了ハンドラはこう書けばいいのである。

```swift
public typealias CompletionHandler = (URL?, Error?) -> Void
```

そしてこのコードを見ていてふと思い出したのが[この部分の謎コード](https://github.com/tkgstrator/PasscodeLock/blob/267257eefe9d266d688b7b02f74aabe5b1c05730/PasscodeLock/PasscodeLockViewController.swift#L39)でした。

コピペせずに頑張って手打ちしていたのが功を奏したと言えます。コピペしていたら記憶に残ることはなかったでしょう。
