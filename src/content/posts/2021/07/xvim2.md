---
title: BigSur + XVim2
published: 2021-07-05
description: XVim2はBigSurだとバグが発生していたのですが、その解決法が載っていたのでご紹介します
category: Programming
tags: [Xcode]
---

# XVim2 + BigSur

XVim2 は Xcode で Vim のキーバインドを有効化するためのプラグインで、Vimmer なぼくは重宝していたのですが BigSur では AppleID にサインインできなくなるという致命的な問題がありました。

BigSur がリリースされてから随分経ち、根本的ではないもの解決法がでてきたのでそれを試したいと思います。

![](https://pbs.twimg.com/media/EtiKWICVgAI2x7R?format=png)

> BigSur + XVim2 で発生するエラーメッセージ

## XVim2 の導入方法

実は XVim2 には自己署名以外にも複数導入方法が存在する。

そもそも、自己署名をするのはオリジナルの状態では自己署名した XVim2 プラグインを Xcode が読み込めないことに起因する。

つまり、自己署名プラグインを強制的に読み込ませるような設定にすれば、わざわざ Xcode に自己署名を施さなくても良くなり、そうなれば BigSur でのサインイン問題は発生しないというわけである。

|               Xcode               |                   macOS                   |      方式      | アーキテクチャ |
| :-------------------------------: | :---------------------------------------: | :------------: | :------------: |
| 自己署名<br>BigSur サインイン問題 |                 設定不要                  | プラグイン方式 |   x64/arm64    |
|             署名削除              |                     ^                     |       ^        |      x64       |
|            オリジナル             |      ライブラリ整合性チェック無効化       |       ^        |       -        |
|                 ^                 | ライブラリ整合性チェック無効化+SIP 無効化 |       ^        |   x64/arm64    |
|                 ^                 |                     ^                     |     SIMBL      |      x64       |

実際、上の表のようにサインイン問題が発生するのは Xcode に自己署名を行った場合のみであることがわかる。

::: warning 署名削除について

ちなみに、署名削除の方法は`tccd`問題が発生するために行ってはならないとされている。`tccd`問題ってなんぞ？

あと、Markdown はデフォルトでテーブルの連結に対応してほしいです。

:::

### ライブラリ整合性チェック無効化

まず最初に Xcode でのライブラリの署名のチェック機能をオフにします。

よくわからないのですが、以下のコマンドでいけるようです。

```zsh
sudo defaults write /Library/Preferences/com.apple.security.libraryvalidation.plist DisableLibraryValidation -bool true
```

### SIP 無効化

SIP とは System Integrity Protection の略で、まあ要するにセキュリティ保護を無効化します。

通常モードからでは変更できないので、リカバリーモードとして起動する必要があります。

`Command+R`を押しながら macOS を起動して、ターミナルを開いて以下のコマンドを入力します。

```zsh
csrutil disable
```

あとは Xcode 自体に署名をせず、普通にプラグイン形式で XVim2 を読み込めば動作します。

## [Xcode13](https://developer.apple.com/xcode/)

とはいうものの、Xcode13 では Vim mode が実装されているので Xcode に XVim2 を導入するメリットはあまりありません。

ん、ということは今までは BigSur のサインイン問題でアップデートを渋っていたのですが、Xcode13 の Vim mode を使うためにも逆に積極的に BigSur を使うべきだという話になりそうですね。

というわけで、テストするために BigSur にアップデートしてみます。

XVim2、いままでありがとう。

## 追記


