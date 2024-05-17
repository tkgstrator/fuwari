---
title: Realmでレコードを削除するとクラッシュする問題
published: 2021-05-24
description: Realmでレコードを削除するとアプリがクラッシュしてしまう場合があるのですが、今回は何故クラッシュするのか、対策と解決策について考えます
category: Programming
tags: [Swift, Realm]
---

## Realm がクラッシュする問題

Realm はモバイル向けのデータベースで、軽量かつ高速でいろいろなアプリで利用されています。

有名どころだと ikaWidget2 や Salmon Rec などが Realm を採用しています。Salmonia が Realm を採用したのも、これらの二つのアプリが Realm を採用していて勉強しやすかったというのがあります。

## Realm のリレーション

Realm には`LinkingObject`という各テーブル同士を繋げるような仕組みがあります。これだけだとさっぱりわからないので、公式ドキュメントを使って例を作ります。

```swift
import Foundation
import RealmSwift

class Dog: Object {
    dynamic var name = ""
    dynamic var age = 0
}
```

例えば、上のように`Dog`クラスを作成し、犬の名前と年齢をデータベースに保存していく場合を考えます。

|  name  | age |
| :----: | :-: |
|  Taro  |  3  |
| Hanako |  4  |
| Wanko  |  5  |

すると、こんな感じでどんどんレコードを追加していくことができます。

これだけでも十分データベースとして役割は果たせているのですが、実際に運用していくだけでは少し物足りない気もします。

野良犬でなければ犬には必ず飼い主がいるので、飼い主情報も保存したいとします。

```swift
class Person: Object {
    dynamic var name = ""
    dynamic var gender = ""
}
```

飼い主情報としては名前と性別を今回は保存することにしました。

| name  | gender |
| :---: | :----: |
| Alice | female |
|  Bob  |  male  |

すると、例えば上のようなレコードが追加されるわけです。

ここで大事になるのは「飼い主は複数の犬を飼っている可能性がある」が、「一匹の犬には複数の飼い主がいることはない」ということです。

このような関係を「多対一」の関係と呼び、それぞれの飼い主が飼っている犬の情報も保存しておきたいわけです。

## List を使って実装する

そこで、飼い主が飼い犬の情報を保存できるようにクラスを改良します。一人の Person クラスのオブジェクトが複数の Dog クラスのオブジェクトを持ちたいのですが、これは Realm では`List`を使って実装できます。

`List`は`Int`や`String`型などの情報の他に`Realm Object`自体をもリスト化することができます。

```swift
class Person: Object {
    dynamic var name = ""
    dynamic var gender = ""
    let dogs = List<Dog>() // 追加
}
```

つまり、このように書くことができるというわけです。

| name  | gender |     dogs     |
| :---: | :----: | :----------: |
| Alice | female | Taro, Hanako |
|  Bob  |  male  |    Wanko     |

こういうデータベース構造をつくれば、このように「Alice という女性が Taro と Hanako を飼っている」「Bob という男性が Wanko を飼っている」という情報が簡潔に保存できることになります。

この構造があれば、飼い主情報がわかればそれぞれの飼い犬情報が取得できます。

```swift
let dogs = alice.dogs
for dog in dogs {
    print(dog.name, dog.age)
}
```

上は擬似コードなのでそのままでは動作しませんが、このようなコードを書くことで Alice の飼い犬情報をループして全ての飼い犬の名前と年齢を表示させることができます。

ここまでできれば問題なさそうな気がするのですが、「飼い主情報から飼い犬情報は参照できる」が「それぞれの犬から飼い主情報を参照できない」という問題が残ります。

つまり「年齢が三歳以上の飼い犬がいる飼い主の名前」を調べようとしたときに、「三歳以上の犬 -> その飼い主」のデータを読み込むことができないのです。

::: tip 愚直な解決策

もちろん、全ての飼い主をループして、更にその飼い犬をループして三歳以上の犬がいれば～という条件分を書くことはできます。

ただし、それを実装すると二重ループが必要になり実行速度が犠牲になってしまう。

:::

この問題を解決するのが逆方向の参照（バックリンク）である`Linking Object`になります。

## Linking Object

`Linking Object`は以下のように`List`に対してリンクを張ります。

