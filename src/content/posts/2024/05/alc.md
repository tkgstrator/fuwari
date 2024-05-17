---
title: アクセスレベルコントロールを学ぼう 
published: 2024-05-02
description: 言語ごとに結構アクセスレベルコントロールが異なるので学習します
category: Programming
tags: [Swift, TypeScript]
---

## アクセスレベルコントロールとは

プログラム内のメソッド、プロパティにアクセスできる範囲などをコントロールするための仕組み。

言語によって異なるが大雑把に、

- public
  - どこからでも読み書き可能
- protected
  - 継承クラス・サブクラスから読み書き可能
- private
  - 同じ構造体・クラスの中からのみ読み書き可能

などが使われている。

なので、アクセス制限の緩さから言えば**public > protected > private**となるわけです。

そして、言語によってはprotectedはサポートされていないことも多いです。

事実、私がよく使っているSwiftやTypeScriptではこのようなACLはサポートされていません。

### 利用したい場面

アクセスレベルコントロールの種類にどのようなものがあるかを解説したうえで、次に実際に必要になる場面を考えてみましょう。

```swift
class Walltet {
  var amount: Int

  func add(_ value: Int) {
  }

  func sub(_ value: Int) throws {
  }
}
```

例えば上のような財布クラスが存在したとします。

財布クラスは金額を増やしたり減らしたりするメソッドを持ち、内部的に財布の中にいくら入っているかを保持しています。

このクラスを利用する理由としては、所持金は財布クラスだけが管理しており、全ての金銭の流れは財布クラスが把握すべきだからです。

家計簿をキチンとつけることができるのは財布の中身と領収書を全て管理している人がいるからです。

もし、誰かが勝手に財布からお金を抜いたり増やしたりすれば帳簿をつけたときに金額が合わずに困ってしまいますね。

よって、財布の中身である`amount`は他の人が操作できないようにしたいわけです。

ここで、単に外部から変更できないようにすれば　

```swift
class Walltet {
  // プライベートに変更
  // amountにアクセスできるのはこのクラス内のメソッドのみ
  private var amount: Int 

  func add(_ value: Int) {
  }

  func sub(_ value: Int) throws {
  }
}
```

とすればよいのですが、これでは外部からWalletクラスが`amount`というプロパティを持っている事自体もわからなくなってしまい、財布にいくら入っているかを知る術がなくなってしまいます。

よって「読み取りはできるが書き込みは捺せたくない」という状況が発生します。

これは単純なアクセスレベルコントロールだけでは実現できません。

```swift
class Walltet {
  // プライベートに変更
  // amountにアクセスできるのはこのクラス内のメソッドのみ
  private var _amount: Int 

  func add(_ value: Int) {
  }

  func sub(_ value: Int) throws {
  }

  func amount() -> Int {
    return _amount
  }
}
```

解決策の一つとして上のようなコードを書く人が一定数いるのですが、個人的にはこの書き方はコードを無意味に冗長にするだけなのでNGです。

こんなことをしなくてもこの要求を満たすための書き方がプログラミング言語には存在します。

### 読み取り専用

Swiftの場合はそれに`private(set)`が該当します。

こうすることで値を**Set**することは外部からのアクセスを拒むことができます。

```swift
class Walltet {
  // setterだけはprivate
  private(set) var amount: Int 

  func add(_ value: Int) {
  }

  func sub(_ value: Int) throws {
  }
}
```

じゃあTypeScriptではどう書くんですかとなるんですが、実はTypeScriptにはそのような単純な仕組みはありません。

```ts
class Walltet {
  private _amount: number

  add(value: number) {
  }

  sub(value: number) { 
  }

  // _amountの値を返すgetter
  get amount() {
    return _amount
  }
}
```

よって、めんどくさいのですが上のように`_amount`を定義してあげる必要があります。

これで`private(set)`と同様の効果が期待できます。

### 内部的にも変更不可

では、内部的にも変更ができないようにしたければどうすればよいでしょうか？

例えば、財布の所有者のIDというものを財布クラスに追加したとしましょう。

所有者のIDは外部からも見えていいですが、変更はできず、更に内部的にも変更ができないようにしたいです。

```swift
class Walltet {
  private(set) var id: Int
  private(set) var amount: Int 

  func add(_ value: Int) {
  }

  func sub(_ value: Int) throws {
  }
}
```

こう書けば外部からは読み込みしかできませんが、内部から書き換えることができてしまいます。

内部からも書き込みを許したくない場合はどうするのでしょうか。

はい、これは`var`ではなく`let`を使えばよいのです。

Swiftにおける`let`は定数なので初期化時に一度値を決めたら二度と返ることはできません。

```swift
class Walltet {
  // 外部からも内部からも読み込み専用
  let id: Int
  // 外部からは読み込み専用
  private(set) var amount: Int 

  func add(_ value: Int) {
  }

  func sub(_ value: Int) throws {
  }
}
```

ちなみにですが`private(set) let`は意味のないアクセスレベルコントロールです。

`let`な時点で参照しかできないので「外部からは参照しかできない」を意味する`private(set)`は付ける意味がありません。

では同様の機能はTypeScriptにはあるのでしょうか？

```ts
class Walltet {
  private _amount: number
  private readonly id: number

  add(value: number) {
  }

  sub(value: number) { 
  }

  // _amountの値を返すgetter
  get amount() {
    return _amount
  }
}
```

はい、実は読み込み専用にするための仕組みは存在しています。

それが`readonly`なのですがこれは内部的にも外部的にも読み込み専用にしてしまいます。

要するに、Swiftにおける`let`と同じ効果を持ちます。

## まとめ

さて、ここまでを比較してみましょう。

「外部からのアクセスだけ可能」「書き込みだけ可能」「内部からも読み取り不可」のようなアクセスレベルコントロールは存在する意味がないので、必要なパターンは以下に載せている五通りのみです。

> 組み合わせ的には内部からの書き込みはできないが、外部からの書き込みはできるという頭のおかしいアクセスレベルが考えられるが、そういうものは存在しない

この全てのアクセスレベルを修飾子で定義できれば良いということになります。

### Swiftの場合

| Swift            | 外部読み込み | 外部書き込み | 内部読み込み | 内部書き込み | 
| :--------------: | :----------: | :----------: | :----------: | :----------: | 
| public var       | ✔           | ✔           | ✔           | ✔           | 
| private(set) var | ✔           | -            | ✔           | ✔           | 
| private(set) let | ✔           | -            | ✔           | -            | 
| public let       | ✔           | -            | ✔           | -            | 
| private var      | -            | -            | ✔           | ✔           | 
| private let      | -            | -            | ✔           | -            | 

するとSwiftは全パターンを列挙していることがわかります。

### TypeScriptの場合

| TypeScript       | 外部読み込み | 外部書き込み | 内部読み込み | 内部書き込み | 
| :--------------: | :----------: | :----------: | :----------: | :----------: | 
| public           | ✔           | ✔           | ✔           | ✔           | 
| private + getter | ✔           | -            | ✔           | ✔           | 
| public readonly  | ✔           | -            | ✔           | -            | 
| private          | -            | -            | ✔           | ✔           | 
| private readonly | -            | -            | ✔           | -            | 

それと比較するとTypeScriptは外部からの書き込みだけを制限するアクセスレベルコントロールを実現するために`private + getter`という少々めんどくさい仕組みを導入しなければいけないことがわかります。

外部からは参照だけにしたい、っていうのは結構求められる状況が多い気がするのですが、需要がないのでしょうか？

記事は以上。