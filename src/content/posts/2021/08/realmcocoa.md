---
title: RealmCocoaがSwiftUIに正式対応してるっぽい
published: 2021-08-05
description: RealmSwiftがSwiftUIに対応した
category: Programming
tags: [Swift, RealmSwift]
---

# [RealmSwift](https://github.com/realm/realm-cocoa)

iOS アプリで利用できる軽量データベースフレームワーク。

これが最近アップデートされて SwiftUI にどうやら正式対応したらしい。

というのも、以前からでも SwiftUI で RealmSwift は利用できたのだがリストを ForEach で回して表示しているときに`remove`メソッドでリストを削除しようとすると、SwiftUI 側と RealmSwift 側でデータを削除するタイミングがずれてしまうので SwiftUI が「アクセスしようとしたデータがないんだが」というエラーがでてクラッシュしてしまっていた。

これは Realm5.0 で追加された`freeze()`を使えば常に`immutable`なオブジェクトを返し、クラッシュすることがないようにできたのだがいささか実装がめんどくさかった。

## ObservedResults

そんな中現れたのが`ObservedResults`で、これは RealmSwift で公式サポートされている機能である。

```swift
struct ContactsView: View {
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

で、それを使えば削除するメソッドがこんなに簡単にかけてしまう！！

::: warning onMove

ただ、`onMove`はこの書き方では動作しないので注意。

:::

しかもこれ、便利なことに`persons`に対して`filter`などを書けても正しく動作する。便利すぎる！！！


