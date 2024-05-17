---
title: VuepressでMarkdownに直接コンポーネントを読み込む方法
published: 2021-08-02
description: VuepressでVueコンポーネントを利用する方法について解説します
category: Programming
tags: [Vue, Javascript]
message: "Hello, Tkgling!"
---

# Vuepress

Vuepress は単なる Markdown 記法のテキストを HTML に変換するだけのフレームワークだと思っていたのですが、よく考えれば Vue なので Vue コンポーネントも利用できるわけです。

Vue はもう半年以上触っていなくてどんなものか忘れてしまっていたのですが、せっかくなのでこの機会に思い出してみることにしました。

## Vue コンポーネント

まずは Vue コンポーネントを作成します。

Vue コンポーネントは HTML, CSS, Javascript の三つが混ざったようなものです。以下が Vue コンポーネントのテンプレートです。

```vue
<template></template>

<script>
export default {
  data() {
    return {};
  },
};
</script>

<style></style>
```

### Template

HTML っぽいものを書きます。ここは親の属性が一つだけである必要があるので注意しましょう。

例えば以下のものは親が`<div></div>`なのでこの条件を満たしています。

```vue
<template>
  <div>
    <p>Hello, World!</p>
  </div>
</template>
```

### Script

Javascript のコードを書きます。変数に値を代入したりとか、そういうことができます。

例えば`message`という変数に`Hello, World!`という文字列を代入するコードは次のように書けます。

```vue
<script>
export default {
  data() {
    return {
      message: "Hello, World!",
    };
  },
};
</script>
```

### CSS

見た目を装飾します。

CSS の他にも SCSS とか SASS とかが使えます。

```vue
<style>
p {
  color: red;
}
</style>
```

### 組み合わせてみる

Vue で変数を HTML に反映させるには`{{}}`でかこむ必要があります。

```vue
<template>
  <p class="color-red">{{ message }}</p>
</template>

<script>
export default {
  data() {
    return {
      message: "Hello, World!",
    };
  },
};
</script>

<style>
.color-red {
  color: red;
}
</style>
```

というわけで、単に`Hello, World!`と出力するだけのコンポーネントであればこのように書けます。

## コンポーネントの登録

あとはこのコンポーネントを Markdown から呼び出せるようにする必要があります。

Vuepress では`.vuepress/components/********.vue`という風にコンポーネントを配置すれば勝手に認識してくれます。

ただし、このままではコンポーネントは登録できても呼び出せないので、呼び出せるようにコンポーネントに名前をつけておきます。

```vue
<template>
  <p class="color-red">{{ message }}</p>
</template>

<script>
export default {
  name: "HelloWorld", // 命名
  data() {
    return {
      message: "Hello, World!",
    };
  },
};
</script>

<style>
.color-red {
  color: red;
}
</style>
```

こうすれば Markdown 中に、`<HelloWorld/>`と書けば赤い字でそれが表示されます。

<!-- <HelloWorld/> -->

## 引数を受け取るコンポーネント

さて、簡単なコンポーネントは表示できましたが Markdown からコンポーネントに対して引数を与えたい場合もあります。

例えば、指定したメッセージを表示するようなコンポーネントを考えます。

Vue コンポーネントのコンストラクタでは直接引数を指定できないので、`frontmatter`の機能を利用します。

Vuepress で記事を書いているのであれば Frontmatter で`tags`などの指定をしていると思います。そこに値を書き込むことで無理やり読み込ませられます。

```md
---
tags: ["Vue"]
message: "Hello, Tkgling!"
---
```

次に Vue コンポーネントを以下のように書き換えます。

```vue
<template>
  <p class="color-red">{{ $page.frontmatter.message }}</p>
</template>

<script>
export default {
  name: "HelloWorld",
  data() {
    return {};
  },
};
</script>

<style>
.color-red {
  color: red;
}
</style>
```

<HelloWorld/>

## Script を直接埋め込む

Vue コンポーネントがあればなんでも Markdown に埋め込みできそうですが、Javascript をそのまま埋め込もうとするとおかしなことになります。

```vue
<template>
  <script>
    console.log("{{ $page.frontmatter.message }}");
  </script>
</template>

<script>
export default {
  name: "HelloWorld",
  data() {
    return {};
  },
};
</script>

<style></style>
```

例えば、上のようなコードを書くと一回目の描画では正しく読み込むことができますが、リロードを行なうと`Uncaught SyntaxError: Unexpected token '&'`というエラーが発生してしまいます。

これは、HTML にスクリプトを埋め込んだ際に特殊文字である`"`をエスケープしてしまって`$quot`に置き換わったのが原因です。

これに対する対策はパッと思いついたところで二つあります。

- 強制的にエスケープを無視する
  - ある意味最強だが、エスケープすることで悪意のあるスクリプトを実行できてしまう可能性がある
- Javascript を埋め込む別の方法を探す
  - これが一番無難
