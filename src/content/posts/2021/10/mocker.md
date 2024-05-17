---
title: Mockerでテスト環境をつくる
published: 2021-10-01
description: APIテストをMockerでどうにかしてみます
category: Programming
tags: [Swift]
---

# Mocker

## 使い方

JSON を扱うライブラリの場合、Mocker とは別に SwiftyJSON もあると良い。

```swift
func testExample() throws {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.

    /// 非同期で値を返す(completion内の内容が返るのを待つ)テストの場合、これを定義しないとダメ
    let expectation = expectation(description: "Expectation")
    /// 返ってくるダミーデータ
    let response: [String: String] = [
        "x_product_version": "9.99.0",
        "api_version": "99991231"
    ]

    /// アクセスする先のURL
    let url = URL(string: "https://h505nylwxl.execute-api.ap-northeast-1.amazonaws.com/dev/version")!
    /// Mockの定義(内容については後述)
    let mock = Mock(url: url, dataType: .json, statusCode: 200, data: [
        .get : try! JSON(response).rawData() // Data containing the JSON response
    ])
    /// Mockを登録
    mock.register()

    /// URLSessionでリクエストを送る
    URLSession.shared.dataTask(with: url) { (data, response, error) in
        /// data, responseがnilならエラーを返す
        XCTAssertNotNil(data)
        XCTAssertNotNil(response)
        /// errorがnilでなければエラーを返す
        XCTAssertNil(error)

        /// アンラップして中身を取り出す
        if let data = data {
            do {
                XCTAssertNoThrow(try JSON(data: data))
                let json = try JSON(data: data)
                /// 中身を表示
                print(json)
            } catch {
            }
        }
        /// 終了を伝えるおまじない
        expectation.fulfill()
    }.resume()
    /// expectationの内容が終わる(fulfill()が呼ばれる)のを最大10秒間待つ
    wait(for: [expectation], timeout: 10.0)
}
```

大雑把にこういうような内容になっている。公式ドキュメントが古く、そのまま書いただけでは全く動作しないのが困る。

### Mock の定義

```swift
/// Mockの定義(内容については後述)
let mock = Mock(url: url, dataType: .json, statusCode: 200, data: [
    .get : try! JSON(response).rawData() // Data containing the JSON response
])
```

さて、ここの定義の意味なのだがちゃんと検証したわけではないのでいろいろ疑問は残るのだが、

「url で指定された URL に対してアクセスしたときに、dataType で指定される Content-Type、statusCode で指定されるステータスコードでデータを返す」ということを定義するようだ。

また、そのときに GET と POST といったようにメソッドによって返す値を切り替えることもできる。

値は Data 型でないといけないので、`Dictionary->JSON->Data`という変換を経て値を返すようにしている。

::: tip 返り値について

よく考えたらわざわざ`JSON`を経由する必要はないかもしれない。

:::

## Alamofire

実はこの Mocker は`URLSession`だけでなく`Alamofire`に対しても使うことができます。

ただし、ちょっと使い方が異なるのでそれをメモしておきます。

```swift
// 通常の使い方
AF.request("https://httpbin.org/get").responseJSON { response in
    debugPrint(response)
}
```

Alamofire は`AF`というインスタンス（モジュール名？）を持っているため、これを利用して上のようにリクエストを送ることが多いと思います。

ですが、この書き方では Mocker は動作しません。

```swift
let configuration = URLSessionConfiguration.af.default
configuration.protocolClasses = [MockingURLProtocol.self]
let sessionManager = Alamofire.Session(configuration: configuration)

sessionManager.request("https://httpbin.org/get").responseJSON { response in
    debugPrint(response)
}
```

上のように一度`MockerURLProtocol`を`Configuration`として設定してセッション用のインスタンスを作成し、それを利用して通信を行う必要があります。
