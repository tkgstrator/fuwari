---
title: SwiftでSingletonを実装する
published: 2021-04-08
description: たった一つしかインスタンスを許容しない、SingletonをSwiftで実装するためのメモ
category: Programming
tags: [Swift]
---

## Swift5 + Singleton

今回 Singleton を学ぶにあたって[こちらの記事](https://qiita.com/satoru_pripara/items/725b66fd0dfb301cd80c)を参考にさせていただいた。

非常にわかりやすかったのでこの記事を読むよりもおすすめしたい。

## Singleton とはなにか

要するにたった一つしかないオブジェクトのこと。

アプリやライブラリのコア部分を司る機能を管理しているオブジェクトが常に同じ一つであってほしいという仕組み。そうでないと例えば二つのオブジェクトが同時にデータを書き換えたりしてしまうとデータの不整合が生じたりしていろいろとめんどくさいことになってしまう。

では「オブジェクトをたった一つしかつくられないためにどうしたらいいのか」というのが Singleton の考え方になるわけである。

## Singleton の実装

まずは継承を防ぐために`final`修飾子をつけ、値型の`struct`ではなく`class`を使うようにする。

`class`と`struct`の最も大きな違いの一つに、コピーができるかできないかというのがある。これは Python や Javascript でよくあることなのだが、例えば A の現在のデータをスワップしたりして同じクラスの B を作りたいとしよう。

このときシャローコピーをすると A のコピーを B としてつくると A と B が全く同一のオブジェクトになってしまう。これは鏡写しのようなもので、A をスワップした時点で B の内容も変わってしまうのだ。

これを防ぐためにはディープコピーと呼ばれるコピーの仕方をおこなう必要がある。要するに、クラスの場合はコピーしたとしても実体ではなくメモリのポインタがコピーされるだけなのだ。

```swift
final public class AppManager {}
```

更に、外部から呼び出されないようにイニシャライザをプライベートにする。

```swift
private init {}
```

最後にオブジェクトをたった一つだけ生成するために、

```swift
public static let appManager = AppManager()
```

として`static`変数で宣言する。

## スレッドセーフにする

これについては現状、自分では利用する場面がないが覚えておいて損はないのでメモをしておく。

```swift
private let queue = DispatchQueue(label: "AppManager")
private let userDefaults = UserDefaults.standard

func setValue(_ value: Any, forKey key: String) { [weak self]
    queue.sync {
        userDefaults.setValue(value, forKey: key)
    }
}
```

ただ、全部の処理をシリアルキューにするとパフォーマンスが低下してしまうので読み込みは同時並行で実行するようにするなどの配慮があると良い。

## じゃあ結局どうするの

これは非常に簡単で、Singleton としたいクラスは次のように書けば良い。

```swift
final public class AppManager() {
    public static let shared = AppManager()
    private let queue = DispatchQueue(label: "AppManager")
    private let value: Int = 100
    private init() {}

}
```

これを使いたいときは次のようにする。

```swift
AppManager.shared.value // -> 100
```

一度クラスを作ってしまえばそれを Singleton にすること自体は難しくないと言えるだろう。
