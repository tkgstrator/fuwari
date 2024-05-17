---
title: "[二日目] Apple Reviewの審査に通るまで"
published: 2021-01-15
category: Programming
tags: [Swift]
---

## 背景

審査に引っかかった項目をポチポチと直し続けて今に至ります。

さて、今回またリジェクトをくらったのでその箇所の解説と直し方をメモしていきます。

## 引っかかった規約

今回引っかかったのは三項目ですが、以前とは違うところで引っかかりました。

### 1. 5 Safety: Developer Information

> The support URL specified in your app’s metadata, [https://twitter.com/tkgling](https://twitter.com/tkgling), does not properly navigate to the intended destination.

サポート URL に Twitter アカウント載せたら怒られました！！！！！

なのでサポート用のページ作ります！！！！

### 2. 1 Performance: App Completeness

> We’re looking forward to reviewing your app, but we were unable to sign in with the demo account credentials you provided.

「レビューするためにデモアカウントにログインしようとしたらできないんだが？」って言われた。

それもそのはずで、ニンテンドーが二段階認証を要求するようになったため。

ログイン時には必ず登録してあるメールアドレスにログイン用のコードが送られるようになっているのだ。これがなんとも言えないくそめんどくさい仕様で、レビューのときにどうすればええんや？ってなっている。

### 2. 3 Performance: Accurate Metadata

> We noticed that your app name or subtitle to be displayed on the App Store includes the following trademarked term or popular app name, which is not appropriate for use in these metadata items.

「App Store に表示されるアプリ名やサブタイトルに有名なアプリの名前が入ってるから、使うのはふさわしくないよ」という忠告を頂きました。

なんのこっちゃろって思ったら「Salmon Run/サーモンラン」っていう言葉がダメらしいです。

え、ダメなの？？？

### ログインできない問題について

これについてはこちらではどうしようもない問題なので、任天堂がログイン方式を変えたからでもアカウントは使えなくなったと説明するしかなかった。

> Nintendo have changed login method required e-mail verification in order to sign in. So, we can not provide demo account credentials of the username and password.

というふうに返事を送ったのだが、これで伝わるのかどうかは微妙。

というのも、以前頭のおかしいレビュワーにあたってひたすら同じ文言のやりとりをした覚えがあるため。もうあのような惨劇は繰り返してはいけないので、次きたらまた担当者変えてもらう。

ちゃんと正常に動作しているときの動画も載せたけど、なんとかなるだろうか？

### サーモンランという名称問題

サーモンランという名称自体は固有名詞ではなく、一般名詞だから使っても問題ないでしょ。他にサーモンランって名前のつくアプリあるの？

っていう形で若干抗議してみた。通ればラッキーくらいの気持ちでやろうと思う。

## 既存のバグ？

突っ込まれてはいないものの、不具合としてこちらがわで認識しているものをまとめる。

### SwiftyStoreKit

SwiftyStoreKit には`retrieveProductsInfo()`というアプリ内課金のプロダクト ID を指定するとその情報を返してくれる API が存在する。

で、この API はシミュレータ上では正しく動作するのだが、実機で動かそうとすると以下のようなエラーを出力する。

```
Invalid product identifier: work.tkgstrator.Salmonia2.Accounts
Invalid product identifier: work.tkgstrator.Salmonia2.Consumable.Donation
Invalid product identifier: work.tkgstrator.Salmonia2.MonthlyPass
```

最初はリリースビルドだけのバグかと思ったのだが、そうではないようだ。

リリースビルドだけのバグであるなら、デバッグビルドが Configuration.storekit を参照していることから単に SwiftyStoreKit の通信の実装に問題があるのかと考えることもできるのだが、同じデバッグビルドでも実機だと上手く動かないというのは腑に落ちない。

これが解消しない限り、リリースすることはできないだろう。

### Purchase の処理が異常に遅い問題

[App purchasing is extremely slow](https://github.com/bizz84/SwiftyStoreKit/issues/506)

調べてみたらなにやら issue が上がっており、解決法も載っていたので自分のコードに反映させてみた。

ただ、上に述べたように SwiftyStoreKit が実機に対して`Invalid product identeifier`を返すのでそもそも購入処理が行えない。

なので、直ったかどうかがわからないという状況になっている。

## まとめ

ライブラリが原因で上手く動かないというのはなんとも気持ちの悪い感じがする。

早急にリリースしたいのだけれど。

記事は以上。
