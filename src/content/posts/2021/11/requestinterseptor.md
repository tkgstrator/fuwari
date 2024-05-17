---
title: Request Interceptorで有効期限付きAPIにリクエストを送る
published: 2021-11-19
description: Alamofireにこんな機能あったのかということで試してみました
category: Programming
tags: [Swift, Alamofire]
---

# Request Interceptor

`RequestInterceptor`とは`RequestAdaptor`と`RequestRetrier`を合体させて一つにしたもの。

じゃあそれぞれ一体どんな役割を持っているのかということを解説しよう。

## RequestAdapter

> Alamofire’s RequestAdapter protocol allows each URLRequest that’s to be performed by a Session to be inspected and mutated before being issued over the network. One very common use of an adapter is to add an Authorization header to requests behind a certain type of authentication.

Alamofire の公式ドキュメントにはこうある。

要するにこれを使えばリクエストを送る前にヘッダー部分に認証用のキーを追加できる、とある。

```swift
func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void)
```

`RequestAdapter`は上のようなプロトコルを持っているので、準拠するクラス等はこれに適合する必要がある。

```swift
let accessToken: String

func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
    var urlRequest = urlRequest
    urlRequest.headers.add(.authorization(bearerToken: accessToken))

    completion(.success(urlRequest))
}
```

サンプルコードによるとこんな感じで使う。

この場合はどこかで`accessToken`を持っておいて、その値をリクエストが送られる前に認証に adapt(適合)するように変化させるというわけである、なるほど賢い。

## RequestRetrier

> Alamofire’s RequestRetrier protocol allows a Request that encountered an Error while being executed to be retried. This includes Errors produced at any stage of Alamofire’s request pipeline.

Alamofire の公式ドキュメントにはこうある。

つまり、リクエストを送ってエラーが発生したときに自動的に実行される Delegate のようなものである。

```swift
func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void)
```

で、準拠するのに必要なプロトコルは上の通り。

`RetryResult`は以下で表される Enum で、次のような値を持っている。

```swift
/// Outcome of determination whether retry is necessary.
public enum RetryResult {
    /// Retry should be attempted immediately.
    case retry
    /// Retry should be attempted after the associated `TimeInterval`.
    case retryWithDelay(TimeInterval)
    /// Do not retry.
    case doNotRetry
    /// Do not retry due to the associated `Error`.
    case doNotRetryWithError(Error)
}
```

これを使って実装すると以下のようなサンプルコードになる。

```swift
open func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
    if request.retryCount < retryLimit,
       let httpMethod = request.request?.method,
       retryableHTTPMethods.contains(httpMethod),
       shouldRetry(response: request.response, error: error) {
        let timeDelay = pow(Double(exponentialBackoffBase), Double(request.retryCount)) * exponentialBackoffScale
        completion(.retryWithDelay(timeDelay))
    } else {
        completion(.doNotRetry)
    }
}
```

リトライ回数が`retryLimit`以下なら遅延を入れて再実行するという仕組みである。

`retryLimit`は関数内で定義しても意味ないので、まあ親クラスが持っているとかそんなんだとおもう。

これを使えば`adapt`でリクエストごとに自動的に認証用ヘッダーを付け、有効期限切れで失敗すれば`retry`でトークンを再生成してリトライするという挙動が簡単に実装できそうな気がする。

で、この仕組みを開発中の SplatNet2 ライブラリに組み込んでみることにしました。

## SplatNet2

エラー処理を特に何も考えないのであれば`DataResponsePublisher`を使うのが手っ取り早いのだが、SplatNet2 では正しくエラーを返したかったためエラーの中身を変換してから利用する`AnyPublisher`を採用した。

`SplatNet2`クラスを`RequestInterceptor`プロトコルに準拠させ、以下のような感じでコードを書く。

```swift
extension SplatNet2: RequestInterceptor {
    public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Swift.Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        // ヘッダーにUserAgentを追加
        urlRequest.headers.add(.userAgent("Salmonia3/tkgling"))
        // ヘッダーに認証情報を追加
        urlRequest.headers.add(HTTPHeader(name: "cookie", value: "iksm_session=\(iksmSession)"))
        completion(.success(urlRequest))
    }

    public func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        // リトライ回数が一回以下の場合実行する
        if request.retryCount < 1 {
        getCookie(sessionToken: sessionToken)
            .sink(receiveCompletion: { result in
                switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        // 認証情報の再生成に失敗したらリトライせずに終了
                        completion(.doNotRetry)
                }
            }, receiveValue: { response in
                self.account = response
                // 成功したのでリトライする
                completion(.retry)
            })
            .store(in: &task)
        }
    }
}
```

これだけで認証に失敗したらリトライして再生成ができる。

個別に何かを書く必要もない、神かな？
