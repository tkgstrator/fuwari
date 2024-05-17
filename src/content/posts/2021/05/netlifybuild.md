---
title: GitHub ActionsでNetlifyのビルド時間を浮かせよう
published: 2021-05-06
description: Netlifyは便利なのですが、ビルド時間が一ヶ月で300分しかないのが問題ですなので、それをGitHub Actionsで解決しましょう
category: Programming
tags: []
---

## Netlify の最大の問題点

Netlify は GitHub にプッシュされた内容を自動でビルドして更新してくれるというスグレモノではあるものの、無料枠が 300 分しかなくそれ以上のビルドをすると料金がかかってしまう仕組みになっている。

単なるウェブサイトなら気にもならないのだが、本ページのようなブログだと誤字修正などで頻繁にプッシュするため小さなビルド時間も積み重なってかなり食ってしまう。

現時点でも 58/300 を使い切ってしまっており、このままの更新ペースを維持した場合とても無料枠に収まりきりそうにないのである。

## GitHub Actions を使う

その点、GitHub Actions であればパブリックなレポジトリに関してはビルド制限がまったくないのでこれを利用する。

::: tip うちのブログは

うちのブログは Vssue を利用しているためにブログのレポジトリにプライベートキーが載っていたりする。

そのため公開レポジトリにはできないのだが、それでも GitHub Actions なら 2000 分のビルドクレジットがあるので Netlify の実に 6 倍以上である。当分、ビルド時間に関して心配は要らなさそうだ。

:::

## 実装してみる

[Netlify へのデプロイをビルド時間 0 で行うための GitHub Actions](https://qiita.com/nwtgck/items/e9a355c2ccb03d8e8eb0)でキーの取得から設定まで載っているので利用させていただきましょう。

```yml
// キャッシュ無効
name: Netlify

on:
  push:
  pull_request:
    types: [opened, synchronize]

jobs:
  build:
    runs-on: ubuntu-18.04

    steps:
      - uses: actions/checkout@v2

      - uses: actions/setup-node@v2
        with:
          node-version: "14"

      - run: yarn install
      - run: yarn build

      - run: npx netlify-cli deploy --prod --dir=./blog/.vuepress/dist
        env:
          NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
          NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
```

せっかくなので最新の Node.js を利用するようにしたのと、Netlify にデプロイするときにプロダクションとして扱うようにしました。

これで、GitHub にプッシュするだけで自動的にビルドが行われ、ビルドされたデータが Netlify に送られて更新されるというわけです。

::: warning Netlify の設定

当たり前だが、Netlify からデプロイ時のビルドをしないように変更しておこう。

そうでないと二回ビルドされてしまって意味がない。

:::

で、これでもいいのですが、どうせならキャッシュを使って GitHub Actions のビルド時間も減らします。

```yml
// キャッシュ有効化
name: Netlify

on:
  push:
  pull_request:
    types: [opened, synchronize]

jobs:
  build:
    runs-on: ubuntu-18.04

    steps:
      - uses: actions/checkout@v2

      - uses: actions/setup-node@v2
        with:
          node-version: "14"

      - name: Get yarn cache directory path
        id: yarn-cache-dir-path
        run: echo "::set-output name=dir::$(yarn cache dir)"

      - uses: actions/cache@v2
        id: yarn-cache # use this to check for `cache-hit` (`steps.yarn-cache.outputs.cache-hit != 'true'`)
        with:
          path: ${{ steps.yarn-cache-dir-path.outputs.dir }}
          key: ${{ runner.os }}-yarn-${{ hashFiles('**/yarn.lock') }}
          restore-keys: |
            ${{ runner.os }}-yarn-

      - run: yarn install
      - run: yarn build

      - run: npx netlify-cli deploy --prod --dir=./blog/.vuepress/dist
        env:
          NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
          NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
```

初回のみ必ずキャッシュがミスヒットするので余計に時間がかかりますが、二回目以降は速くなるはずです。

|                               | Using Cache | Without Cache |
| :---------------------------: | :---------: | :-----------: |
|          Set up job           |     4s      |      3s       |
|    Run actions/checkout@v2    |     6s      |      4s       |
|   Run actions/setup-node@v2   |     1s      |      1s       |
| Get yarn cache directory path |     2s      |       -       |
|     Run actions/cache@v2      |     1s      |       -       |
|       Run yarn install        |     34s     |      28s      |
|        Run yarn build         |     66s     |      65s      |
|  Run npx netlify-cli deploy   |     62s     |      57s      |
|   Post Run actions/cache@v2   |     9s      |      0s       |
| Post Run actions/checkout@v2  |     0s      |       -       |
|         Complete job          |     0s      |      0s       |
|             Total             |    200s     |     158s      |

一回目をやった感じだと 40 秒くらい遅い結果に。果たして二回目は？

|                               | Using Cache | Using Cache | Without Cache |
| :---------------------------: | :---------: | :---------: | :-----------: |
|          Set up job           |     4s      |     5s      |      3s       |
|    Run actions/checkout@v2    |     6s      |     7s      |      4s       |
|   Run actions/setup-node@v2   |     1s      |     0s      |      1s       |
| Get yarn cache directory path |     2s      |     4s      |       -       |
|     Run actions/cache@v2      |     1s      |     2s      |       -       |
|       Run yarn install        |     34s     |     11s     |      28s      |
|        Run yarn build         |     66s     |     65s     |      65s      |
|  Run npx netlify-cli deploy   |     62s     |     59s     |      57s      |
|   Post Run actions/cache@v2   |     9s      |     2s      |      0s       |
| Post Run actions/checkout@v2  |     0s      |     1s      |       -       |
|         Complete job          |     0s      |     0s      |      0s       |
|             Total             |    200s     |    156s     |     158s      |

思ったよりも速くならなかった！！！

まあでも三分以下でビルドできるということは一ヶ月に 600 回はブログを更新できるということです。一日 20 回ペースでプッシュしなければ大丈夫なので、まあ多分大丈夫でしょう。

`yarn`ではなく`node_modules`自体をキャッシュしたほうが高速化できるそう（`yarn install`が一秒で終わるとかなんとか）なのですが、まあそんなに変わらないので今回はパスということで。

記事は以上。


