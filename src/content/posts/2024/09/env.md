---
title: Honoで環境変数を扱う方法 
published: 2024-09-05
description: Honoで環境変数を読み込む方法がいつもわからなくなるので 
category: Programming
tags: [TypeScript, Hono, Bun, Cloudflare, Cloudflare Workers]
---

## Hono + Bun

TypeScriptでアプリケーションを作成する際、環境変数の読み込みについては毎回困るので対応方法についてメモしてみました

| フレームワーク     | 環境変数        | ファイル  | 備考                          | 
| :----------------: | :-------------: | :-------: | :---------------------------: | 
| Bun                | process.env     | .env      | -                             | 
| Cloudflare Workers | c.env           | .dev.vars | -                             | 
| Vite               | import.meta.env | .env      | `VITE_`のプレフィックスが必要 | 
| Node               | process.env     | .env      | dotenvが必要                  | 

### Vite

Viteでの環境変数の読み込みについての[ドキュメント](https://ja.vitejs.dev/guide/env-and-mode)によるとViteでは環境変数を`import.meta.env`で読み込み、更にそれぞれの環境変数は`VITE_`のプレフィックスがついている必要があります。

内部的には`dotenv`が利用されているらしいので、追加で`dotenv`をインストールする必要はありません。

### Node.js

Node.jsではそのまま環境変数を読み込むことが出来ないので[`dotenv`](https://github.com/motdotla/dotenv)をインポートする必要があります。

使い方に関してはレポジトリのREADME.mdを読んでください。

### Bun

Bunでは[ドキュメント](https://bun.sh/guides/runtime/read-env)によれば何もしなくても`.env`が読み込まれます。Viteのようなプレフィックスも不要です。

`process.env`で読み込むことが出来ますがエイリアスがあるので`Bun.env`としても読み込めます。

### Cloudflare Workers

Cloudflare Workers + Honoの環境では`Context`と呼ばれる仕組みを利用して`c.env`で環境変数にアクセスできます。

更に`Bindings`の仕組みを使うことで本来環境変数を読み込むと型が`string | undefined`になってしまうのですが、値が存在することを保証させることができます。

```zsh
API_KEY=XXXXXXXX
```

というような文字列を`.dev.vars`に書き込みます。

```ts
type Bindings = {
  API_TOKEN: string
}

const app = new Hono<{ Bindings: Bindings }>()
```

のような感じで利用できます。これについてはHonoの[公式ドキュメント](https://hono.dev/docs/getting-started/cloudflare-workers#bindings)が充実しているのでそちらを読んでみるとよいでしょう。

## 結論

で、今回はCloudflare Workersは使わないけどHonoもBunも使う状況で`Bindings`を利用して環境変数をちゃんと読み込みたいという需要に対する解決策を提案します。

Cloudflare Workersを使っていない場合(`bun wrangler dev src/index.ts`のように実行していない場合)は`.dev.vars`を読み込まないので`c.env`とやっても環境変数を読み込むことは出来ません。

Bunを使っていれば`Bun.env`で読み込めますが`string | undefined`になってしまいます。

```ts
app.use('*', async (c: Context, next) => {
  c.env = { ...process.env }
  await next()
})
```

で、早いですが結論から言うと上のコードを`src/index.ts`に書き込みます。

すると`process.env`の中身が`c.env`にマージされます。

こうしたうえで`Bindings`を正しく設定することで`c.env.API_TOKEN`が`undefined`にならずに取得することができます。　

### 最後に

わかってしまえば簡単でした。記事は以上。