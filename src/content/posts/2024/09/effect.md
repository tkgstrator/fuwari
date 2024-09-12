---
title: EffectTSよりZodを使おう 
published: 2024-09-12
description: 以前ちょっとだけ紹介したかもしれないEffectTSですが...... 
category: Programming
tags: [TypeScript, Bun, Cloudflare, EffectTS, Zod]
---

## EffectTS vs Zod

[Zod](https://github.com/colinhacks/zod)とはTypeScript-fristなスキーマのバリデーションライブラリで、同様の機能を持つものに以前ひょっとしたらちょっとだけ紹介したかもしれない[EffectTS](https://github.com/Effect-TS/effect)があります。

こちらはTypeScriptのエコシステムという感じでZodよりももうちょっとだけ強力なイメージがあります。

で、実は以前はEffectTSを採用しているプロジェクトもあったのですが今は100%完全にZodを利用しており、EffectTSからZodへの置き換え作業も行っています。

今回は何故EffectTSを採用し、Zodへ移行することを決断したのかについて簡単にまとめたいと思います。

### 必要とされる理由

TypeScriptはJavaScriptのスーパーセットであるため、型は明示できますしその型の値が入っていることは静的解析の時点でコンパイラが保証してくれますが、APIとの通信の兼ね合いでどうしても型を保証できないタイミングが発生します。

その時に確実に指定した型に変換されることを保証し、合致しない場合にはエラーを変えしてくれるようなシステムがあればAPIから何が返ってくるかをビクビクせずに済むわけです。

この機能を実装するために以前は[class-validator](https://github.com/typestack/class-validator)と[class-transformer](https://github.com/typestack/class-transformer)を採用していましたが、デコレータで記述するという仕様上どうしてもコードが煩雑になりがちでした。

複雑なレスポンスを処理するときなど、ファイルの殆どがデコレータになってしまったこともあります。

そこでEffectTSのようなエコシステムが必要になったわけです。

### Zodに乗り換えた理由

乗り換えた理由は、EffectTSの機能に不満があったというよりは「利用したいフレームワークを選んだ結果Zodしか選択肢がなかった」という方が正しいかもしれません。

[公式ドキュメント](https://github.com/Effect-TS/effect/tree/main/packages/schema)にもあるようにEffect/SchemaはゴリゴリにZodを意識しています。

よって、Effect/Schemaで実行できることはZodでもだいたいできます。

では何故Effect/SchemaからZodに乗り換えたのかを解説します。

#### 公式ドキュメントがわかりにくい

Effect/Schemaが最近モノレポになったことが影響するのかもしれませんが、更新されないまま古いコード例が残っていたりして使い方がわからないことが多かったです。

#### ググっても何もでてこない

これも先にリリースされていたZodの方がググったときに参考文献がたくさん見つかりました。これはZodという名前にも影響しているのかもしれません。

正直、EffectTSという名前では検索してもEffectの方に引っ張られて本当に欲しい情報を探すのにとても苦労しました。

#### HonoのMiddlewareとして公開されている

恐らく、最大にして最強の理由がこれ。

class-transformerやclass-validatorを見限ったのもこれです。

現状、私は何かしらのサービスを運用しようと考えた場合にまずCloudflare Workersが利用できないかを考えます。

そしてWeb APIを作成するのであればCloudflare Workers + Honoという組み合わせは鉄板です。NestJSはCloudflare Workersでは動作しません。

となるとHonoの[Middleware](https://hono.dev/docs/middleware/third-party)としてZodが公開されている以上、Zodを利用するのは至極当然と言えます。

## まとめ

何も考えずにZodを使え。