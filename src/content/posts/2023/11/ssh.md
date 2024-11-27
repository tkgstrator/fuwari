---
title: 突然SSHが繋がらなくなっちゃった話
published: 2023-11-18
description: macOSからSSHが繋がらなくなっちゃった時の原因と解決法について
category: Tech
tags: [macOS, SSH]
---

## 背景

SSH が繋がらなくなっちゃった。

Linode で契約しているサーバーに、root とは異なるアカウント(tkgling)を作成しそのアカウントにログインを試みる。

```zsh
tkgling@xxx.xxx.xxx.xxx: Permission denied (publickey,password).
```

まず、~~パスワード認証はしていない~~と勘違いしていたので password と表示されるのが不可解。

### config

`~/.ssh/config`は以下の通り。

```zsh
Host LanPlay
  HostName xxx.xxx.xxx.xxx
  User tkgling

Host *
  UseKeychain yes
  AddKeysToAgent yes
  PreferredAuthentications publickey
  IdentityFile ~/.ssh/id_ed25519
```

#### ログインできない理由

Linode はインスタンス作成時に何故か root でかつパスワードログインができる、かつ公開鍵認証が無効化されているという謎仕様になっている。

なので`Host *`に対して`PreferredAuthentications publickey`の設定が有効化されていると詰んでしまうというわけです。

公開鍵認証が無効化されているのは意味がわからないので、パスワード認証を無効化した上で公開鍵認証を有効化しましょう。

### 認証方式

うちの環境では作成する鍵は全て`id_ed25519`なので以下のコマンドをホストマシンから入力する。よくわかっていないが、指定された公開鍵を指定されたサーバーにログインして登録するコマンドっぽい。

```zsh
ssh-copy-id -i ~/.ssh/id_ed25519 tkgling@xxx.xxx.xxx.xxx
```

するとパスワード入力後に鍵が登録される。

できたら`sudoedit /etc/ssh/sshd_config`で SSH 接続設定を変更します。変更しないと脆弱なままなので注意。

```zsh
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
```

のように変更をかければパスワード認証がオフになります。

`systemctl restart sshd`で設定を反映させましょう。

> macOSの場合は`sudo launchctl kickstart -k system/com.openssh.sshd`でいけます

[Linode で仮想マシンを作ったらまずやること](https://qiita.com/tarooishi/items/5f8ec51323eeed919818)のように StackScripts を作成してしまっても良いです。

`sudo apt install sshguard`を入れておくとログイン試行してくる人を BAN できるのでより安全になります。

記事は以上。
