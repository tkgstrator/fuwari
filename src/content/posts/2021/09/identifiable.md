---
title: Identifiableに適合させるお話
published: 2021-09-27
description: SwiftのプロトコルにIdentifiableというものがあるのですが、それを完全に勘違いしていたという話
category: Programming
tags: [Swift, SwiftUI]
---

# [Identifiable](https://developer.apple.com/documentation/swift/identifiable)

Swift における Identifiable とは要するに識別可能で、データが重複しないことを保証するためのプロパティである。



## ForEach

例えば、SwiftUI では`ForEach`を使うときに以下のようなコードを書いた経験が誰にでもあると思う。

### Range

```swift
struct ContentView: View {
    var body: some View {
        Form {
            ForEach(1 ..< 6) { index in
                Text("\(index)")
            }
        }
    }
}
```

::: tip Range 型について

整数の範囲をとるので`1 ... 5`のような書き方はできない。これはコンパイルエラーになる

:::

### 配列 + インデックス

`ForEach`はもともと配列をループするための関数なので、配列を使って以下のように書くこともできる。

```swift
struct ContentView: View {
    let users: [String] = ["Mike", "John", "Kate", "Mary"]
    var body: some View {
        Form {
            ForEach(0 ..< users.count) { index in
                Text(self.users[index])
            }
        }
    }
}
```

より便利な方法として、

```swift
struct ContentView: View {
    let users: [String] = ["Mike", "John", "Kate", "Mary"]
    var body: some View {
        Form {
            ForEach(users.indices) { index in
                Text(self.users[index])
            }
        }
    }
}
```

という書き方を知っている人がいるかも知れない。`indices`は`index`の複数形で要するに配列のインデックスを返す。

つまり、この場合だと`[0, 1, 2, 3]`が返ってくるというわけである。

### 配列 + オブジェクト

ただ、インデックスではなくてオブジェクト自体がほしいという場合もある。

何故ならオブジェクト自体が返ってくるのであれば以下のようにより完結にコードを書くことができるためだ。

```swift
struct ContentView: View {
    let users: [String] = ["Mike", "John", "Kate", "Mary"]
    var body: some View {
        Form {
            ForEach(users) { user in
                Text(user)
            }
        }
    }
}
```

ここで問題となるのは果たして`ForEach(users)`というのは有効な書き方なのかどうかということである。

結論から言えばこの書き方はコンパイルエラーを招く、何故か？

::: warning コンパイルエラー

正確にはコンパイルの前に、

> Referencing initializer 'init(\_:content:)' on 'ForEach' requires that 'String' conform to 'Identifiable'

というエラーが発生するのでそもそもコンパイルを実行できない。

:::

## SwiftUI は Identifiable を前提としている

SwiftUI では「View やそれらのコンポーネントが識別可能で互いに異なるものである」ということを前提としている。

なので、ForEach で View を複数生成するときに「全く同じもの」を生成してしまうとバグが発生するのである。

`Identifiable`に適合させるためには`id`というプロパティを設定する必要があるのですが、適合していなくてもプログラマが「`Identifiable`である」ということを`ForEach`に情報として与えてやれば利用することができます。

先程のコードの場合は`ForEach(users, id:\.self)`と書くことで「`id`として`self`を利用する」ということが明示できます。

```swift
struct ContentView: View {
    let users: [String] = ["Mike", "John", "Kate", "Mary"]
    var body: some View {
        Form {
            ForEach(users, id:\.self) { user in
                Text(user)
            }
        }
    }
}
```

このとき、それぞれの文字列は別々のインスタンスですので、互いに識別可能で SwiftUI がクラッシュするようなこともありません。

::: tip 文字列が重複しても大丈夫

`\.self`プロパティはそれ自身の中身ではなくてインスタンス自体を参照するので`let users: [String] = ["Mary", "Mary", "Mary"]`のように重複していても大丈夫です。

`struct`のオブジェクトもコピーを生成するので問題ないですが、`class`のオブジェクトはコピーではなくポインタを利用するので全く同一のオブジェクトが作成されるためこの方法は利用できません、多分。

:::

### Struct を渡す場合

例えば、以下のように`User`の構造体を作成してそれを`ForEach`でループすることを考えます。

```swift
struct ContentView: View {
    let users: [User] = [
        User(name: "Mary", age: 20),
        User(name: "Kate", age: 24),
        User(name: "Mike", age: 22)
    ]

    var body: some View {
        Form {
            ForEach(users, id:\.self) { user in
                HStack(content:  {
                    Text(user.name)
                    Spacer()
                    Text("\(user.age)")
                })
            }
        }
    }

    struct User {
        internal init(name: String, age: Int) {
            self.name = name
            self.age = age
        }

        let name: String
        let age: Int
    }
}
```

すると、`Generic struct 'ForEach' requires that 'ContentView.User' conform to 'Hashable'`というエラーが発生します。

```swift
struct User: Hashable {
    internal init(name: String, age: Int) {
        self.name = name
        self.age = age
    }

    let name: String
    let age: Int
}
```

このときは構造体に`Hashable`であることを明示することでエラーを解消できます。

### Class を渡す場合

クラスの場合は構造体と違って`Hashable`に適合させる必要はありません。

