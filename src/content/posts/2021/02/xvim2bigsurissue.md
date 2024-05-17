---
title: XVim2がBig Surでバグる問題について
published: 2021-02-09
category: Tech
tags: [XCode]
---

## XVim2

XVim2 は Xcode に Vim のショートカットキーを導入できる神アプリ。

Mac を初期化するたびに必ず導入していたのだが、どうも Big Sur へのアップデートで XVim2 が正しく動かなくなったようだ。

## ログインできないバグ

さて、Xcode でアプリ開発する上で実機で動作させようとすると必ずアプリに対して署名をする必要がある。

で、その署名はどうするかというと Xcode で Apple ID でログインすれば自動的に Xcode が署名を生成してくれるという仕組みになっている。この辺の仕組みについてはほとんど自動化されているので、Xcode で Apple ID でログインしなければならないということを真面目に意識している人は少ないだろう。

![](https://pbs.twimg.com/media/EtiKSlvVIAY3Pge?format=png)

で、どうもこの Apple ID へログインするためのセッションを開始できないバグが発生したようだ。

XVim2 でプラグインを読み込ませるために Xcode に自己証明書で署名を上書きしているのが問題な気はしている。

![](https://pbs.twimg.com/media/EtiKWICVgAI2x7R?format=png)

[On macOS Big Sur, after codesign Xcode and try to login to my account, got "Couldn’t communicate with a helper application"])(https://github.com/XVimProject/XVim2/issues/340)

最初はなんのバグかわからなかったのだが、調べていると XVim2 の issue として挙がっているのを確認した。一応関連する issue は見て回ったが、どうも現段階で抜本的な解決方法はないようだ。

というか、スレッドでなされている対策が署名を上書きしない Xcode と上書きした Xcode の二種類を用意するなどと解説されていたりする。容量が 20GB を超える Xcode を二つも共存させる方法はスマートとは言い難いだろう。

困ったことといえば、この issue 自体が二ヶ月以上も前に報告されているにもかかわらず、解決の目処が立っていないということだ。普通、こういう問題が上がった場合、まずは暫定的な対処方法が提案され、その後リポジトリ自体にアップデートが入って正式対応するという流れが筋である。

しかし、未だに暫定的な対処方法すら一つも挙がってこない。これは若干まずい気がしている。

### App Store からダウンロードし直す

![](https://pbs.twimg.com/media/EtlTyotUcAMvWFP?format=png)

時間はかかったが、インストールし直すとなんの障害もなくログインすることができた。

もちろん、自己署名をしていないので XVim2 などのプラグインをロードすることはできない。

なので結局 Xcode12.5beta を導入して Xcode12.4 で XVim2 を使ってコーディング、Xcode12.5 でビルドして提出という方法を取ることになった。とてもめんどくさい。

ちなみに Xcode12.5 は[このリンク](https://developer.apple.com/download/)からダウンロードできます。

## おまけ

Admob を Xcode12 で動かそうとすると、Info.plist にパラメータを設定しているにも関わらず初期化エラーが発生してしまう。

そんなときに以下のサイトをお見かけして解決しました。

[【Swift5】Terminating app due to uncaught exception ‘GADInvalidInitializationException’](https://exgyaruo.com/swift/terminating-app-due-to-uncaught-exception-gadinvalidinitializationexception)

```
<key>GADIsAdManagerApp</key>
<true/>
```

Info.plist に追加で上の内容を追記すればいいらしいです。
