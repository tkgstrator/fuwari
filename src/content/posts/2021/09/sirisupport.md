---
title: ITMS-90626のエラーを解消した話
published: 2021-09-20
description: App Store Connect(以下ASC)からのエラーメールが届くこの対処について解説
category: Programming
tags: [Xcode]
---

# ITMS-90626 とは

アプリをローカライズしていたときに発生するエラーで、たちの悪いことにバイナリを ASC にアップロードしてからでしか警告がでない。

::: tip ITMS-90626
Dear Developer,

We identified one or more issues with a recent delivery for your app, "APP NAME" VERSION (BUILD VERSION). Your delivery was successful, but you may wish to correct the following issues in your next delivery:

ITMS-90626: Invalid Siri Support - Localized description for custom intent: 'Configuration' not found for locale: en

ITMS-90626: Invalid Siri Support - Localized description for custom intent: 'Configuration' not found for locale: ja

After you’ve corrected the issues, you can upload a new binary to App Store Connect.

Best regards,

The App Store Team
:::

とあるように`Invalid Siri Support`というのが直接的な原因であるようである。

ちなみに、このエラーが発生するためには`Widget`が利用可能である、という条件がついてくる。

### ITMS-90626 の発生条件

このエラーが発生するには以下の条件を満たす必要があるようだ。

- アプリが多言語対応している
- Widget をサポートしている
  - intentdefinition ファイルが追加されている
  - intentdefinition が多言語対応していない

要約すると WidgetKit をターゲットに追加するときのウィザードで Configuration を有効化していると自動的に Siri Intent Definition というファイルが作成され、それがローカライズされていないためにエラーが発生しているということになる。

## テンプレート的な対処法

### プロジェクトファイルの設定

![](https://pbs.twimg.com/media/E_ust_BUYAM8NWL?format=jpg&name=large)

まずはプロジェクトファイルに対して`Use Base Internationalization`のチェックを入れる。

で、正直コレの意味がよくわからない。

::: tip Base と Development Language

`Base`と`English - Development Language`は何が違うというのだろうか。

対応する言語がなければ Base つまりは Development Language として表示されるという考えなので、わざわざ Base なんてつくる必要ないと思うのだが
:::

とは言うものの、単に Localize しただけでは上手くいかない。というのも、どうやらちゃんと Localize していてもバイナリに上手く組み込まれないケースがあるようだ。

### アプリ自体のローカライズ

![](https://pbs.twimg.com/media/E_us3PFVgAEAK2a?format=png&name=900x900)

これは本件とは関係ないのだが、アプリのローカライズもしっかりとしておこう。

`Localizable.strings`というファイルを作成して、インスペクタから Localize を押せば自動でローカライズしてくれる。

### Widget のローカライズ

![](https://pbs.twimg.com/media/E_utC0CVcAQXzG-?format=jpg&name=4096x4096)

次に Widget 自体のローカライズをする。最初に Base を利用するように指定してあるので、アプリが英語と日本語に対応していたらこのように`Base`, `English`, `Japanese`の三つが表示されるはず。

それぞれにチェックを入れれば良いので入れておくように。

::: tip 注意点

環境によっては`Description`の項目を何かで埋めておかないとダメだという報告がある。

> WidgetKit で App group 追加したら ITMS-90626 エラーのメールが来るようになって localize とか色々試してもダメで厄介なのが ASC にアップロードしてからじゃないとエラーが出るのかどうか分からない点で散々上げ直した挙句結局インテントに description 入れるだけで解決したので誰かに届けこの想い（140 字）

:::

![](https://pbs.twimg.com/media/E_us7ROVEAESM3o?format=png&name=900x900)

こんな感じでローカライズのファイルがでたら問題はない。

::: warning

どうもちゃんと Xcode から追加したローカライズのファイルでないと認識しない場合があるようなので、ローカライズしているはずなのに ITMS-90626 エラーがでる人はローカライズのチェックをポチポチして再生成してやると上手くいくかも知れない。少なくとも当環境ではそれでなんとかなった。

:::
