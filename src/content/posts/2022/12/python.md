---
title: Python
published: 2022-12-05
description: Pythonで何回も調べ直してしまうことを備忘録として残しておきます
category: Programming
tags: [Python]
---

## 環境構築

Python は 3.3 から`virtualenv`を取り込んで`venv`として標準で使えるようになりました。

例えば`VENV`という名前の仮想環境を作りたいのなら以下のコマンドでいけます。

```zsh
python -m venv .venv --prompt VENV
```

VScode だと`Python`のプラグインを入れれば`venv`にも対応して Workspace を開いたタイミングで`venv`を有効化してくれます。

### VScode で自動読み込み

VScode で Workspace に`.venv`が含まれる場合は自動で認識して仮想環境を有効化してくれる、とある。

が、やってみると

### 環境変数

秘匿にしておきたい鍵などはローカル環境では`.env`に書いておき、サーバで動かす際には`ENVIRONMENT VALUE`みたいな設定から値を設定することが多いです。

例えば、以下のような環境変数が書けます。

```zsh
CLIENT_SECRET=1234567890
```

環境変数は全て文字列として扱われるのでダブルクオーテーションは不要です。

これを読み込むための Python のコードは以下のとおりです。

```python
import os
from dotenv import load_dotenv

load_dotenv()

if __name__=="__main__":
  print(os.environ.get('CLIENT_SECRET'))
```

このコードの意味については以下で解説します。

#### os.environ

これはシステムの環境変数を読み込むコマンドなので、これだけを使っても`.env`の中身を読み込むことはできません。なぜなら、`.env`はあくまでもローカルの環境変数だからです。

よって、`.env`の中身を一時的にシステムの環境変数に追加する必要があります。

#### pyhton-dotenv

`python-dotenv`は`.env`に書き込まれた内容をシステム環境変数に読み込みます。

よって、`os.environ`と`python-dotenv`を組み合わせることで Python で`.env`のデータを読み込むことができるようになるわけです。
