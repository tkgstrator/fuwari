---
title: GAS版Salmoniaを複数アカウント対応した
published: 2021-02-04
category: Nintendo
tags: [Salmonia3+]
---

## Android 利用者向けである

Salmonia というよりは、単なるリザルト（JSON）アップローダなのだが、まあそこには目をつむってほしい。

Android 版の Salmonia はリザルトアップロード機能しかなく、iOS 版のようにデータ分析などができない。よって、本記事は Android を所持している方向けで、そういう人はパソコンがあるなら絶対に導入したほうがいいです。

iPhone や iPad があるならこれを導入した上で Salmonia2 を使えば、より便利にサーモンランを楽しむことができるでしょう。

### Google Apps Script の設定など

GAS のアカウント開設や、設定の大まかな方法は以前と変わっていません。

また、iksm_session の取得には PC 版の Salmonia が必須です。

最近コードを大幅に変えて安定性を向上させたので、ぜひともそっちを使ってみてください。

[Windows 版 Salmonia 1.11.0](https://github.com/tkgstrator/Salmonia/releases/tag/v1.11.0)

::: tip 最新のバージョン

古いバージョンの Salmonia を使っていると正しく iksm_session が取得できないので気をつけてください。

:::

え、じゃあ何が変わったんだとなるわけですが、複数アカウントに対応したのが今回の一番の目玉です。

### サブ垢対応のコード

[Salmonia for GAS](https://gist.github.com/tkgstrator/3f190327b114ec6ce9d7405559e600fe)

### プロパティについて

プロパティは JSON 形式にのみ対応しています。

JSON 形式と言われてもよくわからないと思うので、テンプレートを置いておくのでそのとおりに書いてみてください。

```
IKSM_SESSION => ["IKSM_SESSION_1", "IKSM_SESSION_2"]
API_TOKEN => API_TOKEN
JOB_NUM => ["0", "0"]
```

`IKSM_SESSION`と`JOB_NUM`だけは読み込みの都合上、ダブルクオーテーションで囲む必要があります。`API_TOKEN`だけはそのままであることに注意してください。

![](https://pbs.twimg.com/media/EtYPFKAVkAEjv4s?format=png)

こんな感じで書き込めたら今まで通り指定したトリガーで実行されます。

![](https://pbs.twimg.com/media/EtYQDKaUcAAPV-a?format=png)

こんな感じでどんどんリザルトを自動取得してくれます。実はアップロードが正しくできているかは未確認なのだが、多分大丈夫でしょう（ヨシ

記事は以上。
