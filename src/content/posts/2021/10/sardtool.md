---
title: "[決定版] SARC Toolの使い方"
published: 2021-10-02
description: SZSやSARCファイルの中身を取り出すSARC Toolの使い方について解説します
category: Hack
tags: [CFW, Switch]
---

# [SarcTool](https://github.com/aboood40091/SARC-Tool)

SZS や SARC の中のファイルを取り出したいときは SARC Tool を使うのが最も手っ取り早いです。

オリジナルコードは python にしか対応していませんが、リリースには実行ファイル（.exe）があるのでそっちを使いましょう。

## SZS とは

Nintendo Wii から使われている 3D モデルやテクスチャデータが入っている圧縮ファイル。

圧縮される前は SARC という拡張子が用いられる。

詳しくは以下の引用文をどうぞ。

> Data file used by games for the Nintendo Wii; most commonly known for storing 3D model and texture data for the Wii game Mario Kart, but also used by other games for the same kinds of data as well as other types of data; sometimes modified by the homebrew and modding communities to create custom Mario Kart graphics.
>
> https://fileinfo.com/extension/szs

SZS は暗号化されていないので各種キーは不要です。

### 展開

`sarc_tool.exe`というファイルがあるはずなので、そこに SZS をドラッグアンドドロップするだけです。

::: tip 対応ファイル

SARC Tool とあるが`SZS`, `SARC`, `PACK`の拡張子に対応している。

:::

### 圧縮

フォルダごと `sarc_tool.exe` にドラッグアンドドロップします。

ただ、これでは圧縮されていないので元のファイルよりもずいぶん大きくなってしまいますし、拡張子が`SZS`ではなく`SARC`になっているのでちゃんと読み込んでくれるかどうか不安です。

::: tip SARC と SZS

`SZS`は`SARC`の圧縮形式である。`sarc_tool.exe`は高速化のために何もしなければ圧縮しないという処理がなされるため、単にドラッグアンドドロップしただけだと`SARC`ファイルになってしまう。

:::

#### バッチファイル

そこで、以下のコマンドを実行するバッチファイルを作成します。

```zsh
:: Compress to szs for Nintendo Switch
%~dp0sarc_tool.exe -little -compress 9 %~f1
```

このバッチファイルができたら`sarc_tool.exe`と同じフォルダに突っ込みましょう。

圧縮したいときは`sarc_tool`ではなくてこのバッチファイルにドラッグアンドドロップすれば`SZS`に圧縮してくれます。

::: tip 圧縮率について

圧縮率は 9 に設定していますが、時間がかかる場合は小さい数字にしてください。

うちの環境（i7 6700K）だと元サイズ 91MB のファイルを圧縮率 9 で 46MB に圧縮するのに約 50 秒かかりました。

:::

## まとめ

sarc_tool の使い方をきかれるとは全く思っていなかったのですが、何人かの方にきかれたので執筆しました。

重要はどこにあるかわからないものですね。
