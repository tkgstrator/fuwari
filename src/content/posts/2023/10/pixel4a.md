---
title: Pixel 4a 5GをRoot化する
published: 2023-10-24
description: Androidはあまり触ってこなかったのでRoot化の手順についてメモをします
category: Hack
tags: [Android]
---

## 背景

Android の最初期には SuperSU とかを使っていたのですが、最近は Magisk を利用する方法が一般的なようです。

これがどういうツールなのかというと、ブートローダーをアンロックしたデバイスで公式のファームウェアにパッチを当てたものをインストールすることで管理者権限を取得した状態でデバイスを起動させるような仕組みみたいです（違ったらごめんなさい）

原理としては CFW にあたるわけですが、iOS が BootROM(Android でいうところのブートローダー)のアンロックを認めていないので BootROM exploit が見つからない限り CFW の起動が不可能であることに対して、Android は公式がブートローダーのアンロック機能を実装しているという点で異なります。

このあたりは長年の iOS ユーザーとして Android は便利だなあと思いました。

iOS もブートローダーのアンロックを認めてくれてもいいじゃないかと思うのですが、そうすると CFW の導入及びセキュリティの低下、海賊版の横行などデメリットがあまりに大きすぎるので多分やらないと思います。やらなくてもそれなりにシェアが取れているわけですし。

## 必要なもの

- [Magisk](https://github.com/topjohnwu/Magisk/releases)
- [Factory Image(Pixel 4a 5G)](https://developers.google.com/android/images#bramble)

必要なのは Magisk と Root 化したいデバイスの Factory Image です。今回は Pixel 4a 5G を Root 化します。

なお、デバイスによっては Factory Image が提供されていなかったりするのでマイナーなメーカーは使わずに大人しく Pixel などを使うと良いです。

### デバイスの前準備

とりあえず、まずは Magisk をインストールします。

インストール方法についてはインターネットにいくらでも記事が転がっているので割愛します。

インストールしたらデバイスをビルド番号を七回タップして開発者モードに切り替えてから USB デバッグを有効化するのとブートローダーをアンロックします。

れでデバイスが ADB を受け付けるようになり、flashboot でイメージを書き込めるようになります。

## Factory Image

一番新しい Android 14.0.0 を Root 化したいので[14.0.0 (UP1A.231005.007, Oct 2023)](https://dl.google.com/dl/android/aosp/bramble-up1a.231005.007-factory-fc548663.zip)をダウンロードします。

ダウンロードしたファイルを解凍したディレクトリの中に image-bramble-up1a.231005.007.zip があるのでそれも解凍します。

```zsh
bramble-up1a.231005.007/
├── bootloader-bramble-b5-0.6-10489838.img
├── flash-all.bat
├── flash-all.sh
├── flash-base.sh
├── image-bramble-up1a.231005.007/
│   ├── android-info.txt
│   ├── boot.img
│   ├── dtbo.img
│   ├── product.img
│   ├── super_empty.img
│   ├── system_ext.img
│   ├── system_other.img
│   ├── system.img
│   ├── vbmeta_system.img
│   ├── vbmeta.img
│   ├── vendor_boot.img
│   └── vendor.img
├── image-bramble-up1a.231005.007.zip
└── radio-bramble-g7250-00264-230619-b-10346159.img
```

すると上のようなディレクトリ構成になるはずです。ちなみにディレクトリの構造自体は重要ではありません。

解凍したファイルの中に boot.img があればそれを Google Drive を利用するなり何らかの方法でデバイスからアクセスできるようにします。

### Patched Image の作成

次に Magisk を起動して Install を押したら boot.img を選択します。

数分待てばパッチが当たった boot.img が作成されるので、それを今度はパソコンにコピーします。

> 今回は`magisk_patched-26300_zIdcQ.img`というファイルが作成されました

## Platform tools

次に[ここのリンク](https://developer.android.com/studio/releases/platform-tools)から Platform tools をダウンロードします。

これがないとパソコンの方で`adb`コマンドが認識されません。本来であれば Android Studio をインストールするのですが、Android Studio 自体は Root 化には全く要らないので今回はコマンドラインツールだけを拝借します。

以下、macOS 向けの手順なので Windows または Linux ユーザーは無視してください。

ZIP ファイルを解凍してでてきた platform-tools を Applications ディレクトリにコピーします。

```zsh
Applications/
└── platform-tools/
    ├── adb
    ├── etc1tool
    ├── fastboot
    ├── lib64/
    ├── make_f2fs
    ├── make_f2fs_casefold
    ├── mke2fs
    ├── mke2fs.conf
    ├── NOTICE.txt
    ├── source.properties
    └── sqlite3
```

コピーしたら`.zshrc`に以下の内容を追記します。

```zsh
export PATH="$PATH:/Applications/platform-tools"
```

その後`source ~/.zshrc`とすれば設定が読み込まれて`adb`及び`fastboot`コマンドが効くようになります。

### ブートローダーの起動、書き込み

パッチが当たった boot.img があるディレクトリで以下のコマンドを入力します。

```zsh
adb reboot bootloader
fastboot flash boot magisk_patched-26300_zIdcQ.img
```

これでデバイスがブートローダーで起動し、パッチが当たった状態でデバイスが起動します。

## おまけ

知っている限り、あると便利だなと思った Root 化デバイス専用のツールなど。

- [LSPosed](https://github.com/LSPosed/LSPosed)
  - アプリにパッチを当てることができるツール
  - iOS でいうところの THEOS で作成した Tweak のこと
- [LSPatch](https://github.com/LSPosed/LSPatch)
  - アプリにパッチを当ててそれをインストールするツール
  - 非 Root なデバイスではパッチ自体を実行できないので、パッチが当たった apk をインストールしてしまえということ
  - iOS に詳しい人だと THEOS Jailed + Sideload を自動でやってくれるツールと言えばわかりやすいかも
- [Shamiko](https://github.com/LSPosed/LSPosed.github.io/releases)
  - Root 化検知を無効化するパッチ
  - これがないと Root 化した状態で NSO が起動しません
- [NSOk](https://github.com/Coxxs/NSOk)
  - NSO でアレができるようにするパッチ
  - 普通の使い方はできなくなるので一台デバイスを捨てる覚悟でどうぞ
