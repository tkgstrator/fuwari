---
title: Swiftでの配列に対する操作まとめ
published: 2021-07-12
description: いつも配列でやりたいことの実装方法を忘れてしまうので備忘録としてまとめておきます
category: Programming
tags: [Swift]
---

# 配列の操作方法

## 乱数の配列の作成

Swift には標準乱数ライブラリがあるので、それを使ってテスト用の配列を作成します。

今回は要素数 100、Int 型で 0 から 20 までのいずれかの数字が入っているような配列を考えます。

```swift
let items: [Int] = (0 ..< 100).map { _ in .random(in: 0...20) }
```

これは上のように`map`と`Int.random(in: Range<Int>)`を利用して簡単に作成できます。

```swift
let items: [Int] = [
    17, 1, 15, 18, 14, 13, 14, 7, 3, 20, 5, 11, 14, 18, 5, 10, 14, 3, 11, 0, 1, 5, 19, 2, 10, 15, 17, 16, 11, 1, 4, 17, 18, 17, 17, 6, 18, 3, 2, 1, 17, 9, 2, 11, 15, 0, 10, 16, 6, 11, 4, 1, 14, 10, 9, 18, 13, 17, 19, 0, 11, 2, 5, 7, 7, 8, 4, 20, 10, 18, 6, 15, 7, 3, 14, 8, 2, 13, 18, 2, 1, 0, 11, 16, 19, 19, 1, 20, 12, 0, 10, 15, 3, 11, 16, 17, 2, 10, 15, 20
    ]
```

## 要素を取得

### N 番目の値を取得

これは単にインデックスを使うことで取得できます。

```swift
print(items[50]) // -> 4
print(items[200]) // -> Index out of range
```

このとき、コンパイラはインデックスが配列の要素数未満であることを確認しません。なので`items[200]`のように存在しないインデックスを参照しようとすると`Index out of range`でコケます。

繰り返しますが、コンパイラはインデックスの正当性をチェックせず、チェックするような関数も存在しないためインデックスが要素数未満を指定しているかどうかはプログラマがチェックする必要があります。何故なら、Swift のコーディング規約ではインデックス外の参照はエラーではなくバグだと捉えているためです。

### 先頭や末尾の値を取得

先頭や末尾の場合は特別な`first`や`last`という特別なプロパティが利用できます。

```swift
print(items.first) // -> Optional(17)
print(items.last)  // -> Optional(8)
```

これらの便利なところはインデックス外参照が発生せず、クラッシュしないということです。つまり、配列の要素数が 0 なら`nil`が返ってきて、それ以外であればオプショナルで値が返ってきます。

### 要素からランダムに取得

```swift
print(items.randomElement()) // -> Optional(15)
```

これも配列が空である可能性を考慮して、空っぽであれば`nil`を返します。

#### ランダムに複数選択

### N 要素取得

先頭・末尾から N 個の要素を取得する場合には`prefix()`と`suffix()`が利用できます。

```swift
print(items.prefix(5)) // -> [17, 1, 15, 18, 14]
print(items.suffix(5)) // -> [17, 2, 10, 15, 20]
```

指定する要素数として配列の要素数よりも大きい値を指定した場合は単純に全要素が返ってきます。

## 計算プロパティ

### 要素数

要素数は常に`count`で取得できます。

```swift
print(items.count) // -> 100
```

類似するプロパティとしてメモリが確保しているサイズを返す`capacity`があります。

```swift
print(items.capacity) // -> 100
```

基本的にはこれらは同じ値を返しますが、配列を全削除するときにメモリを解放すれば`count = capacity = 0`になりますが、解放しなければ`capacity`の値は保存されます。

### 配列が空かどうか

配列が空かどうかは、`if items.count == 0`でも判定できますが、この場合にはより簡潔に書ける`isEmpty`のプロパティを利用したほうが良いでしょう。

```swift
// Bad
if items.count == 0 {
    // Code
}

// Good
if items.isEmpty {
    // Code
}
```

### 最小値・最大値を取得

```swift
print(items.min()) // -> Optional(0)
print(items.max()) // -> Optional(20)
```

最小値・最大値もともにオプショナルで返ってきます。

