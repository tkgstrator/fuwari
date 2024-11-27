---
title: NestJSをNodeJSの代わりにBunで実行する 
published: 2024-02-15
description: NestJSをBunで動かすと速いんですかという疑問に答える
category: Programming
tags: [NestJS, NodeJS, Bun]
---

## NestJS

Bunって個人的には勝手にnpmやyarnの代替となるものだというイメージだったのですが、NodeJSの代わりにもなるそうです。

で、[NodeJSフレームワークのNestJSをBunで動かしてみた](https://dev.to/mourishitz/running-nestjs-server-with-bun-4cdl)という記事を見たのでそれを参考に本当に早くなるのか実験してみたいと思います。

記事の内容ではNodeJSだと4246回しか処理できなかったけれど、Bunだと開発ビルドで6661回処理、本番ビルドで16130回処理できて高速っていう結論でしたが、果たして本当にそんなに速いんでしょうか？

## テスト環境

- macOS Sonoma 14.1.1
- Apple M1 Ultra
- yarn 4.1.0
- bun 1.0.26
- NodeJS 20.11.0

パソコンはそこそこいいものを利用しましたが、別の環境でもチェックしてみたいと思います。

コマンドは以下のものが利用されていたので、全く同じものを使ってみます。

```zsh
# スレッド数12、コネクション数400で30秒間でいくつリクエストを処理できるか
wrk -t12 -c400 -d30s http://localhost:3000
```

プロジェクト自体は初期設定のものを利用します。またビルドは開発のものと本番のものを両方使います。

### Express

開発環境`yarn start:dev`で実行した環境についてのテスト結果。

```zsh
Running 30s test @ http://localhost:3000
  12 threads and 400 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    37.55ms  115.30ms   1.99s    98.12%
    Req/Sec     1.33k   139.03     1.87k    88.61%
  477476 requests in 30.04s, 108.83MB read
  Socket errors: connect 0, read 1310, write 5, timeout 78
Requests/sec:  15894.94
Transfer/sec:      3.62MB
```

開発環境`yarn start:prod`で実行した環境についてのテスト結果。

```zsh
Running 30s test @ http://localhost:3000
  12 threads and 400 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    37.91ms  112.02ms   1.99s    98.33%
    Req/Sec     1.24k   133.03     2.07k    89.14%
  445840 requests in 30.05s, 101.62MB read
  Socket errors: connect 0, read 1174, write 5, timeout 95
Requests/sec:  14835.61
Transfer/sec:      3.38MB
```

### Fastify

[Fastify](https://github.com/fastify/fastify)はExpressより速いぞっていうことなので実験してみました。

導入方法については[こちら](https://docs.nestjs.com/techniques/performance)をどうぞ。

#### `yarn start:dev`

こちらは`yarn start:dev`の実行結果です。

ただFastifyAdapterを使っただけなのに3倍以上性能が上がっています。タイムアウト数も0なので特別な理由がない限りはExpressからFastifyに乗り換えたほうが良いでしょう。導入自体も簡単ですし。

```zsh
Running 30s test @ http://localhost:3000
  12 threads and 400 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    10.91ms   34.28ms 841.58ms   99.01%
    Req/Sec     4.10k   356.19     6.90k    90.22%
  1468671 requests in 30.02s, 247.91MB read
  Socket errors: connect 0, read 1147, write 0, timeout 0
Requests/sec:  48921.42
Transfer/sec:      8.26MB
```

#### `yarn start:prod`

```zsh
Running 30s test @ http://localhost:3000
  12 threads and 400 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    10.70ms   35.38ms 861.32ms   99.07%
    Req/Sec     4.21k   579.21    27.23k    98.50%
  1509004 requests in 30.10s, 254.72MB read
  Socket errors: connect 0, read 1050, write 1, timeout 0
Requests/sec:  50125.73
Transfer/sec:      8.46MB
```

こちらはほんの僅かですがリクエスト処理数は一部改善しました。

Fastifyの公式ドキュメントにはi7 4GHzのマシンで77,193回リクエストを処理できたと書いているのでそちらも実際に試してみました。

```zsh
autocannon -c 100 -d 40 -p 10 localhost:3000
Running 40s test @ http://localhost:3000
100 connections with 10 pipelining factor

┌─────────┬──────┬──────┬───────┬───────┬──────────┬─────────┬────────┐
│ Stat    │ 2.5% │ 50%  │ 97.5% │ 99%   │ Avg      │ Stdev   │ Max    │
├─────────┼──────┼──────┼───────┼───────┼──────────┼─────────┼────────┤
│ Latency │ 7 ms │ 8 ms │ 17 ms │ 18 ms │ 10.88 ms │ 4.71 ms │ 340 ms │
└─────────┴──────┴──────┴───────┴───────┴──────────┴─────────┴────────┘
┌───────────┬─────────┬─────────┬─────────┬─────────┬─────────┬──────────┬─────────┐
│ Stat      │ 1%      │ 2.5%    │ 50%     │ 97.5%   │ Avg     │ Stdev    │ Min     │
├───────────┼─────────┼─────────┼─────────┼─────────┼─────────┼──────────┼─────────┤
│ Req/Sec   │ 80,063  │ 80,063  │ 88,575  │ 91,007  │ 87,856  │ 2,853.89 │ 80,057  │
├───────────┼─────────┼─────────┼─────────┼─────────┼─────────┼──────────┼─────────┤
│ Bytes/Sec │ 14.2 MB │ 14.2 MB │ 15.7 MB │ 16.1 MB │ 15.6 MB │ 505 kB   │ 14.2 MB │
└───────────┴─────────┴─────────┴─────────┴─────────┴───────────┴──────────┴────────┘
```

すると結果は87,856回となり、パソコンのスペック差を考えると同じような感じになりました。

`awk`の場合と同じようにコネクション数400、パイプライン12、計測時間30で実行すると以下のような感じになりました。

```zsh
$ autocannon -c 400 -d 30 -p 12 localhost:3000
Running 30s test @ http://localhost:3000
400 connections with 12 pipelining factor

┌─────────┬───────┬───────┬────────┬────────┬──────────┬───────────┬─────────┐
│ Stat    │ 2.5%  │ 50%   │ 97.5%  │ 99%    │ Avg      │ Stdev     │ Max     │
├─────────┼───────┼───────┼────────┼────────┼──────────┼───────────┼─────────┤
│ Latency │ 29 ms │ 47 ms │ 166 ms │ 205 ms │ 67.29 ms │ 129.89 ms │ 6033 ms │
└─────────┴───────┴───────┴────────┴────────┴──────────┴───────────┴─────────┘
┌───────────┬─────────┬─────────┬─────────┬─────────┬───────────┬──────────┬────────┐
│ Stat      │ 1%      │ 2.5%    │ 50%     │ 97.5%   │ Avg       │ Stdev    │ Min    │
├───────────┼─────────┼─────────┼─────────┼─────────┼───────────┼──────────┼────────┤
│ Req/Sec   │ 68,095  │ 68,095  │ 80,767  │ 84,415  │ 79,833.61 │ 3,409.32 │ 68,052 │
├───────────┼─────────┼─────────┼─────────┼─────────┼───────────┼──────────┼────────┤
│ Bytes/Sec │ 12.1 MB │ 12.1 MB │ 14.3 MB │ 14.9 MB │ 14.1 MB   │ 604 kB   │ 12 MB  │
└───────────┴─────────┴─────────┴─────────┴─────────┴───────────┴──────────┴────────┘
```

負荷が増えた結果、目に見えて遅延(Latency)が大きくなっていることがわかります。

## Bun

超高速らしいので使ってみます。

あまり本旨とは関係ないのですが`bun install`が速すぎてビビりました。

これだけで使う価値はあるかもしれません。

### Express

まずは開発ビルドの結果がこちら。コマンドは`bun start:dev`ではなく`bun start`を利用しましょう。

#### `bun start`

```zsh
Running 30s test @ http://localhost:3000
  12 threads and 400 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    37.54ms  111.75ms   1.99s    98.28%
    Req/Sec     1.28k   143.51     2.38k    88.58%
  457783 requests in 30.04s, 104.34MB read
  Socket errors: connect 0, read 1229, write 0, timeout 83
Requests/sec:  15237.20
Transfer/sec:      3.47MB
```

NodeJSが15894回だったのでほぼ変わらず。

#### `bun run dist/main.js`

`bun run build`でビルドを実行してから立ち上げます。

```zsh
Running 30s test @ http://localhost:3000
  12 threads and 400 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency    11.04ms    2.43ms  79.36ms   98.03%
    Req/Sec     3.02k   219.66     4.19k    94.75%
  1082071 requests in 30.03s, 198.13MB read
  Socket errors: connect 0, read 405, write 0, timeout 0
Requests/sec:  36038.99
Transfer/sec:      6.60MB
```

急に倍くらい速くなりました。

> `bun run start:prod`を実行すると`bun run dist/main.js`ではなく`node dist/main`が実行されて結局NodeJSで動いて遅くなるので注意してください。

### Fastify

となるとFastifyで実行したときの結果が気になるというものです。

#### `bun start`

```zsh
Running 30s test @ http://localhost:3000
  12 threads and 400 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     8.95ms   27.81ms 765.05ms   99.14%
    Req/Sec     4.85k   766.18    32.11k    96.70%
  1739951 requests in 30.10s, 293.70MB read
  Socket errors: connect 0, read 1128, write 1, timeout 0
Requests/sec:  57796.36
Transfer/sec:      9.76MB
```

先程までの劇的な変化はありませんが単純にNodeJS+Fastifyを利用したものよりも10%ほど高速化できています。

これで本番ビルドでやるともっと速くなるのでしょうか？

#### `bun run dist/main.js`

```zsh
Running 30s test @ http://localhost:3000
  12 threads and 400 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     6.82ms    1.48ms  43.20ms   97.11%
    Req/Sec     4.89k   340.22     6.42k    95.25%
  1753199 requests in 30.03s, 215.69MB read
  Socket errors: connect 0, read 394, write 0, timeout 0
Requests/sec:  58387.30
Transfer/sec:      7.18MB
```

更に速く！！とはならず、ほぼ横ばいとなりました。

このマシンのスペックだとTypeScriptでAPIを立てるとこのあたりが限界なのかもしれません。

最後に`autocannon`の実行結果を載せます。

```zsh
Running 40s test @ http://localhost:3000
100 connections with 10 pipelining factor

┌─────────┬──────┬──────┬───────┬───────┬─────────┬─────────┬───────┐
│ Stat    │ 2.5% │ 50%  │ 97.5% │ 99%   │ Avg     │ Stdev   │ Max   │
├─────────┼──────┼──────┼───────┼───────┼─────────┼─────────┼───────┤
│ Latency │ 4 ms │ 9 ms │ 12 ms │ 13 ms │ 8.94 ms │ 2.98 ms │ 99 ms │
└─────────┴──────┴──────┴───────┴───────┴─────────┴─────────┴───────┘
┌───────────┬─────────┬─────────┬─────────┬─────────┬───────────┬──────────┬─────────┐
│ Stat      │ 1%      │ 2.5%    │ 50%     │ 97.5%   │ Avg       │ Stdev    │ Min     │
├───────────┼─────────┼─────────┼─────────┼─────────┼───────────┼──────────┼─────────┤
│ Req/Sec   │ 93,759  │ 93,759  │ 106,687 │ 110,399 │ 106,009.6 │ 3,690.75 │ 93,734  │
├───────────┼─────────┼─────────┼─────────┼─────────┼───────────┼──────────┼─────────┤
│ Bytes/Sec │ 12.1 MB │ 12.1 MB │ 13.8 MB │ 14.2 MB │ 13.7 MB   │ 476 kB   │ 12.1 MB │
└───────────┴─────────┴─────────┴─────────┴─────────┴───────────┴──────────┴─────────┘
```

結果としては大台の一秒での十万リクエスト処理を超えることができました。

うーん、たしかにこれは速いかもしれない......

### おまけ

C/C++と並んで最速と名高いRustでAPIを立てて実行してみました。

```zsh
brew install rust
git clone https://github.com/rwf2/Rocket
cd Rocket
git checkout v0.5
cd examples/hello
cargo build -r # リリースビルド
cargo run -r # リリースビルド実行
```

とりあえず環境からなかったのでRustをインストールするところから始めました。

Rustは初心者なので全く同じコードは書けなかったのでとりあえず適当に一番軽そうな単に`Hi`とだけ返すAPIを立ててベンチマークを実行しました。

```zsh
Running 30s test @ http://localhost:8000
  12 threads and 400 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     3.59ms  500.63us  39.39ms   99.33%
    Req/Sec     9.19k   429.89    10.33k    97.25%
  3291593 requests in 30.02s, 743.97MB read
  Socket errors: connect 0, read 226, write 31, timeout 0
Requests/sec: 109644.02
Transfer/sec:     24.78MB
```

ソケットエラーこそ発生しているものの、驚くべき速さを見せてくれました。

やはり事前にコンパイルしておける言語は処理速度では圧倒的だと言えますね。

```zsh
Running 40s test @ http://localhost:8000
100 connections with 10 pipelining factor

┌─────────┬──────┬──────┬───────┬──────┬─────────┬─────────┬────────┐
│ Stat    │ 2.5% │ 50%  │ 97.5% │ 99%  │ Avg     │ Stdev   │ Max    │
├─────────┼──────┼──────┼───────┼──────┼─────────┼─────────┼────────┤
│ Latency │ 5 ms │ 6 ms │ 7 ms  │ 9 ms │ 6.09 ms │ 1.36 ms │ 107 ms │
└─────────┴──────┴──────┴───────┴──────┴─────────┴─────────┴────────┘
┌───────────┬─────────┬─────────┬─────────┬─────────┬────────────┬─────────┬─────────┐
│ Stat      │ 1%      │ 2.5%    │ 50%     │ 97.5%   │ Avg        │ Stdev   │ Min     │
├───────────┼─────────┼─────────┼─────────┼─────────┼────────────┼─────────┼─────────┤
│ Req/Sec   │ 138,879 │ 138,879 │ 155,903 │ 157,951 │ 154,771.21 │ 4,017.2 │ 138,810 │
├───────────┼─────────┼─────────┼─────────┼─────────┼────────────┼─────────┼─────────┤
│ Bytes/Sec │ 32.9 MB │ 32.9 MB │ 36.9 MB │ 37.4 MB │ 36.7 MB    │ 955 kB  │ 32.9 MB │
└───────────┴─────────┴─────────┴─────────┴─────────┴───────────┴──────────┴────────┘
```

負荷を軽くしたバージョンの`autocannon`でもこのような結果となりました。平均処理数は15万となり、圧倒的な数値です。

## まとめ

ざっくりと本番用のビルドでのスレッド数12、コネクション数400での一秒間の処理数を比較すると以下のようになります。

| Framework | Express | Fastify | Rocket | 
| --------- | ------- | ------- | ------ | 
| NodeJS    | 14835   | 50125   | -      | 
| Bun       | 36038   | 58387   | -      | 
| Rust      | -       | -       | 109644 | 

こう見るとFastifyを使っているなら速度の面だけで言えばNodeJSからBunへ移行するメリットはそこまでないように思います。

ただ、実際にデプロイするとなったときにNodeJSであればdistrolessなどでビルドしようとするとマルチステージングビルドを意識してDockerfileを編集しなければいけないですが、Bunであれば何も考えずに[oven/bun](https://hub.docker.com/r/oven/bun/tags)が使えるのがメリットですね。

移行コストにはよるのですが、ワンチャン切り替えても良さそうです。ビルドが楽ならそっちのほうが良いですし。

しかし、速度面ではRustがぶっちぎりなのでめちゃくちゃ速度が要求される場面では選択しても良さそうです。

今回は結構スペックがあるマシンでチェックしたのですが個人用のAPIサーバーはN100で動いているのでそちらでベンチマークを取ってみても面白いかもしれません。

記事は以上。