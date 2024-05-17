---
title: GitHub Packagesを使わずにプライベートパッケージを公開するまでの手順
published: 2023-03-27
description: GitHub Packagesすらもめんどくさい方向けのチュートリアルです
category: Tech
tags: [GitHub]
---

## 背景

- Typescript で書いたライブラリを使いたい
- リモートに保存しておきたい
- NPM で公開するまででもない
- GitHub Packages すらもめんどくさい

という方向けの記事になります。

基本的に、パッケージというのは Typescript で書かれたものであれば Javascript にコンパイルされていなければいけないので、ライブラリとして利用するためにはコンパイルされたパッケージとして利用する必要があるわけです。

ぶっちゃけるとコンパイルしたファイル自体をコミットすれば動くといえば動くのですが、流石にそれはアレなので生成物は同梱しないようにしてそれを実装します。

### スクリプトを利用する

`package.json`には通常のスクリプトとは別に`pre`や`post`のプレフィックスを付けることで任意のタイミングでスクリプトを実行することができます。

それについては[この記事](https://www.twilio.com/blog/npm-scripts)が比較的わかりやすく書いてくれているので、これを読むと良いと思います。

で、`yarn install`が実行されたあとで`yarn postinstall`が実行されるので、このタイミングでソースコードから自分をコンパイルするようなコードを書きます。

```json
{
  "scripts": {
    "test": "jest",
    "build": "tsc",
    "format": "prettier --write 'src/**/*.ts'",
    "lint": "eslint \"{src, test}/**/*.ts\" --fix",
    "postinstall": "tsc"
  }
}
```

つまりは上のようなコードになるのですが、これだと`@types/webpack`がそもそものプロジェクトに入っているときなどに失敗したりします。原因はよくわからないのですが、型チェックが入っているとコケるようです。

コケない人もいると思うので、以下はコケた人向けの内容です。

### tsc-transpile-only を利用する

対策としては`{ transpileOnly: true }`を`webpack.config.js`に書き込むなどいろいろ方法はあるのですが、ライブラリ側がコンパイルが通っている時点で型チェックはできているとみなして、インストールする際には型チェックをしないようにします。

ところが`tsc`には`--transpile-only`のようなオプションがないのでこのままだと何回やってもコンパイルが通りません。

なんとかならないのかと思っていたところ[tsc-transpile-only](https://www.npmjs.com/package/tsc-transpile-only)というライブラリを発見しました。どうも型チェックを無視してくれるパッチがあたった`tsc`のようです。

というわけで、以下のように書き換えます。

```json
{
  "scripts": {
    "test": "jest",
    "build": "tsc",
    "format": "prettier --write 'src/**/*.ts'",
    "lint": "eslint \"{src, test}/**/*.ts\" --fix",
    "postinstall": "tsc-transpile-only"
  }
}
```

こうすると少なくとも自分の環境ではエラーが発生せずにソースコードからビルドしてライブラリとして取り込むことができました。

記事は以上。
