---
title: OBSでサーモンランを配信する補助ツールを作りました
published: 2021-11-03
description: OBSで現在の評価や勝敗を表示できるツールの導入方法について解説
category: Programming
tags: [Nintendo Switch]
---

# [Salmonrun-Overlay](https://github.com/tkgstrator/obs-salmonrun-overlay)

OBS で現在の評価値などを表示するためのツールです。

![](https://pbs.twimg.com/media/FDQwibdaUAAslAJ?format=jpg&name=large)

::: tip デザインについて

デザイン力は皆無なのでとあるデザインをパク...もといリスペクトして参考にしました。

勝率グラフしか表示してないんですけど、アニメーションで金イクラや赤イクラの占有率に変えてもいいかなあと思っていたり。

:::

## ファイル構成

以下のようにファイルを置きます。

```
OBS-Salmonrun-Overlay
├── assets
│   ├── stats.js
│   └── style.sass
├── config.json
├── coop.json
├── index.html
└── OBS-Salmonrun-Overlay.exe
```

### config.json

`config.json`は以下のようなフォーマットで与えられる JSON ファイルです。

```json
{
  "version": "1.13.2", // X-Product Version
  "account": [
    {
      "nsaid": null, // 現在未使用
      "nickname": "えむいーのはか",
      "iksm_session": null, // Salmonia等で事前に取得して書き込み
      "session_token": null, // Salmonia等で事前に取得して書き込み
      "clear": 0,
      "failure": 0,
      "grade_point": 0,
      "failure_counts": [0, 0, 0],
      "dead_total": 0,
      "help_total": 0,
      "team_golden_ikura_total": 0,
      "team_ikura_total": 0,
      "my_ikura_total": 0,
      "my_golden_ikura_total": 0,
      "kuma_point_total": 0,
      "job_num": 0
    }
  ]
}
```

`session_token`と`iksm_session`は Salmonia 等で取得した値を書き込んでください。nickname は識別用の名前なので自分で区別ができれば何でも良いです。

アカウントはこれらの配列なので、いくらでもサブアカウントを追加することができます。

このサブ垢機能、本家 Salmonia にもマージしたいと思っています。

## 追加機能リクエスト

というわけで、配信者向けに作成してこの OBS-Salmonrun-Overlay ですが、やろうと思えばいろいろ表示する画面を追加することができます。

- 勝敗
  - 現在は単純な勝敗のみだが、どの WAVE で負けたとかを表示することが可能
  - 直近 50 戦の勝敗
    - ○●○○○ みたいに勝敗を表示することも可能
- 金イクラ・赤イクラ
  - 金イクラ占有率、赤イクラ占有率、平均などの表示
  - 金イクラ総合、赤イクラ総合の表示（四人の値も表示可能）
- 救助数、非救助数またはその平均の表示
- クマサンポイントの表示

最大の納品数などを調べるのはちょっと手間がかかりますが、実装できます。

で、人によってはもっと機能欲しいぞっていう人がいると思うので仕事として（ここ大事）依頼していただければ表示するビューワを作成します。

その際には「こんなものをここに表示したい」とか「こういうデザインにして欲しい」などの案があるとスムーズに作業が進みます。

記事は以上。
