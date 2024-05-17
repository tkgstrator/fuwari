---
title: BPRM/BYAML/BYMLを復号しよう
published: 2021-05-28
description: スプラトゥーンではXMLを暗号化したBPRMなどのファイルが使われていますが、これを復号して中身を見てみることにしましょう
category: Hack
tags: []
---

## BPRM/BYAML/BYML とは

XML の派生である YAML などをニンテンドー独自の暗号化で難読化したもの。

復号ツールが公開されているのでそれをまずはダウンロードしてきます。

## [TheFourthDimension](https://github.com/exelix11/TheFourthDimension)

スーパーマリオオデッセイ用のプログラムなのですが、スプラトゥーン 2 と同じく bprm v3 の暗号化が施されているのでこのツールで復号化することができます。

どうもいくつかの最新のファイルには対応していないようですが、基本的にはこれで問題ありません。

ダウンロードすると The4Dimension.exe が入っていると思います。

この The4Dimension.exe は `The4Dimension.exe.exe batch FileName` というコマンドで bprm や byml を復号することができます。

ただ、これだと単一のファイルにしか対応していないのでバッチファイルを作成してループ処理ができるようにします。

```zsh
@echo off
mkdir %~dp0bprm
for %%f in (*.bprm) do (
copy %%f %~dp0bprm %%~nxf
%~dp0convert.exe batch %~dp0bprm %%~nxf
del %~dp0bprm %%~nxf
ren %~dp0bprm %%~nxf.xml %%~nf.xml
)
```

このバッチファイルを作成してやれば BPRM ファイルを突っ込めば同一ディレクトリにある全ての BPRM ファイルを XML に変換してくれます。

作成したバッチファイル（例えば、Decrypt.bat）を convert.exe と同じフォルダにおいておきます。

あとはこのバッチファイルに bprm ファイルをドラッグアンドドロップするとフォルダ内の BPRM ファイルが全てコピーされたあとで変換されるという仕組みです。

ただ、この次に紹介する ParmHash を使えばいちいちバッチファイルなんかつくらなくても変換してくれるのでそっちでもアリかもしれません。

### コードを置換する

ただ、これで復号した xml はそのままでは読みにくいので人間が読みやすいコードに変換しましょう。

ちょっと前にリリースした[ParamHash](https://tkgstrator.work/posts/2021/02/26/paramchanger.html)

::: warning 逆変換にバグがある

ハッシュからパラメータ名に変換するときに型を無視する設定にしてしまったので、逆変換ができません。

:::

## 暗号化

```zsh
@echo off
mkdir %~dp0encrypt
for %%f in (*.xml) do (
copy %%f %~dp0encrypt %%~nxf
%~dp0convert.exe batch %~dp0encrypt %%~nxf
del %~dp0encrypt %%~nxf
ren %~dp0encrypt %%~nxf.byml %%~nf.bprm
)
```

再暗号化は同じコマンド`The4Dimension.exe.exe batch FileName`で行なえます。

やはりそれでも一つずつしかファイルが処理できないのでバッチファイルを作成します。

::: danger コマンドについて

動作確認していないのですが、多分上記みたいなバッチファイルで動作するはずです。

間違っていたら各自修正お願いします。

:::

## まとめ

今回は BPRM を XML に復号してパラメータを弄る方法について解説しました。

記事は以上。
