---
title: Burp SuiteでiOSの通信内容をキャプチャする
published: 2023-10-24
description: FiddlerがiOS向けだと利用できないのでBurp Suiteで代用します
category: Tech
tags: []
---

## [Burp Suite](https://portswigger.net/burp)

Burp Suite は Web アプリケーションのセキュリティや侵入テストに使用されてる Java アプリケーションです。

### Fiddler との比較

Fiddler も似たような機能を有するアプリケーションですが、無料の Fiddler Classic は macOS 非対応で UI などが一新された Fiddler Everywhere は月額 12 ドルもかかります。

1 年間のアップデートで買い切り$100 とかであれば良かったのですが、サブスク形式は個人的にはあまり好きではないのでできれば Fiddler Everywhere 以外の選択肢を探していました。

|    アプリケーション     | macOS  |       値段       |
| :---------------------: | :----: | :--------------: |
|     Fiddler Classic     | 非対応 |       無料       |
|   Fiddler Everywhere    |  対応  | 月額 2000 円ほど |
| Burp Suite Professional |  対応  |   67500 円ほど   |
|  Burp Suite Community   |  対応  |       無料       |

大雑把に比較するとこんな感じで、macOS に対応している Burp Suite Community がかなり魅力的に感じます。

とはいえ、Fiddler とは操作性が違うのでその辺りを慣れるために記事を書くことにしました。

## セットアップ

Burp Suite が起動したら Proxy のタブを選択し、Proxy listeners のところに 127.0.0.1:8080 の項目があると思うので Edit を押します。

Edit proxy listener が開いたら Binding のタブから Bind to address を All interfaces に変更します。

ここまでできればパソコンのローカル IP アドレスを調べて、ポート 8080 にアクセスします。

私の環境ではパソコンのローカル IP は 192.168.1.15 でしたのでアクセスするべき URL は[http://192.168.1.15:8080](http://192.168.1.15:8080)になります。

アクセスしたら右上の CA Certificate をタップしてプロファイルをダウンロードし、設定からインストールします。このあたりは詳しく書いてくれている記事があるので詳細は割愛します。

> [iOS ネイティブアプリの http 通信の内容を確認する](https://qiita.com/fnm0131/items/53298e5dd3c367b84d41)などがわかりやすいと思います
