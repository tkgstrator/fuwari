---
title: GitHubでをより便利にする備忘録
published: 2024-08-30
description: GitHubの設定を忘れてしまうのでメモしておきます
category: Tech
tags: [GitHub, Git]
---

## GitHub

いろいろ設定があるのですが、いつも忘れてしまうので覚えておきます。

### Rulesets

ルールセットはブランチプロテクションの新バージョンみたいな感じです。主に`master`ブランチと`develop`ブランチに対してルールを設定しましょう。


| ルール                                           | master | develop | 
| :----------------------------------------------: | :----: | :-----: | 
| Block force pushes                               | ✔     | ✔      | 
| Restrict deletions                               | ✔     | ✔      | 
| Require a pull request before merging            | ✔     | ✔      | 
| Require signed commits                           | ✔     | -       | 
| Require status checks to pass                    | ✔     | -       | 
| Require branches to be up to date before merging | ✔     | -       | 

設定はこんな感じで大丈夫です。

### PR Agent

現在、管理しているほぼ全てのレポジトリにChatGPTを利用して自動でコードレビューをしてくれるPR Agentを導入しています。

`gpt-4o-mini`がめちゃくちゃ安い上に`gpt-4`と同程度に賢い上に速いので愛用しています。

とりあえず自分は以下のような`.pr_agent.toml`をプロジェクトのルートにおいています。

```toml
[github_app]
handle_pr_actions = [
  'opened',
  'reopened',
  'ready_for_review',
  'review_requested',
]
pr_commands = [
  '/describe --pr_description.final_update_message=false',
  '/review --pr_reviewer.num_code_suggestions=0',
]
handle_push_trigger = true
push_commands = ['/describe', '/review --pr_reviewer.num_code_suggestions=0']

[pr_code_suggestions]
max_context_tokens = 10000
num_code_suggestions = 4

[pr_description]
auto_describe = true
auto_improve = true
auto_review = true
collapsible_file_list = true
enable_semantic_files_types = true
generate_ai_title = false
include_generated_by_header = true
inline_file_summary = true
use_description_markers = true

[pr_reviewer]
require_score_review = true
require_tests_review = true
num_code_suggestions = 0
inline_code_comments = true

[config]
verbosity_level = 2
model = 'gpt-4o-mini'
model_turbo = 'gpt-4o-mini'
fallback_models = ['gpt-4o-mini']
```

ついでにこれをGitHub Actionsで実行します。プッシュするたびに実行していると流石にお金がかかりすぎるのでプルリクエストが更新されるたびに実行されるようにします。

```yaml
name: Code Review
on:
  pull_request:
    types: [opened, reopened, ready_for_review, synchronize]
  issue_comment:
    types: [created, edited]
  workflow_dispatch:

jobs:
  pr_agent_job:
    name: Code review
    if: ${{ github.event.sender.type != 'Bot' }}
    runs-on: ubuntu-24.04
    permissions:
      issues: write
      pull-requests: write
      contents: write
    steps:
      - name: Review
        id: pragent
        uses: Codium-ai/pr-agent@main
        env:
          CONFIG.MODEL: gpt-4o-mini
          GITHUB_ACTION.AUTO_DESCRIBE: true
          GITHUB_ACTION.AUTO_IMPROVE: true
          GITHUB_ACTION.AUTO_REVIEW: true
          GITHUB_ACTION.PR_DESCRIPTION.USE_DESCRIPTION_MARKERS: true
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          OPENAI_KEY: ${{ secrets.OPENAI_KEY }}
          PR_DESCRIPTION.EXTRA_INSTRUCTIONS: Please use Japanese in descriptions. Titles should have prefix of commitlint pattern such as `feat:`, `fix:`, `perf:`, `refactor:`, `test:`, `chore:`, `ci:`, `docs:` etc
          PR_DESCRIPTION.USE_DESCRIPTION_MARKERS: true
          PR_REVIEWER.EXTRA_INSTRUCTIONS: Please use Japanese in descriptions.
```

`CONFIG.MODEL`はこれで書き方あっているのかわからないですが、とりあえずこれを書いています。

日本語にしたい場合には`EXTRA_INSTRUCTIONS`を書いてあげましょう。

### Continuous Integration

コードの品質を保証するために必要な継続的インテグレーションです。

1. コミットメッセージがちゃんと規則に従っているか
2. ロックファイルが一致しているか
3. フォーマットして差分が発生しないか

を調べています。プッシュされるたびに実行されますが、軽い処理が多いのですぐに終わります。

