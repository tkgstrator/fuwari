---
title: Realm + SwiftUI
published: 2021-05-25
description: RealmをSwiftUIで使うためのチュートリアル
category: Programming
tags: [Swift, Realm]
---

## Realm + SwiftUI

Realm は SwiftUI を公式サポートしていないのでいろいろ対応が必要になりますが、その一つがデータ更新時にビューの再レンダリングに対応していないことが挙げられます。

また、データ削除でクラッシュする[Realm でレコードを削除するとクラッシュする問題
](https://tkgstrator.work/posts/2021/05/24/realmrelation.html)もあるので、こちらにも目を通しておいて下さい。

## 再レンダリングの方法

以下は再レンダリングを実行するためのテンプレートである。頻繁に使うので覚えておいたほうが良い。

```swift
import Combine
import SwiftUI
import RealmSwift

let realm = try! Realm()

class RealmCoopResult: Object {
    let goldenEggs = RealmOptional<Int>()
    let powerEggs = RealmOptional<Int>()

    init(goldenEggs: Int?, powerEggs: Int?) {
        self.goldenEggs.value = goldenEggs
        self.powerEggs.value = powerEggs
    }
}

class Tkgstrator: ObservableObject {
    private var token: NotificationToken?

    // 最初の一回しか呼ばれない
    let results: RealmSwift.Results<RealmCoopResult> = realm.objects(RealmCoopResult.self)

    init() {
        // 最初の一回しか呼ばれない
        token = results.observe { [self] _ in
            // データ変更が起こったときに実行される
            objectWillChange.send()
        }
    }
}
```

このコードの場合`objectWillChange.send()`で強制再レンダリングがかかるので変数は`@Published`属性を付けなくても良いことに注意。

::: warning Realm インスタンスの呼び出し方

今回のテンプレートでは`let realm = try! Realm()`で呼び出しているが、この書き方だとマイグレーションが必要なときなどに必ずクラッシュしてしまう。

より柔軟な書き方については別の記事で解説予定。

:::

あと、データの反映を全てのビューで受け取れるように`@EnvironmentObject`を設定する必要がある。

```swift
@main
struct RealmRelationApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(Tkgstrator()) // 追加
        }
    }
}
```

このようにルートビューに`@EnviromentObject`を読み込むように設定する。これで、全てのビューで`Tkgstrator`クラスのデータにアクセスできる。

```swift
// ContentView.siwft
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var data: Tkgstrator // EnvironmentObjectを利用することを明記

    var body: some View {
        NavigationView {
            Form {
                NavigationLink(destination: resultLists, label: { Text("RESULTS") })
                NavigationLink(destination: settingMenu, label: { Text("SETTING") })
            }
        }
    }

    var resultLists: some View {
        Form {
            Button(action: { addData(num: 5) }, label: { Text("ADD DATA") })
            ForEach(data.results, id:\.self) { result in
                HStack {
                    Text("\(result.goldenEggs.value ?? 0)")
                    Spacer()
                    Text("\(result.powerEggs.value ?? 0)")
                }
            }
        }
    }

    var settingMenu: some View {
        Form {
            HStack {
                Text("RESULTS NUM")
                Spacer()
                Text("\(data.results.count)")
            }
            Button(action: { addData(num: 5) }, label: { Text("ADD DATA") })
            Button(action: { deleteAll() }, label: { Text("DELETE ALL") })
        }
    }

    private func addData(num: Int = 100) {
        autoreleasepool {
            realm.beginWrite()
            for _ in 0 ..< num {
                realm.create(RealmCoopResult.self, value: RealmCoopResult(goldenEggs: Int.random(in: 69 ..< 200), powerEggs: Int.random(in: 3000 ..< 5000)))
            }
            try? realm.commitWrite()
        }
    }

    private func deleteAll() {
        autoreleasepool {
            realm.beginWrite()
            realm.deleteAll()
            try? realm.commitWrite()
        }
    }
}
```

## OBservableObject の書き方

さて、ここまでで`RealmSwift.Results`を常に最新のものをとってくることができた。

::: tip 初期化は一回しか行われていないが...

`results`への代入は一回しか行われていないので値が更新されないように思うかもしれないが、`realm`のインスタンスの内部状態は常に最新のものに更新されるので（計算プロパティのようなものと思えば良い）、`results`のプロパティを参照すれば常に最新のデータが取得できる。

:::

データベースを運用していく上では単に全てのリザルトだけでなくさまざまなデータを計算してその結果を返してほしいのだが、それをどうやってコーディングすればいいかを考える。

例えば、それぞれの平均を求めたいとしよう。Realm には平均を返す`average(ofProperty: String)`というものがあるのでこれを利用する。

```swift
// 正しく動かないコード
class Tkgstrator: ObservableObject {
    private var token: NotificationToken?

    let results: RealmSwift.Results<RealmCoopResult> = realm.objects(RealmCoopResult.self)
    let avgGoldenEggs: Double?
    let avgPowerEggs: Double?

    init() {
        avgGoldenEggs = results.average(ofProperty: "goldenEggs") // この時点で値が決まっている
        avgPowerEggs = results.average(ofProperty: "powerEggs") // この時点で値が決まっている

        token = results.observe { [self] _ in
            objectWillChange.send()
        }
    }
}
```

一見すると上のコードで動作しそうな気がするが、これは正しく動かない。というのも、`avgGoldenEggs`というのは`Double?`型の変数であり、`realm`のインスタンスの内部状態に依存しないためだ。つまり、イニシャライザでプロパティに代入した瞬間に値が決まってしまい、`objectWillChange.send()`が呼ばれてもデータが更新されない。

```swift
// 正しく動かないコード
class Tkgstrator: ObservableObject {
    private var token: NotificationToken?

    let results: RealmSwift.Results<RealmCoopResult> = realm.objects(RealmCoopResult.self)
    @Published var avgGoldenEggs: Double?
    @Published var avgPowerEggs: Double?

    init() {
        avgGoldenEggs = results.average(ofProperty: "goldenEggs") // この時点で値が決まっている
        avgPowerEggs = results.average(ofProperty: "powerEggs") // この時点で値が決まっている

        token = results.observe { [self] _ in
            objectWillChange.send()
        }
    }
}
```

それは`@Published`をつけても同様のことがいえる。そもそも、`@Published`自体が「そのプロパティのデータが更新されたときにビューを再レンダリングする」という効果しか持たないので、`objectWillChange.send()`を使うのであれば不要である。

これも、何回実行しても最初のイニシャライザで設定した値から変わらないのでやはり再レンダリングはできない。

## 読み込み時に計算するコード

```swift
// 正しく動作するコード
class Tkgstrator: ObservableObject {
    private var token: NotificationToken?

    let results: RealmSwift.Results<RealmCoopResult> = realm.objects(RealmCoopResult.self)
    var avgGoldenEggs: Double? {
        results.average(ofProperty: "goldenEggs")
    }
    var avgPowerEggs: Double? {
        results.average(ofProperty: "powerEggs")
    }

    init() {
        token = results.observe { [self] _ in
            objectWillChange.send()
        }
    }
}
```

そのためには、例えば変数を計算プロパティにするという方法が考えられる。これは`results`は常に最新のデータを取得するので呼び出すごとに結果が変わり、そのためデータを追加すれば正しくビューの再レンダリングがかかり平均のデータも更新される。

### データを毎回代入するコード

```swift
// 正しく動くコード
class Tkgstrator: ObservableObject {
    private var token: NotificationToken?

    let results: RealmSwift.Results<RealmCoopResult> = realm.objects(RealmCoopResult.self)
    var avgGoldenEggs: Double?
    var avgPowerEggs: Double?

    init() {
        token = results.observe { [self] _ in
            avgGoldenEggs = results.average(ofProperty: "goldenEggs")
            avgPowerEggs = results.average(ofProperty: "powerEggs")
            objectWillChange.send()
        }
    }
}
```

このようにデータベース更新時に毎回代入し直すようなコードでも正しく動作する。

### データを毎回代入するコード

`objectWillChange.send()`を使わず、`@Published`を利用する方法でも良い。

が、何度も`@Published`を書くことになるので、個人的には一回だけ`objectWillChange.send()`を使うほうが楽そうな気はする。

```swift
// 正しく動くコード
class Tkgstrator: ObservableObject {
    private var token: NotificationToken?

    @Published var results: RealmSwift.Results<RealmCoopResult> = realm.objects(RealmCoopResult.self)
    @Published var avgGoldenEggs: Double?
    @Published var avgPowerEggs: Double?

    init() {
        token = results.observe { [self] _ in
            avgGoldenEggs = results.average(ofProperty: "goldenEggs")
            avgPowerEggs = results.average(ofProperty: "powerEggs")
        }
    }
}
```

## 現時点でオススメのコード

### 計算内容が重い場合

```swift
class Tkgstrator: ObservableObject {
    private var token: NotificationToken?

    let results: RealmSwift.Results<RealmCoopResult> = realm.objects(RealmCoopResult.self)
    var avgGoldenEggs: Double?
    var avgPowerEggs: Double?

    init() {

        token = results.observe { [self] _ in
            avgGoldenEggs = results.average(ofProperty: "goldenEggs")
            avgPowerEggs = results.average(ofProperty: "powerEggs")
            objectWillChange.send()
        }
    }
}
```

このコードの注意すべき点はデータベースに何らかの変更があったときに、毎回クロージャ内の計算が実行されてしまうということである。

つまり、100 件のデータ書き込みを 1 件ずつ行っていると毎回計算処理が発生して非常にパフォーマンスがよろしくない。

```swift
realm.beginWrite()
for result in results {
    // データ書き込み（実際には書き込まれていない）
}
try? realm.commitWrite() // ここで全件書き込み
```

のように 100 件同時書き込みをするようにコーディングすること。こうすれば 100 件データが追加されたあとでしか計算処理が発生しない。

### 計算内容が軽い場合

```swift
// 正しく動作するコード
class Tkgstrator: ObservableObject {
    private var token: NotificationToken?

    let results: RealmSwift.Results<RealmCoopResult> = realm.objects(RealmCoopResult.self)
    var avgGoldenEggs: Double? {
        results.average(ofProperty: "goldenEggs")
    }
    var avgPowerEggs: Double? {
        results.average(ofProperty: "powerEggs")
    }

    init() {
        // メモリリークを防ぐために弱参照を用いる
        token = results.observe { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
}
```

現時点ではこのコードが一番オススメかなあという気がしている。なんといっても、イニシャライザが非常に簡単にかけることが大きい。

スパゲッティコードになることを防ぎやすく、わかりやすさでは一番の気がしている。

::: warning 注意点

ただし、どちらの場合もイニシャライザやクロージャ内や計算プロパティ内に重い処理を書いているとアプリがフリーズしたような状態になってしまうので、それを防ぐためには`DispatchQueue`を使ってメインスレッド以外で実行する必要が出てくる。

このとき、全部の計算プロパティをいちいち別スレッドで実行するのもめんどくさいので、重い処理が多いときは前者の書き方のほうが良いかもしれない。

:::

というわけで、SwiftUI と Realm の組み合わせの仕方について学びました。

これを使ってアプリ開発を勧めていきたいと思いました、まる。

記事は以上。
