---
title: GitHub Actionsが便利すぎた
published: 2021-05-06
description: GitHub Actionsの存在は知っていたのですが、使ってみたら驚くほどに便利でした
category: Programming
tags: []
---

## GitHub Actions

そもそも GitHub Actions とは何だということになるのだが、詳しくは GitHub の公式ページを見るのが良い。そこには次のように記されている。

::: tip GitHub Actions とは

GitHub Actions を使用すると、ワールドクラスの CI/CD ですべてのソフトウェアワークフローを簡単に自動化できます。GitHub から直接コードをビルド、テスト、デプロイでき、コードレビュー、ブランチ管理、問題のトリアージを希望どおりに機能させます。

:::

要するにソースコードを Push したら GitHub のサーバがそれを勝手にビルドしてくれるということ。このあたりは Docker に似たものを感じなくもないですね。

ただし、リソースを使うので使い放題というわけではなく、一ヶ月に利用可能なビルド時間というものがあります。

|         | 消費クレジット |
| :-----: | :------------: |
|  Linux  |       1        |
| Windows |       2        |
|  macOS  |       10       |

考え方としてはクレジット方式で、無料ユーザであれば 2000、有料ユーザであれば 3000 のクレジットが毎月与えられます。Linux のビルドだと 1 分で 1 クレジット消費するので 2000 分ビルドできるのですが、macOS でビルドすると 200 分しか使えないというわけです。

## GitHub Actions を使ってみよう

では実際に GitHub Actions を使ってみましょう。

使うといっても実行したいコマンドを YAML ファイルに書いていくだけです。書き方がわからなかったのですが、つよつよエンジニアの[ささぴよげえむず](https://twitter.com/sasapiyogames)さんが Github に対して PR を送ってくれたのでそれを参考にしてみることにします。

Salmonia は Python のプログラムで、Windows でそのまま実行しようとすると Pyinstaller でビルドする必要があります。今回は GitHub Actions で Pyinstaller で EXE 化した上で Release に出力するところを考えてみましょう。

```yaml
name: build executables

on:
  push:
    tag:
      - "v*"

jobs:
  windows-build: # Windows向けビルド
    runs-on: windows-latest
    steps: # コマンドを上から順番に書いていく
      - name: Checkout commit
        uses: actions/checkout@master

      - name: Set up Python 3.9
        uses: actions/setup-python@master
        with: { python-version: 3.9 }

      - name: Upgrade pip
        run: python -m pip install --upgrade pip PyInstaller

      - name: Install requirements
        run: pip install -r requirements.txt

      - name: build
        run: pyinstaller Salmonia.py --onefile

      - name: upload
        uses: actions/upload-artifact@v1
        with:
          name: Salmonia-windows
          path: dist/Salmonia.exe

  release: # 実行するジョブを書く
    needs: [windows-build]
    runs-on: ubuntu-latest

    steps: # ビルド後の処理などを書く
      - name: Download Windows
        uses: actions/download-artifact@v1
        with:
          name: Salmonia-windows

      - name: Create Release
        id: create_release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          draft: false
          prerelease: false

      - name: Zip
        run: zip --junk-paths Salmonia-windows ./Salmonia-windows/Salmonia.exe

      - name: Append Binary
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          upload_url: ${{ steps.create_release.outputs.upload_url }}
          asset_path: ./Salmonia-windows.zip
          asset_name: Salmonia-windows.zip
          asset_content_type: application/zip
```

Pyinstaller で EXE を作成するためには Windows で実行しないと意味がないのでビルド時には`runs-on`に`windows-latest`を指定していますが、アップロードや ZIP 化するのは別に Linux で構わないのでこちらには`ubuntu-latest`を指定します。

これがベースの書き方で、これさえ書いておけば全ての Python プログラムは Pyinstaller でビルドして自動リリースができます。ただ、このままだとタグの値に関わらず常に同じファイル名になってしまうので少し気がかりです。

そこで、タグ情報をファイル名に埋め込めるようにします。

```diff
steps: # ビルド後の処理などを書く
+ - name: Set version
+   id: version
+   run: |
+     REPOSITORY=$(echo ${{ github.repository }} | sed -e "s#.*/##")
+     VERSION=$(echo ${{ github.ref }} | sed -e "s#refs/tags/##g")
+     echo ::set-output name=version::$VERSION
+     echo ::set-output name=filename::$REPOSITORY-$VERSION
  - name: Download Windows
    uses: actions/download-artifact@v1
    with:
      name: Salmonia-windows
# 中略
  - name: Append Binary
    uses: actions/upload-release-asset@v1
    env:
      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    with:
      upload_url: ${{ steps.create_release.outputs.upload_url }}
      asset_path: ./Salmonia-windows.zip
-     asset_name: Salmonia-windows.zip
+     asset_name: Salmonia-${{ steps.version.outputs.version }}-windows.zip
      asset_content_type: application/zip
```

`github.ref`には余計な情報が入っているので一回コマンドでそれらを削除した後に環境変数に入れることで対応します。この使い方、割とスタンダードらしいので覚えておくと便利かもしれません。



## 実際にやってみた

ビルドして完成したものが[こちら](https://github.com/tkgstrator/Salmonia/releases/tag/v1.10.1)

Windows でのビルドは二分くらいで終わったので常識的な範囲内なら大丈夫そうです。

記事は以上。
