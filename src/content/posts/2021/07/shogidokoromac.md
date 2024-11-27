---
title: 将棋検討ソフトをmacOSに導入する
published: 2021-07-18
description: 将棋検討ソフトはWindows用のものが多いですが、macOSでも動かせるか試してみました
category: Shogi
tags: [macOS]
---

# 将棋検討ソフト

## [将棋所 Mac](http://shogidokoro.starfree.jp/mac/index.html)

Mac 版の将棋所は ShogiGUI とは違うのでちょっと操作になれが必要でした。

### 不満点

何故か駒の解像度が異常に低いです。解像度が高い画像に差し替えてもこれなのでつらいところです。

これなら MyShogi とか将棋 GUI を使ったほうが良いのではないかとも思えてきました。

## エンジン導入方法

どこかに適当に`shogi`というフォルダを作成し、以下のようなディレクトリ構造になるようにします。

`nn.bin`, `user_book1.db`, `Yaneuraou-by-arm64`の三つのファイルはこれからダウンロードしてくるので`eval`, `book`, `engine`の三つのフォルダだけ作成しておきましょう。

```sh
shogi
└ engine
　 ├ eval
　 │ └ nn.bin
　 ├ book
　 │ └ user_book1.db
　 └ Yaneuraou-by-arm64
```

### やねうら王のダウンロード

やねうら王の M1 用ビルドが公開されていたのでそれを利用します。

ここに`Mac OSX版 M1チップ対応やねうら王`があるのでそれをダウンロードしてきます。ソースコードが公開されていないのが気になるのですが、まあそれはおいておきましょう。

ダウンロードしたら`Yaneuraou-by-arm64`みたいな名前に変えておきます。変えなくても別に困らないので変えたくない人はそのままでいいです。

### 評価関数のダウンロード

無償で公開されている評価関数はいろいろあるのですが、自分は[コンピュータ将棋データベース](https://www.qhapaq.org/shogi/kifdb/)を愛用しています。

少し古いですが`orqha1018`を使うことにしました。

ダウンロードして展開すると`nn.bin`という評価関数ファイルがあります。

### 定跡ファイル

やねうら王さんが作成した[100 テラショック定跡](https://github.com/yaneurao/YaneuraOu/releases/tag/BOOK-100T-Shock)を利用します。

もちろん、自身で学習させた定跡でも構いません。

### エンジン設定

エンジン管理から利用したい`Yaneuraou-by-arm64`を指定します。

![](https://pbs.twimg.com/media/E6hV3OLVIAE-vSI?format=jpg&name=large)

メモリが何故か 16MB しか使用してくれない設定になっているので 2048MB くらいを指定します。今回利用しているやねうら王のビルドは 32 ビット扱いなのでメモリは 2048MB までしか使えないようになっているぽいです。まあそれでもめちゃくちゃ早いのでいいとしましょう。

## M1 vs SSE42

今回の記事ではネイティブの M1 で動かしていますが Rosetta2 と呼ばれるシステムを利用して SSE42 として動作させることもできます。

他のブログや記事などで書かれている方法はほとんどがその方法です。ネイティブの方が速いに決まっているのですが、どのくらい速いか調べてみました。

設定は完全に同じにできればよかったのですが、全く同じにはできなかったことをご了承ください。

相横歩取りの指定局面をどちらも 60 秒間読ませてみることにしました。

### SSE42

![](https://pbs.twimg.com/media/E6hQblDVkAMxCjj?format=jpg&name=large)

こちらはメモリ上限がないので 4096MB、スレッド数は 8 を指定しました。

![](https://pbs.twimg.com/media/E6hQc9IVkAEgD9_?format=jpg&name=4096x4096)

60 秒間で探索した局面は約 2150 万局面でした。

### M1

![](https://pbs.twimg.com/media/E6hRNgeVIAABEGz?format=jpg&name=large)

メモリが 2048MB までしか使えないという制約がありました。スレッド数は 8 を指定。

![](https://pbs.twimg.com/media/E6hRIg8VcAA8Hto?format=jpg&name=4096x4096)

60 秒間で探索した局面は約 3570 万局面でした。なんと M1 仕様の方が 1.5 倍くらい速いという結果になりました。

これは M1 版やねうら王を使う価値が十分にあるといえるでしょう。


