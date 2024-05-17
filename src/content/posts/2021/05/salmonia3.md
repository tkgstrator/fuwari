---
title: Salmonia開発記
published: 2021-05-05
description: ライブラリを開発していたら妙なところで詰まったのでメモ&開発進捗をしておきます
category: Programming
tags: [Swift]
---

## Salmonia3 の開発について

今更感は否めないのだが、なんだかんだで開発は続いています。

2022 年の 1 月 1 日までサーモンランのシフトは公開されているので、まあ半年前までにはいいところまで完成させたいですよね。最初は 2 の機能を引き継ぐ感じで開発をしていたのですが、ライブラリを勉強する機会があったので通信部分をライブラリに置き換えて開発しようということになりました。

で、ライブラリ開発やネットワーク部分は初めて扱うので少々時間がかかってしまいました。四月の段階でやたらとプログラミングの記事が多かったのはその通信部分をずっと勉強していたからです。

## ライブラリのメリット

苦労してライブラリを導入するメリットが何なのかということなのですが、一番は自分のプログラミング技術の向上です。また、ライブラリとして公開することで誰でも簡単に導入できるので別のアプリを作成するときにいちいち通信部分を気にしなくて良くなります。

これだけだと開発者側しかメリットがなさそうですが、それ以外にも利用者側にも大きなメリットがあります。

|                          |   ライブラリ    |           旧式            |
| :----------------------: | :-------------: | :-----------------------: |
|        レスポンス        |     構造体      |           JSON            |
|           導入           |      簡単       |        自分で実装         |
|     セッション再生成     |      自動       |           手動            |
|     アカウントデータ     | Keychain に保存 | DB や UserDefaults に保存 |
| アプリアンインストール時 |  データを保持   |       データが消滅        |
|        非同期通信        |      自動       |           手動            |

まず、今回のライブラリではニンテンドーオンラインにログインするための情報をセキュアな情報として Keychain に保存することにしました。今まではデータベースや UserDefaults という領域に保存していたので（一応安全とはいえ）ちょっとセキュリティ的に怪しいところがあったのですが、Keychain を使うことで安全性が増しました。

また、Keychain はアプリとは別にデータが保存されているので、アプリを削除したとしても iTunes アカウントにログイン情報が残っています。機種変更しても iPhone がウェブサイトのパスワードを覚えていて自動入力できるのをご存知だと思うのですが、あれと同じ原理です。

つまり、アプリの不具合などでアンインストールした場合でも再ログインは不要です。

## ライブラリのデメリット

更に、ライブラリは JSON を構造体に変換して返してくれます。これによって、開発者がキーの値を間違えたり型を勘違いしたりすることもなくなります。

まさにいいことづくめではないかとおもっていたのですが、ここで大きな問題が発生しました。

それは、リザルトを Salmon Stats にアップロードするときには JSON または String 型ではないといけないということでした。

というのも、ライブラリは元の JSON を構造体に変換するときに「流石にこのデータは要らないでしょ」というデータを全て捨ててしまっているためです。構造体自体は Codable に準拠しているので構造体を JSON に再び変換することは可能なのですが、ネストが変わってしまっているために Salmon Stats が受け付けることのできないデータに変わってしまっているのです。

::: tip 構造体から JSON に復元したデータ

より洗練されたデータ構造（自称）にしているため、いくつかのデータが失われている。

例えば、本来は何のオオモノをたおしたかというデータは配列ではなく辞書配列なのだがそれらのデータはここでは失われている。

:::

