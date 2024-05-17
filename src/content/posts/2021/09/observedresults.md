---
title: ObservedResultsの使い方について
published: 2021-09-27
description: Realm + SwiftUIの決定版ともいうべきObservedResultsについて調査してみました
category: Programming
tags: [Swift, SwiftUI]
---

# [ObservedResults](https://docs.mongodb.com/realm-sdks/swift/latest/Structs/ObservedResults.html)

`ObservedResults`とは超簡単に説明すると SwiftUI の List や Form で RealmSwift のオブジェクトを扱うために作られたラッパープロパティのこと。

というのも、SwiftUI と RealmSwift のライフサイクルのタイミングの違いの問題で、`RealmSwift.List`や`RealmSwift.Results`の結果を List や Form で表示して、それを編集しようとするとバグが発生してしまっていました。

そのために`@ObservableObject`や`freeze`でごにょごにょしなきゃいけなかったのですが、それら全てから開放されるのがこの`@ObservedResults`になります。



## 基本的な使い方

RealmSwift のドキュメントに載っている通りに解説しようと思います。

ちなみに、以下の記事を最初に読んでおくと幸せになれます。

> [RealmCocoa が SwiftUI に正式対応してるっぽい](https://tkgstrator.work/posts/2021/08/05/realmcocoa.html)
>
> [RealmCocoa がまたアップデートしてるんだが](https://tkgstrator.work/posts/2021/07/08/realmswift.html)

### Person クラス

10.10.0 のアップデートで`@Persisted`が推奨になり、`@objc dynamic var`や`RealmOptional`などは全て利用する必要がなくなった。

```swift
import RealmSwift
import SwiftUI

class Person: Object {
    @Persisted(primaryKey: true) var _id: String
    @Persisted var name: String
    @Persisted var age: Int
}
```

### ContentView

作成された`Person`クラスの結果である`RealmSwift.Results<Person>`を List で表示する。

#### 従来の方法

表示するだけなら現在でもこの方法が利用できる。

ただし、Realm はインスタンスに変化があるとその更新の通知が即座に反映されてしまうので、`onMove`や`onDelete`を実装するとクラッシュしてしまう。

```swift
struct ContentView: View {
    // 事前にどこかで`realm`を宣言しておくこと
    @State var persons: realm.objects(Person.self)

    var body: some View {
        List {
            ForEach(persons) { person in
                Text(person.name)
            }
        }
    }
}
```

#### ObservedObject を利用した方法

```swift
import RealmSwift

class Persons: ObservableObject {
    @Published var persons: RealmSwift.Results<Person> = realm.objects(Person.self)
}
```

まず最初に上のように`ObservableObject`を定義しておき、

```swift
struct ContentView: View {
    @ObservedObject var persons: Persons

    var body: some View {
        List {
            ForEach(persons.persons) { person in
                Text(person.name)
            }
        }
    }
}
```

という風に利用する。ただしこれも結局編集しようとすると落ちてしまうので意味がない。

編集しても落ちないようにするためには`freeze`したオブジェクトを List に渡す必要がある。

#### ObservedResults を利用した方法

`freeze`を利用する方法などは学ばずに、バカ正直に Realm 謹製の`@OservedResults`を利用するのが良い。

```swift
struct ContentView: View {
    @ObservedResults(Person.self) var persons

    var body: some View {
        List {
            ForEach(persons) { person in
                Text(person.name)
            }
            .onMove(perform: $persons.move)
            .onDelete(perform: $persons.remove)
        }.navigationBarItems(trailing:
            Button("Add") {
                $persons.append(Person())
            }
        )
    }
}
```

これだけで全く落ちない完璧なコードが書ける。

## フィルタリングやソート

ここで注意しなければいけないのは`@ObservedResults`は中身が`freeze`したオブジェクトであるので、List 等で表示するのは便利だが扱い方が少し異なるという点である。

List として表示するときにソートしたりフィルタリングしたりする方法が異なるので覚えておきたい。

公式ドキュメントでは省略されているが、以下が正しい`@ObservedResults`の宣言方法である。

```swift
@ObservedResults(Person.self, filter: NSPredicate(format: "age >= 20"), sortDescriptor: SortDescriptor(keyPath: "age", ascending: false)) var persons
```

::: tip 更に詳しく述べると

実はこれに加えて更に`configuration`を使って RealmSwift の`Configuration`を設定することも可能である。

が、今回はそこまでは利用しないと考えて割愛した。

:::

### フィルタリング

`NSPredicate`を利用してフィルタリングをすることができる。利用方法は概ね普通に`RealmSwift.Results`に対してフィルタリングする場合と同じなのだが、ちょっと違うところもあるので書いておく。

#### 比較演算子

```swift
// 従来
@State var persons = realm.objects(Person.self).filter("age >= %@", 20)

// NSPredicate
@ObservedResults(Person.self, filter: NSPredicate(format: "age >= %@", argumentArray: [20]))
```

ただのイコール判定をするだけなら比較的わかりやすいのですが、`IN`がミスしやすいです。

```swift
// 従来
@State var persons = realm.objects(Person.self).filter("age IN %@", [20, 24, 30])

// NSPredicate
@ObservedResults(Person.self, filter: NSPredicate(format: "age IN %@", argumentArray: [[20, 24, 30]]))
```

なお、これらを詳しくまとめた記事が[Swift で Realm を使う時の Tips(3) NSPredicate 編](https://qiita.com/nakau1/items/40865299dacc50d71604)で公開されていますので、器になる方はぜひ読んで見てください。

### ソート

ソートには`SortDescriptor`を利用します。

```swift
// 従来
@State var persons = realm.objects(Person.self).sorted(byKeyPath: "age")

// SortDescriptor
@ObservedResults(Person.self, sortDescriptor: SortDescriptor(keyPath: "age"))
```

一応、従来の方法との組み合わせで、

```swift
struct ContentView: View {
    @ObservedResults(Person.self) var persons

    var body: some View {
        List {
            ForEach(persons.sorted(byKeyPath: "age")) { person in
                Text(person.name)
            }
            .onMove(perform: $persons.move)
            .onDelete(perform: $persons.remove)
        }.navigationBarItems(trailing:
            Button("Add") {
                $persons.append(Person())
            }
        )
    }
}
```

みたいな書き方もできますが、`@ObservedResults`は`freeze`でありそのままではリアルタイム更新されないので、これをやると`ObservedResults`と ForEach の中身の ID がズレるので削除したのとは違うカラムが消えてしまいます。

なのでこの書き方は避けるようにしましょう。

記事は以上。


