---
title: "[第一回] THEOSで脱獄アプリを作成する"
published: 2021-06-21
description: THEOSを使って簡単な脱獄Tweakを作成するためのチュートリアルです
category: Programming
tags: [Swift]
---

# THEOS のセットアップについて

まだ THEOS をセットアップできていない方はこの記事を読んで THEOS をセットアップしてください。

脱獄 Tweak を作成しようという意気込みがあるくらいの方であれば 20 分もあればできると思います。

##

もし THEOS JAILED もセットアップしている場合は`$THEOS/bin/nic.pl`を実行すると以下の 18 のテンプレートが表示されると思います。

```zsh
[1.] iphone/activator_event
[2.] iphone/activator_listner
[3.] iphone/application_modern
[4.] iphone/application_swift
[5.] iphone/cydget
[6.] iphone/flipswitch_switch
[7.] iphone/framework
[8.] iphone/jailed
[9.] iphone/library
[10.] iphone/notification_center_widget
[11.] iphone/notification_center_widget-7up
[12.] iphone/preference_bundle_module
[13.] iphone/theme
[14.] iphone/tool
[15.] iphone/tool_swift
[16.] iphone/tweak
[17.] iphone/tweak_with_simple_preferences
[18.] iphone/xpc_service
```

どれを利用すればいいのかわからなくなると思いますが、単純なものをつくるのであれば基本は`iphone/tweak`を指定すればよいです。

単純なものというのは単に広告を非表示にしたり、何らかのチェックを無効化したりするようなやつです。

### それぞれのテンプレートの意味

- activator_event
  - Activator 用のイベント
- activator_listener
  - Activator 用のリスナー
- application_modern
  - 標準 iOS アプリ
- application_swift
  - 標準 iOS アプリ
- flipswitch
  - Flipswitch 用のスイッチ
- framework
  - 他の開発者が利用できる framework
- library
  - リンク可能なライブラリ(/usr/lib/libblah.dylib のようなもの)
- notification_center_widget
  - iOS5 - 6 での通知
- notification_center-7up
  - iOS7 - 9 での通知
- preference_bundle
  - [PreferenceLoader](https://iphonedev.wiki/index.php/PreferenceLoader)が読み込める Preference bundle
- tool
  - コマンドラインツール
- tool_swift
  - コマンドラインツール
- tweak
  - Cydia Substrate をベースとして動作する Tweak
- tweak_with_simple_preferences
  - Preference bundle がある tweak
- xpc_service
  - C 言語をベースとした XPC サービス
