---
title: SwiftUIでLaunchScreenを実装する方法
published: 2021-08-26
description: SwiftUIアプリで起動時の画面を作成する方法について解説します
category: Programming
tags: [Swift, SwiftUI]
---

# LaunchScreen とは

LaunchScreen とはその名の通りアプリ起動直後に表示される画面のこと。Android では SplashScreen と言ったりします。

ソシャゲなどだと、起動直後にキャラクターの集合絵などが表示されていると思うけど、要するにあれのこと。

LaunchScreen には Apple のガイドラインがあり、それについては[このドキュメント](https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/launch-screen/)

- 起動画面に静的画像を使用しないこと
  − デバイスサイズごとに表示する画像のサイズ、向きを変えろ
- 起動画面にテキストを含めない
  - ローカライズされないので入れるな
- 演出は短くすべし
  - あんまり凝ったデザインにするな
- 広告を入れるな
  - LaunchScreen はブランディングの機会ではないのでブランド要素を入れるな

という風になっています。

では、LaunchScreen を SwiftUI で実装する方法について解説してきましょう。

##
