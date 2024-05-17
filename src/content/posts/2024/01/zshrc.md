---
title: .zshrcメモ 
published: 2024-01-11
description: No description
category: Programming
tags: [macOS]
---

## .zshrc

macOSの標準のターミナルを可能な限り便利に使いたいのでいろいろカスタマイズします。

### 求める機能

- 自動で`.nvmrc`でNodeJSのバージョンを合わせる
- 自動で`.env`で仮想環境に移行する
- Figの補完が効く
- Gitの補完が効く
- 現在のディレクトリの位置がわかる

今回の導入方法ではVSCodeで直接ディレクトリをひらいても仮想環境が適用されるので便利です。

### 導入

Fig, rbenv, nvmはHomebrewからインストールする。

Rubyを使わないならrbenv, ruby-buildに関しては不要。

```zsh
brew install nvm rbenv ruby-build fig
mkdir ~/.zsh
cd ~/.zsh
curl -o git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
curl -o git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
curl -o _git https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh
```

できたら`~/.zshrc`を編集する。

```zsh
# Fig
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"

# GIT
source ~/.zsh/git-prompt.sh
fpath=(~/.zsh $fpath)
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
autoload -Uz compinit && compinit

GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUPSTREAM=auto

setopt PROMPT_SUBST ; PS1='%F{green}devonly@TKG%f: %F{cyan}%c%f %F{red}$(__git_ps1 "(%s)")%f\$ '

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Load NVM
autoload -U add-zsh-hook
load-nvmrc() {
  if [[ -f .nvmrc && -r .nvmrc ]]; then
    nvm use
  elif [[ $(nvm version) != $(nvm version default)  ]]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# Load VENV 
autoload -U add-zsh-hook
load-pyenv() {
  if [[ -r .venv ]]; then
    source .venv/bin/activate
  elif [[ -n "$VIRTUAL_ENV" && $PWD != ${VIRTUAL_ENV%/*} && $PWD != ${VIRTUAL_ENV%/*}/* ]]; then
    deactivate
  fi
}
add-zsh-hook chpwd load-pyenv
load-pyenv

# Load Rbenv
[[ -d ~/.rbenv  ]] && \
  export PATH=${HOME}/.rbenv/bin:${PATH} && \
  eval "$(rbenv init -)"

# Fig
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"
```

最後に`source ~/.zshrc`として設定を読み込めば完了です。

> `autoload -U add-zsh-hook`についてはよくわかっていないので適当を書いているかもしれない......

記事は以上。