```yaml
name: Continuous Integration
on:
  push:

jobs:
  lockfile:
    name: Lockfile
    runs-on: ubuntu-24.04
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Bun
        uses: oven-sh/setup-bun@v2
        with:
          bun-version: latest
      - name: Install
        run: |
          bun install --frozen-lockfile --ignore-scripts
  commitlint:
    name: CommitLint
    if: github.event.action != 'closed' || github.event.pull_request.merged != true
    runs-on: ubuntu-24.04
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Bun
        uses: oven-sh/setup-bun@v2
        with:
          bun-version: latest
      - name: Install commitlint
        run: |
          bun install conventional-changelog-conventionalcommits
          bun install commitlint@latest
      - name: Validate current commit (last commit) with commitlint
        if: github.event_name == 'push'
        run: bunx commitlint --last --verbose
      - name: Validate PR commits with commitlint
        if: github.event_name == 'pull_request'
        run: bunx commitlint --from ${{ github.event.pull_request.head.sha }}~${{ github.event.pull_request.commits }} --to ${{ github.event.pull_request.head.sha }} --verbose
  check:
    name: Code Check
    runs-on: ubuntu-24.04
    if: github.event.action != 'closed' || github.event.pull_request.merged != true
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Bun
        uses: oven-sh/setup-bun@v2
        with:
          bun-version: latest
      - name: Format
        run: |
          bunx @biomejs/biome format src
      - name: Lint
        run: |
          bunx @biomejs/biome lint src
```

### Continuous Development

継続的デリバリーで自動的に更新されるようにしましょう。

以前はDocker Hubなどを利用することも多かったのですが最近は基本的にGitHubだけを利用するようになりました。

例外があるとしたらCloudflare Workersくらいでしょうか。サーバーレス、とても便利。

1. GitHub Container Registry
2. GitHub Package Registry
3. GitHub Release
4. Cloudflare Workers

よって、自分が使うデプロイ先は上の四つです

#### Container Registry

マージが完了したときにデプロイするWorkflowです。

```yaml
name: Deploy to Container Registry
on:
  pull_request:
    types: [closed]

jobs:
  deploy:
    name: Deploy to Container Registry
    runs-on: ubuntu-20.04
    if: github.event.pull_request.merged == true
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.merge_commit_sha }}
      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Cache Docker layers
        uses: actions/cache@v4
        with:
          path: /tmp/.buildx-cache
          key: ${{ github.ref }}-${{ github.sha }}
          restore-keys: |
            ${{ github.ref }}-${{ github.sha }}
            ${{ github.ref }}
            refs/head/main
      - name: Set up Docker Buildx
        id: buildx
        uses: docker/setup-buildx-action@v3
      - name: Get Version
        id: current_version
        run: |
          echo "version=$(cat package.json | jq -r '.version')" >> $GITHUB_OUTPUT
      - name: Create tag
        id: current_time
        run: echo "date=$(date +'%Y%m%d')" >> $GITHUB_OUTPUT
      - name: Build and Push Docker Image
        id: docker_build
        uses: docker/build-push-action@v6
        with:
          context: ./
          file: ./Dockerfile
          builder: ${{ steps.buildx.outputs.name }}
          platforms: linux/amd64,linux/arm64
          push: true
          tags: |
            ghcr.io/${{ github.repository }}:${{ steps.current_version.outputs.version }}
            ghcr.io/${{ github.repository }}:${{ steps.current_time.outputs.date }}
            ghcr.io/${{ github.repository }}:latest
          cache-from: type=local,src=/tmp/.buildx-cache
          cache-to: type=local,dest=/tmp/.buildx-cache
```

キャッシュを有効にしていますが、どのくらい効果があるのかは謎です。

NodeJSを前提としているのでバージョンを`package.json`から取得していますが、Pythonの場合はpoetryなどを利用してください。

#### Package Registry

#### Release

`actions/create-release@v1`とかが既にアーカイブになっているのでちょっと不安になります。

ファイル名などをハードコードで指定しているのでそのままは使えないのですが、大体以下のような感じで書けばいけます。

