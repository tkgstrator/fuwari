---
title: NextJSのテンプレートを理解しよう 
published: 2024-05-07
description: 普段はVueばっかりなのでたまにはReactを勉強してみることにしました 
category: Programming
tags: [NextJS, React, TypeScript]
---

## NextJS

普段Bunを使っているのでチュートリアルに従ってNextJSのプロジェクトを作成してみます。

```zsh
.
├── src/
│   └── app/
│       ├── favicon.ico
│       ├── globals.css
│       ├── layout.tsx
│       └── page.tsx
├── .gitignore
├── biome.json
├── bun.lockb
├── next.config.mjs
├── package.json
├── postcss.config.mjs
├── tailwind.config.ts
└── tsconfig.json
```

すると上のようなファイルが生成されました。

この状態で`bun run dev`を実行すると`next dev`が実行されてサーバーが立ち上がります。

### SASS/SCSS

基本的にはtailwind cssを利用することが多いと思うのですが、どうしても独自のフォントを利用したい場合はSASSをコンパイルできるようにする必要があります。

[公式ドキュメント](https://nextjs.org/docs/app/building-your-application/styling/sass)に書いてあるのでそれを見てみます。

```zsh
bun add -D sass
```

あとはこの設定を反映させるように`next.config.mjs`を修正します。

```mjs
const path = require('path')
 
module.exports = {
  sassOptions: {
    includePaths: [path.join(__dirname, 'styles')],
  },
}
```

公式ドキュメントにはこのように書いているのですが、ES Moduleではこの記法は利用できないので、

```mjs
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

module.exports = {
  sassOptions: {
    includePaths: [path.join(__dirname, 'styles')],
  },
}
```

として`__dirname`を参照できるようにしましょう。

で、実際にこのパスがどこを参照しているかチェックしてみると`/home/bun/app/styles`と表示されました。

