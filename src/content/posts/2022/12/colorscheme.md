---
title: SwiftUIでアプリ全体のテーマを一括で切り替えたいなら`preferredColorScheme`を使ってはいけない件
published: 2022-12-23
description: SwiftUIでColorSchemeを利用すると伝播したりしなかったりするので解決方法をまとめます
category: Programming
tags: [Swift, SwiftUI]
---

## ColorScheme について

iOS アプリはダークモードとライトモードがあって、それが切り替えられます。なんですけど SwiftUI と UIKit で微妙に設定方法が違うのでそれについての備忘録です。

### SwiftUI

`preferredColorScheme`か`colorScheme`を View に対してくっつけることで有効化できます。

```swift
var body: some Scene {
  WindowGroup {
    ContentView()
      .preferredColorScheme(.dark)
  }
}
```

もしくは、

```swift
var body: some Scene {
  WindowGroup {
    ContentView()
      .colorScheme(.dark)
  }
}
```

ということになります。どちらも引数に`ColorScheme`を取ります。これは`.dark`か`.light`が指定できます。

が、現在は`.colorScheme`は非推奨で`.preferredColorScheme`の利用が推奨されています。じゃあこれは何が違うのかというと、`colorScheme`は子 View にしか伝播しませんが、`preferredColorScheme`は親にも伝播します。なので基本的にはアプリ内のどこか一箇所だけで使えば良いです。

ただし、注意点として`.sheet`や`.fullScreenCover`で表示した別 View から Toggle の値を切り替えると親 View には即座に反映されますが、自身には反映されません。これだと挙動としておかしいので、このままだといけないわけですね。

### UIKit

UIKit の場合は`UIUserInterfaceStyle`で ColorScheme を指定します。ちなみに`UIUserInterfaceStyle`と`ColorScheme`は全く互換性がありません。なんでこんなややこしいことにしたのかは謎です。

`UIWindow`や`UIViewController`には`overrideUserInterfaceStyle`というプロパティが存在するのでこれを上書きしてしまえば指定した ColorScheme を反映されることができます。

一般的には指定された`UIViewController`のテーマを変更するだけなのですが`UIWindowsScene`に対して実行すれば全てのテーマを一気に変更することができます。

## 効果の範囲

子 View というのはとどのつまり`NavigationLink`で遷移した先の View のことです。ややこしいのですが`.sheet`や`.fullScreenCover`は子 View ではなく別の View 扱いなのですが、親 View にも伝播する`preferredColorScheme`であれば反映されます。

|                         | colorScheme | preferredColorScheme | overrideUserInterfaceStyle |
| :---------------------: | :---------: | :------------------: | :------------------------: |
| 子 View(NavigationLink) |    有効     |         有効         |            有効            |
|         親 View         |      -      |         有効         |            有効            |
|         .sheet          |      -      |        有効\*        |            有効            |
|    .fullScreenCover     |      -      |        有効\*        |            有効            |
|        .present         |      -      |          -           |            有効            |
|   .confirmationDialog   |      -      |          -           |            有効            |
|         .alert          |      -      |          -           |            有効            |

> \*がついている箇所は呼び出した View 内で Toggle の値を切り替えても自身に即座に反映されない

つまり、上記のコードを利用して`ContentView`に`preferredColorScheme`をつけたとしても`.alert`、`confirmationDialog`そして`UIHostingController`と`UIViewController`を使った別 View の描画方法には効かないことになります。

`UIHostingController`が効かないのはまあいいとして、`.confirmationDialog`と`.alert`に対して効かないのは結構大きな問題だと思うんですけれど。

で、なんで効かないのかというと`.confirmationDialog`と`.alert`は内部的には`UIAlertController`を利用しているためだと思われます。なので SwiftUI で変更する方法ではダメなわけです。

なので一括でアプリ内の全てのテーマを変更したければ`UIWindow`に対して`overrideUserInterfaceStyle`を実行すれば良いです。

### UIWindow

ルートの`UIWindow`を取得するコードは以下の通り。最近この辺りは Deprecated になっているものが多いので、特に理由もなく以下のコードをコピペすればよいです。

```swift
extension UIApplication {
    public var window: UIWindow? {
        UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first?.windows.first
    }
}
```

これでアプリが利用している`UIWindow`のうち、ルートのものがとってこれます。なので、

```swift
@main
struct DemoApp: App {
  @AppStorage("APP.CONFIG.DARKMODE") var isDarkMode: Bool = false

  var body: some Scene {
    WindowGroup {
      ContentView()
        .onChange(of: isDarkMode, perform: { newValue in
          UIApplication.shared.window?.overrideUserInterfaceStyle = newValue ? .dark : .light
        })
    }
  }
}
```

なので例えば上のように`@main`内で`UIApplication.shared.window?.overrideUserInterfaceStyle = isDarkMode ? .dark : .light`とすれば`ContentView`以下の全ての View でテーマの変更が有効になります。データを保存しておくためにどちらのテーマを利用しているかは`@AppStorage`に保存しておきましょう。

このとき`.preferredColorScheme`を同時に使うとこちらの設定が優先されて`.sheet`や`.fullScreenCover`内で Toggle を切り替えたときに変更が効かなくなります。ただこれだと、Toggle を切り替えたときにしかテーマの切り替えが効かなくなるので起動時にも反映されるようにします。

```swift
@main
struct DemoApp: App {
  @AppStorage("APP.CONFIG.DARKMODE") var colorScheme: UIUserInterfaceStyle = .dark

  var body: some Scene {
    WindowGroup {
      ContentView()
        .onChange(of: isDarkMode, perform: { newValue in
          UIApplication.shared.window?.overrideUserInterfaceStyle = newValue
        })
        .onAppear(perform: {
          UIApplication.shared.window?.overrideUserInterfaceStyle = colorScheme
        })
    }
  }
}

/// AppStorageにUIUserInterfaceStyleを突っ込めるようにする
extension UIUserInterfaceStyle: Codable {}

/// テーマを切り替えるToggle
struct ThemeToggle: View {
  @AppStorage("APP.CONFIG.DARKMODE") var colorScheme: UIUserInterfaceStyle = .dark

  var body: some View {
    Toggle(isOn: Binding(get: {
        colorScheme == .dark
      }, set: { newValue in
        colorScheme = newValue ? .dark  : .light
      }),
      label: {
        Text("DarkMode")
    })
  }
}
```

みたいな感じにすればこのトグルをどこに設置しても切り替えれば即座にアプリの全ての View のテーマが切り替わります。`.preferredColorScheme`なんて使う必要なかったんだよなあ、うん。
