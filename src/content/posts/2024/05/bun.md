---
title: Bunでサポートされていないもの 
published: 2024-05-17
description: 自分が利用していてBunでは動かなかったものをメモしていきます
category: Programming
tags: [Bun, NodeJS, TypeScript]
---

## 脱NodeJSにはまだ早い

BunはNodeJSに代わる高速なJavaScriptランタイムで、環境によっては完全にNodeJSを利用しないような状態にすることもできますが、一方でフレームワークあるいはライブラリの依存の問題からNodeJSとの関係を断ち切れないものがあります。

普段、あまり気にすることがなかったのですが開発途中であれこれ動かないじゃんと気づいたことがあったのでそれをメモします。

### NestJS

一応サポートはされているっぽいのだが、NestJS+SWCで十分に高速なので完全な脱NodeJSはしなくても良い気はする。

特に、Prismaと連携するような場合にはPrismaがNodeJSが必要になってくるので切っても切れない関係になっている。

### Wrangler

Cloudflare謹製のCLIツールだが機能の一部で`PerformanceResourceTiming`が使われており、これが[Bunに実装されていない](https://bun.sh/docs/runtime/nodejs-apis#performance)ため動作しない。

### Karma, Webpack, Puppeteer

複雑怪奇な構造になっているのでどこが原因かはわからないのだがPuppeteerを使ってテストを実行したところBun環境では動かなかった。

```zsh
webpack was not included as a framework in karma configuration, setting this automatically...
17 05 2024 22:44:10.361:ERROR [karma-server]: Server start failed on port 9876: Error: No provider for "proxies"! (Resolving: webServer -> proxies)
```

[try-puppeteer-in-bun](https://github.com/rgl/try-puppeteer-in-bun)なんていうものもあるので、こっちを利用したほうがいいのかもしれない。

## Bun + NodeJS

じゃあどうすればいいんですか？

諦めてNodeJSを使いましょう。

ランタイムとして使うのではなく単にバンドラとかトランスパイラとして利用すればいい。

TypeScriptをそのままトランスパイルして実行できるし、ライブラリのインストールは速いしでそういう意味でも利用価値は高い。

```dockerfile
FROM oven/bun:1.1.7 

COPY --from=node:20.13.1 /usr/local/bin/node /usr/local/bin/node
COPY --from=node:20.13.1 /usr/local/lib/node_modules /usr/local/lib/node_modules

RUN ln -fs /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm
RUN ln -fs /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npx

USER bun
WORKDIR /home/bun/app
CMD ["/bin/bash"]
```

例えばBunとNodeJSが融合したような環境がつくりたければ上のようにすればよい。

こうするとBunで実行できない機能があればNodeJSのAPIが利用される。

記事は以上。