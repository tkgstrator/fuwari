---
title: iOSで生体認証ロックを作ろう
published: 2021-04-13
description: iOSで生体認証を使ったセキュリティシステムをつくる
category: Programming
tags: [Swift]
---

## iOS における生体認証

iOS では FaceID と TouchID の二つの生体認証がパスコード認証とは別に利用できる。

今回はその生体認証をアプリに組み込む方法について学ぶ。まず前提として、パスコードを含めた認証システムを使うには`import LocalAuthentication`を読み込む必要がある。

### 認証のプロセス

- 生体認証が可能かどうかチェックする
  - ここでパスコード認証を許可するかどうかを設定できる
- 可能であれば生体認証を行なう
  - または生体認証をキャンセルしてパスコード認証を行なう

パスコード認証を許可するかどうかのフラグが何故あるかというと、iPhone5 以前のデバイスでは TouchID や FaceID が使用不可であり、そもそもそれ以降のデバイスでも生体認証を登録していないユーザがいるためである。

というわけで、全通りパターン分けをするとこのようになる。

```swift
func biometricsAuth() {
    let context = LAContext()
    let reason = "This app uses Touch ID / Face ID to secure your data."
    var authError: NSError?

    if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            if success {
                // 生体認証が成功した場合
            } else {
                // 生体認証が失敗した場合
            }
        }
    } else {
        // 生体認証ができない場合
    }
}
```

指紋認証のためのボタンは SF symbols で定義されている`touchid`というやつが使える。

## 前回のコードとくっつける

パスコード入力画面に追加して動作チェックをしてみる。

```swift
import SwiftUI
import LocalAuthentication

struct PasscodeView: View {

    typealias CompletionHandler = (Result<Bool, Error>) -> Void
    let completionHandler: CompletionHandler
    let passcode: Int

    init(passcode: Int, completionHandler: @escaping CompletionHandler) {
        self.completionHandler = completionHandler
        self.passcode = passcode
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
            // 認証画面を真ん中に表示
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .edgesIgnoringSafeArea(.all)
        .background(Color.white)
    }

    func addSign(sender: Int) {
        if sender == passcode {
            completionHandler(.success(true))
        } else {
            completionHandler(.success(false))
        }
    }

    func biometricsAuth() {
        let context = LAContext()
        let reason = "This app uses Touch ID / Face ID to secure your data."
        var authError: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                if success {
                    // 生体認証が成功した場合
                    print("SUCCESS")
                } else {
                    // 生体認証が失敗した場合
                    print("FAILURE")
                }
            }
        } else {
            // 生体認証ができない場合
            print("FAILURE")
        }
    }
}

struct CircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? Color.white : Color.blue)
            .overlay(Circle().stroke(Color.blue, lineWidth: 1))
            .contentShape(Circle())
            .background(Circle().foregroundColor(configuration.isPressed ? Color.blue : Color.clear))
    }
}
```