```swift
import Foundation
import RealmSwift

class Dog: Object {
    dynamic var name = ""
    dynamic var age = 0
    let owner = LinkingObjects(fromType: Person.self, property: "dogs") // 追加
}

class Person: Object {
    dynamic var name = ""
    dynamic var gender = ""
    let dogs = List<Dog>()
}
```

今回の場合ですと、`Person`クラスの`dogs`というプロパティが`Dog`クラスへの多対一のリンクになっているので、そのバックリンクとして`Linking Object`を設定します。

このようなリンクを張っておけば、

```swift
let dog = taro
print(dog.owner.name) // Alice
```

のような感じで飼い主情報を参照することができます、便利ですね。

## アプリクラッシュの条件

ここまでで LinkingObjects が何故必要か、あるとどう便利なのかを解説しましたが、ここからコーディングの際のトラップについて解説します。

Realm は SwiftUI を正式サポートしていないため、力技で実装することになるのですがそのためいろいろなところでエラーが発生したりします。

今回はその中でも最も困る「レコードを削除するとアプリがクラッシュする」問題について解説します。

このときデバッグコンソールに出力されるエラーメッセージは以下のとおりです。

```
*** Terminating app due to uncaught exception 'RLMException', reason: 'Object has been deleted or invalidated.'
terminating with uncaught exception of type NSException
```

要するに削除されて「有効でない」または「削除済み」のデータにアクセスしようとしてエラーが発生しているわけですね。

### 1. リアルタイム反映させている

一つ目の発生条件は、削除しようとしているクラスに対して`observe`で SwiftUI に再レンダリングをかけているということです。再レンダリング処理をしていなければ当該の問題は発生しませんが、そうするとレコードを追加しても SwiftUI 側に反映されないので、再レンダリング処理をしていない人はいないと思います。

::: tip 再レンダリングについて

SwiftUI は構造体を使っているため、プロパティが変化したことを SwiftUI フレームワークに伝えて画面を再レンダリングするための仕組みがあります。

:::

それが`@State`や`@Binding`や`@ObservedObject`における`@Published`になるのですが、これをそのまま Realm でやろうとすると失敗します。

というのも`@Published`はインスタンスの値自体が変わったタイミングでしか通知がこないので、インスタンスの内部状態が変わってもその変更を受け取れないためです。

そこで`observe` メソッドを利用して、Realm のデータベースに変更が起きる度にクロージャ内の処理を実行し、クロージャ内で`@Published`の値を変更すれば、

`Realm -> observe -> Closure -> @Published -> SwiftUI`という流れで再レンダリングがかかります。

