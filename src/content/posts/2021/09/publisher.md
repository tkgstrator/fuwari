---
title: Publisherを使いこうなそう
published: 2021-09-13
description: 標準的な関数をPublisher型に変換することで便利に利用できます
category: Programming
tags: [Swift, SwiftUI]
---

# [Publisher](https://developer.apple.com/documentation/combine/publisher)

iOS13 から利用できる`Combine`フレームワークのメインの機能の一つ。

非同期処理や繰り返しなどがとっても便利にかけるらしい。正直、内容が濃すぎて全てを追うことはできなかったので、今回は簡単に内容を学ぶことにする。

## Publisher のメリット

以下、普通の関数にはできなくて Publisher を利用すれば簡単にできることのメモ。

### 再実行

エラーが返ってきたときに、n 回再実行するというのが非常に簡単に書けます。

### 並列実行

同時に n 個並列に実行するというのも簡単に書けます。

## Publisher の種類

### Future

一つの値と完了か失敗を返せる。

### Just

一つの値を返して完了。

### Deferred

Future がインスタンスを作成した段階で実行されるのに対して、`sink`されたタイミングでしか実行されない。

### Fail

失敗だけ返して完了。

### Record

複数値を返して完了か失敗を返せる。

## チュートリアル

与えられた整数に 10 を足したものを返す関数`addValue(value: Int)`を考えます。

これはすぐに、以下のような関数になることがわかります。

```swift
func addValue(value: Int) -> Int {
    value + 10
}
```

で、当然これは失敗もしないのでこれだけでは意味がないのですが、まあ感覚的に Publisher を理解するためだと思ってください。

### Publisher

Publisher はタスクの集合みたいなものなので、処理したい内容っぽいのを配列として用意します。

今回は適当に 1 から 10 までの数を入力とし、それを Publisher としましょう。

```swift
// Publisherの内容を保持するために必要
var task = Set<AnyCancellable>()

// タスクにわたす値の配列
let publisher = Array(Range(1 ... 10).map({ $0 })).publisher
```

ここで`task`が必要になる理由ですが、`Publisher`はキャンセル可能なタスクなのでこれを使って値を保持しておかないとインスタンスが消えた瞬間に強制的にタスク自体がキャンセルされるためです。

### 実装

とりあえずよくわからなくてもいいので以下のコードを見ます。

```swift
publisher
    .receive(on: DispatchQueue.main)
    .map({ addValue(value: $0)})
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("FINISHED")
        case .failure:
            print("ERROR")
        }
    }, receiveValue: { value in
        print(value)
    })
    .store(in: &task)
```

#### Receive

どのスレッドで実行するかを決めるところです。今回はとりあえずメインスレッドにしましたが、メインスレッドで実行すると重い処理をすると UI が固まるのでケースバーケースです。

#### Map

publisher が持つ`[Int]`は`[1, 2, ..., 10]`なのですが、それを`[addValue(value: 1), addValue(value: 2), ... , addValue(value: 10)]`に変換します。

`addValue(value: Int)`は与えられた数に 10 を足して返す関数なので結局`[11, 12, ... , 20]`が入っていることになります。

#### Sink

エラーが発生する可能性がある Publisher の返り値を受け取るところです。

- `receiveCompletion`
  - すべての処理が終わったときに呼び出されます
- `receiveValue`
  - 値を受け取ったときに呼び出されます

今回は Publisher が 10 個の要素を持つので、`receiveValue`は 10 回呼び出されます。

#### Store

Publisher の状態を保持するためのおまじないみたいなものと捉えています。

### 実行結果

出力結果は以下のようになります。

```swift
11
12
13
14
15
16
17
18
19
20
FINISHED
```

で、これだけでは何も面白くないので関数自体を Publisher 化します。

## Publisher 化

Publisher 化するには関数自体を Publisher 化するのはもちろん、Publisher 自体も変更しなければいけません。

### Publisher

こちらは`map`を`flatMap`に書き換えるだけです。

```swift
publisher
    .receive(on: DispatchQueue.main)
    // mapからflatMapに変更
    .flatMap({ addValue(value: $0) })
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("FINISHED")
        case .failure(let error):
            // エラーの内容を表示
            print("ERROR", error)
        }
    }, receiveValue: { value in
        // 受け取った値を表示
        print("RECEIVE", value)
    })
    .store(in: &task)
```

