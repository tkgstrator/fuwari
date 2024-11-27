---
title: GeometryReaderの挙動について学ぶ
published: 2021-10-11
category: Programming
tags: [SwiftUI, Swift]
---

# GeometryReader

##

### Hello, world!

![](https://pbs.twimg.com/media/FBYEOVEVQAUxVeb?format=png&name=4096x4096)

中央に`Hello, world!`が表示され、特に違和感もない。

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Hello, world!")
            .padding()
    }
}
```

### +GeomeyryReader

![](https://pbs.twimg.com/media/FBYEOVGVkAAquAE?format=png&name=4096x4096)

Geometry Reader に対して入れ子にするとデフォルトの上下左右の中央揃えのレイアウトが消える。

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader { geometry in
            Text("Hello, world!")
                .padding()
        }
    }
}
```

### +ScrollView

![](https://pbs.twimg.com/media/FBYEwLNUcAIIsnp?format=png&name=4096x4096)

ScrollView に対しても入れ子にすると上のようになる。見た目は全く変わらないがスクロールができる。

ちなみに GeometryReader に対して青、ScrollView に対して赤の背景色を与えると以下のようなレイヤー構成になっている。

![](https://pbs.twimg.com/media/FBYGItOVQAI7r-Y?format=jpg&name=4096x4096)

#### 誤った使い方

以下は誤った使い方で`ScrollView`は`GeometryReader`を入れ子にするように記述するのが正しい。

このように書くと`Text`の部分にしか ScrollView が適用されなくなる。

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                Text("Hello, world!")
                    .padding()
            }
        }
    }
}
```

![](https://pbs.twimg.com/media/FBYGItKVQAEaFWI?format=jpg&name=4096x4096)

## LazyVGrid を適用してみる

検証用のソースコードとして以下のものを考えた。

```swift
LazyVGrid(columns: Array(repeating: .init(.flexible(minimum: 50, maximum: 100)), count: 4), alignment: .center, spacing: nil, pinnedViews: [], content: {
    ForEach(Range(0...11)) { _ in
        Circle()
            .background(Color.yellow.opacity(0.3))
        }
    })
```

これを見て、一体どんな View が生成されると思うだろうか？

恐らくデバイスの幅に応じて最小 50、最大 100 の円が四つ並んだものが三列あると想像した方が多いだろう。というよりも、そういうものを想定してこのコードを書いたと言って良い。

![](https://pbs.twimg.com/media/FBYKBTMVkAAygYA?format=png&name=large)

ちなみに、円には背景色として不透明度 30%の黄色を指定しているが`Cirlce`は`stroke`を指定しない限りは背景色が真っ黒になるので黄色と黒が混ざって結局黒になることが想定される。

### 実際に書いてみた

![](https://pbs.twimg.com/media/FBYLQUiVcAANAsv?format=jpg&name=4096x4096)

ところが期待に反してそうはならない。

領域自体は横幅 100 ピクセルが確保されているようなのだが、円自体は大きくなっていない。

もちろん、円自体に`frame`等で幅を指定してやれば変化はするだろうが、そうなると大きいデバイスだとスカスカで、小さいデバイスだとキツキツ（ひょっとしたらはみ出してしまうかもしれない）になってしまう。

それではとてもレスポンシブデザインとは言えない。

で、これをやると GeometryReader の値が常に ScrollView のサイズと一致してしまうので`ForEach`の中の円の大きさについては全くわからない。この書き方だと意味がない気がするのだが...

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVGrid(columns: Array(repeating: .init(.flexible(minimum: 50, maximum: 100)), count: 4), alignment: .center, spacing: nil, pinnedViews: [], content: {
                    ForEach(Range(0...11)) { _ in
                        Circle()
                            .background(Color.yellow.opacity(0.3))
                    }
                })
            }
            .background(Color.red.opacity(0.3))
        }
        .background(Color.blue.opacity(0.3))
    }
}
```

|               | width | height |
| :-----------: | :---: | :----: |
| GeometryProxy | 414.0 | 818.0  |

