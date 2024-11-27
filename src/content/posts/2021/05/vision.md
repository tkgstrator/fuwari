---
title: Vision + SwiftUI
published: 2021-05-26
description: SwiftUIで画像認識系のフレームワークであるVisionを使ってみました
category: Programming
tags: [Swift]
---

## [Vision](https://developer.apple.com/documentation/vision)とは

Apple のドキュメントによると映像や画像からさまざまなタスクをこなすアルゴリズムをまとめたものだという。Vision 自体は iOS11 以降使えるので、現在利用されている iOS デバイスのほとんど全て（今更 iOS11 以下を使っている人は超少数派だろう）で動作するということになる。

よってサポート面での問題はないと言って良い。リリース直後はバグもあったかもしれないが、流石にもう目立ったものは修正されているだろう。

同じような画像認識フレームワークとしては CIDetector というものがあるのだが、特に何も制限がないのでとりあえず新しい方を使おうという考えである。

[この記事](https://reftec.work/posts/2019/9/111/)によると CIDetector と Vision で認識精度に大きな違いは見られなかったそうだが、まあどっちを使っても変わらないのであればやっぱり新しい方を使いたい。

## Vision の使い方

`Vision`では通常の画像ではなく`CIImage`というものを使うらしい。で、困ったことに`CIImage`は引数に`Image`ではなく`UIImage`を使う。`Image`は`View`なのだから仕方ないとはいえ、ちょっとめんどくさい。

で、本当はコードを載せたいのだが全部載せているとめちゃくちゃ長くなるので GitHub でプロジェクトを公開しておく。