### 和を取得

Python 等であれば`sum()`を使って一括で取得できるのですが、Swift にはありません。そこで、取得できるように`Extension`を定義します。

今回の場合は配列の要素が Int 型であるものに対して`sum()`を定義しました。

```swift
extension Collection where Element == Int {
    func sum() -> Int {
        self.reduce(0, +)
    }
}
```

このままだと Int 型にしか適用できないのですが、CGFloat や Double でも同様のことはできるはずなので、これを拡張して、

```swift
extension Collection where Element: Numeric {
    func sum() -> Element {
        self.reduce(0, +)
    }
}
```

このようにすれば`Numeric`プロトコルに適合する全ての型に対して`sum()`を定義することができます。

```swift
print(items.sum()) // -> 1021
```

### 平均を取得

平均を求める際は除算が必要になるので Int 型の場合は型を担保できません。

よって、Int 型とそれ以外で Extension を分ける必要があります。Int 型の平均を Int 型で必要とする場合は少ないと思うので、今回は Double 型に変換することにしました。

```swift
// Int型 -> Double型
extension Collection where Element == Int {
    func avg() -> Double {
        Double(self.reduce(0, +)) / Double(self.count)
    }
}

// Int型以外
extension Collection where Element: FloatingPoint {
    func avg() -> Element {
        self.reduce(0, +) / Element(self.count)
    }
}
```

```swift
print(items.avg()) // -> 10.108910891089108
```

## 配列の並び替え

配列を並び替えておくと検索が高速になります。

整頓されていないリストに対しての値検索は要素数が k であれば $O(k)$かかるところが、整序済みであれば$O(\ln k)$で済むからです。

### ソーティング

ソートするコードは`sort()`と`sorted()`がありますが、利用方法がまったく異なるため注意が必要です。

|        |   sort()   |     sorted()     |
| :----: | :--------: | :--------------: |
| 返り値 |    Void    | ソートされた配列 |
|  配列  | 更新される |    変わらない    |

ここで大事なのは`sorted()`はソートした配列を返すのでそれを受け取らないと意味がなく、`sort()`は元の配列をソートするので`var`でないと利用できないという点です。

```swift
print(imtes.sort())   // -> ()
print(items.sorted()) // -> [0, 0, 0, 0, 0, 1, 1, 1, 1, ... , 20]
```

元の配列を保存しておきたい場合には`sorted()`を利用し、`let sortedItems = items.sorted()`のように書くと良いでしょう。

で、内部ではクイックソートが動いていたはずなので一般的な配列に対しては殆どの場合で最速です。自分でソーティングライブラリを書く必要はありません。

### ランダム

ランダムの並び替えには`shuffle()`と`shuffled()`があります。

|        | shuffle()  |      shuffled()      |
| :----: | :--------: | :------------------: |
| 返り値 |    Void    | シャッフルされた配列 |
|  配列  | 更新される |      変わらない      |

これもソーティングと同じく配列を保存する`shuffled()`と保存しない`shuffle()`で区別されています。

### 逆順

配列を逆順にするには`reverse()`と`reversed()`があります。

|        | reverse()  |     reversed()     |
| :----: | :--------: | :----------------: |
| 返り値 |    Void    | ReversedCollection |
|  配列  | 更新される |     変わらない     |

注意点としては`reversed()`は逆順になった配列が返ってくるのではなく`ReversedCollection`が返ってくるという点です。

これは`reversed()`されたプロパティが参照された際に初めて配列の値が確定するプロパティになります。

```swift
let reversedItems = items.reversed()
print(reversedItems) // ReversedCollection<Int>

let reversedItems: [Int] = items.reversed()
print(reversedItems) // Collection<Int>

print(Array(items.reversed()))
```

つまり、単に変数に代入しただけであれば`Array`になっていないので通常の配列として利用したい場合は型を明示するか`Array()`で配列化する必要があります。

## 配列の検索

### 指定された値を含むかどうか

`contanins()`は指定された値があるかどうかを Boolean で返します。

```swift
print(items.contains(10)) // -> true
print(items.contains(30)) // -> false
```

### 値を指定して検索

