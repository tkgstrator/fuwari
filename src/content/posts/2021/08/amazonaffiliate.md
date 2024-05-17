---
title: Vuepressでアマゾンアフィリエイトを表示させる
published: 2021-08-10
description: Vuepressでつくったサイトにアフィリエイトを表示させるコンポーネントを作成する手順について解説
category: Programming
tags: [Vue, Javascript]
---

# アマゾンアフィリエイト

アマゾンアフィリエイトは単にリンクを貼るものと PA API(Product Advertising API)を利用するものとがあるのですが、PA API は使わないでいると利用制限がかかってしまいます。また、Vuepress は静的サイトなので誰かがアクセスするたびに PA API を叩いて〜ということが普通はできないのですが、コンポーネントを使って Javascript を走らせればそれに対応できそうだということがわかりました（気づくのが遅い）

なので、やってみようと思います。



## [コンポーネント](https://tkgstrator.work/posts/2021/08/02/markdownvue.html)

前回、Markdown で Vue コンポーネントを読み込ませる手順については解説したので、それを利用します。

毎回商品を指定してそれを表示できるようにしてもよいのですが、めんどくさいのでコンポーネントを指定すれば何らかの商品リストから適当に一つ商品を表示するようなシステムを構築します。

```vue
<template>
  <div id="product" @click="openURL">
    <div id="leftCol">
      <img :src="imageURL" />
    </div>
    <div id="centerCol">
      <h1 id="productTitle">{{ productName }}</h1>
      <span>価格</span>
      <span id="productPrice">{{ productPrice }}</span>
    </div>
  </div>
</template>
```

表示させるところは上のようなものを考えました。一応、当ブログで使っていた前のやつよりもまともな構成にはなっているはず。

見た目とかそういうやつはアマゾンの公式サイトを参考にしました。

`id=product`にはクリックすれば別タブでリンクが開くように`@click`属性を付けています。

### データベースを構築

データベースといっても本格的なものではなく、表示する商品のリストを作成してまとめたファイルを指します。

一つ一つ手作業で追加してもよいのですが、どうせなら売れ筋商品を表示したほうがクリック数もよかろう（ゲス）ということで、アマゾンのいろいろなカテゴリから TOP50 の売れ筋商品ばかりをデータベース化しました。

ここでちょいと問題になったのが、アマゾンの商品コード ASIN で商品画像は取得できるのですが、商品名や価格は取得できないということです。なので、データベースには ASIN だけではなく商品名と価格も含める必要があります。

```json
{
  "categoryTag": "videogames",
  "productId": "B07WXL5YPW",
  "productName": "Nintendo Switch 本体 (ニンテンドースイッチ) Joy-Con(L) ネオンブルー/(R) ネオンレッド",
  "productPrice": "¥32,970"
}
```

そこで、上のような JSON 形式でデータを扱うようにしました。一つや二つだけならいいとして、これらを数百件集めようとしているのですから手作業でやっていたら日が暮れます。

つまり[プログラミングの出番](https://tkgstrator.work/posts/2021/06/16/whyprogramming.html)というわけですね。

こういう作業を苦もなく黙々とできる方はプログラマーに向いていません（悪い意味ではないです）

収集に使ったコードは公開してもいいのですが、公開すると同じようなことを考える人がたくさんでそうなので当記事内で紹介するのは避けておきます。まあそんなに難しくないので Vuepress でブログを立ち上げようとしている人がいるなら書かなくても大丈夫でしょう。

完成したものを`product.json`として適当にコンポーネントと同じディレクトリにおいておきます。

### データ読み込み

```vue
<script>
/* ファイル読み込み */
import ProductData from "./product.json"

export default {
  name: "Amazon",
  data() {
    return {
      imageURL: "",
      productName: "",
      productURL: "",
      productPrice: "",
      products: ProductData,
      associateId: "tkgstrator0f-22",
      baseURL: "https://www.amazon.co.jp/gp/product/",
    }
  },
  methods: {
    // クリックしたら別ウィンドウで開くための関数
    openURL() {
      window.open(this.productURL, "_blank")
    }
  },
  mounted: function() {
    // ランダムにプロダクトIDを選ぶ
    const product = this.products[Math.floor(Math.random() * this.products.length)]
    // 画像のURLを取得(PA APIでしか取得できない場合もあるらしいが今回はないものとして扱う)
    this.imageURL = `https://images-na.ssl-images-amazon.com/images/P/${product["productId"]}.09.LZZZZZZZ`
    // リンクをタグ付きで作成
    this.productURL = `${this.baseURL}${product["productId"]}/?tag=${this.associateId}`
    this.productName = product["productName"]
    this.productPrice = product["productPrice"]
  }
};
```

内容としてはシンプルで、読み込んだデータベースからランダムに一つ表示データを格納して HTML に反映させます。

本当にそれだけなのでおもしろいところは特にありません。

あとは``としてコンポーネントを Markdown に埋め込めばリロードするたびに異なる商品が表示されます。リロードすると変わるので見ている側も飽きなかったりするかもしれません。

ただ、逆に言えば常に指定した商品を表示できないのでこのアタリは改善の余地があります。

オプション指定でランダム表示か指定した ASIN の商品を表示かを切り替えられるようにしたいですね。

### CSS

最後に見た目をモダンにするための CSS を紹介しておきます。

今使っているのはこれとはちょっと違うのですが、だいたいこんな感じです。

```css
#product {
  display: flex;
  margin: 0 auto;
  max-height: 120px;
  cursor: pointer;
  padding-top: 5px;
  padding-bottom: 5px;
  border: solid 2.7px #d0d0d0;
  border-radius: 10px;
  border-spacing: 1px;
}

#product #leftCol {
  width: 30%;
  max-width: 200px;
  min-width: 100px;
  max-height: 100%;
}

h1#productTitle {
  margin-top: initial;
  padding-top: initial;
  appearance: none;
  font-weight: 400;
  font-size: 14px !important;
  border-bottom: none !important;
  /* 省略するためのスタイル */
  word-break: break-all;
  overflow: hidden;
  text-overflow: ellipsis;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;

  line-height: 24px;
  max-height: calc(24px * 2);
}

#productPrice {
  color: #b12704 !important;
  font-size: 16px;
  line-height: 24px;
}

img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}
```

記事は以上。


