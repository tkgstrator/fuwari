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
error: gpg failed to sign the data
fatal: failed to write commit object
```

いま、ログがどっかいったのでないのですがスペースとしておいておきます。

### 対応方法

GPGのエージェントがおかしいっぽいので直します。

`~/.gnupg/gpg-agent.conf`を編集します。

```zsh
enable-ssh-support
pinentry-program /opt/homebrew/bin/pinentry-mac
```

`enable-ssh-support`はつけていても問題なかったのでつけています。

Keychainからパスワードを引っ張ってくるための設定として`pinentry-program`のパスは`which pinentry-mac`で取ってきた値を突っ込みます。

最後に、

```zsh
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent
```

と入力して`gpg-agent`を再起動します。ただ設定を読み込み直すだけでダメっぽいです。

あ、ここまでの話は全部ホストマシンでやります。

最後にDevContainerを再起動すればちゃんと署名できるようになっていると思います、多分。

### ロックされている場合

```zsh
$ gpg --list-keys --keyid-format LONG
gpg: Note: database_open 134217901 waiting for lock (held by 3142) ...
```

みたいな不穏なメッセージが出るときに使います。

とりあえず原因がわからないので毎回`~/.gnupg`をふっとばしています。

```zsh
$ rm -rf ~/.gnupg
$ gpgconf --kill gpg-agent
$ gpgconf --launch gpg-agent
$ vi ~/.gnupg/gpg-agent.conf
```

として

```zsh
enable-ssh-support
pinentry-program /opt/homebrew/bin/pinentry-mac
```

を書いて保存し、このままだと鍵がないので、

```zsh
$ gpg --import private.key
```

で鍵をインポートしたあと、

```zsh
$ gpg --edit-key GPG_KEY_ID
```

で対話形式で鍵を変更し、信頼するようにします。

```zsh
trust
5
```

と入力して全面的に鍵を信頼するように変更したら`quit`で保存して終了します。

最後に、

```zsh
$ gpgconf --kill gpg-agent
$ gpgconf --launch gpg-agent
```

でgpg-agentを再起動します。この状態でDevContainerを開き直せば署名ができるようになっていると思います、多分。　




