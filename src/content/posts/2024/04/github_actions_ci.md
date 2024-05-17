---
title: GitHub Actionsでタグ管理、バージョン管理を行う 
published: 2024-04-06
description: GitHub Actionsを駆使して面倒くさい作業を自動化しました
category: Tech
tags: [GitHub, GitHub Actions]
---

## 背景

`packge.json`のバージョン管理とか忘れるし、適当にタグつけたらそのコミットでは動作しなかったりで本当に困る......

こういうのを自動で管理してくれる仕組みはないのか......

それ、GitHub Actionsでできますよ！！！

### 要望

- プッシュされるとデフォルトブランチ以外の全てのブランチでテスト・ビルドが実行される
  - ビルドまでは不要な気がするが、異なる変更を複数取り込んだ結果動かなくなることもあるので念の為
  - 開発用ブランチはデフォルトをリベースしたもの(この表現で正しいのかわからないが)なので開発用ブランチで動くことが確認できれば十分
- デフォルトブランチはプロテクションを利用して直接プッシュできないようにする
  - これ必須
  - 開発用ブランチはギリ、オレオレ認証を許すが本番へのPRではこの特権を使えないようにする
- デフォルトブランチにマージされたらタグを付ける
  - ついでにDockerイメージを作成してGHCRにプッシュする
  - そこにもタグを付ける
- デフォルトブランチへのプルリクエストが作成されたらバージョンを確認する
  - バージョンが上がらないようなプルリクエストは通さない

これを満たすとどうなるかというと、

1. 新機能を開発したいと思ったら開発用ブランチから切って作成する
2. コミットしたらプッシュする
3. プッシュすると自動でCI(テストとビルド)が行われる
4. 動かない機能が追加されたものはそもそも開発用ブランチにマージできない
5. CIが通れば開発用ブランチにマージできる
6. 追加したい機能がいくつかたまったらデフォルトブランチにプルリクエストを出す
7. このときCI(バージョンチェック、テスト、ビルド)が行われる
8. バージョンが上がっていないとテストが通らないのがミソ
9. 差分をチェックしてCI(ラベル付け)で適切なラベルが割り当てられる
10. レビューが終わればマージする
11. マージされるとCD(タグ作成、ビルド、イメージ作成)でコミットにタグがつく
12. ビルドしたDockerのイメージがGHCRにプッシュされ、自動でリリースされる

つまり、管理しなければいけないのは`package.json`のバージョンの値だけということになり、その他の面倒くさい作業は全てGitHub ActionsがCI/CDの一環として行ってくれるわけです。

一番のポイントはバージョンが更新されていなければCIが通らずにそもそもマージができないので、正しくマージできればバージョンがちゃんと更新されていることが保証されることです！しかも同時にタグまでつけてくれるのでこれでバージョン管理の煩わしさから解放されるというわけですね。

ネットの広大な知識を検索しているとラベルを付けたときにバージョンを更新するといったような記事も見かけたのですが、今回はその機能は見送りました。

> 特に問題はないと思うのですが、その機能をつけるとバージョンの管理がめんどくさくなる気がしたためです

コミットをhuskyで管理しているなら破壊的変更のコミットが含まれていると自動でメジャーアップデート扱いにする、みたいな操作ができればより便利かと思いました。

## GitHub Actionsの中身

### バージョンチェック

プルリクエストが更新されとたときにプルリクエストのマージ先とマージ元のバージョンを比較して更新されているかを確認します。

更新されていない場合はエラーを返します。

`package.json`しかチェックできませんが、パスを指定することもできます。

```yaml
name: Check Version Update with Pull Request

inputs:
  path:
    description: 'Path to package.json'
    required: false
    default: '.'
outputs:
  semver:
    description: 'Semantic Versioning'
    value: ${{ steps.check-version-update.outputs.semver }}

runs:
  using: 'composite'
  steps:
    - name: Checkout
      uses: actions/checkout@v4
      with:
        ref: ${{ github.base_ref }}

    - name: Current Version
      id: current_version
      shell: bash
      run: |
        echo "version=$(cat ${{ inputs.path }}/package.json | jq -r '.version')" >> $GITHUB_OUTPUT

    - name: Checkout
      uses: actions/checkout@v4
      with:
        ref: ${{ github.ref }}

    - name: Release Version
      id: release_version
      shell: bash
      run: |
        echo "version=$(cat ${{ inputs.path }}/package.json | jq -r '.version')" >> $GITHUB_OUTPUT

    - name: Check version update
      id: check-version-update
      shell: bash
      run: |
        release_version=${{ steps.release_version.outputs.version }}
        release_ver_array=(${release_version//./ })
        current_version=${{ steps.current_version.outputs.version }}
        current_ver_array=(${current_version//./ })
        if [ ${release_ver_array[0]} -gt ${current_ver_array[0]} ]; then echo "semver=Semver-Major" >> "$GITHUB_OUTPUT"; exit 0; fi
        if [ ${release_ver_array[0]} -eq ${current_ver_array[0]} ] && [ ${release_ver_array[1]} -gt ${current_ver_array[1]} ]; then echo "semver=Semver-Minor" >> "$GITHUB_OUTPUT"; exit 0; fi
        if [ ${release_ver_array[0]} -eq ${current_ver_array[0]} ] && [ ${release_ver_array[1]} -eq ${current_ver_array[1]} ] && [ ${release_ver_array[2]} -gt ${current_ver_array[2]} ]; then echo "semver=Semver-Patch" >> "$GITHUB_OUTPUT"; exit 0; fi
        echo "Please update version in package.json"
        exit 1
```

