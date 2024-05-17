---
title: Prisma Clientの使い方を学ぶ
published: 2022-05-09
category: Programming
tags: [Typescript, NodeJS, PostgreSQL, Prisma]
---

## Prisma

一つ前の記事で Prisma のモデル定義を理解した前提で記事を書いていきます。つまり、自分が理解できていなかったらこの記事の内容を理解できないので、執筆が永遠に終わらないことになります。

### Scheme

今回は以下のように scheme.prisma ファイルを定義しました。`previewFeatures = ["interactiveTransactions"]`を追記していますが、これはデータベースのロールバックするときに使います。

[Prisma2 での transaction を ActiveRecord 風に書きたい問題](https://zenn.dev/qaynam/articles/0ef7c4d28a9066)で詳しく解説されているので、こちらを読むと幸せになれます。

```ts
// This is your Prisma schema file,
// learn more about it in the docs: https://pris.ly/d/prisma-schema

generator client {
  provider        = "prisma-client-js"
  previewFeatures = ["interactiveTransactions"]
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        Int      @id @default(autoincrement())
  username  String
  posts     Post[]
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt()
}

model Post {
  id        Int      @id @default(autoincrement())
  text      String
  author    User     @relation(fields: [authorId], references: [id])
  authorId  Int
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt()
}
```

で、このモデルで定義されたデータに対して Prisma Client を使って Typescript からデータを操作したいというのが今回の目標になります。

### Prisma Service

`prisma.service.ts`というファイルを`main.ts`と同じところに作成します。何も考えずコピペで OK です。

```ts
import { Injectable, OnModuleInit, OnModuleDestroy } from "@nestjs/common";
import { PrismaClient } from "@prisma/client";

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
```

### app.module.ts

次に app.module.ts に`PrismaService`を追記します。

これをしておかないと NestJS がエラーを吐きます。

```ts
import { Module } from "@nestjs/common";
import { AppController } from "./app.controller";
import { AppService } from "./app.service";
import { PrismaService } from "./prisma.service";

@Module({
  imports: [],
  controllers: [AppController],
  providers: [AppService, PrismaService],
})
export class AppModule {}
```

## サービスの作成

さて、ユーザを定義したのでユーザを操作できるエンドポイントを作成します。

```zsh
nest g module users
nest g service users
nest g controller users
```

のコマンドで必要なファイルを作成します。これだけで必要なものが勝手に作成されるのでありがたいです。

### users.controller.ts

以下のようなものを書きます。

コントローラに全ての処理を書いていると長くなりすぎるので、実際の処理の内容は`UsersService`に丸投げする感じです。

```ts
import { Controller, Get, Post } from "@nestjs/common";
import { UsersService } from "./users.service";

@Controller("users")
export class UsersController {
  constructor(private readonly service: UsersService) {}

  @Get()
  findAll() {
    this.service.findAll();
  }

  @Post()
  create() {
    this.service.create();
  }
}
```

簡単に解説しておくと`localhost:3000/users`にアクセスされたときの処理がここに定義されています。GET リクエストがくると`findAll()`が実行されるイメージです。

### users.service.ts

実際に処理を書くのがこのファイルです。

データベースにアクセスしてデータをあれこれするので`PrismaService`をインポートしておきましょう。

```ts
import { Injectable } from "@nestjs/common";
import { PrismaService } from "src/prisma.service";

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  findAll() {}

  create() {}
}
```

これで全ての準備は完了です。

あとはやりたいことを`findAll()`と`create()`に書いていくだけになります。

## NestJS

### リクエストで受け取るデータ

API 側がデータを受け取るには主にパスパラータ、クエリパラメータ、ボディパラメータの三つがある。他にはヘッダーで受け取るなどがあるが、ここでは考えないこととする。

これらは NestJS ではそれぞれ次の属性に対応している。いつも`@Param`をクエリパラメータだと勘違いしてしまうが、これはパスパラメータなので注意すること。

| @Param | @Query | @Body |
| :----: | :----: | :---: |
|  Path  |  Form  | JSON  |

- `@Param`
  - パスパラメータ
- `@Query`
  - フォームパラメータ
- `@Body`
  - JSON データ、GET では扱えない

#### リクエストで受け取る型

基本的にネットワーク経由で送られてくるパスパラメータとクエリパラメータは全て文字列型として送信されています。

```ts
@Get(':id')
findOne(@Param('id') id: number) {
  console.log(typeof id === 'number'); // false
  return 'This action returns a user';
}
```

例えば上のコードではデータは`number`型で受け取ると明記しているにも関わらず`string`型で受け取ってしまいます。

```ts
@Get(':id')
findOne(@Param('id', ParseIntPipe) id: number) {
  console.log(typeof id === 'number'); // true
  return 'This action returns a user';
}
```

その時はこのように ValidationPipe を通すことで型チェックと型変換を同時に行うことができます。

### バリデーション

返すデータはデータベースに突っ込まれている以上、常に整合性が取れているのだが、リクエストの正当性をチェックしなければいけない。

例えば、ユーザ ID が整数型だとすれば入力として整数値以外が入っていた場合は自動的にエラーを返してほしいわけである。

なお、執筆にあたり[Validation](https://docs.nestjs.com/techniques/validation#auto-validation)の項目を参考にした。いや、ホント公式ドキュメントが参考になります。

#### Validation Pipe

デフォルトで五つのバリデーション用の Pipe が用意されている。この中でも`ValidationPipe`は特に優秀で[Auto Validation](https://docs.nestjs.com/techniques/validation#auto-validation)を設定するだけで基本的には対応できる。

- ValidationPipe
- ParseIntPipe
- ParseBoolPipe
- ParseArrayPipe
- ParseUUIDPipe

それぞれ`@Param`や`@Query`などに適用して、入力された値の型が間違いなくそれであることを保証するものである。

これを使わないと入力値は常に文字列型で受け取ってしまうので注意が必要である。

ちなみに ValidationPipe にはいろいろオプションを設定できるので、詳しくは[公式ドキュメント](https://docs.nestjs.com/techniques/validation#using-the-built-in-validationpipe)を参照されたい。

#### 入力値のバリデーション

`users.controller.ts`を次のように変更する。`FindUserDto`というクラスを作成し、そのクラスに対してバリデーションをかける。

```ts
// users.controller.ts
@Get(':id')
find(@Param() request: FindUserDto): Promise<UserModel> {
  return this.service.find(request.id);
}
```

どこに定義しても良いが、今回は`users.dto.ts`に定義した。

```ts
import { ApiProperty } from "@nestjs/swagger";
import { Expose, Transform } from "class-transformer";
import { IsInt, IsNumberString, Min } from "class-validator";

export class FindUserDto {
  @Expose() // 変換した値をそのまま利用する
  @Transform((params) => parseInt(params.value, 10)) // 入力された値を10進数整数値に変換する
  @IsInt() // 整数値以外は許可しない
  @Min(1) // 最小値は1
  @ApiProperty() // これを忘れるとSwaggerに表示されない
  id: number;
}
```

パスパラメータとして受け取るのは常に文字列型なので、このように`@Transform`で整数型に変換してやらないと常にエラーを返してしまう。

ちなみに、ただ単純に整数値であることを保証したいだけであれば、

```ts
@Get(':id')
find(@Param('id', ParseIntPipe) id: number): Promise<UserModel> {
  return this.service.find(id);
}
```

のように`FindUserDto`を利用せずに`ParseIntPipe`で整数値に変換可能な入力のみを通すことができる。

なお、`ParseIntPipe`を利用して整数値以外のリクエストを投げた場合、以下のようなエラーメッセージが返ってくる。

```json
{
  "statusCode": 400,
  "message": "Validation failed (numeric string is expected)",
  "error": "Bad Request"
}
```

## バージョニング

API はバージョンが変わるとレスポンスが変わったり、受理するリクエストが変わったりする。

しかし、単に API を全部変えてしまうと旧 API を使っている人が困ってしまう場合がある。だが、エンドポイントを分けるとそれはそれでめんどくさい。

そこで、NestJS で利用されているバージョン管理機能を利用する。

### バージョン管理タイプ

[Versioning](https://docs.nestjs.com/techniques/versioning#versioning)を読んで得られた知見をまとめる。めんどくさいので全部ではなく、自分が利用できそうだと思ったところをメインに書いていく。

- URI
- ヘッダー
- メディアタイプ
- カスタム

の四種類でバージョン管理ができる。ヘッダーというのは指定されたヘッダーのキーにバージョンの値を入れておいて、それで分岐する感じである。これを利用しているのがスプラトゥーン 2 で採用されている X-Product Version に該当する。

個人的にはよく使われているのは URI バージョニングの気がしている。これは単にエンドポイントに対して`v1`や`v2`といったパスが追加される感じである。

今回はこれを利用することにした。

### 設定方法

やることは簡単で`main.ts`に追記する。

```ts
// main.ts
app.enableVersioning({
  type: VersioningType.URI,
});
```

これだけでバージョン管理システムは有効化されている。

```ts
// users.controller.ts
@Controller({ path: 'users', version: '1' })
```

どのバージョンを利用するかはコントローラに設定すれば良い。なお、エンドポイントごとにバージョンを分けることもできる。その場合は以下のように記述する。

```ts
import { Controller, Get, Version } from "@nestjs/common";

@Controller()
export class CatsController {
  @Version("1")
  @Get("cats")
  findAllV1() {
    return "This action returns all cats for version 1";
  }

  @Version("2")
  @Get("cats")
  findAllV2() {
    return "This action returns all cats for version 2";
  }
}
```

その他、複数のバージョニングや、デフォルト値などの設定もあるので[この辺](https://docs.nestjs.com/techniques/versioning#multiple-versions)をしっかりと読んでおくように。

## スキーマオブジェクト

まだ必要ではないが、将来的に必ず必要になりそうなので[ドキュメント](https://github.com/nestjs/swagger/blob/master/lib/interfaces/open-api-spec.interface.ts#L197)だけ載せておく。

## カスタムレスポンス

NestJS には後述するように 427 エラーに対応するステータスコードが定義されておらず、また 427 エラーのレスポンスも定義されていないので予め定義しておく。

```ts
import { applyDecorators } from "@nestjs/common";
import { ApiResponse } from "@nestjs/swagger";

export const ApiUpgradeRequiredResponse = () => {
  return applyDecorators(
    ApiResponse({
      status: 427,
    })
  );
};
```

こうしておけば`@ApiUpgradeRequiredResponse()`として呼び出すことができる。

## エラー処理

絶対に必要なのがエラー処理である。エラーの種類はそれこそ無数にあって全部列挙するのは難しいので、今回は基本的なものだけを列挙していく。

エラーに対応するレスポンスを Swagger に定義する場合は以下のものが利用できる。よくあるステータスコードについては[HTTP ステータスコード](https://developer.mozilla.org/ja/docs/Web/HTTP/Status)のドキュメントを参照した。

- @ApiOkResponse()
  - 200
- @ApiCreatedResponse()
  - 201
- @ApiAcceptedResponse()
  - 202
- @ApiNoContentResponse()
  - 204
- @ApiMovedPermanentlyResponse()
  - 301
- @ApiBadRequestResponse()
  - 400
- @ApiUnauthorizedResponse()
  - 401
- @ApiForbiddenResponse()
  - 403
- @ApiNotFoundResponse()
  - 404
- @ApiMethodNotAllowedResponse()
  - 405
- @ApiNotAcceptableResponse()
  - 406
- @ApiRequestTimeoutResponse()
  - 408
- @ApiConflictResponse()
  - 409
- @ApiTooManyRequestsResponse()
  - 429
- @ApiGoneResponse()
  - 410
- @ApiPayloadTooLargeResponse()
  - 413
- @ApiUnsupportedMediaTypeResponse()
  - 415
- @ApiUnprocessableEntityResponse()
  - 422
- @ApiInternalServerErrorResponse()
  - 500
- @ApiNotImplementedResponse()
  - 501
- @ApiBadGatewayResponse()
  - 502
- @ApiServiceUnavailableResponse()
  - 503
- @ApiGatewayTimeoutResponse()
  - 504
- @ApiDefaultResponse()

という感じで、基本的なステータスコードについては対応したレスポンスが予め定義されている。

### 該当するカラムがないときに 404 を返す

必要そうになりそうなエラー処理として、まずこれが考えられる。

```ts
// users.service.ts
find(id: number): Promise<UserModel> {
  return this.prisma.user.findUnique({
    where: { id: Number(id) },
  });
}
```

ユーザの検索は上のようなコードで実行しているのだが、検索結果が 0 だったときにはエラーを返したいわけである。

で、返すためのエラーはあらかじめいろいろ定義されているので[Built-in HTTP exceptions](https://docs.nestjs.com/exception-filters#built-in-http-exceptions)を読んでおこう。

ちなみに、今回のような場合は以下のコードで実装できる。

#### 検索結果が null ならエラーを返す

```ts
find(id: number): Promise<UserModel> {
  return this.prisma.user
    .findUnique({
      where: { id: id },
    })
    .then((user) => {
      if (user === null) {
        throw new NotFoundException();
      }
      return user;
    });
}
```

`findUnique()`で検索して、なければ`NotFoundException()`を返せば良い。

> tip rejectOnNotFound を利用する
> Prisma 側にユニーク検索でヒットしなかった場合にエラーを返す仕組みが存在した！なので`null`チェックは不要でした。

```ts
async find(id: number): Promise<UserModel> {
  return this.prisma.user
    .findUnique({
      where: { id: id },
      rejectOnNotFound: true,
    })
    .then((user) => {
      return user;
    })
    .catch((error) => {
      throw new NotFoundException();
    });
}
```

#### アップデートでエラーを返す

次は既存のユーザのデータをアップデートしようとした場合にエラーを返すことを想定する。アップデート用のデータを受ける場合には`Prisma.UserUpdateInput`という便利な型が使えるのでこれを利用する。

> tip 便利な型
> Prisma で定義したモデルのものが使える。`Book`を定義して、それをアップデートしたい場合には`Prisma.BookUpdateInput`を利用すれば良い。

```ts
async update(id: number, published: Prisma.UserUpdateInput): Promise<UserModel> {
  return this.prisma.user
    .update({
      where: { id: id },
      published: {
        username: data.username,
      },
    })
    .then((user) => {
      return user;
    })
    .catch((error) => {
      const message = (error as PrismaClientKnownRequestError).meta.cause;
      throw new HttpException(message, HttpStatus.NOT_FOUND);
    });
}
```

すると上のようなコードが書ける。ただこれは実際に書き込んでエラーが返ってきているが、本来は書き込む前にエラー判定が必要な気もする。

なのでこれをそのまま使うのは良くないような気がする。[公式のコード](https://github.com/prisma/prisma-examples/blob/a2aad33123a820982e9809c2f8b3f5d76575f2fd/typescript/rest-nestjs/src/app.controller.ts#L110)を読むと、

```ts
@Put('publish/:id')
async togglePublishPost(@Param('id') id: string): Promise<PostModel> {
  const postData = await this.prismaService.post.findUnique({
    where: { id: Number(id) },
    select: {
      published: true,
    },
  })

  return this.prismaService.post.update({
    where: { id: Number(id) || undefined },
    published: { published: !postData?.published },
  })
}
```

のようになっており、アップデートをする前に存在チェックを行っていることがわかる。

なのでこれに従ってコードを書き直すと、以下のようになりそうな気がする。

```ts
async update(id: number, published: Prisma.UserUpdateInput): Promise<UserModel> {
  return this.prisma.user
    .findUnique({
      where: { id: id },
    })
    .then((user) => {
      if (user === null) {
        throw new NotFoundException();
      }
      return this.prisma.user.update({
        where: { id: id },
        published: {
          username: data.username,
        },
      });
    });
}
```

こう書けばなければ 404 が返り、それ以外ではデータが正しく更新される。

## レスポンスを返す

### ページネーション

ページネーションはカラム数が多い場合にサーバへの負荷を考えて結果を分割して返す仕組みである。

返し方はいろいろあるのだが、`prev`や`next`を利用するものがデータベースを全件走査しないだけ負荷が低い。何故なら`offset`方式の場合は全部で何件データがあるかを予め返す必要があるからだ。

が、よほどデータが多くない限り`offset`方式でも問題がないと思われる。実際、NestJS のドキュメントではこの方式のコードが書かれている。では、実際にそのコードを紐解いてみよう。

```ts
import { applyDecorators, Type } from "@nestjs/common";
import { ApiOkResponse, ApiProperty, getSchemaPath } from "@nestjs/swagger";
import { Expose, Transform } from "class-transformer";
import { IsInt, Max, Min } from "class-validator";

export class PaginatedResponseDto<TData> {
  @Expose()
  @Transform((params) => {
    parseInt(params.value, 10);
  })
  @IsInt()
  @ApiProperty({ type: "integer" })
  total: number;

  @Expose()
  @Transform((params) => {
    parseInt(params.value, 10);
  })
  @IsInt()
  @Max(50)
  @Min(0)
  @ApiProperty({ type: "integer", minimum: 0, maximum: 50 })
  limit: number;

  @Expose()
  @Transform((params) => {
    parseInt(params.value, 10);
  })
  @IsInt()
  @ApiProperty({ type: "integer" })
  offset: number;

  results: TData[];
}

export const ApiPaginatedResponse = <TModel extends Type<any>>(
  model: TModel
) => {
  return applyDecorators(
    ApiOkResponse({
      schema: {
        allOf: [
          { $ref: getSchemaPath(PaginatedResponseDto) },
          {
            properties: {
              results: {
                type: "array",
                items: { $ref: getSchemaPath(model) },
              },
            },
          },
        ],
      },
    })
  );
};
```

少々長いが、上のようなコードをどこかに定義する。ただ、このままでは`PaginatedResponseDto`が Swagger に正しく反映されないので、

```ts

```

## Query

次にモデルに対するクエリを学ぶ。[ドキュメント](https://www.prisma.io/docs/reference/api-reference/prisma-client-reference#model-queries)は今回は Prisma のものを読むことにした。

### findUnique

ID またはユニーク属性があるフィールドで検索を行う

|       名前       | 必須 |               意味               |
| :--------------: | :--: | :------------------------------: |
|      where       | Yes  |        ユニークキーを指定        |
|      select      |  No  | 指定したフィールドを返すかどうか |
|     include      |  No  |    リレーションを返すかどうか    |
| rejectOnNotFound |  No  |   該当しない場合にエラーを返す   |

### findFirst

データベースで最初に合致したレコードを返す。

|       名前       | 必須 |                    意味                    |
| :--------------: | :--: | :----------------------------------------: |
|     distinct     |  No  | 特定のフィールドの重複する行をフィルタリグ |
|      where       |  No  |                  合致条件                  |
|      cursor      |  No  |          検索結果の中の特別な位置          |
|     orderBy      |  No  |            ソートするフィールド            |
|     include      |  No  |         リレーションを返すかどうか         |
|      select      |  No  |      指定したフィールドを返すかどうか      |
|       skip       |  No  |           最初の N 件を無視する            |
|       take       |  No  |     1 か −1 を指定、−1 なら最後の一件      |
| rejectOnNotFound |  No  |        該当しない場合にエラーを返す        |

### findMany

データベースで合致するレコードの配列を返す。何もしないと全件返ってくるので注意。

|   名前   | 必須 |                    意味                    |
| :------: | :--: | :----------------------------------------: |
|  where   |  No  |                  合致条件                  |
| orderBy  |  No  |            ソートするフィールド            |
|   skip   |  No  |           最初の N 件を無視する            |
|  cursor  |  No  |          検索結果の中の特別な位置          |
|   take   |  No  |     1 か −1 を指定、−1 なら最後の一件      |
|  select  |  No  |      指定したフィールドを返すかどうか      |
| include  |  No  |         リレーションを返すかどうか         |
| distinct |  No  | 特定のフィールドの重複する行をフィルタリグ |

### create

新しいレコードを作成する。Nested create をした場合は全てのレコードが同時に作成される。

|  名前   | 必須 |               意味               |
| :-----: | :--: | :------------------------------: |
|  data   | Yes  |          書き込むデータ          |
| select  |  No  | 指定したフィールドを返すかどうか |
| include |  No  |    リレーションを返すかどうか    |

### createMany

一つのトランザクションで複数のレコードを作成する。

|      名前      | 必須 |       意味       |
| :------------: | :--: | :--------------: |
|      data      | Yes  |  書き込むデータ  |
| skipDuplicates |  No  | 重複した際の挙動 |

### updateMany

一つのトランザクションで複数のレコードを更新する。

| 名前  | 必須 |      意味      |
| :---: | :--: | :------------: |
| data  | Yes  | 書き込むデータ |
| where |  No  |      条件      |

where で合致したレコードの中身を data で置き換える。

### deleteMany

いっぱい消す、以上。

### count

条件に合致するレコードの件数を返す。

|  名前   | 必須 |               意味                |
| :-----: | :--: | :-------------------------------: |
|  where  |  No  |             合致条件              |
| cursor  |  No  |     検索結果の中の特別な位置      |
|  skip   |  No  |       最初の N 件を無視する       |
|  take   |  No  | 1 か −1 を指定、−1 なら最後の一件 |
| orderBy |  No  |       ソートするフィールド        |
| select  |  No  | 指定したフィールドを返すかどうか  |

null が入っているレコードもカウントされてしまうので、あるフィールドに null が入っているものを除外したい場合には select を使うこと。

### aggregate

集約、概要、グループ、そしてよくわからん。まあ多分集約関数のようなもの。

|  名前   | 必須 |               意味                |
| :-----: | :--: | :-------------------------------: |
|  where  |  No  |             合致条件              |
| orderBy |  No  |       ソートするフィールド        |
| cursor  |  No  |     検索結果の中の特別な位置      |
|  skip   |  No  |       最初の N 件を無視する       |
|  take   |  No  | 1 か −1 を指定、−1 なら最後の一件 |
| \_count |  No  |                                   |
|  \_avg  |  No  |                                   |
|  \_sum  |  No  |                                   |
|  \_min  |  No  |                                   |
|  \_max  |  No  |                                   |

### groupBy

[ドキュメント](https://www.prisma.io/docs/concepts/components/prisma-client/aggregation-grouping-summarizing#group-by)

|  名前   | 必須 |               意味                |
| :-----: | :--: | :-------------------------------: |
|  where  |  No  |             合致条件              |
| orderBy |  No  |       ソートするフィールド        |
|   by    |  No  |     グループ化するフィールド      |
| having  |  No  | 集約値でグループ化することを許可  |
|  skip   |  No  |       最初の N 件を無視する       |
|  take   |  No  | 1 か −1 を指定、−1 なら最後の一件 |
| \_count |  No  |                                   |
|  \_avg  |  No  |                                   |
|  \_sum  |  No  |                                   |
|  \_min  |  No  |                                   |
|  \_max  |  No  |                                   |

## クエリオプション

### select

### include

### where

### orderBy

### distinct

## 階層クエリ

### create

階層クエリはあるレコードを追加するときに別のレコードも同時に追加するようなときに使われる。例えば User モデル作成時に、そのユーザのプロフィールを Profile モデルとして作成するような場合である。

```ts
const user = await prisma.user.create({
  published: {
    username: "tkgling",
    profile: {
      create: { commnet: "Hello World" },
    },
  },
});
```

これは例えば上のようなコードで実装される。逆にプロフィール実装時にユーザを追加することもできる。

```ts
const user = await prisma.profile.create({
  published: {
    comment: 'Hello World',
    user: {
|     create: { username: 'tkgling' },
    },
  },
})
```

また、複数のレコードを一度に作成することもできる。

```ts
const user = await prisma.user.create({
  published: {
    username: "tkgling",
    posts: {
      create: [
        {
          title: "This is my first post",
        },
        {
          title: "This is my second post",
        },
      ],
    },
  },
});
```

このとき、なんで createMany ではないのかが気になったりする。

```ts
const user = await prisma.user.update({
  where: { username: "tkgling" },
  published: {
    profile: {
      create: { comment: "Hello World" },
    },
  },
});
```

こういうコードも書けるらしいが、これがどうなるのか気になる。一見すると where で合致する全てのユーザの Profile が新規作成されそうだ。Profile は一人に一つのはずなので、既に Profile があればこれはバグを引き起こしそうなのだが......

### createMany

階層クエリの createMany は一つの親レコードに対して複数のレコードセットを追加する。

多対多のリレーションでは利用できない。例えば`prisma.post.create(...)`の内部で Category モデルを追加するために`createMany`を呼ぶことはできない。

ただし、多対一のリレーションでは利用できるので`prisma.user.create(...)`の内部で Post モデルを追加することはできる。

### set

リレーションの値を上書きする。例えば Post のレコードを別のレコードに上書きできる。詳しくは[ドキュメント](https://www.prisma.io/docs/concepts/components/prisma-client/relation-queries)を読めとのこと。

### connect

階層クエリの connect は既に存在するレコードのプライマリキーまたはユニーク制約を連携する。

```ts
const user = await prisma.profile.create({
  published: {
    comment: "Hello World",
    user: {
      connect: { username: "tkgling" },
    },
  },
});
```

例えばこのように書けばユーザ名`tkgling`の Profile が作成される。ユーザ自体は作成されない。

```ts
const user = await prisma.profile.create({
  published: {
    comment: "Hello World",
    user: {
      connect: { id: 1 },
    },
  },
});
```

このようにプライマリキーを指定することもできる。また、バージョン 2.11.0 以降は省略して、

```ts
const user = await prisma.profile.create({
  published: {
    comment: "Hello World",
    userId: 1,
  },
});
```

と書くこともできるようだ。

### connectOrCreate

あれば connect、なければ create してくれる大変賢いクエリ。

### disconnect

リレーションを削除する。なんで unset という名前にしなかったのかは謎。

### upsert

あれば update、なければ create する大変賢いクエリ。なんで insert じゃなくて create なのかは謎（そもそも何故 create なのか

### delete

消える。

### updateMany

普通の updateMany と違いがよくわからない。例えば、ユーザ ID が 2 で、いいね数が 0 の投稿を非公開にするコードは以下のように書ける。

```ts
const result = await prisma.user.update({
  where: {
    id: 2,
  },
  published: {
    posts: {
      updateMany: {
        where: {
          published: false,
        },
        published: {
          likes: 0,
        },
      },
    },
  },
});
```

### deleteMany

たくさん消す。

## Guard

現在進行中のプロダクトではあまり必要とされていないが、権限によるアクセス制限が考えられる。

で、それをよしなにやってくれる仕組みが NestJS にはある。あるのだが、どのくらい便利なのかわからないので試してみることにした。

今回も[ドキュメント](https://docs.nestjs.com/guards)を読んで理解をすすめることにした。Guard というやつはパーミッション、権限、アクセスコントロールのようなものを制御してルーティング可能かどうかを返す仕組みらしい。

当然ながらこの仕組みは認証として利用されることが多い。

### Guard の種類

#### Authorization guard

API を叩くときに、そのエンドポイント、リクエストを叩くことができる権限があるかどうかをチェックする。

```ts
import { Injectable } from "@nestjs/common";

@Injectable()
export class AuthGuard {
  async canActivate(context) {
    const request = context.switchToHttp().getRequest();
    return validateRequest(request);
  }
}
```

#### Role-based authentication

```ts
import { Injectable } from "@nestjs/common";

@Injectable()
export class RolesGuard {
  canActivate(context) {
    return true;
  }
}
```

### Guard を適用する

以下のようにすれば`users`以下のエンドポイントにアクセスする際に Guard が機能する。

```ts
@Controller("users")
@UseGuards(new RolesGuard())
export class UsersController {}
```

もしも全体に適用させたい場合は`main.ts`に以下のように書けば良い。

```ts
const app = await NestFactory.create(AppModule);
app.useGlobalGuards(new RolesGuard());
```
