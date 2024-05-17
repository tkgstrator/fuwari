---
title: Swiftにおけるデバイスの向き判定
published: 2022-12-12
description: Swiftでデバイスの向きを取得しようとするといろいろとややこしいので備忘録として残しておきます
category: Programming
tags: [Swift]
---

## Swift でデバイスの向きを正しく取得するには

Swift ではデバイスの傾きを取得するプロパティとして、

- `UIInterfaceOrientation`
- `UIDeviceOrientation`
- `AVCaptureVideoOrientation`

の三つが存在します。以下、それぞれの対応表と Enum での値を載せておきます。これ、いつもめっちゃ忘れるのでちゃんと覚えておきたいですね。

|                    | UIInterfaceOrientation | UIDeviceOrientation | AVCaptureVideoOrientation |
| :----------------: | :--------------------: | :-----------------: | :-----------------------: |
|      unknown       |           0            |          0          |             -             |
|      portrait      |           1            |          1          |             1             |
| portraitUpsideDown |           2            |          2          |             2             |
|   landscapeLeft    |           3            |          3          |             4             |
|   landscapeRight   |           4            |          4          |             3             |
|       faceUp       |           -            |          5          |             -             |
|      faceDown      |           -            |          6          |             -             |

### UIInterfaceOrientation

`UIInterfaceOrientation`は簡単に言うとステータスバーの向きです。なのでデバイスが上を向いているか下を向いているかの判定`faceUp`や`faceDown`はありません。ステータスバーが表示されれば値はとってこれるのですが、それまでは`unknown`が入っています。

なので`viewDidLoad`などで呼び出すと多分`unknown`が入っていて意味のあるデータが取れません。ステータスバーを非表示にしているときはどうなるんでしょう。

> 調べたところどうも`viewDidAppear`以降に呼ぶと良いらしい。

#### 取得方法

iOS13 以降は`UIWindowScene`を使えとのことなのでちょっとめんどくさいですが`UIApplication`の`extension`を使って実装します。

```swift
extension UIApplication {
  var foregroundScene: UIWindowScene? {
    UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive})
  }
}
```

このような計算プロパティを設定した上で、

```swift
func getCurrentDeviceOrientation() -> UIInterfaceOrientation {
  guard let orientation: UIInterfaceOrientation = UIApplication.shared.foregroundScene?.interfaceOrientation else {
    return .unknown
  }
  return orientation
}
```

とすればとってこれます。ないときが存在するので、そのときは適当に`unknown`でも設定してしまうのが良いでしょう。

#### 傾き検出

`UIInterfaceOrientation`が変化するときは画面がぐるっとまわるようなアニメーションが発生するのですが、その際に`viewWillTransition`が呼ばれるのでこれをオーバーライドしてしまえばステータスバーの回転を検出することができます。

```swift
override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    guard let orientation: UIInterfaceOrientation = UIApplication.shared.foregroundScene?.interfaceOrientation else {
        return
    }
}
```

### UIDeviceOrientation

`UIDeviceOrientation`が実際に言うところの正しいデバイスの向きを取得します。ただし、ジャイロで向きを判定しているのでアプリを起動してから一度もデバイスを傾けていない状態では`unknown`が入ってしまいます。

なので起動直後は`UIInterfaceOrientation`の方が正しいデータが取れます。起動時に下向きにしている人とかはいないと思うので、多分。

#### 取得方法

`UIInterfaceOrientation`と違って簡単にとってこれます。

```swift
UIDevice.current.orientation
```

#### 値の設定

```swift
UIDevice.current.setValue(3, forKey: "orientation")
```

#### 設定値の制限

`UIViewController`を継承しているクラスで`supportedInterfaceOrientation`をオーバーライドすれば各 View ごとに対応している向きを固定できるらしいです。

```swift
override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
  return .all
}
```

なお、`AppDelegate`でも同じような事ができる模様。

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
    return .all
  }
}
```

#### 傾き検出

`UIDeviceOrientation`の値が変わったかどうかは`UIDeviceOrientationDidChangeNotification`を使うことで取得できます。

で、昔から使われているのがこの手法です。ただ、個人的には`selector`とか`@objc`とかの記法が全く好きではないのでこれ以外を使いたいなあと思っています。

```swift
class ViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    NotificationCenter.default.addObserver(
    self,
    selector: #selector(ViewController.orientationChanged),
    name: UIDevice.orientationDidChangeNotification,
    object: nil)
  }

  @objc func orientationChanged() {
    // 処理を書く
  }
}
```

### AVCaptureVideoOrientation

`AVCaptureVideoOrientation`はカメラの向きです。何故かこれだけ`landscapeLeft`と`landscapeRight`の`rawValue`の値が逆になっています。こういう頭のおかしい設計、誰が許可したんですか。
