---
title: HerokuでTwitterのOAuthを実装してみた
published: 2021-03-18
category: Tech
tags: [Heroku]
---

## Heroku

ほとんど備忘録的な記事。

これから先、Twitter OAuth をしたくなったときに直ぐにできるのはありがたい。

[Heroku](https://jp.heroku.com/)

なんかよくわからんけどすごいサービス。

とりあえずアカウントを解説します。

[Elements Marketplace: twitter-oauth-test](https://elements.heroku.com/buttons/tyfkda/twitter-oauth-test)

やりたいことはこれなんですけど、これは Ruby なので PHP でも同じことができるかチャレンジします。

### Twitter Apps を設定する

まずは Twitter の Developer 申請を行って API Key と API Key Secret が取得できるようにしましょう。

![](https://pbs.twimg.com/media/EwwYOvkVoAI_nZi?format=png)

### Heroku に環境変数をセットする

Settings から環境変数をセットします。

![](https://pbs.twimg.com/media/EwwXNq9VkAQaCWK?format=png)

### composer のインストール

twitteroauth や dotenv をインストールするために必要なのでインストールします。

[ikastapi](https://github.com/tkgstrator/ikastapi)

めんどくさい場合はここから clone してきても良い。

### env ファイルの作成

ファイル自体に API Key を書くとまずいことになるので環境変数自体に API Key を書きます。

dotenv は.env ファイルから環境変数を PHP に読み込ませるための便利なツールなのでそれを利用します。

```
// .env
CONSUMER_KEY=""
CONSUMER_KEY_SECRET=""
```

こんな感じでキーをベタ書きしておきます。

## コールバック用の PHP ファイルの作成

[Twitter OAuth](https://gist.github.com/tkgstrator/827e4fca6c6ec4198c2d6a65877a86ac)

こんな感じで index.php と callback.php を設定したら GitHub にプッシュするだけです。

Twitter Developer の方で callbackURL として Heroku の URL を通しておくのも忘れないように。

## 完成したやつ

[ikastagram](https://ikastagram.herokuapp.com/)

するとサーバレスで簡単に OAuth 認証用の URL が作成できます。

callback.php が認証の方までやってくれるので user_id の値がとってこれます。Twitter の機能にアクセスせず、ユーザ認証をするだけであればこれで十分な気もします。

Heroku 自体はめちゃくちゃ面白くて可能性感じまくりなので土日にでもいろいろ触ってみたいですね。

記事は以上。
