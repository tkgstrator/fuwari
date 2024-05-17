---
title: GitHub Actionsで自動でバージョニングしたい話 
published: 2024-01-24
description: No description
category: Programming
tags: [macOS, GitHub]
---

## 概要

NodeJSで動くパッケージなどを作っている際に気になるのがタグ付けとバージョン管理です。

これらは本来のコミットとズレてしまっては意味がないのですが、自分はよくタグ付けを間違えてしまったり忘れてしまったりします。

そこで、GitHub Actionsを使ってこれらを一元管理できないかを考えました。

### 求める仕様

1. レポジトリには何らかのバージョンを管理するファイルがある
    - NodeJS向けのやつだと`package.json`の`version`の値を参照する
2. `master`または`main`にPull Request経由でマージされた際にGitHub Actionsが実行される
    - バージョンが上がっていることを確認する(最悪、バージョンが被っていないとかでも良い)
    - バージョンが上がっていればタグを作成する
3. DockerfileがあればDocker Imageを作成する
    - そのイメージに自動でバージョンでタグを付ける
4. そのイメージがDocker HubにPushされる

さて、これらについていろいろ調べていきましょう。

## GitHub Actions

### バージョン管理

`package.json`からバージョンを取得するのは偉い人がMarketplaceで[Get current package version](https://github.com/marketplace/actions/get-current-package-version)を公開してくれているのでそれを利用します。

```yaml
- name: Get Package Version
  id: version
  uses: martinbeentjes/npm-get-version-action@v1.3.1
  with:
    path: .

- name: Check Version
  run: echo "Version is ${{ steps.version.outputs.current-version }}"
```

この`path`はドキュメントルートからの`package.json`へのパスなので特に何もなければ`.`となるはずです。

取得した値へのアクセスは`${{ steps.version.outputs.current-version }}`で行えます。

### タグとラベルの管理

Dockerでのタグとラベルの管理については[公式ドキュメント](https://docs.docker.com/build/ci/github-actions/manage-tags-labels/)に記載があったのでこれを読み解きます。

で、ここではDocker HubではなくGitHub Container Registryを利用するようです。

```yaml
jobs:
  docker:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          # 環境変数 github.repositoryを利用する
          images: |
            ghcr.io/${{ github.repository }}
          tags: |
            type=schedule
            type=ref,event=branch
            type=ref,event=pr
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=semver,pattern={{major}}
            type=sha
    
        # マルチプラットフォームビルドに必要
      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to GitHub Container Registry
        if: github.event_name != 'pull_request'
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.repository_owner }}
          # 別途トークンを用意するみたいな記事もあるけど不要
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          file: Dockerfile
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
```

ここでのポイントはimagesに対して`ghcr.io/${{ github.repository }}`を割り当てるということ。こうすればどんなレポジトリに対しても共通のYAMLが書けます。

`GITHUB_TOKEN`は組織のレポジトリであってもそこに所属しているユーザーのトークンが利用できるので[Developer Settings](https://github.com/settings/tokens)からトークンを発行しましょう。