指定した値のインデックスを知りたい時は`index(of: )`が利用できます。これは存在しない場合には`nil`を返します。

|                  |      値      |        意味        |
| :--------------: | :----------: | :----------------: |
| firstIndex(of: ) | オプショナル | 最初のインデックス |
| lastIndex(of: )  | オプショナル | 最後のインデックス |
|   index(of: )    | オプショナル | 最初のインデックス |
|  index(after: )  |     Int      |   与えられた値+1   |
| index(before: )  |     Int      |   与えられた値-1   |

`index(after: )`と`index(before: )`の使いみちはイマイチわかりません。

```swift
print(items.firstIndex(of: 10)) // -> Optional(15)
print(items.lastIndex(of: 10))  // -> Optional(97)
print(items.index(of: 10))      // -> Optional(15)
print(items.index(after: 10))   // -> 11
print(items.index(before: 10))  // -> 9
```

### 値を指定して全検索

全検索するメンバ関数がないので、Extension で実装します。

```swift
print(items.allIndices(of: 10)) // -> [15, 24, 46, 53, 68, 90, 97]

extension Array where Element: Equatable {
    func allIndices(of value: Element) -> [Int] {
        self.indices.filter({ self[$0] == value })
    }
}
```

この Extension は配列中の指定した値のインデックスの配列を返します。指定された値がない場合には空の配列を返します。

`index(of: )`がオプショナルを返すので、それに合わせたいのであれば、

```swift
extension Array where Element: Equatable {
    func allIndices(of value: Element) -> [Int]? {
        let indices = self.indices.filter({ self[$0] == value })
        return indices.isEmpty ? nil : indices
    }
}
```

とすれば、指定された値がないときには`nil`が返り、そうでないときには全インデックスが Int 型で返ります。

### 指定した値の要素数

指定した値の要素数を返すメンバ関数がないので、Extension で実装します。

```swift
print(items.count(of: 10)) // -> 7

extension Array where Element: Equatable {
    func count(of value: Element) -> Int {
        self.filter({ $0 == value }).count
    }
}
```

### 最頻値

最も出現した値を返します。

```swift
print(items.multimode()) // -> [(value: 11, count: 8), (value: 17, count: 8)]

extension Array where Element: Hashable {
    func multimode() -> [(value: Element, count: Int)] {
        let uniqueSet = Array(Set(self)).map({ (value: $0, count: self.count(of: $0)) })
        let maxCount = uniqueSet.map({ $0.count }).max()
        return uniqueSet.filter({ $0.count == maxCount })
    }
}
```

今回はわかりやすさを重視して、最頻値を出現回数と共に全部出力するようにした。ループ回数を減らすために`Set`を利用したので`Hashabble`プロトコルに適合する型でしか動作しなくなったがまあ細かい問題ではないだろう。

単に唯一の最頻値の値が欲しい場合などは各自 Extension を改良するなどして対応してほしい。

## 配列の操作

### 重複の削除

重複する要素を削除したい場合には`Set`が利用できます。`Set`は`Array`とは異なるプロトコルなのですが相互変換可能で、`Set`は重複を許さないという条件があります。

なので、一度`Set`に変換してから再度`Array`に戻せば重複が取り除かれます。

```swift
print(Array(Set(items))) // -> [11, 18, 8, 2, 4, 5, 0, 14, 10, 17, 1, 15, 19, 12, 20, 16, 3, 9, 7, 6, 13]

extension Array where Element: Hashable {
    func removeDuplicated() -> Array<Element> {
        Array(Set(self))
    }
}
```

ただし、この変換はユニークではないので実行ごとに値が変わることに注意してください。毎回同じ値が欲しい場合は、返り値をソーティングする必要があります。

### 追加

配列に要素を追加する方法はいくつかあります。

#### 要素を追加

```swift
var items: [Int] = [1, 2, 3]

//
items += [4]
print(items) // -> [1, 2, 3, 4]

// Good
items.append(4)
print(items) // -> [1, 2, 3, 4]

// Good
items.append(contentsOf: [4])
print(items) // -> [1, 2, 3, 4]
```

要素を一つ加えるというのは、要素数が 1 の配列を追加するとみなすことができます。

#### 配列を追加

