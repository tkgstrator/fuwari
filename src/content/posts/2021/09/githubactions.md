---
title: GitHub Actionsで定期実行しよう
published: 2021-09-16
description: 北米版のBD販売予定リストを自動更新するコードについて解説します
category: Programming
tags: [Python]
---

# GitHub Actions

当 HP では何度か GitHub Actions について触れているので、GitHub Actions ってなんぞっていう方はまずそっちを読むことをおすすめします。

- [GitHub Actions が便利すぎた](https://tkgstrator.work/posts/2021/05/06/githubactions.html)
- [GitHub Actions で Netlify のビルド時間を浮かせよう](https://tkgstrator.work/posts/2021/05/06/netlifybuild.html)



## [北米版 BD 販売予定リスト](https://rightstuf-release.netlify.app/)

せっかくなので成果物は先に載せておきます。

### 今後の展望

- ソート機能
- フィルタリング機能
- 画像を表示したりとか

## 定期実行

GitHub Actions は様々なトリガーに対して Action を起こすことができます。たとえばコミットがプッシュされたときや、タグが付けられたときなどがあります。

GitHub Actions は Cron を利用して定期実行されます。

::: tip GitHub Actions の定期実行

Cron は本来は一分単位で実行が可能なのだが、GitHub Actions では最短五分あけないと実行されないようになっている。

負荷がかかるので当然だが、逆に言えば五分に一回実行できるのはありがたい。

:::

### 定期実行の設定

GitHub Actions の実行内容は`.github/workflows/***.yml`に記述します。

`yml`のファイル名は何でもいいです。

```yml
name: Scheduled build # 名前は必須

on:
  schedule:
    - cron: "0 0 * * *" # 定期実行のコマンド
```

で、この定期実行のコマンドが若干ややこしいです。[公式ドキュメント](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#scheduled-events)に設定例などがあるのですが、案の定英語なので日本語で軽く解説します。

```sh
┌───────────── minute (0 - 59)
│ ┌───────────── hour (0 - 23)
│ │ ┌───────────── day of the month (1 - 31)
│ │ │ ┌───────────── month (1 - 12 or JAN-DEC)
│ │ │ │ ┌───────────── day of the week (0 - 6 or SUN-SAT)
│ │ │ │ │
│ │ │ │ │
│ │ │ │ │
* * * * *
```

要するに五つのパラメータで設定し、左から順に「分」「時間」「日」「月」「曜日」を指します。 更に四つのメタ文字があり、これでありとあらゆる表現が可能になります。

- `*`
  - 任意の値
- `'`
  - 区切り
- `-`
  - 範囲
- `/`
  - ステップ

### 定期実行コマンドの例

#### 一日一回実行

これが一番使い所が多い気がします。

```sh
0 0 * * *   # 毎日00:00(UTC)に実行
```

::: warning UTC と JST

ここで注意すべき点は、GitHub Actions は UTC(協定世界時)で動いているので日本とは九時間の時差があります。

この書き方をすると日本では毎朝 09:00 に実行されることを覚えておきましょう。

:::

#### 一時間ごとに実行

```sh
0 * * * *   # 毎時0分に実行

30 * * * *  # 毎時30分に実行
```

こうかけば「分」が 0 になったタイミングで実行されます。このタイミングは一時間に一回だけです。

#### N 分または N 時間ごとに実行

```sh
*/10 * * * *  # 10分置きに実行 -> 00, 10, 20, ... , 55

* */1 * * *   # 1時間置きに実行
```

この書き方をすると常に N 時 0 分, 10 分, 20 分, ... 50 分のタイミングで実行されます。5 分, 15 分のように微妙なタイミングで実行したい場合は、

```sh
05-59/10 * * * *  # 10分置きに実行 -> 05, 10, 15, 20, ... ,55
```

とする必要があります。

## YML を記述しよう

今回は以前の記事で紹介した RightStuf から北米版 BD の販売情報を取得するプログラムを考えます。

あれは Python で動作するので、GitHub Actions でも Python を実行する環境を与えます。

```yml
jobs:
  build:
    name: build
    runs-on: ubuntu-latest # Ubuntuを使えば基本的には問題ない
    steps:
      - uses: actions/checkout@v2 # おまじない

      - name: Setup Python # Pythonのセットアップ
        uses: actions/setup-python@v2
        with:
          python-version: "3.9" # Pythonのバージョン指定

      - name: Install dependencies # 依存パッケージのインストール
        run: |
          python -m pip install --upgrade pip
          pip install requests

      - name: Run right.py # PythonでRigthStufからデータ取得
        run: |
          python right.py

      - name: Commit and Push # 実行結果をプッシュしてレポジトリに反映
        run: |
          git config --local user.email "XXXXXXXXXXXX" # メールアドレスを設定 
          git config --local user.name "XXXXXX" # ユーザ名を設定
          git add .
          git commit -m "ZZZZZZZZZZ" # コミットメッセージを記述
          git pull
          git push origin master
```

これがテンプレートで Python を実行したいのであればこの書き方で問題ありません。

こうしておけば、一日一回実行され、そのときに`right.py`が新しいファイルを作成してその内容が自動的にプッシュされ、プッシュされることで Netlify の自動ビルドが始まるという仕組みです。

::: warning GitHub のプッシュについて

今回の例でいうと`python right.py`のコマンドで新規ファイルまたはファイルに変更がないと`git commit`のときに「変更点がないよ」と怒られてしまう。

何らかの差分が生じるようなコードにしよう。

:::

### デプロイ

ひょっとしたら GitHub Actions の Push は自動で検知してくれないかもしれないので、一応 Netlify へのデプロイも含めたコードの紹介をしておきます。

[Netlify へのデプロイをビルド時間 0 で行うための GitHub Actions](https://qiita.com/nwtgck/items/e9a355c2ccb03d8e8eb0)の内容が大変参考になるので、こちらを読んでください。

記事は以上。


