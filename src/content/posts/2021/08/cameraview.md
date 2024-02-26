---
title: SwiftUIでCameraViewを利用する
published: 2021-08-27
description: SwiftUIでカメラを利用する方法について解説します
category: Programming
tags: [Swift, SwiftUI]
---

# [CameraView](https://gist.github.com/tkgstrator/2f8f3ecac3777808d69b929a474b5093)

SwiftUI ではデフォルトでカメラを利用する仕組みがないので、まずは SwiftUI でカメラを利用するためのコードを書きます。

上記のリンクから GitHub Gist へ飛べ、利用可能なコードが閲覧できます。まずはそれぞれのコードの役割を解説します。

- CameraManager.swift
  - Camera への設定を行う ObservableObject クラス
- CameraView.swift
  - SwiftUI から呼び出せる View
- CameraPreview.swift
  - UICameraView を SwiftUI で利用するための UIViewRepresentable
- UICameraView.swift
  - UIView を継承したカメラの映像を表示するためのクラス

このうち、CameraView.swift と CameraPreview.swift はほとんど完成しているので弄らなくて大丈夫です。

## デバイスの回転に対応する

デバイスの傾きとは別にカメラの向きというものがあり、デバイスの傾き=カメラの向きになっていないとビューに表示するカメラの画像の傾きがズレてしまいます。

### Orientation の種類

iOS で使えるデバイスの傾きは次の三種類で、カメラ機能以外では`UIDeviceOrientaion`と`UIInterfaceOrientation`の二つがあります。

これらの違いですが、`UIInterfaceOrientation`はステータスバーの向きを取得しているため起動時に何らかの値が入ります。

それに対して、`UIDeviceOrientation`はデバイスの傾きであるため`faceUp`と`faceDown`という二つの Orientation が余計にあります。また、アプリ起動時には`unknown`の値が入っており、デバイスを傾けるまで正しいデータを取得することができません。

なので、一般的にアプリケーションの UI をデバイスの向きで変更したいのであれば`UIInterfaceOrientation`を利用するべきでしょう。

|                    | AVCaptureVideoOrientation | UIDeviceOrientation | UIInterfaceOrientation |
| :----------------: | :-----------------------: | :-----------------: | :--------------------: |
|      unknown       |             -             |          0          |           0            |
|      portrait      |             1             |          1          |           1            |
| portraitUpsideDown |             2             |          2          |           2            |
|   landscapeRight   |             3             |          3          |           3            |
|   landscapeLeft    |             4             |          4          |           4            |
|       faceUp       |             -             |          5          |           -            |
|      faceDown      |             -             |          6          |           -            |

```swift
// UIDeviceOrientaion
let orientation: UIDeviceOrientation = UIDevice.current.orientation

// UIInterfaceOrientation
let orientation: UIInterfaceOrientation? = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
```

また、`AVCaptureVideoOrientation`にも`faceUp`と`faceDown`の Enum が存在しないので`UIInterfaceOrientation`を使って調整するほうが理にかなっていると言えます。

## 方針

さて、どうやってカメラデバイスとビューの傾きを揃えるかということなのですが、次の方法が考えられると思います。

### View を回転させる

SwiftUI の View は`rotateEffect()`で回転させることができます。これを利用して、デバイスの向きが変わる度に View 自体を回転させるという方法です。

View をいじるので、変更するのは CameraView.swift となります。

```swift
import Foundation
import SwiftUI

public struct CameraView: View {
    @StateObject var capture: CameraManager = CameraManager(deviceType: .builtInWideAngleCamera, mediaType: .video, position: .front)
    @State var rotation: Double = 0.0 // 追加

    public init() {}

    public var body: some View {
        GeometryReader { geometry in
            CameraPreview(previewFrame: CGRect(x: 0, y: 0, width: 300, height: 300), capture: capture)
                .frame(width: 300, height: 300, alignment: .center)
        }
        .onAppear(perform: capture.setupSession)
        .onDisappear(perform: capture.endSession)
    }
}
```

ここにデバイスが傾いたことをチェックするような仕組みを書けば良いので、`onReceive()`を利用します。

#### Extension

`UIInterfaceOrientaion`から回転させるべき角度を求める Extension を追加します。

```swift
// CameraManager.swift
extension UIInterfaceOrientation {
    var degree: Double {
        switch self {
        case .landscapeLeft:
            return 90
        case .landscapeRight:
            return -90
        case .portrait:
            return 0
        case .portraitUpsideDown:
            return 180
        case .unknown:
            return 0
        @unknown default:
            fatalError()
        }
    }
}
```

