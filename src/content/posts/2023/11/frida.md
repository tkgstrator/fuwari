---
title: 未脱獄でもバイナリ解析をしよう 
published: 2023-11-26
description: No description 
category: Programming
tags: [macOS, iOS, Jailbreak]
---

## Objection

通常、アプリを動的解析するのであればデバイスが脱獄されている必要があります。

ですがアプリ自体にバイナリを同梱することで未脱獄状態でも解析ができます。

めちゃくちゃ頑張っていたのですが、以下の作業は全て無になりました。

### 必要なもの

- Objection
- Frida
- [Sideloadly](https://sideloadly.io/)
- [FridaGadget.dylib](https://github.com/frida/frida/releases/download/16.1.6/frida-gadget-16.1.6-ios-universal.dylib.gz)

FridaGadget.dylibはダウンロードしたものを展開してファイル名を変えてください。変えなくても問題ないかもですが、なんとなく変えました。

## Sideload

復号したIPAファイルを用意したらSideloadlyに突っ込みます。

Tweak Injectionがあるので`+dylib/deb/bundle`からFridaGadget.dylibを突っ込みます。

下に三つチェックを入れるところがありますが、全て外します。未脱獄ではCydia SubstrateもSubstituteも入っていないので動きません。

Sideload Spooferだけはよく分からなかったのですが、チェックを入れたらMobile Substrateのチェックみたいなのが入って動きませんでした。なので全部外します。

`Anisette Authentication`はLocal、`Signing Mode`はApple Id SideloadにしてStartを押します。

インストールができます。

### 解析

このパッチが当てられたアプリは通常起動はできません。

解析するにあたってコンソールを二つ開く必要があります。ひょっとしたら一つでもできるかもしれないのですが、わかりません。

#### コンソール1

```zsh
frida -Uf com.nintendo.znca
     ____
    / _  |   Frida 16.1.7 - A world-class dynamic instrumentation toolkit
   | (_| |
    > _  |   Commands:
   /_/ |_|       help      -> Displays the help system
   . . . .       object?   -> Display information about 'object'
   . . . .       exit/quit -> Exit
   . . . .
   . . . .   More info at https://frida.re/docs/home/
   . . . .
   . . . .   Connected to iPhone (id=921686d2cdbb7e8c7ea972d61652a0370b1e994e)
Spawning `com.nintendo.znca`...
Spawned `com.nintendo.znca`. Resuming main thread!                  
[iPhone::com.nintendo.znca ]->
```

一つ目を起動しただけだと無限にフリーズするので二つ目のコンソールからObjectionを実行します。

#### コンソール2

```
objection explore

Using USB device `iPhone`
Agent injected and responds ok!

     _   _         _   _
 ___| |_|_|___ ___| |_|_|___ ___
| . | . | | -_|  _|  _| | . |   |
|___|___| |___|___|_| |_|___|_|_|
      |___|(object)inject(ion) v1.11.0

     Runtime Mobile Exploration
        by: @leonjza from @sensepost
```

すると普通に起動します。

ここから解析を進めると良いです。

記事は以上（以下の内容は存在しません、そのうち消します）

## これより下は作業の証

### 空のプロジェクトの作成

署名に必要なMobile Provisionを取得します。[Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/profiles/list)から発行しても良いのですが、めんどくさいのでXcodeからやる方が楽です。

適当にBundle Identifierを指定してiOS向けアプリを作成します。

`Signing & Capabilities`からAutomatically manage signingを有効化します。

するとちょっと下の方にSigning Certificat Apple Development: XXXXXX (YYYYYYYYYY)と表示されます。されたらファイルは作成されたのでこれを抜きます。

ここのYYYYYYYYYYの値は少しの間覚えておいてください。

適当に`Product>Archive`を押します。

出力されたアーカイブの上で右クリックを押して`Show in Finder`を押します。

出力されたファイルはそのまま開くとXcodeが開いてしまうので、右クリックで`Show Package Contents`を押します。

```zsh
XXXXXX.xcarchive/
├── Info.plist
├── dSYMs/
└── Products/
    └── Applications/
        └── XXXXXX/
            ├── XXXXXX
            ├── embedded.mobileprovision
            ├── PkgInfo
            ├── _CodeSIgnature/
            └── Frameworks/
```

こうなっているので`embedded.mobileprovision`を取り出しておきます。

### 証明書の確認

```zsh
security find-identity -p codesigning -v
```

とすればデバイスに保存されている証明書が見れます。

```zsh
security find-identity -p codesigning -v                                                                         
  1) C1AC4EFE2714E89EXXXXXXXXXXXXXXXXXXXXXXXX "Apple Development: Devonly (XXXXXXXXXX)"
  2) 850E2342E18F291EXXXXXXXXXXXXXXXXXXXXXXXX "Apple Distribution: Devonly (YYYYYYYYYY)"
     2 valid identities found
```

こんな感じで見つかります。ちなみにApple DevelopmentでもApple Distributionのどちらもで良いみたいです。先程覚えたYYYYYYYYYYに対応するIdentityの値をコピーします。

### insert_dylib

バイナリがFridaGadget.dylibを読み込めるようにパッチを当てます。

```zsh
git clone https://github.com/Tyilo/insert_dylib
cd insert_dylib
xcodebuild
sudo cp build/Release/insert_dylib /usr/local/bin/insert_dylib
```

元々のコードでは最後のコマンドに`sudo`はついていなかったのですが、これがないとパーミッションエラーで怒られたので入れておきます。

ちなみにこれは一回やれば二回目以降は不要です。

### ios-deploy & applesign

```zsh
yarn global add ios-deploy applesign
```

署名とかアプリのインストールに必要なツールをインストールします。

### FridaGadget.dylib

[Releases](https://github.com/frida/frida/releases)からFrida GadgetのiOS向けのdylibをダウンロードします。

最新のFrida Gadgetは16.1.7なのですがまだバイナリがないので16.1.6で代用します。

[frida-gadget-16.1.6-ios-universal.dylib.gz](https://github.com/frida/frida/releases/download/16.1.6/frida-gadget-16.1.6-ios-universal.dylib.gz)をダウンロードして展開し、ファイル名を`FridaGadget.dylib`に変更します。

## 手順

此処から先は集めたファイルを使います。

```zsh
com.nintendo.znca.ipa
FridaGadget.dylib
embedded.mobileprovision
```

### IPAのビルド

Objectionの`patchipa`でもできるみたいなことが書いてあるのですが、自分の環境だと何度やっても署名が正しくできなくて詰みました。

労力としては一緒なのでMakefileで実行できるようにしました。

```zsh
PHONY: patch
patch:
	unzip -o ${BUNDLE_IDENTIFIER}.ipa
	cp FridaGadget.dylib Payload/${BINARY_TARGET}.app/Frameworks
	insert_dylib --strip-codesig --inplace '@executable_path/Frameworks/FridaGadget.dylib' Payload/${BINARY_TARGET}.app/${BINARY_TARGET}
	codesign -f -v -s ${HASH_IDENTITY} Payload/${BINARY_TARGET}.app/Frameworks/FridaGadget.dylib
	zip -qry ${BUNDLE_IDENTIFIER}.patched.ipa Payload
	applesign -i ${HASH_IDENTITY} -m embedded.mobileprovision -o ${BUNDLE_IDENTIFIER}.signed.ipa ${BUNDLE_IDENTIFIER}.patched.ipa
	unzip -o ${BUNDLE_IDENTIFIER}.signed.ipa
	rm ${BUNDLE_IDENTIFIER}.patched.ipa 

PHONY: install
install:
	ios-deploy --bundle Payload/${BINARY_TARGET}.app --debug -W
```

必要なパラメータは三つで、それらは`.env`に書きます。

```zsh
BUNDLE_IDENTIFIER=com.nintendo.znca
HASH_IDENTITY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
BINARY_TARGET=Coral
```

`HASH_IDENTITY`は上の方でコピーした超長い文字列です。

のような出力がでてきます。

```zsh
com.nintendo.znca-frida-codesigned.ipa
```

みたいなのが出力されます。
