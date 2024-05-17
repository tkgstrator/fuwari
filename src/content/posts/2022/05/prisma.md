---
title: Prismaの使い方を学ぶ
published: 2022-05-08
category: Programming
tags: [Typescript, NodeJS, PostgreSQL, Prisma]
---

## Prisma

Prisma とは公式ドキュメントによると、

> Next-generation Node.js and TypeScript ORM

とあるので、要するに次世代の NodeJS と Typescript の ORM であるらしい。ORM とは Object-Relational Mapping のことでオブジェクトのリレーションを行うものを指し、要するに TS で書いたオブジェクトとデータベースを関連付けるための仕組みのことのことなのだと思う、多分。

NodeJS でデータベースを扱うには GraphQL や Prisma や TypeORM などがあるが、GraphQL だけは REST ではない API らしいので、REST を勉強したばかりということもあって今回は Prisma を採用しました。

TypeORM はちょっと触ったのですが、定義がややこしかったので Prisma の方が個人的には触りやすい気がしています。

## PostgreSQL

Prisma はデータベースなら大体なんでも対応しているのですが、今回は PostgreSQL を選択しました。理由は単純で、PostgreSQL ならデータベースで配列をネイティブサポートしているからです。MySQL だとこの辺が上手くいかなかったりなんだったりなので。

ただ、PostgreSQL だとインサート失敗したときに Auto increment が勝手に上がってしまって歯抜けになってしまうので、しっかりとインサートできるかどうかのチェックは行わなければいけません。ロールバックしても AI の値はロールバックされないらしいので余計にめんどくさい。

## 環境構築

