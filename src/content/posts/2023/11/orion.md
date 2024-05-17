---
title: SwiftでTweak開発ができるOrionのチュートリアル
published: 2023-11-25
description: No description
category: Programming
tags: [macOS, iOS, Jailbreak]
---

## Orion

[公式ドキュメント](https://orion.theos.dev/)には次のようにある。

> Orion is a DSL designed to make it entirely effortless to interact with with Objective-C's dynamic aspects in Swift. The project's primary goal is to enable easy, fun, and versatile jailbreak tweak development in Swift. In some ways, it is to Swift what Logos is to Objective-C, but it's simultaneously a lot more than that.

OrionはObjective-Cの動的な側面とSwiftで対話することを楽にするように設計されたDSL(Domain-Specific-Language)である。LogosがObjective-Cに対してそうであったように、OrionはSwiftに対してそれ以上のものである。

要するにSwiftでTweakが開発できるというわけです。

個人的にObjective-Cは全く好きではないかつ書けないのでSwiftで書けるのはとても良いです。

## 環境構築

必要なものは以下の通り。

- macOS
- Theos
- 脱獄済みデバイス

Orion自体はTheosのツールの一部なのでTheosをインストールすればOrionもついでにインストールされます。

ちなみにmacOS自体は必須ではなく、LinuxやWSL2でも実行できます。

脱獄済みデバイスには[Orion Runtime](https://chariz.com/get/orion-runtime14)のインストールが必須です。

- Orion Runtime (iOS 14 - 16)
    - iOS 14.0 - 16.3
- Orion Runtime (iOS 12 - 13)
    - iOS 12.0 - 13.7

これ以外のバージョンだと多分Orionは実行できません。

### Theos

macOSであればTHEOSは以下のコマンドでインストールできます。

```zsh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/theos/theos/master/bin/install-theos)"
```

### Theos Jailed

未脱獄でも実行できるTheos Jailedを導入したい場合は、

```zsh
git clone --recursive https://github.com/kabiroberai/theos-jailed.git
cd theos-jailed
./install
```

でとても簡単に導入できます。

#### アップデート

アップデートするなら以下のどちらかを実行。

```zsh
# 方法1
$THEOS/bin/update-theos

# 方法2
make update-theos
```

#### おまけ

`~/.zshrc`に以下の内容を追記すれば`nic.pl`だけで新規プロジェクトが作成できます。

```zsh
export PATH=$THEOS/bin:$PATH
```

設定したら`source ~/.zshrc`で読み込んで反映させましょう。

## プロジェクト作成

`nic.pl`を実行すれば以下のようなものが表示されるはずです。

```zsh
NIC 2.0 - New Instance Creator
------------------------------
  [1.] iphone/activator_event
  [2.] iphone/activator_listener
  [3.] iphone/application
  [4.] iphone/application_swift
  [5.] iphone/control_center_module-11up
  [6.] iphone/cydget
  [7.] iphone/flipswitch_switch
  [8.] iphone/framework
  [9.] iphone/jailed
  [10.] iphone/library
  [11.] iphone/notification_center_widget
  [12.] iphone/notification_center_widget-7up
  [13.] iphone/preference_bundle
  [14.] iphone/preference_bundle_swift
  [15.] iphone/theme
  [16.] iphone/tool
  [17.] iphone/tool_swift
  [18.] iphone/tweak
  [19.] iphone/tweak_swift
  [20.] iphone/tweak_with_simple_preferences
  [21.] iphone/xpc_service
  [22.] iphone/xpc_service_modern
Choose a Template (required): 
```

Orionで作成するには`iphone/tweak_swift`を選択します。なので今回の場合は`19`を入力します。

```zsh
Choose a Template (required): 19
Project Name (required): My Tweak # 好きなプロジェクト名
Package Name [com.yourcompany.mytweak]: work.tkgstrator.mytweak # Bundle Identifier
Author/Maintainer Name [devonly]: devonly # ユーザー名
[iphone/tweak_swift] MobileSubstrate Bundle filter [com.apple.springboard]: org.videolan.vlc-ios # HookしたいアプリのBundle Identifier
[iphone/tweak_swift] List of applications to terminate upon installation (space-separated, '-' for none) [SpringBoard]: 'VLC for iOS' # アプリ名
Instantiating iphone/tweak_swift in mytweak/...
```

するとフォルダが作成されるので、

```zsh
cd mytweak
make spm
```

として初期設定を済ませましょう。

ちなみにXcodeからビルドしようとしても失敗します。なので実質Xcodeは利用できません。

### コマンド一覧

- `make spm`
    - Swift Package Manager用のファイル作成
    - 最初の一回だけで良い
- `make do`
    - `make package`, `make install`の実行
- `make package`
    - パッケージを作成
- `make install`
    - ビルドされているパッケージをインストール
- `make clean`
    - クリーン
- `make clean-packages`
    - パッケージをクリーン

基本的に使うのは`make do`です。

### 設定

デフォルトの設定のままだと、ビルドしたデバイスでインストールが実行されてしまいます。

基本的にはmacOSでビルドしてモバイルのデバイスにインストールしたいと思うのでこの設定では困ります。

`Makefile`に設定が書き込めるので追記します。

```zsh
TARGET := iphone:clang:latest:14.0 # デフォルトだと12.2になっているが古いので14.0にしましょう
ARCHS = arm64e # ARM64e向けにのみビルド
DEBUG = 0 # デバッグビルドを無効化
TARGET_INSTALL_REMOTE = 1 # リモートインストールを許可
THEOS_DEVICE_USER = root # ルートユーザーで認証
THEOS_DEVICE_IP = 192.168.1.26 # IPアドレス
THEOS_DEVICE_PORT = 22 # ポート
```

開発時はデバッグビルドのほうが良いので、リリース時にのみ有効化するようにしましょう。

その他のコマンドは[iPhone Dev Wiki](https://iphonedev.wiki/Theos)に載っています。

Tweakの再インストール時にリスプリングがかからなくするオプションもあった気がするのですが、忘れてしまいました。

誰か覚えていたら教えてください。

## コード

`Souces/MyTweak/Tweak.x.swift`がソースコードなのでこれを編集します。

チュートリアルでは以下のようなコードが載っています。

```swift
import Orion
import MyTweakC
import UIKit

class LabelHook: ClassHook<UILabel> {
    func setText(_ text: String) {
        orig.setText(
            text.uppercased().replacingOccurrences(of: " ", with: "👏")
        )
    }
}
```

これは`UILabel`の`setText`を変更するコードです。

`orig`は本来のコードを示しています。本来のコードをなにかに置き換えたい場合や、本来の値を返す必要がある場合はこれを書く必要があります。

コードの中身は簡単で`setText`が呼ばれたら本来書き込むはずの文字列を全部大文字にしてから空白文字を置き換えます。

### ビルド

```zsh
make do
```

でビルド後にリモートデバイスへのインストールが始まります。

#### エラー255

```zsh
Shell "bash" is not executable: No such file or directory
make: *** [internal-install] Error 255
```

と表示される場合にはFigのSSHが有効になっているので無効化します。

```zsh
fig integrations uninstall ssh
```

で無効化できます。

#### エラー1

```zsh
make: *** [internal-install] Error 1
```

と表示される場合にはOrionの実行に必要なランタイムがインストールされていないので、

[Chariz](sileo://source/https://repo.chariz.com/)から追加しましょう。

```zsh
$ make do                       
> Making all for tweak MyTweak…
> Making stage for tweak MyTweak…
dm.pl: building package `work.tkgstrator.mytweak:iphoneos-arm' in `./packages/work.tkgstrator.mytweak_0.0.1-13_iphoneos-arm.deb'
==> Installing…
Selecting previously unselected package work.tkgstrator.mytweak.
(Reading database ... 6004 files and directories currently installed.)
Preparing to unpack /tmp/_theos_install.deb ...
Unpacking work.tkgstrator.mytweak (0.0.1-13) ...
Setting up work.tkgstrator.mytweak (0.0.1-13) ...
Processing triggers for org.coolstar.sileo (2.5) ...
==> Unloading 'VLC for iOS'…
```

こんなのが出たらインストールは成功です。

### 確認

VLCを起動すると全てのラベルが大文字になっていることがわかります。

## 備忘録

気になったことなどをメモするところ。

### 未脱獄で動かないんですか

Orion Runtimeがインストールできないんだから動くわけがない。未脱獄で動かしたい場合はMonkeyDevかTheos Jailedしか実質的に方法がない。

中国語ばっかりで読みにくいけれどTheos Jailedは実質MonkeyDevであっちのほうがドキュメントが充実していると思う。

例えば[BHTwitter](https://github.com/BandarHL/BHTwitter)とかはMonkeyDevで作られている。

記事は以上。