演算子で追加する方法と`append(contentsOf: )`を利用する方法がありますが、後者のほうがわかりやすいと思います。

```swift
var items: [Int] = [1, 2, 3]

//
items += [4, 5]
print(items) // -> [1, 2, 3, 4, 5]

// Good
items.append(contentsOf: [4, 5])
print(items) // -> [1, 2, 3, 4, 5]
```

ただし、元の配列を保存しておきたい場合には使えないので以下のように書く必要があります。

```swift
let items: [Int] = [1, 2, 3]
let newItems: [Int] = items + [4, 5]
print(newItems) // -> [1, 2, 3, 4, 5]
```

### 削除

追加に比べて削除は少し難しくなります。

削除するプロパティはたくさんあるのでちゃんと覚えておきたいですね。

|                                  |            返り値            |           意味            |
| :------------------------------: | :--------------------------: | :-----------------------: |
|           dropFirst()            |             配列             |   配列の最初の値を削除    |
|            dropLast()            |             配列             |   配列の最後の値を削除    |
|        dropFirst(k: Int)         |             配列             | 配列の最初の k 要素を削除 |
|         dropLast(k: Int)         |             配列             | 配列の最後の k 要素を削除 |
|           removeLast()           |        配列の最後の値        |   配列の最後の値を削除    |
|          removeFirst()           |        配列の最初の値        |   配列の最初の値を削除    |
|            popLast()             | 配列の最後の値のオプショナル |   配列の最後の値を削除    |
|         remove(at: Int)          |      配列の N 番目の値       |    配列の N 番目を削除    |
|           removeAll()            |             Void             |       配列を全削除        |
| removeAll(keepingCapacity: Bool) |             Void             |       配列を全削除        |

`removeAll()`以外は削除した値を返り値として持ちます。`removeFirst()`と`removeLast()`はオプショナルではないので空の配列に対して実行した場合には`Index out of range`と同様のエラーである`Can't remove first/last element from an empty collection`が発生します。

そして、何故か`popLast()`はあるのに`popFirst()`は存在しません。

#### keepingCapacity

keepingCapacity は確保したメモリを解放するかどうか、のパラメータな気がしています。

どちらも配列を削除したので`items.count`では`0`が返ってくるのですが`keepingCapacity: true`とした場合には`items.capcity`とすると`100`が返ってきます。

メモリを解放すれば空き容量が増えるわけですが、空っぽにした後にまたすぐに配列を代入するようなケースではメモリを解放してしまうとまた確保するための作業が必要になります。

#### 値を指定して削除

`remove()`にはインデックスしか指定できないため、指定した値を持つ要素を削除することができません。

そこで`Extension`を使って指定した値を配列から削除できるようにします。

```swift
extension Array where Element: Numeric {
    mutating func remove(value: Element) {
        if let index = self.firstIndex(of: value) {
            self.remove(at: index)
        }
    }
}
```

ただ、これでは同一の値を持つ Element が複数あった場合には最初の一つしか削除できません。

Element の全てのインデックスを知りたい場合は以下の Extension を作成すると良いです。

#### 値を指定して全削除

指定した値を全て削除したい場合には削除すると考えるのではなく、指定された値以外で配列を再度生成することを考えるほうが楽です。

```swift
extension Array where Element: Equatable {
    mutating func removeAll(value: Element) {
        self = self.filter({ $0 != value })
    }
}
```

#### 複数の値を指定して全削除

複数の値を指定してそれを削除したい場合は`filter()`で`contains()`を利用すれば効率的に書けます。

```swift
extension Array where Element: Equatable {
    mutating func removeAll(value: [Element]) {
        self = self.filter({ !value.contains($0) })
    }
}

```

## 配列から配列を作成

配列から更に配列を作成するには`map`や`filter`が利用できます。

- map
  - 全要素に対して変換を行なう
- compactMap
  - nil でない値に対して変換を行なう
- flatMap
  - nil でない値に対して変換を行なう
  - 配列の次元を一つ落とす

### 配列の次元を減らす

`flatMap()`は減らせる場合に配列の次元を一つ減らします。

