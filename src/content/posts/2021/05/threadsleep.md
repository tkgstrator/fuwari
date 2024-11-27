---
title: SwiftUIでスリープ機能を実装しよう
published: 2021-05-17
description: ある処理を行ったときに連続で処理することを防ぐためにスリープする方法を考えます
category: Programming
tags: [Swift]
---

## スリープ処理は難しい

アプリを開発しているうえで必要になってくるのが、なにか重い処理をしたときにそれが外部端末あるいはサーバに負荷がかかることを防ぐために短期間での同時アクセスをしないようにするという仕組みである。

アプリ自体がアプリ自体に重い処理をさせるのであればどこにも迷惑をかけないのでいいのだが、外部サーバに大量にリクエストを投げていては困るというわけである。

なので例えばサーバに何かを問い合わせる処理 A は 5 秒おきにしか実行しないというような場合を考えよう。つまり、A を行ってから 5 秒間は何もしないという動作が欲しいのである。

この仕様を満たすアプリを設計するためのコードの書き方について解説する。

## スレッドを理解する

Swift では`main`スレッドと`global`スレッドの二つが存在する。

`main`スレッドでは`Main Queue`のみが実行され、`global`スレッドでは`Global Queue`だけが実行される。どちらのスレッドに処理（`Queue`）を追加するかは基本的にシステムが自動的に行なってくれるのだが`DispatchQueue`を指定することで任意のスレッドに処理を渡すことができる。

`Global Queue`には実行優先度があり、高い方から順に`high`、`default`、`low`、`background`となっている。

ただし、これらの実行優先度を直接指定することはなく、普通は Enum を使って指定する
:w

### userInteractive

UI の更新など、即座にタスクが実行されてほしい場合に利用する。

### userInitiated

ボタンのタップなどで非同期に処理をする場合に利用する。優先度`high`が割り当てられる。

### default

デフォルトの優先度。

### utility

プログレスバーや、計算処理、ダウンロード処理などで使う。

### background

すぐには利用しないデータのプリフェッチなどで使う。

### unspecified

特筆すべき優先度がないことを示す。システム側で自動的に優先度が割り当てられる。

## さまざまなスリープ処理

Swift にはさまざまなスリープ処理があるのだが、まずは単にスリープ処理を入れることだけを考えてみる。

これは自分も含め、初学者がよく引っかかってしまうトラップになっているので備忘録として残しておきたい。

今回はテストアプリとして、ボタンを押すと 1 秒おきに時刻を取得し、それをリストとしてリアルタイムで反映させるものを考えよう。

プログラムとしてはひどく基本的なものなのでコード自体の詳しい解説は割愛する。

### sleep を使う

Swift には標準で`sleep`コマンドがあるのでそれを利用する。

```swift
import SwiftUI

struct ContentView: View {
    @State var dateList: [String] = []
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
        for _ in 0 ..< 10 {
            dateList.append("\(Date().description) on \(Thread.current.isMainThread)")
            sleep(1)
        }
    }
}
```

ところがこのコードは想定通りの動作をしない。というのも`runDispatchQueue`がメインスレッドで実行されてしまうからだ。

つまり、`sleep(1)`はメインスレッドを 1 秒間停止するという意味になり、それを 10 回繰り返すのでトータル 10 秒間メインスレッドが停止してしまう。

メインスレッドが停止するということは画面の再描画がされないのでフリーズしたような状態になってしまうことを意味する。更に「処理 ->1 秒停止」なので処理中はメインスレッドが動いているため画面の再描画がされそうな気もするのだが、実際にはされないことにも注意しよう。

|     内容     |   詳細   |
| :----------: | :------: |
| 実行スレッド |   main   |
|    アプリ    | フリーズ |
|    再描画    | されない |
|    データ    |  正しい  |
|  データ並び  |  正しい  |

### Thread.sleep を使う

では`sleep`ではなく`Thread.sleep`を使ってみてはどうかということになるが、これも結局`rundDispatchQueue()`がメインスレッドで実行されているのでメインスレッドが止まってしまう。

```swift
private func runDispatchQueue() {
    dateList.removeAll(keepingCapacity: true)
    for _ in 0 ..< 10 {
        dateList.append("\(Date().description) on \(Thread.current.isMainThread)")
        Thread.sleep(forTimeInterval: 1)
    }
}
```

|     内容     |   詳細   |
| :----------: | :------: |
| 実行スレッド |   main   |
|    アプリ    | フリーズ |
|    再描画    | されない |
|    データ    |  正しい  |
|  データ並び  |  正しい  |

## Serial Queue で実行してみよう

では次に`DispatchQueue.global`を使い、処理を`Global Queue`として渡すことにする。

`DispatchQueue.global`には async（非同期）と async（同期）の二つがあり、更に並列処理か逐次処理がある。つまり、全部で四通りの実行の仕方があることになる。

ただし、今回は負荷をかけないためのコーディングについて考えるので並列処理（同時に複数実行）は考えず、逐次処理（同時に一つだけ実行）を考える。

::: tip Sleep について

`DispatchQueue.global`内で`sleep`または`Thread.sleep`を使ってみたのですが、どちらでも動作に違いはありませんでした。

:::

### Serial + Sync

`sync`を指定すると`DispatchQueue`のクロージャが全部終了してから呼び出し元に制御を返します。

```swift
import SwiftUI

struct ContentView: View {
    @State var dateList: [String] = []
    // 逐次処理
    let queue = DispatchQueue(label: "work.tkgstrator.dispatch_queue_serial")

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
            queue.sync {
                dateList.append("\(loop) -> \(Date().description) on \(Thread.current.isMainThread)")
                Thread.sleep(forTimeInterval: 1)
            }
        }
    }
}
```

