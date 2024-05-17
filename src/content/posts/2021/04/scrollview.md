---
title: ScrollView + Reader
published: 2021-04-08
description: GeometryReaderやScrollViewReaderの使い方をメモした
category: Programming
tags: [Swift]
---

## ScrollViewReader

ScrollViewReader は iOS14 以降で使える List や ScrollView で使える便利な機能である。

## 自動スクロール

以下のコードは一見すると要素数 100 のリストを自動生成し、View を表示すると同時に 20 番目にジャンプするコードだが正しく動作しない。

```swift
var body: some View {
    ScrollViewReader { value in
        List {
            ForEach(Range(0...100)) { idx in
                Text("\(idx)")
            }
        }
        .onAppear() {
            value.scrollTo(20, anchor: .top)
        }
    }
}
```

この場合だと`value.scrollTo(20, anchor: .top)`の 20 は Hashable である必要があるのだが、List のそれぞれの要素について適切な ID が割り当てられていないからだ。

```swift
var body: some View {
    ScrollViewReader { value in
        List {
            ForEach(Range(0...100)) { idx in
                Text("\(idx)")
                    .id(idx)
            }
        }
        .onAppear() {
            value.scrollTo(20, anchor: .top)
        }
    }
}
```

このように適切に ID を割り当てれば View 表示と同時にジャンプする。ただ、このままだといきなりジャンプするのでアニメーションを挟んでゆったりとした動作にしたい場合には`withAnimation`を使えば良い。

`withAnimation`のネスト内で変数の値を変化させたとき、その変数の変化でビューの再描画が行われたときにアニメーションを発生させることができるようになる。

```swift
var body: some View {
    ScrollViewReader { value in
        List {
            ForEach(Range(0...100)) { idx in
                Text("\(idx)")
                    .id(idx)
            }
        }
        .onAppear() {
            withAnimation {
                value.scrollTo(20, anchor: .top)
            }
        }
    }
}
```

よって、完成するコードは上のようになる。

## 横スクロールを実装する

### TabView を使う

愚直な方法が TabView を利用する方法である。

```swift
struct ContentView: View {
    var body: some View {
        TabView(selection: $selection) {
            ForEach(Range(0...1000)) { idx in
                Text("CONTENT")
                    .tag(idx)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
    }
}
```

ただし、TabView は SwiftUI2.0 からはタブの状態を保持するようになったためデータをたくさん描画するタブを無数に生成するとメモリを大量に消費する。

画面下部に表示される Index を押せば一応画面は遷移できるが小さくて押しにくいので微妙だったりする。これは ScrollViewReader を組み合わせ上手くできる。

### ScrollView + LazyHStack を使う

Lazy なので呼び出されるまで画面を描画せず、そのためメモリを消費しにくいという利点がある。

ただ、横幅指定をしてもちょうど中央に来たときに止めることができないので真面目に実装しようとするとゴリゴリのコーディングが必要になる。TabView だけで 100 件くらいならなんとかなりそうなので、それ以上の表示を要求されるときだけで良いかもしれない。

次期バージョンで LazyHStack に step みたいな機能がついてくれると嬉しい。
