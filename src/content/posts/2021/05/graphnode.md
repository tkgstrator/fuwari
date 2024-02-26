---
title: グラフノードを変換しよう
published: 2021-05-07
description: スプラトゥーンで利用されているグラフノードはXMLで与えられているのでこれをグラフとて利用できるように変換するための手順を解説します
category: Programming
tags: [Swift]
---

## グラフノードとは

要するにただのグラフである。以下のようなものを想像してもらえばよく、それぞれのノードはスタート地点からの距離に応じたコストを持っている。

![](https://pbs.twimg.com/media/E0vqIKKXEAYAUtx?format=png)

::: tip コストについて

今回はスタート地点からの距離をコストとしたが、より正確には「ノードを繋ぐエッジに重みがある」とする方が正しい。

そうでないと、例えばこのデータだけではコスト 8 のノードからコスト 8 のノードへ移動するときにいくらコストがかかるかをパッと計算することができない。ただし、ガチホコバトルにおいては「ゴールまでの距離」がカウントとして扱われるのでこのような表記とした。

:::

## スプラトゥーンのグラフノード

スプラトゥーンにおけるグラフノードはサーモンランなどでも使われている。サーモンランの場合はシャケが通行可能なルートをグラフノードで制御していたりする。

このグラフノードは BYAML という XML を暗号化したフォーマットで与えられており、普通のエディタでは中身を見ることができない。

ただ、そこはスーパーハカーが[復号用のプログラム](https://github.com/exelix11/TheFourthDimension)を開発してくれている。この中にある`The4Dimension.exe`を使って`BYAML、BYML、BPRM`などのデータを復号することができる。

::: tip BYAML などについて

ちなみに BYAML などの最初についている B は Binary を意味している。バイナリ化することでファイルサイズを圧縮しているのだ。

復号のために必要な知識は[Wiki](<http://mk8.tockdom.com/wiki/BYAML_(File_Format)>)にのっているので自作ライブラリをつくってみるのも良いかもしれない。ちなみにぼくは挫折しました。

:::

## 変換のための手順

必要なものは以下の通り。

- [SARC-Tool](https://github.com/aboood40091/SARC-Tool)
  - 圧縮ファイルを解凍するためのツール
  - 解凍して BYAML データを手に入れます
- [TheFourthDimension](https://github.com/exelix11/TheFourthDimension)
  - BYAML を XML に変換するツール
- [VSCode](https://azure.microsoft.com/ja-jp/products/visual-studio-code/)
  - XML を編集/閲覧するテキストエディタ
  - 好きなのを使えばいいけど、これをオススメ
  - 実際、エディタはなくても困らないけど解説のために載せておく
