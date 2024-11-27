---
title: Gitコマンドをより便利に利用する
published: 2021-07-14
description: ターミナルでGitコマンドの補完が効くようにするための方法です
category: Programming
tags: [Git]
---

# Git のコマンドをより便利にする

Git は便利なのだが、Tab キーでブランチ名が補完できないので長い名前にしていると入力ミスなどが発生する。

Sourcetree などの GUI ツールを使っていればそういうことは発生しないのだが、ターミナルでも便利に使えるようにしたいわけである。

執筆にあたり[【zsh】絶対やるべき！ターミナルで git のブランチ名を表示&補完【git-prompt / git-completion】](https://qiita.com/mikan3rd/items/d41a8ca26523f950ea9d)がとても参考になりました。

## git-prompt

`git-prompt`という便利なツールがあるのでそれを導入する。以下のコマンドを一括でコピペしてターミナルに貼り付けて実行すれば良い。

```sh
mkdir ~/.zsh
cd ~/.zsh

curl -o git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
curl -o git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
curl -o _git https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh
```

### .zshrc の編集

```sh
# git-promptの読み込み
source ~/.zsh/git-prompt.sh

# git-completionの読み込み
fpath=(~/.zsh $fpath)
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
autoload -Uz compinit && compinit

# プロンプトのオプション表示設定
GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUPSTREAM=auto

# プロンプトの表示設定(好きなようにカスタマイズ可)
setopt PROMPT_SUBST ; PS1='%F{green}%n@%m%f: %F{cyan}%~%f %F{red}$(__git_ps1 "(%s)")%f
\$ '
```

最後に`source ~/.zshrc`として設定を読み込んでやれば良い。

### パーミッションの変更

ターミナルの起動時にパーミッションエラーで怒られる可能性があるので、以下のコマンドでディレクトリにパーミッションを与えておくと良い。

```sh
chmod 755 /usr/local/share/zsh/site-functions
chmod 755 /usr/local/share/zsh
```


