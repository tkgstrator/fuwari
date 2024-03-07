---
title: DevContainer+Dockerでキレイな開発環境を手に入れる 
published: 2024-03-07
description: 開発環境の構築という大いなる課題にいよいよ決着がつきそうです 
category: Tech
tags: [VSCode, DevContainer, NodeJS, Docker]
---

## 開発環境構築の大きな課題

開発環境の構築において、従来は以下のような課題がありました。

- それぞれ動いているマシンが異なる
- それぞれ動いているマシンのOSが異なる
- そもそもアーキテクチャが異なる

で、これを解決するための大いなる力がDockerだったわけです。

Dockerは提供さえされていればPlatformの違いも全て丸く収めてくれるので、Apple SiliconのデバイスであろうともRosetta2を経由することでx86_64環境を再現して開発ができました。

Rosetta2がどれほどのものかはよくわかっていないのですが、今のところ実機でできてRosetta2でできないような作業は見つかっていません、とてもすごい。

### Docker

とはいえDockerですら万能ではありませんでした。

例えば本番環境ではNode 18を継承したDocker Imageをdocker composeなりで動かすようなプロダクトを考えましょう。

```dockerfile
FROM oven/bun:1

WORKDIR /home/bun/app
COPY package.json bun.lockb ./
RUN bun install --frozen-lockfile
```

その時は上のようなDockerfileを作成すると思います。

```zsh
.
├── node_modules/
├── src/
│   └── index.ts
├── package.json
├── tsconfig.json
├── Dockerfile
├── docker-compose.yaml
└── bun.lockb
```

そして、実際に今まで私がプロダクト開発をする際は上のようなディレクトリ構成になっていました。

### 問題点

ではこの構成の問題点は何でしょうか？

一つは、実際に開発する環境が動かす環境と異なってしまうという点です。

例えばDockerのイメージとしてNode 18を使いたければホストマシンにNode 18をインストールする必要があります。

するとNodeのバージョン管理マネージャーが必要になるのでnvmなどのインストールが必要になります。

もう一つはホストマシンとDockerのアーキテクチャの差を埋めることができないということです。

稀にaarch64で動かないみたいなパッケージもあったりするので、上のような構成ではホストマシンは常にホストマシンでのアーキテクチャでしか動作させることができません。

せっかくDockerがアーキテクチャの差を埋められるのにホストマシンでそのまま開発していては意味がないわけです。

じゃあDockerコンテナを立ち上げてその中で開発してしまえばよいのですが、これにも問題があります。

1. Dockerコンテナ内で変更した内容がホストマシンに伝わらない
2. Dockerコンテナ内からリポジトリにプッシュできない
3. VSCodeのExtensionなどが効かない

1についてはvolumesを利用することで解消できます。

2については公開鍵認証を利用している場合に問題になります。当たり前ですが、ホストマシンの`.ssh`を`COPY`コマンドで複製するようなムーブメントは絶対にしないでください。

3についてはまあそりゃそうかっていう感じです。

要するに私達がしたいのはDockerのコンテナの中で開発をし、変更は即座にホストマシンに反映され、かつリポジトリにプッシュもできてExtensionも使えるという状況です。

開発は全てDockerのコンテナの中でやりたいわけです。

こうすれば、ありとあらゆる互換性の問題は排除されます。

## DevContainer

そしてそれらを全て解決する仕組みがVSCodeには備わっていました。

それがDevContainerで、Dockerコンテナ内で作業をするのを便利にするための神ツールです。

```zsh
.
├── .devcontainer/
│   ├── devcontainer.json
│   ├── Dockerfile
│   └── docker-compose.yaml
├── node_modules/
├── src/
│   └── index.ts
├── package.json
├── tsconfig.json
└── bun.lockb
```

まず、先程の構成を上のように変更します。

`.devcontainer`というディレクトリを作成して元々あった`Dockerfile`と`docker-compose.yaml`をコピーします。

### devcontainer.json

設定ファイルは以下のようなものを書きます。

自分の場合、開発するのは主にNodeかBunだと思うのでそれを載せておきます。

|      | remoteUser | workspaceFolder | postCreatecommand                    | 
| ---- | ---------- | --------------- | ------------------------------------ | 
| Bun  | bun        | /home/bun/app   | sudo chown -R bun:bun node_modules   | 
| Node | node       | /home/node/app  | sudo chown -R node:node node_modules | 

Bunだとデフォルトユーザーが`bun`, Nodeだと`node`なので異なるのはそこだけです。

`workspaceFolder`は末尾に`app`をつけていますが直接`/home/bun`のように指定する人もいると思います。

ここはDockerfileで決められるので好きなものをご利用ください。

`service`の値は`docker-compose.yaml`で設定した値を使います。

```json
{
  "name": "Dev Container",
  "dockerComposeFile": [
    "docker-compose.yaml"
  ],
  "service": "DOCKER_COMPOSE_SERVICE_NAME",
  "workspaceFolder": "/home/bun/app",
  "shutdownAction": "stopCompose",
  "remoteUser": "bun",
  "mounts": [
    "source=${env:HOME}/home/bun/.ssh,target=/.ssh,type=bind,consistency=cached,readonly"
  ],
  "features": {
    "ghcr.io/devcontainers/features/git:1": {},
    "ghcr.io/devcontainers/features/common-utils:2": {
      "configureZshAsDefaultShell": true
    },
    "ghcr.io/devcontainers/features/github-cli:1": {},
    "ghcr.io/devcontainers/features/docker-outside-of-docker:1": {
      "moby": false,
      "dockerDashComposeVersion": "v2"
    }
  },
  "postAttachCommand": "git config --global --unset commit.template",
  "postCreateCommand": "sudo chown -R bun:bun node_modules",
  "customizations": {
    "vscode": {
      "settings": {
        "debug.internalConsoleOptions": "neverOpen",
        "editor.formatOnPaste": true,
        "editor.guides.bracketPairs": "active",
        "scm.defaultViewMode": "tree",
        "diffEditor.diffAlgorithm": "advanced",
        "diffEditor.experimental.showMoves": true,
        "diffEditor.renderSideBySide": false,
        "files.watcherExclude": {
          "**/node_modules/**": true
        },
        "betterTypeScriptErrors.prettify": true
      },
      "extensions": []
    }
  }
}
```

