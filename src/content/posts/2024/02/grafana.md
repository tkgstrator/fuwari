---
title: Grafana+PrometheusでDockerの状態をウェブから確認しよう 
published: 2024-02-11
description: Dockerが現在どんな状態なのか、ブラウザから見るための方法 
category: Tech
tags: [Ubuntu, Docker, Cloudflare, Grafana, cAdvisor, Prometheus]
---

## 背景

うちのパソコン、たまに負荷をかけると勝手に再起動してしまう問題がありました。

再起動しても`docker-compose.yaml`で`restart: always`を設定しておけばDockerのサービスが走った段階で勝手にコンテナが立ち上がってくれるのですが、どうせなら現在どんな状態にあるのかもウェブから見れたら便利だなと思った次第です。

まあDocker自体がコケたらウェブサービスもコケるので意味があるのかないのかは微妙なところなのですが、死活監視というのは結構楽しそうでCloudflareにも似たような機能があるっぽいのですがnxapiでも利用されているGrafanaを利用してみることにしました。

### Grafana

[Grafana](https://github.com/grafana/grafana)はサーバーのデータのビジュアライズをしてくれるフレームワークです。

クラウドのサービスも展開しているのですが、小規模であればオンプレでやってしまっても良いでしょう。Dockerのイメージも公開されているのでそれを利用します。

![](https://miro.medium.com/v2/resize:fit:2000/format:webp/1*tLaFWxgkVNfYbN3NTKQo-w.gif)

データの流れとしてはこんな感じで、直接Dockerの様子を覗きにいくのはcAdvisorです。

ただしcAdvisor自体はビジュアライズ面がそこまで強力ではないので、Grafanaを利用しようわけですね。

## [grafana-docker-resource-monitor](https://github.com/tkgstrator/grafana-docker-resource-monitor)

めんどくさかったので全部Dockerで動くようにしました。

Cloudflare Tunnelは必須ではありません。

参考にしたページは[Docker Container Monitoring with cAdvisor, Prometheus, and Grafana using Docker Compose](https://medium.com/@sohammohite/docker-container-monitoring-with-cadvisor-prometheus-and-grafana-using-docker-compose-b47ec78efbc)で、ファイルもだいたい同じ感じですが不要なポートはDockerから外に出さないようにしてアクセスは全てCloudflare Tunnelを経由するようにしています。

そのせいなのかわかりませんが、Public dashboardを立ち上げるとInternal Server ErrorがData Sourceで返ってきて何も表示されません

`datasources.yml`のURLで直接指定してみてもダメだったのでダメなのかもしれません。単に`access=proxy`なのがダメなのかもしれないんですが、原因がわからないのとまあ使えなくてもそこまで不便ではないのでとりあえず放置しています。

わかった方はPR出していただけると助かります。

### 備忘録

起動すると`Error response from daemon: error while creating mount source path '/var/lib/docker': mkdir /var/lib/docker: read-only file system`と表示されることがある。これはDockerが`apt`ではなく`snap`でインストールされていることが原因である。

`snap`と`apt`の比較については[Snap vs APT: What's the Difference?](https://phoenixnap.com/kb/snap-vs-apt)がわかりやすい。

| 項目                       | Snap             | APT                 | 
| -------------------------- | ---------------- | ------------------- | 
| パッケージタイプ           | .snap            | .deb                | 
| ツール名                   | snaped           | APT                 | 
| CLI                        | snap             | apt                 | 
| フォーマット               | SquashFS archive | ar archive          | 
| リリース                   | Snap Store       | Debian repositories | 
| インストールサイズ         | 大きい           | 小さい              | 
| 依存関係                   | パッケージに梱包 | 共有                | 
| アップデート               | 自動             | 手動                | 
| セキュリティ制限           | 制限             | 限定的に制限        | 
| 複数インストール           | 可能             | 不可能              | 
| 複数バージョンインストール | 可能             | 不可能              | 

どちらが良いかは一長一短のようなのだが、特に困っていることがなければ`snap`のほうが安全そうな気はする。

`docker`がどこにインストールされているかは`which docker`で確認できる。`/snap/bin/docker`と表示された場合には`snap`でdockerがインストールされている。

```yaml
    # Snap
      - /var/snap/docker/common/var-lib-docker:/var/snap/docker/common/var-lib-docker:ro
    # APT
    # - /var/lib/docker/:/var/lib/docker:ro
```

そのときはcadvisorで指定しているvolumesを上のように変更する。すると正しく起動できるようになるはず。

記事は以上。