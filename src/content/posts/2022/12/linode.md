---
title: Heroku vs Linode
published: 2022-12-19
description: HerokuとLinodeのどっちが良いのかを考えてみる会です
category: Tech
tags: [Linode, Heroku]
---

## Heroku vs Linode

Heroku が有料化されたので Linode に移行することになりました。

とはいえ、Linode 自体は別に無料ではないので「Heroku で有料プラン使っても変わらないんじゃないのか」と思うところではあります。というわけで、まずは両者を比較してみます。

### サーバー

|            |     Heroku Eco      | Heroku Basic | Linode Nanode |
| :--------: | :-----------------: | :----------: | :-----------: |
|    料金    |         $5          |      $7      |      $5       |
|   メモリ   |        512MB        |    512MB     |    1024MB     |
|  スリープ  | 30 分アクセスなし時 |     なし     |     なし      |
| ストレージ |          -          |      -       |     25GB      |
|    転送    |        2TB?         |     2TB?     |      1TB      |

サーバーだけ見るとこんな感じです。Heroku Eco は 30 分アクセスしないとスリープ状態になってしまうのでナシだとして、Basic と Nanode を比較すると Nanode の方がメモリが倍あって月額も安いことがわかります。

しかも Heroku は日本リージョンがないため、通信を行うときにいちいち米国を経由しなければ成らないのに対して Linode は日本リージョンがあります。

更に Linode は Ubuntu のサーバー自体を借りられるので AWS と同じように使えるのに対して Heroku は自由に使うようにはできていない（多分）ので、自由度でも見劣りします。

いいところはソースコードさえ用意すればプッシュするだけでアプリが起動することくらいです。でもこれ、めっちゃ便利なんですよね。

### データベース

サーバーとデータベースは同じところにあったほうが通信のラグが減るので、可能であれば同じサービスを選びたいです。

サーバーを Linode にするなら DB も Linode、Heroku にするなら DB も Heroku といった感じです。

データベース部は PostgreSQL を前提に書いているのですが、幸いにも Heroku は PostgreSQL をサポートしています。

|              | Heroku Mini | Heroku Basic |  Linode  |
| :----------: | :---------: | :----------: | :------: |
|     料金     |     $5      |      $9      |   $15    |
|  リージョン  |    米国     |     米国     |   日本   |
|  バージョン  |      -      |      -       |   14.4   |
|   保存上限   |   1 万行    |  1000 万行   |   なし   |
|     CPU      |      -      |      -       |    1     |
|     RAM      |     0GB     |     0GB      |   1GB    |
|  ストレージ  |     1GB     |     10GB     |   25GB   |
| バックアップ |      ?      |      ?       | 一日一回 |

調べてみたところこんな感じでした。Mini だと保存上限が 10000 行しかないのでこれだと流石に足りないと思います。半年も稼働してない Salmon Stats で 20 万行を超えたので、現在の 3 の稼働率を見る限りあっという間にこの上限は突破してしまいそうです。

となると、Basic となるわけですが、リージョンが米国しかないことを除けばそんなに悪くもない気がしてきました。

Linode は自動でバックアップをとってくれたりと便利なのですが、この差額ならまあ Heroku でもいいかなってなりますね。

バージョンについての記載は見つからなかったのですが、14.4 が使えないということはないでしょう。

保存上限が 1000 万行とのことですが、まあ多分大丈夫なのではないかと思います、多分。

## 最低限プランで足りるのか

ここまでは必要最低限のプランでの運用を考えていましたが、これで足りるのかという問題があります。

2 のときは Linode の最低限のプランでも十分動いていたので問題ない気はするのですが、3 の人気を考えるとユーザーがめちゃくちゃ増えるとそれなりに重くなりそうな気もします。

とりあえずは最低限のプランで運用してみて、負荷が大きそうならより大きなプランで運用する、でいいかなと思います。

### 利用に月額費用をかけるか

今のところは考えていません。

もし、Salmon Stats へのアップロードを有料プランにしてしまうと十分なデータが集まらない可能性があります。

ただ、ウェブ上で Salmon Stats を利用するにあたって有料プランであれば何らかの追加コンテンツがあっても良いかなとは思っています。

## NodeJS

Heroku は環境変数をブラウザから設定できるので特に環境変数を`.env`から読み込ませる必要はありません。

ただ、いくつか詰まるところがあるのでそれについて解説します。

### デプロイすると 503 エラーがでる

ローカルでは動いていてもそのままデプロイするとアプリケーションエラーが発生します。

理由はよくわかっていないですが、以下の方法で解決します。

なお[NestJS アプリを Heroku にデプロイしたときに発生する 503 エラーを解消する](https://zenn.dev/k0kishima/articles/78f7cd55afca93)の記事が大変参考になりました。

#### ポートの参照を変更

```diff
import { AppModule } from "./app.module";

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
- (await app.listen(3000));
+ (await app.listen(process.env.PORT || 3000));
}
bootstrap();
```

どうも Heroku は環境変数の PORT で指定されたポートを優先的に使うようになっているらしいので、指定されていればそちらを使うように設定します。

#### Pocfile の作成

Pocfile という名前のファイルをプロジェクトルートに作成します。

自分は`yarn`を使っているので以下のコマンドになりました。

```
web: yarn start:prod
```

あとは普通に`git push heroku master`を使えばビルド後にプッシュされて正しくページを表示することができます。

## PostgreSQL

アドオンで PostgreSQL を追加していると環境変数`DATABASE_URL`が設定されます。

NodeJS でデータベースを扱う方法はいろいろあるのですが、自分は Prisma を使っていたのですがこれで少し問題が発生しました。

### マイグレーションに失敗する

マイグレーションをするために`yarn prisma migrate dev --name init`を実行すると以下のようなエラーが表示されます。

```
Error: P3014

Prisma Migrate could not create the shadow database. Please make sure the database user has permission to create databases. Read more about the shadow database (and workarounds) at https://pris.ly/d/migrate-shadow

Original error:
db error: ERROR: permission denied to create database
   0: migration_core::state::DevDiagnostic
             at migration-engine/core/src/state.rs:250
```

ドキュメントによると`prisma migrate dev`または`prisma migrate reset`を実行した際は shadow database というものが自動的に作成、削除されるらしいのですが Heroku のデータベースは自分専用のものではないため shadow database を作成する権限がなく、そのために失敗してしまうようです。

shadow database を利用するためには PostgreSQL の場合はユーザーがスーパーユーザーであるか、または`CREATEDB`の権限を持つ必要があるとのこと。これがないのでダメというわけですね。

> Some cloud providers do not allow you to drop and create databases with SQL. Some require to create or drop the database via an online interface, and some really limit you to 1 database. If you develop in such a cloud-hosted environment, you must:

要約するとクラウドのプロバイダーは利用者がデータベースを作成したり削除したりすることを許可していないため、ユーザーが利用するデータベースを確実に一つに制限したりオンラインのインターフェースを経由する必要がある、とのこと。

じゃあ全くできないのかというとそういうわけでは内容で、`shadowDatabaseUrl`というものを設定すれば良いようです。そういう事態にもしっかりと対応しているのが素晴らしいですね。
