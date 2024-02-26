---
title: Swiftでのエラーの扱い
published: 2021-04-08
description: SwiftではError型とNSError型を使うことができる
category: Programming
tags: [Swift]
---

## エラーの扱いについて

Swift では Error 型と NSError 型を使うことができる。Error 型は SwiftUI で使われる一般的なエラー型ではあるがエラーコードがなかったりとかゆいところに手が届かなかったりする。

ここでは独自の Error 型を定義し、それを柔軟に使っていくためのチュートリアルを解説する。

## 独自のエラー型を定義しよう

エラーの定義である Enum は Error を継承することはもちろん、ついでに CaseIterable を継承しておくと良い。

今回はアプリが「不明」「期限切れ」「空」「無効」の四パターンのエラーを返すものを想定した。

```swift
enum APPError: Error, CaseIterable {
    case unknown
    case expired
    case empty
    case invalid
}
```

それは Enum を使ってこのように書けるが、これだけだと意味がないので、この APPError に対してエラーの詳細やエラーコードを割り当てていく。

## エラーコード

エラーコードは CustomNSError を継承すれば定義することができる。

```swift
extension APPError: CustomNSError {
    var errorCode: Int {
        switch self {
        case .unknown:
            return 9999
        case .expired:
            return 10000
        case .empty:
            return 2000
        case .invalid:
            return 3000
        }
    }
}
```

## エラー詳細

エラー詳細は`errorDescription`というメンバ変数に割り当てる。これは`LocalizedError`を継承すれば String?型で定義することができる。

```swift
extension APPError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "ERROR_UNKNOWN"
        case .expired:
            return "ERROR_EXPIRED"
        case .empty:
            return "ERROR_EMPTY"
        case .invalid:
            return "ERROR_INVALID"
        }
    }
}
```

これで独自に定義したエラーに対してエラーコードとエラー詳細を設定することができた。

## エラーの呼び出し

SwiftUI においては`throw ERROR`とすることでエラーを呼び出すことができる。これは普通の return などと違い、放置すればクラッシュするので`try?`でエラーをなかったことにするか`do catch`で適切にハンドリングする必要がある。

エラーが呼び出される関数には必ず呼び出される可能性があることを明示しなければならない。

```swift
// OK
func throwError() throws -> () {
    throw (APPError.allCases.randomElement() ?? APPError.unknown)
}
```

例えばこれは定義された APPError 型から適当に一つ選んでエラーを発生させるコードである。`randomElement()`が nil を返す場合があるのでその場合にはとりあえず不明なエラーを返すようにした。

ここでの`throws`(throw ではない)はエラーが発生したときにエラーハンドリングをせずにこの関数を呼び出した関数に「エラー自体」を伝達することを意味する。

なぜならこの関数は`do catch`でエラーハンドリングをしていないにもかかわらず関数内に`throw`があるためにエラーを発生させる可能性があるためである。エラーを発生させる可能性(`throw`)があるが、`do catch`がない関数には必ず`throws`でエラーを投げる可能性があることを明示しなければならないのだ。

```swift
// NG
func throwError() -> () {
    throw (APPError.allCases.randomElement() ?? APPError.unknown)
}
```

なのでこのように`throws`がない関数はコンパイルエラーが発生する。

```swift
// OK
func throwError() -> () {
    do {
        throw (APPError.allCases.randomElement() ?? APPError.unknown)
    } catch {
        print("ERROR")
    }
}
```

このように`do catch`を使ってエラーハンドリングをし、関数からエラーが投げられないようにすれば`throws`を書かなくて済む。ただ、これだとエラーが発生したときに ERROR という文字列が表示されるだけで、これではエラーハンドリングとは言えない。

### エラー処理をする

まず、エラーの中身を見たときはこのように書けば良い。多くのプログラミング言語では`catch`で error が定義されている。Swift の場合もそうなので定義しなくても`error`という変数でエラーの内容をとってくることができる。

```swift
do {
    try throwError()
} catch {
    print(error)
}
```

もしも独自の変数名を与えたい場合は次のようにかけば良い。

```swift
do {
    try throwError()
} catch(let e) {
    print(e)
}
```

`throwError()`は APPError 型を返すのだが、実際にどんな値を受け取っているのか見てみると`empty`や`invalid`という値が返っていていた。

つまり、受け取っているのはただの Enum だということだ。

```swift
do {
    try throwError()
} catch {
    print(error.localizedDescription)
}
```

では肝心の中身を見る話だかこれは`error.errorCode`や`error.errorDescription`のように受け取ることができない。SwiftUI で受け取ることができるのはあくまでも Error 型であり、Error 型は`localizedDescripion`というメンバ変数しか持たないためだ。

ただ、`localizedDescription`を表示すると`errorDescription`の値を表示することはできた。問題は`errorCode`をどうやって受け取るかである。

Swift で使えるエラーには`Error`、`NSError`、`CustomNSError`などがあるが、今回のケースではエラーコードを利用するために`CustomNSError`を継承しているのでこれを利用する。

```swift
do {
    try throwError()
} catch {
    let customNSError = error as? CustomNSError
    print(error.errorCode)
}
```

つまり、上のように CustomNSError にキャストすることでエラーコードを表示することができるようになる。

## アラートでエラー発生

エラーが発生したときにそれを検知してアラートを表示したいケースが多いが、そのたびに何度も Alert の定義を書くのはめんどくさいのでエラーが発生しそうなところに使える ViewModifier を定義した。

```swift
struct AlertView: ViewModifier {
    @Binding var isPresented: Bool
    let error: CustomNSError

    func body(content: Content) -> some View {
        content
            .alert(isPresented: $isPresented) {
                Alert(title: Text("ERROR"), message: Text(error.localizedDescription), dismissButton: nil)
            }
    }
}

extension View {
    func alert(isPresented: Binding<Bool>, error: CustomNSError?) -> some View {
        guard let error = error else { return AnyView(self) }
        return AnyView(self.modifier(AlertView(isPresented: isPresented, error: error)))
    }
}
```

これは単にエラーが発生したら表示するだけなので再利用するのは簡単である。ViewModifier の中身を変えれば自由にカスタマイズすることもできる。
