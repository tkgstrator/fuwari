---
title: iOSアプリ開発で導入すべきライブラリまとめ
published: 2021-08-23
description: SwiftUIでデバイスや傾きごとにレイアウトを変更したい場合のコーディングについて学びます
category: Programming
tags: [Swift, SwiftUI]
---

# ライブラリまとめ

何らかのアプリをつくろうとしたとき、自分で全部の仕組みを作るのは大変ですし車輪の再発明になりがちです。

なので、既に公開されている便利なライブラリ・フレームワークがあるならそれを利用するべきです。



## Web 系

### [BetterSafariView](https://github.com/stleamist/BetterSafariView)

| ライセンス | Swift Package Manager |
| :--------: | :-------------------: |
|    MIT     |         対応          |

![](https://github.com/stleamist/BetterSafariView/raw/main/Docs/Images/BetterSafariView-Comparison.svg)

アプリ内ブラウザを実装しようと考えているならまずこれを利用しましょう。

アプリ内ブラウザだけでなく WebAuthenticationSession を利用した認証にも対応しているので URLScheme を利用した OAuth もこれだけで対応できます。

`Info.plist`に URLScheme とか設定する手間も省けるので、是非導入を検討してみてください。

### [Alamofire](https://github.com/Alamofire/Alamofire)

| ライセンス | Swift Package Manager |
| :--------: | :-------------------: |
|    MIT     |         対応          |

HTTP/HTTPS 通信の大御所ライブラリです。非同期通信に対応しており、ネットワークから何かをダウンロードしたい・アップロードしたいという場合にはこれを使えばほとんどすべてが解決します。

### [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)

| ライセンス | Swift Package Manager |
| :--------: | :-------------------: |
|    MIT     |         対応          |

Alamofire で取得した JSON データはそのままでは Data 型なのですがそれを JSON 型に一発で変換することができる便利なライブラリです。

ただし、キー名指定などが面倒であれば Codable 準拠の構造体を定義して SwiftyJSON を使わずに変換してしまったほうが確実と言えます。

### [CombinExpectations](https://github.com/groue/CombineExpectations)

| ライセンス | Swift Package Manager |
| :--------: | :-------------------: |
|    MIT     |         対応          |

Combine を利用したコードはそのままではテストをパスしてしまうので、これを使って取得したデータが正しいかどうかをチェックできます。

## UI 系

### [SwiftUIX](https://github.com/SwiftUIX/SwiftUIX)

| ライセンス | Swift Package Manager |
| :--------: | :-------------------: |
|    MIT     |         対応          |

UIKit では実装されているが、SwiftUI ではまだ足りていない部分などを補うためのライブラリです。

死ぬほど便利なので絶対入れること。

### [FontAwesomeSwiftUI](https://github.com/onmyway133/FontAwesomeSwiftUI)

| ライセンス | Swift Package Manager |
| :--------: | :-------------------: |
|    MIT     |         対応          |

FontAwesome5 のアイコンを SwiftUI から手軽に利用できるようにするためのライブラリです。

Apple 謹製の[SF Symbols](https://developer.apple.com/sf-symbols/)を使うことが多いので、こちらのライブラリは使ったことがないのですが FontAwesome にしかないようなフォントを使いたい場合には良いかと思います。

### [PopupView](https://github.com/exyte/PopupView)

| ライセンス | Swift Package Manager |
| :--------: | :-------------------: |
|    MIT     |         対応          |

![](https://raw.githubusercontent.com/exyte/PopupView/master/Assets/demo.gif)

`toast`, `float`, `default`の三種類のポップアップを表示させることができるライブラリです。

### [SwiftUICharts](https://github.com/willdale/SwiftUICharts)

| ライセンス | Swift Package Manager |
| :--------: | :-------------------: |
|    MIT     |         対応          |

![](https://github.com/willdale/SwiftUICharts/raw/main/Resources/images/LineCharts/MultiLineChart.png)

[Charts](https://github.com/danielgindi/Charts)の SwiftUI 版みたいなライブラリです。Charts は SwiftUI に対応していないので SwiftUICharts は便利といえば便利なのですが、見た目がちょっと微妙な気がします。

### [SlideOverCard](https://github.com/joogps/SlideOverCard)

| ライセンス | Swift Package Manager |
| :--------: | :-------------------: |
|    MIT     |         対応          |

![](https://github.com/joogps/SlideOverCard/raw/assets/demo-example.gif)

### [PartialSheet](https://github.com/AndreaMiotto/PartialSheet)

| ライセンス | Swift Package Manager |
| :--------: | :-------------------: |
|    MIT     |         対応          |

![](https://user-images.githubusercontent.com/11211914/68700574-6c100580-0585-11ea-9727-8a02ec36b118.gif)

SwiftUI はデフォルトでは ModalWindow のサイズを変更できないのですが、自由なサイズの ModalWindow を表示するためのライブラリです。

### [SwiftUIRefresh](https://github.com/siteline/SwiftUIRefresh)

| ライセンス | Swift Package Manager |
| :--------: | :-------------------: |
|    MIT     |         対応          |

![](https://github.com/siteline/SwiftUIRefresh/raw/master/docs/demo.gif)

`pullToRefresh`の機能を SwiftUI の View に対して実装してくれるがバグも多い。

最後にアップデートされたのが一年以上前なのでどうしても今すぐ`pullToRefresh`が使いたい場合以外は利用しないほうが良い。後述する`SwiftUI-Introspect`を使って実装するか、Fork して自力でアップデートするのが良いかと。

## 画像系

### [URLImage](https://github.com/dmytro-anokhin/url-image)

| ライセンス | Swift Package Manager |
| :--------: | :-------------------: |
|    MIT     |         対応          |

SwiftUI の View は URL を指定するイニシャライザがないので URL 上の画像を利用するためのライブラリです。

バージョンアップされてやや使い方がわかりにくくなりましたが、今でもこれを利用しています。

### [Kingfisher](https://github.com/onevcat/Kingfisher)

![](https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/logo.png)

調べていたらこちらも見つかったのでご紹介。

使ったことはないのですが、こちらの方がより直感的に使えそうな気はします。

## その他

### [RealmSwift](https://github.com/realm/realm-cocoa)

| ライセンス | Swift Package Manager |
| :--------: | :-------------------: |
|    MIT     |         対応          |

iOS でアプリ開発をしてデータベースを利用するならこれを使うのが一番です。他に選択肢はないです。

### [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess)

| ライセンス | Swift Package Manager |
| :--------: | :-------------------: |
|    MIT     |         対応          |

Keychain にアクセスするのはめんどくさいのですが、これを利用すればものすごく簡単に Keychain が扱えます。

セキュアなデータは UserDefaults やデータベースではなく Keychain に保存するようにしましょう。

### [SwiftyStoreKit](https://github.com/bizz84/SwiftyStoreKit)

| ライセンス | Swift Package Manager |
| :--------: | :-------------------: |
|    MIT     |         対応          |

In-app Purchase を実装するならまずこれを利用するのを検討しましょう。

SwiftUI でアクセスするとバグかなんかなのかやたらと反応が悪い時があるのですが、よくわかりません。

SwiftUI で課金処理をする際に StoreKit へのアクセス部分を書くのがとてつもなくめんどくさいのでこれを導入しておくと楽だと思います。

### [SwiftUI-Introspect](https://github.com/siteline/SwiftUI-Introspect)

| ライセンス | Swift Package Manager |
| :--------: | :-------------------: |
|    MIT     |         対応          |

一部の SwiftUI コンポーネントが UIKit との互換性があることを利用して、クロージャからそれらのプロパティにアクセスすることができるようにするライブラリです。

これを使えば大体なんでもできます。

### [PermissionsSwiftUI](https://github.com/jevonmao/PermissionsSwiftUI)

| ライセンス | Swift Package Manager |
| :--------: | :-------------------: |
|    MIT     |         対応          |

![](https://github.com/jevonmao/PermissionsSwiftUI/raw/main/Resources/Main-screenshot.png?raw=true)

iOS では現在アプリに対して 12 の権限が与えられているのですが、それらを許可するか拒否するかのダイアログをパッと出してくれるライブラリです。

まだ使ったことはないのですが、カメラやマイクの権限を必要とするアプリを開発した際には使ってみたいなと考えています。

記事は以上。


