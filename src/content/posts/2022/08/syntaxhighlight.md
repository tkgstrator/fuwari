---
title: Denoにシンタックスハイライトをつける
published: 2022-08-29
description: Denoではデフォルトでシンタックスハイライトが効くはずなのですが、なぜか効かなかったのでその対応方法について書きます
category: Programming
tags: [Deno, Typescript]
---

## シンタックスハイライト

シンタックスハイライトとは、コードブロックに書かれたコードに対していい感じに色を付けてくれる仕組みのこと。

これをやるにはコードブロック内のコードの解析が必要なので Javascript の手を借りる必要がありますが、シンタックスハイライトをするためのプラグインというものは既に開発されて普及しており、

- [Prism.js](https://prismjs.com/)
- [highlight.js](https://highlightjs.org/)

あたりが有名なものかと思います。

で、Deno は Prism.js をサポートしているはずなのですが、何故かシンタックスハイライトが効きません。おかしいですね。

### main.ts

```ts
// Add syntax highlighting support for C by default
import "https://esm.sh/prismjs@1.28.0/components/prism-c?no-check";

export { UnoCSS };
export type UnoConfig = typeof UnoCSS extends (
  arg: infer P | undefined
) => unknown
  ? P
  : never;
```

それもそのはずで、`deps.ts`を確認してみると、デフォルトで対応しているのは C 言語のみで（一応 js 指定で Javascript などもシンタックスハイライトが効くが ts は効かない）、それ以外はオプショナルだからです。

> なお、この章の執筆にあたっては[@p1atdev](https://twitter.com/p1atdev)氏にご助力を頂きました。

よって、ユーザーが個別にシンタックスハイライトを効かせたいのであれば、それを`main.ts`に伝える必要があります。

で、サポートしている言語については[GitHub](https://github.com/PrismJS/prism/tree/master/components)で公開されているので、同じような感じで`main.ts`に追記するだけです。

うちのブログでは`Swift`, `Python`, `Typescript`, `JSON`を扱うことが多かったので、

```ts
import "https://esm.sh/prismjs@1.28.0/components/prism-swift.min?no-check";
import "https://esm.sh/prismjs@1.28.0/components/prism-typescript.min?no-check";
import "https://esm.sh/prismjs@1.28.0/components/prism-python.min?no-check";
import "https://esm.sh/prismjs@1.28.0/components/prism-bash.min?no-check";
import "https://esm.sh/prismjs@1.28.0/components/prism-json.min?no-check";
import "https://esm.sh/prismjs@1.28.0/components/prism-scheme.min?no-check";
```

を追記しました。

これで問題なく Typescript などに対してもシンタックスハイライトが効くようになります。シンタックスハイライトが効くか効かないかでコードブロックの可読性に大きく関わるので、うまく対応させられてよかったです。

記事は以上。
