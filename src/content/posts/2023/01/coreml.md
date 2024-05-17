---
title: Core MLについての備忘録
published: 2023-01-20
description: Core MLについて学習したのでそれをまとめます
category: Programming
tags: [Swift]
---

## Core ML とは

iOS11.0 以降使えるようになった機械学習用のモデルフレームワークのこと。

機械学習をデバイスで実行することのメリット

- データ送信の必要なし
- ネイティブ動作なので高速
- サーバー不要

ちょっと気になるのがネイティブ動作というところなのですが、最近のトレーニングモデルは GPGPU を利用することを前提としているものが多いので、CPU で実行するとアホみたいに時間がかかります。

### Real CUGAN NCNN Vulkan

例えば重いことで有名な Real CUGAN を実行してみます。Vulkan を利用して直接 GPU の API を叩いてもそれなりに重く、RTX3090 を利用しても一分間にたったの 183 フレームしか変換できません。普通のアニメであれば 1 秒に 25 フレームくらいあるので、60 秒かけて 7 秒分くらいしか変換できないわけです。

|     GPU      | 1080p to 2160p |
| :----------: | :------------: |
|   RTX3090    |      183f      |
|  Tesla P40   |      62f       |
| Quadro M1200 |      14f       |
|    RX480     |      10f       |

となると実時間の 12.5%くらいの速度しかないわけで、まあ重いと言われる所以がよくわかります。これを CPU などで実行していてはいくら時間があっても足りないわけですね。

ちなみに Vulkan 自体は M1 でもサポートされているので動作させることができます。

それでやってみると M1 Ultra を使ってみても 60 秒で 70~80f くらいしか変換できません。M1 Ultra の GPU 性能は RTX3090 の半分くらいと言われているのでまあまあ妥当なあたりだと思います。

## CoreML Models を使ってみる