これらの仕様については[こちらの記事](https://qiita.com/chocoyama/items/af172b32f492b706c96d)が大変参考になりました。

```swift
import Combine

class Dogs: ObservableObject {
    private(set) var dogs = realm.objects(Dog.self)
    private var token: NotificationToken?

    init() {
        token = realm.objects(Dog.self).observe { [self] _ in
            self.objectWillChange.send()
        }
    }

    deinit {
        token?.invalidate()
    }
}
```

例えば、常に最新の`RealmSwift.Results<Dog>`を持ちたい場合には次のような`ObservableObject`を継承したクラスを定義します。

これは`dogs`が常に最新の`RealmSwift.Results<Dog>`を持っているにも関わらず、View が再レンダリングされないことを防ぐため、Realm の`Dog`のデータベースに何らかの変更があった場合に`self.objectWillChange.send()`で SwiftUI に再レンダリングを促すためのコードです。

`dogs`自体は最新のデータを持っているので、再レンダリングがかかれば望んでいるデータが手に入るというわけですね。

::: tip 再レンダリングのタイミング

コードを読めばわかるのだが`NotificationToken`は`realm.objects(Dog.self)`から発行されている。つまり`realm.obbjects(Dog.self)`のレコードが変更されたときにしかこのクロージャは呼び出されない。

:::

### 再レンダリングの不思議

ここで以下の`Dog`クラスを管轄する`Dogs`クラスと`Person`クラスを管轄する`Persons`クラスを考える。

なお、`Dog`と`Person`は以下の定義を用い、今回はお互いが完全に独立したものとして扱う。

```swift
// Realm.swift
import Foundation
import RealmSwift

class Dog: Object {
    dynamic var name = ""
    dynamic var age = 0
}

class Person: Object {
    dynamic var name = ""
    dynamic var gender = ""
}
```

```swift
// RealmModel.swift
import Foundation
import RealmSwift
import Combine

class Dogs: ObservableObject {
    var objectWillChange: ObservableObjectPublisher = .init()
    private(set) var dogs = realm.objects(Dog.self)
    private var token: NotificationToken?

    init() {
        token = realm.objects(Dog.self).observe { [self] _ in
            // 何もしない
        }
    }

    deinit {
        token?.invalidate()
    }
}

class Persons: ObservableObject {
    var objectWillChange: ObservableObjectPublisher = .init()
    private(set) var persons = realm.objects(Person.self)
    private var token: NotificationToken?

    init() {
        token = realm.objects(Person.self).observe { [self] _ in
            self.objectWillChange.send()
        }
    }

    deinit {
        token?.invalidate()
    }
}
```

これはやればわかると思うのだが、`Dog`にデータを追加してもビューは再レンダリングされず、`Person`にデータを追加したときにだけ再レンダリングがかかる。これは実際、そのように動作する。

|         |      追加      |      削除      |
| :-----: | :------------: | :------------: |
|  Dogs   |    されない    |    されない    |
| Persons | 再レンダリング | 再レンダリング |

::: tip 勘違いしやすい点

ここで勘違いされやすいのは`Dogs`はいつまで経っても更新されないと思ってしまうことである。

それは誤りで、データベースが更新される度に`Persons`クラスは絶えず更新されている。ただ、その更新が行われたということを SwiftUI が検知できず、ビューが再レンダリングされていないだけなのである。

つまり`Person -> Dog`という順でデータを更新された場合には最初の`Person`の更新の時点までしかビューが再レンダリングされないが、`Dog -> Person`の順でデータを更新した場合には`Dog`は正しく最新の情報が表示されるのである。

:::

### リンクを張ってみる

では次に、Realm.swift だけ更新し、`Person -> Dog`への多対一のリンク(List)を持つようにする。

```swift
// Realm.swift
import Foundation
import RealmSwift

class Dog: Object {
    dynamic var name = ""
    dynamic var age = 0
    let owner = LinkingObjects(fromType: Person.self, property: "dogs") // 追加
}

class Person: Object {
    dynamic var name = ""
    dynamic var gender = ""
    let dogs = RealmSwift.List<Dog>() // 順リンクを追加
}
```

すると先ほどと同じで、やはり Dog が更新されたタイミングでしか再レンダリングはかからない。

|         |      追加      |      削除      |
| :-----: | :------------: | :------------: |
|  Dogs   |    されない    |    されない    |
| Persons | 再レンダリング | 再レンダリング |

これ自体に特別な意味はないのだが、Dog クラスと Person クラスにこのような関係性がある場合「Dog だけを追加する」というような状態がないのがわかるだろうか？

例えば Bob が新たに Wataru という犬を飼いはじめ、それをデータベースに入力する場合を考えよう。このとき、単純に Wataru という犬のレコードを Dog クラスに追加するのは意味がない。何故なら、Dog クラスには「誰が飼い主であるか」という情報をプロパティではなくバックリンクでしか持っていないためである。

|  name  | age |
| :----: | :-: |
|  Taro  |  3  |
| Hanako |  4  |
| Wanko  |  5  |
| Wataru |  3  |

| name  | gender |     dogs     |
| :---: | :----: | :----------: |
| Alice | female | Taro, Hanako |
|  Bob  |  male  |    Wanko     |

もしも単純に`Dog`クラスに追加した場合には次のように`Person`クラスの`dogs`の配列が更新されないため、Wataru のバックリンクを参照したときに`nil`が返ってきてしまう。

これを防ぐためには「Bob の`dogs`プロパティに Wataru を追加する」という処理を行わねばならない。つまり、バックリンクを持つデータベースにデータが「追加」されるのであれば、それは「バックリンク先だけで再レンダリング処理考えれば良い」ということになる。

::: tip Realm の挙動について

今回のように`Person -> Dog`のリレーションがある場合、`Person`にデータを追加する際は必ず「子（Dog）」->「親（Person）」の順でデータベースの更新がかかるので、`Person`クラスの変更だけをチェックするような仕組みにすれば良い。

:::

### データ更新

なので「追加」という観点から見ればバックリンクを持つデータベースには再レンダリング処理を記述しなくていいことになるが、今回のケースでは実は`Dog`クラスにも再レンダリングのコードを書かなければいけない。

というのも、再レンダリングが必要になるのは何も「データ追加」だけではなく「データ更新」の場合にも必要になるからである。

例えば、飼い犬の名前を変えたい場合などは別に`Person`クラスのデータは一切更新しない。こういう場合は`Person`のデータが変わっただけで再レンダリング処理をしていると飼い犬の名前が変更されたときに SwiftUI が再レンダリングをかけることができない。

### 2. プライマリキーを設定している

二つ目の条件は削除しようとしているデータベースにプライマリキーが設定されているということです。

```swift
class Dog: Object {
    dynamic var name = ""
    dynamic var age = 0
    let owner = LinkingObjects(fromType: Person.self, property: "dogs")

    // 追加
    override static func primaryKey() -> String? {
        return "name"
    }
}
```

このように飼い犬の名前が重複しないように（名前は重複しやすいので、名前にプライマリキーをつけることは基本的にありませんが）プライマリキーを設定すると削除時にクラッシュします。

## 結論

いろいろ調べてクラッシュする原因をだいぶ突き止めた気がする。

困ったことは`NavigationView`を使った場合と`TabView`を使った場合で挙動が異なるということ。まじで意味わからん。

### NavigationView の場合

![](https://pbs.twimg.com/media/E2JMfZqVcAAqmdU?format=png)

NavigationView の場合は`objectWillChange`を指定しなくても`NavigationLink`で遷移すると`ForEach`の中身が自動で再レンダリングされるようだ。

ただし、`ForEach`以外は再レンダリングされないので`objectWillChange`を使わなくても良いということではない。

「追加」は問題ないが「削除」を`ForEach`と同じビューで実行してはいけない。

::: tip 削除と同じビューとは

```swift
From {
    Button(action: { deleteAll() }, label: { Text("DELETE") }) // dogsのレコードを削除する
    ForEach(dogs) { dog in
        Text(dog.name) // ForEachなのでwillObjectChangeがなくても更新される
    }
    Text("\(dogs.count)") // ForEachでないので更新されない
}
```

のように dogs(RealmSwift.Results)自体を弄るような関数を同じビューに書いてはいけないということを意味する。

:::

その場合、プライマリキーがあれば`Invalidate`を、なければ`Index out of range`のエラーを返す。これは`objectWillChange`があってもなくても関係ないので覚えておくこと。

[Realm Swift + SwiftUI でテーブル表示・編集・削除](https://llcc.hatenablog.com/entry/2020/04/26/205254)のページにもあるように`RealmSwift.Results`ではなく、それを配列に変換したものなどを使うと良い。

### TabView の場合

![](https://pbs.twimg.com/media/E2JMixiVIAIwiUu?format=png)

TabView の場合、NavigationView のように別のビューが表示されている扱いではなく「全てのタブが同時に表示されている」ような状態になっている。

なので例えば、A、B、C 三つのタブがあり、A のタブで`ForEach`でレコードの中身を表示していて B のタブでプライマリキーが設定されているレコードの削除を行うと`Invalidate`がでる。

また、NavigationView と違い、View を再表示したときに強制再レンダリングが発生しないため`objectWillChange`を書かないと何も反映されない。

::: tip TabView と NavigationView の違い

要するに「TabView において A でレコード表示、B でレコード削除」というのは「一つの View でレコード表示、レコード削除」をしているのとほとんど同じ状態になっている。

ただし、`index out of range`のエラーは何故か発生しないのでプライマリキーが設定されていないのであればエラーは起きない。ここが不思議なところの一つである。ただし、NavigationView と同じように「A でレコード表示、A でレコード削除」とすればやはり`index out of range`が発生する。

:::

## まとめ

|                          |        NavigationView         |            TabView            |
| :----------------------: | :---------------------------: | :---------------------------: |
|     objectWillChange     |     ForEach 内は自動更新      |             必須              |
| 同一ビューでレコード追加 |           問題なし            |           問題なし            |
| 同一ビューでレコード削除 | Invalidate/Index out of range | Invalidate/Index out of range |
|  別ビューでレコード追加  |           問題なし            |           問題なし            |
|  別ビューでレコード削除  |           問題なし            |      Invalidate/問題なし      |

::: warning Invalidate について

現状、プライマリキーを設定している場合にしか発生しないようだ。

:::
