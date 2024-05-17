---
title: SwiftUI+UIKit
published: 2022-12-09
description: SwiftUIで妙にいじれないところを備忘録としてメモする
category: Programming
tags: [SwiftUI, Swift]
---

## AppDelegate + SceneDelegate

SwiftUI では`AppDelegate`と`SceneDelegate`がないので`@UIApplicationDelegateAdaptor`を使って対応する。

こうすると今までと同じように`AppDelegate`と`SceneDelegate`が使えます。

```swift
@main
struct mainApp: SwiftUI.App {
@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

class AppDelegate: NSObject, UIApplicationDelegate, UIWindowSceneDelegate {
  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    let config = UISceneConfiguration(
      name: nil,
      sessionRole: connectingSceneSession.role
      )
    config.delegateClass = AppDelegate.self
    return config
  }
}
```

### Custom URL Scheme

URLScheme を動かそうとするとちょっと詰まったので備忘録。

URLScheme でアプリを呼び出した時、アプリが起動状態かそうでないかで処理が分岐する。当たり前ですが、`Info.plist`の`URL Types`に URLScheme を設定しておくこと。

#### 起動中

`SceneDelegate`の`func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>)`が呼ばれるので、以下のように書けば良い。

```swift
func scene(
  _ scene: UIScene,
  openURLContexts URLContexts: Set<UIOpenURLContext>
) {
    if let url: URL = URLContexts.first?.url
    {
    }
}
```

#### 未起動

`SceneDelegate`の`func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions)`が呼ばれるので、以下のように書けば良い。

> `func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>)`は呼ばれないので注意

```swift
func scene(
  _ scene: UIScene,
  willConnectTo session: UISceneSession,
  options connectionOptions: UIScene.ConnectionOptions
) {
    if let url = connectionOptions.urlContexts.first?.url
    {
    }
}
```

## UIViewController

たまに現在表示されている`ViewController`のインスタンスが欲しくなるときがあります。`present()`で何かを表示しようとしたら最前面の`ViewController`から呼ばないと何も起きないためです。

Xcode13 くらいから`Deprecated`なメソッドが増えたので、Warning なしで`rootViewController`をとってくるには以下のようなコードが必要になります。

```swift
extension UIApplication {
  internal var rootViewController: UIViewController? {
    UIApplication.shared.connectedScenes
      .filter({ $0.activationState == .foregroundActive })
      .compactMap({ $0 as? UIWindowScene })
      .first?
      .windows
      .first?
      .rootViewController
  }
}
```

じゃあこれで動くのかというと常に動くわけではないのが玉に瑕。というのも、SwiftUI の場合は`sheet()`や`fullScreenCover()`でその View よりも更に上位の View が`presented`されている可能性があるため。上のコードは現在、表示されている View の親は返しますが、現在表示されている View とは限らないわけです。

というわけで上のコードを拡張して現在の`UIViewController`を取得するコードは以下の通り。

```swift
extension UIApplication {
  internal var current: UIViewController? {
    if let current = rootViewController.presentedViewController {
      return current
    }
    return rootViewController
  }
}
```

ただこれでも、上にどんどん重ねていると最前面の`UIViewController`は取れないのでそこは各自修正してください。

## UIView + SwiftUI

### UIHostingController

SwiftUI の`View`を`UIKit`で使える`UIViewController`っぽいものに変換してくれます。

```swift
let hosting: UIHostingController = UIHostingController(rootView: ContentView())
```

みたいな感じでいつも書いてます。

### UIViewControllerRepresentable

上とは逆に UIKit の`UIViewController`を SwiftUI の`View`に変換してくれます。

### UIViewRepresentable

UIKit の`UIView`を SwiftUI の`View`に変換してくれます。

どっちかというといつも`UIViewControllerRepresentable`を使うので出番はあまりなかったりする。

## SwiftUI の拡張

### UITabBarController

SwiftUI で TabView を実装しようとすると`TabView`を普通に使うことになると思うのですが、これを使うといろいろと欠点が見えてきたのでそれを列挙します。

#### タブタップを検知できない

最も大きな問題がこれ。`SwiftUI-Introspect`を使っても全くわからなかったので結構根が深い問題なのかもしれない。英語で検索しても`id`を書き換えたり`selection`を`Binding`するような正攻法とは思えない方法しかでてこない。

じゃあ`UIViewControllerRepresentable`で`UITabBarController`のラッパーを作るしかないわけです。

ただ、従来の方法と違って`TabView`は内部に`View`を複数持つわけで、それを個別に`UIHostingController`で扱う方法がわかりませんでした。ただ、今回は利用したい場面ではあらかじめタブの個数が決まっているので決め打ちする感じで対応しました。`SwiftUIX`のコードは読んだんですけど`AnyForEach<Page>`とか使っててよくわかりませんでした。

大雑把に書くと以下のようなコードで実現できました。

```swift
private struct _ContentView: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> UITabBarController {
   let controller = UITabBarController()

   let tab1 = UIHostingController(rootView: TabView1())
   let tab2 = UIHostingController(rootView: TabView2())
   let tab3 = UIHostingController(rootView: TabView3())

   let views = [tab1, tab2, tab3]
   controller.setViewControllers(views, animated: false)
   return controller
  }
}
```

タブに突っ込みたい SwiftUI の View をそれぞれ`UIHostingController`で`UIViewController`化して`setViewControllers`でセットする感じです。往々にして`NavigationView`と併用したい場合があると思うのですが、その場合は、

```swift
private struct _ContentView: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> UITabBarController {
   let controller = UITabBarController()

   let tab1 = UINavigationController(rootViewController: UIHostingController(rootView: TabView1()))
   let tab2 = UINavigationController(rootViewController: UIHostingController(rootView: TabView2()))
   let tab3 = UINavigationController(rootViewController: UIHostingController(rootView: TabView3()))

   let views = [tab1, tab2, tab3]
   controller.setViewControllers(views, animated: false)
   return controller
  }
}
```

という感じで更に`UINavigationController`を利用すればいけます。こう書けば以下の SwiftUI のコードとほぼ同じ機能が実現できます。

で、更に UIKit で細かいところが弄ることができるので、こちらのほうが圧倒的に優れていますね。ちゃんと同じタブをタップすると`NavigationView`の`popToRootViewController`が効いてくれます。

あとは動的にタブを追加できたら便利なんですけどね。何れにせよ、UIKit は細かいところまで手が届くので書いていて面白いです。

```swift
struct ContentView: View {
  var body: some View {
    TabView(content: {
      NavigationView(content: {
        TabView1()
      })
      NavigationView(content: {
        TabView2()
      })
      NavigationView(content: {
        TabView3()
      })
    })
  }
}
```

### UISplitViewController

### UINavigationController

## Xcode

### ビルド ID の自動インクリメント

色々情報が錯綜しているけれど Xcode14 でも現役で動いてかつ簡単なのがこれ。

Edit Scheme から Archive の Post-actions に以下のコマンドを書き込み。

```zsh
# Type a script or drag a script file from your workspace to insert its path.
cd "${PROJECT_DIR}" ; agvtool bump
```

このとき、Provide build settings from に開発中のアプリを連携させるのを忘れないこと。
