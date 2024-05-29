---
title: Hono + Cloudflare Workers 
published: 2024-05-24
description: Cloudflare Workersが便利そうなので使ってみることにしました 
category: Programming
tags: [Hono, Cloudflare, Cloudflare Workers]
---

## Hono

普段APIを立てるときはNestJSを利用するのですが、今回はHonoを使います。

その理由はNodeJSへの依存が少ないのとCloudflare Workersに対応しているからです、ただそれだけ。

### 環境構築

[Cloudflare Workers + Hono](https://github.com/Magisleap/Hono)のテンプレートをつくっていたのでそれを利用します。

Cloudflare Workersの設定は主に`wrangler.toml`に書き込まれているので、ここを設定します。

## `wrangler.toml`

```toml
name = "hono-app"
compatibility_date = "2023-12-01"
main = "src/index.ts"
minify = true
```

基本的な設定はこんな感じです。

### 環境変数

結構詰まったのがここでした。

単にHonoを動かす場合には`.env`に書き込んでおけば、

```ts
import { Hono } from 'hono'
import { cache } from 'hono/cache'
import { cors } from 'hono/cors'
import { csrf } from 'hono/csrf'
import { logger } from 'hono/logger'

const app = new Hono()

export default {
  port: 32821,
  fetch: app.fetch,
}
```

```ts
import { env } from 'hono/adapter'

app.get('', async (c) => {
    const { PRIVATE_TOKEN } = env<{ PRIVATE_TOKEN: string}>(c)
    return c.json({ PRIVATE_TOKEN: PRIVATE_TOKEN })
})
```

のような感じで取得できます。

ところがCloudflare Workersで動かした場合にはこの方法では環境変数を取得できません。

[公式ドキュメント](https://developers.cloudflare.com/workers/configuration/environment-variables/)を見てみると環境変数を`wrangler.toml`に書き込む方法が解説されていますが、この手順では`wrangler.toml`に機密情報が含まれる場合`wrangler.toml`をgitで管理することができないというデメリットが生じてしまいます。

```toml
name = "hono-app"
compatibility_date = "2023-12-01"
main = "src/index.ts"
minify = true

[vars]
PRIVATE_TOKEN = "SECRET_VALUE"
```

更に、このままworkersを立ち上げると、

```zsh
Your worker has access to the following bindings:
- Vars:
  - PRIVATE_TOKEN: "SECRET_VALUE"
```

という感じで変数の中身がそのまま標準出力されます。

で、その対策として利用されるのが`.*.vars`という独自の仕組みで、大体`.env`と同じように使えます。

```vars
PRIVATE_TOKEN = "SECRET_VALUE"
```

開発環境の環境変数を突っ込みたい場合には`.env.vars`に書き込むと良いです。

```zsh
Using vars defined in .dev.vars
Your worker has access to the following bindings:
- Vars:
  - PRIVATE_TOKEN: "(hidden)"
```

すると起動したときに値を隠すことができます。

これでローカルで環境変数をCloudflare Workersに渡すことができ、この値はそのままHonoが取得することができます。