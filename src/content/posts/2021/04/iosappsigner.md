---
title: iOS App Signerでアプリに署名しよう
published: 2021-04-19
description: iOS App Signerでアプリに署名し、Sideloadを使って365日間有効なIPAを作成するためのチュートリアルです
category: Programming
tags: [Swift, Sideload]
---

## Sideload の必要性

Sideload が特別なにか重要かと言われると実はそうでもなかったりする。

要するに今まで脱獄しなければできなかったことを dylb をバイナリに直接突っ込んで同梱してしまうことで一部の機能を利用できるようにしようという仕組みである。

ただ、非改造の iOS は署名のないアプリは起動できない。そこで、Apple で正式に発行した自己署名を使ってアプリにサインし、動かしてしまおうというのである。

自己署名は七日間しか有効でないが、Developer Program に参加していれば 365 日まで延長することができる。この登録は年間 12000 円もかかってしまうので Sideload のためにわざわざ登録する意味はないが、誰かが登録さえしていればデバイスは 100 台まで登録できる。

つまり、全員で分担すれば一台あたり年間 120 円で Sideload を使うことができるというわけだ。これならハードルはかなり低いように感じる。

で、ぼく自身は Salmonia のリリースのためにデベロッパ登録をしている。現在デバイス自体は自分が所有している七台が登録されているが、まだまだ余裕がある。

なのでもしも UDID を送ってくれたらデバイス登録をします。

### UDID が洩れて大丈夫なのか

大丈夫である。

UDID を利用するアプリは Apple でリジェクトされるようになっているし、世間的にも UDID は使用しない方向に進んでいる。

現在利用されているのは UUID と呼ばれる識別子であり、これはデバイス登録には必要とされていない。

UUID が洩れても使っているデバイスの種類(iPhone か iPad かなど)やデバイスモデル(iPhone 8 や iPhone X など)がわかるくらいである。

## 手順

### Identifier の作成

[ここ](https://developer.apple.com/account/resources/identifiers/list)でログインしてまずは Identirfier を作成します。

自分は Twitter Owl の Sideload がしたかったのでこんな感じに設定しました。多分、Sideload したいアプリの数だけ Identirfier は作成しないとダメです。

### デバイスの登録

[ここ](https://developer.apple.com/account/resources/devices/list)からデバイスの登録を行います。

UDID が必要になるのであらかじめ調べておきましょう。

UDID は Mac であればデバイスを繋いでからデバイス名の下のところを一回クリックすれば表示されます。

Windows であれば iTunes で繋いで調べることができます、多分。

登録デバイスが増えたときはここからやり直す必要があります。

### Provisioning Profile のダウンロード

[ここ](https://developer.apple.com/account/resources/profiles/list)から Provisioning Profile を作成してダウンロードします。

Identirfier には先程作成したものを利用します。

### iOS App Signer

iOS App Signer は[ここ](https://dantheman827.github.io/ios-app-signer/)で配布されています。

ダウンロードしたら起動し、Provisionig Profile に先ほど作成してダウンロードしたものを指定します。

その後 Input File から署名したい IPA ファイルを選択します。今回は Twitter アプリに対して署名したかったので[GitHub の公式ページ](https://github.com/ipahost/Owl-for-Twitter)から IPA をダウンロードしてきました。

あとは署名をしてしまえば終了です。だいたい一分くらいで終わります。

## 配布する

以下のテンプレートに則って PLIST ファイルを作成します。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>items</key>
  <array>
    <dict>
      <key>assets</key>
      <array>
        <dict>
          <key>kind</key>
          <string>software-package</string>
          <key>url</key>
          <string>配布用URLを記述する</string>
        </dict>
      </array>
      <key>metadata</key>
      <dict>
        <key>bundle-identifier</key>
        <string>IPAのバンドルIDを指定する</string>
        <key>bundle-version</key>
        <string>IPAのバージョンを指定する</string>
        <key>kind</key>
        <string>software</string>
        <key>subtitle</key>
        <string>企業名を指定する</string>
        <key>title</key>
        <string>アプリ名を指定する</string>
      </dict>
    </dict>
  </array>
</dict>
</plist>
```

### リンクの作成

最後にこの PLIST にアクセスするために必要なリンクを作成する。

Markdown だと以下のように書けば良い。`item-services://`の URL スキームを使うことでインストーラが開くという仕組みになっている。

```md
[リンク](itms-services://?action=download-manifest&url=https://tkgling.netlify.app/resources/plist/twitterowl.plist)
```

注意点としては PLIST ファイルは必ず HTTPS プロトコルでアクセスしないといけない。今どき使っている人はいないだろうが、HTTP だとインストールができない。

また、PLIST ファイルが置いてあるドメインと IPA が置かれているドメインは同じでないといけない。要するに、勝手に別のドメインのアプリをインストールすることはできない。

## 完成したもの

UDID を登録しているデバイスで以下のリンクを開くとアプリがインストールされる。

365 日間有効なのでご自由にどうぞ。

### Twitter Owl

主な機能は以下の通り。

- 広告の非表示
- Fleet 画像の保存
- ツイートを画像として保存
- 動画の保存
- いいねアクションの無効化
- フィード動画の保存
- いいね時に確認機能を追加
- フォロー外しの際に確認機能を追加
- フリートの無効化
- ボイスメッセージの送信

ただし、以下の点でバグが存在する（これは潜在的で解決できるようなものではない）

- 通知が来ない

|                                                     バージョン                                                     | リリース日 | プラグインバージョン |
| :----------------------------------------------------------------------------------------------------------------: | :--------: | :------------------: |
| [8.59](itms-services://?action=download-manifest&url=https://tkgling.netlify.app/resources/plist/twitterowl.plist) | 2020/04/08 |         1.7          |

### Youtube

主な機能は以下の通り。

- 広告の非表示
- スリープモード
- バックグラウンド再生
- 自動再生無効化
- ループ再生
- HD 画質有効可
- 自動購読登録/解除
- すべての動画に自動で高評価
- すべての動画に自動で低評価
- ショートストーリーを保存

ただし、以下の点でバグが存在する（これは潜在的で解決できるようなものではない）

- 通知が来ない

|                                                     バージョン                                                     | リリース日 | プラグインバージョン |
| :----------------------------------------------------------------------------------------------------------------: | :--------: | :------------------: |
| [16.09.2](itms-services://?action=download-manifest&url=https://tkgling.netlify.app/resources/plist/youtube.plist) | 2020/03/19 |         1.7          |
