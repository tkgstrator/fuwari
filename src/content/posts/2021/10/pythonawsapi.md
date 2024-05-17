---
title: AWS+Pythonで簡易APIを立てよう
published: 2021-10-04
description: APIは普通はPythonでは立てないと思うのですが、立てられるときいたのでAWSで試してみました
category: Programming
tags: [Python, AWS]
---

# AWS + Python

AWS には AWS Gateway と呼ばれる API を立てるための仕組みが存在する。

ただ、これはデフォルトだとどうも決まりきった定型文のようなものしか返せない。

受け取ったリクエストからなにかデータを作成して返すためには EC2 などと連携する必要があるようだ。

そこで稼働中の EC2 サーバで Python を動かしその結果を返すための API を作成することにした。

## 仕組み

![](https://pbs.twimg.com/media/FA00xjcUcAAXldh?format=png&name=medium)

仕組みとしては上図のような感じ。

EC2 内で Python コードを動かして API のような動作をさせておき、EC2-Gateway 間でデータのやり取りをおこなう。外部のクライアントは直接 EC2 の API を叩くことはできず、あくまでも Gateway を介するようにする。

こうすることでアクセス禁止やアクセス頻度制限などは Gateway のみで設定できるようになるはずである。

### Python コード

Python で API を立てる方法については[Python で REST API をサクっと実装](https://qiita.com/Morinikiz/items/c2af4ffa180856d1bf30)の記事が大変参考になりました。

#### X-Product Version

Nintendo Switch Online にログインするために必要な X-Product Version を自動更新する API は以下の通り。

```python
from flask import Flask, jsonify, abort, make_response

api = Flask(__name__)

@api.route("/version", methods=["GET"])
def get_version():
    result = {
        "x_product_version": "1.12.0",
        "api_version": "20211004"
    }
    return make_response(jsonify(result))

@api.errorhandler(404)
def not_found(error):
    result = {
        "error": "Not found"
    }
    return make_response(jsonify(result))

if __name__=="__main__":
    api.run(host="localhost", port=3000)
```

これだけで API が立てられてしまうので便利というほかない。
