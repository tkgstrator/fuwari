---
title: iOSで生体認証ロックを作ろう
published: 2021-04-30
description: 生体認証を使ったロックの仕組みをつくる
category: Programming
tags: [Swift]
---

## 生体認証ロック

以前も記事で解説したのだが、Swift では`LocalAuthentication`をインポートするだけで簡単に生体認証の仕組みをつくることができる。

が、実際にはそれだけでは想定している動作が実現できないのでサンプルコードを使ってデモアプリを作成してみようと思う。

## 生体認証の仕様

生体認証を利用するアプリとしては高いセキュリティが要求される銀行系のアプリなどが考えられる。

例えばりそな銀行のアプリで確かめてみる。すると次のような仕様であることがわかった。

- ログイン画面で生体認証が自動で表示される
- 画面をバックグラウンドにして復帰するとパスコード画面が表示される
- ロックを解除すると最後にひらいていた画面が表示される

また、生体認証をキャンセルした場合次のような挙動を示した

- 生体認証をキャンセル
- 画面をバックグラウンドにしてから復帰すると再度生体認証が自動表示

大事になるのは「生体認証が自動で表示」と「バックグラウンドでロックがかかる」という点だと思われる。「生体認証が自動で表示」に関しては`onAppear`で対応できそうな気がするが「バックグラウンドでロックがかかる」というのはバックグラウンドに移行したことを検知できないと実装できない。どうやってその仕組みを実装するのだろうか。

## Environment をつかう

これも以前解説したのだが、SwiftUI にはいくつかの環境変数が自動でセットされている。あとはそれを呼び出すだけで使えるのである。

その中に`scenePhase`というものがあり、これは`active`、`inactive`、`background`の三つの状態のいずれかを保持している。これらを使えば上手く仕様を満たすことができそうだ。

## 生体認証フラグ

このアプリの仕様を満たすためには二つの生体認証フラグが必要になる。一つはデバイスが生体認証登録されているかという`isBiometricsAvailable`で、もう一つはアプリ自体で生体認証を有効化しているかという`isBiometricsEnabled`である。

指紋登録などをしていなければそもそもアプリで生体認証を有効化できないし、指紋登録をしていてもアプリで生体認証を使いたくないという場合が考えられるからだ。

で、ここで次のようなフローチャートを考える。

|    状態    | 生体認証 | パスコード認証 |
| :--------: | :------: | :------------: |
| Biometrics |    OK    |       OK       |
|   Enter    |    -     |       OK       |
|   Wrong    |    -     |       OK       |

### isBiometricsAvailable

生体認証が可能かどうかは`canEvaluatePolicy`で簡単に取得できる。

今回は計算プロパティにしているが、アプリの起動中にこれらが変わることは考えなくても良さそうなので、普通のプロパティにしておいてもいいかもしれない。

```swift
// AppLocker.swift
import Foundation
import SwiftUI
import LocalAuthentication

class AppLocker: Observablebject {
    private var isBiometricsAvailable: Bool {
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
}
```

### isBiometricsEnabled

次に、アプリ側で生体認証を有効化しているかどうかの状態をとってくる。これはひょっとしたらアプリ起動中に設定をころころ変えるかもしれないので常に最新の値をとってきて反映させられるように`@Published`で値をとってくるようにする。

```swift
// AppLocker.swift
import Foundation
import SwiftUI
import LocalAuthentication

class AppLocker: ObservableObject {
    @Published var isBiometricsEnabled: Bool = false
    private var isBiometricsAvailable: Bool {
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
}
```

更に、アプリがロックされているかどうかの状態も必要なのでそれも変数に加えておく。また、生体認証をするためのメソッドも必要なので追加しておこう

```swift
// AppLocker.swift
import Foundation
import SwiftUI
import LocalAuthentication

class AppLocker: ObservableObject {
    @Published var isAppLocked: Bool = false // アプリがロックされているか

    @Published var isBiometricsEnabled: Bool = false // 生体認証が有効化されているかどうか

    private var isBiometricsAvailable: Bool { // 生体認証が利用可能かどうか
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    func authorizeWithBiometrics() {
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "AUTHORIZED WITH BIOMETRICS") { (success, error) in
            print(success, error)
        }
    }
}
```

### メソッドに処理を入れる

このままだと`authorizeWithBiometrics()`で認証が成功しても何も反応がなくなってしまう。そこで、認証成功した場合には`isAppLocked`の値を`false`にする処理を追加する。