### ScrollView+GeometryReader+LazyVGrid

![](https://pbs.twimg.com/media/FBYLeK0VEAI5lj5?format=jpg&name=4096x4096)

何も変化がないし、GeometryReader の背景色が一段目にしか適応されていないのも違和感がある。

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            GeometryReader { geometry in
                LazyVGrid(columns: Array(repeating: .init(.flexible(minimum: 50, maximum: 100)), count: 4), alignment: .center, spacing: nil, pinnedViews: [], content: {
                    ForEach(Range(0...11)) { _ in
                        Circle()
                            .background(Color.yellow.opacity(0.3))
                    }
                })
            }
            .background(Color.blue.opacity(0.3))
        }
        .background(Color.red.opacity(0.3))
    }
}
```

### ScrollView+LazyVGrid+GeometryReader

![](https://pbs.twimg.com/media/FBYRUv6VgAo7m_0?format=jpg&name=4096x4096)

こうすれば`Circle`に対して`GeometryReader`が効いているので個別の`Circle`の大きさを`GeometryProxy`から知ることができる。

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: .init(.flexible(minimum: 50, maximum: 100)), count: 4), alignment: .center, spacing: nil, pinnedViews: [], content: {
                ForEach(Range(0...11)) { _ in
                    GeometryReader { geometry in
                        Circle()
                            .background(Color.yellow.opacity(0.3))
                    }
                    .background(Color.blue.opacity(0.3))
                }
            })
        }
        .background(Color.red.opacity(0.3))
    }
}
```

|               | width | height |
| :-----------: | :---: | :----: |
| GeometryProxy | 97.5  |  10.0  |

試しに Circle に対する GeomeyryProxy の値を取得してみたところ、横幅 97.5、縦幅 10.0 であることがわかった。縦幅も 97.5 であればよかったのだが、`LazyVGrid`はあくまでも横幅に対するグリッドなので縦幅に関しては何も弄らないという方針なのだろう（もちろんそれが正しい挙動である）

つまり`LazyVGrid`はあくまでも横幅を自動的に調整する仕組みであって、何も指定しなければ縦幅は最小の 10.0 に固定されるということだ。

そして`Circle`はその中で自身を最大化しようとするのでサイズが 10 の円しか表示されないのだと思う。これを解消するためには「横幅制限の許す限り、円を最大化する」という処理を書けば良い。

### contentMode を利用する

