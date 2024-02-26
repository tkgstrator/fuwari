---
title: NestJS+BunをDockerで動かす 
published: 2024-02-15
description: 'やろうとしたらちょっと躓いたので備忘録としてメモしておきます'
image: ''
tags: ['Docker', 'Bun', 'NestJS']
category: 'Programming'
draft: false 
---

## Bun.build

ビルドすると以下のような感じになります。

```zsh
.
├── node_modules
├── dist/
│   ├── src/
│   │   └── main.js
│   ├── package.json
│   └── tsconfig.build.tsbuildinfo
├── package.json
├── tsconfig.json
└── tsconfig.build.json
```

NodeJSでビルドしたときだと`node_modules`と`dist`があれば`node dist/src/main`で起動できました。

Bunの場合は`bun dist/src/main.js`で起動できます。Nodeの場合と違って拡張子を指定しなければいけないようです。

### Dockerfile

Bunの公式サイトに[Dockerfileのドキュメント](https://bun.sh/guides/ecosystem/docker)があるのでそれを参考にしてみます。

```docker
FROM oven/bun:1 AS base

# Development Install
FROM base AS install 
WORKDIR /app/dev
COPY package.json bun.lockb ./
RUN bun install --frozen-lockfile

# Production Install
WORKDIR /app/prod
COPY package.json bun.lockb ./ 
RUN bun install --frozen-lockfile --production --ignore-scripts

# Pre Release
FROM base AS prerelease 
WORKDIR /app
COPY --from=install /app/dev/node_modules node_modules
COPY . .

# Test and Build
ENV NODE_ENV=production
RUN bun test
RUN bun run build
```

途中まで書くとこういう感じになります。

実行時には`devDependencies`は不要なのですがビルドのときには必要な場合があるのでビルドのときには`Development`の方の`node_modules`を利用します。

なので`Pre Release`のところでは`/app/dev/node_modules`の方を使っているわけですね。

そしてもともとあるソースコードを利用してテストとビルドを実行します。

ここのビルドが通れば上で書いたようなディレクトリ構成でトランスパイルされたものが出力されるので`Pre Release`のコンテナは以下のようになるはずです。

```zsh
app/
├── node_modules
├── src/
│   └── main.ts
├── dist/
│   ├── src/
│   │   └── main.js
│   ├── package.json
│   └── tsconfig.build.tsbuildinfo
├── package.json
├── tsconfig.json
└── tsconfig.build.json
```

ただ、実際には`COPY . . `でディレクトリの全てのファイルをコピーしてきているので余計なファイルも多分に含まれています。余計なファイルを同梱するとイメージのサイズが大きくなるのでそれらは含まないように配慮してリリース用のイメージにコピーします。

### リリース用イメージ

ここで再度公式ドキュメントを参考にコピーするファイルを選定します。

```dockerfile
FROM base AS release
WORKDIR /app
COPY --from=install /app/dev/node_modules ./node_modules
COPY --from=prerelease /app/dist/src ./src
COPY --from=prerelease /app/package.json ./package.json
COPY --from=prerelease /app/tsconfig.json ./tsconfig.json
```

よくわからないのですがBunは実行時にもどうも`package.json`と`tsconfig.json`が必要なので突っ込みました。

あと、ビルドした段階ではNestJSはデフォルトで`./dist`にトランスパイルしたコードが出力されるのですがこれをそのまま突っ込むとモジュールの参照エラーが発生します。

どうも`bun run **/main.js`を実行したときのディレクトリからの相対パスが問題っぽく`bun run src/main.js`で実行できるようなディレクトリ構造になっていないとダメなようです。

なので`COPY --from=prerelease /app/dist/src ./src`として`dist/src`の中身を`src`にコピーするという若干ややこしいことをしています。


