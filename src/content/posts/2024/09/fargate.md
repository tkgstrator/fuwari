---
title: AWSのFargateなんもわからん 
published: 2024-09-24
description: Fargateを使って困ったことなどのメモ
category: Programming
tags: [AWS, Fargate, ECS, ECR]
---

## FargateでServerlessを動かすまで

Fargateがなんなのかよくわかっていないのだが、サーバーレスでプログラムが動かせるらしい. プログラムが動く以上、サーバーはある気がするのだがEC2のように固定インスタンスがどこかにあるわけではないという意味でのサーバーレスなのだと思う。

Cloudflare Workersはサーバーレスという感じがするのだがFargateはDockerのイメージも動かせるのでますますサーバーレスという気がしない。

まあなんだかんだで今回必要になったのはFargateでHonoでつくったAPIを動かし、別のEC2インスタンスのDBに接続してデータを返すというものであった。

### 思ったこと

1. Fargateって立ち上げるためにIP変わるからEC2でのアクセス許可をどうするん
2. FargateでそもそもどうやってDockerを動かすのん

### やってみた

手順を全部解説すると長いので大雑把にいうと、ビルドしたDockerのイメージは通常Docker HubなどにアップロードするがそれをECRにアップロードする。するとそのイメージをもとにしてインスタンスを立ち上げることができる。

このとき立ち上げることができるのはFargateとEC2の二種類がある。どちらにせよ、Dockerのイメージを更新するだけでバージョン更新ができるので便利である。

今回はタイトルにもあるようにFargateを採用した。

### ECR

レポジトリを作成する。外部に公開したくないのであればプライベートにすると良い。

イメージ名を決めるとデプロイするためのコマンドが表示されるのでそれを利用しよう。

`XXXXXXXXXXXXXXXX.dkr.ecr.ap-northeast-1.amazonaws.com/YYYYYYYYYYYYY`のようなURIが表示されるので、それをコピーする。

### ECS

ECRのイメージをもとにしてサービスを立ち上げるためのサービス。

- クラスター(Clusters)
- タスク定義(Task definitions)
- サービス(Services)

の三つがあり、ややこしい。

イメージとしては「クラスターにサービスを割り当てるとタスク定義の通りに動く」という感じです。

#### クラスター

名前とFargateを指定して終わり。

#### タスク定義

どんなマシンで動かすかを決めるところで、主に以下の内容を決めます。

- Launch Type
    - Fargate
    - EC2
- OS/Architecture
    - Linux/X86_64
    - Linux/ARM64
- Task Size
    - CPU
    - Memory
- Task Role
    - ecsTaskExecutionRole
- Task Execution Role
    - ecsTaskExecutionRole
- Container
    - Image URI
- Port Mappings
- Environment Variables

結構多いので注意。Cloudflare Workersと同じく、一度決めてしまうとバージョンを上げないと変更できない。

逆に言えばバージョンさえ上げれば上の設定は切り替えられます。

#### サービス

タスク定義からつくられる実際に動くサービスの設定

- タスク定義のバージョン(リビジョン)
- サービス名
- 同時実行数
- VPC
    - サブネット
    - セキュリティグループ

これらのうちVPCなどのネットワークに関する設定はサービスを更新しても変更できない。

つまり、クラスターで一度サービスが動いてしまうとサービスを止めるしかなくなるわけです。

Fargateはその性質上、IPアドレスがサービスを立ち上げるたびに変わってしまうのでどうしようかなという感じですね。

### Cloudfront