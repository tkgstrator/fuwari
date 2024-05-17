---
title: ERBFormatter/BeautifyをVSCodeで使うときの注意点
published: 2024-01-11
description: No description
category: Programming
tags: [macOS, VSCode, Ruby]
---

## ERBFormatter/Beautify

Rubyで書かれた`.erb`をフォーマットしてくれるという便利な拡張機能です。

Rubyはそもそも使わないんですが、ひょっとしたら使うかもしれないので書いておきます。

### 導入

[ここ](https://github.com/aliariff/vscode-erb-beautify)から導入します。

この拡張機能は内部的にhtmlbeautifierを使っているのでそれをインストールします。

> 以下、導入が随分前なので忘れているが主に[ここ](https://qiita.com/pokeneko/items/c80be1af2edb7698f248)と同じエラーが発生する

ただし`gem install htmlbeautifier`でインストールすると権限の問題などで実行できないときがあります。

> でも確認してみたら`Executable Path`は単純に`htmlbeautifier`が指定されていた...

一応、備忘録として普通に使えている現状の設定とかを残しておきます。

```zsh
$ which htmlbeautifier
/Users/tkgling/.rbenv/shims/htmlbeautifier

$ rbenv which htmlbeautifier
/Users/tkgling/.rbenv/versions/3.0.6/bin/htmlbeautifier

$ rbenv versions
  system
* 3.0.6 (set by /Users/tkgling/.rbenv/version)
```

また、`.zshrc`に以下を記入済み。

```zsh
[[ -d ~/.rbenv  ]] && \
  export PATH=${HOME}/.rbenv/bin:${PATH} && \
  eval "$(rbenv init -)"
```

VSCodeの設定は以下の通り。

```
Vscode-erb-beautify: Execute Path:
htmlbeautifier

Vscode-erb-beautify: Use Bundler:
チェックを外す
```


### 文字コード

`.vscode/settings.json`に以下を追記します.

```json
{
  "vscode-erb-beautify.customEnvVar": {
    "LC_ALL": "en_US.UTF-8"
  }
}
```

これをしておかないと日本語が含まれるコードがフォーマットできない。