---
title: Homebrewが別ユーザーでPermission deniedになる問題 
published: 2024-03-30
description: Homebrewをいろんなアカウントで使いたいよねという問題に対応 
category: Tech
tags: [Homebrew, macOS]
---

## 概要

Homebrewを別アカウントで利用しようとするとディレクトリに書き込みができずに失敗してしまう。

以下、簡単な対応方法。

```zsh
sudo chgrp -R admin /opt/homebrew
sudo chmod -R g+w /opt/homebrew
```

adminグループが`/opt/homebrew`へのアクセス権限を持つようにする。

当然、利用したい別ユーザーはadmin権限を持っておくこと。

> このコマンドはApple Silicon向けでIntel macだとhomebrewのインストール先が違ったような気もする

`which brew`でどこにインストールされるかはチェックしておこう。

記事は以上。