---
title: Wranglerが突然ぶっ壊れた話
published: 2024-07-26
description: Wranglerが立ち上がらなくなってしまったのでその備忘録として 
category: Programming
tags: [Cloudflare, Cloudflare KV, Hono, Cloudflare Workers]
---

## Wrangler

WranglerはCloudflare KVやCloudflare Workersを含めて主要なサービスをNodeJSランタイムから実行できるフレームワークです。

特にCloudflare Workersを利用する際にはローカルでテストする際にKVと接続するためにほとんど必須のような状態になっています。

### 突然の死

どのタイミングからかは忘れてしまったのですが、Wranglerが突然立ち上がらなくなってしまいました。

正確に言うと、立ち上がっているのですがブラウザ経由でアクセスするといつまでも処理が始まらないといった感じです。

このバグには二種類のタイプがあるようで、

1. そもそもWranglerが起動直後に落ちる
2. 起動はしているようだがブラウザ経由でアクセスできない(Postman等も不可)

でした