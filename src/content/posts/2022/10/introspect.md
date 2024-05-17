---
title: SwiftUI+Introspect
published: 2022-10-18
description: Introspectを使ってSwiftUIをカスタマイズする話
category: Programming
tags: [SwiftUI, Swift]
---

## [Introspect](https://github.com/siteline/SwiftUI-Introspect)

Introspect は SwiftUI のコンポーネントの裏に UIKit がいることを利用して SwiftUI のコードでは直接カスタマイズできないコンポーネントのかゆいところに手を届かせるためのライブラリです。

### ScrollView

SwiftUI で`ScrollView`には`refreshable`が効かないのですが、Introspect を使えば効くようにできます。

`UIViewRepresentable`を利用する方法などもあるらしいのですが、こちらのほうが圧倒的に楽です。

```swift
import Introspect
import SwiftUI

extension ScrollView {
  /// Marks ScrollView as refreshable.
  func refreshable(action: @escaping @Sendable () async -> Void) -> some View {
    self
      .introspectScrollView(customize: { uiScrollView in
        let refreshControl: UIRefreshControl = UIRefreshControl()
        let action: UIAction = UIAction(handler: { handler in
          let sender = handler.sender as? UIRefreshControl
          sender?.endRefreshing()
          Task {
            await action()
          }
        })
        refreshControl.addAction(action, for: .valueChanged)
        uiScrollView.refreshControl = refreshControl
      })
  }
}
```

なんか`@Sendable`を書いているとちょっとおかしいこともあるっぽいので要らないなら消していいかもしれない。

### UINavigationController

`NavigationView`で戻るを好きなボタンに変えたいときに使うライフハック。

```swift
import Introspect
import SwiftUI

struct CustomBackButton: ViewModifier {
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.dismiss) var dismiss

  func body(content: Content) -> some View {
    content
      .introspectNavigationController(customize: { nvc in
        nvc.navigationBar.backIndicatorImage = UIImage()
        nvc.navigationBar.backIndicatorTransitionMaskImage = UIImage()
        nvc.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(
          title: nil, image: UIImage(named: "ButtonType/BackArrow"), primaryAction: nil, menu: nil)
        nvc.navigationBar.tintColor = colorScheme == .dark ? .white : .black
      })
  }
}

extension View {
  func navigationBarBackButtonHidden() -> some View {
    self.modifier(CustomBackButton())
  }
}
```

で、これ思った人いると思うんですよ、以下のコードで同じことができるんじゃないかって。

```swift
import SwiftUI

struct CustomBackButton: ViewModifier {
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.dismiss) var dismiss

  func body(content: Content) -> some View {
    content
      .navigationBarBackButtonHidden(true)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button(
            action: {
              dismiss()
            },
            label: {
              Image(name: "ButtonType/BackArrow")
            }
          ).tint(colorScheme == .dark ? .black : .white)
        }
      }
  }
}

extension View {
  func navigationBarBackButtonHidden() -> some View {
    self.modifier(CustomBackButton())
  }
}
```

で、だいたいこれでも思った通りの挙動をするのですが、標準のスワイプバックが効かなくなるという問題あります。これが困るんですよね。

ちなみに上記の方法でも困る点があって、指定された`NavigationView`よりも下位の階層にあるコンポーネントにも強制的に反映されてしまうという問題があります。ただ、今回はスワイプバックが効かなくなる方が困るので、こちらの案を採用しました。

### NavigationHeaderItem

```swift
import Introspect
import SwiftUI

struct CustomBackButton: ViewModifier {
  @Environment(\.colorScheme) var colorScheme
  @Environment(\.dismiss) var dismiss

  func body(content: Content) -> some View {
    content
      .introspectNavigationController(customize: { nvc in
        nvc.navigationBar.titleTextAttributes = [NSAttributedString.Key.font: UIFont(name: "FONT NAME", size: 16)!]
      })
  }
}
```

また何か便利そうなライフハック見つけたら掲載します。
