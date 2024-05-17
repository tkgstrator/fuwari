---
title: Pickerでチェックボックスが表示されないバグ
published: 2021-05-21
description: SwiftUIでビューを作成しているときに、Pickerが正しく動作しないバグに遭遇したので解決法をまとめました
category: Programming
tags: [Swift]
---

## Picker が正しく表示されない

Picker でチェックボックスが表示されないバグは[stack overflow](https://stackoverflow.com/questions/58103437/swiftui-picker-in-form-does-not-show-checkmark)でも報告されていて、いろいろ解決法が載っていますが、この方法では解決しません。

## バグについて

- 選択しているにも関わらずチェックマークが表示されない
- 選択範囲がおかしい
  - Form 内の Picker は全範囲にタップ判定があるのだが、このバグが発生するとラベルにしかタップ判定がない

### バグが発生しないコード

以下のコードは普通に動作する。

```swift
import SwiftUI

struct ContentView: View {
    @State var selection: FruitType = .apple
    private var timers = Array(FruitType.allCases)

    var body: some View {
        NavigationView {
            Form {
                Picker(selection: $selection, label: Text("Select")) {
                    ForEach(fruits, id:\.rawValue) {
                        Text($0.rawValue)
                    }
                }
            }
            .navigationTitle("Picker")
        }
    }
}

enum FruitType: String, CaseIterable {
    case apple
    case orange
    case banana
}
```

![](https://pbs.twimg.com/media/E15HulIVkAIKGQ_?format=png)

### バグを含むコード

以下のコードは実行すると Picker にバグが発生する。

```swift
import SwiftUI

struct ContentView: View {
    @State var selection: FruitType = .apple
    private var timers = Array(FruitType.allCases)

    var body: some View {
        NavigationView {
            Form {
                Picker(selection: $selection, label: Text("Select")) {
                    ForEach(fruits, id:\.rawValue) {
                        Text($0.rawValue)
                    }
                }
            }
            .navigationTitle("Picker")
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum FruitType: String, CaseIterable {
    case apple
    case orange
    case banana
}
```

![](https://pbs.twimg.com/media/E15HulHUUAM4aKR?format=png)

## バグの原因について

要するに`NavigationView`に`.buttonStyle(PlainButtonStyle())`がかかっていると`Form`内の`Picker`の表示がおかしくなってしまう。

なので、`.buttonStyle(PlanButtonStyle())`をネストの浅いところに書いてしまうのは良くない。特に、`WindowGroup`に書くと全ビューにスタイルが適応されて便利なのだが、もしも Picker を利用するつもりであれば`.buttonStyle()`を書く場所はしっかりと考えたほうが良い。

::: tip おまけ

iOS 向けの Style は以下の三つが使えるが、`DefaultButtonStyle`以外はバグが発生します。

:::

|                       |    バグ    |
| :-------------------: | :--------: |
|   PlainButtonStyle    |    発生    |
|  DefaultButtonStyle   | 発生しない |
| BorderlessButtonStyle |    発生    |


