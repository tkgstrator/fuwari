---
title: "[決定版] SwitchLanPlay"
published: 2021-04-26
description: LanPlay導入方法のチュートリアルです
category: Nintendo
tags: [LanPlay]
---

## LanPlay とは

Lan プレイとはニンテンドースイッチに実装されている隠し機能を使って同一 LAN 内で通信を可能にする仕組みです。

例えば、スプラトゥーン甲子園などではこの機能が使われています。

本来、LAN プレイは同一ネットワークでしか使えないのですが、これをインターネット越しでも使えるようにしたのが SwitchLanPlay になります。

簡単に言うと、本来はみんなが同じ場所に集まらなければできなかったイカッチャでのサーモンランがインターネットを使ってオンラインのサーモンランのように遊べてしまうということになります。

## LanPlay 対応ゲーム一覧

非改造で LanPlay が楽しめるゲームは以下の 11 タイトルのみです。それ以外は CFW が必要になります。CFW でのみ LanPlay が可能なタイトルについては[LanPlay 公式サイト](http://lan-play.com/games-switch)で紹介されています。

|                   タイトル                    |   FW    |
| :-------------------------------------------: | :-----: |
|                     ARMS                      | OFW/CFW |
|                  Bayonetta 2                  | OFW/CFW |
| Mario & Sonic at the Olympic Games Tokyo 2020 | OFW/CFW |
|              Mario Kart 8 Deluxe              | OFW/CFW |
|               Mario Tennis Aces               | OFW/CFW |
|             Pokkén Tournament DX              | OFW/CFW |
|                Pokémon Shield                 | OFW/CFW |
|                 Pokémon Sword                 | OFW/CFW |
|   SAINTS ROW: THE THIRD - THE FULL PACKAGE    | OFW/CFW |
|                  Splatoon 2                   | OFW/CFW |
|                  Titan Quest                  | OFW/CFW |

## LanPlay の導入

リンクが張ってあるのでダウンロードしてください。

- [WinPcap](https://www.winpcap.org/install/default.htm)
  - LanPlay の動作に必須です
- [C++再頒布パッケージ x64](https://aka.ms/vs/16/release/vc_redist.x64.exe)
  - SwitchLanPlay を実行するのに必要なパッケージです
- [SwitchLanPlay](https://tkgstrator.work/switchlanplay/index.html)
  - [@spacemeowx2](https://twitter.com/spacemeowx2)氏が開発した[switch-lan-play](https://github.com/spacemeowx2/switch-lan-play)を GUI で簡単に扱えるようにしたものです

MacOS は対応してはいますがファイルがないため全て手動で設定する必要があります。めんどくさいのであまりおすすめしません。

### WinPcap のインストール

WinPcap は Windows10 向けのものも公開されていますが、そちらでは動作しません。

### C++再頒布パッケージ

ダウンロードしてインストールするだけです。

万が一インストールできない場合は[C++再頒布パッケージ x86](https://aka.ms/vs/16/release/vc_redist.x86.exe)を試してみてください。

### SwitchLanPlay

同様にダウンロードしてインストールするだけです。

::: tip

もしインストールが上手くいかない場合、この[オフラインインストーラ](https://cdn.discordapp.com/attachments/720612694667034646/836272289431421018/Offline_InstallerSwitchLanPlay.zip)をダウンロードしてみてください

:::

インストールが終わった起動して、サーバを選んでから CONNECT を押します。

黒い画面が立ち上がり、以下のような表示がされるはずです。

```zsh
Interface not specified, opening all interfaces
[DEBUG]: open \Device\NPF_{EECC75CA-BB9D-4C56-A7DE-4D99AC3EE074} ok
pcap loop start
[DEBUG]: packet init buffer 00007FF725D3AF60
[DEBUG]: pmtu is set to 1000
Server IP: 13.231.102.57
```

`pcap loop start`の後で`Server IP: 13.231.102.57`と表示された場合は接続が成功しています。

::: danger

この黒い画面が二つ以上ひらいたままにならないようにしてください。

LanPlay に接続できなくなってしまいます。

:::

### Nintendo Switch の設定

<video controls src="https://video.twimg.com/ext_tw_video/1386658146014298115/pu/vid/1280x720/fCXFvEnZYgoqY9ve.mp4"></video>

「設定」から「インターネット設定」を開き、次のように設定します。

::: tip

動画内では DNS は下の推奨設定と異なっていますが、推奨設定で問題ありません。

:::

|                 |       項目       |      値       |                              注釈                              |
| :-------------: | :--------------: | :-----------: | :------------------------------------------------------------: |
| IP アドレス設定 |       手動       |               |                                                                |
|                 |   IP アドレス    | 10.13.XXX.YYY | XXX、YYY は他人とかぶらないような 000-255 までの好きな値を設定 |
|                 | サブネットマスク |  255.255.0.0  |                            全員共通                            |
|                 |   ゲートウェイ   |  10.13.37.1   |                            全員共通                            |
|    DNS 設定     |       手動       |               |                                                                |
|                 |     優先 DNS     |    8.8.8.8    |                            全員共通                            |
|                 |     代替 DNS     |    8.8.4.4    |                            全員共通                            |

```zsh
Interface not specified, opening all interfaces
[DEBUG]: open \Device\NPF_{EECC75CA-BB9D-4C56-A7DE-4D99AC3EE074} ok
pcap loop start
[DEBUG]: packet init buffer 00007FF725D3AF60
[DEBUG]: pmtu is set to 1000
Server IP: 13.231.102.57
[DEBUG]: IConnection::IConnection
[DEBUG]: IConnection::~IConnection
```

設定後に接続テストを行い、`[DEBUG]: IConnection::IConnecton`と表示されたら接続成功です。

### スプラトゥーンの設定

イカッチャで L スティック押し込み + L + R を同時押しして三秒間固定すれば LanPlay に切り替わります。

右下の黄色いスタンプマークが消えていれば LanPlay に切り替わっています。

<video controls src="https://video.twimg.com/ext_tw_video/1386659361146081289/pu/vid/1280x720/JAvXlgaE9OyV4HCF.mp4"></video>

あとは部屋を立てるなり、合流するなり楽しんでください。
