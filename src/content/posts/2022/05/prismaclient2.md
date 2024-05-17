---
title: Prisma Clientの使い方を学ぶ2
published: 2022-05-11
category: Programming
tags: [Typescript, NodeJS, PostgreSQL, Prisma]
---

## エンドポイントの仕様

まずは想定されているエンドポイントの定義を考える。

今回は以下で定義されるユーザのレコードを持っている。

```prisma
enum Gender {
    MALE,
    FEMALE
}

model User {
    id      Int @id(autoincrement())
    name    String?
    gender  Gender?
}
```

つまり、id は必ずあるが名前と性別は設定されていないかもしれないというようなデータベース構造である。

そして、次のエンドポイントがあることを考える。

- ユーザ全体を返す
  - 結果が 0 でもその値を空配列で返す
- ユーザ ID を指定して返す
  - 存在しない ID が指定された場合は 404 を返す

また、ユーザ全体の検索の場合は name と gender でフィルタリングがかけられ、データ数が多いことを見越して Pagination が行われるものとする。

これは Prisma の`findMany()`を利用すればさほど難しくなく実装することができる。

## Service

では`users.service.ts`がどのようなコードになるかを考えよう。

```ts
// users.service.ts
import { User as UserModel } from ".prisma/client";
import { Injectable, NotFoundException } from "@nestjs/common";
import { PrismaService } from "src/prisma.service";

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {} // 全件検索

  async findMany(skip: number, take: number): Promise<UserModel[]> {
    return await this.prisma.user.findMany({
      skip: skip,
      take: take,
    });
  }

  // 個別検索
  async find(id: number): Promise<UserModel> {
    return await this.prisma.user
      .findUnique({
        where: { id: id },
        rejectOnNotFound: true,
      })
      .catch((error) => {
        throw new NotFoundException();
      });
  }
}
```

全件検索については`findMany()`に対して`skip`と`take`を利用すれば Pagination ができるため、特に何も考えずにこのように実装すれば想定しているものができる。

個別検索については`findUnique()`で`rejectOnNotFound`のオプションを付けることで、一件もヒットしなかった場合にエラーが返る。そのエラーをそのまま返すことはできないようなので、`catch`してから`NotFoundException`を返すようにすれば、404 エラーが正しく返る。

## Controller + Query/Param

```ts
// users.controller.ts
import { User as UserModel } from ".prisma/client";
import { Controller, Get, Param, ParseIntPipe, Query } from "@nestjs/common";
import {
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiResponse,
} from "@nestjs/swagger";
import { UsersService } from "./users.service";

@Controller("users")
export class UsersController {
  constructor(private readonly service: UsersService) {}

  @Get("")
  @ApiOkResponse()
  findMany(
    @Query("offset") skip: number,
    @Query("limit") take: number
  ): Promise<UserModel[]> {
    return this.service.findMany(skip, take);
  }

  @Get(":user_id")
  @ApiOkResponse()
  @ApiNotFoundResponse()
  find(@Param("id") id: number): Promise<UserModel> {
    return this.service.find(id);
  }
}
```

で、例えば上のようなコードを書けば良いのではないかと考える人が多いと思う。が、実際にこれを動かすと Internal Server Error が発生する。

```ts
Argument skip: Got invalid value '10' on prisma.findManyUser. Provided String, expected Int.
Argument take: Got invalid value '10' on prisma.findManyUser. Provided String, expected Int.
```

何故なら前の記事でも紹介したように`@Param()`や`@Query()`で受け取るデータは全て`string`型として扱われてしまうからである。よって、以下で示す箇所で`number`型を想定しているものの実際には`string`型で受け取ってしまうのである。

```ts
@Get("")
@ApiOkResponse()
findMany(
  @Query("offset") skip: number, // string型が代入される
  @Query("limit") take: number // string型が代入される
): Promise<UserModel[]> {
  return this.service.findMany(skip, take);
}
```

これはインタプリタ型言語の宿命とも言えなくもないのだが、この辺りの型安全性がちゃんと守られていないとうーんとなる。まあうーんとなっても仕方がないので対応方法を考えよう。これも前回の記事で書いたが、`ValidationPipe`という仕組みを使うことで簡単に対応できる。

### ValidationPipe

```ts
@Get("")
@ApiOkResponse()
findMany(
  @Query("offset", ParseIntPipe) skip: number, // number型が保証される
  @Query("limit", ParseIntPipe) take: number // number型が保証される
): Promise<UserModel[]> {
  return this.service.findMany(skip, take);
}
```

Postman などを利用して(Swagger では型を無視したリクエストが送れないので)整数型以外をデータとして与えるとちゃんと 400 エラーが返ってくることが確認できる。

```json
{
  "statusCode": 400,
  "message": "Validation failed (numeric string is expected)",
  "error": "Bad Request"
}
```

ただ、これでは正の整数であることは保証されない。skip に負の値を入力するとやはり Internal Server Error が発生してしまう。

そこで、正の整数値のみを扱う`ParseUnsignedIntPipe`を自作してみることにする。

### ParseUnsignedIntPipe

ParseIntPipe がもともと定義されているので、それの継承クラスとして定義してやれば良い。

```ts
import { ArgumentMetadata, Injectable, ParseIntPipe } from "@nestjs/common";

@Injectable()
export class ParseUnsignedIntPipe extends ParseIntPipe {
  /**
   * Method that accesses and performs optional transformation on argument for
   * in-flight requests.
   *
   * @param value currently processed route argument
   * @param metadata contains metadata about the currently processed route argument
   */
  async transform(value: string, metapublished: ArgumentMetadata): Promise<number> {
    const intValue = await super.transform(value, metadata);
    if (intValue < 0) {
      throw this.exceptionFactory(
        "Validation failed (unsigned value is expected)"
      );
    }
    return intValue;
  }
}
```

といってもほとんど同じで、親クラスのメソッドを呼び出して返ってきた値が 0 未満ならエラーを返すようにしただけである。これを`ParseIntPipe`の代わりに使えば、負の数をパラメータに入れた場合に、

```json
{
  "statusCode": 400,
  "message": "Validation failed (unsigned value is expected)",
  "error": "Bad Request"
}
```

というエラーが返ってくるようになる。

### Optional

さて、ここまでは値がなにか入っていればその整合性をチェックするようなものを書いたが、一括取得の場合、何もパラメータが設定されていなかったら自動で`skip=0, take=50`のような値が入っていて欲しい場合がある。

さっき書いた`ParseUnsignedIntPipe`ではパラメータに何も入力しなかった場合、

```json
{
  "statusCode": 400,
  "message": "Validation failed (numeric string is expected)",
  "error": "Bad Request"
}
```

というエラーが返ってくる。本来はここは入力値が空であることを通知してほしいのであるが、
