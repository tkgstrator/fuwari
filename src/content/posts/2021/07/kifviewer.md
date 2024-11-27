---
title: KifuViewerをVuepressに対応させた
published: 2021-08-01
description: HTML5で駒を動かせるKifuViewerをVuepressで対応させるまでの流れを解説
category: Programming
tags: [Shogi]
---

# KifuViewer

[KifuViewer](https://marmooo.github.io/kifu-viewer/)とは Javascript で動く将棋の棋譜再生ライブラリのこと。

この KifuViewer は[kifPlayer](https://shogi-study.com/%E3%83%96%E3%83%A9%E3%82%A6%E3%82%B6%E6%A3%8B%E8%AD%9C%E5%86%8D%E7%94%9F%E3%83%84%E3%83%BC%E3%83%AB%E3%80%8Ckifplayer%E3%80%8D/)をベースにして開発されたものなのですが、kifPlayer はぼくが開発した[kifviewer](https://github.com/tkgstrator/kifviewer)を参考にしていただいたようなので、なんだか嬉しい限りです。

ソースコードも可読性が良くなり、いろいろ機能も増えたので開発してよかったなと本当に思いました。

## KifuViewer のいいところ

本家の HP でも解説されているのですが、良いところを挙げると、

- SVG で拡大縮小に対して全く劣化しない
- SVG なので PNG などの画像に比べて非常に綺麗
- 評価値表示に対応
- Bttostrap 以外の他のライブラリに全く依存しない
- 高速かつ軽量
- 反転、評価値（解析済みであることが条件）表示に対応

追加の機能としてほしいのは、

- SFEN 形式の読み込みに対応
- 分岐に対応

くらいかなという気がしています。分岐自体はどうやら対応されているようなのですが、手元ではうまく再現できませんでした。

SFEN 形式の読み込みは KIF→SFEN への変換ライブラリを作ればそのまま KifuViewer に読み込ませれば良いと考えています。

### Vuepress に移植する

Vuepress は静的サイトですが、KifuViewer は Javascript だけで動作するので問題なく利用できます。

ただ、ここでどうやって KifuViewer を Vuepress に導入するかということで悩みました。

というのも、Vuepress は記事を Markdown で書くため、いちいち KifuViewer を表示するためのコードを書いていると可読性が悪くなってしまうためです。

なので、KifuViewer を呼び出すためのコマンドのようなものを作成し、Markdown から HTML に変換する際に自動で置換してくれるようなプラグインを作成することにしました。

## [markdown-it-regexp](https://github.com/rlidwka/markdown-it-regexp)

markdown-it-regexp は正規表現で Markdown から任意の文字列を抽出し、それを置換することができるライブラリです。

これを使って自分でコマンドを定義し、それだけにマッチするような正規表現を考えれば良いことになります。

```sh
@[kif](KIF URL)

# 例
@[kif](https://raw.githubusercontent.com/tkgstrator/kifviewer/master/kif/ryu3001.kif)
```

そこで、今回は上のようなコマンドを考えました。これであれば偶然記事中の別の文章がコマンドとして誤って検知されることは殆どないでしょう。

かっこの中には Markdown のリンクを貼るときと同じように URL を指定します。

### KifuViewer の利用方法

```html
<head>
  <link
    href="https://fonts.googleapis.com/icon?family=Material+Icons"
    rel="stylesheet"
  />
</head>
<div tabindex="-1">
  <svg
    id="board"
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0,0,400,540"
  ></svg>
</div>
<script src="kifu-viewer.min.js"></script>
<script>
  new KifuViewer(document.getElementById("board")).load("test-utf8.kif");
</script>
```

さて、KifuViewer は README.md によると上のような書き方で読み込ませるようです。

ただし、`<head></head>`の部分は一つの記事の中にいくつも将棋盤を配置したときに何度も同じのを読み込んでしまうので別途読み込むようにします。また、スクリプトファイル自体も一回読み込めばいいので省略します。

よって、実際にコマンドから置換させるべき文字列は以下のようになります。

```html
<div tabindex="-1">
  <svg
    id="board"
    xmlns="http://www.w3.org/2000/svg"
    viewBox="0,0,400,540"
  ></svg>
</div>
<script>
  new KifuViewer(document.getElementById("board")).load("test-utf8.kif");
</script>
```

このとき、`test-utf8.kif`の部分は自分が指定した KIF ファイルの URL に置き換える必要があることに注意しましょう。

では、それらを実現するような正規表現を考えます。

## プラグインを作成

まず、コマンドを認識するための正規表現ですが、次のものを利用します。

```js
const EMBED_REGEX = /@\[([kif].+)]\([\s]*(.*?)[\s]*[)]/im;
```

正規表現チェックには[正規表現チェッカー](https://www-creators.com/tool/regex-checker)を利用させていただきました。

### 置換するためのコード

Vuepress で Markdown を置換するためのコードのテンプレートは以下のとおりです。

いろいろ調べても意味不明なドキュメントしかでてこないので、これを利用するのが早いと思います。

なお、このコードの開発にあたって[@ckoshien_tech](https://twitter.com/ckoshien_tech)氏に大変お世話になりました。

この場を持ちましてお礼申し上げます。

```js
"use strict";

var Plugin = require("markdown-it-regexp");
const EMBED_REGEX = /@\[([kif].+)]\([\s]*(.*?)[\s]*[)]/im;

// Vuepress Pluginの書き方テンプレート
module.exports = {
  extendMarkdown: (md) => {
    md.use(
      Plugin(EMBED_REGEX, function (match, utils) {
        return "Hello, world!";
      })
    );
  },
  name: "vuepress-plugin-kifviewer",
};
```

で、上のコードは`@[kif](ANY WORD)`を`Hello, world!`に置換するコードです。つまり、`Hello, world!`のところを任意の文字列にすれば、それがそっくりそのまま HTML に埋め込まれます。

そして埋め込むべき文字列は以下の内容です。

```js
`
<div tabindex="-1" class="kifviewer">
    <svg id="${utils.escape(
      match[2]
    )}" xmlns="http://www.w3.org/2000/svg" viewBox="0,0,400,540">
    </svg>
</div>
<script>
    new KifuViewer(document.getElementById("${utils.escape(match[2])}"))
    .load("${utils.escape(match[2])}", "UTF-8");
</script>
`;
```

`${utils.escape(match[2])}`というのは正規表現にマッチした第三パターンを抽出しているので、これが`()`内の URL ということになります。

あとはこれを`Hello, world!`とおきかえてやればプラグインの完成です。

## 完成したもの

###


