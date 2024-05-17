---
title: フォントをマージして利用する
published: 2023-06-29
description: フォントをマージして一つのフォントとして利用しやすくするためのチュートリアルです
category: Nintendo
tags: [Splatoon3, Salmonia3+]
---

## 背景

Salmonia3+にはフォントが同梱されていないので、自分でフォントをインストールして表示する方法に付いて解説します。

スプラトゥーン 3 で利用されているフォントは以下の通り。

- 共通
  - Splatoon1-common.3b7ce8b3c19f74921f51.woff2
  - Splatoon1-symbol-common.38ddb9a11cb1f225e092.woff2
  - Splatoon1-cjk-common.62441e2d3263b7141ca0.woff2
  - Splatoon1JP-hiragana-katakana.7650dccc9af86f19f094.woff2
  - Splatoon2-common.4e7b2cad208fa2fc42ca.woff2
  - Splatoon2-symbol-common.93fd6ce98e21ffcf60bb.woff2
  - Splatoon2-cjk-common.7dc791c403ed7f33d73e.woff2
  - Splatoon2JP-hiragana-katakana.f423b5ce60b7456df1b3.woff2
- 日本語
  - Splatoon1JP-level1.fafc97f04a568e26ba52.woff2
  - Splatoon1JP-level2.225bb1db5962c9d61773.woff2
  - Splatoon2JP-level1.1f43f499aa71ee002067.woff2
  - Splatoon2JP-level2.9742567c70e359573d6d.woff2
- 韓国語
  - Splatoon1KRko-level1.a94dd3748648749f4583.woff2
  - Splatoon1KRko-level2.fcce77dce5655afed7d2.woff2
  - Splatoon2KRko-level1.43823c36f04880c807a5.woff2
  - Splatoon2KRko-level2.5f8850c8a0ecb0e0bad0.woff2
- 中国語(繁体字)
  - Splatoon1TWzh-level1.e991c1b3c2084df56d18.woff2
  - Splatoon1TWzh-level2.054b111fb7118a083ff7.woff2
  - Splatoon2TWzh-level1.e7cd7449c1194b2e74fc.woff2
  - Splatoon2TWzh-level2.c6e3984575483b178a4f.woff2
- 中国語(簡体字)
  - Splatoon1CHzh-level1.6b6af277c3dc45a8cf10.woff2
  - Splatoon1CHzh-level2.a24ca5d538d0b6a0d086.woff2
  - Splatoon2CHzh-level1.2b5402a3e1871d28d815.woff2
  - Splatoon2CHzh-level2.f1fae9e976006ec600e1.woff2

なんでこんなにたくさんあるのかと言うと、文字コード上漢字は日本語と中国語で共通のコードが割り当てられているので、日本語と中国語のフォントをマージしてしまうと漢字の表記が正しくできなくなってしまうためです。韓国語はなんで分かれてるんだっけという感じですが、分かれてなくても大丈夫だったような気がします。

なお、漢字を利用しない言語の場合（英語圏など）は共通のフォントだけをマージしてしまえば OK です。

ちなみに英語圏であっても`Splatoon2JP-hiragana-katakana`のようにひらがなのフォントが必要になるのは、プレイヤー名としてひらがなが利用可能なためです。

ひらがなのフォントを入れていないと、マッチングした仲間の名前が正しく表示されないわけですね。要するに共通フォントというのは実質的にプレイヤー名として利用な文字コードのことです。

> 正確にはちょっと違いますが、そういう認識で大丈夫です

中国語や韓国語を利用したい方はめんどくさいですが以下の手順と同じようにマージを繰り返してください。

## 環境設定

- OS
  - macOS Ventura 13.4
  - Windows 11 Pro ARM
