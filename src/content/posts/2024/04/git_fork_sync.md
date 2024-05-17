---
title: GitでFork元の変更を取り込む方法 
published: 2024-04-06
description: いつも忘れるのでメモすることにしました 
category: Tech
tags: [GitHub]
---

## 概要

このブログは元々のコードは[fuwari](https://github.com/saicaca/fuwari)で開発されています。

まだまだ開発段階ではあるものの、それなりに修正などが入っているため一ヶ月に一回くらいはフォーク元の変更を取り込んで自分のレポジトリに反映させたいです。

で、それをどうやってやるのかいつも忘れるのでメモします。

### リモートの追加

まず、フォーク元のリポジトリを`upstream`という名前で追加します。

ここの名前はぶっちゃけるとなんでもいいです。

```zsh
$ git remote add upstream https://github.com/saicaca/fuwari.git
```

追加できると、

```zsh
$ git branch -a
* feature/tkgling
  main
  master
  remotes/origin/HEAD -> origin/main
  remotes/origin/feature/tkgling
  remotes/origin/main
  remotes/origin/master
  remotes/upstream/demo
  remotes/upstream/giscus
  remotes/upstream/main
  remotes/upstream/toc
```

のように表示されます。

### 変更取り込み

```zsh
$ git fetch upstream
```

でフォーク元の最新のコミットを取得します。

### リベース

マージする方もいると思うのですが、個人的にはリベース派なのでこれを利用します。

現在、記事を書いているブランチは`feature/tkgling`なのでここに差分を取り込みます。

```zsh
$ git rebase upstream/master feature/tkgling
```

最後にコンフリクトを解消してプッシュします。

お疲れ様でした。

記事は以上。