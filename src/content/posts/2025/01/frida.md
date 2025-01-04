---
title: FridaをLAN経由で使いたい
published: 2025-01-04
description: FridaはUSB経由で利用されることが前提とされているのでそれを突破します
category: Tech
tags: [iOS, Jailbreak, Frida]
---

## 背景

Fridaは基本的にUSB経由で実行することを前提とされているのですが、macOSでDev Containerを使うとホストマシンのUSBデバイスを上手くコンテナ内に繋げることができません。

多分、何らかのセキュリティ上の問題だと思うのですがそれでは困るのでLAN経由で繋げられるようにします。

### 環境

- Jailbreak済みのiOS/iPadOSデバイス
  - Sileoでのみ検証

必要なものは脱獄されたデバイスだけです。

まず最初に、

- [Frida](sileo://source/https://build.frida.re)を追加
- Frida, openssh, NewTerm 3 Beta, gettext-localizationsをインストール

ルートパスワードを忘れてしまっている場合などはNewTerm 3 Betaを使って修正しましょう。

```bash
sudo passwd root
```

とやればルートパスワードを変更できます。

### SSH接続

```bash
var/
└── jb/
    ├── Library/
    │   └── LaunchDaemons/
    │       └── re.frida.server.plist
    └── usr/
        └── lib/
            ├── frida/
            │   └── frida-agent.dylib
            └── sbin/
                └── frida-serer
```

ルートパスワードが変更できたら`ssh root@192.168.XXX.YYY`でデバイスに繋げることができるので繋ぎます

ディレクトリの構成は上のようになっているので、`vi /var/jb/Library/LaunchDaemons/re.frida.server.plist`としてファイルを編集します。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
 <key>Label</key>
 <string>re.frida.server</string>
 <key>Program</key>
 <string>/var/jb/usr/sbin/frida-server</string>

 <key>ProgramArguments</key>
 <array>
  <string>/var/jb/usr/sbin/frida-server</string>
 </array>

 <key>UserName</key>
 <string>root</string>
 <key>POSIXSpawnType</key>
 <string>Interactive</string>
 <key>RunAtLoad</key>
 <true/>
 <key>KeepAlive</key>
 <true/>
 <key>ThrottleInterval</key>
 <integer>5</integer>
 <key>ExecuteAllowed</key>
 <true/>
</dict>
</plist>
```

このうち`ProgramArguments`を以下のように変更します。

```xml
<key>ProgramArguments</key>
<array>
 <string>/var/jb/usr/sbin/frida-server</string>
 <string>-l</string>
 <string>0.0.0.0</string>
</array>
```

保存したら以下のコマンドで設定ファイルを読み込ませます。

```bash
$ launchctl unload re.frida.server.plist
$ launchctl load re.frida.server.plist
```

これで`ps aux | grep frida`とすれば`/var/jb/usr/sbin/frida-server -l 0.0.0.0`のように起動するようになっています。

### まとめ

LAN経由で繋がると便利です、Fridaについてもっと詳しくなりたいですね。

新年あけましておめでとうございます、かしこ。
