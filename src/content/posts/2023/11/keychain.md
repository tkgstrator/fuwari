---
title: SSH接続時に毎回パスフレーズを入力するのを省略する
published: 2023-11-16
description: macOSでSSH秘密鍵にパスフレーズが設定してあると毎回入力を求められるのでその対策
category: Tech
tags: [macOS, SSH]
---

## 背景

SSH の秘密鍵作成時にパスフレーズを設定していると、ありとあらゆる入力のタイミングでパスフレーズを要求されます。

これが地味にめんどくさかったので信頼しているデバイスからはパスフレーズを自動で入力してくれるようにする設定を入れます。正確にはパスフレーズを Keychain から読み出しているみたいなので自動入力しているわけではないです。

### 技術

必要な処理は以下の二つ。

1. Keychain にパスフレーズを保存する
2. パスフレーズ要求時に Keychain から自動で読み出す

それについては[macOS で再起動しても ssh agent に秘密鍵を保持させ続ける二つの方法](https://qiita.com/sonots/items/a6dec06f95fca4757d4a)で簡単に紹介されていて大体これで間違っていないのですが少し補足説明を入れます。

まず、`-K`と`-A`のオプションは既に非推奨となっており、入力すると以下のように警告が表示されます。

```zsh
WARNING: The -K and -A flags are deprecated and have been replaced
         by the --apple-use-keychain and --apple-load-keychain
         flags, respectively.  To suppress this warning, set the
         environment variable APPLE_SSH_ADD_BEHAVIOR as described in
         the ssh-add(1) manual page.
```

なので、本来入力すべきコマンドは、

```zsh
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

となります。これをすると`~/.ssh/id_ed25519`のパスフレーズが Keychain に追加されます。今日のご時世に ED25519 以外のデジタル署名アルゴリズムを使っている人はいないと思うのでこれで大丈夫です。

パスフレーズを Keychain に登録したあとはこれを SSH 接続時に読み込むようにします。

なので`~/.ssh/config`を編集します。

```zsh
Host GitHub
  HostName github.com
  User XXXXXXXX
  IdentityFile ~/.ssh/id_ed25519

Host *
  UseKeychain yes
  AddKeysToAgent yes
```

のようにすれば任意の接続先に対して Keychain に保存されているパスフレーズを利用し、GitHub への SSH 接続に対して`id_ed25519`を利用するように設定できます。

記事は以上。