[このレポジトリ](https://github.com/tkgstrator/nestjs-prisma-swagger)に必要最低限の機能が突っ込んであるので、clone すれば以下の機能が使えます。

- Swagger で自動的に API ドキュメントが更新される
  - [localhost:3000/documents](http://localhost:3000/documents/)にアクセス
- Redoc で自動的に API ドキュメントが HTML 化される
  - `docs`ディレクトリに`index.html`として出力されるので`GitHub Pages`でそのまま公開可能
- Makefile に必要なコマンドを実装
  - めんどくさい`docker-compose`のタイプが不要

### Makefile

- `make up`
  - `docker-compose up`が実行される
- `make init`
  - `.env`と`docker-compose.yml`が生成される
- `make migrate`
  - `yarn prisma migrate dev --name init`が実行される
  - 接続しているデータベースがマイグレーションされる
- `make down`
  - `docker-compose down -v`が実行される

まずは設定ファイルにデータを書き込む必要があるので`make init`を実行します。

### .env

これには以下のようなデータが書き込まれています。

```
DATABASE_URL="postgres://POSTGRES_USER:POSTGRES_PASSWORD@localhost:5432/POSTGRES_DB"
POSTGRES_USER=
POSTGRES_PASSWORD=
POSTGRES_DB=
```

ここに DB 接続に必要な値を書き込めば大丈夫です。下の三つの値と上の値がおなじになるようにしないといけないので注意。

一例でいえばこんな感じ。ポート番号も合わせるようにしてください。

```
DATABASE_URL="postgres://root:prisma@localhost:5432/prisma"
POSTGRES_USER=root
POSTGRES_PASSWORD=prisma
POSTGRES_DB=prisma
```

ここまでできれば`yarn install`として必要パッケージをインストールしましょう。

データベースに接続したいのであれば`make up`として PostgreSQL を立ち上げておきます。

この状態で`yarn start:dev`とすればローカルサーバが立ち上がります。

## Prisma の使い方

ここからは実際に Prisma を使って DB を弄るコードの書き方を学びます。

公式ドキュメントを読んで内容を理解することが目的です。

### Model 定義

まずはモデルを定義します。

```prisma
model User {
  // Fields
}
```

[命名規則](https://www.prisma.io/docs/reference/api-reference/prisma-schema-reference#naming-conventions)によればモデル名はパスカルケースで単数形を使うべきとある。

モデルを定義するとマイグレーションしたときにモデルの内容に従ってデータベースが構築されます。

ちなみに、スネークケースを利用したい場合はモデル名自体はパスカルケースで定義して`@@map`を利用すべきだそうです。

```prisma
model Comment {
  // Fields

  @@map("comments")
}
```

### フィールド定義

フィールドには次の四つが含まれます。

- フィールド名
- フィールド型
- (オプション)型モディファイア
- (オプション)属性

#### スカラーフィールド

[利用可能なスカラーな型](https://www.prisma.io/docs/reference/api-reference/prisma-schema-reference#model-field-scalar-types)についてはここを参考に。

多少の差異がありますが、基本的には、

- `String`
- `Boolean`
- `Int`
- `BigInt`
- `Float`
- `Decimal`
- `DateTime`
- `Json`
- `Bytes`
- `Unsupported`

が利用できます。よって、例えば以下のようなモデルが定義できます。

```prisma
model Comment {
  id      Int    @id @default(autoincrement())
  title   String
  content String
}
```

#### リレーションフィールド

別のモデルとの関係性を表現したい場合に利用します。

以下の例では一つの Post モデルが複数の Comment モデルを持っていることがわかります。このとき、子(Comment)が親(Post)を識別できれば良いので、`postId`のフィールドを追加して Comment が親情報を保存できるようにします。

```prisma
model Post {
  id       Int       @id @default(autoincrement())
  // Other fields
  comments Comment[] // A post can have many comments
}

model Comment {
  id     Int
  // Other fields
  Post   Post? @relation(fields: [postId], references: [id]) // A comment can have one post
  postId Int?
}
```

#### 型属性

- `[]`
  - フィールドをリストとして扱います
  - オプショナルと組み合わせて`String[]?`とはできないので注意
- `?`
  - NULL を許可します
  - 逆にいえばこれをつけないと`NN`になるので注意

### 属性

その前にまずは Attributes を理解しておきましょう。よく使われるのは以下の四つです。

- `@default`
  - デフォルト値を設定できます
  - `autoincrement()`, `cuid()`, `uuid()`が利用できます
- `@id`
  - 単一プライマリキーを意味します
- `@@id`
  - プライマリキー組み合わせを意味します
- `@unique`
  - ユニークキーを設定できます
- `@@unique`
  - ユニークインデックスを設定できます
- `@@index`
  - インデックスを設定できます
- `@@relation`
  - データベース間のリレーションを設定できます
  - [Relation](https://www.prisma.io/docs/reference/api-reference/prisma-schema-reference#relation)で詳しく解説されている模様
- `@map`
  - 別の名前に置き換えると思う
- `@updateAt`
  - 設定すると自動でアップデートされたときの`Datetime`が上書きされます

### プライマリキー制約

プライマリキーは一つのモデルにおいて一つ存在し、重複や NULL が許されない値です。

プライマリーキーは単一または複数のフィールドの組み合わせを設定できます。リレーションが存在する場合、一意な値が必要になるのでプライマリーキーまたは後述するユニーク制約が必須になります。

#### 単一プライマリキー

```prisma
model User {
  // Int型で自動でインクリメントされる, プライマリキーなので重複不可
  id        Int     @id @default(autoincrement())
  firstName String
  lastName  String
  // ユニークインデックスなので重複不可
  email     String  @unique
  // 何もしなければfalseが設定される
  isAdmin   Boolean @default(false)

  // 名字と名前の組み合わせはユニーク制約, 同姓同名を許可しない
  @@unique([firstName, lastName])
}
```

#### 複数プライマリキー

プライマリキーは一つしか設定できませんが、組み合わせて使うこともできます。

```prisma
model User {
  firstName String
  lastName  String
  email     String  @unique
  isAdmin   Boolean @default(false)

  @@id([firstName, lastName])
}
```

このようにすれば`firstName`と`lastName`の組み合わせがプライマリキーになります。

#### ユニーク制約

以下の例ではユーザはユニーク制約によって一意に識別されます。

```prisma
model User {
  email   String   @unique
  name    String?
  // これはEnum, 詳細は後述
  role    Role     @default(USER)
  // 配列
  posts   Post[]
  // オプショナル,  これも後述
  profile Profile?
}
```

### Enum 定義

モデルと同じようにパスカルケース、単数形で定義すべきです。

[ドキュメント](https://www.prisma.io/docs/reference/api-reference/prisma-schema-reference#enum)で簡単に説明されていますが、どうも値付き Enum にはできないようです。

### 複合型

MongoDB では独自の型を定義することもできます。その他のデータベースでは利用できません。

```prisma
model Product {
  id     String  @id @default(auto()) @map("_id") @db.ObjectId
  name   String
  photos Photo[]
}

type Photo {
  height Int
  width  Int
  url    String
}
```

## リレーション

今回学びたいのがこれ。これを学ぶためだけにここまで書いてきたと言っても良い。

[ドキュメント](https://www.prisma.io/docs/concepts/components/prisma-schema/relations)はこれなので、これを読んで理解を深めたい。

リレーションは二つのモデルの関係性であり、例えば`User`と`Post`の一対多のリレーションが考えられる。何故なら一人のユーザは複数の投稿を持つことができるからです。

以下のコードは`User`と`Post`の一対多のリレーションの定義です。

```prisma
model User {
  id    Int    @id @default(autoincrement())
  posts Post[]
}

model Post {
  id       Int  @id @default(autoincrement())
  author   User @relation(fields: [authorId], references: [id])
  authorId Int // relation scalar field  (used in the `@relation` attribute above)
}
```

![](https://www.prisma.io/docs/static/e83a6a5933258930b5e6b7bc6f1bf839/5819f/one-to-many.png)

このとき、リレーションは Prisma モデルレベルの定義なので、`posts`と`author`の二つのフィールドは実際のデータベースには存在しません。また、同様に`authorId`も存在しません。

### 一対一リレーション

ユーザがただ一つのプロフィールを持つ場合、`User`と`Profile`は以下のように定義されます。

```prisma
model User {
  id      Int      @id @default(autoincrement())
  profile Profile?
}

model Profile {
  id     Int  @id @default(autoincrement())
  user   User @relation(fields: [userId], references: [id])
  userId Int // relation scalar field (used in the `@relation` attribute above)
}
```

ユーザはプロフィールを持たない可能性(未設定の場合など)があるので、`Profile?`としてオプショナルにしておきます。ただし、全てのプロファイルは必ず一つのユーザと繋がっていなければいけないので`userId`はオプショナルであってはいけません。

#### マルチフィールドリレーション

さっきは User 側にプライマリキーがあったのですが、プライマリキーが単一ではなく複合だった場合には以下のように書くみたいです。

```prisma
model User {
  firstName String
  lastName  String
  profile   Profile?

  @@id([firstName, lastName])
}

model Profile {
  id            Int    @id @default(autoincrement())
  user          User   @relation(fields: [userFirstName, userLastName], references: [firstName, lastName])
  userFirstName String // relation scalar field (used in the `@relation` attribute above)
  userLastName  String // relation scalar field (used in the `@relation` attribute above)
}
```

要は`@relation(fields: [])`の配列の中身がユニークであれば良いっぽい感じでしょうか。

### 一対多リレーション

```prisma
model User {
  id    Int    @id @default(autoincrement())
  posts Post[]
}

model Post {
  id       Int  @id @default(autoincrement())
  author   User @relation(fields: [authorId], references: [id])
  authorId Int
}
```

#### マルチフィールドリレーション

```prisma
model User {
  firstName String
  lastName  String
  post      Post[]

  @@id([firstName, lastName])
}

model Post {
  id              Int    @id @default(autoincrement())
  author          User   @relation(fields: [authorFirstName, authorLastName], references: [firstName, lastName])
  authorFirstName String // relation scalar field (used in the `@relation` attribute above)
  authorLastName  String // relation scalar field (used in the `@relation` attribute above)
}
```

一対一リレーションとほとんど同じなので割愛。

### 多対多リレーション

ここまでのリレーションと違い、多対多の場合には中間テーブルが必要になります。

例えば Post と Category のモデルがあるとすれば、一つの Post は複数のカテゴリを持つことができ、それぞれのカテゴリにはそのカテゴリとして投稿された Post が参照できてほしいわけです。

```prisma
model Post {
  id         Int                 @id @default(autoincrement())
  title      String
  categories CategoriesOnPosts[]
}

model Category {
  id    Int                 @id @default(autoincrement())
  name  String
  posts CategoriesOnPosts[]
}

model CategoriesOnPosts {
  post       Post     @relation(fields: [postId], references: [id])
  postId     Int // relation scalar field (used in the `@relation` attribute above)
  category   Category @relation(fields: [categoryId], references: [id])
  categoryId Int // relation scalar field (used in the `@relation` attribute above)
  assignedAt DateTime @default(now())
  assignedBy String

  @@id([postId, categoryId])
}
```

### 自己リレーション

ドキュメントを読んでいたらまたよくわからないのが出てきたという感じ。自己リレーションとはなんぞ。

```prisma
model User {
  id          Int     @id @default(autoincrement())
  name        String?
  successorId Int?
  successor   User?   @relation("BlogOwnerHistory", fields: [successorId], references: [id])
  predecessor User?   @relation("BlogOwnerHistory")
}
```

モデル定義は上のような感じで、ユーザは前任者と後継者がいる可能性がある、というわけです。で、前任者と後継者の情報も当然 User モデルなので User モデルから User モデルへのリレーションなので自己リレーションというわけですね。

要するに、他のデータベースを経由しないリレーションなわけです。

というわけで、ここまでで Prisma Scheme の書き方を学びました。次回はこの定義した DB にアクセスするための Prisma Client の書き方を学びます。

記事は以上。
