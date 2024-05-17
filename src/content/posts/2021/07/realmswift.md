---
title: RealmCocoaがまたアップデートしてるんだが
published: 2021-07-08
description: RealmSwiftがアップデートされて大幅に変更されていました
category: Programming
tags: [Swift, RealmSwift]
---

# [RealmSwift](https://github.com/realm/realm-cocoa)

RealmSwift が[10.10.0](https://github.com/realm/realm-cocoa/releases/tag/v10.10.0)にアップデートされて大幅な変更が入っていました。

## RealmSwift 10.10.0

### 新規機能

- 全てのプロパティが同一の方法で宣言できる
- プライマリキーの設定が簡単になった
- リストも簡単に宣言できる
- `RawRepresentable`が`@Persisted`に対応している型であれば Enum も保存できる
- `Map.merge()`が実装され、辞書形式ペアを他の`Map`や`Dictionary`に変換できるようになった
- `Map.asKeyValueSequence()`が実装され、辞書形式の配列を返すようになった

### バグ修正

- より多くの Enum オブジェクトをサポート
- `RealmProperty<AnyRealmValue?>`を宣言するとエラーを返す問題
- `KVO`を経由して`RLMDictionary/Map`の`Invalidated`の通知が正しく設定されない問題

## 使い方

全てのプロパティを`@Persisted`で宣言できるのはとても便利。もっと早くコレに対応すべきだったのでは。

### 旧コード

```swift
// Legacy
class User: Object {
    @objc dynamic var id: Int = 0       // Int
    let age = RealmOptional<Int>() = 0  // RealmOptional<Int>
    let age = RealmProperty<Int?>() = 0 // RealmProperty<Int?>

    // Primary Key
    override static func primaryKey() -> String? {
        return "id"
    }
}
```

### 新コード

```swift
// Modern
class User: Object {
    @Persisted var id: Int = 0      // Int
    @Persisted var age: Int? = 0    // Int?

    // Primary Key
    @Persisted(primaryKey: true) userId: Int = 0
    @Persisted(indexed: true) point: Int = 0
    // Enum
    @Persisted var userType: UserType = .standard
}

enum UserType: Int, PersitableEnum {
    case standard   = 0
    case unlimited  = 1
}
```

### LinkingObjects

`LinkingObjects`はちょっと書き方が変わっていました。ドキュメントも古いままなのでわからなかったのですが、テストコードを読んでようやく意味を理解。

```swift
class User: Object{
    @Persisted var cats: List<Cat> = List<Cat>()

    override init() {
        super.init()
        self.cats.append(Cat(name: "Mike"))
    }
}

class Cat: Object {
    @Persisted var name: String = ""

    // Legacy
    let owner = LinkingObjects(fromType: User.self, property: "cats")

    // Modern
    @Persisted(originProperty: "cats") var owner: LinkingObjects<User>

    // Convenience
    convenience init(name: String) {
        self.init()
        self.name = name
    }
}
```

::: warning イニシャライザ

引数を取るイニシャライザを定義した場合、`convenience`と`self.init()`を書かないと実行時にエラーが発生します。

:::

`LinkingObject`をたどるためには、

```swift
let owner = cat.owner.first!
guard let owner = cat.owner.first else { return }
```

のようにしてアクセスすれば良い。しかし、バックリンクは一つしかないはずなのに何故`first`が必要なのかがわからない。

```swift
LinkingObjects<User> <0x7f9da952a1a0> (
	[0] User {
		id = 27;
		age = 43;
		cats = List<Cat> <0x600001d9d290> (
			[0] Cat {
				age = 1;
				name = Mike;
			}
		);
		userType = 0;
	}
)
```

ちなみに`LinkingObject`自体は参照すると上のようなデータを持っていたので、やはり`[0]`番目にアクセスするには`first`とつけなければいけないようだ。

### 疑問点

以下のプロパティは使い方がいまいちわからなかった。

```swift
@Persisted(wrappedValue: 100) var id: Int
@Persisted var id: Int = 100
```

この二つ、ほとんど同じように感じますし、実際に実行するとどちらも初期値 100 で初期化されています。

### 注意点

単にクラスを定義するだけなら以下のように書けます。

```swift
class User: Object {
    @Persisted(primaryKey: true) var id: Int = 0
    @Persisted var age: Int? = 0

    // Override
    override init() {
        self.id = Int.random(in: Range(0 ... 100))
        self.age = Int.random(in: Range(0 ... 100))
    }
}
```

イニシャライザを`override`しなければいけないことだけ忘れないように。

`RealmSwift.List`を定義するとちょっとだけややこしくなります。

```swift
class User: Object {
    @Persisted(primaryKey: true) var id: Int = 0
    @Persisted var age: Int? = 0
    @Persisted var cats: List<Cat>

    override init() {
        self.id = Int.random(in: Range(0 ... 100))
        self.age = Int.random(in: Range(0 ... 100))
        self.cats.append(Cat(name: "Mike"))
    }
}

class Cat: Object {
    @Persisted var name: String = ""

    override init(name: String) {
        self.name = name
    }
}
```

こうすると初期化されていない`cats`に値を代入しようとしているとエラーが出ます。

```swift
class User: Object {
    @Persisted(primaryKey: true) var id: Int = 0
    @Persisted var age: Int? = 0
    @Persisted var cats: List<Cat>

    override init() {
        super.init()    // Required
        self.id = Int.random(in: Range(0 ... 100))
        self.age = Int.random(in: Range(0 ... 100))
        self.cats.append(Cat(name: "Mike"))
    }
}

class Cat: Object {
    @Persisted var name: String = ""

    override init(name: String) {
        self.name = name
    }
}
```

この場合はイニシャライザ内で`super.init()`を実行しなければいけません。

## マイグレーションのタイミング

データベースのマイグレーションおよびスキームバージョンのアップデートは起動時に行われるべきです。

ただし、いくつかの注意点があります。

```swift
import SwiftUI
import Realm
import RealmSwift

// グローバル変数で定義してはいけない
let realm = try! Realm()

@main
struct RealmSwiftDemoApp: SwiftUI.App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        #if DEBUG
        let config = Realm.Configuration(schemaVersion: 1, deleteRealmIfMigrationNeeded: true)
        Realm.Configuration.defaultConfiguration = config
        #else
        let config = Realm.Configuration(schemaVersion: 1)
        Realm.Configuration.defaultConfiguration = config
        #endif
        return true
    }
}
```

このように`let realm = try! Realm()`をグローバルで宣言すると、どこからでも利用できて便利なのですが`Realm.Configuration`でスキームバージョンを上げるよりも前に初期化されてしまうのでクラッシュします。

というよりも、`realm`のインスタンスはグローバルにすべきではありません。

何故なら、こうするとありとあらゆるファイルからデータベースの更新が可能になってしまい、コードの追加等で意図しないタイミングでデータベースが更新されてしまうからです。

なので、データベースを更新する専用のクラスをつくるほうが無難です。

### データベース更新用のクラス

```swift
import Foundation
import RealmSwift

final class RealmManager {
    private static let realm = try! Realm()

    class Objects {
        static var users: RealmSwift.Results<User> {
            return realm.objects(User.self)
        }
    }
}
```

というわけで以下のようなクラスをつくってみた。

## SwiftUI から削除するとクラッシュする問題

```swift
    @State var users = RealmManager.Objects.users

    var body: some View {
        Form {
            ForEach(users) { user in
                Text("\(user.id)")
            }
            .onDelete(perform: delete)
        }
    }

    private func delete(offsets: IndexSet) {
        guard let realm = try? Realm() else { return }
        if let index = offsets.first {
            try? realm.write {
                realm.delete(users[index])
            }
        }
    }
```

で、例えばこんなコードを書いてみます。

::: tip Realm のインスタンス

本来は`realm`を`delete()`内で宣言したくなかったのですが、わかりやすくするために書きました。

:::

```sh
libc++abi.dylib: terminating with uncaught exception of type NSException
*** Terminating app due to uncaught exception 'RLMException', reason: 'Index 8 is out of bounds (must be less than 7).'
terminating with uncaught exception of type NSException
```

このコードを実装すると、リストからデータを削除したときにクラッシュしてしまいます。というのも、データベースから削除されたにも関わらず、SwiftUI が`ForEach`ですでに削除されているインデックスにアクセスしようとしてしまうためです。

### ObservableObject を利用した回避法

要するに直接 Realm のデータ`RealmSwift.Results`を削除しようとしたためにエラーが発生してしまうので`RealmSwift.Results`を`Array`に変換して、SwiftUI 側では`Array`を使って`List`を表示するようにします。

```swift
class UserModel: ObservableObject {
    private var token: NotificationToken?
    private var users: RealmSwift.Results<User> = RealmManager.Objects.users
    @Published var usersModel: [User] = []

    init() {
        // RealmSwift.Results<User>が更新されるとこのクロージャが実行される
        // そしてuserModelの配列がアップデートされる
        token = users.observe { [weak self] _ in
            self?.usersModel = Array(self!.users)
        }
    }
}
```

という感じで、データベースが更新されるとその通知を受け取ってから`Array`を更新します。あとは SwiftUI が`Array`を参照してリストを表示するようにすれば良いので、

```swift
struct ContentView: View {
    @ObservedObject var userModel = UserModel()

    var body: some View {
        Form {
            ForEach(userModel.usersModel) { user in
                Text("\(user.id)")
            }
            .onDelete(perform: delete)
        }
    }

    private func delete(offsets: IndexSet) {
        guard let realm = try? Realm() else { return }
        // 削除されたArrayから、削除されるRealmSwiftl.Results<User>を計算する
        if let index = offsets.first, let user = realm.objects(User.self).filter("id=%@", userModel.usersModel[index].id).first {
            try? realm.write {
                realm.delete(user)
            }
        }
    }
}
```

とすれば良いことになります。

### ObservableObject を利用しない回避法

また、`ObserverdObject`を使わない場合は以下のように書けます。

```swift
struct ContentView: View {
    @State var users: [User] = Array(RealmManager.Objects.users)

    var body: some View {
        Form {
            ForEach(users) { user in
                Text("\(user.id)")
            }
            .onDelete(perform: delete)
        }
    }

    private func delete(offsets: IndexSet) {
        guard let realm = try? Realm() else { return }
        if let index = offsets.first {
            try? realm.write {
                // ここの判定は曖昧なのでより厳密にしても良いかも
                // データベースから削除
                realm.delete(users[index])
            }
            // SwiftUIのリストから削除
            users.remove(atOffsets: offsets)
        }
    }
}
```

### Frozen Objects を利用した回避法

```swift
struct ContentView: View {
    @State private(set) var users: RealmSwift.Results<User> = RealmManager.Objects.users
    @State private(set) var freezedUsers: RealmSwift.Results<User> = RealmManager.Objects.users

    var body: some View {
        Form {
            ForEach(users) { user in
                Text("\(user.id)")
            }
            .onDelete(perform: delete)
        }
    }

    private func delete(offsets: IndexSet) {
        guard let realm = try? Realm() else { return }
        if let index = offsets.first {
            try? realm.write {
                // ここの判定は曖昧なのでより厳密にしても良いかも
                // データベースから削除
                realm.delete(freezedUsers[index])
            }
            // freezeでコピー
            users = freezedUsers.freeze()
        }
    }
}
```

同じものを複数用意するというのが少々ダサいです。

個人的にはループのところで、

```swift
var body: some View {
    Form {
        ForEach(users.freeze()) { user in
            Text("\(user.id)")
        }
        .onDelete(perform: delete)
    }
}
```

ができたら便利だと思うのですが、これをやると削除しても SwiftUI がリストをアップデートしてくれませんでした、残念。

> なんとアップデートでできるようになっていました。
> [RealmCocoa が SwiftUI に正式対応してるっぽい](https://tkgstrator.work/posts/2021/08/05/realmcocoa.html)