```swift
struct ContentView: View {
    let users: [User] = [
        User(name: "Mary", age: 20),
        User(name: "Kate", age: 24),
        User(name: "Mike", age: 22)
    ]

    var body: some View {
        Form {
            ForEach(users) { user in
                HStack(content:  {
                    Text(user.name)
                    Spacer()
                    Text("\(user.age)")
                })
            }
        }
    }

    class User: Identifiable {
        internal init(name: String, age: Int) {
            self.name = name
            self.age = age
        }

        let name: String
        let age: Int
    }
}
```

ちょっとだけ短く書くことができますね。

## Identifiable + SwiftUI

で、ここからが本番になります。

SwiftUI でアラートなどを表示させる際には予めエラー用の View を用意しておいてそこにデータを代入して表示させるような仕組みになっています。

もし、エラーがたった一つしか種類がないのであれば、

```swift
struct ContentView: View {
    @State var isPresented: Bool = false

    var body: some View {
        Button(action: {
            isPresented.toggle()
        }, label: {
            Text("ALERT")
        })
        .alert(isPresented: $isPresented, content: {
            Alert(title: Text("ERROR"))
        })
    }
}
```

のようなコードで実装できます。要するに、アラートを表示するかどうかを`isPresented`で制御しているということです。

ただ、場合によっては複数のエラーが返ってくる可能性があるようなケースもあります。そのときにエラーの数だけ`alert`や`isPresented`を定義するのは馬鹿らしいです。

そこで利用できるのが`.alert(item: <Binding<Identifiable?>, content: (Identifiable) -> Alert)`というプロパティです。

### item を利用する

この仕組みの面白いところは`item`に指定されたプロパティが変化すれば`isPresented == true`と同じ処理が実行されアラートが表示されるということです。

そしてアラートを閉じればそのときにプロパティに`nil`が代入されます。要するに、複数の`isPresented`を定義しなくてもこの`item`さえあればすべてまかなえることになります。

そして、重要な点はこの`item`は`Identifiable`に適合していなくてはいけないという点です。

```swift
struct ContentView: View {
    @State var appError: APPError? = nil // 初期値はnilにしておこう

    var body: some View {
        Button(action: {
            // ランダムにエラーを一つ発生させる
            appError = APPError.allCases.randomElement()
        }, label: {
            Text("ALERT")
        })
        .alert(item: $appError, content: { appError in
            // オプショナルを外してエラーの中身を取得し、表示
            Alert(title: Text(appError.type))
        })
    }

    enum APPError: Error, CaseIterable {
        case server
        case app

        var type: String {
            switch self {
            case .server:
                return "SERVER"
            case .app:
                return "APPLICATION"
            }
        }
    }
}
```

サンプルコードはこのような感じで、エラー型プロトコルに準拠した`APPError`という`Enum`を作成し、ボタンを押せばランダムにどちらかのエラーが発生するようにします。

で、このままだとコンパイルエラーがでるのでビルドできません。先程も言ったように`Identifiable`に準拠していないからです。

そこで`id`のプロパティを追加して、`Identifiable`に準拠させます。

`id`は識別可能である必要があるので、被ってはいけません。そこで非常に低い確率でしか重複しない`UUID`を利用してみます。すると、コードは以下のように書けます。

```swift
enum APPError: Error, CaseIterable, Identifiable {
    var id: UUID { UUID() }

    case server
    case app

    var type: String {
        switch self {
        case .server:
            return "SERVER"
        case .app:
            return "APPLICATION"
        }
    }
}
```

で、これはちゃんと動いているように見えるのですが恐ろしいバグをはらんでいるのです...

#### アラートが二回表示されるバグ

一つの View だけで動作させている場合にはこれで上手くいっているように見えるのですが、ライブラリ化などした場合に問題が発生します。

というのもこの書き方だとエラーの Enum が呼ばれるたびに UUID がセットされてしまうので、「異なるエラーは異なる ID を持つ」という条件を満たすのですが、「同一のエラーであれば同じ ID を持つ」という条件が満たされないのです。

よって、この APPError がライブラリ等から呼ばれた際に、同じエラーにも関わらず違う ID が与えられているために`.alert(item: <Binding<Identifiable?>, content: (Identifiable) -> Alert)`が二回呼び出され、結果的にアラートが無意味に二回表示されるというバグが発生するのです。

なお、これは`alert`に限らず`item`を利用する`ViewModifier`全てで発生する可能性があります。

### 正しい Identifiable を設定

このバグを直すためには同一の Enum であれば常に同じ ID を返すようにすれば良いです。

いろいろ方法はありますが、簡単なのは`RawValue`を利用することでしょう。`Enum`は必ず`RawValue`はそれぞれの`case`で異なる必要があるので、`RawValue`を Id とすれば絶対に重複しません

```swift
// RawValueとしてIntを設定する
enum APPError: Int, Error, CaseIterable, Identifiable {
    var id: Int { rawValue }

    case server
    case app

    var type: String {
        switch self {
        case .server:
            return "SERVER"
        case .app:
            return "APPLICATION"
        }
    }
}
```

型自体は何でも良いので、とりあえず型付き Enum にしてやれば問題は解決します。