```swift
CameraPreview(previewFrame: CGRect(x: 0, y: 0, width: 300, height: 300), capture: capture)
    .frame(width: 300, height: 300, alignment: .center)
    .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification), perform: { value in
        if let orientation: UIInterfaceOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation {
            rotation = orientation.degree
        }
    })
    .rotationEffect(.degrees(rotation))
```

で、一応これで実装はできるのですが実際にやってみるとビューがぐるんぐるんして見た目が良くないです。

### UIView を回転させる

UIKit の UIView 自体を回転させるという方法です。UIView は`CATransform3DMakeRotation()`で回転させることができます。

`CATransform3DMakeRotation()`の引数は CGFloat なのでそこだけを書き換えます。

```swift
// CameraManager.swift
extension UIInterfaceOrientation {
    var degree: CGFloat {
        switch self {
        case .landscapeLeft:
            return 90
        case .landscapeRight:
            return -90
        case .portrait:
            return 0
        case .portraitUpsideDown:
            return 180
        case .unknown:
            return 0
        @unknown default:
            fatalError()
        }
    }
}
```

次に UICameraView.swift を変更します。

```swift
// UICameraView.swift
// SwiftUIでのonReceiveのようなもの
private func addOrientationChangeDetector() {
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(updatePreviewOrientation),
        name: UIDevice.orientationDidChangeNotification,
        object: nil
    )
}

// @objcで宣言する必要がある
// UIDevice.orientationDidChageNotificationを検知する度に実行される
@objc func updatePreviewOrientation() {
    guard let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation else { return }

    self.previewLayer.transform = CATransform3DMakeRotation(orientation.degree / 180 * CGFloat.pi, 0, 0, 1)
    self.previewLayer.frame = self.bounds // 場合によってはない方が良い
}
```

### カメラの傾きを変える

これが一番自然な方法です。先ほど作成した`updatePreviewOrientation()`内で View の向きを変えるのではなく、カメラの向きを変えるようにします。

```swift
// UICameraView.swift
@objc func updatePreviewOrientation() {
    guard let orientation: UIInterfaceOrientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation else { return }
    guard let videoOrientation: AVCaptureVideoOrientation = AVCaptureVideoOrientation(rawValue: orientation.rawValue) else { return }
    self.previewLayer.connection?.videoOrientation = videoOrientation
}
```

この実装方法だと View 自体は回転しないのでさっきよりはマシですが、やっぱり少し違和感があります。

というのも、iOS 標準のカメラであれば常にカメラの向きは固定で、ビュー自体が回転しているからです。

## [VideoGravity](https://developer.apple.com/documentation/avfoundation/avcapturevideopreviewlayer/1386708-videogravity)

```swift
func setupPreview(previewSize: CGRect) {
    self.frame = previewSize

    self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
    self.previewLayer.frame = self.bounds
    self.previewLayer.videoGravity = .resizeAspectFill
    self.layer.addSublayer(previewLayer)
}
```

最初に実装するときに一番苦労したのがここでした。SwiftUI でカメラを利用するときには取り込んだ映像を`previewLayer`に表示しているのですが、指定したサイズに上手く変換できなかったためです。

フレームのサイズはまあ簡単に変えられたのですが、アスペクト比を維持したまま View を埋めるのはどうすればよいのかと考えていたらそれは`videoGravity`で変えることができるとわかりました。

なんでプロパティ名が`videoGravity`なのかはさっぱりわかりません。普通に`aspectRatioMode`みたいなので良かったんじゃないかと思うのですが。

|                | resize | resizeAspect | resizeAspectFill |
| :------------: | :----: | :----------: | :--------------: |
|  アスペクト比  |  変更  |     維持     |       維持       |
| レイヤーサイズ | 満たす |  満たさない  |      満たす      |

`videoGravity`は上の三つから選ぶことができ、アスペクト比を変えたいというケースは稀だと思うのでまあ大体`resizeAspect`か`resizeAspectFill`を使うことになると思います。

今回は`resizeAspectFill`を利用しましたが、単に`resizeAspect`を使って画像の中央を指定したフレームで切り抜くような感じで実装するのも良いと思います。

## おまけ

実は[Apple 謹製の Swift 向けのカメラのコード](https://developer.apple.com/documentation/avfoundation/cameras_and_media_capture/avcam_building_a_camera_app)がのっているのだが、これを実行してもデバイスを回転させたときの挙動がおかしいことには代わりがない。

挙動が一番正しいのはカメラアプリなのだが、こちらは実装のコードがのっていないためどうやればこのように View を回転させることができるのかがわからない。