このとき、`isAppLocked`は`@Published`なのでメインスレッドでしか更新できないことに注意する。

```swift
// AppLocker.swift
func authorizeWithBiometrics() {
    let context = LAContext()
    context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "AUTHORIZED WITH BIOMETRICS") { [self] (success, error) in
        // メインスレッドで更新する
        DispatchQueue.main.async {
            if success {
                isAppLocked = false
            } else {
                // エラーの内容を表示
                print(error)
            }
        }
    }
}
```

## ここまでの概要

ここまでをまとめると以下のようなコードが完成する。

一見するとこれでうまくいきそうなのだが、実はバグが存在している。

### App.swift

```swift
// App.swift
import SwiftUI
import LocalAuthentication

@main
struct BiometricsApp: App {
    @StateObject var appLocker = AppLocker()
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appLocker)
                .onChange(of: scenePhase) { value in
                    switch value {
                    case .active:
                        // アクティブになったときに生体認証を表示
                        appLocker.authorizeWithBiometrics()
                    case .background:
                        appLocker.isAppLocked = true
                    case .inactive:
                        break
                    @unknown default:
                        print("UNKNOWN")
                    }
                }
        }
    }

}
```

### ContentView.swift

特に面白いことはせず、`AppHomeView()`に飛ばすだけの処理をする。

```swift
// ConentView.swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        AppHomeView()
    }
}
```

### AppHomeView.swift

```swift
// AppHomeView.swift
import SwiftUI

struct AppHomeView: View {
    @EnvironmentObject var appLocker: AppLocker

    var body: some View {
        ZStack {
            if !appLocker.isAppLocked {
                Text("HELLO, WORLD")
            } else {
                AppLockView()
            }
        }
        .onAppear {
            appLocker.authorizeWithBiometrics()
        }
    }
}
```

## scenePhase のバグ

scenePhase に由来するバグではないのだが、ここの判定はこのままでは意図しない動作を引き起こす。

というのも、この`scenePhase`の値が変化したチェックは`ContentView()`で行われているためである。つまり、生体認証画面のポップアップが表示された段階で`ContentView()`は`.inactive`になってしまい、

- `ContentView()`が表示
- `.active`になるので生体認証画面が表示
  - この時点で`ContentView()`が`.inactive`になる
  - 生体認証を終える
- `ContentView()`が`.active`になる

という処理が行われ、結果として何度認証を繰り返してもキャンセルしても無限に生体認証ダイアログが表示されてしまう。

これを回避するためには ContentView がバックグラウンドに移行した段階で何らかのフラグを設定し、生体認証を一回終えた時点でそのフラグを回収するような処理が考えられる。

```swift
// App.swift
import SwiftUI
import LocalAuthentication

@main
struct BiometricsApp: App {
    @StateObject var appLocker = AppLocker()
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appLocker)
                .onChange(of: scenePhase) { value in
                    switch value {
                    case .active:
                        if appLocker.isFirstLaunch {
                            appLocker.isFirstLaunch = false
                            appLocker.authorizeWithBiometrics()
                        }
                    case .background:
                        appLocker.isFirstLaunch = true
                        appLocker.isAppLocked = true
                    case .inactive:
                        break
                    @unknown default:
                        print("UNKNOWN")
                    }
                }
        }
    }

}
```

```swift
// AppLocker.swift
import SwiftUI
import LocalAuthentication

class AppLocker: ObservableObject {
    @Published var isAppLocked: Bool = true // アプリがロックされているか

    @Published var isBiometricsEnabled: Bool = false // 生体認証が有効化されているかどうか

    @Published var isFirstLaunch: Bool = true // 初回のチェックかどうかを調べる

    private var isBiometricsAvailable: Bool { // 生体認証が利用可能かどうか
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    func authorizeWithBiometrics() {
        if isFirstLaunch {
            isFirstLaunch.toggle()
            let context = LAContext()
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "AUTHORIZED WITH BIOMETRICS") { [self] (success, error) in
                DispatchQueue.main.async {
                    if success {
                        isAppLocked = false
                    } else {
                        print(success, error)
                    }
                }
            }
        }
    }
}
```

よって、上のようにコードを修正すれば「バックグラウンドから復帰したら生体認証表示」「画面が開いた直後に生体認証表示」の仕様を満たすことができる。
