---
title: FirestoreAuthでTwitterログインしよう
published: 2021-11-24
description: FirestoreAuth+SwiftUIでログインするためのコードの書き方について解説
category: Programming
tags: [Swift, Firestore]
---

# FirestoreAuth

Firestore のデータベースを読み書きするにはログインしていることが条件になってきます。テストモードだと問答無用で読み書きできるのですが、それでは困るので本番環境ではログインしているユーザだけにします。

となると困るのは、どうやってユーザ登録をさせるかということですね。

ぼくは正直、ちまちまメールアドレスを入れたりするような登録システムは非常にめんどくさいのでやりたくないです。管理するパスワードも増えますし。

なので、別のサービスを利用してその認証システムを使ってしまうのが早いです。こうすれば自分でログインシステムを作る必要もないですし、パスワード管理も不要です。登録自体も OAuth でログインするだけなのであっという間です。

個人情報が不要で、ユーザの識別だけができればよいシステムであればこれが最も楽でしょう。

では、早速そのような仕組みを利用したいと思います。

## SwiftUI + FirestoreAuth

以前の FirestoreAuth だと SwiftUI で利用するのが若干めんどくさかったのですが、アップデートのせいかなんなのかめちゃくちゃ楽になっていました。

::: warning 前提条件

当たり前ですが、Twitter App 用の Client Id と Client Secret は予め取得して Firebase コンソール上で設定しておいてください。

:::

```swift
class FireManager {
    /// プロバイダーを定義(Twitterでのログインの場合はこのままで良い)
    private let provider = OAuthProvicer(providerID: "twitter.com")

    @Published var user: FirebaseAuth.User?

    init() {
        /// Userの認証状態が変わるとここが自動的に呼ばれるのでそれを登録しておく
        Auth.auth().addStateDidChangeListener({ auth, user in
            self.user = user
        })
    }

    internal func twitterSignin() {
        provider.getCredentialWith(nil, completion: { credential, error in
            if let error = error {
                // エラー発生時の記述
            }

            if let credential = credential {
                Auth.auth().signIn(with: credential, completion: { result, error in
                    if let error = error {
                        // エラー発生時の記述
                    }
                    // ログイン,登録できたときの処理
                })
            }
        })
    }
}
```

こんなんでちゃんと動くんかいなという気もしますが、ちゃんと動きます。

::: tip UI について

適当なボタンから認証できるということは、ログインボタンは自分の好きな UI にカスタマイズできるということでもある、神だな？

:::

SwiftUI の場合だと、適当なボタンで`twitterSignin()`をコールすれば勝手に`NavigationLink`的なもので画面が遷移して、認証画面が表示されます。

注意点としては`Info.plist`にコールバック用の URLScheme を書いておかないとアプリがクラッシュします。

まあ、書き忘れていたらクラッシュした上でデバッグログにそのメッセージが表示されるので詰まることはないと思います。

### ログイン状態を保持

毎回ログインしてもよいのだが、ログイン情報(Credential)を Keychain に保存しておけばそれはそれで良い気もする。

セキュアな情報なのでデータベースや UserDefaults を利用するのではなく、必ず Keychain を利用しよう。

## まとめ

調べても超古いコードしか見つからなかったのですが、普通に Google のサンプルコードほとんどそのままでログインシステムが作れました。
