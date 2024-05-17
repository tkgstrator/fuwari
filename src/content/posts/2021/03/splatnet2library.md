---
title: SplatNet2のライブラリを更新している
published: 2021-03-26
category: Programming
tags: [Swift]
---

## SplatNet2 ライブラリ

[SplatNet2](https://github.com/tkgstrator/SplatNet2/tree/develop)

Swift で簡単に API を叩けるライブラリ、のつもりで作成したのだがあまりにもゴミコードだったので泣いています。

まあ簡単にいえば iksm_session をとってきたり更新したり、サーモンラン用のリザルトをとってきたりとできるコードだったのですがあまりに酷いので書き直すことにしました。

iOS13 以降には Combine という面白い仕組みがあるのでこれを利用すればクロージャの数を減らしつつ良いコードが書けそうな気がします。

Salmonia3 は以下の参考記事を利用させていただいて Realm にデータを書き込む際に Codable を使って一気に変換しているのですが、よく考えたら API のレスポンスをライブラリが上手く整形してやればこんな処理は不要なわけです。

[【Swift4】Realm+Codable を使ったお手軽な DB Part.1（モデル編）](https://qiita.com/cottpan/items/b75abd5d4e4ce73e00f2)

つまり、何らかのクラスや構造体を返してしまえばいちいちキーなんて使わなくてもメンバ変数を使ってパパっと値をとってこれるわけです。

ライブラリからエラーを起こさずに値が返ってきている時点でちゃんとデータが入っていることは間違いなく、（返り値に対する）バリデーションも不要になります。これはなんか高便利そうですね？

## Combine + Alamofire

というわけで、以下の記事を参考に Combine を使ってタスクを渡してそれをクロージャで処理できるライブラリをつくることにしました。

[Combine+Alamofire+SwiftUI で API 実行](https://qiita.com/shira-shun/items/778e65308f26860664fc)

クロージャを使う仕組みは`@escaping`を使うのと対して変わらないのですが、API を叩く際のプロトコルを決めておくことで新しいエンドポイントがでたときにも柔軟に対応することができます。

```swift
protocol APIProtocol {
    associatedtype ResponseType: Decodable

    var method: HTTPMethod { get }
    var baseURL: URL { get }
    var path: String { get set }
    var headers: [String: String[? { get }
    var allowConstrainedNetworkAccess: Bool { get }
}

extension APIProtocol {
    var baseURL: URL {
        return URL(string: "https://app.splatoon2.nintendo.net/api/")!
    }

    var headers: [String: String[? {
        return nil
    }

    var allowConstrainedNetworkAccess: Bool {
        return true
    }
}
```

そして API プロトコルを継承したリクエストプロトコルを作ります

```swift
protocol RequestProtocol: APIProtocol, URLRequestConvertible {
    var parameters: Parameters? { get }
    var encoding: JSONEncoding { get }
}

extension RequestProtocol {
    var encoding: JSONEncoding {
        return JSONEncoding.default
    }

    public func asURLRequest() throws -> URLRequest {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = headers
        request.timeoutInterval = TimeInterval(5)
        request.allowsConstrainedNetworkAccess = allowConstrainedNetworkAccess

        if let params = parameters {
            request = try encoding.encode(request, with: params)
        }

        return request
    }
}
```

ここでは Alamofire の構造体が良かったのでそのまま利用したとのこと。なので`import Alamofire`を忘れないようにしましょう。

参考記事では URLEncoding を採用していますが、SplatNet2 はほぼすべてのリクエストで JSONEncoding しかつかわないので問題ないでしょう。唯一の例外が s2s API なのですがそれはそれでまた別の話。

なので Encoding として型は JSONEncoding ではなくて Encoding のようなものを持ちたかったのですが、それがなかったので少し別の方法を考えなくてはいけません。

`asURLRequest()`で URLRequest を作成してそれを Alamofire で実行するという仕組みです。

```swift
import Foundation
import Combine
import Alamofire
import SwiftyJSON

struct NetworkPublisher {

    private static let contentType = ["application/json"[
    private static let retryCount = 1
    static let decoder: JSONDecoder()

    static func publish<T: RequestProtocol, V: Decodable>(_ request: T) -> Future<V.ResponseType, APIError> {

        return Future { promise in
            let alamofire = AF.request(request)
                .validate(statusCode: 200...300)
                .validate(contentType: contentType)
                .cURLDescription { request in
                    print(request)
                }
                .responseJSON { response in
                    switch response.result {
                    case .success(let value):
                        do {
                            let json = try JSON(value).rawData()
                            let data = try decoder.decode(V.self, from: json)
                            print(data)
                            promise(.success(data))
                        } catch(let error) {
                            print(error)
                            promise(.failure(APIError.invalid))
                        }
                    case .failure(let error):
                        print(error)
                        promise(.failure(APIError.failure))
                    }
                }
            alamofire.resume()
        }
    }
}

public enum APIError: Error {
    case failure
    case invalid
    case requests
    case unavailable
    case upgrade
    case unknown
    case badrequests
}
```

今回は意味もなく（おい）SwiftyJSON を導入しているので JSONDecoder のところの記述が少し異なります。

まあ多分気にしなくても大丈夫。

## 進捗情報

とりあえずリザルトの ID をを指定すれば取得できるようにはなりました。

SplatNet2 のバグなのかは知らないのですが、イベントなしの WAVE のキーが water-levels とかいう謎な値になっています。まあひょっとしたら-と返すのがダサくてそうしたのかもしれません。

Wave も Event も Enum でそれぞれ値があるのですが、このまま文字列で返したほうがいいのかどうかは考えどころですね。

いまは Swift 風に LCC で変数名を設定していて、ネストも SplatNet2 準拠なのですが時刻のデータなどは普通にネストに入れてしまってもいいような気がします（startTime、endTime、playTime）の三つが並んでいるのが若干違和感。

で、ここまで書いておいてステージ ID が取れていないことに気付いたのですが、今日中に頑張って直したいと思います。