よってこれは以下のように動作します。

- メインスレッドが`runDispatchQueue`を実行
- グローバルスレッドがループを実行
  - その間メインスレッドはグローバルスレッドが完了するのを待つ
  - 待っている間は当然`sleep`しているとの同じ状態
- グローバルスレッドが制御を返す
- `dateList`が変化しているので画面の再描画が行われる

::: tip ナゼ？

`DispatchQueue`ではグローバルスレッドを指定しているはずなのだが、何故かメインスレッドで実行される。

これに限らず、`Sync`を使うとメインスレッドで実行されてしまう。そういう宿命なのだろうか。

:::

|     内容     |   詳細   |
| :----------: | :------: |
| 実行スレッド |   main   |
|    アプリ    | フリーズ |
|    再描画    | されない |
|    データ    |  正しい  |
|  データ並び  |  正しい  |

しかも実行してみると`Global Queue`として実行しているはずなのに何故かメインスレッドで実行されています、謎です。

### Serial + Async

次に`Async`を使って実行してみます。

これはメインスレッドを止めずに裏で実行するような感じですので期待通りの結果が得られます。

```swift
private func runDispatchQueue() {
    dateList.removeAll(keepingCapacity: true)
    for loop in 0 ..< 10 {
        queue.async {
            dateList.append("\(loop) -> \(Date().description) on \(Thread.current.isMainThread)")
            Thread.sleep(forTimeInterval: 1)
        }
    }
}
```

つまり、ちゃんと 1 秒毎にデータが 1 つずつ増えていき、その順番も内容も間違っていないということです。

|     内容     |   詳細   |
| :----------: | :------: |
| 実行スレッド |  global  |
|    アプリ    | 正常動作 |
|    再描画    |  される  |
|    データ    |  正しい  |
|  データ並び  |  正しい  |

## 別のスレッドを動かす

### Sync + Main.Sync

`Sync`内で`Main.Async`を動かすとどうなるのでしょうか。

これをすると`dateList.append()`を行うのと`sleep`をするスレッドが同じであるにも関わらず、先にすぐに処理が終わる`dateList.append()`を実行した後に 10 秒間のスリープ処理が入ります。

つまり、ボタンを押した瞬間にフリーズして全く同じデータ（ボタンを押した時刻）が 10 秒後に描画されます。

```swift
private func runDispatchQueue() {
    dateList.removeAll(keepingCapacity: true)
    for loop in 0 ..< 10 {
        queue.async {
            dateList.append("\(loop) -> \(Date().description) on \(Thread.current.isMainThread)")
            print("\(loop) -> \(Date().description) on \(Thread.current.isMainThread)")
            DispatchQueue.main.async {
                Thread.sleep(forTimeInterval: 1)
            }
        }
    }
}
```

|     内容     |    詳細    |
| :----------: | :--------: |
| 実行スレッド |    main    |
|    アプリ    |  フリーズ  |
|    再描画    |  されない  |
|    データ    | 正しくない |
|  データ並び  |    不明    |

### Async + Main.Async

次に`Async`内でメインスレッドを動かしてみます。

すると、`dateList.append()`と`sleep`が別スレッドで実行されるため、ボタンを押して 1 秒後に画面が一気に再描画されます。つまり、データは全部同一の時刻が表示されるため、中身は正しくありません。

```swift
private func runDispatchQueue() {
    dateList.removeAll(keepingCapacity: true)
    for loop in 0 ..< 10 {
        queue.async {
            dateList.append("\(loop) -> \(Date().description) on \(Thread.current.isMainThread)")
            print("\(loop) -> \(Date().description) on \(Thread.current.isMainThread)")
            DispatchQueue.main.async {
                Thread.sleep(forTimeInterval: 1)
            }
        }
    }
}
```

|     内容     |     詳細     |
| :----------: | :----------: |
| 実行スレッド |    global    |
|    アプリ    | 1 秒フリーズ |
|    再描画    | 1 秒後される |
|    データ    |  正しくない  |
|  データ並び  |     不明     |

## AsyncAfter を使う

メインスレッドには指定時間後に処理を実行する`DispatchQueue.main.asyncAfter`という仕様が存在します。

```swift
private func runDispatchQueue() {
    dateList.removeAll(keepingCapacity: true)
    for loop in 0 ..< 10 {
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(loop)) {
            dateList.append("\(Date().description) on \(Thread.current)")
        }
    }
}
```

このとき`.now() + 定数`という書き方をしてしまうと定数秒後に 10 回のループが同時に実行されてしまうので、現在時刻である`.now()`から少しずつズレて実行できるように`deadline`の値は変数にすべきです。

こうすれば想定通りの仕様を満たします。`DispatchQueue.global.async`を使ったときと違うのはメインスレッドで実行されるという点でしょう。

::: danger 処理の重さに注意

ただし、注意しなければいけないのは時間がかかる処理に対してはこの手法は使えないということです。何故なら、処理の予約がボタンを押した瞬間に`Main Queue`として保存されているためです。

例えば、5 秒かかるような処理に対してこのコードを書くと、処理が終わっていないにも関わらず次の Queue が実行されてしまいます。`DispatchQueue.global.async`の場合は処理が終わってから +1 秒後というコードのため、このような問題は発生しません。

:::

|     内容     |   詳細   |
| :----------: | :------: |
| 実行スレッド |   main   |
|    アプリ    | 正常動作 |
|    再描画    |  される  |
|    データ    |  正しい  |
|  データ並び  |  正しい  |

### まとめ

スリープ処理をしたいのであれば`DispatchQueue.global.async`を使おう。
