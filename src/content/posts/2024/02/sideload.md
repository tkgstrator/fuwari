---
title: Sideloadでプッシュ通知を有効化したアプリをインストールする方法 
published: 2024-02-02
description: No description
category: Programming
tags: [macOS, iOS]
---

## Sideload

自己署名を行ったアプリではプッシュ通知が効かなくなってしまうという問題が存在する。

例えば、Twitterの機能を拡張したBHTwitterのTweakをアプリにバンドルしたものは非常に便利なのだが、これをSideloadでインストールするとフォローやリプライ、DMに対する通知が一切受け取れなくなってしまう。

Sideloadについて知りたい方は[Sideloading Master Guide](https://sideloading.gitbook.io/sideloading-master-guide/)を読むと良い。

### 通知が受け取れない理由

その原因ははっきりとは理解していないのだが、概ね以下の理由のどれかだと思われる。

1. 自己署名の際にアプリのBundle Identifierが変わってしまっている
2. 自己署名の際に利用したMobile ProvisioningにPush通知に対する権限がない
3. 署名のBundle Identifierがアプリにバンドルされているentitlementの値と異なってしまっている

ところが、ググってみると開発者証明書であればSideloadでも通知を受け取れる、という記述をいくつか見かける。

しかしながら詳しい手順について調べてみても見つからず、唯一近い情報であろうと思われる[MaplesignでSideload](https://note.com/tiyoko2525/n/naea3d9d86f9c)についてはEsignを利用するというような情報しか得られなかった。

また、自分がアプリ開発のために開発者証明書を持っているのでPush通知が効くようにしたProvisioningでインストールしてもやっぱり通知は効かなかった。

### appdb.to

Sideloadをサービス化して展開しているappdb.toの公式アカウントを見ると以下のようなツイートを見つけることができた。

> Regarding push notifications on tweaked apps: They work, if you are replacing original app, because it depends on bundle id

プッシュ通知が機能するかどうかはバンドルIDに依存しているので、元のアプリを置換すれば機能する。

> They work, only if you are jail broken

端末が脱獄されている場合のみ動作する。

端末が脱獄されていればうちのブログで何度も述べているようにインストールできるアプリ数が三つに制限されている(非開発者証明書の場合)Sideloadを使う必要がないので(Tweak自体をインストールすれば良い)一体何のツイートなんだという気がしなくもない。

と思っていた矢先、つい五日前に投稿されたRedditのスレッド[Push notifications for sideloaded apps](https://www.reddit.com/r/sideloaded/comments/1aciv22/comment/kjvbsd7/)が解決の糸口となった。

> Hi everyone,
>
> I have my own developer accounts and I wonder is it possible to get push notifications through that (for instagram etc..)? I’m asking because I saw so many topic about it “if you have dev account it’s possible” but can’t see any way how to make it happen.
> 
> Thanks.

これは、おおよそ以下のように解釈できる。

よう、お前ら！
わいは自分自身の開発者アカウントを持っているんやが、プッシュ通知をインスタグラムやその他のアカウントで受け取ることができるのかどうかが気になってるんや。いくつかのトピックで開発者アカウントを持っていればできるって見かけたんやけど、どうやればできるかが見つからんのや。
知ってたら教えてな、ほな。

それに対する公式の回答がこちら。

> Add your developer account to appdb, so it will be configured correctly, enable “ask for installation options” on device features configuration page, install app and answer “yes” to push notifications support. No computer required, no payments required.

開発者アカウントをappdbに追加するやろ？ほなら設定がうまくいくわけや。インストールオプションをデバイス機能設定ページから有効化して、アプリのインストール時にプッシュ通知をサポートするかどうかにイエスと答えればええんやで。パソコンも要らんし、無料でできるで。

......!?

## 実際にやってみた

以下、必要なもの

- 開発者用アカウント(年間$99のApple税を支払う必要がある)、多分必須
  - ない場合は[MapleSign](https://maplesign.ca/)や[UDID Registrations](https://www.udidregistrations.com/)で他の開発者に自分の端末UDIDをプロビジョニングに紐付けてもらう必要がある
  - 大体一年間で$15~20が相場、この値段は端末一台あたりである
  - もし家族や友人と使いたいなどでデバイスが五台以上あるなら割り勘して素直に開発者アカウントを取ると良い
- [appdb.to](https://appdb.to/)のアカウント

> 代わりに[GitHub](https://github.com/n3d1117/appdb)のこれでもいけるかも、試してないけど

以下、BHTwitterでやってみた内容をメモ。

公式サイトの[該当ページ](https://appdb.to/my/configure)に移動し`Ask for options during installation requests?`を有効化する。

その後でインストールしたいアプリを`Install custom application(MyAppStore)`にアップロードして(既に公式でサポートされている場合はこの限りではない)、それをインストールする。

するとインストール時にバンドルIDを変えるとか、アプリ名を変えるとかの選択肢が表示される。

そこでプッシュ通知を有効化するを選択する。

しばらくするとインストールが始まり、アプリを起動してログイン時に表示される「プッシュ通知を有効化しますか」というダイアログに対して「はい」を押す。

別アカウントからリプライやDMなどで通知が来るような処理を飛ばすと......

通知がきた！！！！！

### 仕組み

わからん。

多分Push通知を有効化しているプロビジョニングを発行しているとかそんなのだと思う。

> 通常発行される任意のバンドルIDに対するプロファイルはプッシュ通知を有効化できない

便利な機能ではあるがappdb自体が内部的な処理がブラックボックスなのでアップロードしたアプリにマルウェアが混入されているとかそういう可能性も否めない(なのでリスクを最低限に抑えるためにも自分自身でアプリをアップロードしているのだが)ところは唯一の欠点と言える。

ローカルで署名できるSideloadlyにも同じ機能が付けばいいのにと思わなくもないが、ネットワーク経由でできればそれはそれで便利なのでそのあたりのリスクを許容できるのであれば良いサービスなのではないかと思う。

Xの通知が受け取れなくて困っていたので、こんなに簡単に解決できたのは非常に良かった。プロビジョニングの発行とかめんどくさいし。

インストール時のオプションには課金を有効にするというものもあるが、これもバンドルIDが変わるとAppleへのリクエストが通らなくなり、課金ができなくなることへの対策だと思われる。

ということは、ここを有効化すればSideloadしたアプリでもVPNを利用できる可能性がある！ちょっとテンション上がってきました。

記事は以上。