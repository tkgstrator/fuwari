---
title: Salmonia3の進捗報告
published: 2021-08-31
description: ようやくSalmonia3にアプリ内課金を導入することができましたのでここまでを総括します
category: Programming
tags: [SwiftUI, Swift]
---

# Salmonia3

現在の進捗状況について説明します。

## 表示スタイルの違い

Salmonia3 ではリザルト表示スタイルを六種類サポートしています。それぞれの違いについて大雑把に解説します。

### インセット

iOS14 以降で利用できるスタイルです。

内側に丸め込まれて表示されるので画面が狭い iPhone 等では利用を推奨していません。

![](https://pbs.twimg.com/media/E-DMCoWVcAMZLjg?format=jpg&name=large)

### サイドバー

iOS14 以降で利用できるスタイルです。

グループごとに閉じることができるので、シフトあたりのバイト回数が多い場合には便利です。

![](https://pbs.twimg.com/media/E-DMCoWUUAAc2rB?format=jpg&name=large)

### デフォルト

iOS13 以降で利用できるスタイルです。

自動でふさわしいスタイルが適用されます。

![](https://pbs.twimg.com/media/E-DMCoYVQAYSZEF?format=jpg&name=large)

### グループ

iOS13 以降で利用できるスタイルです。

デフォルトと似たようなスタイルですが、ヘッダー（下図でいうとシフト情報）が固定されず全体として一つのリストのようになります。

![](https://pbs.twimg.com/media/E-DMCoWUcAImDQ7?format=jpg&name=large)

### 無印

iOS13 以降で利用できるスタイルです。

何も設定しない場合、デフォルトのスタイルはこの無印になります。

見た目はグループと似ていますが、下図のようにヘッダー部分が常に一番上に固定されます。

![](https://pbs.twimg.com/media/E-DR0-OVgAAvuve?format=jpg&name=large)

### 旧式

Salmonia1 で実装されていた横スワイプでリザルトを遡れるスタイルです。

他のスタイルに比べてリザルト選択、戻るの作業が不要なので簡単にリザルトが遡れます。

![](https://pbs.twimg.com/media/E-DR1WWVgAYkY2w?format=jpg&name=large)

## 実装中の機能

### Salmon Stats 閲覧

現在は開くと必ず TOP ページにジャンプしてしまうのですが、次期アップデートで現在ログイン中のアカウントにジャンプするように変更します。

<video controls src="https://video.twimg.com/tweet_video/E-CJmX-VEAUJNFk.mp4"></video>

既に実装済みなのでアップデートをお待ち下さい。

### Salmon Stats 取り込み

> Salmonia3 のリザルト取得が、なぜか残り 50 から一向に進みません

![](https://pbs.twimg.com/media/E9r0-o6VoAAAR1y?format=jpg&name=large)

Salmon Stats のリザルト取り込みは正当性を担保していないので何らかの理由でデータを受け取りミスを起こす場合がある。

取り込み終了判定は「取り込んだ件数=リザルト件数」なので、取り込みミスを起こすとこのようにいつまでも終わらなくなってアプリを終了するしかなくなってしまう。

原因はわかっているのだが、対処するための上手いコードの書き方がわからないので対応できていない。同様の問題は単なるリザルト取得でも発生する可能性があるが、こちらはイカリング 2 のサーバが Salmon Stats よりも遥かに強いため取得漏れをすることは殆どない（取得中に任天堂のサーバがメンテナンスにでもならない限りは）。

対応はしたいのだが、すぐにできるかは微妙。

### チャート機能

Salmonia1 ではシフトごとの平均納品数とかのグラフが見れたのですが、Salmonia3 では実装されていません。

やる気自体はあるのですが、グラフを簡単に表示するための満足するライブラリがありません。自分でつくろうとしたら予想以上にめんどくさかったので実装を見送っています。

やるとしたら ChartView か Charts かなあという気がしています。

#### [ChartView](https://github.com/AppPear/ChartView)

Apple Watch 向けなのか、iOS デバイスでの表示がやたらとダサい。

![](https://user-images.githubusercontent.com/2826764/131211985-f77464d6-7fd8-429d-9e77-9f9bc7424d32.gif)

たとえばこれなんかは、フルスクリーン表示できたら良いのに何故か中央にポツンとある、ダサい。

#### [SwiftUICharts](https://github.com/willdale/SwiftUICharts)

フルスクリーン対応なのは良いけど、ダサい。

![](https://raw.githubusercontent.com/willdale/SwiftUICharts/main/Resources/images/PieCharts/PieChart.png)

#### [Charts](https://github.com/danielgindi/Charts)

高機能だが SwiftUI や Flat Design に対応できておらず、見た目がダサい。

![](https://camo.githubusercontent.com/f7c66f238dd089717173e0e88e18293f94493cd24b0a53e69f199a9967e97684/68747470733a2f2f7261772e6769746875622e636f6d2f5068696c4a61792f4d50416e64726f696443686172742f6d61737465722f73637265656e73686f74732f6c696e655f63686172745f6772616469656e742e706e67)

#### [SwiftSunburstDiagram](https://github.com/lludo/SwiftSunburstDiagram)

見た目は悪くないが Pie Chart しか表示できない。

![](https://github.com/lludo/SwiftSunburstDiagram/raw/master/Docs/diagram-with-text.png)

### シフトごとのシャケレート

Salmonia2 では実装されていたが、コードがダサかったので書き直そうとして放置してる。

やろうと思えばいつでも実装できます。

### オオモノ討伐率

Salmonia2 では実装されていたが、コードがダサかったので書き直そうとして放置してる。

やろうと思えばいつでも実装できます。

### 最高記録から該当リザルトへのジャンプ

Salmonia2 では実装されていたが、コードがダサかったので書き直そうとして放置してる。

やろうと思えばいつでも実装できます。

### ランダム編成のコンプ所要回数

ちょっとめんどくさいけど実装は可能。

### ゲーミングスタイル

Salmonia2 では実装されていた機能。

面白そうなので実装しようと考えている、優先度は高め。

### 運試し機能

実装はできているので表示するだけ。

### Salmon Stats の記録閲覧

Salmonia とかでは Salmon Stats のシフト記録が見れたのでそれの閲覧機能。

![](https://pbs.twimg.com/media/E-Dkm-gUcAMvzf6?format=jpg&name=large)

現状だと、いちいち当該ページにジャンプしなければならずめんどくさい。

![](https://pbs.twimg.com/media/E9_ihhqVgAAUmWv?format=jpg&name=medium)

を改良する感じでつくりたいんだけど、良いデザイン案がないのが現状。デザイン案さえくれたらやります。

- イベント名・潮位名
  - 潮位名は図でも代用可なので必須ではない
- 記録
  - 自分の最高記録
  - 自分の平均記録
  - Salmon Stats の記録
- イベント詳細
  - 発生した回数、確率

ユーザビリティの観点からこれらがタブやスイッチなどで切り替えせずに見れること。ただ、潮位タブはあってもいいかも、という気がしないでもない。

### ログ機能

ライブラリアップデート時にオフにしてしまったので復活させたい。

### エラー確認機能

エラーがひと目で分かるように直したい所存。

### リザルト詳細

初期リリースのまま放置してしまったので直したい。

![](https://pbs.twimg.com/media/E-DnGRVVgAYyvYR?format=jpg&name=large)

### Picker

SwiftUI の Picker がバグっているのでスタイルを強制的に変更しているのだけれど ActionSheet でいいのではないか説があるので切り替え予定。

### ST 機能

機能としては簡単に実装できるので、ブラウザでなくネイティブアプリであれば音を鳴らすのも簡単。