### ラベル付け

上のバージョンチェックが通った際の返り値をプルリクエストにラベルとしてつけます。

```yaml
name: Set Label to Pull Request
inputs:
  semver:
    required: true
runs:
  using: 'composite'
  steps:
    - uses: actions/github-script@v7
      with:
        script: |
          const { SEMVER } = process.env
          github.rest.issues.setLabels({
            owner: context.repo.owner,
            repo: context.repo.repo,
            issue_number: context.payload.pull_request.number,
            labels: [SEMVER]
          });
      env:
        SEMVER: ${{ inputs.semver }}
```

### バージョン管理

上の二つを組み合わせたものです。

バージョンチェックはデフォルトブランチにマージするプルリクエストに対してのみ実行するようにします。

```yaml
name: Semantic Versioning

on:
  pull_request:
    branches:
      - '**'
      - 'develop'

jobs:
  version:
    if: github.base_ref == 'master'
    runs-on: self-hosted
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Check version update
        id: check-version-update
        uses: ./.github/workflows/actions/check-version-update

      - name: Set Label to Pull Request
        uses: ./.github/workflows/actions/set-label
        with:
          semver: ${{ steps.check-version-update.outputs.semver }}
```

### タグ付け

デフォルトブランチへのプルリクエストがマージされたときに実行されます。

```yaml
name: Continuous Deployment

on:
  pull_request:
    branches:
      - 'main'
      - 'master'
      - 'develop'
    types: [closed]

jobs:
  set_tag:
    if: github.event.pull_request.merged == true && github.base_ref == 'master'
    runs-on: self-hosted
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Get Version
        id: current_version
        run: |
          echo "version=$(cat package.json | jq -r '.version')" >> $GITHUB_OUTPUT

      - name: Set Tags
        run: |
          git fetch origin ${{ github.event.pull_request.head.ref }}
          git checkout ${{ github.event.pull_request.head.ref }}
          git tag `echo '${{ github.event.pull_request.head.ref }}'`
          git push origin `echo '${{ github.event.pull_request.head.ref }}'`
```

### デプロイ

プルリクエストのターゲットがデフォルトブランチか開発用ブランチかで最後のタグ付けを少し変えています。

Docker Hubにプッシュする方法もあるのですが、GHCRを利用すれば特別なログイン操作などが不要なので便利です。

```yaml
name: Continuous Deployment

on:
  pull_request:
    branches:
      - 'main'
      - 'master'
      - 'develop'
    types: [closed]

jobs:
  deploy:
    if: github.event.pull_request.merged == true
    runs-on: self-hosted
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - uses: benjlevesque/short-sha@v3.0
        id: hash
        with:
          length: 7

      - name: Get Version
        id: current_version
        run: |
          echo "version=$(cat package.json | jq -r '.version')" >> $GITHUB_OUTPUT

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to GitHub Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.repository_owner }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v5
        if: github.base_ref == 'develop'
        with:
          context: .
          file: Dockerfile
          platforms: linux/amd64,linux/arm64
          push: ${{ github.event_name == 'pull_request' }}
          tags: |
            ghcr.io/${{ github.repository_owner }}/av5ja_stats_api:${{ steps.hash.outputs.sha }}
            ghcr.io/${{ github.repository_owner }}/av5ja_stats_api:develop

      - name: Build and push
        uses: docker/build-push-action@v5
        if: github.base_ref == 'master'
        with:
          context: .
          file: Dockerfile
          platforms: linux/amd64,linux/arm64
          push: ${{ github.event_name == 'pull_request' }}
          tags: |
            ghcr.io/${{ github.repository_owner }}/av5ja_stats_api:${{ steps.current_version.outputs.version }}
            ghcr.io/${{ github.repository_owner }}/av5ja_stats_api:latest
```