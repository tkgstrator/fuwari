---
title: VuePressで環境変数を利用する
published: 2021-08-16
description: VuePressで環境変数を利用してアプリケーションを動かしてみます
category: Programming
tags: [Vue, Javascript]
---

# 環境変数を読み込もう

Webhook の API を VuePress で利用したい場合、ソースコードに埋め込んでいると GitHub 先生に怒られてしまうので環境変数から読み込むようにします。

このとき、開発環境と本番環境だと参照先が違うのでどちらにも対応する必要があります。

|        |     開発環境     |     本番環境     |
| :----: | :--------------: | :--------------: |
| 参照先 | ローカルファイル | サーバの環境変数 |

このとき、ローカルファイルの環境変数が書かれたファイルを Git で Push しては意味がないので`.gitignore`に追加するのを忘れないようにしましょう。



## dotenv のインストール

[VuePress の Vue コンポーネントで環境変数を使いたいとき](https://qiita.com/wakame_tech/items/1e5b65c180d2d940032d)が大変参考になりました。

```zsh
yarn add -D dotenv
```

どうやら`webpack`からでは`process.env`が参照できないらしいので`config.js`で`.env`を読み込んで`webpack`にわたす必要があります。

そのために`dotenv`が要るとのことなのでインストールします。

### confing.json

そして、`config.json`に次のように追記して`process.env`を読み込めるようにします。

```json
const webpack = require("webpack");
const { config } = require("dotenv");
config();

module.exports = {
  title: "VuePress Title",
  configureWebpack: {
    plugins: [
      new webpack.DefinePlugin({
        "process.env": {
          "VUE_APP_WEBHOOK_URL": JSON.stringify(process.env.VUE_APP_WEBHOOK_URL),
        },
      }),
    ],
  },
```

こうかけば、`.env`に

```zsh
VUE_APP_WEBHOOK_URL="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
```

と書いておけば、それを Vue 側から`process.env.VUE_APP_WEBHOOK_URL`として読み込むことができます。

ローカルでの開発環境ではこのようにしておけば動作テストができるわけですね。

### Environment Variables

ちなみに本番環境では Netlify から環境変数を読み込むので、

Site settings->Build and Deploy->Environment variables から環境変数を設定すれば自動で読み込んでくれます、便利！

## Vue Component

今回は Slack の Webhook の URL を環境変数から読み込んで、通知を送るプログラムを書きました。

```vue
<template>
  <form>
    <div class="form">
      <div class="group">
        <input v-model="code" type="text" required />
        <span class="highlight"></span>
        <span class="bar"></span>
        <label>ギフトコード</label>
        <div class="span3">
          <button href="" class="btn btn-flat" @click="sendMessage">
            <span>応援</span>
          </button>
        </div>
      </div>
    </div>
  </form>
</template>

<script>
export default {
  name: "GiftCode",
  methods: {
    sendMessage() {
      let url = process.env.VUE_APP_WEBHOOK_URL;
      const payload = {
        blocks: [
          {
            type: "section",
            text: {
              type: "mrkdwn",
              text: this.code,
            },
          },
        ],
      };
      fetch(url, {
        method: "POST",
        body: JSON.stringify(payload),
      })
        .then((response) => {
          if (response.ok) {
            alert("ご支援ありがとうございます");
          }
        })
        .catch((error) => {
          console.log(error);
        });
    },
  },
  mounted() {},
  data() {
    return {
      code: "",
    };
  },
  computed: {},
};
</script>
```

非常に大雑把なのですが、これで一応動きます。正確にはコードの Validation をする必要があるのですが、めんどくさかったので今回はスルーしました。

アマゾンギフト券のコードは 16 桁（または 15 桁？）らしいので、桁数と英数字の Validation をつければ十分だと思います。

なお、アマゾンギフト券でのご支援は[このページ](https://tkgstrator.work/amazongiftcode/)で承っております。

記事は以上。


