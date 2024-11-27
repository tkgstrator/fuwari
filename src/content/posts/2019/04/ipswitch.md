---
title: "[Hack] IPSwitchの使い方"
published: 2019-04-01
description: IPSwitchについて簡単に解説しています
category: Hack
tags: [IPSwitch]
---

## [IPSwitch](https://github.com/3096/ipswitch)

IPSwitch とは pchtxt（パッチテキスト）を読み込み、IPS 形式のパッチとして出力するツールのこと。

これがあるだけでわざわざ自分で IPS ファイルを書かなくてもコードを実際に使える形式に変換してくれます。

まずは IPSwitch をダウンロードし、switch フォルダ内に「ipswitch」というフォルダを作成し、ipswitch.nro をコピーします。

つぎに ipswitch フォルダ内に名前は何でもいいので、フォルダを作成します。

あとはそのつくったフォルダの中に pchtxt 形式のコードファイルをコピーします。

例えとしては、こんな感じです。

`sdmc:/switch/ipswitch/Splatoon 2/5.4.0public.pchtxt`

コードは移植と開発の二通りの入手方法があります。

また、インターネットで誰かが公開しているものを使うという手も考えられます。

[スプラトゥーン 2 チートコード](https://takaharu422.github.io/Splatoon2.github.io/ja.html)

## Switch 側の設定

hbmenu から IPSwitch を起動します。

Toggle Patch Text Contents で A ボタンを押して進めます。

今回は 5.4.0 向けのコードを有効化したかったので 5.4.0public.pchtxt で A ボタンを押すと、ファイル内に記述されているコードがロードされます。

![](https://pbs.twimg.com/media/E2cR9kiVUAA3qT6?format=png)

赤色表示は無効化されているコードなので有効化したいもので A ボタンを押して逐次好きなようにカスタマイズしてください。

カスタマイズができたら最後に Y ボタンを押して IPS ファイルを出力します。

![](https://pbs.twimg.com/media/E2cR_wnVEAIeDJG?format=png)

All Done と表示されたらコード出力が完了したので + ボタンで hbmenu に、HOME ボタンで HOME メニューに戻れます。

あとは好きなだけ遊んでください。

記事は以上。