```json
{
  "golden_eggs": 136,
  "grade_point": 999,
  "power_eggs": 4435,
  "wave_details": [
    {
      "golden_ikura_pop_num": 59,
      "golden_ikura_num": 48,
      "water_level": 1,
      "ikura_num": 1545,
      "quota_num": 21,
      "event_type": 2
    },
    {
      "golden_ikura_pop_num": 66,
      "golden_ikura_num": 42,
      "water_level": 0,
      "ikura_num": 1945,
      "quota_num": 23,
      "event_type": 6
    },
    {
      "golden_ikura_pop_num": 69,
      "golden_ikura_num": 46,
      "water_level": 1,
      "ikura_num": 945,
      "quota_num": 25,
      "event_type": 0
    }
  ],
  "boss_counts": [10, 4, 5, 3, 8, 9, 7, 0, 3],
  "time": {
    "start_time": 1611360000,
    "end_time": 1611511200,
    "play_time": 1611395933
  },
  "kuma_point": 687,
  "results": [
    {
      "special_id": 8,
      "special_counts": [0, 0, 2],
      "weapon_list": [1010, 2050, 30],
      "boss_kill_counts": [1, 2, 2, 0, 3, 2, 1, 0, 2],
      "golden_ikura_num": 35,
      "dead_count": 1,
      "ikura_num": 910,
      "player_type": {
        "species": "inklings",
        "style": "girl"
      },
      "help_count": 0,
      "name": "まゆしぃのかみ",
      "pid": "3f89c3791c43ea57"
    },
    {
      "special_id": 7,
      "special_counts": [0, 0, 1],
      "weapon_list": [2050, 1010, 0],
      "boss_kill_counts": [0, 0, 0, 1, 2, 3, 6, 1, 1],
      "golden_ikura_num": 42,
      "dead_count": 1,
      "ikura_num": 1337,
      "player_type": {
        "species": "inklings",
        "style": "boy"
      },
      "help_count": 0,
      "name": "xxxxxxxxxx",
      "pid": "xxxxxxxxxxxxxxxx"
    },
    {
      "special_id": 2,
      "special_counts": [0, 0, 2],
      "weapon_list": [20010, 0, 2050],
      "boss_kill_counts": [1, 3, 1, 1, 0, 4, 2, 3, 1],
      "golden_ikura_num": 28,
      "dead_count": 0,
      "ikura_num": 1513,
      "player_type": {
        "species": "octolings",
        "style": "girl"
      },
      "help_count": 0,
      "name": "xxxxxxxxxx",
      "pid": "xxxxxxxxxxxxxxxx"
    },
    {
      "special_id": 9,
      "special_counts": [0, 0, 2],
      "weapon_list": [0, 200, 1010],
      "boss_kill_counts": [1, 0, 1, 0, 3, 0, 1, 0, 0],
      "golden_ikura_num": 31,
      "dead_count": 0,
      "ikura_num": 675,
      "player_type": {
        "species": "octolings",
        "style": "girl"
      },
      "help_count": 2,
      "name": "xxxxxxxxxx",
      "pid": "xxxxxxxxxxxxxxxx"
    }
  ],
  "job_id": 3501,
  "grade_point_delta": 20,
  "job_result": {
    "is_clear": true
  },
  "stage_id": 5000,
  "job_score": 158,
  "job_rate": 435,
  "boss_kill_counts": [3, 5, 4, 2, 8, 9, 10, 4, 4],
  "danger_rate": 200,
  "grade": 5,
  "schedule": {
    "weapon_list": [1010, 0, 2050, -1],
    "stage_id": 5000,
    "start_time": 1611360000,
    "end_time": 1611511200
  }
}
```

## 考えられる解決策

現在、ライブラリでは`JSON ->（自動変換）-> 構造体 ->（手動変換）-> 整形済み構造体`というプロセスで変換を行っている。

自動変換だけでは使い勝手があまり良くなく、Salmon Stats とのレスポンスとの兼ね合いもありこのような処理になっている。

で、復元する際に`整形済み構造体 ->（自動変換）-> JSON`というふうに間を一段階飛ばしてしまっているので正しくない形でデータが返ってきてしまっているのである。

これに対する対応として一番愚直なのは今は単に JSONEncoder で自動変換しているところを愚直に書き直すという方法である。

しかしこれをやると何のために自動変換して JSON から構造体にしたのかがわからない。わからないのだが、これしかないような気もしている。

どうせ整形済み構造体にするときに一度手動変換を書いたのでその逆の変換を書くだけなのだが、正直に言うとあんまり書きたくない。というのも、[変換するだけのコード](https://github.com/tkgstrator/SplatNet2/blob/main/Sources/SplatNet2/SplatNet2.swift)で 200 行くらいあるからだ。

似たようなことをするだけとはいえ、めんどくさいなあと。

## 現在の実装部分

|         機能         | Salmonia2 | Salmonia3 |
| :------------------: | :-------: | :-------: |
|     リザルト保存     |   対応    |   対応    |
| リザルトアップロード |   対応    |  未対応   |
|   リザルト取り込み   |   対応    |   対応    |

まだベータ版でしか対応していないのですが、リザルト取り込みにも仮対応しています。

取得件数が多いと（5000 件あると 10 分くらい）すごい時間がかかるのですが、こればかりは仕方ないです。

## 今後の展望

通信部分ばかりを改良しているせいで目に見える機能があんまり増えていないのですが、一番の根幹の部分なので頑張って完成させたいです。