![](https://pbs.twimg.com/media/FBYSzJsVkAYkBMw?format=jpg&name=4096x4096)

そこで`contentMode(.fit)`または`contentMode(.fill)`を利用する。

これは元々は単にアスペクト比を維持するためだけのプロパティのはずなのだが`LazyVGrid`内で利用すると横幅に合わせてオブジェクトを最大化することができる。

ただし、拡大率は全く調整できないので`LazyVGrid`の範囲内で許す限り最大まで大きくなってしまう。ちょっと横幅をもたせたい場合には`padding()`を利用するなどしよう。

## View に対しても通用するのか

例えば以下のように`UserView`を 12 個並べるような場合を考えよう。

```swift
struct ContentView: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: .init(.flexible(minimum: 50, maximum: 100)), count: 4), alignment: .center, spacing: nil, pinnedViews: [], content: {
                ForEach(Range(0...11)) { _ in
                    UserView()
                }
            })
        }
        .background(Color.red.opacity(0.3))
    }
}

struct UserView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .strokeBorder(Color.blue, lineWidth: 3)
            .overlay(Text("Nyamo"))
    }
}
```

これはどのように表示されるだろうか？

![](https://pbs.twimg.com/media/FBYUegUVQAIFfTS?format=jpg&name=4096x4096)

恐らくその予想はあたっていて、上のようにやはり縦幅が 10 に固定されてしまいぺっちゃんこの View になってしまう。

これも`contentMode(.fit)`で解決できるだろうか？実はできてしまった（とても嬉しい）

![](https://pbs.twimg.com/media/FBYU8VqUcAE2KKo?format=png&name=4096x4096)

というわけで`LazyVGrid`を使ってコンテンツを正方形内に表示したい場合には`contentMode`を利用するようにしましょう。

### 正方形じゃない場合はどうするのか

例えば、デバイスのサイズに関係なく 4:3 のサイズのボタンを表示したいとしよう。

今回利用した`contentMode`は縦幅を強制的に縦幅と同じにするコードなのでそのままでは利用できない。では、どうするか？

横幅がわかるんだからそこから縦幅を計算させればよいだろうと思うが、そう簡単ではない。

![](https://pbs.twimg.com/media/FBYWmIMVgAAKHtH?format=jpg&name=4096x4096)

```swift
struct UserView: View {
    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.blue, lineWidth: 3)
                .overlay(Text("Nyamo"))
                .frame(width: geometry.size.width, height: geometry.size.width * 0.75, alignment: .center)
        }
        .aspectRatio(contentMode: .fill)
    }
}
```

単にこのように`RoundRectangle`に`frame`の値を突っ込んだだけだと、`LazyVGrid`がその値を読み込めないため「わいの中身、CGSize(97.5, 10.0)で定義してるし間隔そんなにあけなくていいよな」と誤解するので上の図のように詰まってしまう。

詰まらせないためには`UserView()`に対して`frame`の値を指定しなければいけない。だが`UserView`の大きさを知っているのは`GeometryReader`の入れ子内だけである、困った。

一応の解決策としては`UserView()`自体に`contentMode`を指定する方法がある。これをやれば詰まらなくはなるが、どんなに縦幅が小さい View でも常に横幅と同じだけ間隔があいてしまう。

#### 暫定的な対応

```swift
struct UserView: View {
    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.blue, lineWidth: 3)
                .overlay(Text("Nyamo"))
                .frame(width: geometry.size.width, height: geometry.size.width * 3/2, alignment: .center)
        }
        .aspectRatio(contentMode: .fit)
    }
}
```

![](https://pbs.twimg.com/media/FBYWmIKVgAEAKAn?format=png&name=4096x4096)

第一、縦幅の方が横幅よりも長くなったときには使えない。根本的な解決にはなっていない。

![](https://pbs.twimg.com/media/FBYbaF8VUAcL5Sg?format=png&name=4096x4096)

### `aspectRatio`の引数を利用する

正方形以外を利用したい場合には`aspectRatio`の引数を利用する方法がある。

![](https://pbs.twimg.com/media/FBYbaF9VcAQacz0?format=png&name=4096x4096)

例えば、3:2 のアスペクト比のボタンを用意したい場合には`.frame(width: geometry.size.width, height: geometry.size.width * 3/2, alignment: .center)`でアスペクト比を 3:2 にしてからその情報を`UserView`に対して伝えてやれば良い。

注意点としては SwiftUI のアスペクト比は「横の縦に対する比」のようになっているので、3:2 のアスペクト比の場合はその逆数の 2/3 を引数として与えなければいけない。

```swift
struct UserView: View {
    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.blue, lineWidth: 3)
                .overlay(Text("Nyamo"))
                .frame(width: geometry.size.width, height: geometry.size.width * 3/2, alignment: .center)
        }
        .aspectRatio(2/3, contentMode: .fit)
    }
}
```

![](https://pbs.twimg.com/media/FBYbaF8VEAAvRSc?format=png&name=4096x4096)

そしてこの方法を利用することで無事に理想的な表示方法に成功することができた。

## ここまでのまとめ

- LazyVGrid で最大サイズを指定しても自動で大きさを変えてくれない
  - 指定したサイズ内でオブジェクトの大きさを変えたいときは`aspectRation(contentMode)`を利用する
  - 正方形の View であればそれだけで解決する
- 正方形でない場合は`aspectRatio()`の引数にアスペクト比の逆数を入力する
  - このときは`GeometryReader`が必要になる
  - `GeometryReader`は`ForEach`の中に書くこと

## LazyVGrid の仕様とおまけ

### スペースを空ける

![](https://pbs.twimg.com/media/FBYSzJsVkAYkBMw?format=jpg&name=4096x4096)

そのまま`LazyVGrid`を最大化すると ScrollView の上部に張り付いてしまう。

張り付いたからといって問題があるわけではないのだが、これでは余裕が全くないためにちょっと不便を感じるかもしれない。

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: .init(.flexible(minimum: 50, maximum: 100)), count: 4), alignment: .center, spacing: nil, pinnedViews: [], content: {
                ForEach(Range(0...11)) { _ in
                    Circle()
                        .aspectRatio(contentMode: .fill)
                }
            })
            .padding()
        }
        .background(Color.red.opacity(0.3))
    }
}
```

その時は上のように`LazyVGrid`に`padding()`をつけてやると良い。すると自動的にスペースが空いて、それに応じてオブジェクトも小さくなる。

### 中央揃え

### 上下を揃える

![](https://pbs.twimg.com/media/FBYg7cTVUAEUHll?format=png&name=900x900)

今までは縦幅が必ず同じものを想定していたが、場合によっては上のようにテキストの長さが変わることで縦幅のサイズが可変になる場合が考えられる。

このとき、上のように幅が小さいものは最も長いものに合わせる形にしたいのだろうが、可能だろうか？

というわけで、適当に円とテキストを組み合わせる View を作成してみた。

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: .init(.flexible(minimum: 50, maximum: 100)), count: 4), alignment: .center, spacing: nil, pinnedViews: [], content: {
                ForEach(Range(0...11)) { _ in
                    VStack(alignment: .center, spacing: nil, content: {
                        Circle()
                            .aspectRatio(contentMode: .fit)
                        Text(Range(0 ... Int.random(in: 0 ... 10)).map({ _ in "A" }).joined())
                    })
                }
            })
            .padding()
        }
        .background(Color.red.opacity(0.3))
    }
}
```

#### .fit

![](https://pbs.twimg.com/media/FBYiGoaUcAcx4bZ?format=jpg&name=4096x4096)

`.fit`の場合は円の大きさは固定で理想的な状態になったが、上下に対して中央揃えになってしまっているためこれではダメで修正が必要になる。

```swift
struct ContentView: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: .init(.flexible(minimum: 50, maximum: 100)), count: 4), alignment: .center, spacing: nil, pinnedViews: [], content: {
                ForEach(Range(0...11)) { _ in
                    VStack(alignment: .center, spacing: nil, content: {
                        Circle()
                            .aspectRatio(contentMode: .fit)
                        Text(Range(0 ... Int.random(in: 0 ... 10)).map({ _ in "A" }).joined())
                        Spacer()  // 追加
                    })
                }
            })
            .padding()
        }
        .background(Color.red.opacity(0.3))
    }
}
```

というわけで下に`Spacer()`をつけることで、無理やり上に揃えることができる。

`SwiftUI LazyVGrid Position Top`とかで調べてもでてこなかったので、これ以外に方法があるのかは不明なのだがとりあえずこれでできそう。

![](https://pbs.twimg.com/media/FBZdbuFVUAAZ9N8?format=jpg&name=4096x4096)

#### .fill

![](https://pbs.twimg.com/media/FBYiGoaVQAIIDiB?format=jpg&name=4096x4096)

`.fill`の場合は最大まで円を大きくしようとするのでそもそも円の大きさが変わってしまった。

よって、こちらは使えないことがわかる。

## GeometryReader で位置揃え

一番最初にも述べたように`GeometryReader`を利用すると`GeometryReader`内で View の位置を揃えようとするため何もしなければ`.topLeading`のような状態になり左上に View が寄ってしまう。

![](https://pbs.twimg.com/media/FBYEOVGVkAAquAE?format=png&name=4096x4096)

これを中央にしたいわけなのだが、どのデバイスでも必ず中央にするにはどうすればよいのかという問題である。

### 要件

- どのデバイスでも相対的に同じ位置に表示する
- ボタンなどは下側に表示したいのだが、それにも対応する

この仕様を達成するには`position(x: y:)`を利用するのが最も手っ取り早い。何故なら`GeometryProxy`で対象の View の幅や高さは簡単に取得できるためです。

#### `.position`について

これは View の中央を`position()`で指定された場所に移動させるという効果を持ちます。

![](https://pbs.twimg.com/media/FBZe7wqVkActvnJ?format=png&name=small)

幅 400、高さ 300 の`GeometryReader`の領域を赤く表示すると次のようになります。もし仮に`Circle`の`position`として`(0, 0)`をしてすれば円の中心が`(0, 0)`に移動するので上のような図の状態になるはずです。

#### 何もしないとき

![](https://pbs.twimg.com/media/FBZfmiAVQAEsXox?format=jpg&name=4096x4096)

単に`GeometryReader`に円を表示しただけだとこのように左上に寄っただけになります。

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .center, spacing: nil, content: {
            Spacer(minLength: 100)
            HStack(alignment: .center, spacing: nil, content: {
                Spacer(minLength: 100)
                GeometryReader { geometry in
                    Circle()
                        .strokeBorder(Color.blue, lineWidth: 5)
                        .frame(width: 80, height: 80, alignment: .center)
                }
                .background(Color.red.opacity(0.3))
            })
        })
    }
}
```

#### `(0, 0)`を指定したとき

![](https://pbs.twimg.com/media/FBZfmi0UUAMOfHz?format=jpg&name=4096x4096)

このように予想図通りになります。

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .center, spacing: nil, content: {
            Spacer(minLength: 100)
            HStack(alignment: .center, spacing: nil, content: {
                Spacer(minLength: 100)
                GeometryReader { geometry in
                    Circle()
                        .strokeBorder(Color.blue, lineWidth: 5)
                        .frame(width: 80, height: 80, alignment: .center)
                        .position(x: 0, y: 0)  // 追加
                }
                .background(Color.red.opacity(0.3))
            })
        })
    }
}
```

### GeometryProxy

`GeometryProxy`の frame には`.global`と`.local`の二つのプロパティがあります。

| frame | global |     local      |
| :---: | :----: | :------------: |
| View  |  root  | その View 自身 |

`.global`は rootView を表し、`.local`はその View 自身を指します。

| frame | 意味 |
| :---: | :--: |
| minX  |  0   |
| midX  | 中央 |
| maxX  |  端  |
| minY  |  0   |
| midY  | 中央 |
| maxY  |  端  |

更に特殊な六つのプロパティを持ちます。どんな意味なのかは[[SwiftUI] GeometryReader で View のサイズを知る](https://blog.personal-factory.com/2019/12/08/how-to-know-coorginate-space-by-geometryreader/)で詳しく解説されています。

![](https://pbs.twimg.com/media/FBZpKErVkAQSTj6?format=png&name=900x900)

まあ図を見ればそこまで難しくは感じないと思います。真ん中に表示したかったら変にコードを書かなくても`midX`で十分だということです。

![](https://pbs.twimg.com/media/FBZfzmEVIAAk7eL?format=jpg&name=4096x4096)

実際に実装してみると、このように簡単に書くことができます。

## ボタンのときの注意

ボタンを作成するときに`position`の設定を誤ると表示されているボタンと実際に押せる位置がズレるというとんでもないバグが起きます。

なので以下のコードを参考にしてください。`overlay`ではなく`background`を利用するのが良いです。

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader { geometry in
            Button(action: {}, label: {
                Text("Login")
                    .frame(width: min(geometry.size.width * 0.4, 400), height: 60, alignment: .center)
                    .background(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.blue, lineWidth: 5))
            })
            .position(x: geometry.frame(in: .local).midX, y: geometry.frame(in: .local).maxY - 80)
        }
        .background(Color.red.opacity(0.3))
    }
}
```
