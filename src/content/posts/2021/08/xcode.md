---
title: Xcodeで使えるTipsあれこれ
published: 2021-08-31
description: Xcodeで利用できるおまけ機能的な便利な機能を紹介します
category: Programming
tags: [Xcode, Swift]
---

# Xcode

## ビルド ID

### ビルド ID を自動インクリメント

AppStoreConnect にアップロードするときだけビルド ID を更新してほしいので、`Edit Scheme`から`Archive`の`Pre-actions`を更新する。

```sh
cd ${PROJECT_DIR}
xcrun agvtool next-version -all
```

### ビルド ID を Git のコミット数に変更

TARGET の`Build Phases`から+を押して`New Run Script Phase`を選択。

```sh
buildNumber=$(git rev-list HEAD | wc -l | tr -d ' ')
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${PROJECT_DIR}/${INFOPLIST_FILE}"
```

## デバッグ機能

### 余計なログを非表示

`OS_ACTIVITY_MODE = disable`を環境変数に設定する。

## Info.plist

### HTTP 通信を許可する

`App Transport Security Settings`で`Allow Arbitrary Load`の値を`YES`にする。

`Allow Arbitrary Loads in Web Content`では WebView のみ HTTP 通信が許可されるので、Alamofire などで対応したい場合にはこちらではなく`Allow Arbitrary Load`の方を変更すること。
