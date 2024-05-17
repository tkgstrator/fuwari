---
title: 非同期処理と同期処理
published: 2021-05-17
description: Swiftで非同期処理と同期処理を扱います
category: Programming
tags: [Swift]
---

## 非同期処理と同期処理

非同期処理と同期処理の考え方は非常にややこしくて、この記事を執筆している現在でもよくわかっていません。

あくまでも自分なりの考え、納得の仕方なので本来の仕様とは違うのかもしれないですが、いろいろなコードを書いてどのように実行されるか考えていきましょう。

なお、スレッド処理については[前回の記事](https://tkgstrator.work/posts/2021/05/17/threadsleep.html)で軽く解説しているので先に目を通しておくと良いかもしれません。

## 逐次処理と並列処理

ややこしいのが非同期処理と同期処理とは別に逐次処理（Serial）と並列処理（Concurrent）があるというところです。

### 逐次処理

一度に一つのタスクが実行されることを保証する。ただし、全てのタスクが同一のスレッドで実行されるとは限らない。

::: tip 逐次処理について

例えばあるループを逐次処理で行うと、0 番目、1 番目、2 番目の順に Queue に追加されていく。逐次処理なので 1 番目の処理は 0 番目が終わるまで開始されないことが保証される。

当然、出力も 0 番目からのように順序が保存される。

:::

### 並列処理

一度に一つ以上のタスクが実行される。ただし、処理の順番は Queue に追加された順に行われる。

::: tip 並列処理について

例えばあるループを逐次処理で行うと、0 番目、1 番目、2 番目の順に Queue に追加されていく。並列処理なので 1 番目が実行されるのは 0 番目より後だが、0 番目が終了するのを待たずに 1 番目が実行される。

0 番目の処理が重かった場合には 1 番目の出力が先に行われることも当然ある。

:::

##

### 並列処理 + Async

このコードは以下のように動作する。

- メソッドが呼ばれる
- 10 回のループが一瞬で実行される（重い処理がないため）
  - 10 個の Queue が追加される
- 0 番目から実行されるが、0 番目の終了を待たずに 1 番目が実行される
  - 今回は処理の内容が軽いので基本的には実行された順に出力されるが、たまにズレたりする（並列処理なので当然）

```swift
import SwiftUI

struct ContentView: View {
    @State var dateList: [String] = []
    // 並列処理のQueueを作成
    let queue = DispatchQueue(label: "work.tkgstrator.dispatch_queue_serial", attributes: .concurrent)

    var body: some View {
        List {
            ForEach(dateList, id:\.self) { date in
                Text(date)
            }
        }
        Button(action: { runDispatchQueue() }, label: {
            Text("Run")
        })
    }

    private func runDispatchQueue() {
        dateList.removeAll(keepingCapacity: true)
        for loop in 0 ..< 10 {
            queue.async {
                dateList.append("\(loop) -> on \(Thread.current)")
                print("\(loop) -> on \(Thread.current)")
            }
        }
    }
}
```

以下の出力結果を見ればわかるのですが、違うスレッドで処理が実行されており、その順番もバラバラであることがわかります。

```
1 -> on <NSThread: 0x6000027c2100>{number = 3, name = (null)}
2 -> on <NSThread: 0x6000027e4680>{number = 11, name = (null)}
4 -> on <NSThread: 0x6000027e4680>{number = 11, name = (null)}
0 -> on <NSThread: 0x6000027e6440>{number = 6, name = (null)}
6 -> on <NSThread: 0x6000027e4680>{number = 11, name = (null)}
8 -> on <NSThread: 0x6000027e6440>{number = 6, name = (null)}
3 -> on <NSThread: 0x6000027c2100>{number = 3, name = (null)}
7 -> on <NSThread: 0x6000027d04c0>{number = 9, name = (null)}
5 -> on <NSThread: 0x6000027d81c0>{number = 5, name = (null)}
9 -> on <NSThread: 0x6000027e4680>{number = 11, name = (null)}
```

::: warning SwiftUI との兼ね合いについて

実際に実行してみればわかるのだが、リストが正しく 10 件表示されるときと 10 件表示されないときある。これはメソッドの実行間隔が速すぎることに起因していると思われる。

つまり、SwiftUI が@State の値の変化をチェックしてビューを再描画するのが間に合っていないということになる。これ、どうやって対応すればいいんでしょうね。

:::

### 並列処理 + Sync

このコードは以下のように動作する。

- メソッドが呼ばれる
- 10 回のループが一瞬で実行される（重い処理がないため）
  - 10 個の Queue が追加される
- 処理がメインスレッドで行われる
  - メインスレッドは一つしかないので逐次実行される

```swift
private func runDispatchQueue() {
    dateList.removeAll(keepingCapacity: true)
    for loop in 0 ..< 10 {
        queue.sync {
            dateList.append("\(loop) -> on \(Thread.current)")
            print("\(loop) -> on \(Thread.current)")
        }
    }
}
```

出力は順番が保存され、メインスレッドで実行されていることがわかる。

```
0 -> on <NSThread: 0x600000188540>{number = 1, name = main}
1 -> on <NSThread: 0x600000188540>{number = 1, name = main}
2 -> on <NSThread: 0x600000188540>{number = 1, name = main}
3 -> on <NSThread: 0x600000188540>{number = 1, name = main}
4 -> on <NSThread: 0x600000188540>{number = 1, name = main}
5 -> on <NSThread: 0x600000188540>{number = 1, name = main}
6 -> on <NSThread: 0x600000188540>{number = 1, name = main}
7 -> on <NSThread: 0x600000188540>{number = 1, name = main}
8 -> on <NSThread: 0x600000188540>{number = 1, name = main}
9 -> on <NSThread: 0x600000188540>{number = 1, name = main}
```

ただし、メインスレッドで実行しているので`Queue.sync`内に重い処理があった場合はフリーズする。

```swift
// 10秒間フリーズするコード
private func runDispatchQueue() {
    dateList.removeAll(keepingCapacity: true)
    for loop in 0 ..< 10 {
        queue.sync {
            dateList.append("\(loop) -> on \(Thread.current)")
            print("\(loop) -> on \(Thread.current)")
            Thread.sleep(forTimeInterval: 1)
        }
    }
}
```

### 逐次処理 + Async

これはグローバルスレッドで処理が実行され、逐次実行なので順番が保存される。

また、この場合は SwiftUI で正しく検知できるのかリストの要素数が減ったりすることもない。

グローバルスレッドなので重い処理を挟んでもフリーズすることがない。

```swift
// 並列処理から逐次処理に切り替え
// let queue = DispatchQueue.global(qos: .utility)
let queue = DispatchQueue(label: "work.tkgstrator.dispatch_queue_serial")

private func runDispatchQueue() {
    dateList.removeAll(keepingCapacity: true)
    for loop in 0 ..< 10 {
        queue.async {
            dateList.append("\(loop) -> on \(Thread.current)")
            print("\(loop) -> on \(Thread.current)")
        }
    }
}
```

### 逐次処理 + Sync

これは並列処理 + Sync をしているのと全く同じ結果が得られる。

つまり、メインスレッドで実行され、順番も保存されるが重い処理を書くとフリーズする。メインスレッドで実行されるときは、重い処理を書くとフリーズするというのは覚えておこう。

```swift
// 並列処理から逐次処理に切り替え
// let queue = DispatchQueue.global(qos: .utility)
let queue = DispatchQueue(label: "work.tkgstrator.dispatch_queue_serial")

private func runDispatchQueue() {
    dateList.removeAll(keepingCapacity: true)
    for loop in 0 ..< 10 {
        queue.sync {
            dateList.append("\(loop) -> on \(Thread.current)")
            print("\(loop) -> on \(Thread.current)")
        }
    }
}
```

## まとめ

ここまでをまとめると以下の通り。

SwiftUI で使う場合には`Serial + Async`の組み合わせが良いのかもしれませんね。

|                        |                               非同期（Async）                                |                    同期（Sync）                    |
| :--------------------: | :--------------------------------------------------------------------------: | :------------------------------------------------: |
|     逐次（Serial）     |              グローバルスレッド<br>順番は保存される<br>正常動作              | メインスレッド<br>順番は保存される<br>フリーズする |
| 並列処理（Concurrent） | グローバルスレッド<br>順番は保存されない<br>SwiftUI が検知できない場合がある | メインスレッド<br>順番は保存される<br>フリーズする |

```

```
