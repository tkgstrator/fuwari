---
title: NestJSでREST API開発時に使える設定とかまとめ
published: 2022-12-29
description: ESLintやPrettierでどんな設定を追加すればいいかわからなかったのでいろいろ参考にしてみました
category: Programming
tags: [Javascript, Typescript]
---

## 背景

[NestJS に俺の考えた最強の ESLint + Prettier の設定を導入するぞ！！](https://qiita.com/ganja_tuber/items/895e382cd4d3cfae23a7)で NestJS に ESLint と Prettier を導入されている方がいたので、これを参考にしてみました。

### 必要なもの

- VScode
- nvm

基本的には VScode さえあれば全てが事足ります。

nvm は以下のコマンドで導入できます。場合によっては`xcode-select --install`が必要になるので入れておきましょう。後は画面に表示される手順に従ってディレクトリを作成したりします。

```
brew install nvm
```

### NodeJS のバージョン設定

NestJS は最新の NodeJS だと動かないことがあります。16.15.0 では動作することがわかっているので、とりあえずこのバージョンを使っておきます。

なので`.nvmrc`というファイルを作成して、

```
v16.15.0
```

とだけ書いておきます。これで`nvm use`とすれば明示的に 16.15.0 が使用されるようになります。

ただ、これだといちいちプロジェクトを開くたびに`nvm use`と入力しなければならず、めんどくさいです。

というわけで`.zshrc`に以下のコマンドを書きます。

これは[[Visual Studio Code] [MacOS] .nvmrc で指定したバージョンに自動で切り替えてプロジェクトをスタートする](https://qiita.com/cleverdog/items/f50dcff0bc2905816b8e)の記事がとても参考になりました。

```
source ~/.nvm/nvm.sh
# place this after nvm initialization!
autoload -U add-zsh-hook
load-nvmrc() {
  if [[ -f .nvmrc && -r .nvmrc ]]; then
    nvm use
  elif [[ $(nvm version) != $(nvm version default)  ]]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc
```

当たり前ですが`nvm`は導入済みである必要があるので入れておきましょう。

### ESLint

ESLint を導入することで世間一般で使われているコーディング規約を学ぶことができます。チームでコードを書くときなどは、ルールを統一しておかないとごっちゃになるので入れておくのが無難です。

NestJS の場合は`.eslintrc.yml`を作成して以下のように記述するとかなりキツめの設定が反映されます。要らないと思ったらいくつか無効化しても良いと思います。

```yml
root: true
env:
  node: true
  es2022: true
parser: "@typescript-eslint/parser"
parserOptions:
  project: ./tsconfig.json
  sourceType: module
extends:
  - eslint:recommended
  - plugin:@typescript-eslint/recommended
  - prettier
plugins:
  - import
  - sort-keys-fix
  - typescript-sort-keys
  - unused-imports
rules:
  import/order:
    - error
    - groups:
        - builtin
        - external
        - internal
        - parent
        - sibling
        - index
        - object
        - type
      newlines-between: always
      alphabetize:
        order: asc
  import/no-duplicates: error
  sort-keys-fix/sort-keys-fix: error
  typescript-sort-keys/interface: error
  unused-imports/no-unused-imports: error
```

### Prettier

`.prettierrc.yml`を作成して以下のような内容を書き込みます。

```yml
trailingComma: all
tabWidth: 2
semi: true
singleQuote: false
jsxSingleQuote: false
printWidth: 100
```

### Swagger

NestJS で作ったドキュメントを OpenAPI で公開したい場合には Swagger を使うと良いと習ったのでそれも実装します。

`ValidationPipe`を使わない人は存在しないと思われるのでデフォルトで入れてあります。また、ビルドすると自動で`docs`内に`index.html`が作成されるのでこれを GitHub Pages で公開しておけば常に最新のドキュメントが見れるようになります。

```ts
import { ValidationPipe } from "@nestjs/common";
import { NestFactory } from "@nestjs/core";
import { SwaggerModule, DocumentBuilder, OpenAPIObject } from "@nestjs/swagger";
import { AppModule } from "./app.module";
import { config } from "dotenv";
import { exec } from "child_process";
import { mkdir, writeFileSync } from "fs";
import * as path from "path";
config({ path: ".env" });

async function build(documents: OpenAPIObject) {
  const build = path.resolve(process.cwd(), "docs");
  const output = path.resolve(build, "index");
  mkdir(build, { recursive: true }, () => {});
  writeFileSync(`${output}.json`, JSON.stringify(documents), {
    encoding: "utf8",
  });
  exec(`npx redoc-cli build ${output}.json -o ${output}.html`);
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useGlobalPipes(
    new ValidationPipe({
      disableErrorMessages: true,
      transform: true,
    })
  );
  const options = new DocumentBuilder().build();
  const documents = SwaggerModule.createDocument(app, options);
  build(documents);
  SwaggerModule.createDocument;
  SwaggerModule.setup("documents", app, documents);
  await app.listen(process.env.PORT || 3000);
}
bootstrap();
```

`redoc-cli`を利用しているのでそれだけ入れ忘れないようにしましょう。

もし入っていない場合は`yarn add redoc-cli`で導入できます。

> ただ、この設定を書くと何もしないアロー関数があるとかで eslint さんに怒られます。なんとかしたいです。

## まとめ

ここまでを全部くっつけたやつを[NestJS](https://github.com/MagiJS/NestJS)としてテンプレート化してみました。

自分のレポジトリがごちゃごちゃしてきたので NodeJS を使うものは分けたいところですね。

記事は以上。
