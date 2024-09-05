---
title: BlueskyのBot作成をしてみた
published: 2024-09-05
description: Blueskyで動作する将棋Botを作成してみました 
category: Programming
tags: [TypeScript, Bun, Cloudflare]
---

## Bluesky

X(旧Twitter)のAPI規制が強いのでBluesky向けのBotを作成することにしました。

BlueskyのAPIにも[Rate Limits](https://docs.bsky.app/docs/advanced-guides/rate-limits)は存在するのですが、Xのものに比べて格段に緩いので、今後Botを作成するのであればBlueskyのBotは検討の余地があると思います。

### 技術スタック

BluskyのSDKはTypeScript向けのものがあるのでそれを利用しましょう。一応Python向けのもありますがCloudflare Workersで動作させたいのでそっちの方がいいと思います。

- TypeScript
- Bun/Node.js
- Hono
- Cloudflare Workers
- Cloudflare R2

今回は上記の技術スタックを採用しました。

Cloudflare WorkersにはCron Eventsという定期実行の仕組みがあるので、それを利用することで定期的にBotを動作させることができます。

Cloudflare R2は必ずしも必要ではないのですが、今回は採用した将棋Botでデータを毎回ソースにアクセスするのではなくR2に保存しておくことで最初の一回以外は負荷をかけないように対策しました。


### 仕様

- 毎週データ更新
- 毎朝九時に対局情報
- 毎朝八時に詰将棋情報
- 十五分ごとに局面情報

をポストするようにしました。

データはあれば参照したものがあればR2から、なければソースから取得してR2に保存するようになっています。

> 毎週のデータ取得は本来は不要なのですが、一応更新するようにしています

```toml
[triggers]
crons = ["0 0 * * 1", "*/15 0-15 * * *", "0 0 * * *", "0 23 * * *"]
```

これを実行するための`wrangler.toml`は上のようになります。

Cron EventsはUTC基準なので日本時間であるJSTに変換するには`+9`する必要があります。

よって`"0 23 * * *"`は日本時間で`23+9 mod 24 = 8`となり、毎朝八時に実行することを意味するわけです。

## コード解説

では実際に使われているコードを解説します。

本当はレポジトリを公開したかったのですが、認証に関するアルゴリズムを含むため残念ながら公開することができません。

ただし、基本的なコードは[テンプレートレポジトリ](https://github.com/Magisleap/Hono)で公開しているので、こちらを利用してください。

```ts
export const scheduled = async (event: ScheduledController, env: Bindings, ctx: ExecutionContext): Promise<void> => {
  switch (event.cron) {
    case '0 0 * * *':
      break
    case '0 23 * * *':
      break
    case '*/15 0-15 * * *':
      break
    case '0 0 * * 1':
      break
    default:
      break
  }
}
```

`wrangler.toml`では複数のスケジュールを定義することができないので、ScheduledControllerの`event.cron`を利用して分岐します。

### Bluesky SDK

```zsh
bun add @atproto/api
```

で追加できます。ドキュメントも豊富でわかりやすいです。

## Botの実装

ログインするにあたってIDとパスワードが必要です。ただし、一般的なパスワードではなくアプリパスワードが必要になります。

アプリパスワードは[このリンク](https://bsky.app/settings/app-passwords)から発行できます。一度発行すると二度と表示されないので、必ずどこかに保存しておきましょう。

また、このIDとパスワードを`.dev.vars`に書き込みます。

```zsh
BLUESKY_IDENTIFIER=
BLUESKY_APP_PASSWORD=
```

### ログイン

```ts
import { AtpAgent, type ComAtprotoRepoStrongRef, RichText } from '@atproto/api'

const agent = new AtpAgent({
  service: 'https://bsky.social'
})

export const post = async (env: Bindings): Promise<void> => {
  // ここに処理を書きます
}

export const scheduled = async (event: ScheduledController, env: Bindings, ctx: ExecutionContext): Promise<void> => {
  await agent.login({
    identifier: env.BLUESKY_IDENTIFIER,
    password: env.BLUESKY_APP_PASSWORD
  })
  switch (event.cron) {
    case '0 0 * * *':
      break
    case '0 23 * * *':
      break
    case '*/15 0-15 * * *':
      break
    case '0 0 * * 1':
      break
    default:
      ctx.waitUntil(post(env))
      break
  }
}
```

`BskyAgent`は非推奨ですので`AtpAgent`を使うようにしてください。正しく`Bindings`を定義していればこのようにしてログインができます。`Env`が使えればもうちょっと便利だと思うのですが、使い方がわかっていません。

`await post(env)`と書いても動作させることはできるのですが、Cloudflare Workersは[CPU時間の制限](https://developers.cloudflare.com/workers/platform/limits/#duration)があるのでこの書き方をすると処理が重い場合にタイム・アウトしてしまいます。

ところが`ctx.waitUntil(post(env))`とすればWorkers自体が終了しても裏で処理が実行できます。

### リッチテキスト

ただのテキストではなくハイパーリンクやハッシュタグを利用したい場合には一度`RichText`を経由する必要があります。

```ts
const richText: RichText = new RichText({ text: 'ハッシュタグやリンクを含むテキスト' })
await richText.detectFacets(agent) // 忘れずに実行しよう
return agent.post({
  text: richText.text,
  facets: richText.facets
})
```

ちなみにテキストにハッシュタグやリンクが含まれていなくても大丈夫です。

### 画像投稿

```ts
const result = agent.uploadBlob(image, { encoding: 'image/png' })
const richText: RichText = new RichText({ text: 'ハッシュタグやリンクを含むテキスト' })
await richText.detectFacets(agent) // 忘れずに実行しよう
return agent.post({
  text: richText.text,
  facets: richText.facets,
  embed: {
  $type: 'app.bsky.embed.images',
  images: [{
      alt: '',
      image: result.data.blob,
      aspectRatio: {
        width: 600,
        height: 550
      }
  }]
})
```

画像はそのままポストに埋め込むのではなく、事前にアップロードすることが必要になります。また、配列を利用すれば読ん枚までアップロードできます。

`uploadBlob()`に渡す引数は`Uint8Array`ですので`Buffer`を利用するなりでうまく変換してください。`encoding`に関しては`image/png`の他に`image/jpeg`なども指定できるみたいですが、最高画質でアップロードしたいなら`image/png`一択です。

動画もどうやらSDK的には対応しているのですが、サーバーが未対応なのかアップロードしようとすると失敗します。

### リプライ

リプライするには`parent`と`root`を指定する必要があります。試していないのでわからないのですが`root`はリプライツリーが始まった一番最初のポストである必要があるかもしれません。

`parent`はいわゆるリプライ先になるので、`A->B->C`のようなリプライツリーを作りたい場合には、まず最初にリプライを指定せずにポストして`A`の`uri`と`cid`を取得し、それを`parant`と`root`に設定してポストすることで`B`を作成。最後に`parent`に`B`, `root`に`B`を指定してポストすることでCを作成するといった感じです。ちょっとめんどくさいですが、理にはかなっています。

`uri`と`cid`の値は`agent.post()`の返り値として受け取ることができます。

## まとめ

BlueskyのSDKを触ってみましたが、Xとは異なる仕様のため難しく感じる箇所もありました。

ただ、アプリパスワードを使って簡単に認証が行える点、レートリミットが比較的緩い点、デベロッパーアカウントの開設が不要な点などが便利でした。SDKに関してはまだまだ改善する余地があると思いますが、今後の発展性について期待できる内容でした。

記事は以上。