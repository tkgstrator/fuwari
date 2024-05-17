---
title: GitHub RunnerをDockerで動かす 
published: 2024-02-02
description: Self HostedなGitHub RunnerをDockerで動かすための方法 
category: Programming
tags: [macOS, Docker]
---

## GitHub Runner

GitHub Runnerをself-hostedで動作させることは以前少し紹介したのでそれを多少改良したものになる。

個人的にGitHub Runnerの最も良くないところだと考えているのは何故かシェルスクリプトで動かすことを前提としているところだった。

シェルスクリプトで動かすとなると、待機させておきたいRunnerの数だけターミナルを起動しないといけないし、何らかの理由でコケたときに復帰させるのがめんどくさい。

じゃあDockerで動かしてDocker composeで管理してしまえばいいじゃんとなった。

### Docker

Dockerを使えば全部解決かというとそうではない。

基本的に良いことばかりだが、良くない点としてはmacOS(Apple Silicon?)でDockerを動かすとネイティブに比べてやたらと遅くなってしまうという問題がある。

これはx264をエンコードしたときにも感じたのだが、本来の実力の75%くらいしか出せないと思って良い。

とはいえ、ものすごく重い処理でなければこの差がはっきりと出るような場面はなさそうだ。

もう一つの問題点はmacOS自体をコンテナとして利用できなくなる点である。

例えばiOS向けのアプリのビルドはmacOSでしかできないが、Dockerで動かすとUbuntuなどになってしまうためXcodeが利用できずに詰んでしまう。

というか、Dockerで結局Ubuntuで実行するなら最初から公式の無料のRunnerを使えばいいじゃないかという話になってしまう。

なので、macOS上でわざわざUbuntuのGitHub RunnerをDockerで動かす意味があるかというと、殆どない。プライベートレポジトリで何らかの理由でガンガンActionsを回して無料分では足りませんというときくらいだろう。

無料のRunnerはスペックがそこまで高くないのでSelf-hostedの構成のPCで回したいというのならわかるが、macOSの場合は先程も述べたようにDockerを経由するとパフォーマンスが落ちるのでそこの恩恵も小さい。それなら最初からUbuntu上でDockerを動かせば良い。

というわけで何の意味があるのかよくわからないが(Dockerで自分自身を参照できればよいのだが)、とりあえず実装してみることにした。

### イメージ

[tcardonne/github-runner](https://hub.docker.com/r/tcardonne/github-runner)というイメージがDocker Hub上に見つかったが三年前なので古い。

ないなら作るかと思ったが[myoung34/github-runner](https://hub.docker.com/r/myoung34/github-runner)を見つけたのでこちらを参考に自前でDockerfileを作成することにした。

## [docker-github-actions-runner](https://github.com/tkgstrator/docker-github-actions-runner)

完全に個人用にはなるのだが[tkgling/github-runner](https://hub.docker.com/r/tkgling/github-runner)としてリリースすることができた。

> えらいので一応ARM64とAMD64の二種類のイメージを用意しています

当初はDistrolessを利用したかったのだが、使えないコマンドがあまりも多すぎたので妥協して`ubuntu:focal`を利用した。

これでもベースのイメージは70.8MBになったがDistrolessが利用できればこの1/10くらいにはなったはずなのでちょっと悔しい。

ベースイメージに対してNodeJSを追加したバージョンもリリースしており、基本的にはこちらを使っている、便利である。

```yaml
version: '3.9'

services:
  vuepress:
    image: tkgling/github-runner:node20.11.0
    platform: linux/amd64
    restart: always
    container_name: CONTAINER_NAME
    tty: true  
    stdin_open: true
    environment:
      REPO_URL: REPO_URL
      RUNNER_NAME: RUNNER_NAME 
      RUNNER_SCOPE: RUNNER_SCOPE
      RUN_AS_ROOT: true
      ACCESS_TOKEN: $ACCESS_TOKEN
    security_opt:
      - label:disable
    volumes:
      - '/var/run/docker.sock:/var/run/docker.sock'
```

作成する`docker-compose.yaml`は上のような通り。`RUNNER_NAME`は適当で良い。

レポジトリ単位でRunnerを動かしたい場合は`RUNNER_SCOPE=repo`、もしも組織で一つのRunnerを動かしたい場合は`RUNNER_SCOPE=org`とする。

> `RUNNER_SCOPE=org`を設定した場合は`REPO_URL`ではなく`ORG_NAME`を指定すること

`RUN_AS_ROOT`は何か知らないけれど必要になってしまった、なくても動くようにしたい。`ACCESS_TOKEN`はGitHubのPersonal Access Tokenを指定する。

記事は以上。