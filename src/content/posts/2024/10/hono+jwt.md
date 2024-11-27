---
title: Hono+Cloudflare WorkersをJWTで認証しよう
published: 2024-10-16
description: JWT認証から逃げ続けるのはもうやめよう
category: Programing
tags: [Hono, Cloudflare Workers, JWT]
---

## 認証

ユーザーの認証やサービスを提供にするにあたってユーザーを識別する機能は必須です。

それをやるだけならBasic認証とかでもいいわけですが、もしもパスワードが洩れてパスワードを変えられてしまったら大変ですよね。そうなるともはやどっちが本人かもわからなくなってしまって「乗っ取られたのでパスワードをリセットしてください」すら信用できなくなるわけです。

なので今回はそれをもうちょっと安全にします。

具体的にはDiscordのアカウントで認証を行って、それに対するJSON Web Tokenを発行します。通常、JWTは一定時間(大体数時間のことが多い)で失効する上にJWTにはscopeを利用して権限をつけることができるので、admin権限がついているトークンを発行してそれを洩らさない限りは安心です。

また、万が一洩れてしまっても期限が切れているものであれば悪用はできません。アクセストークン自体を発行できる有効なトークンが洩れたらそれは問題ですが、それはそんなトークンを発行した上に洩らした側が悪いので無視しましょう。

### 秘密鍵

JWTの署名アルゴリズムはいくつかあるのですが、個人開発であれば対称鍵であればよいでしょう。

非対称であればユーザー側でも検証ができたり、異なるサーバーでも運用が簡単だったりするのですが個人開発であればどうせサーバーも一台でしょうし問題ありません。

秘密鍵生成にはいつもどおり[1Password Generator](https://1password.com/password-generator)を利用します。

今回は長さ43の鍵を生成しました。このくらいの長さがあればはっきりと安全、と言えるでしょう。

英数字だけでも43文字あればおよそ256bit分の安全性があります。

### Hono

```ts
app.openAPIRegistry.registerComponent('securitySchemes', 'Bearer', {
  type: 'http',
  scheme: 'bearer',
  in: 'header',
  description: 'Bearer Token'
})
```

OpenAPIでBearerTokenが利用できるようにこれを`index.ts`に書きます。

公式の`bearerAuth`を使ってもいいのですが、大した労力でもないので自作します。

```ts
import type { Bindings } from '@/utils/bindings'
import type { Context, Next } from 'hono'
import { jwt } from 'hono/jwt'
import { AlgorithmTypes } from 'hono/utils/jwt/jwa'

export const bearerToken = async (c: Context<{ Bindings: Bindings }>, next: Next) => {
  return jwt({
    secret: c.env.JWT_PRIVATE_KEY,
    alg: AlgorithmTypes.HS256
  })(c, next)
}
```

あらかじめ`.dev.vars`に`JWT_PRIVATE_KEY`を追加して`Bindings`で読み込めるようにしておきましょう。

アルゴリズムのHS256は高速な対称アルゴリズムで、個人開発であればこの程度で良いとのこと。

```ts
app.openapi(
  createRoute({
    method: HTTPMethod.GET,
    path: '/users',
    middleware: [bearerToken],
  })
)
```

のようにエンドポイントを定義して`BearerToken`が必要であることを明示します。これを書かないと意味がないので注意。

この状態でPostmanなどでBeaerTokenを設定せずにアクセスすると、

```json
{
  "message": "no authorization included in request"
}
```

でステータスコード401が返ってきて、正しく認証できていることがわかります。
