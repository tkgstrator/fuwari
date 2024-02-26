---
title: "5.4.0向けインスタンスアドレス"
published: 2021-02-28
category: Hack
tags: [IPSwitch]
---

## 5.4.0 向けインスタンスアドレス

|            クラス            |  3.1.0   |  5.4.0   |                意味                |
| :--------------------------: | :------: | :------: | :--------------------------------: |
|       Game::PlayerMgr        | 04157578 | 02CFDCF8 |   ガチマッチなどのプレイヤー情報   |
|    Game::Coop::RuleConfig    | 04158008 |    -     |        パラメータを設定する        |
|   Game::Coop::LevelsConfig   | 04160E00 |    -     |     詳細なパラメータを設定する     |
|     Game::Coop::Setting      | 04160E08 |    -     | キケン度やステージなどの設定を司る |
|  Game::Coop::EnemyDirector   | 04165740 |    -     |         シャケを司るクラス         |
|  Game::Coop::PlayerDirector  | 04165DB8 | 02D0CEE0 | サーモンランのプレイヤー情報を司る |
|  Game::Coop::EventDirector   | 04167BC0 |    -     |     夜イベントなどの情報を司る     |
|    Game::Coop::Moderator     | 04168C78 |    -     |        クマサンの挙動を司る        |
| Game::Coop::ResultPlayReport | 04169050 |    -     |        リザルトデータを司る        |

## Hook するアドレスまとめ

クラスの定義のアドレスは変わっていなかったのですが、Hook する関数はズレていたので載せておきます。

### Game::PlayerMgr::getControlledPerformer

自分自身のプレイヤーのインスタンスを取得するために必要な関数。

|              サブルーチン               |  3.1.0   |  5.4.0   |
| :-------------------------------------: | :------: | :------: |
| Game::PlayerMgr::getControlledPerformer | 00F07B1C | 010E6D2C |

5.3.1 からズレました

### Game::PlayerCloneHandle::sendSignalEvent

ナイスやカモンを Hook するための関数。

|               サブルーチン               |  3.1.0   |  5.4.0   |
| :--------------------------------------: | :------: | :------: |
| Game::PlayerCloneHandle::sendSignalEvent | 00E797FC | 0104C94C |

5.3.1 からズレました

## 移植しよう

例のテンプレートをペタペタと埋めるだけ。

sendSignalEvent のアドレスが変わったのでまずはそこをズラそう。

### シグナルで 999 納品

```
// Game::PlayerCloneHandle::sendSignalEvent(Game::PlayerSignalCloneEvent::Type) [5.4.0]
0104C94C ADRP X0, #0xXXXXX000
0104C950 LDR X0, [X0, #0xYYY]
0104C954 LDR X0, [X0]
0104C958 MOV W1, #0x270F
0104C95C STR W1, [X0, #0x370]
0104C960 MOV W1, #0x3E7
0104C964 STR W1, [X0, #0x378]
0104C968 STR W1, [X0, #0x37C]
0104C96C RET
```

こちらは BL 命令を使わないのでコールスタックは不要。XXXXX と YYY の値を計算したらおしまい。

```
Game::Coop::PlayerDirector : 02D0CEE0 -> 02D0C
ADRP : 0104C94C -> 0104C

XXXXX = 02D0C - 0104C = 01CC0
YYY = EE0
```

```
// Game::PlayerCloneHandle::sendSignalEvent(Game::PlayerSignalCloneEvent::Type) [5.4.0]
0104C94C ADRP X0, #0x01CC0000
0104C950 LDR X0, [X0, #0xEE0]
0104C954 LDR X0, [X0]
0104C958 MOV W1, #0x270F
0104C95C STR W1, [X0, #0x370]
0104C960 MOV W1, #0x3E7
0104C964 STR W1, [X0, #0x378]
0104C968 STR W1, [X0, #0x37C]
0104C96C RET
```

これを ARM64 に変換するところは簡単ですので自分でやってみましょう。

### 金イクラを消してみよう

イクラを取得すると取った瞬間になかったことになるコードです。

```
Game::Coop::PlayerDirector : 02D0CEE0 -> 02D0C
ADRP : 0073C604 -> 0073C

XXXXX = 02D0C - 0073C = 02594
YYY = EE0
```

```
0073C604 ADRP X0, #0x25D0000
0073C608 LDR X0, [X0, #0xEE0]
0073C60C LDR X0, [X0]
0073C610 STR WZR, [X0, #0x374]
0073C614 RET
```

```
// Lost Cashed GoldenEggs [tkgling]
@disabled
0073C604 802E0190
0073C608 007047F9
0073C60C 000040F9
0073C610 1F7403B9
0073C614 C0035FD6
```

## おまけ

これだけだと記事の内容として寂しいのでいくつかのコードを載せておきます。5.4.0 で動きます。

### 金イクラがいっぱい

```
// Infinite Golden Eggs [tkgling]
@disabled
0066739C 0031881A // Salmonids
0068D680 40018052 // Snatchers
006CF59C 40018052 // Chinooks
00667398 48018052 // Boss Salmonids
```

シャケが金イクラを 10 個ドロップするようになります。ただし、キンシャケ探しのキンシャケ・ラッシュのキンシャケ・霧のキンシャケ・グリルの四つのオオモノについては別パラメータで設定されているため変化しません。

### 切断チェック回避

本来であれば 60 秒間操作せずにいると回線落ち扱いになるのですが、3600 秒放置しないと落ちないようになります。

```
// Disable MovelessPlayer Checker [tkgling]
@disabled
00F8EAD0 094C9D52
```

記事は以上。
