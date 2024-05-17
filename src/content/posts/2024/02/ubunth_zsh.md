---
title: Ubuntuでzshを使おう
published: 2024-02-10
description: デフォルトではbashですがmacOSに慣れているのでzshを利用することにしました 
category: Tech
tags: [Ubuntu, Homebrew, zsh]
---

## 概要

Ubuntuの使い勝手を良くしていきます。

### zshへの切り替え

```zsh
sudo apt install zsh -y
chsh
```

パスワード入力を求められたら`/usr/bin/zsh`と入力する。

### Homebrewの導入

```zsh
sudo apt install -y build-essential procps curl file git
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

エンターを押すとインストールが始まる。終わったら以下のコマンド入力。

```zsh
(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /home/mini/.zshrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
```

### Node Version Manager

```zsh
brew install nvm
```

でインストールが始まる。

```zsh
mkdir ~/.nvm
export NVM_DIR="$HOME/.nvm"
[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"  # This loads nvm
[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
```

とすれば反映される。

### Git

```zsh
mkdir ~/.zsh
cd ~/.zsh
curl -o git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
curl -o git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
curl -o _git https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh
```

現在いるブランチとかが表示される、便利。

## 最後に

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

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"
[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm"

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

これで変更が効かないときは`exec zsh`を実行すると良い。

> [Ubuntu Zsh (via Vagrant) is not locating Zsh or its functions](https://stackoverflow.com/questions/25997617/ubuntu-zsh-via-vagrant-is-not-locating-zsh-or-its-functions)