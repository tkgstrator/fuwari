---
title: "[第二回] THEOSで脱獄アプリを作成する"
published: 2021-06-22
description: THEOSを使って簡単な脱獄Tweakを作成するためのチュートリアルです
category: Programming
tags: [Swift]
---

## THEOS JAILED

```zsh
==============
= 必要なもの =
==============
1. 忍耐力と運
2. XcodeとiOS SDK
3. Clutchなどで復号されたipaファイル

======================================
= プロビジョニングプロファイルの作成 =
======================================
注意: このステップは一つのアプリに対して一度実行するだけで良い. もしワイルドカード
     のプロファイルがある場合はこのステップをとばして構わない.
1. Xcodeをひらき、新規プロジェクトを作成.
2. iOSを選択し, Single View Applicationを選ぶ.
3. プロダクト名として<PRODUCT NAME>を利用する.
4. Organization Identifierとして<ORGANIZATION IDENTIFIER>を設定する.
5. Nextを押してプロジェクトを保存. Gitのチェックは外しておくこと.
6. デバイスをMacに接続してアプリをビルドする. さまざまな警告はのちのち解決するので
   現段階では無視して良い.
7. Deployment Info内のDeployment Targetを自身のデバイスに合わせる.
8. Signingで自分のAppleIDを選択する
9. Fix Issueを押す. この段階でプロビジョニングプロファイルが自動で作成される.
10. Generalタブの右のCapabilitiesを選択する.
11. App Groupsを有効化する.

==============================================
= プロビジョニングプロファイルのインストール =
==============================================
1. Runを押してアプリをインストールする.
2. アプリがインストールして起動を確認したらアプリを削除する.
3. Xcodeを終了する
注意: このステップは一つのアプリに対して一度実行するだけで良い

================================
= ios-deployでインストールする =
================================
1. Run make package install PROFILE=ID-5A701E68.work.tkgstrator.ikawidget2adkiller
   Note: If you omit the PROFILE=… part, the script will try to use
         Xcode iOS Wildcard App ID. This will only work if you are enrolled
         in the Apple Developer Program.
2. If you get an error during installation, use the following method:

===========================
= Xcodeでインストールする =
===========================
1. XcodeのタブからDeviceを選択する.
2. Installed Appsの下の+をクリックする.
3. パッチを当てたipaを選択し, 神に祈る.
4. パッチを当てたipaがデバイス上に表示される
```
