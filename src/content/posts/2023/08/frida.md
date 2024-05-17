---
title: 脱獄したiPhoneからIPAファイルをぶっこ抜く
published: 2023-08-01
description: アプリ解析のためにIPAファイルをぶっこ抜くことにしました
category: Tech
tags: [macOS]
---

## はじめに

本記事は iOS のセキュリティに関して学習することを前提とした内容になっております。海賊版などを推奨するものではありませんのでご理解の程よろしくお願いします。

## [脱獄する](https://ios.cfw.guide/get-started/)

IPA ファイルを抜き出すには脱獄できる iOS デバイスが必須となります。個人的にオススメなのは以下の三つのデバイスです。

- iPhone7
- iPhone8
- iPad Pro 10.5

|               |   OS   | CPU  |
| :-----------: | :----: | :--: |
|   iPhone 7    | 15.7.2 | A10  |
|   iPhone 8    |  16.2  | A11  |
| iPad Pro 10.5 |  16.2  | A10X |

> iPad Pro 10.5 は iOS17 もサポートしていてオススメです

これらが何故オススメなのかというと BootROM Exploit である Checkm8 が利用可能であるということが上げられます。これらは iOS のアップデートで塞ぐことができないため、いかなるバージョンにおいても（ソフトウェアのアップデートが必要になる場合がありますが）脱獄可能ということになります。

ただ、A11 ではパスコードがオンになっていると脱獄できないなどの問題があるので個人的には iOS16 を必ずしも必要としないのであれば iPhone7、iOS17 もサポートしたいなら iPad Pro 10.5 を推奨しています。

### Palera1n

#### [Rootless](https://ios.cfw.guide/installing-palera1n/)

