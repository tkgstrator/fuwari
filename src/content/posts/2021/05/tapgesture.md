---
title: ContentView自体にタップ判定をつけよう
published: 2021-05-06
description: ContentViewやそれ以上のルートビューにonTapGestureをつけると思わぬ不具合を生んでしまいます
category: Programming
tags: [Swift]
---

## タップジェスチャーを取得する方法

タイトルだけ見て「なんだそれ」って思った方もいるかも知れない。ただ単にタップされたかどうかをとってきたいのであれば、`onTapGesture()` を使えば苦もなく実装できるからだ。

ところがこれでは上手くいかないような状況がある。というのも`onTapGesture()`は同時に一つしか実行できないためだ。これがどういうふうに困るかというのは次の図を見ればわかるのではないかと思う。

![](https://pbs.twimg.com/media/E0r0uuyUYAAHOKL?format=png)

要するにタップしたときの挙動が TabView 自体に備わっているのでめんどくさいことになるのである。

## デモアプリ

例えば以下のコードはタブの中に表示されているコンテンツをタップするとそのタブの番号を返すコードである。

ビルドしてみればわかるが、確かに`Tab Content 1`をタップすれば`1`と表示されるし、`Tab Content 2`をタップすれば`2`と表示される。ここまでは問題がないように思える。

```swift
import SwiftUI

struct ContentView: View {
    @State var selection: Int = 1
    var body: some View {
        TabView(selection: $selection,
                content:  {
                    Text("Tab Content 1").tabItem { Text("Tab1") }.tag(1)
                        .onTapGesture {
                            print(selection)
                        }
                    Text("Tab Content 2").tabItem { Text("Tab2") }.tag(2)
                        .onTapGesture {
                            print(selection)
                        }
                    Text("Tab Content 3").tabItem { Text("Tab3") }.tag(3)
                        .onTapGesture {
                            print(selection)
                        }
                })
    }
}
```

ではこの TabView 自体がタップされたときに別の挙動をしたい場合はどうすればよいだろうか。単純に思いつくのは TabView 自体にも`onTapGesture()`を追加する方法である。TabView 自体に`onTapGesture()`を追加してどういう意味があるのかと思うだろうが、ちょっと前の記事で触れたように「指定時間操作がなければ別の画面に遷移する」というような機能を実装しようとしたら「最後にアプリを操作した時間」というのが必要になる。

よって、最も大きいビュー自体をタップされたかどうかを検知する必要があるというわけだ。

### TabView

```swift
import SwiftUI

struct ContentView: View {
    @State var selection: Int = 1
    var body: some View {
        TabView(selection: $selection,
                content:  {
                    Text("Tab Content 1").tabItem { Text("Tab1") }.tag(1)
                        .onTapGesture {
                            print(selection)
                        }
                    Text("Tab Content 2").tabItem { Text("Tab2") }.tag(2)
                        .onTapGesture {
                            print(selection)
                        }
                    Text("Tab Content 3").tabItem { Text("Tab3") }.tag(3)
                        .onTapGesture {
                            print(selection)
                        }
                })
            // 追加
            .onTapGesture {
                print("TabView")
            }
    }
}
```

で、やってみればわかるのだがこのアプリは想定通りの動作をしない。というのも TabView 自体がタップされた場所で`$selection`の値を変更してタブを切り替えるという動作が実装されているからだ。

つまり、TabView 自体に`onTapGesture()`をつけた時点でそちらの機能が優先されてしまい、タブが切り替わらなくなってしまうのである。

第一、この方式はあまり推奨されない。何故ならこれだと TabView のタップされた判定しかとってこれないからだ。他のビューでも同様にタップされたかの判定を書く必要が生じるが、それはオブジェクト指向に反する。

### App.swift

ならばアプリのルートに対して`onTapGesture()`をつければいいじゃないかという話になるが、やはりこれもタブの切替ができなくなってしまう。

```swift
@main
struct TouchDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onTapGesture {
                    print("TAPPED")
                }
        }
    }
}
```

## 解決策

どうしたものかと頭を悩ませていたのだが、世界中の知識が集まる[StackOverflow](https://stackoverflow.com/questions/63927489/how-to-track-all-touches-across-swiftui-app)に解決策が載っていた。

まず、以下のような Extension を作成する。これは SwiftUI というよりは Objective-C に近いのではないかと勝手に思っている。

```swift
extension UIApplication {
    func addTapGestureRecognizer() {
        guard let window = windows.first else { return }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        tapGesture.requiresExclusiveTouchType = false
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        window.addGestureRecognizer(tapGesture)
    }

    @objc func tapAction(_ sender: UITapGestureRecognizer) {
        print("tapped")
    }
}

extension UIApplication: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true // もし他のジェスチャーと競合したくない場合はfalseを設定する
    }
}
```

最後にこの関数を`onAppear()`を使って ContentView 自体に適用する。

```swift
@main
struct TouchDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear(perform: UIApplication.shared.addTapGestureRecognizer)
        }
    }
}
```

なんとこれだけで終わりである、神かな？