```yaml
name: Deploy to Release
on:
  pull_request:
    types: [closed]

jobs:
  deploy:
    name: Deploy
    runs-on: ubuntu-20.04
    if: github.event.pull_request.merged == true
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.merge_commit_sha }}
      - name: Install
        if: ${{ github.event.head.user.login == 'act' }}
        run: |
          apt-get update
          apt-get install -y unzip zip jq
      - name: Bun
        uses: oven-sh/setup-bun@v2
        with:
          bun-version: latest
      - name: Install and Build
        run: |
          bun install --frozen-lockfile --ignore-scripts
          bun run build
      - name: Create ZIP
        run: |
          mkdir -p output
          zip -r output/artifacts.zip dist/
      - name: Get Version
        id: current_version
        run: |
          echo "version=v$(cat package.json | jq -r '.version')" >> $GITHUB_OUTPUT
      - name: Create Release
        id: create_release
        uses: actions/create-release@v1
        with:
          tag_name: ${{ steps.current_version.outputs.version }}
          release_name: ${{ steps.current_version.outputs.version }}
          draft: false
          prerelease: false
          target_commitish: ${{ github.event.repository.default_branch }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      - name: Upload Release
        uses: actions/upload-release-asset@v1
        with:
          upload_url: ${{ steps.create_release.outputs.upload_url }}
          asset_path: output/artifacts.zip
          asset_name: citrus_bluesky_plugin_${{ steps.current_version.outputs.version }}.zip
          asset_content_type: application/zip
```

### GPGキー

署名付きコミットをするために必要なので設定します。

キーの作成はDevContainerの中ではなくホストマシンから実行しないと多分失敗する、そんな事する人いないと思うけど一応。

```zsh
gpg --full-generate-key
```

のコマンドでGPGキーが作成できます。コマンドがない場合には`brew install gnupg`を使ってインストールしてください。

色々設定が出てきますが、

- RSA and RSA
- 4096bit
- 0(有効期限なし)

としてから名前とメールアドレスを入力します。

```zsh
pub   rsa4096 2024-08-30 [SC]
      1008E76264870ED5722268A7C9DE991D1A522478
uid                      tkgstrator <nasawake.am@gmail.com>
sub   rsa4096 2024-08-30 [E]
```

すると上のような出力が表示され、GPGキーの作成は成功です。

#### GitHubへの登録

作成されたGPGキーを表示するには以下のコマンドを利用します。

```zsh
$ gpg --list-keys --keyid-format LONG
[keyboxd]
---------
pub   rsa4096/C9DE991D1A522478 2024-08-30 [SC]
      1008E76264870ED5722268A7C9DE991D1A522478
uid                 [ultimate] tkgstrator <nasawake.am@gmail.com>
sub   rsa4096/73B215945D81D247 2024-08-30 [E]
```

> `[ultimate]`と表示されている必要があります


このとき`GPG KEY ID=C9DE991D1A522478`になります。

> `1008E76264870ED5722268A7C9DE991D1A522478`ではないので注意しましょう。この値はどこでも使うことがないです。

```zsh
gpg --armor --export <GPG KEY ID> 
```

とすると、公開鍵が出力されます。

表示される値を[SSH and GPG keys](https://github.com/settings/keys)から登録しましょう。

ちゃんと登録できればGitHub上で`Key ID: XXXXXXXXXXXXXXXX`のような感じで入力した値がそのまま反映されていると思います。

これでGitHub上での操作は終わりです。

#### Keychainにパスフレーズを保存する

このままだと毎回パスフレーズを入力させられてめんどうなので、Keychainに保存して読み込めるようにします。

```zsh
brew install pinentry-mac
```

とりあえず最初に`pinentry-mac`のパスを知りたいので、

```zsh
$ which pinentry-mac        
/opt/homebrew/bin/pinentry-mac
```

とやって出力された値をコピーして`~/.gnupg/gpg-agent.conf`を作成または編集します。

```zsh
use-agent
enable-ssh-support
pinentry-program /opt/homebrew/bin/pinentry-mac
```

みたいなことを書いて保存。これをやらないとGPGのパスフレーズを入力できないし、入力した値が保存されません。Keychainは偉大。

#### コミットに署名をつける

とりあえず全てのコミットに署名をつけてしまって困ることがないので、つけましょう。

```zsh
git config --global user.signingkey <GPG KEY ID>
```

署名付きでコミットしたいときには、

```zsh
git commit -S
```

とすればいいのですが、毎回実行するのはめんどくさいので自動で有効になるようにしました。

```zsh
git config --global commit.gpgSign true
```

こうすると勝手に署名が付きます。

#### DevContainer

なにか設定が必要な可能性もあるのですが,SSHキーを共有していたらホストマシンのものがコンテナ内でも利用できました。

#### キーの出力

```zsh
gpg --export <GPG KEY ID> public.key
gpg --export-secret-keys <GPG KEY ID> > private.key
```

なくすと困るので出力しておきます。