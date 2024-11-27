---
title: commitlint+huskyでgitのコミットメッセージ問題から解消されよう
published: 2024-02-13
description: そろそろコミットメッセージで悩むのはやめにしませんか 
category: Programming
tags: [Git]
---

## 背景

ESLintやPrettierでファイルはちゃんとフォーマットしているのにコミットメッセージは人によってめちゃくちゃだったりします。

ルールも決まっていないと後から読み返したときに何をしたんだこれとなるのですが、とはいえ毎回「どんなルールだったっけ」とプロジェクトごとに見返すのもめんどくさいです。

あと、コミットしてから「あ、フォーマットするの忘れてた」となって再コミットするのもダサいです。

これらを全て解決する方法が求められていました。

### [Husky](https://typicode.github.io/husky/)

huskyはgitで何らかの操作を行った際に割り込んで処理が行える仕組みを提供します。

例えば、コミットする際には`git commit`が実行される前に`yarn lint`や`yarn test`を実行するなどといった操作ができるようになります。

こうすればコミットされた内容はCIでのテストをパスすることが保証されるようになります。

この仕組みの便利なところはESLintとPrettierの基準を満たすかどうかをチェックしているのではなく、実際にこの時点で整形してくれることにあります、とても便利。

とはいえテストが通らないコミットができないのは困るので、テスト自体は通らなくても良いですがESLintとPrettierの整形は通って欲しい感じになります。

[Husky](https://typicode.github.io/husky/)はつい最近アップデートがあったようで、使い方が大きく変更されています。ネットで検索しても違うコマンドが載っていたりして困ります。

#### 導入

プライベートレポジトリでないなら以下の二つをインストールします。

```zsh
yarn add -D husky pinst
yarn husky init
```

> プライベートの場合は`pinst`は不要のようです

`yarn husky init`については不要かもしれませんが、一応実行しました。

これで`package.json`の`scripts`に`"prepare": "husky"`が追加されていればOKです。

```zsh
.
├── .husky/
│   ├── _/
│   └── pre-commit
└── package.json
```

この時点で上のような構成になっていると思います。

### [lint-staged](https://github.com/lint-staged/lint-staged)

コミット前にESLintを実行させることができます。

```zsh
yarn add -D lint-staged
```

としてパッケージを追加し`.lintstagedrc.yaml`を作成します。

```yaml
---
'**/*.ts':
  - yarn lint
  - yarn format
```

こう書くとコミット内容に`.ts`のファイルがあれば`yarn lint`と`yarn format`を実行してくれます。

最後にこの処理が`git commit`が実行される前に実行されてほしいので`.husky/pre-commit`を編集します。

```zsh
yarn test
yarn lint-staged
```

> ここの`yarn test`は必ずしも必要ではない、大事なのは`yarn lint-staged`が実行されること

```zsh
.
├── .husky/
│   ├── _/
│   └── pre-commit
├── .lintstagedrc.yaml
└── package.json
```

するとこんな感じになると思います。

### [commitlint](https://github.com/conventional-changelog/commitlint)

commitlintはコミットメッセージが`.commitlintrc.yaml`に設定されたルールに則っているかをチェックするパッケージです。

```zsh
yarn add -D @commitlint/cli @commitlint/config-conventional
```

インストールができたら`.commitlintrc.yaml`を作成します。

```yaml
---
extends:
  - '@commitlint/config-conventional'
```

今回は特に何も入れていませんが、ここに[プロジェクトごとのルール](https://github.com/conventional-changelog/commitlint/blob/master/docs/reference-rules.md)を追記することができます。

最後にコミットメッセージを書き込んだ後にチェックを行うので`.husky/commit-msg`のファイルを作成します。

```zsh
yarn commitlint --edit ${1}
```

こうすれば最後のコミットメッセージを読み込んで`commitlint`が実行されます。

```zsh
.
├── .husky/
│   ├── _/
│   ├── commit-msg
│   └── pre-commit
├── .commitlintrc.yaml
├── .lintstagedrc.yaml
└── package.json
```

するとここまでのファイル構成はこうなります。

実際にどんな挙動をするか確かめたい場合は`commit-msg`の最後に`exit 1`を入れれば必ず失敗するので実際にコミットログが作成されません。

その状態で`git commit -m "testing pre-commit code"`みたいな感じで実行すればどうなるかがわかります。

正常に動作していればcommitlintがエラーを返すはずです。

もしcommitlintがちゃんと動いていないようであればHuskyがhookに失敗しているので`yarn install`で`husky`をインストールしてください。

### [cz-commitlint](https://github.com/conventional-changelog/commitlint/tree/master/@commitlint/cz-commitlint)

cz-commitlintはcommitlintの拡張で、対話式でコミットメッセージが作成できるパッケージです。

commitlintと組み合わせて入力ミスを防ぎつつ、フォーマットに則ったコミットメッセージが書けます。

```zsh
yarn add -D @commitlint/cz-commitlint commitizen
```

> エラーが発生する場合は`inquirer@8`もインストールしてください

インストールが完了したら`package.json`を編集して、

```json
{
  "scripts": {
    "commit": "git-cz"
  },
  "config": {
    "commitizen": {
      "path": "@commitlint/cz-commitlint"
    }
  }
}
```

を追記します。こうすると`yarn commit`で対話式のコミットメッセージが書けます。

#### git commit

とはいえ`git commit`に慣れているので、このコマンドを実行したときにも`yarn commit`と同様の効果が得られてほしいです。

そこで`.husky/prepare-commit-msg`を作成して以下の内容を書き込みます。

```zsh
exec < /dev/tty && yarn cz --hook || true
```

これは`yarn cz`を実行してその結果がtrueであれば`exec 0`を返すコードです。

Huskyは0以外の値を返すとエラーとしてコミットがなかったことになります。

> `tty`を入れないと対話式にならない(何も入力できない)

```zsh
├── .husky/
│   ├── _/
│   ├── prepare-commit-msg
│   ├── commit-msg
│   └── pre-commit
├── .commitlintrc.yaml
├── .lintstagedrc.yaml
└── package.json
```

最終的にファイルの構成は上のようになります。

これでコミットメッセージに悩まされる日々から無事に開放されました、やったね。

> でもこのレポジトリにはこの機能を実装していないという矛盾(おい

記事は以上。