---
title: 脱獄したiOSデバイスのrootパスワードを変更する 
published: 2024-01-09
description: No description
category: Programming
tags: [macOS, iOS, Jailbreak]
---

## 背景

デバイスのrootパスワードがわからなくなっちゃったときのメモ。

Rootlessで脱獄したときなどはパスワードを変えていないはずなのにfridaを使おうとするとパスワードが要求されたりする、謎。

## 変更方法

Sileoから以下の二つをインストールする。

- NewTerm
- gettext-localizations

インストールしたらNewTermを起動して以下のコマンドを実行。

いろいろ訊かれるので新しいパスワードを入力する。

デフォルトパスワードは`alpine`だと思う。

```zsh
sudo passwd root
```

終わったら`su`と入力してrootでログインできれば成功。

> [How to change the ROOT Password on a rootless Jailbreak (iOS 15 – iOS 17)](https://idevicecentral.com/jailbreak-guide/how-to-change-the-root-password-on-a-rootless-jailbreak-ios-15-ios-17/)
