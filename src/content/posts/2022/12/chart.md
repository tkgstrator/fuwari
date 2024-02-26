---
title: SwiftUI+Chart
published: 2022-12-16
description: SwiftUIでChartライブラリを使う方法についてまとめ
category: Programming
tags: [SwiftUI, Swift]
---

## Chart がきた

iOS には今まで標準ライブラリでチャートを表示させる方法がなく、外部ライブラリに依存しっぱなしだったのですがとうとう Swift にもチャートライブラリが実装されました。

正直、機能としてはまだまだ足りないところがあるのですが標準機能として実装されるのはありがたいですね。

今回は[Creating a chart using Swift Charts](https://developer.apple.com/documentation/charts/creating-a-chart-using-swift-charts)を読みながら、SwiftUI でチャートを実装させるための方法を学んでいこうと思います。

### チャートの種類

チャートには`Mark`と呼ばれるコンポーネントがあり、これでチャートを表現します。

- AreaMark
- LineMark
- PointMark
- RectangleMark
- RuleMark
- BarMark

実装されているのは上の六種類で、PieMark や DoughnutMark や RadarMark のようなものは存在しません。あればよかったんですけどね、残念です。

で、それぞれどんな実装が可能なのかを見ていきます。サンプルの画像は Apple のドキュメントから引っ張ってきました。

#### AreaMark

<img src="https://docs-assets.developer.apple.com/published/c5fa5deae23b091d5a8606f21c5805d6/AreaMark-1-macOS~dark@2x.png" style="margin: 0 auto !important" width="300">

```swift
init<X, Y>(
    x: PlottableValue<X>,
    y: PlottableValue<Y>,
    stacking: MarkStackingMethod = .standard
) where X : Plottable, Y : Plottable
```

株価とかに使えそうなやつですね。

<img src="https://docs-assets.developer.apple.com/published/745eadb11c0d7c616719bbe7130c81d4/AreaMark-2-macOS~dark@2x.png" style="margin: 0 auto !important" width="300">

これも積み重ねることができます。

<img src="https://docs-assets.developer.apple.com/published/2e1ac1899c0ebbf19d2e787459d1a61a/AreaMark-4-macOS~dark@2x.png" style="margin: 0 auto !important" width="300">

積み重ね方を変えるとこういう表現も可能という例。

#### LineMark

<img src="https://docs-assets.developer.apple.com/published/b29790cab797787fe63a31d15d92e549/LineMarkSwift.LineMarkLineChart~dark@2x.png" style="margin: 0 auto !important" width="300">

```swift
init<X, Y>(
    x: PlottableValue<X>,
    y: PlottableValue<Y>
) where X : Plottable, Y : Plottable
```

標準的なラインチャートって感じがします。

<img src="https://docs-assets.developer.apple.com/published/cf2687fb01fa446b1d7978a454be1cd9/LineMarkSwift.LineMarkMultiSeriesLineChart~dark@2x.png" style="margin: 0 auto !important" width="300">

線を増やすこともできます。

#### PointMark

<img src="https://docs-assets.developer.apple.com/published/b9db27a0921cc629bd474fc6bc302435/PointMarkSwift.PointMarkScatterChart~dark@2x.png" style="margin: 0 auto !important" width="300">

```swift
init<X, Y>(
    x: PlottableValue<X>,
    y: PlottableValue<Y>
) where X : Plottable, Y : Plottable
```

散布図とかに使えるやつです。

#### RectangleMark

<img src="https://docs-assets.developer.apple.com/published/57a02799373e7e71edea0c1ed65d3c11/RectangleMarkSwift.RectangleMarkHistogramHeatmap2D~dark@2x.png" style="margin: 0 auto !important" width="300">

```swift
init<X, Y>(
    x: PlottableValue<X>,
    yStart: PlottableValue<Y>,
    yEnd: PlottableValue<Y>,
    width: MarkDimension = .automatic
) where X : Plottable, Y : Plottable
```

使い所がよくわからないグラフの一つ。

#### RuleMark

<img src="https://docs-assets.developer.apple.com/published/5789935e81ddfbaf89402588427dca03/LineSegmentMarkSwift.LineSegmentMarkHorizontalLineSegmentChart~dark@2x.png" style="margin: 0 auto !important" width="300">

```swift
init<X, Y>(
    x: PlottableValue<X>,
    yStart: PlottableValue<Y>,
    yEnd: PlottableValue<Y>
) where X : Plottable, Y : Plottable
```

これもいまいち使い所がわかっていないです。幅をもたせたいときに使う感じでしょうか。

#### BarMark

<img src="https://docs-assets.developer.apple.com/published/02c5bc3881285969d1e06928d5f9389b/BarMarkSwift.BarMarkBarChart~dark@2x.png" style="margin: 0 auto !important" width="300">

```swift
init<X, Y>(
    x: PlottableValue<X>,
    yStart: PlottableValue<Y>,
    yEnd: PlottableValue<Y>,
    width: MarkDimension = .automatic
) where X : Plottable, Y : Plottable
```

標準的なバーチャートです。使い所は多いはず。サンプルはこの向きですが、X 軸と Y 軸の反転や積み重ねなどもできます。

<img src="https://docs-assets.developer.apple.com/published/bc30459294f7df472e52e16f5422ae59/BarMarkSwift.BarMarkStackedBarChartWithForegroundColor~dark@2x.png" style="margin: 0 auto !important" width="300">

### PlottableValue

で、チャートを表現するために必要なのがこの`PlottableValue`という謎の構造体。

```swift
struct PlottableValue<Value> where Value: Plottable {
}
```

定義を見てみるとこんな感じで、要は`Plottable`に適合すれば良いらしいので、`Plottable`を調べると、

> You can plot Plottable data values with marks with `.value(label, keyPath)`:

とでてきます。なんでこんなややこしいことになっているのかとも思ったのですが、よくよく考えれば理にかなっている気もします。

例えばラインチャートを使って以下の画像のようなものを表示させることを考えます。

<img src="https://docs-assets.developer.apple.com/published/b29790cab797787fe63a31d15d92e549/LineMarkSwift.LineMarkLineChart~dark@2x.png" style="margin: 0 auto !important" width="300">

このときに必要なのは`x`の値を`y`の値を持つ構造体の配列です。なので以下のようなコードを使って`Entry`を定義して、その配列を渡せばチャートの表示に必要なデータとしては十分なわけです。

```swift
struct Entry<T: BinaryFloatingPoint> {
  let x: T
  let y: T
}

let entries: [Entry] = []

var body: some View {
    Chart(entries, content: {
        LineMark(
            x: .value(x)),
            y: .value(y))
        )
    })
}
```

あれ、じゃあデータが一つ増えて二本の線を引くことになったらどうすればいいんだとなりますね。

<img src="https://docs-assets.developer.apple.com/published/cf2687fb01fa446b1d7978a454be1cd9/LineMarkSwift.LineMarkMultiSeriesLineChart~dark@2x.png" style="margin: 0 auto !important" width="300">

バカ正直に考えると`entries`を二次元配列にして、二回描画するとかなるわけですがそれだと無駄にコードが複雑化してしまいます。

じゃあどうするのかというと`entries`自体は弄らずに、線を区別するための情報を`Entry`にもたせます。例として、以下のコードでは`type`で区別するようにしました。

```swift
struct Entry<T: BinaryFloatingPoint> {
  let x: T
  let y: T
  let type: Int
}

let entries: [Entry] = []

var body: some View {
    Chart(entries, content: { entry in
        LineMark(
            x: .value(entry.x)),
            y: .value(entry.y))
        )
        .foregroundStyle(by: .value(entry.type))
    })
}
```

`foregroundStyle`というのはまあ簡単に言えばカテゴリ分類みたいな感じです。上のコードでは簡略化のためにラベルを省略していますが、本来の`Plottable`はラベルと値を組み合わせたプロトコルなので、ラベルのデータも必要になります。

とはいえ、使う場面があまりないのでなくてもいいのかもしれません。いや、多分要るけど理解ができてなさすぎて使う場面がわからないだけなんですけれど。
