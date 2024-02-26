---
title: プロトコルとかクラスとか
published: 2021-04-20
description: プロトコルを使って柔軟にクラスを書いてみます
category: Programming
tags: [Swift]
---

## プロトコル

プロトコルを学ぶにあたって、なぜプロトコルが必要なのかを理解しておく必要がある。

これに関しては[こちらの記事](https://qiita.com/Howasuto/items/546e615325f9feca55f7)が大変参考になりました。

::: tip

「プロトコルはクラスや構造体が実装するプロパティとメソッドの最低限の決まり事を設定する機能」とおぼえておけば良い

:::

同様の機能としてスーパークラスというものがあるが、Swift の構造体にはスーパークラスという概念がない。そのため、代わりにプロトコルを使うというわけである。

## プロトコルのメリット

参考文献を見ながら自分でも確認する感じで読みすすめていきました。

### 実装をあとから変更できる

プロトコルは定義（プロパティ名や型）だけを指定できるので、実際そこにどんな値を入れるかはクラスや構造体ごとに変えることができる。

### 構造体にもつかえる

先程も述べたように Swift では構造体に対して継承ができません。

が、プロトコルであればほとんど同じようなことができます。

### 複数継承できる

クラスは一つしか継承できませんが、プロトコルであれば複数適用することができます。

## プロトコルを考える

API と通信を行なうためには以下のような情報が必要になります。

- 基本 URL
  - API サーバの URL
  - "https://tkgling.netlify.app/api/"
- パス
  - "session_token"
- エンドポイント
  - たたく API の URL
  - 基本 URL とパスの組み合わせ
  - "https://tkgling.netlify.app/api/session_token"
- メソッド
  - POST とか GET とか PUT とか
- ヘッダー
  - 認証情報を入れたりとか
- エンコーディング方式
  - URL エンコードか JSON エンコードかパラメータエンコードか
- パラメータ
  - Body に入れるデータ

なのでこれらを全部プロトコルで定義してしまえばいいような気がしますが、パラメータはメソッドが GET のときには不要ですし、ライブラリ化するときには一つの API サーバに対して通信することを想定しているのですから基本 URL も不要です。

パスと基本 URL があればいいのでエンドポイントも不要ですし、ヘッダーが常に認証情報しか保たないのであればこれもやはり不要です。エンコーディング方式も「POST と PUT 以外であれば URL エンコード」というような仕様になっていれば、実際に必要なのは次の三つの情報になります。

## プロトコルを書いてみる

例えば以下のようなシンプルなものを考えてみます。

### 単純なプロトコルのみ

```swift
protocol RequestType {
    var method: String { get }
    var parameters: [String: Any]? { get }
    var path: String { get }
}

class Request: RequestType {
    var method: String // 必須
    var parameters: [String : Any]? // 必須
    var path: String // 必須

    init(method: String, path: String, paramaters: [String: Any]? = nil) {
        self.method = method
        self.parameters = paramaters
        self.path = path
    }
}
```

そして以下のように実行してみます。

POST という値でメソッドを初期化しているので、当然結果は POST が出力されます。

```swift
let request = Request(method: "POST", path: "session_token")
print(request.method) // POST
print((request as RequestType).method) // POST
```

### Extension で拡張する

次に、Extension で拡張して既に定義されているプロパティに何らかの値を持たせてみます。

```swift
protocol RequestType {
    var method: String { get }
    var parameters: [String: Any]? { get }
    var path: String { get }
}

extension RequestType {
    var method: String { return "GET" }
}

class Request: RequestType {
    var method: String // 必須
    var parameters: [String : Any]? // 必須
    var path: String // 必須

    init(method: String, path: String, paramaters: [String: Any]? = nil) {
        self.method = method
        self.parameters = paramaters
        self.path = path
    }
}
```

するとこれも先程と同じくどちらも POST という値を返します。

どうやら、Extension で何らかの値を設定してもクラス側で上書きされる（または Extension の値よりもクラスの値が優先して呼び出される）ようです。

```swift
let request = Request(method: "POST", path: "session_token")
print(request.method) // POST
print((request as RequestType).method) // POST
```

### パラメータを消してみる

Extension で定義しているのでプロトコルから method を取り除いてみます。

するとプロトコルを適用している Request は必ずしも method プロパティをもつ必要がなくなります。

```swift
protocol RequestType {
    // methodを削除
    var parameters: [String: Any]? { get }
    var path: String { get }
}

extension RequestType {
    var method: String { return "GET" }
}

class Request: RequestType {
    var method: String // 必須ではない
    var parameters: [String : Any]? // 必須
    var path: String // 必須

    init(method: String, path: String, paramaters: [String: Any]? = nil) {
        self.method = method
        self.parameters = paramaters
        self.path = path
    }
}
```

この状態で同じように実行してみるとなんと結果が変わってしまいました。

```swift
let request = Request(method: "POST", path: "session_token")
print(request.method) // POST
print((request as RequestType).method) // GET
```

### クラスからも消してみる

```swift
protocol RequestType {
    var parameters: [String: Any]? { get }
    var path: String { get }
}

extension RequestType {
    var method: String { return "GET" }
}

class Request: RequestType {
    var parameters: [String : Any]?
    var path: String

    init(path: String, paramaters: [String: Any]? = nil) {
        self.parameters = paramaters
        self.path = path
    }
}
```

クラスからもプロパティを消して`request.method`が呼び出すことができるのかどうかは気になるところなのですが、Request クラスは RequestType を継承しているため問題なく呼び出すことができます。

そして、このときは（当たり前ですが）Extension 側のプロパティが呼ばれるということです。

```swift
let request = Request(path: "session_token")
print(request.method) // GET
print((request as RequestType).method) // GET
```

ここまでをまとめるとこうなります。

つまり、プロトコルには宣言されていないが Extension で宣言したプロパティは、静的型付けをして呼び出すと Extension 側の値が呼び出されるということになります。

| プロトコル宣言 | Extension | クラス宣言 | メソッド  |    値     |
| :------------: | :-------: | :--------: | :-------: | :-------: |
|      あり      |   あり    |    必須    | 静的/動的 |  クラス   |
|      あり      |   なし    |    必須    | 静的/動的 |  クラス   |
|      なし      |   あり    |    あり    |   静的    | Extension |
|      なし      |   あり    |    あり    |   動的    |  クラス   |
|      なし      |   あり    |    なし    | 静的/動的 | Extension |

## この仕様を利用する

この仕様を利用すれば必須パラメータはプロトコルに直接書き、オプショナルなパラメータは Extension に書いてそのプロトコルを継承したクラスを書くのがスマートな方法になりそうです。

```swift
protocol RequestType {
    var method: String { get }
    var parameters: [String: Any]? { get }
    var path: String { get }
}

extension RequestType {
    var baseURL: String { "https://tkgling.netlify.app/api/" }
    var headers: [String: String]? { nil }
    var encoding: ParameterEncoding { URLEncoding.default }
}

class Request: RequestType {
    var method: String // 必須
    var parameters: [String : Any]? // 必須
    var path: String // 必須

    init(method: String, path: String, paramaters: [String: Any]? = nil) {
        self.method = method
        self.parameters = paramaters
        self.path = path
    }
}
```

このデータに対しては以下のようにアクセスできる。Request クラスで定義しておらず、必須でないプロパティにアクセスできるのは便利な気がしている。

もしもユーザがそれらのプロパティが必要だと思えば、クラスに書いてしまえばいいのである。

```swift
// 型はRequestでなくRequestTypeにすること
func remote(request: RequestType) -> Void {
    print(request.method) // Request
    print(request.parameters) // Request
    print(request.path) // Request
    print(request.headers) // RequestType
    print(request.baseURL) // RequestType
    print(request.encoding) // RequestType
    // すべてのデータにアクセスできる！！
}

let request = Request(method: "POST", path: "token")
remote(request: request)
```

## 計算プロパティにしてみる

現在の Extension はこの様になっているが、エンコーディングの部分はメソッドの値によって動的に切り替えたいわけである。

```swift
extension RequestType {
    var baseURL: String { "https://tkgling.netlify.app/api/" }
    var headers: [String: String]? { nil }
    var encoding: ParameterEncoding { URLEncoding.default }
}
```

単純に`self.method`で切り替えるようにすると後で上書きしたときに（今回の場合は get しか method に設定されていないので上書きされることはないが）データを正しくとってくることができなくなってしまう。

よって、encoding の値を参照する度に毎回 method の値を調べ、その値によって変わるような仕組みにしたいのである。

これは計算プロパティで簡単に実装できる。つまり、以下のように書けば良い。

```swift
extension RequestType {
    var baseURL: String { "https://tkgling.netlify.app/api/" }
    var headers: [String: String]? { nil }
    var encoding: ParameterEncoding {
        get {
            switch self.method {
                case .post:
                    return JSONEncoding.default
                case .put:
                    return JSONEncoding.default
                default:
                    return URLEncoding.default
            }
        }
     }
}
```

これの良いところは全ての設定を RequestType プロトコルで行なうことで、実際に Request クラスを書くユーザに対しては秘匿になっている点である。

要するに、コードを書く人間はエンコーディング方式を全く気にせず Request クラス（ないしは RequestType プロトコルを適用したクラス）を書くことができるわけである。

そして、デフォルトでは POST リクエストであれば自動的に JSONEncoding.default が使われてしまうのだが、もしもあるリクエストは POST メソッドなのだが JSONEncoding.default とは違うエンコーディングが使いたければ、

```swift
class Request: RequestType {
    // Extensionの値が上書きされる！
    var encoding: ParameterEncoding = JSONEncoding.queryString
}
```

勝手に自分でエンコーディングを設定すればよいのである。

ただし、これは Request クラスのプロパティとして設定されているので RequestType プロトコルで呼び出したメソッドに対してはそのまま`request.encoding`と呼び出すと予期しない値を参照してしまう。

```swift
// RequestTypeプロトコルとして呼び出す
func remote(request: RequestType) -> Void {
    print(request.encoding) // RequsetType -> URLEncoding
    print((request as! Request).encoding) // Request -> JSONEncoding.queryString
}

// Requestクラスとして呼び出す
func remote(request: Request) -> Void {
    print(request.encoding) // Request -> JSONEncoding.queryString
    print((request as! Request).encoding) // Request -> JSONEncoding.queryString
}
```

ただ、下の Request クラスとして呼び出すメソッドは書きたくない。これだとたった一つの Request クラスでしか引数にできない。

ライブラリとしては個別の RequestType プロトコルの適用クラスではなく、引数は常に RequestType プロトコル準拠の全てのクラスというようにしたいのである。

### 読み込み側で対応してみる

ジェネリクスで対応できないかとやってみた。

```swift
protocol RequestType {
    var method: String { get }
    var parameters: [String: Any]? { get }
    var path: String { get }

    init(method: String, path: String, parameters: [String: Any]?)
}

extension RequestType {
    var baseURL: String { "https://tkgling.netlify.app/api/" }
    var headers: [String: String]? { nil }
    var encoding: ParameterEncoding { URLEncoding.default }
}

class Request: RequestType {
    var method: String
    var parameters: [String : Any]?
    var path: String

    required init(method: String, path: String, parameters: [String: Any]? = nil) {
        self.method = method
        self.parameters = parameters
        self.path = path
        self.encoding = JSONEncoding.queryString
    }
}

// この三つは同値と思われる
func remote(request: RequestType) -> Void {
}

func remote<T>(request: T) where T: RequestType -> Void {
    print((request as! T).encoding) // RequsetType -> URLEncoding
}

func remote<T: RequestType>(request: T) -> Void {
    print((request as! T).encoding) // RequsetType -> URLEncoding
}
```

すると読み込み時ではちゃんと Request 型としているのに、`encoding`のプロパティを参照すると何故か RequestType の Extension の値の方が参照されてしまう。

しかしどうもクラスのプロパティを参照することはできないみたいなのでこちらの方向は諦めた。上手いこと RequestType プロトコルの値を変えてしまうほうが楽そうだ。