[バイナリ](https://github.com/palera1n/palera1n/releases)が別にあるのでダウンロードします。

macOS ユーザーであれば`palera1n-macos-universal`を使っておけば良いとのこと。

```zsh
sudo /bin/sh -c "$(curl -fsSL https://static.palera.in/scripts/install.sh)"
```

俗に言う Rootless 脱獄で、その名の通り rootFSを読み込み専用でマウントするモードです。

こちらは必要ではないので今回は紹介しません。

#### [Rootful](https://ios.cfw.guide/archived-palera1n-rootful/)

```zsh
sudo mkdir -p /usr/local/bin
sudo mv ~/Download/palera1n-macos-universal /usr/local/bin/palera1n
sudo xattr -c /usr/local/bin/palera1n
sudo chmod +x /usr/local/bin/palera1n
```

従来の脱獄で root 権限を持ちます。IPA をぶっこ抜くにはメモリにアクセスする必要があるのでこちらの脱獄が必要になります。

|  OS   | 必要な容量 |
| :---: | :--------: |
| iOS15 |   2~3GB    |
| iOS16 |  10~15GB   |

ただし、Rootful 脱獄にはデバイスの空き容量が必要になります。これは root 領域のファイルが変更されていることを検知するとデバイスが起動しなくなるという脱獄検知システムがファームウェアに備わっているためです。

なので、書き戻すために root 領域のバックアップを取る必要があるというわけですね。iOS16 では 10GB 以上の容量を消費するため、16GB のデバイスでは(存在するのか知らないけれども)脱獄ができません。最低 32GB あれば多分動くので、32GB 以上のモデルを用意しましょう。

で、iOS15 向けと iOS16 向けでコマンドが違います。間違えないようにしましょう。

```zsh
// iOS15
palera1n -B -f
// iOS16
palera1n -c -f
```

このコマンドを入力すると FakeFS か BindFS が生成されるので(どちらが生成されるかはコマンド依存)、何らかの理由でデバイスの電源を落として再起動する際には Rootless 脱獄と異なり、

```zsh
palera1n -f
```

のコマンドで起動してあげる必要があります。

> Apple Silicon Mac で実行すると DFU モードの接続が解除されるバグがあるので`Checkmate!`と表示されたら一度ケーブルを抜いて再度差し込む必要があります
>
> これをしないとタイムアウトして普通に起動してしまうので注意

### レポジトリの追加

インストーラは適当に Sileo を選択しておけば良いでしょう。

> 起動したら一番下に`Rootless`と表示されていないことを確認しましょう。

リポジトリから`https://build.frida.re`を追加します。

> 自分の環境だと Rootless 脱獄だとここで失敗しました

追加したら`frida`をインストールします

これで、端末側での操作は終了です

### root のパスワード変更

[https://repo.chariz.com](sileo://source/https://repo.chariz.com)のレポジトリを Sileo から登録します。

登録したら NewTerm 3 をインストールします。

> gettext-localizations がインストールされていないと`Session Ended`という謎エラーが返ってくるのでこちらもインストールしましょう。

NewTerm 3 を起動したら以下のコマンドを入力して root のパスワードを変更します。

```zsh
sudo passwd root
```

## macOS での環境構築

- frida-tools
- iproxy
- frida-ios-dump

この先、脱獄された iPhone がパソコンに接続されている前提で話を進めます。

### [frida-tools](https://frida.re/docs/installation/)

万能すぎるツールです。

ドキュメントにめちゃくちゃたくさん使い方が載っているので頑張って覚えたい所存。

```zsh
pip install frida-tools
```

### iproxy

Homebrew がインストールされていれば以下のコマンドで導入できます。

```zsh
brew install libimobiledevice
```

インストールしたら起動して放置します。

```zsh
iproxy 2222 22
```

これは IPA をダンプする度に必要になります。

### [frida-ios-dump](https://github.com/AloneMonkey/frida-ios-dump)

IPA を抜き出すためのコードはいろいろあるのですが、動かないものもあったりして謎でした。

とりあえずこれは動いたのでご紹介しておきます。

```zsh
git clone https://github.com/AloneMonkey/frida-ios-dump
cd frida-ios-dump
pip install -r requirements.txt --upgrade
```

#### 使い方

`python dump.py -l`でインストールされているアプリの一覧が見れます。

今回はチュートリアルに習って VLC の IPA を取得したいと思います。

```zsh
$ pyhton dump.py -l
 PID  Name                    Identifier
----  ----------------------  -----------------------------
1783  Settings                com.apple.Preferences
   -  Analytics               com.google.AnalyticsApp
   -  App Store               com.apple.AppStore
   -  Bluesky                 xyz.blueskyweb.app
   -  Books                   com.apple.iBooks
   -  Calculator              com.apple.calculator
   -  Calendar                com.apple.mobilecal
   -  Camera                  com.apple.camera
   -  Chrome                  com.google.chrome.ios
   -  Clock                   com.apple.mobiletimer
   -  Compass                 com.apple.compass
   -  Connect                 com.apple.AppStoreConnect
   -  Contacts                com.apple.MobileAddressBook
   -  Discord                 com.hammerandchisel.discord
   -  FaceTime                com.apple.facetime
   -  Files                   com.apple.DocumentsApp
   -  Find My                 com.apple.findmy
   -  Health                  com.apple.Health
   -  Home                    com.apple.Home
   -  Magnifier               com.apple.Magnifier
   -  Mail                    com.apple.mobilemail
   -  Maps                    com.apple.Maps
   -  Measure                 com.apple.measure
   -  Messages                com.apple.MobileSMS
   -  Music                   com.apple.Music
   -  MyAdmob                 hanhphan.admobtracking
   -  Nintendo Switch Online  com.nintendo.znca
   -  Notes                   com.apple.mobilenotes
   -  Phone                   com.apple.mobilephone
   -  Photos                  com.apple.mobileslideshow
   -  Podcasts                com.apple.podcasts
   -  Reminders               com.apple.reminders
   -  Safari                  com.apple.mobilesafari
   -  Shortcuts               com.apple.shortcuts
   -  Sileo                   org.coolstar.SileoStore
   -  Stocks                  com.apple.stocks
   -  TV                      com.apple.tv
   -  TestFlight              com.apple.TestFlight
   -  Tips                    com.apple.tips
   -  Translate               com.apple.Translate
   -  Twitter                 com.atebits.Tweetie2
   -  VLC                     org.videolan.vlc-ios
   -  Voice Memos             com.apple.VoiceMemos
   -  Wallet                  com.apple.Passbook
   -  Watch                   com.apple.Bridge
   -  Weather                 com.apple.weather
   -  YouTube                 com.google.ios.youtube
   -  iTunes Store            com.apple.MobileStore
```

その場合は以下のようにコマンドを入力します。

```zsh
$ python dump.py org.videolan.vlc-ios
Start the target app org.videolan.vlc-ios
Dumping VLC to /var/folders/85/mp1chg8s0sv20nlz6x6yyvg80000gn/T
[frida-ios-dump]: Load VLCMediaLibraryKit.framework success.
[frida-ios-dump]: Load MobileVLCKit.framework success.
start dump /private/var/containers/Bundle/Application/CACF780C-5731-40C5-9D5C-F8FB46E98E88/VLC for iOS.app/VLC for iOS
VLC for iOS.fid: 100%|██████████████████████████████████████████████████| 12.8M/12.8M [00:00<00:00, 31.3MB/s]
start dump /private/var/containers/Bundle/Application/CACF780C-5731-40C5-9D5C-F8FB46E98E88/VLC for iOS.app/Frameworks/MobileVLCKit.framework/MobileVLCKit
MobileVLCKit.fid: 100%|█████████████████████████████████████████████████| 34.3M/34.3M [00:00<00:00, 37.4MB/s]
start dump /private/var/containers/Bundle/Application/CACF780C-5731-40C5-9D5C-F8FB46E98E88/VLC for iOS.app/Frameworks/VLCMediaLibraryKit.framework/VLCMediaLibraryKit
VLCMediaLibraryKit.fid: 100%|███████████████████████████████████████████| 4.46M/4.46M [00:00<00:00, 26.7MB/s]
runtime.nib: 57.4MB [00:03, 15.6MB/s]
0.00B [00:00, ?B/s]
Generating "VLC.ipa"
```

ここで何もバーが進まない場合は手動でそのアプリを起動してあげると動きます。

すると VLC.ipa が無事にダンプできました。