- [FontForge](https://fontforge.org/en-US/downloads/windows/)20230101
- [Apple Configurator 2](https://apps.apple.com/jp/app/id1037126344)(macOS)
- [iMazing Profile Editor](https://imazing.com/profile-editor)(Windows)

一応 Windows と macOS での両方で作成できることは確認しました。

Windows は ARM 版しかチェックしていないのですが一般的な OSx86 でも動作すると思います。

### 日本語・英語

というわけでスプラトゥーン 3 の公式のフォントをマージしようとしたら共通フォント 8+日本語フォント 4 でとてつもなくめんどくさいのですが、なんと英語と日本語対応だけであればスプラトゥーン 2 用のフォントが利用できます。

> スプラトゥーン 2 は日本語・英語・欧州の言語に対応している

中国語と韓国語のフォントはプレイヤー名に使えないので、中国語・韓国語でないのであればこちらを利用するのが楽です。フォント自体も四つしかないので二回マージしてしまえば良いです。

- Splatfont
  - [ab3ec448c2439eaed33fcf7f31b70b33.woff2](https://app.splatoon2.nintendo.net/fonts/bundled/ab3ec448c2439eaed33fcf7f31b70b33.woff2)
  - [0e12b13c359d4803021dc4e17cecc311.woff2](https://app.splatoon2.nintendo.net/fonts/bundled/0e12b13c359d4803021dc4e17cecc311.woff2)
- Splatfont2
  - [eb82d017016045bf998cade4dac1ec22.woff2](https://app.splatoon2.nintendo.net/fonts/bundled/eb82d017016045bf998cade4dac1ec22.woff2)
  - [da3c7139972a0e4e47dd8de4cacea984.woff2](https://app.splatoon2.nintendo.net/fonts/bundled/da3c7139972a0e4e47dd8de4cacea984.woff2)

> 二次配布ではなく公式のフォントへのリンクです

スプラトゥーン 2 のフォントは認証もなくアクセスできるので URL を貼っておきます。これをダウンロードして自分のパソコンでマージしてしまいます。

なお、マージには FontForge というアプリケーションが必要になります。一応、Windows と macOS の両対応らしいので手元では macOS でしか検証していませんが同じようにインストールできると思います。

### スプラトゥーン 1

スプラトゥーン 1 用のフォント二つを FontForge で開きます。

- 0e12b13c359d4803021dc4e17cecc311.woff2
- ab3ec448c2439eaed33fcf7f31b70b33.woff2

ここで`0e12b13c359d4803021dc4e17cecc311.woff2`を開いているウィンドウで操作を進めます。

> `ab3ec448c2439eaed33fcf7f31b70b33.woff2`は日本語フォントでマージするフォントなのでこちらはただ開いているだけで大丈夫です。

#### フォント情報の変更

`Element`から`Font Info`で確認するといろいろ情報が見れますが、ここの情報を正しく設定しないとアプリがフォントを読み込めないので、以下のように変更します。

|                 |  修正前   |   修正後   |
| :-------------: | :-------: | :--------: |
|    Fontname     | Splatoon1 | Splatfont1 |
|   Family Name   | Splatoon1 | Splatfont1 |
| Name For Humans | Splatoon1 | Splatfont1 |
|     Weight      | ExtraBold | ExtraBold  |
|     Version     |  001.001  |   1.0.0    |

#### フォントのマージ

次に`Element`から`Merge Fonts`を選択します。すると`Font to merge into Splatfont1`と表示されます。

> 違う文面が表示されたら`Font Info`の設定が誤っているので最初からやり直してください

ここでちゃんと`ab3ec448c2439eaed33fcf7f31b70b33.woff2`を開いていれば`RowdyStd-EB-Kanji`というのが表示されていると思うのでそれを選択して OK を押します。

#### フォントの出力

これでフォントのマージはできたので、最後に`File`から`Generate Fonts`を選択します。

ファイル名は何でも良いのですが、今回は`Splatfont1.ttf`にしました。

![](https://pbs.twimg.com/media/FzwJU45aQAEjeho?format=jpg&name=large)

ファイル名の下には`TrueType`が選択されているようにします。

> TrueType 以外は利用できないので必ず確認してください

あとは Generate を押して、何か警告が出たら適当に全て OK を押してください。

これができたら今開いている FontForge を全て閉じます。

### スプラトゥーン 2

スプラトゥーン 2 用のフォント二つを FontForge で開きます。

- eb82d017016045bf998cade4dac1ec22.woff2
- da3c7139972a0e4e47dd8de4cacea984.woff2

ここで`eb82d017016045bf998cade4dac1ec22.woff2`を開いているウィンドウで操作を進めます。

> `da3c7139972a0e4e47dd8de4cacea984.woff2`は日本語フォントでマージするフォントなのでこちらはただ開いているだけで大丈夫です。

#### フォント情報の変更

`Element`から`Font Info`を開いて編集します。

|                 |  修正前   |   修正後   |
| :-------------: | :-------: | :--------: |
|    Fontname     | Splatoon2 | Splatfont2 |
|   Family Name   | Splatoon2 | Splatfont2 |
| Name For Humans | Splatoon2 | Splatfont2 |
|     Weight      |  Regular  |  Regular   |
|     Version     |  001.001  |   1.0.0    |

スプラトゥーン 2 向けのフォントの場合は高さの設定がバグっているので追加で修正する必要があります。

追加で`OS/2`の`Metrics`タブを選択してください。

そして、以下のように値を変更します。

|      項目      | 修正後 |
| :------------: | :----: |
|   Win Ascent   |  1101  |
|  Win Descent   |  311   |
|  Typo Ascent   |  800   |
|  Typo Descent  |  -200  |
| Typo Line Gap  |   90   |
|  HHead Ascent  |  1101  |
| HHead Descent  |  -311  |
| HHead Line Gap |   90   |
| Capital Height |  781   |
|    X Height    |  573   |

変更ができたら OK を押して保存します。

#### フォントのマージ

次に`Element`から`Merge Fonts`を選択します。すると`Font to merge into Splatfont2`と表示されます。

`KurokaneStd-EB-Kanji`というのが表示されていると思うのでそれを選択して OK を押します。

#### フォントの出力

こちらは`Splatfont2.ttf`という名前で保存しました。

### チェック

ちゃんと作成できれば以下のファイルが生成されるはずです。ハッシュ値をチェックしたい方は、

```zsh
shasum -a 256 Splatfont1.ttf
shasum -a 256 Splatfont2.ttf
```

で確認できます。ひょっとしたらこのコマンドは macOS だけでしか効かないかもしれませんが......

- Splatfont1.ttf
  - 999KB
  - 148e343c715635d53bad8e75d3512578e5a40c107c1ff4f48c9245e02f99e413
- Splatfont2.ttf
  - 889KB
  - f898a0e3dc7b7f618693b33ea895f3cf2648858bf68f30850e74e689dd058c33

> FontForge が毎回同じファイルを出力するかはわからないのですが、一応上のハッシュになりました

## 構成プロファイルの作成

次に作成したフォントを構成プロファイルに組み込みます。

構成プロファイルはただの XML ファイルなのでテキストエディタでも作成はできるのですが、BASE64 エンコードする必要があったりとめんどくさいので専用のソフトウェアを利用する方法を推奨しています。

> macOS ユーザーにはおなじみの plist ファイルです

Windows の場合は iMazing Profile Editor を macOS の場合は Apple Configurator 2 を使いましょう。

多分 Windows ユーザーの方が多いと思うので iMazing Profile Editor の画面で説明します。

[iMazing Profile Editor](https://imazing.com/profile-editor/download)を開いて Download for PC で Windows 向けのソフトウェアをダウンロードし、インストールします。

インストールして起動したとします。

### 一般設定

構成プロファイルの目的がわかりやすいように名前をつけておきましょう。

また、固有の Identifier を設定する必要があります。デフォルトだと変な値が入っていますが、PC 名が入っている場合などがあるので適当に UUID で置き換えてしまって構いません。

今回は[Online UUID Generator](https://www.uuidgenerator.net/version4)で適当な値を生成してくれるのでそれを利用しました。

![](https://pbs.twimg.com/media/FzwOiVMakAc43ag?format=jpg&name=large)

### フォントの追加

左側のタブからフォントの項目を検索して+を押してファイルを選択して追加します。

追加する順番はどっちからでも良いです。

> フォントは ttf か otf しか対応していません

![](https://pbs.twimg.com/media/FzwMiCTaIAADumG?format=jpg&name=large)

あとはこれを Splatfont.mobileconfig として保存します。

すると 2500KB くらいのファイルが生成されるはずなので、それを何らかの方法で iPhone に転送します。

> メールとかディスコードとかで大丈夫です
>
> この構成プロファイルは任天堂の著作物を含むので絶対に一般公開しないようにしてください

ここまででパソコンでの操作は完了です。

## 構成プロファイルのインストール

iPhone でメールで送られてきた構成プロファイルやディスコードの添付ファイルのリンクを開きます。

それを開いたときの操作を[インストール方法](https://video.twimg.com/ext_tw_video/1674240573933506560/pu/vid/720x1558/HT6NtAcQ7rx_JqzR.mp4)として動画化したのでこちらを見ていただくのが良いかと思います。

この状態で再び Salmonia3+を開くとインストールしたフォントが反映されていると思います。

ホームスクリーンに[Salmon Stats+](https://cdn.discordapp.com/attachments/1123803718249349150/1123803873954504754/SalmonStats.mobileconfig)を追加するプロファイルを作成してみたので、どういうことができるか気になる方はインストールしてみてください。

### 注意点

構成プロファイルはインストールすると本来の設定では弄れないところまで変更することもできてしまうので、署名されていない（誰が作成したかを Apple が保証していない）プロファイルをインストールすることは絶対に避けてください。

今回は自身で作成したプロファイルで、怪しい設定が含まれていないことがわかっているので無条件にインストールしています。