```swift
let words: [String] = ["Apple", "Google", "Facebook", "Microsoft", "Amazon"]

print(words.flatMap({ $0 })) // -> ["A", "p", "p", "l", "e", "G", "o", "o", "g", "l", "e", "F", "a", "c", "e", "b", "o", "o", "k", "M", "i", "c", "r", "o", "s", "o", "f", "t", "A", "m", "a", "z", "o", "n"]
```

二次元配列を一次元に戻したいときなどに使えます。

```swift
let items: [[Int]] = [[1, 2, 3], [1, 2], [3, 4], [5]]
print(items.flatMap({ $0 })) // ->[1, 2, 3, 1, 2, 3, 4, 5]
```

### 二次元配列に変換

要素数が 100 の配列を要素数が 10 の配列 x10 の二次元配列にしたい場合があります。Python などでは`chunked()`というメソッドがあるのですが、Swift にはないので自作します。

```swift
print(items.chunked(by: 10)) // -> [[17, 1, 15, 18, 14, 13, 14, 7, 3, 20], [5, 11, 14, 18, 5, 10, 14, 3, 11, 0], [1, 5, 19, 2, 10, 15, 17, 16, 11, 1], [4, 17, 18, 17, 17, 6, 18, 3, 2, 1], [17, 9, 2, 11, 15, 0, 10, 16, 6, 11], [4, 1, 14, 10, 9, 18, 13, 17, 19, 0], [11, 2, 5, 7, 7, 8, 4, 20, 10, 18], [6, 15, 7, 3, 14, 8, 2, 13, 18, 2], [1, 0, 11, 16, 19, 19, 1, 20, 12, 0], [10, 15, 3, 11, 16, 17, 2, 10, 15, 20]]

extension Array {
    func chunked(by size: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, self.count)])
        }
    }
}
```

> 参考文献
>
> [Swift で配列を n 個の要素に分割する](https://gist.github.com/sumitokamoi/22b8f30c2c1a3ef93cb1f03d4a7e8066)

### nil を除去した配列

オプショナルの配列から`nil`を除去したい場合があります。

`compactMap()`および`flatMap()`にはオプショナルを許容しないという制約があるので、これらを通せば安全にアンラップすることができます。

ただの`map()`ではダメなことと、`flatMap()`にはアンラップ以外にも配列の次元を 1 つ減らすという効果があるので`compactMap()`を使うのが安全かと思います。

```swift
let items: [Int?] = [0, nil, 2, 3, nil, 5, 6, 7, nil, 9]

print(items.map({ $0 }))        // -> [Optional(0), nil, Optional(2), Optional(3), nil, Optional(5), Optional(6), Optional(7), nil, Optional(9)]
print(items.flatMap({ $0 }))    // -> [0, 2, 3, 5, 6, 7, 9]
print(items.compactMap({ $0 })) // -> [0, 2, 3, 5, 6, 7, 9]
```

### 二つの配列の和

Python では`add()`などで二つの配列の和を計算できるのですが、Swift ではできないので Extension で実装します。

配列の型が同じである必要がありますが、要素数は異なっていても構いません。その場合は小さい方に合わせて返ってきます。

```swift
let itemsA: [Int] = [1, 2, 3, 4, 5]
let itemsB: [Int] = [3, 4, 5 ,6, 7]
let itemsC = itemsA.add(itemsB) // -> [4, 6, 8, 10, 12]

extension Array where Element: Numeric  {
    func add<T: Numeric>(_ input: Array<T>) -> Array<T> {
        return zip(self as! [T], input).map({ $0.0 + $0.1 })
    }
}
```

### 配列の和

二次元配列を与えると全てを足してその和を返すようなものを考えます。

```swift
let items: [[Int]] = [[1, 2, 3, 4, 5], [3, 4, 5, 6, 7], [6, 7, 8, 9, 10]]
print(sum(of: items)) // -> [10, 13, 16, 19, 22]

func sum<T: Numeric>(of arrays: Array<Array<T>>) -> Array<T> {
    if let first = arrays.first {
        var sum: [T] = Array(repeating: 0, count: first.count)
        let _ = arrays.map({ sum = sum.add($0) })
        return sum
    }
    return []
}
```

書き方がダサいので多分もっとかっこよく書けます。


