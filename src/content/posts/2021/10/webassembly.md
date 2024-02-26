---
title: WebAssemblyでブラウザでアセンブラを動かそう
published: 2021-10-13
description: ブラウザで実行できるアセンブラの作成方法について考えてみるの巻
category: Programming
tags: [Swift, Javascript]
---

# WebAssembly

ブラウザから機械語であるアセンブリを実行するようにする謎の技術。

「ブラウザは Javascript が実行できるからアセンブリを実行する意味ある？」と思うかも知れないが、大いに意味はある。というのも、Javascript は動的型付け言語であるために実行時解析に時間がかかり、動作としては非常に遅い。

しかし、それも今までは気にならなかった。何故ならそんな重い処理をブラウザで実行するような場面がそうそうなかったからだ。

ところが最近は複雑なアニメーションやら WebGL やらでいろいろと思い処理を実行しなければならない場面が増えてきた。

## asm.js

asm.js とは Javasciprt のコードの一部を事前にコンパイルすることで機械語として実行するための仕組み。

機械語として実行するので当然早いが、ファイルサイズが大きくなるなどの潜在的な問題を抱えていた。

じゃあもう「最初から C 言語などで書いたコードをアセンブラにして、そいつをブラウザで実行すればええやんけ」というのが WebAssembly の始まりである。

## Swift+ WebAssembly

うちは Mac しかないので折角なので Swift をブラウザで実行することにした。

### 環境構築

`carton`というツールをインストールする。M1 Mac でもインストール可能なので安心して欲しい。

`brew install swiftwasm/tap/carton`

今回は適当に`Hello, world!`を出力するプログラムを書いてみることにする。

```sh
mkdir helloworld
cd helloworld
carton init --template tokamak
```
