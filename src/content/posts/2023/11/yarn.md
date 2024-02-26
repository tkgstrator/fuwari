---
title: yarn v2をつかってみる
published: 2023-11-22
description: yarn v2への移行を実際に試してみました
category: Tech
tags: [macOS, yarn]
---

## 背景

Yarnにはバージョン1とバージョン2(Berry)がありnode_modulesの肥大化を解決している模様。

キャッシュも利用していて、キャッシュが効く場合にはインストールもそれなりに速いらしいです。

> 効かない場合はむしろ依存関係の問題？でv1の方が10倍くらい速いときもある、謎

### バージョン確認

```zsh
yarn -v
1.22.19
```

とするとバージョンが分かります。

### バージョン更新

```zsh
yarn set version berry
```

を実行すると同一ディレクトリ配下に、

- `.yarn/`
- `.yarnrc.yml`

が作成されます。再度バージョンを確認すると、

```zsh
yarn -v
4.0.2
```

と何故かバージョンが4に上がりました。

> 2とは一体？

このままだと余計なファイルがgitの管理に入ってしまうので、.gitignoreに

```zsh
# yarn v2
.yarn/cache
.yarn/unplugged
.yarn/build-state.yml
.yarn/install-state.gz
.pnp.*
```

を追加しておきます。

この状態で終わらせてもいいのですが、`node`や`ts-node`を実行したときに`node_modules`を探しにいくので実行エラーが発生してしまいます。

これはv2では`node_modules`が生成されないためなのですが、これに対処するために`.yarnrc.yml`に以下の内容を追記します。

```zsh
nodeLinker: node-modules

yarnPath: .yarn/releases/yarn-4.0.2.cjs
```

`node_modules`じゃなくて`node-modules`であることがポイントです。なんでハイフンなのかは謎です。これをやると`yarn install`時に`node_modules`が作成されるようになり、v1のときに比べてサイズ自体はものすごく小さいのですがこれ自体をgit管理する意味はないので引き続き.gitignoreで除外設定はしておきましょう。

これでVSCodeなりでこのディレクトリを開くとバージョンが自動的に切り替わるようになりました。

```zsh
devonly: ~ $ yarn -v
1.22.19 ＃ このYarn自体はbrew install yarnでインストールしました
devonly: ~ $ cd Developer/ios-app-decryptor 
devonly: ~/Developer/ios-app-decryptor (docs *%=)$ yarn -v
4.0.2
```

上のようにホームディレクトリでは1.22.19だったバージョンがディレクトリを移動するだけでv2が利用できているのがわかります。

## v2にない機能

v2ではv1にはあった機能のいくつかがないのでプラグインで対応します。

### upgrade-interactive

例えば`upgrade-interactive`は対話的にバージョン管理が行える便利なコマンドでしたが、v2だとそのまま実装されてはないので、

```zsh
yarn plugin import interactive-tools
```

として追加します。

### プロダクションビルド

Dockerなどで`yarn install`を実行するときに開発環境用のモジュールは追加したくないので、

```zsh
yarn --production --ignore-scripts --prefer-offline
```

というコマンドがありましたが、v2ではこれはありません。

```zsh
yarn plugin import workspace-tools
yarn workspaces focus --all --production
```

その場合、上のコマンドで代用可能なのでこちらを利用しましょう。

### GitHub Actions

GitHub ActionsでSSGをビルドする際にデフォルトではyarnが入っていなかったので`npm install -g yarn`でわざわざインストールしていたのですが、これを`npm install -g yarn@2`と変更します。

これでv2がインストールされるので、最終的に以下のようになります。

```yaml
jobs:
  publish:
    runs-on: ubuntu-20.04
    permissions:
      contents: read
      deployments: write
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Install Yarn
        run: npm install -g yarn@2 # ここを変更

      - name: Cache CDK Dependencies
        uses: actions/cache@v3
        id: cache_cdk_dependency_id
        env:
          cache-name: cache-cdk-dependency
        with:
          path: .yarn/cache # node_modulesに代えて.yarn/cacheをキャッシュする
          key: ${{ runner.os }}-build-${{ env.cache-name }}-${{ hashFiles('yarn.lock') }}
          restore-keys: ${{ runner.os }}-build-${{ env.cache-name }}-
      
      - name: Install Dependencies
        if: ${{ steps.cache_cdk_dependency_id.outputs.cache-hit != 'true' }}
        run: yarn --immutable --immutable-cache
```

記事は以上。