### Publisher 関数

```swift
// 通常の関数
func addValue(value: Int) -> Int {
    value + 10
}

// Publisher化した関数
// 返り値はAnyPublisher型にする
func addValue(value: Int) -> AnyPublisher<Int, Never> {
    // Deferredにすることで即時実行されない
    Deferred {
        Future { promise in
            // Returnの代わりにこう書く
            promise(.success(value + 10))
        }
    }
    // よくわからないが必須のおまじない
    .eraseToAnyPublisher()
}
```

エラーを返さない場合の書き方についてはこれを丸暗記すると良いそうです。

### エラーを返す場合

一定の確率でエラーを発生させるコードを考えます。

以下のコードは 10%の確率でエラーを発生させます。

```swift
// エラー型を定義
enum APIError: Error {
    case invalidValue
}

func addValue2(value: Int) -> AnyPublisher<Int, APIError> {
    Deferred {
        Future { promise in
            if Int.random(in: 0 ... 9) == 0 {
                // エラーを返す
                promise(.failure(.invalidValue))
            } else {
                // 成功したので10足した数を返す
                promise(.success(value + 10))
            }
        }
    }
    .eraseToAnyPublisher()
}
```

### 実行してみる

エラーが発生すると、その時点で処理が終わり`receiveCompletion`が呼ばれます。

```swift
RECEIVE 19
ERROR invalidValue // エラー発生
```

エラーが発生しない場合はそのまま普通に終わります。

### リトライする

```swift
publisher
    .receive(on: DispatchQueue.main)
    .flatMap({ addValue(value: $0) })
    .retry(10) // リトライ回数を書く
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("FINISHED")
        case .failure(let error):
            print("ERROR", error)
        }
    }, receiveValue: { value in
        print("RECEIVE", value)
    })
    .store(in: &task)
```

::: tip リトライ回数について

リトライを宣言すると、どこかでエラーが発生した場合に「最初からやり直す」という処理になってしまう。

失敗したものだけリトライする方法がないか探してみる。

:::

### 並列処理する

```swift
publisher
    .receive(on: DispatchQueue.main)
    // 同時に実行するPublisher数を指定
    .flatMap(maxPublishers: .max(5), { addValue(value: $0)})
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("FINISHED")
        case .failure(let error):
            print("ERROR", error)
        }
    }, receiveValue: { value in
        print("RECEIVE", value)
    })
    .store(in: &task)
```

## 連結する

例えば何らかの処理で A というメソッドが計算した値を引数として B というメソッドに渡し、その結果を得たいという場合がある。

今回は 5 足したあとに更にその数に 10 を足すようなコードを考える。

```swift
publisher
    .receive(on: DispatchQueue.main)
    // 数珠つなぎを長くしすぎないように注意
    .flatMap(maxPublishers: .max(5), { addValue5(value: $0)})
    .flatMap(maxPublishers: .max(5), { addValue10(value: $0)})
    .retry(10)
    .sink(receiveCompletion: { completion in
        switch completion {
        case .finished:
            print("FINISHED")
        case .failure(let error):
            print("ERROR", error)
        }
    }, receiveValue: { value in
        print("RECEIVE", value)
    })
    .store(in: &task)
```

やることは簡単で、単純に`flatMap`で連結してやれば良い。

ただし、あんまり多く`flatMap`を数珠つなぎににすると Xcode の静的解析にめちゃくちゃ時間がかかって全くビルドが進まなくなる。

::: tip flatMap の深さ

イカリング 2 にログインするためには八回くらい API を叩けなければならず、ビルドが通らないため三つのメソッドに分割することで対応した。

:::

```swift
func addValue5(value: Int) -> AnyPublisher<Int, APIError> {
    Deferred {
        Future { promise in
            promise(.success(value + 5))
        }
    }
    .eraseToAnyPublisher()
}

func addValue10(value: Int) -> AnyPublisher<Int, APIError> {
    Deferred {
        Future { promise in
            promise(.success(value + 10))
        }
    }
    .eraseToAnyPublisher()
}
```
