---
title: Gitのやってはいけないコマンド集
published: 2024-08-30
description: でもやってはいけないコマンドってやりたくなるよね
category: Tech
tags: [GitHub, Git]
---

## Git

### Push

#### setupstream

```zsh
git config --global --add --bool push.autoSetupRemote true
```

初回に`git push -u origin xxxxx/yyyyy`というコマンドを打たなくて良くなる、健康によい。

### 歴史修正

#### Force Push

```zsh
git push -f
```

前の変更をなかったことにする魔法。

### Filter Branch

```zsh
git filter-branch -f --commit-filter 'git commit-tree -S "$@";' HEAD
```

俺様の署名で全部上書きする魔法。

```zsh
git filter-branch -f --env-filter "GIT_AUTHOR_NAME='$(git config --get user.name)'; GIT_AUTHOR_EMAIL='$(git config --get user.email)'; GIT_COMMITTER_NAME='$(git config --get user.name)'; GIT_COMMITTER_EMAIL='$(git config --get user.email)'; git commit-tree -S "$@";" HEAD
```

コミットのメールアドレスとユーザー名を全部自分に書き換える魔法。

### ブランチ削除

#### マージ済みブランチ削除

```zsh
git branch --merged|egrep -v '\*|develop|main|master'|xargs git branch -d
```

`develop`でも`main`でも`master`でもなければすべて消えます。

ローカルしか消さないのでこれは優しい。

> [Gitでマージ済みブランチを一括削除](https://qiita.com/hajimeni/items/73d2155fc59e152630c4)

```zsh
git branch --remotes --merged | grep -v "origin/main" | sed -E 's/  origin\/(.*)/\1/' | xargs -I{} git push origin :{}
```

リモートも削除する力がほしいという方はこちらをどうぞ。

> [【GitHub】 マージ済みのremote branchを一括削除するコマンド](https://blog.pinkumohikan.com/entry/bulk-remove-remote-branches-on-github)

#### リモートにないブランチ削除

```zsh
git fetch --prune
```

常に有効にしたければ、

```zsh
git config --global fetch.prune true
```

としてあげるとよい。

## まとめ

これらを`postAttachCommand.sh`に書くとDevContainerを立ち上げるたびにレポジトリが浄化される。

> 書くことを推奨しているわけではない

ついでにGPGキーもあれば設定してくれる優しい設計、複数あるとおかしくなる問題はあるが。

```zsh
git config --global --unset commit.template
git config --global --add safe.directory /home/bun/app
git config --global fetch.prune true
git config --global --add --bool push.autoSetupRemote true
git branch --merged|egrep -v '\*|develop|main|master'|xargs git branch -d
git branch --remotes --merged | grep -v "origin/main" | sed -E 's/  origin\/(.*)/\1/' | xargs -I{} git push origin :{}

if gpg --list-secret-keys | grep -q 'sec'; then
  GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | awk '/sec/{print $2}' | cut -d'/' -f2)
  git config --global user.signingkey $GPG_KEY_ID
  git config --global commit.gpgSign true
fi
```