---
title: DevContainerでのWranglerの問題解決した 
published: 2024-10-01
description: DevContainerでWranglerを使ってHonoのAPIを立てると繋がらない問題が解決
category: Programming
tags: [TypeScript, Bun, Cloudflare, Wrangler]
---


## 結論

```toml
[dev]
ip = "0.0.0.0"
port = 8787
```

を`wrangler.toml`に書く。

portの部分は外に出したいポートであれば何でもOK。

新しいバージョンだと新機能が使えたりするので便利です。特に理由がなければバージョンは最新のものにしましょう。

## DevContainer

ついでにDevContainerの設定もちょっと見直してみました。

ベースのイメージでBunを使うと`stdin_open`や`tty`周りの設定をしていないとコンテナが落ちてしまうという問題があったのでNodeをベースモデルに変更します。

適当なNodeのモデルでもいいのですがDevContainer用に最適化された`mcr.microsoft.com`のものがあるのでそれを使います。

### Dockerfile

```dockerfile
FROM mcr.microsoft.com/devcontainers/javascript-node:22-bullseye
```

とりあえずこれを書いたらNode 22.9.0がインストールされました。

### docker-compose.yaml

```yaml
services:
  node:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - 8787:8787
    volumes:
      - node_modules:/home/vscode/app/node_modules
      - ../:/home/vscode/app:cached

volumes:
  node_modules:
```

MCRのイメージはユーザーが`vscode`で設定されているのでそれを利用します。デフォルトで`root`以外のユーザーがあるのはやはり安心感があります。

### devcontainer.json

```json
{
  "name": "Hono",
  "dockerComposeFile": [
    "docker-compose.yaml"
  ],
  "service": "node",
  "workspaceFolder": "/home/vscode/app",
  "shutdownAction": "stopCompose",
  "remoteUser": "vscode",
  "mounts": [
    "source=${env:HOME}/home/vscode/.ssh,target=/.ssh,type=bind,consistency=cached,readonly"
  ],
  "features": {
    "ghcr.io/devcontainers/features/git:1": {
      "version": "2.37.0"
    },
    "ghcr.io/shyim/devcontainers-features/bun:0": {},
    "ghcr.io/devcontainers/features/common-utils:2": {
      "configureZshAsDefaultShell": true
    },
    "ghcr.io/devcontainers/features/docker-outside-of-docker:1": {
      "moby": false,
      "dockerDashComposeVersion": "v2"
    },
    "ghcr.io/dhoeric/features/act:1": {}
  },
  "postAttachCommand": "/bin/sh .devcontainer/postAttachCommand.sh",
  "postCreateCommand": "/bin/sh .devcontainer/postCreateCommand.sh",
  "customizations": {
    "vscode": {
      "extensions": [
        "EditorConfig.EditorConfig",
        "GitHub.copilot",
        "GitHub.copilot-chat",
        "PKief.material-icon-theme",
        "antfu.file-nesting",
        "biomejs.biome",
        "eamodio.gitlens",
        "ms-vscode.vscode-typescript-next",
        "tamasfe.even-better-toml",
        "amazonwebservices.codewhisperer-for-command-line-companion",
        "bierner.markdown-preview-github-styles",
        "bierner.markdown-mermaid",
        "jebbs.markdown-extended"
      ],
      "settings": {
        "betterTypeScriptErrors.prettify": true,
        "debug.internalConsoleOptions": "neverOpen",
        "diffEditor.diffAlgorithm": "advanced",
        "diffEditor.experimental.showMoves": true,
        "diffEditor.renderSideBySide": false,
        "editor.formatOnPaste": true,
        "editor.guides.bracketPairs": "active",
        "editor.codeActionsOnSave": {
          "quickfix.biome": "explicit",
          "source.organizeImports.biome": "explicit"
        },
        "editor.formatOnSave": true,
        "files.watcherExclude": {
          "**/node_modules/**": true
        },
        "scm.defaultViewMode": "tree",
        "[javascript]": {
          "editor.defaultFormatter": "biomejs.biome"
        },
        "[javascriptreact]": {
          "editor.defaultFormatter": "biomejs.biome"
        },
        "[typescript]": {
          "editor.defaultFormatter": "biomejs.biome"
        },
        "[typescriptreact]": {
          "editor.defaultFormatter": "biomejs.biome"
        },
        "[json]": {
          "editor.defaultFormatter": "biomejs.biome"
        },
        "[jsonc]": {
          "editor.defaultFormatter": "biomejs.biome"
        }
      }
    }
  }
}
```

細かい設定は適当ですがインストールするgitのバージョンは2.37.0以降がオススメです。

Bunのインストールは現在拡張機能がバージョン指定に対応していないのでこうなっています。

### postAttachCommand.sh

```zsh
#!/bin/zsh

git config --global --add safe.directory /home/vscode/app
git config --global --unset commit.template
git config --global fetch.prune true
git config --global --add --bool push.autoSetupRemote true
git config --global commit.gpgSign true
git branch --merged|egrep -v '\*|develop|main|master'|xargs git branch -d
```

立ち上げるたびにマージ済みの余計なブランチを削除します。人によっては不要な設定なのでそこは消してください。


### postCreateCommand.sh

```zsh
#!/bin/zsh

sudo chown -R vscode:vscode node_modules
bun install --frozen-lockfile
```

コンテナ作成時に`bun install`を実行します。`node_modules`のディレクトリがnamed volumesを使っているので所有権を変更しないと何もインストールできません。

## まとめ

やっとWranglerの最新バージョンが使えるようになったので心が安らかになりました。

Wranglerのオプションにはまだまだたくさんいろんなものがあるので調べてみたいと思います。