---
title: macOSの最新版でGPG署名に失敗する話
published: 2024-12-09
description: macOSを最新版にするとGPG署名によく失敗するので備忘録として残しておきます
category: Tech
tags: [GPG, macOS]
---

## 概要

macOS 15.0.1+DevContainerを利用しているとたまにGPG署名ができなくなってしまう状況になりました。

```zsh
```

いま、ログがどっかいったのでないのですがスペースとしておいておきます。

### 対応方法

GPGのエージェントがおかしいっぽいので直します。

```zsh
enable-ssh-support
pinentry-program /opt/homebrew/bin/pinentry-mac
```

`enable-ssh-support`はつけていても問題なかったのでつけています。

Keychainからパスワードを引っ張ってくるための設定として`pinentry-program`のパスは`which pinentry-mac`で取ってきた値を突っ込みます。

最後に`gpgconf --launch gpg-agent`と入力して`gpg-agent`を再起動します。

あ、ここまでの話は全部ホストマシンでやります。

最後にDevContainerを再起動すればちゃんと署名できるようになっていると思います、多分。
