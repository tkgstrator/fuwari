---
title: Alignmentが全然わからん
published: 2021-05-12
description: SwiftUIでのAlignmentについての調査をまとめてみました
category: Programming
tags: [Swift]
---

## SwiftUI における Alignment とは

Alignment とは要するに「右揃え」「中央揃え」「左揃え」のようなテキストやオブジェクトなどのグループをどこを基準に揃えるかというパラメータのことである。

で、Alignment については[こちらの記事](https://qiita.com/shiz/items/0c41d20a2cb7b0748875)ででまとめてくれていたりする。

ただ、それを読んだだけでは自分がしっかりと理解できなかったのでその解説となります。

## コードから理解する

各コードと、その時どんなふうに描画されるかを確認して見ましょう。

```swift
// 基本コード
import SwiftUI
import PlaygroundSupport

struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
    }
}

PlaygroundPage.current.liveView = UIHostingController(rootView: ContentView())
```

::: tip コードについて

以後、これの`body`だけを変えたものを書いていきます。

:::

### Text を Stack 要素に入れる

以下の四つは全く同じ見た目になります。つまり、Stack 内に入れるデータが一つしかない場合は見た目の変化が起こりません。

ちなみに見た目としては画面中央揃えでテキストが表示されます。

```swift
var body: some View {
    Text("Hello, world!")
}

var body: some View {
    HStack {
        Text("Hello, world!")
    }
}

var body: some View {
    VStack {
        Text("Hello, world!")
    }
}

var body: some View {
    ZStack {
        Text("Hello, world!")
    }
}
```

![](https://pbs.twimg.com/media/E1T3fUXVEAAvrFL?format=png)

|  テキストが一つ  |    -     |  HStack  |  VStack  |  ZStack  |
| :--------------: | :------: | :------: | :------: | :------: |
| 全体の Alignment | 中央揃え | 中央揃え | 中央揃え | 中央揃え |
| 文字の Alignment | 中央揃え | 中央揃え | 中央揃え | 中央揃え |

### Text 二つを Stack に入れる

テキストを二つ入れると、それぞれの Stack の特徴はでるようになりますが、やはり全体としては中央揃えになります。

なんでなんだろうなあと考えてみたのですが、HStack や VStack などは`body`に対して何の Alignment もかかっていないので変化しないのだと思います。

つまり、SwiftUI においては何もしなければ「中央揃え」が適用されるということになります。

![](https://pbs.twimg.com/media/E1T70nyVkAUEPXp?format=png)

|  テキストが二つ  |    -     |  HStack  |  VStack  |  ZStack  |
| :--------------: | :------: | :------: | :------: | :------: |
| 全体の Alignment | 中央揃え | 中央揃え | 中央揃え | 中央揃え |
| 文字の Alignment | 中央揃え | 中央揃え | 中央揃え | 中央揃え |

### Stack に Alignment をつける

オプションで各 Stack には`Container Alignment`をつけることができます。

ただし、HStack には`leading`はつけられませんし、VStack に`top`を指定することはできません。これってちょっと不便な気がするのですが、どうなんでしょう？

| Container Alignment | HStack | VStack | ZStack |
| :-----------------: | :----: | :----: | :----: |
|       leading       |   -    |   ○    |   ○    |
|       center        |   -    |   ○    |   ○    |
|      trailing       |   -    |   ○    |   ○    |
|         top         |   ○    |   -    |   ○    |
|       center        |   ○    |   -    |   ○    |
|       bottom        |   ○    |   -    |   ○    |

VStack のイメージはこんな感じで、何もしなければコンテナ自体の大きさは可変で中に入れる要素ピッタリの大きさまで広がります。

コンテナ自体の大きさが可変であるため「コンテナ内の上から順番に積み上げていく」という意味である`top`を指定することができないというわけです。

![](https://pbs.twimg.com/media/E1T_vyiUcAEEhTp?format=png)

しかし、SwiftUI には`Frame Alignment`というものがあるので、例えば`frame(height: 200)`などを指定してコンテナのサイズを固定させて上から積み上げていくというのは需要がありそうな気もします。

![](https://pbs.twimg.com/media/E1UA9hfUUAETs9b?format=png)

::: warning middle じゃないじゃん

何も考えずに垂直方向の中央揃えを middle って書いてましたが、実際には center になります。

:::

### Stack に Frame Alignment をつける

というわけで VStack に対して`Frame Alignment`を適用してみます。

```swift
var body: some View {
    VStack(alignment: .center) {
        Text("Hello, world!")
        Text("by tkgstrator.work")
    }
    .frame(alignment: .leading)
}
```

ただし、このコードだと`.frame(alignment: .leading)`は何の効果も持たず、`center`を指定した場合と全く同じ見た目になります。

ただし、以下のように`Frame Alignment`に対して`width`要素を付けると見た目が変わります。

```swift
var body: some View {
    VStack(alignment: .center) {
        Text("Hello, world!")
        Text("by tkgstrator.work")
    }
    .frame(width: 300, alignment: .leading)
}
```

何故なら VStack の幅は可変で常に内部のオブジェクトぴったりになるように大きさが変わっているからです。つまり、VStack（または HStack に対して）`Frame Alignment`だけを指定するのは全く意味がありません。ダグドリオに十万ボルトするくらい意味がないです。

![](https://pbs.twimg.com/media/E1UKtENUcAEney1?format=png)

::: tip Frame Alignment について

幅を指定しないときは VStack と Frame の幅は完全に一致しています。

なので、Frame 内で VStack を左寄せすることはできません。Frame 要素の幅を指定することで VStack を Frame 内で幅寄せすることができるようになるわけです。

:::

点線の部分は実際には見えないので、オブジェクトだけが左に寄ったように見えるわけです。

![](https://pbs.twimg.com/media/E1ULaWoVkAcOB-n?format=png)

```swift
// 確認用コード
var body: some View {
    VStack(alignment: .center) {
        Text("Hello, world!")
        Text("by tkgstrator.work")
    }
    .background(Color.gray.opacity(0.3))
    .frame(width: 200, alignment: .leading)
    .background(Color.red.opacity(0.3))
}
```

実際に表示してみるとこのようになります。赤い背景が Frame でが設定された上で全体の中央になっており（デフォルト）、灰色の背景の VStack が Frame 内で左寄せになり、その中のテキストが中央揃えになっていることがわかります。

## テキストで空文字を表示する

VStack はサイズを自動的に変えると説明したが、これが逆にめんどくさい仕様になる場合もある。

例えば、何かのフラグが有効のときだけ「有効」と表示し、そうでないときは何も表示しないようなコードを考える。

```swift
struct ContentView: View {
    @State private var isPresented: Bool = false

    var body: some View {
        VStack {
            VStack(alignment: .center) {
                Text("Hello, world!")
                Text("by tkgstrator.work")
                Text(isPresented ? "ENABLED" : "")
            }
            .background(Color.gray.opacity(0.3))
            .frame(height: 200, alignment: .top)
            .background(Color.red.opacity(0.3))
            Button(action: { isPresented.toggle() }, label: { Text("SWITCH") })
        }
        .background(Color.blue.opacity(0.3))
    }
}
```

これはボタンを押せば`isPresented`の値が切り替わり、切り替わる度にテキストが空文字から`"ENABLED"`の表示を交互に切り替えるプログラムである。
