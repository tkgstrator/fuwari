---
title: GitDocでコミット忘れを防ごう
published: 2025-03-05
description: つい熱が入りすぎてコミットとかプッシュ忘れることあるよね、私はあります。
category: Programming
tags: [Git, VSCode]
---

## 概要

`git commit`と`git push`を忘れすぎ問題、みんなあるよね、私はあります。

ガリガリにコードを書いているといつの間にかものすごい変更が入っていて、でも`git commit`を忘れていたから折角のgitの良さを無駄にしていること、ありますよね。

家でコードを書いていて、続きを別のところで書こうとしたらプッシュし忘れていて何がなんだかわからなくなること、ありますよね。

それらを全て解決してくれる`GitDoc`をご紹介します。

### [GitDoc](https://marketplace.visualstudio.com/items?itemName=vsls-contrib.gitdoc)

DevContainerでコードを書いている前提とします。

令和七年にもなってホストマシンでそのままコードを書いている人はいないと思いますが、一応断っておきます。

```json
"extensions": [
  "vsls-contrib.gitdoc"
]
```

`.devcontainer.json`にリモート環境の設定が書けるので、拡張機能を読み込むようにします。

```json
"settings": {
  "gitdoc.commitValidationLevel": "warning",
  "gitdoc.autoPull": "onPush",
  "gitdoc.ai.model": "gpt-4o",
  "gitdoc.enabled": true,
  "gitdoc.ai.enabled": true,
  "gitdoc.excludeBranches": [
    "master",
    "develop"
  ]
}
```

設定項目には上のように書きます。それぞれの項目について簡単に説明します。

- `gitdoc.commitValidationLevel`
  - PROBLEMSで警告以上が出力されていればコミットしません
  - 誤ったコードをコミットすることをある程度防げます
- `gitdoc.autoPull`
  - プッシュしたタイミングでプルします
- `gitdoc.ai.model`
  - `gpt-4o`, `o1-mini`などから選べるのですが何故か`o1-mini`だとうまく動かなかったのでデフォルトのものを使っています
- `gitdoc.enabled`
  - GitDocを有効にします
- `gitdoc.ai.model`
  - コミットメッセージをAIに考えてもらいます
- `gitdoc.excludeBranches`
  - これらのブランチではGitDocを無効化します
  - `master`や`develop`には直接コミットを許可しないので予め設定を入れておきます

で、これで概ね問題なく動くのですが`commitlint`などでコミットメッセージにルールを課している場合には困ります。

## commitlint

普段は英語でコミットメッセージを書いているのですが、日本語が良い方のために[【commitlint】commitlintとcommitizenの導入方法【commitizen】](https://qiita.com/P-man_Brown/items/d919bf4dbbc6ff49893c)から抜粋しておきます。

この方のテンプレートをyamlに変換したものが以下になります。

```yaml
---
extends:
- "@commitlint/config-conventional"
rules:
  header-max-length:
  - 2
  - always
  - 72
  type-enum:
  - 2
  - always
  - - build
    - ui
    - ci
    - docs
    - feat
    - fix
    - perf
    - chore
    - refactor
    - revert
    - format
    - test
prompt:
  messages:
    skip: "'Enterでスキップ'"
    max: 最大%d文字
    emptyWarning: 必須事項です
    upperLimitWarning: 最大文字数を超えています
  questions:
    type:
      description: 変更の種類を選択する
      enum:
        build:
          description: ビルドシステムや外部依存に関する変更
          title: Builds
        ci:
          description: CIの設定ファイルやスクリプトの変更
          title: Continuous Integrations
        chore:
          description: 補助ツールの導入やドキュメント生成などソースやテストの変更を含まない変更
          title: Chores
        docs:
          description: ドキュメントのみの変更
          title: Documentation
        feat:
          description: 新機能の追加
          title: Features
        fix:
          description: バグの修正
          title: Bug Fixes
        format:
          description: 動作に影響を与えないコードの書式などの変更
          title: Format
        perf:
          description: パフォーマンス向上を目的としたコードの変更
          title: Performance Improvements
        refactor:
          description: 新機能追加でもバグ修正でもないコードの変更
          title: Code Refactoring
        revert:
          description: コミットの取り消し
          title: Reverts
        test:
          description: テストの追加や変更
          title: Tests
        ui:
          description: スタイリングの追加や変更
          title: UI
    scope:
      description: 変更範囲を記述する
    subject:
      description: 変更内容を概括する
    body:
      description: 変更内容を詳述する(body:最大100文字)
    isBreaking:
      description: 破壊的変更はあるか
    breakingBody:
      description: 破壊的変更がある場合は必ず変更内容を詳説する
    breaking:
      description: 破壊的変更内容を詳述する(footer:最大100文字)
    isIssueAffected:
      description: 未解決のissuesに関する変更か
    issuesBody:
      description: issuesをcloseする場合は必ず変更内容の詳説する
    issues:
      description: 変更内容の詳説とissue番号を記載する(footer:最大100文字)
```

これを`.commitlintrc.yaml`で保存しておき、このルールに従うようにAIにコミットメッセージを書いてもらいます。

```json
"settings": {
  "gitdoc.commitValidationLevel": "warning",
  "gitdoc.autoPull": "onPush",
  "gitdoc.ai.model": "gpt-4o",
  "gitdoc.enabled": true,
  "gitdoc.ai.enabled": true,
  "gitdoc.excludeBranches": [
    "master",
    "develop"
  ],
  "gitdoc.ai.customInstructions": "Generate a commit message in Japanese following the Conventional Commits specification and `commitlint` rules. Use the format `<type>(<scope>): <short description>` and choose `<type>` from `build`, `ci`, `docs`, `feat`, `fix`, `perf`, `chore`, `refactor`, `revert`, `format`, `test`. Limit `<short description>` to 72 characters. If `<short description>` starts with an English word, it must be in lowercase.",
}
```

英語にしたいときは`Japanese`のところを`English`に変えるだけでいいと思います、多分。

AIがこのプロンプトに従わずにめちゃくちゃなコミットメッセージを書いてしまうとcommitlintが通らなくなってしまいますが、今のところ止まったことはないので多分大丈夫です。

### 有効化

デフォルトだとVSCodeのウィンドウを開くたびに無効化されるのでコマンドパレットから逐一有効化する必要があることだけが若干面倒です。

あと、デフォルトで有効化していると何故かEnabled→Disabled→Enabledという二回わざわざ切り替えないと有効にならない不思議な問題があります。

ここの問題さえ直れば個人的には嬉しい。

## まとめ

もうコミットメッセージに困らないし、コミットを忘れることもない。

記事は以上。
