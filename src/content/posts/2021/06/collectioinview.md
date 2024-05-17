---
title: SwiftUIでCollectionViewを実装する
published: 2021-06-07
description: SwiftUIでUIKit時代のCollectionViewを再現するための方法について解説
category: Programming
tags: [Swift, SwiftUI]
---

# CollectionView

CollectionView は UiKit では実装されていたものの、SwiftUI では消されてしまった悲しき存在の一つ。

ですが、SwiftUI2.0 で`LazyHGrid`が実装されたことによりそれっぽく CollectionView をつくることができるようになりました。

## 実装してみる

実装にあたり[こちらの記事](https://qiita.com/yuki_m/items/b2ee2f93e1eb94aaf079)を参考にさせていただきました。

### 主な仕様

- iOS14 のみで動作
  - `LazyHGrid`が iOS13 では実装されていないため
- 全てのページは同じ横幅を持つ
  - 読書アプリのようなものを想定
  - サイズが違う場合は参考ページのように`resizable()`を使えば良いと思います
- 画面を回転させた場合でも常に中央に表示される
  - 参考ページのコードでは回転時にレイアウトが崩れてしまうのでそれを修正しました

```swift
// ScrollViewのExtension
extension ScrollView {
    func paging(geometry: GeometryProxy, index: Binding<Int>, offset: Binding<CGFloat>, orientation: Binding<UIInterfaceOrientation>) -> some View {
        return self
            .content.offset(x: offset.wrappedValue)
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                guard let status = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation else { return }
                if !UIDevice.current.orientation.isFlat {
                    if (orientation.wrappedValue.isPortrait != status.isPortrait) || (orientation.wrappedValue.isLandscape != status.isLandscape) {
                        offset.wrappedValue = -(geometry.size.height + (UIApplication.shared.windows.first?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0)) * CGFloat(index.wrappedValue)
                        orientation.wrappedValue = status
                    }
                }
            }
            .gesture(DragGesture()
                        .onChanged({ value in
                            offset.wrappedValue = value.translation.width - geometry.size.width * CGFloat(index.wrappedValue)
                        })
                        .onEnded({ value in
                            let scrollThreshold = geometry.size.width / 2
                            if value.predictedEndTranslation.width < -scrollThreshold {
                                index.wrappedValue = min(index.wrappedValue + 1, 10)
                            } else if value.predictedEndTranslation.width > scrollThreshold {
                                index.wrappedValue = max(index.wrappedValue - 1, 0)
                            }
                            withAnimation {
                                offset.wrappedValue = -geometry.size.width * CGFloat(index.wrappedValue)
                            }
                        })
            )
    }
}
```

画面の回転に対応させるのがやたらとめんどくさかったです。要するに、`Portrait->Landscape`または`Landscape->Portrait`時にオフセットを再計算すればよいのですが、これを実装するためには「以前の状態」を保持しておく必要があります。

`paging()`内でもできるかもしれないのですが、わからなかったので今回は割愛してバカ正直に`@State`で保存するようにしました。

これで 180 度回転を含むどんな回転をさせてもちゃんと画面の中央に表示されます。

```swift
import SwiftUI

struct ContentView: View {
    @State private var index: Int = 0
    @State private var offset: CGFloat = 0
    @State private var orientation: UIInterfaceOrientation = .portrait

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHGrid(rows: Array(repeating: .init(.fixed(geometry.size.height)), count: 1), alignment: .center, spacing: 0, pinnedViews: []) {
                    ForEach(Range(0 ... 10)) { index in
                        Text("\(index)")
                            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                            .background(Color.red.opacity(0.3).edgesIgnoringSafeArea(.all))
                    }
                }
            }
            .paging(geometry: geometry, index: $index, offset: $offset, orientation: orientation)
        }
    }
}
```

::: tip 謎のオフセット 20 が入る現象

Notification が呼ばれた段階ではステータスバーの高さが無視されているのか、常に 20 だけ`geometry.size`がズレてしまう問題があった。

そのため、わざわざステータスバーの高さを取得してその分だけ余計に計算している。が、ステータスーバーを非表示にしていたらなんかズレそうな気もする。

:::

記事は以上。
