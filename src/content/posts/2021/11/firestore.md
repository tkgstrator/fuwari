---
title: Firestore SDKをiOSで使おう
published: 2021-11-22
category: Programming
tags: [Swift, Firestore]
---

# Firestore

簡単に言うとオンラインで利用できるデータベース。

ローカルに保存するだけなら Realm という選択肢があるが、オンラインでごにょごにょしようとしたら Firestore が一番なのではないかと思う。Realm もオンラインデータベースがあるけどドキュメントを読んでないのでよくわからない。

せっかくなので新しいことに手を出そうと Firestore を選択した。

## [Firestore SDK](https://github.com/invertase/firestore-ios-sdk-frameworks)

Swift Package Manager でインストールする。いろいろプロダクトはあるのだが`FirebaseFirestoreSwift`だけ選んでおけば良い。`FirestoreAnalytics`も便利なので自分はこれもインストールした。必要かどうかはわからない。

最後にウェブ上で Firebase の登録を済ませて`GoogleService-Info.plist`をプロジェクトに突っ込んで準備は完了。

## FSCodable

Firestore を圧倒的に使いやすくするための`FSCodable`という`Codable`+`Identifiable`な独自プロトコルを作成する。

```swift
import Foundation

protocol FSCodable: Codable, Identifiable {
    var id: String? { get }
}

extension FSCodable {
    var id: String? { nil }
}
```

そして`Extension`で`id`のデフォルト値が`nil`になるようにする。ここの`id`は`Identifiable`に由来するユニークな値なので、被らないような値が望ましい。

### Struct

```swift
import Foundation

struct User: FSCodable {
    let name: String
    let age: Int
}

extension User {
    var id: String? { name }
}
```

次に Firestore に保存したい構造体を考える。構造体 →JSON→Firestore 保存はこのあと解説する Manager クラスが全て行うので、ここではプライマリキーと保存したいプロパティだけを考える。

### Manager

最後に Manager クラスを定義しておしまいである。

Generics を利用しているので`FSCodable`に準拠している構造体ならなんでも書き込めるし、何でも読み込める。

::: warning 読み込みについて

読み込みは非同期なので`return`できないことに注意。受け取るには`Combine`を使って`sink`する必要がある。

:::

構造体にプライマリキーが指定されていればそれで書き込み、指定されていなければ Firebase が自動で設定するユニークな ID が割り当てられる。

```swift
import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

class FirestoreManager {
    private let firestore: Firestore = Firestore.firestore()
    private let encoder: Firestore.Encoder = Firestore.Encoder()
    private let decoder: Firestore.Decoder = Firestore.Decoder()

    init() {}

    /// データ書き込み
    func create<T: FSCodable>(_ object: T, merge: Bool = false) throws {
        let data = try encoder.encode(object)
        if let primaryKey = object.id {
            firestore.collection(String(describing: T.self)).document(primaryKey).setData(data, merge: merge)
        } else {
            firestore.collection(String(describing: T.self)).document().setData(data, merge: merge)
        }
    }

    /// プライマリキーを指定してデータ取得
    func object<T: FSCodable>(type: T.Type, primaryKey: String) -> AnyPublisher<T, FIError> {
        Future { [self] promise in
            firestore.collection(String(describing: T.self)).document(primaryKey).getDocument(completion: { [self] (document, _) in
                guard let document = document, let data = document.data() else {
                    // 適当にEnumで設定したエラー
                    promise(.failure(.notfound))
                    return
                }
                do {
                    promise(.success(try decoder.decode(T.self, from: data)))
                } catch {
                    // 適当にEnumで設定したエラー
                    promise(.failure(.undecodable))
                }
            })
        }
        .eraseToAnyPublisher()
    }

    /// 指定された構造体のデータを全て取得
    func objects<T: FSCodable>(type: T.Type) -> AnyPublisher<[T], FIError> {
        Future { [self] promise in
            firestore.collection(String(describing: T.self)).getDocuments(completion: { [self] (snapshot, _) in
                if let snapshot = snapshot, !snapshot.documents.isEmpty {
                    promise(.success(snapshot.documents.compactMap({ try? decoder.decode(T.self, from: $0.data()) })))
                } else {
                    // 適当にEnumで設定したエラー
                    promise(.failure(.notfound))
                }
            })
        }
        .eraseToAnyPublisher()
    }
}
```

エラーを返す場合があるので、エラーは以下のように定義しました。

```swift
import Foundation

enum FIError: Error {
    case notfound
    case undecodable
}
```

## 今後の展望

今回は全部取得するか、一見取得するかにしか対応したコードになっていないが、改良すれば`where`に対応したりできると思います。
