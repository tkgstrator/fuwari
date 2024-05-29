---
title: Effect-TSでより型安全なコードを書く 
published: 2024-05-18
description: Effect-TSというライブラリを見つけたのでNestJSに実装してみました 
category: Programming
tags: [TypeScript, NestJS, NodeJS]
---

## [Effect-TS](https://effect.website/docs/introduction)

TypeScriptでRustのように安全な型を提供することができるライブラリとのこと。

もともとTypeScriptには型があるので安全といえば安全なのですが、JSON形式などはどうしても`any`が入りがちなのでそのあたりをカバーすることができるそうです。

名前が名前なのでそもそも検索がしにくいのと、あまりに情報が少なすぎるので使い方について学ぶことにしました。

今まではJSONレスポンスは`class-validator`と`class-transformer`を利用してパースしていたのですが、`Effect-TS`を利用して書き換えることができれば良いのではないかと思いました。

### `@effect/schema`

おそらく最も使うことになるであろう機能がこの`schema`で構造体を定義することができます。

[バージョン0.67から実装された機能](https://effect.website/blog/schema-release-0.67)なのでドキュメントを読みながらちまちま書いてみようと思います。


今回は非公式APIからサーモンランのスケジュール情報を取得して、バリデーションとパースを行う仕組みをEffect-TSで実装することを考えます。

```json
{
  "bigBoss": "SakelienGiant",
  "phaseId": "664a94e1db05b9e98a069059",
  "startTime": "2024-05-26T16:00:00Z",
  "endTime": "2024-05-28T08:00:00Z",
  "stage": 4,
  "weapons": [
    200,
    6000,
    1020,
    2050
  ],
  "rareWeapons": []
}
```

レスポンスとして返ってくるフォーマットは大体上のような感じです。

```ts
import { Schema as S } from '@effect/schema'

const CreateScheduleSchema = S.Struct({
  bigBoss: S.String,
  phaseId: S.String,
  startTime: S.String,
  endTime: S.String,
  stage: S.Number,
  weapons: S.Array(S.Number),
  rareWeapons: S.Array(S.Number)
})

type CreateScheduleSchema = typeof CreateScheduleSchema.Type
```

これを単純にそれぞれにプロパティの型だけに着目すると上のようにバリデーションが書けます。

日付に関してはString型として扱うよりもDate型として扱ったほうが都合が良いですが最初に受け付ける段階では元々の型を定義したほうが良いかもしれません。

この状態でテストコードを書いてみます。

```ts
import { describe, test } from 'bun:test'

describe('Strucutre', () => {
  test('Schema', () => {
    CreateScheduleSchema.make({
      bigBoss: 'SakelienGiant',
      phaseId: '664a94e1db05b9e98a069059',
      startTime: '2024-05-26T16:00:00Z',
      endTime: '2024-05-28T08:00:00Z',
      stage: 4,
      weapons: [200, 6000, 1020, 2050],
      rareWeapons: []
    })
  })
})
```

Bunを使ってテストしたい場合には`import { describe, test } from 'bun:test'`と明示的に書かなければいけません。

`jest`であればここは不要なので少し特殊ですね。

Jestで実行した場合は以下のようになります。

> package.jsonに`jest --verbose`を追加してあげましょう

```zsh
bun ➜ ~/app (features/kv) $ bun run test
$ jest --verbose
(node:5172) ExperimentalWarning: The Ed25519 Web Crypto API algorithm is an experimental feature and might change at any time
(Use `node --trace-warnings ...` to show where the warning was created)
 PASS  src/schedules/schedule.spec.ts
  Strucutre
    ✓ Schema (2 ms)

Test Suites: 1 passed, 1 total
Tests:       1 passed, 1 total
Snapshots:   0 total
Time:        0.411 s
Ran all test suites.
```

問題なくテストが通っていることがわかります。実行時間は411msでした。

```zsh
bun ➜ ~/app (features/kv) $ bun test
bun test v1.1.10 (5102a944)

src/schedules/schedule.spec.ts:
✓ Strucutre > Schema [4.65ms]

 1 pass
 0 fail
Ran 1 tests across 1 files. [112.00ms]
```

同様のコードを`bun test`で実行すると明らかにさっきより速く終わりました。

実行時間は112msで、Jestで実行した場合よりも四倍も速い結果となりました。

これだけみるとJestを使う価値はなさそうなのですが、Jestの方しかない機能もあるらしいのでまだ一本に絞るのはできないそうです、なるほど。

## Structの書き方

先ほど以下のようなコードを書きましたが、これはよりバリデーションを強くできそうです。

```ts
import { Schema as S } from '@effect/schema'

const CreateScheduleSchema = S.Struct({
  bigBoss: S.String,
  phaseId: S.String,
  startTime: S.String,
  endTime: S.String,
  stage: S.Number,
  weapons: S.Array(S.Number),
  rareWeapons: S.Array(S.Number)
})

type CreateScheduleSchema = typeof CreateScheduleSchema.Type
```

例えば`weapons`や`rareWeapons`で与えられる数値はブキIDで定義される値のどれかなので、Enumを使ってより強く制約をかけることができそうです。

```ts
export namespace WeaponInfoMain {
  export enum Id {
    Dummy = -999,
    RandomGold = -2,
    RandomGreen = -1,
    ShooterShort = 0,
  }
}

export namespace CoopStage {
  export enum Id {
    Dummy = -999,
    Tutorial = 0,
    Shakeup = 1
  }
}
```

なのでこのようにステージIDとブキIDをEnumで定義して、これ以外の値がこればエラーを返すようにします。

```ts
export const CreateScheduleSchema = S.Struct({
  bigBoss: S.String,
  phaseId: S.String,
  startTime: S.String,
  endTime: S.String,
  stage: S.Enums(CoopStage.Id),
  weapons: S.Array(S.Enums(WeaponInfoMain.Id)),
  rareWeapons: S.Array(S.Enums(WeaponInfoMain.Id))
})
```

するとこのように書き換えることができます。

### デコード

色々あるのですが、多分このDecoderの機能を使うのが良いかと思いました

- `decodeUnknownSync`
  - 同期的にデコードし、エラーかその値を返す
- `decodeUnknownOption`
  - デコードし、Option型を返す
- `decodeUnknownEither`
  - デコードし、Either型を返す 
- `decodeUnknownPromise`
  - デコードし、非同期でPromise型を返す 
- `decodeUnknown`
  - デコードし、Effect型を返す

何のことだかさっぱりわからないので公式ドキュメントを読みながら書いてみることにします

```ts
describe('Strucutre', () => {
  test('Schema', () => {
    const data = {
      bigBoss: 'SakelienGiant',
      phaseId: '664a94e1db05b9e98a069059',
      startTime: '2024-05-26T16:00:00Z',
      endTime: '2024-05-28T08:00:00Z',
      stage: 4,
      weapons: [200, 6000, 1020, 2050],
      rareWeapons: []
    }
    const decoderSync = Schema.decodeUnknownSync(CreateScheduleSchema)
    const decoderOption = Schema.decodeUnknownOption(CreateScheduleSchema)
    const decoderEither = Schema.decodeUnknownEither(CreateScheduleSchema)
    const decoderPromise = Schema.decodeUnknownPromise(CreateScheduleSchema)
    const decoderUnknown = Schema.decodeUnknown(CreateScheduleSchema)
  })
})
```

こんな感じでそれぞれデコーダを作成して、どのような挙動を見せるのかチェックしましょう。

#### decodeUnknownSync

これはそのまま同期的に結果が返ります。

```ts
console.log(decoderSync(data))
// {
//   bigBoss: "SakelienGiant",
//   phaseId: "664a94e1db05b9e98a069059",
//   stage: 104,
//   weapons: [ 200, 6000, 1020, 2050 ],
//   rareWeapons: [],
// }
```

もしもデコードできない値をいれると構造体の定義によってはものすごく長いエラーが返ってきます。

```zsh
bun test v1.1.10 (5102a944)

src/schedules/schedule.spec.ts:
430 |   const parser = goMemo(ast, isDecoding);
431 |   return (u, overrideOptions) => parser(u, mergeParseOptions(options, overrideOptions));
432 | };
433 | const getSync = (ast, isDecoding, options) => {
434 |   const parser = getEither(ast, isDecoding, options);
435 |   return (input, overrideOptions) => Either.getOrThrowWith(parser(input, overrideOptions), issue => new Error(TreeFormatter.formatIssueSync(issue), {
# 以下省略
```

つまり、エラーが発生する場合にはこの時点でプログラムがコケてしまうことを意味します。

#### decodeUnknownEither

```ts
console.log(decoderEither(data))
// {
//   _id: "Either",
//   _tag: "Right",
//   right: {
//     bigBoss: "SakelienGiant",
//     phaseId: "664a94e1db05b9e98a069059",
//     stage: 104,
//     weapons: [ 200, 6000, 1020, 2050 ],
//     rareWeapons: [],
//   },
// }
```

一方、`decodeUnknownEither`を利用した場合には直接値が返ってきません。

何やら`_tag`というプロパティが見えますが、これはデコードが成功した場合に`Right`という値が入ります。

成功したら`Right`、失敗したら`Left`になります。

```zsh
{
  _id: "Either",
  _tag: "Left",
  left: {
    _id: "ParseError",
    message: "{ readonly bigBoss: string; readonly phaseId: string; readonly stage: <enum 15 value(s): 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14>; readonly weapons: ReadonlyArray<<enum 71 value(s): 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30 | 31 | 32 | 33 | 34 | 35 | 36 | 37 | 38 | 39 | 40 | 41 | 42 | 43 | 44 | 45 | 46 | 47 | 48 | 49 | 50 | 51 | 52 | 53 | 54 | 55 | 56 | 57 | 58 | 59 | 60 | 61 | 62 | 63 | 64 | 65 | 66 | 67 | 68 | 69 | 70>>; readonly rareWeapons: ReadonlyArray<<enum 71 value(s): 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30 | 31 | 32 | 33 | 34 | 35 | 36 | 37 | 38 | 39 | 40 | 41 | 42 | 43 | 44 | 45 | 46 | 47 | 48 | 49 | 50 | 51 | 52 | 53 | 54 | 55 | 56 | 57 | 58 | 59 | 60 | 61 | 62 | 63 | 64 | 65 | 66 | 67 | 68 | 69 | 70>> }\n└─ [\"stage\"]\n   └─ Expected <enum 15 value(s): 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14>, actual 200",
  },
}
```

デコードできない値を入れたときには`ParseError`が発生しますが、それを含んだ値自体が返ります。

つまり、エラーが発生してもこの段階ではプログラムは落ちません。

#### decodeUnknownOption

```ts
console.log(decoderOption(data))
// {
//   _id: "Option",
//   _tag: "Some",
//   value: {
//     bigBoss: "SakelienGiant",
//     phaseId: "664a94e1db05b9e98a069059",
//     stage: 104,
//     weapons: [ 200, 6000, 1020, 2050 ],
//     rareWeapons: [],
//   },
// }
```

Optionの場合はこのような値が返ってきます。

```zsh
{
  _id: "Option",
  _tag: "None",
}
```

デコードできない値を入れた場合にはこのような値が返ります。エラーは発生しませんが、なぜ失敗したのかもわからない感じですね。

#### decodeUnknownPromise

```ts
console.log(decoderPromise(data))
// Promise { <pending> }
console.log(await decoderPromise(data))
// {
//   bigBoss: "SakelienGiant",
//   phaseId: "664a94e1db05b9e98a069059",
//   stage: 104,
//   weapons: [ 200, 6000, 1020, 2050 ],
//   rareWeapons: [],
// }
```

`decodeUnknownPromise`の場合は`decodeUnknownSync`のPromise版といった感じです。

普通、デコード自体はは一瞬で終わるはずなので、API通信などのレスポンスを非同期でデコードしたい場合に使うのだと思います。

```zsh
# console.log(decoderPromise(data))
Promise { <pending> }
240 |  * @category constructors
241 |  */
242 | export const Error = /*#__PURE__*/function () {
243 |   return class Base extends core.YieldableError {
244 |     constructor(args) {
245 |       super();
                                 ^
(FiberFailure) ParseError:

# console.log(await decoderPromise(data))
240 |  * @category constructors
241 |  */
242 | export const Error = /*#__PURE__*/function () {
243 |   return class Base extends core.YieldableError {
244 |     constructor(args) {
245 |       super();
```

こちらの場合もデコードできない値をいれると`decodeUnknownSync`のようにエラーが直接返ります。

#### decodeUnknown

```ts
console.log(decoderUnknown(data))
// {
//   _id: "Either",
//   _tag: "Right",
//   right: {
//     bigBoss: "SakelienGiant",
//     phaseId: "664a94e1db05b9e98a069059",
//     stage: 104,
//     weapons: [ 200, 6000, 1020, 2050 ],
//     rareWeapons: [],
//   },
// }
```

ここだけ見ると`decodeUnknownEither`と全く同じですね。

```zsh
{
  _id: "Either",
  _tag: "Left",
  left: {
    _id: "ParseError",
    message: "{ readonly bigBoss: string; readonly phaseId: string; readonly stage: <enum 15 value(s): 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14>; readonly weapons: ReadonlyArray<<enum 71 value(s): 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30 | 31 | 32 | 33 | 34 | 35 | 36 | 37 | 38 | 39 | 40 | 41 | 42 | 43 | 44 | 45 | 46 | 47 | 48 | 49 | 50 | 51 | 52 | 53 | 54 | 55 | 56 | 57 | 58 | 59 | 60 | 61 | 62 | 63 | 64 | 65 | 66 | 67 | 68 | 69 | 70>>; readonly rareWeapons: ReadonlyArray<<enum 71 value(s): 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 19 | 20 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 29 | 30 | 31 | 32 | 33 | 34 | 35 | 36 | 37 | 38 | 39 | 40 | 41 | 42 | 43 | 44 | 45 | 46 | 47 | 48 | 49 | 50 | 51 | 52 | 53 | 54 | 55 | 56 | 57 | 58 | 59 | 60 | 61 | 62 | 63 | 64 | 65 | 66 | 67 | 68 | 69 | 70>> }\n└─ [\"stage\"]\n   └─ Expected <enum 15 value(s): 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14>, actual 200",
  },
}
```

こちらも`decodeUnknownEither`と全く同じですね。

### デコードオプション

デコードにはオプションがあるので見てみることにします。

```ts
/**
 * @category model
 * @since 1.0.0
 */
export interface ParseOptions {
  /** default "first" */
  readonly errors?: "first" | "all" | undefined
  /** default "ignore" */
  readonly onExcessProperty?: "ignore" | "error" | "preserve" | undefined
}
```

#### `onExcessProperty`

定義されていないプロパティが渡されたときに、どのような挙動を見せるのかを決めます。

```zsh
# Ignore
{
  _id: "Either",
  _tag: "Right",
  right: {
    bigBoss: "SakelienGiant",
    phaseId: "664a94e1db05b9e98a069059",
    stage: 104,
    weapons: [ 200, 6000, 1020, 2050 ],
    rareWeapons: [],
  },
}

# Preserve
{
  _id: "Either",
  _tag: "Right",
  right: {
    startTime: "2024-05-26T16:00:00Z",
    endTime: "2024-05-28T08:00:00Z",
    bigBoss: "SakelienGiant",
    phaseId: "664a94e1db05b9e98a069059",
    stage: 104,
    weapons: [ 200, 6000, 1020, 2050 ],
    rareWeapons: [],
  },
}

# Error
{
  _id: "Either",
  _tag: "Left",
  left: {
    _id: "ParseError",
    message:
    ...
}

# Undefined
{
  _id: "Either",
  _tag: "Right",
  right: {
    bigBoss: "SakelienGiant",
    phaseId: "664a94e1db05b9e98a069059",
    stage: 104,
    weapons: [ 200, 6000, 1020, 2050 ],
    rareWeapons: [],
  },
}
```

この結果をまとめると、

- `ignore`
  - 無視、そのような値は入っていないとする、これがデフォルト値
- `preserver`
  - バリデーションを行わず、そのまま含める
- `error`
  - エラーを返す
- `undefined`
  `ignore`と同じ？

定義されていないプロパティを勝手に加えてしまうと意図せぬ挙動が発生する可能性があるので、サーバーサイドの観点からはデフォルトの`ignore`または`error`を利用するのが良さそうです。

### `errors`

エラーが発生したときの挙動を決めます。

- `first`
  - 発生した最初のエラーだけを返す、これがデフォルト値
- `all`
  - 発生した全てのエラーを返す

開発環境では全部のエラーが一気に表示されたほうが良いかもしれませんね。

### エンコード

デコードと逆の操作のはずなのですが、未だによくわかっていません。

```ts
export const CreateScheduleSchema = S.Struct({
  bigBoss: S.String,
  phaseId: S.String,
  startTime: S.String,
  endTime: S.String,
  stage: S.Enums(CoopStage.Id),
  weapons: S.Array(S.Enums(WeaponInfoMain.Id)),
  rareWeapons: S.Array(S.Enums(WeaponInfoMain.Id))
})
```

エンコードの場合には以下のメソッドが利用できます。

- `encodeSync`
  - エンコードし、エラーかその値を返す
- `encodeOption`
  - エンコードし、Option型を返す
- `encodeEither`
  - エンコードし、Either型を返す 
- `encodePromise`
  - エンコードし、非同期でPromise型を返す 
- `encode`
  - エンコードし、Effect型を返す

## 変換

### Stirng

ただの文字列型。

- Split
- Trim
- Lowercase
- ParseJson

### Number

ただの数値型。


- NumberFromString
- Clamp

### BigDecimal

十進数整数型、十進数については完璧な精度を持つ。

- BigDecimalFromNumber
- ClampBigDecimal
- NegateBigDecimal

### Duration

日付とかだと思う、多分。

- Duration
- DurationFromNumber
- DurationFromBigint
- ClampDuration

### Secret

シークレット型。どうやら文字列の仲間らしい。

- Secret

### Bigint

Numberでは扱えない巨大な数はこちらを使う。

- Bigint
- BigintFromNumber
- Clamp

### Boolean

真理値型、言うまでもない。

- Not

### Date

日付型。

- Date

## 再帰型

プロパティの中に自分自身の型を持ちたいとき、ありますよね？

```ts
import * as S from "@effect/schema/Schema";

interface Category {
  readonly name: string;
  readonly subcategories: ReadonlyArray<Category>;
}

const Category: S.Schema<Category> = S.Struct({
  name: S.String,
  subcategories: S.Array(S.suspend(() => Category)),
});
```

こうすれば書けます。

## 型

[チートシート](https://github.com/Effect-TS/schema?tab=readme-ov-file#cheatsheet)に大体書いてあるのでここの内容をまとめる。

### Primitives

- Primitive Values
  - `String`
  - `Number`
  - `Bigint`
  - `Boolean`
  - `Symbol`
  - `Object`
- Empty Types
  - `Undefined`
  - `Void`
- Catch All Types
  - `Any`
  - `Unknown`
- Never Type
  - `Never`
- Literals
  - `Null`
  - `Literal`
- Others
  - `Json`
  - `UUID`
  - `ULID`

### Enums

TypeScriptで定義したEnumがそのまま使えます。

```ts
enum Fruits {
  Apple,
  Banana,
}

// $ExpectType Schema<Fruits>
S.Enums(Fruits);
```

とっても便利！！！

### Nullable

```ts
// $ExpectType Schema<String | null>
S.Nullable(S.String);
```

`null`が入ってもいいよっていうときはこれ！

### Unions

```ts
// $ExpectType Schema<String | Number>
S.Union(S.String, S.Number);
```

Unionでどちらの型も受け付けられるUnionって便利だったりするんですが、それにも対応しています。

この書き方だとStringかNumberかのどっちかならオッケーという感じ。

### Tuples

タプルもチェックできます。

```ts
// $ExpectType Schema<readonly [String, Number]>
S.Tuple(S.String, S.Number);
```

### Arrays

当然、配列もチェックできます。

```ts
// $ExpectType Schema<readonly Number[]>
S.Array(S.Number);
```

#### Mutable Arrays

```ts
// $ExpectType Schema<Number[]>
S.Mutable(S.Array(S.Number));
```

#### Non empty Arrays

```ts
S.NonEmptyArray(S.Number);
```

空の配列は許容しない。後で出てくるFilterを使っても良さそう。

### Structs

構造体。基本的にはこれを使えば良いと思う。

```ts
// $ExpectType Schema<{ readonly a: String; readonly b: Number; }>
S.Struct({ a: S.String, b: S.Number });
```

### フィルター

文字列であるうえで更に条件をつけたい場合にフィルターを利用する。

#### String

```ts
S.String.pipe(S.MaxLength(5)); // 最大長さ
S.String.pipe(S.MinLength(5)); // 最低長さ
S.String.pipe(NonEmpty()); // 空文字を許容しない same as S.minLength(1)
S.String.pipe(S.Length(5)); // 文字数指定
S.String.pipe(S.Pattern(regex)); // 正規表現にマッチ
S.String.pipe(S.StartsWith(string)); // 先頭を指定
S.String.pipe(S.EndsWith(string)); // 末尾を指定
S.String.pipe(S.Includes(searchString)); // 指定文字列を含む
S.String.pipe(S.Trimmed()); // 前後の空白削除 verifies that a string contains no leading or trailing whitespaces
S.String.pipe(S.Lowercased()); // 小文字のみ許容 verifies that a string is lowercased
```

#### Number

```ts
S.Number.pipe(S.GreaterThan(5)); // 5 < x 
S.Number.pipe(S.GreaterThanOrEqualTo(5)); // 5 <= x
S.Number.pipe(S.LessThan(5)); // x < 5
S.Number.pipe(S.LessThanOrEqualTo(5)); // x <= 5
S.Number.pipe(S.Between(-2, 2)); // -2 <= x <= 2
S.Number.pipe(S.Int()); // 整数型 value must be an integer
S.Number.pipe(S.NonNaN()); // 数値 not NaN
S.Number.pipe(S.Finite()); // 有限の数 
S.Number.pipe(S.Positive()); // 0 < x
S.Number.pipe(S.NonNegative()); // 0 <= x
S.Number.pipe(S.Negative()); // x < 0
S.Number.pipe(S.NonPositive()); // x <= 0
S.Number.pipe(S.MultipleOf(5)); // 5の倍数
```

### Bigint

```ts
S.Bigint.pipe(S.GreaterThanBigint(5n));
S.Bigint.pipe(S.GreaterThanOrEqualToBigint(5n));
S.Bigint.pipe(S.LessThanBigint(5n));
S.Bigint.pipe(S.LessThanOrEqualToBigint(5n));
S.Bigint.pipe(S.BetweenBigint(-2n, 2n)); // -2n <= x <= 2n
S.Bigint.pipe(S.PositiveBigint()); // 0n < x 
S.Bigint.pipe(S.NonNegativeBigint()); // 0n <= x
S.Bigint.pipe(S.NegativeBigint()); // x < 0n
S.Bigint.pipe(S.NonPositiveBigint()); // x <= 0n
```

### BigDecimal

```ts
S.BigDecimal.pipe(S.GreaterThanBigDecimal(BigDecimal.FromNumber(5)));
S.BigDecimal.pipe(S.GreaterThanOrEqualToBigDecimal(BigDecimal.FromNumber(5)));
S.BigDecimal.pipe(S.LessThanBigDecimal(BigDecimal.FromNumber(5)));
S.BigDecimal.pipe(S.LessThanOrEqualToBigDecimal(BigDecimal.FromNumber(5)));
S.BigDecimal.pipe(
  S.BetweenBigDecimal(BigDecimal.FromNumber(-2), BigDecimal.FromNumber(2))
);

S.BigDecimal.pipe(S.PositiveBigDecimal());
S.BigDecimal.pipe(S.NonNegativeBigDecimal());
S.BigDecimal.pipe(S.NegativeBigDecimal());
S.BigDecimal.pipe(S.NonPositiveBigDecimal());
```

### Duration

```ts
S.Duration.pipe(S.GreaterThanDuration("5 seconds"));
S.Duration.pipe(S.GreaterThanOrEqualToDuration("5 seconds"));
S.Duration.pipe(S.LessThanDuration("5 seconds"));
S.Duration.pipe(S.LessThanOrEqualToDuration("5 seconds"));
S.Duration.pipe(S.BetweenDuration("5 seconds", "10 seconds"));
```

### Array

```ts
S.Array(S.Number).pipe(S.MaxItems(2)); // max array length
S.Array(S.Number).pipe(S.MinItems(2)); // min array length
S.Array(S.Number).pipe(S.ItemsCount(2)); // exact array length
```