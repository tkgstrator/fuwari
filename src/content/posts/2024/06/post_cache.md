---
title: Hono + Cloudflare Workersでキャッシュを利用する 
published: 2024-06-25
description: キャッシュを利用して常に高速にレスポンスを返すようにしましょう 
category: Programming
tags: [Cloudflare, Cloudflare KV, Hono, Cloudflare Workers]
---

## キャッシュ

キャッシュを有効化することで、一定時間以内に再アクセスされた場合に新たにレスポンスを返さずに高速に応答することができるようになります。

で、ここは詳しくないのでよくわかっていないのですがクライアント側のキャッシュとサーバー側のキャッシュの二つがあるんじゃないかと思っています。

### クライアント

レスポンスのヘッダーにキャッシュの有効期限が設定されていた場合、再度アクセスをしようとしたときに有効期限内であればサーバーへのリクエストを行わずに以前受け取ったレスポンスを返す。

サーバーへのリクエストを行わないので最も速く、ステータスコード304を返す。

### サーバー

レスポンスの再生成に一定のコストがかかる場合、キャッシュの有効期限内であれば再生成を行わずに以前生成したデータをそのまま返すような仕組み。

例えば、一時間に一回しか更新されない天気情報などがあればサーバーは一時間に一回だけレスポンスを生成すればよい。

## キャッシュの利点

例えば大雑把にレスポンスの生成に9秒、レスポンスを返すのに1秒かかりデータの更新は一時間に一回あるシステムがあるとします。

模試このサーバーに一時間に3600回のリクエストがあれば、キャッシュを利用しない場合は全員がデータ取得に10秒かかり、合計で36000秒かかることになります。

もしここでキャッシュを利用すれば最初の一人だけはリクエスト時にキャッシュを更新する処理が走るので10秒かかりますが、それ以外の人はキャッシュを利用して1秒で取得できるので10+3599=3609秒しかかかりません。

なんとこれだけで10倍高速化できることになるわけです。

ただし、この方式で困るのは一時間に一回、キャッシュの恩恵を受けることができない人が少なくとも一人出てきてしまうということです。

これを解消するのがPost Cacheという仕組みです。

### Post Cache

Post Cacheについては元々そういう仕組みがあればいいのになと思っていたのですが、NextJSなどでは既に実装されているようです。

なお、実装にあたっては[Hono + Cloudflare Workersでいい感じにpost cacheする](https://zenn.dev/monica/articles/a9fdc5eea7f59c)が大変参考になりました。

簡単にいうと、本来ユーザーがアクセスしたタイミングで行われるサーバーサイドのキャッシュ生成をバックグラウンドで動かすようにしようということです。

これは例えばGoogle App Scriptsで定期実行するとかCronで定期実行するとか色々考えられるのですが、Cloudflare Workersには[Cron Triggers](https://developers.cloudflare.com/workers/configuration/cron-triggers/)という仕組みが実装されているので余計なことをせずとも定期実行が可能です。

この仕組みと`c.executionCtx.waitUntil`を利用して常にキャッシュを返すAPIを作成してみます。

## 仕組み

Cloudflare KVを利用してキャッシュの内容と有効期限の二つのプロパティを持つデータを定義します。

```ts
export type CacheMetadata = {
  expiresIn: string
}

export type CacheResult = {
  cache: string | null
  isExpired: boolean
}
```

Cloudflare KVにはそれ自体に有効期限が設定できるのですが、こちらを設定してしまうと有効期限が切れたタイミングでキャッシュ自体が削除されてしまいます。

よって、独自に有効期限のプロパティを持つデータを定義する必要があります。

### KVCache

今回は適当に`KVCache`という名前空間を作成しました。

```ts
export namespace KVCache {
  export const get = async (c: Context<{ Bindings: Bindings }>): Promise<CacheResult> => {
    // KEYは適当に設定する感じで
    // 私のプロジェクトではアクセスされたURLに対してキーを発行している
    const { value, metadata } = await c.env.Cache.getWithMetadata<CacheMetadata>('KEY')
    if (value === null || metadata === null) {
      return {
        cache: null,
        isExpired: true
      }
    }
    return {
      cache: value,
      // dayjsを利用してキャッシュの有効期限と現在時刻を比較する
      isExpired: dayjs(metadata.expiresIn).unix() < dayjs().unix()
    }
  }

  export const put = async (c: Context<{ Bindings: Bindings }>, value: any): Promise<void> => {
    // KEYは適当に設定する感じで
    // 私のプロジェクトではアクセスされたURLに対してキーを発行している
    await c.env.Cache.put('KEY', JSON.stringify(value), { metadata: { expiresIn: expiresIn } })
  }
}
```

KVCacheは単純にキーを指定してキャッシュを取得して、キャッシュの内容と有効期限が切れているかどうかを返します。

キャッシュが存在しない場合(初回のアクセス時)のみ条件文の最初の条件に引っかかります。

## KVCacheの利用方法

```ts
// 重い処理
export const CACHE_CREATE = async (c: Context<{ Bindings: Bindings }>): Promise<DATA> => {
  const data = // 何らかのデータを作成する
  await KVCache.put(c, data)
  return data
}

app.get('/', async (c) => {
  const { cache, isExpired } = await KVCache.get(c)
  if (isExpired) {
    // キャッシュが有効期限切れの場合、バックグラウンドで更新する
    c.executionCtx.waitUntil(CACHE_CREATE())
  }
  if (cache !== null) {
    // キャッシュがあればその値を返す
    return c.json({ JSON.parse(cache) })
  }
  // 最初の一回だけ実行される
  // キャッシュがなければ作成して更新する
  return c.json({ JSON.parse(CACHE_CREATE()) })
})
```

なんだか条件はもう少しいい感じに書けそうな気がするのですが、これで常にキャッシュを返せるようになります。

ただ、このコードだけだと誰もアクセスしないといつまで経ってもキャッシュが更新されないのでCron Triggersを利用して定期的にキャッシュを更新するようにします。

## Cron Triggers

`wrangler.toml`を編集して、

```toml
[triggers]
crons = ["*/15 * * * *"]
```

のような内容を書きます。

これは15分毎に実行されるを意味します。

以下は一例ですが、`src/index.ts`に下記の内容を追記します。

```ts
const UPDATE_CACHE = async (controller: ScheduledController, env: Env, ctx: ExecutionContext): Promise<void> => {
  // 実行されるコードを書きます
}

const scheduled = (event: ScheduledController, env: Env, ctx: ExecutionContext) => {
  // 定期実行したいコードを書く
  // 今回の場合はUPDATE_CACHEを実行したいわけなので
  ctx.waitUntil(UPDATE_CACHE())
}

export default {
  port: 3000,
  fetch: app.fetch,
  scheduled // 必須
}
```

こうすることで十五分に一回キャッシュが自動で更新され、誰がいつアクセスしても一瞬でレスポンスが返るようになります、便利ですね。

記事は以上。