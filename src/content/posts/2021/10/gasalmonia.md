---
title: GitHub ActionsでSalmoniaを実行してみた
published: 2021-10-01
description: SalmoniaをGASで実行することができるかどうか
category: Programming
tags: [Python, GitHub]
---

# GitHub Actions

まず、Github Actions を利用して Salmonia を定期実行することが GitHub の利用規約に抵触しないかを調べます。

::: tip 利用規約

GitHub アクションでは、カスタムソフトウェア開発のライフサイクルにわたるワークフローを GitHub リポジトリに直接作成することができます。 Actions は、使用量に基づいて課金されます。 Actions のドキュメントには、計算量やストレージ容量 (アカウントのプランによって異なる)、および Actions の使用分数の監視方法や利用限度の設定方法などの詳細情報が記載されています

:::

- 法律違反、またはそれ以外で当社の利用規約またはコミュニティガイドラインに反しているコンテンツまたは行為
- クリプトマイニング
- サーバーレスコンピューティング
- GitHub ユーザまたは GitHub サービスを危険にさらす行為
- GitHub Actions が使用されるリポジトリに関連するソフトウェアプロジェクトの製造、テスト、デプロイ、公開に関連しないその他の行為。 つまり、GitHub Actions を使用して常識的に不適切と判断できることはしないこと

少なくともクリプトマイニングではないし、サーバーレスコンピューティングでもなく、GitHub ユーザやサービスを危険に晒す行為でもないです。

> GitHub Actions が使用されるリポジトリに関連するソフトウェアプロジェクトの製造、テスト、デプロイ、公開に関連しないその他の行為。 つまり、GitHub Actions を使用して常識的に不適切と判断できることはしないこと

このあたりがちょっと気になるところで、要するにレポジトリの内容と無関係なことをするなということになります。

なので単にプログラムを動かしてリザルトをアップロードするだけでなくデータを保存してレポジトリとして建前上意味があるようにしようと思います。

データを保存してまあそれを表示するようなリザルトビューワとしての仕組みもつくればこの利用規約には触れないでしょう。

::: warning とはいっても

リザルトビューワをつくるのはめんどくさいので、最初は Python コードでいいや

:::



## [Salmonia for GitHub Actions](https://github.com/tkgstrator/Salmonia-GA)

というわけでとりあえずリザルトを取得する Python コードを書いてみました。

### アカウントの作成

まず[GitHub アカウント](https://github.com/join)を作成する必要があります。

特に難しいこともないのでちゃちゃっとつくります。

### レポジトリのフォーク

[Salmonia for GitHub Actions](https://github.com/tkgstrator/Salmonia-GA)をフォークします。

![](https://pbs.twimg.com/media/FAi-4fyUUAU7Bfn?format=jpg&name=4096x4096)

リンクを開いた先の右上の`Fork`を押せば自分のレポジトリとして作成されます。

### 環境変数の設定

このままだと大量のエラーを吐いてしまうので、自分のレポジトリ`https://github.com/{作成したアカウントのユーザ名}/Salmonia-GA/settings`を開きます。

`Settings`を押して、その中の`Secrets`を開きます。

![](https://pbs.twimg.com/media/FAi_B1-VEAATBpL?format=jpg&name=large)

で、最初は何も設定されていないと思うのですが、次の五つの環境変数を設定します。

![](https://pbs.twimg.com/media/FAi_HhcVIA8yMvK?format=jpg&name=4096x4096)

- `API_TOKEN`
  - Salmon Stats の api-token です
  - [この URL](https://salmon-stats.yuki.games/settings)から確認できます
- `IKSM_SESSION`
  - SplatNet2 からデータを取得するための iksm_session です
  - [Salmonia](https://github.com/tkgstrator/Salmonia)などで事前に取得しておいてください
- `EMAIL`
  - GitHub に登録したメールアドレスです
- `USERNAME`
  - GitHub に登録したアカウント名です
- `LATEST_JOB_NUM`
  - リザルト ID を指定します
  - 0 を設定しておけば良いです

::: warning ENVIRONMENT について

開発者用の環境変数なので、普通は設定しなくて良いです。

:::

#### 設定方法

![](https://pbs.twimg.com/media/FAjA7uOUUAE4uwb?format=jpg&name=large)

`New repository secret`をクリックします。

![](https://pbs.twimg.com/media/FAjA-7tVUAYX7X6?format=jpg&name=large)

このような画面が開くので、上を参考に五つのパラメータを設定します。

![](https://pbs.twimg.com/media/FAjBYkhVcAI2FqC?format=jpg&name=large)

このように入力し、`Add secret`で環境変数を追加します。

この手順を全てのパラメータに対して行います。

これですべての手順は終了です。

## まとめ

あとは勝手に十分おきにプログラムがイカリング 2 へアクセスして新規リザルトがあるかどうかを確認し、あればリザルトを取得して Salmon Stats へアップロードしてくれます。

他に何もすることはないです。

また、現在はちゃんと実装していませんが[Vite](https://vitejs.dev/)にも対応しているので`yarn vite`を実行すればウェブサイトが立ち上がります。

JSON を読み込んで簡易的なリザルトビューワとして使えるので、将来的に Netlify と連携して色々できたらいいなと思っています。

記事は以上。


