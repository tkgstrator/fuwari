---
title: GitHub Packagesでプライベートパッケージを公開するまでの手順
published: 2023-03-27
description: 使いまわしたいけれど一般リリースするまでもないようなパッケージを個人的に利用したい場合のチュートリアルです
category: Tech
tags: [GitHub]
---

## 背景

使いまわしたいから作成したけれど、NPM で一般リリースするまでもないようなパッケージを GitHub 上に公開するためのチュートリアルです。

イカリング 3 系統のパッケージを作成したのですが、NPM の方の公開の仕方がわからなかったのでまとめておきます。

これに比べれば Package.swift を載せておくだけで GitHub から直接インストールも更新もできる Swift Package Manager って偉大なんだなあと思いました。

## 個人用アクセストークンの取得

[Personal Access Token](https://github.com/settings/tokens)を発行します。

発行したアクセストークンはデフォルトでは自分のレポジトリでしか有効でないので、組織で有効にしたい場合には[組織の個人用アクセストークンポリシーを設定する](https://docs.github.com/ja/organizations/managing-programmatic-access-to-your-organization/setting-a-personal-access-token-policy-for-your-organization#restricting-access-by-personal-access-tokens-classic)から設定して有効化する必要があります。

アクセストークンに必要な権限は`write:packages`だけなのでとりあえずこれだけ有効化しておきましょう。

で、発行します。発行したアクセストークンをここでは`GITHUB_TOKEN`としておきましょう。

### パッケージ名について

さて、次に package.json を編集していきます。GitHub Packages ではスコープ付きのパッケージしかサポートされていないので、パッケージ名は必ず`@SCOPE/PACKAGE_NAME`の形式にする必要があります。

で、`SCOPE`の値と`PACKAGE_NAME`は以下のルールに従う必要があります。

|              |     個人     |     組織     |
| :----------: | :----------: | :----------: |
|    SCOPE     | アカウント名 |    組織名    |
| PACKAGE_NAME | レポジトリ名 | レポジトリ名 |

要するに、公開するレポジトリが決まっている時点で`SCOPE`と`PACKAGE_NAME`は固定になるわけですね。

公開したいレポジトリが`https://github.com/SCOPE/PACKAGE_NAME`となっている必要があるというわけです。

### package.json テンプレート

中略ですが、以下のように書きます。GitHub に公開する場合は`registry`の値は`https://npm.pkg.github.com`になります。

ここの値、GitHub だと常にこの値で良いみたいなのですが[ドキュメント](https://docs.gitlab.com/ee/user/packages/npm_registry/)を読むと GitLab だとちょっとめんどくさいっぽいですね。

```json
{
  "name": "@tkgstrator/private-package-test",
  "repository": {
    "type": "git",
    "url": "git@github.com:tkgstrator/private-package-test.git"
  },
  "publishConfig": {
    "registry": "https://npm.pkg.github.com"
  }
}
```

## NPM にログインする

作成したパッケージをプッシュするためには認証情報を渡さないといけないので、渡します。

このとき、`.npmrc`を利用するか`npm login`を利用するかが選べます。個人的にはどっちでもいいですが`npm login`の方が安全なのかなとは思っています。

### .npmrc を利用する

`touch .npmrc`で作成したファイルに認証情報を書きます。

アクセストークンを含むので、`.gitignore`に追加するのを忘れないようにしておきましょう。

```
//npm.pkg.github.com/:_authToken=GITHUB_TOKEN
```

最初に取得した GITHUB_TOKEN の値をここに書き込みます。

### npm login を利用する

以下のコマンドを入力します。

```
npm login --scope=@test --auth-type=legacy --registry=https://npm.pkg.github.com
```

|          |         個人          |         組織          |
| :------: | :-------------------: | :-------------------: |
| Username |  GitHub アカウント名  |  GitHub アカウント名  |
| Password |     GITHUB_TOKEN      |     GITHUB_TOKEN      |
|  Email   | GitHub メールアドレス | GitHub メールアドレス |

公開したいレポジトリが個人のものでも組織のものでも個人のアカウント名を入力すれば大丈夫だと思います。そのためにアカウントのアクセストークンが組織でも有効になるように設定したので。

ログインができたら`npm publish`を実行します。

```
npm notice === Tarball Details ===
npm notice name:          @tkgstrator/private-package-test
npm notice version:       1.0.1
npm notice filename:      @tkgstrator/private-package-test-1.0.1.tgz
npm notice package size:  35.8 kB
npm notice unpacked size: 276.8 kB
npm notice shasum:        09bef77af0be77cb2cee5b83da07af50e1cd83ed
npm notice integrity:     sha512-Riiz0iJUlvi3o[...]ULnXsE5+IDoZw==
npm notice total files:   106
npm notice
npm notice Publishing to https://npm.pkg.github.com
+ @tkgstrator/private-package-test@1.0.1
```

するとこんな感じでパッケージを無事に公開することができました。

## インストールする

これだけで公開はできているのですが、

```
yarn add @tkgstrator/private-package-test
```

としてインストールしようとすると、

```
yarn add v1.22.19
[1/4] 🔍  Resolving packages...
error An unexpected error occurred: "https://registry.yarnpkg.com/@tkgstrator%2fprivate-package-test: Not found".
info If you think this is a bug, please open a bug report with the information provided in "/Users/devonly/Developer/package-test/yarn-error.log".
info Visit https://yarnpkg.com/en/docs/cli/add for documentation about this command.
```

として怒られます。`@tkgstrator`から始まる名前空間(スコープ)の情報がわからないということだと思うので、`.npmrc`に情報を追記します。

結局`.npmrc`を使わないといけないのであれば最初から使っていればいいのでは感もありますね。

`.npmrc`に以下の情報を書き込みます。

```
@SCOPE:registry=https://npm.pkg.github.com
```

今回の場合は`SCOPE`の値は`tkgstrator`ですが、そこは各自変更してください。

```
yarn add v1.22.19
[1/4] 🔍  Resolving packages...
[2/4] 🚚  Fetching packages...
[3/4] 🔗  Linking dependencies...
warning " > ts-node@10.9.1" has unmet peer dependency "@types/node@*".
[4/4] 🔨  Building fresh packages...
success Saved lockfile.
success Saved 1 new dependency.
info Direct dependencies
└─ @tkgstrator/private-package-test@1.0.1
info All dependencies
└─ @tkgstrator/private-package-test@1.0.1
✨  Done in 2.67s.
```

再度実行すると無事にパッケージをインストールすることができました。めでたしめでたし。