[CoreML-Models](https://github.com/john-rocky/CoreML-Models)というところで有名どころのモデルが CoreML Model に変換されて配布されています。

使ってみたい Real CUGAN がないのですが、それの親戚みたいな Real ESRGUN のアニメーション専用のモデルがあるので利用してみます。

適当なことをぶっこいてるコードが多いので、ちゃんと動作するコードを載せておきます。

```swift
import Foundation
import Vision
import UIKit
import VideoToolbox

class MLTool {
    internal let request: VNCoreMLRequest

    init() {
        guard let model: VNCoreMLModel = try? VNCoreMLModel(for: real_esrgun_anime_x4(configuration: MLModelConfiguration()).model)
        else {
            fatalError("Model initialization failed.")
        }
        self.request = VNCoreMLRequest(model: model)
    }

    func convert(image: UIImage) -> CVPixelBuffer? {
        guard let buffer: CVPixelBuffer = image.asPixcelBuffer
        else {
            return nil
        }
        let handler: VNImageRequestHandler = VNImageRequestHandler(cvPixelBuffer: buffer, options: [:])
        try? handler.perform([request])
        guard let result: CVPixelBuffer = (request.results?.first as? VNPixelBufferObservation)?.pixelBuffer
        else {
            return nil
        }
        return result
    }
}
```

大事なところとしては、画像を CoreML Model に渡すときには`CVPixelBuffer`型ではないといけないことです。`FileManager`などで画像の URL を渡すことが多いと思うので、

入力は`URL -> Data -> UIImage -> CVPixelBuffer`という工程を通ることになります。`UIImage`から`CVPixelBuffer`への変換はサポートされていないので、自力で実装します。幸い、コードが stackoverflow に載っていたのでそれをそのまま採用します。

```swift
extension UIImage {
    convenience init?(buffer: CVPixelBuffer) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(buffer, options: nil, imageOut: &cgImage)

        guard let cgImage: CGImage = cgImage else {
            return nil
        }
        self.init(cgImage: cgImage)
    }

    fileprivate var asPixcelBuffer: CVPixelBuffer? {
        let width = self.size.width
        let height = self.size.height
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(width),
                                         Int(height),
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &pixelBuffer)

        guard let resultPixelBuffer = pixelBuffer, status == kCVReturnSuccess
        else {
            return nil
        }

        CVPixelBufferLockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(resultPixelBuffer)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(published: pixelData,
                                      width: Int(width),
                                      height: Int(height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(resultPixelBuffer),
                                      space: rgbColorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        else {
            return nil
        }

        context.translateBy(x: 0, y: height)
        context.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        return resultPixelBuffer
    }
}
```

これで`UIImage`から`CVPixelBuffer`への変換とその逆の`CVPixelBuffer`から`UIImage`への変換が実装できました、簡単ですね。

```swift
func testConvert() {
    let tool: MLTool = MLTool()
    guard let url: URL = Bundle(for: Self.self).url(forResource: "Test", withExtension: "png"),
          let published: Data = try? Data(contentsOf: url),
          let input: UIImage = UIImage(published: data)
    else {
        return
    }

    guard let buffer: CVPixelBuffer = tool.convert(image: input),
          let output: UIImage = UIImage(buffer: buffer)
    else {
        return
    }
    print(output)
}
```

最後に UnitTests ディレクトリに適当に`Test.png`というファイルを突っ込んでおいて、これを`URL -> Data -> UIImage`を経てトレーニングモデルに渡して変換します。

![](https://pbs.twimg.com/media/Fm1cuCaaEAQksYx?format=jpg&name=4096x4096)

というわけで、Xcode で変換済みの Core ML Model を使って画像をアップスケーリングすることはできました。

### 気になる点

- GPU を使って計算してくれるのか

シミュレータで実行するとアホみたいに時間がかかります。Neural Engine を積んでないからとかそんな理由かもしれません。

> iPad 6Gen だと全くテストが通らずに落ちたので(恐らくメモリ不足)、その公算は高いと思われる

ちなみに Neural Engine のリストは以下のような感じ。

|    CPU     | Cores | Ops/sec |
| :--------: | :---: | :-----: |
|    A11     |   2   | 600 億  |
|    A12     |   8   |  5 兆   |
|    A13     |   8   |  6 兆   |
|    A14     |  16   |  11 兆  |
|     M1     |  16   |  11 兆  |
|    A15     |  16   | 15.8 兆 |
| M1 Pro/Max |  16   |  11 兆  |
|  M1 Ultra  |  32   |  22 兆  |
|     M2     |  16   | 15.8 兆 |
|    A16     |  16   |  17 兆  |
| M2 Pro/Max |  16   | 15.8 兆 |

A15 搭載の iPhone 13 mini で実行したところメモリ消費量 108MB, CPU 使用率 3%であっという間に変換できたので、最近の CPU は速いなあと感激しています。

どうやら、特に何もしなくても Neural Engine が搭載されていれば CPU ではなく GPU を使って計算してくれるようです

## Core ML Models に変換する

基本的にほとんどすべてのネットワークはそもそも Core ML Models で利用されることを想定されていないので別の形式で配布されています。

とはいえ、有名所の以下の三つに関しては`CoreMLTools`というツールを使うことで変換可能です。

- TensorFlow 1.x
- TensorFlow 2.x
- PyTorch

TensorFlow は実際には Keras が使われることが多いと思うので、実際に対応しているのは以下のフレームワークらしいです。

### 環境を構築しよう

Pytorch モデルからの変換には`torch`, `torchvision`, `coremltools`の三つが必要になります。

具体的にどのバージョンを使えばよいのかは[Pytorch Vision Installation](https://github.com/pytorch/vision)に書かれています。Apple Silicon だと古いバージョンの Python がインストールできなかったりするので、とりあえず新しいものを選べば良いと思います。

ただ、新しすぎると`coremltools`が対応していないと表示されるので、自分は以下のバージョンを指定してインストールしました。

`python -m pip install coremltools==6.1 torch==1.12.0 torchvision==0.13.0`

とりあえずこれでエラーが出ずにコマンドが動いたので大丈夫だと思います。

```
certifi==2022.12.7
charset-normalizer==3.0.1
coremltools==6.0
idna==3.4
mpmath==1.2.1
numpy==1.20.0
packaging==23.0
Pillow==9.4.0
protobuf==3.20.1
requests==2.28.2
sympy==1.11.1
torch==1.12.1
torchvision==0.13.0
tqdm==4.64.1
typing_extensions==4.4.0
urllib3==1.26.14
```