デフォルトで`zsh`を利用するように書いているのですが、ひょっとするとNodeの古いバージョンだと動かないと思うのでその時は消してください。

> [VSCode拡張機能 Remote Containers におけるpostCreateCommandなどの実行タイミングについて](https://vlike-vlife.netlify.app/posts/vscode_remote_container_command)

`postCreateCommand`はデフォルトだと`node_modules`が`root:root`になっていてアクセスできないのでそれを変更するためのものです。

`postAttachCommand`は`.gitconfig`をローカルからコピーしてくると`git commit`が効かなくなるのでその対策です。

![](https://vlike-vlife.netlify.app/_images/Remote%20Containers%20%E5%AE%9F%E8%A1%8C%E9%A0%86%E5%BA%8F-2abc2e495615ecd00c9a406a5b31330f0342a730.svg)

`postCreateCommand`で実行できればよいのですが、そのタイミングではまだ`.gitconfig`がコピーされていないので利用できません、悲しい。

正直、アタッチするたびに呼ばれて面倒なのですが、他に良い方法があれば教えて下さい。

### docker-compose.yaml

```yaml
version: '3.9'

services:
  DOCKER_COMPOSE_SERVICE_NAME:
    container_name: DOCKER_COMPOSE_CONTAINER_NAME # 任意の値
    platform: linux/amd64 # 利用したいアーキテクチャ
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - ../:/home/bun/app:cached # NodeかBunかで変更
      - node_modules_cached:/home/bun/app/node_modules # NodeかBunかで変更
    tty: true # とりあえずつけている
    stdin_open: true # とりあえずつけている
  
volumes:
  node_modules_cached:
```

ここではホストマシンとDocker内でファイルを同期するように`volumes`を利用して指定します。

ただし、`node_modules`を同期してしまうととんでもなく遅くなるのでこれだけは名前付きボリュームを利用してホストマシンとは同期しないようにします。

こうすることで以前のプロジェクトでは`yarn install`に150秒くらいかかっていたのが85秒程度にまで高速化できました。

### Dockerfile

```zsh
FROM oven/bun:1.0.30 AS build

# Vim, sudo, curlのインストール
RUN apt update && apt install -y vim sudo curl
RUN apt-get -y autoremove \
  && apt-get -y clean \
  && rm -rf /var/lib/apt/lists/*

# ユーザーの追加(いるかどうかは微妙)
RUN echo 'bun ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
WORKDIR /home/bun/.zsh

# ターミナルにGitのブランチなどを表示する
RUN curl -o git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
RUN curl -o git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
RUN curl -o _git https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh
RUN chmod a+x git*.*

# 上手く動かなかったので絶対パス指定で.zshrcに追記
RUN ls -l $PWD/git*.* | awk '{print "source "$9}' >> /home/bun/.zshrc
RUN echo "source ~/.bash/git-prompt.sh" >> /home/bun/.zshrc
RUN echo "fpath=(~/.bash $fpath)" >> /home/bun/.zshrc
RUN echo "GIT_PS1_SHOWDIRTYSTATE=true" >> /home/bun/.zshrc
RUN echo "GIT_PS1_SHOWUNTRACKEDFILES=true" >> /home/bun/.zshrc
RUN echo "GIT_PS1_SHOWSTASHSTATE=true" >> /home/bun/.zshrc
RUN echo "GIT_PS1_SHOWUPSTREAM=auto" >> /home/bun/.zshrc
RUN echo 'export PS1="\[\033[01;32m\]\u@\h\[\033[01;33m\] \w \[\033[01;31m\]\$(__git_ps1 \"(%s)\") \\n\[\033[01;34m\]\\$ \[\033[00m\]"' >> /home/bun/.zshrc

# Vimでコミットメッセージを書くときに日本語が文字化けするのでUTF-8を指定
RUN echo "set encoding=utf-8" > /home/bun/.vimrc

USER bun
WORKDIR /home/bun/app
CMD ["/bin/bash"] # 勝手にターミナルが閉じるのでその対策(必要?)
```

Dockerファイル自体は上のようになります。

開発に必要な最低限のソフトウェアを追加する感じですね。Gitのブランチ名などは見えたほうが便利なので個人的には重宝しています。

## まとめ

あとはこのディレクトリをVSCodeで開けばDevContainerを利用するかどうか訊いてくるのでYesを押します。

最初こそ時間がかかりますが、それ以後は設定さえ変えなければ一瞬で起動して開発環境に入ることができます。

コンテナ内で変更したソースコードも即座にホストマシンに反映されますし、コンテナ内でホストマシンの`.ssh`を共有しているので公開鍵認証のレポジトリにも問題なくプッシュすることができます。

唯一問題があるとしたら、ネイティブ実行よりも遅いことくらいですが、これはマシンをつよつよにしたり、今後のDockerのアップデートでより良くなるだろうと思っています。

記事は以上。