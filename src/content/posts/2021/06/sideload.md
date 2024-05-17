---
title: Sideloadで入獄状態で脱獄アプリを動かそう
published: 2021-06-23
description: 脱獄していないデバイスで脱獄アプリを直接起動することは不可能ですが、Sideloadを使うことで擬似的に再現できます
category: Hack
tags: [Swift]
---

# Sideload とは

::: tip Sideload とは

サイドローディングとは、アプリケーションストアを通じてアプリの配布や管理を行っているシステムにおいて、正規のアプリケーションストアを経由せずにアプリを入手し、インストールすることである。

:::

> [非脱獄向け Tweak（？）巷で話題の Sideload を試してみたらかなりの可能性を感じた話。](https://qiita.com/ChikuwaJB/items/f9ab56d0d753bec678b0)
>
> [【iOS9.3 対応】Xcode を使った非脱獄デバイスでアプリを Sideload する方法](https://ichitaso.com/iphone/sideload/)

これは最近の脱獄にも使われており、[Uncover](https://unc0ver.dev/)や[TAURINE](https://taurine.app/)も Sideload を使って自己署名を使ってアプリをインストールし、そのアプリから脱獄をおこなう仕組みになっている。

Sideload 自体は公式の機能であるので何ら違法性はないのだが、開発者でないアカウントの場合はインストールする際の署名の有効期限が七日しかないという制約がある。開発者アカウントの場合は一年間有効なのだが、開発者になるためには年間 12000 円程度かかるので、このためだけにわざわざ開発者になる必要はない。

で、ここで Unc0ver や TAURINE が自己署名でインストール可能なのはそれらが署名されていない IPA であり、自己署名可能だからである。

AppStore からインストールした IPA には既にアプリ開発者の署名がされているため、それらに更に署名を施すことはできない。つまり、X というアプリを購入した A くんの iPhone や iTunes から IPA を抜き出し、それを B くんの署名で B くんの iPhone にインストールすることはできない。

要するに、海賊行為はできないようになっているのである。

## 署名の解除

が、署名を解除する方法は存在する。もちろん普通の状態ではできない。インストールされたアプリから署名を解除するにはデバイスが脱獄されている必要がある。

脱獄されたデバイスから署名を解除した IPA をダンプする方法はいくつかあります。

### [dumpdecrypted](https://github.com/stefanesser/dumpdecrypted)

セキュリティ専門家の Stegen Esser 氏が開発したダンプツール。

流石に最近は動かないのではないだろうか。

### [Clutch](https://github.com/KJCracks/Clutch/wiki/Tutorial)

iOS10 くらいまでは使えていた覚えがあるダンプツール。

最近は使えないイメージがある。

### [Rasticrac](https://github.com/easonoutlook/Rasticrac)

Clutch が使えなくなった後に使っていたダンプツール。

最近、公開されていないイメージがある。

### [bfinject](https://github.com/BishopFox/bfinject)

Rasticrac が消滅した後にしばらく使っていたダンプツール。

iOS13 くらいまでは動いていたけど最近はご無沙汰している。

### [bfdecrypt](https://github.com/BishopFox/bfdecrypt/)

bfinject を利用したダンプツール。

多分 iOS14 でも動く

### [Clutch2](https://github.com/KJCracks/Clutch2)

Clutch が進化したやつだけど、最終コミットが 8 年前なのでもう動かなさそう。

### CrackerXI+

現状最もオススメできる IPA 復号ツール。

当たり前だけど、海賊行為には利用しないこと。

標準レポジトリにはないので[AppCake](cydia://url/https://cydia.saurik.com/api/share#?source=http://cydia.iphonecake.com/)をタップして追加しよう。

で、ただインストールしただけだと動かないらしいので CrackXI+をインストールする前に、

- [AppSync Unified](cydia://url/https://cydia.saurik.com/api/share#?source=https://cydia.akemi.ai/)
  - 署名のないアプリをインストールすることができるようにする
- New Term 2
  - 必要かどうかはわからんけど、なんか書いてあった

を先にインストールしておくこと。そうでないと CrackerXI+が動作しない。また、将来的に必要になるので以下のツールもインストールしておくことを推奨する。

- Apple File Conduit "2" (iOS 11+, arm64)
  - root 領域へのアクセスを許可する
- Filza File Manager
  - Web サーバを立てられる便利なユーティリティツール

::: tip インストール順を間違えた場合

先に CrackerXI をインストールしてしまっていた場合には CrackerXI を再インストールすれば良い。

:::

## CrackerXI+の使い方

![](https://pbs.twimg.com/media/E4jlD6kUYAAf2Ao?format=png)

単に起動して署名解除をしようとすると`Enable CrackerXI hook in settings tab.`と表示されるので`Settings`から設定を更新しよう。

![](https://pbs.twimg.com/media/E4jlD6iVUAcsq0U?format=png)

ここで`CrackerXI hook`を有効化します。

![](https://pbs.twimg.com/media/E4jlD6jVgAEVGPZ?format=png)

有効化しているとちゃんと動作します。このとき`YES, Full IPA`を選択します。

![](https://pbs.twimg.com/media/E4jnQoNVUAYveLZ?format=png)

アプリを選択すると一度画面が切り替わったあとで再び`CrackerXI+`がひらきます。

![](https://pbs.twimg.com/media/E4jnQoOUUAMS0jH?format=png)

こんな表示がでたらダンプは成功です。

## ダンプした IPA をコピー

ダンプした IPA は`/var/mobile/Documents/CrackerXI`の中に保存されているので、それをパソコンにコピーします。

これは`Filza File Manager`の`WebDAV Server`の機能を使えば簡単です。

![](https://pbs.twimg.com/media/E4jl4CPVoAIisY6?format=png)

`Filze File Maanger`をひらいたら下にある歯車マークを押します。

![](https://pbs.twimg.com/media/E4jl4CQUUAEhqJh?format=png)

そこで`Enable WebDAV Server`を有効化します。更に下を見ると

```
Listening at https://192.168.1.13:11111
```

と書いてあるので、パソコンでそのアドレスにアクセスします。

::: tip Listening アドレスについて

この値は人によって異なるのでちゃんと自分の表示されている値を確認してください。

:::

![](https://pbs.twimg.com/media/E4jrWivVIAIlZa2?format=png)

URL にアクセスするとこのようにデバイスの内部データにアクセスできます。

`/var/mobile/Documents/CrackerXI`に移動するとダンプした IPA があることがわかります。

![](https://pbs.twimg.com/media/E4jrbIAVUAUcf7o?format=png)

ダウンロードしたいクリックすると以下のような画面に変わります。

![](https://pbs.twimg.com/media/E4jrdZdVEAAwYCN?format=png)

ここで`Download`を押せば IPA ファイルがデバイスからパソコンにコピーされます。

## ここまでの流れ

さて、ここまでできれば Sideload 用の IPA は用意できました。

しかし、よく考えるとここまでの一連の流れは意味がないことがわかると思います。

というのも、インストールされたアプリの署名を解除して自己署名でインストールする意味がないからです。それなら最初から署名の期限もない AppStore 公式の署名を使えばよいではないかと。

なので、単にダンプした IPA をインストールするのではなく、IPA に`dylib`を同梱します。

### dylib とは

`dylib`とは超簡単に言うと実行時にアプリケーションのバイナリが参照するライブラリファイルのことです。

これを同梱するとどんな意味があるかというと、`dylib`に何らかの処理を行うメソッドを書き込んでアプリ起動時にそれを参照するようにすれば本来のアプリの挙動とは違う動作を行なうことができるようになります。

つまり、本来は脱獄 Tweak として動作させていた処理をアプリ自身から行わせることができるということになるわけです。しかも脱獄 Tweak は署名がされていないので非脱獄環境では動作させることができませんが、Sideload であれば自己署名した IPA のバイナリが呼び出すため Sandbox の制約に引っかかることもありません。

### Sideload の限界

とはいっても、全ての脱獄アプリを動作させることができるわけではありません。動作させられるのはアプリのバイナリに Hook するタイプの Tweak に限られます。

また、そのような Tweak も全てが動作するわけではなく外部フレームワークを要求するものについては一部動かすことができません。

## ここからの流れ

次に必要になるのはアプリを改造するための dylib を作成することです。

しかし、これは[THEOS JAILED](https://tkgstrator.work/posts/2021/06/21/theossetup.html)の開発環境を整えたり、Objective-C や Swift などの知識が必要で一朝一夕でできる作業ではありません。

じゃあめんどくさいなあってなるところなんですが、世の中には他の開発者が作成した Tweak が山のようにあるのでそれを利用します。

要するに、

1. 公開されている脱獄 Tweak のうち Sideload で利用できるものを探す
2. その Tweak が Hook しているアプリを AppStore から取得する
3. そのアプリの署名を解除する
4. IPA に dylib を同梱した上で再度 IPA にパッケージングする
5. 改造した IPA を自己署名でインストールする

という流れになります。

## カスタマイズした IPA の作成方法

今回は Twitter のプロモーションのツイートを非表示にする方法を考えてみます。

Twitter のように超有名なアプリは脱獄 Tweak の開発も盛んなので、調べれば簡単に目的のものが見つかります。

### 脱獄 Tweak から DEB を入手する

今回は Hao Nguyen 氏が開発した[Twitter No Ads](https://www.ios-repo-updates.com/repository/bigboss/package/com.haoict.twitternoads/)を利用します。

最新のバージョンは 0.0.2 なのでそれをダウンロードします。

### DEB を展開する

```zsh
brew install dpkg
dpkg -x XXXXXXXX.deb YYYYYYYY
```

::: tip DEB 展開について

`XXXXXXXX`にはダウンロードした`DEB`のファイル名、YYYYYYYY には展開した先のフォルダを指定して下さい。

フォルダがない時は自動的に作成されるので、適当で大丈夫です。

:::

![](https://pbs.twimg.com/media/E4j0IqFVgAA1vHZ?format=png)

すると目的の`dylib`が手に入ります。

### IPA に DYLIB を同梱させる

ここが一番めんどくさいところなのですが、`IPA`に`DYLIB`を同梱させた上でバイナリから`DYLIB`を実行するようにパッチを当ててくれるツールがあります。

- [iPAPatcher](https://github.com/brandonplank/iPAPatcher)
  - Catalina 以上であれば動作する
  - おそらく今後のアップデートはなし
- [iPatch](https://github.com/EamonTracey/iPatch)
  - Big Sur 以上で動作する
  - 今後のアップデートもありそう

上の二つがとりあえず見つかったのですが、自分は macOS が Catalina でしたので必然的に`iPAPatcher`を使うことになりました。

![](https://pbs.twimg.com/media/E4j1RlSVoAMw--H?format=png)

まったく難しい作業はなく、ダンプした署名解除済みの`IPA`と先程展開した`dylib`を選択するだけです

![](https://pbs.twimg.com/media/E4j1cwjVcAce7F5?format=png)

選択したら`Patching.`を選択します。

![](https://pbs.twimg.com/media/E4j1elwVEAEZKUW?format=png)

IPA のサイズにもよるのですが、二分ほどで終わると思います。

### IPA をインストールする

ここまでできれば作成された IPA をインストールするだけです。

- [Cydia Impactor](http://www.cydiaimpactor.com/)
- [iOS App Signer](https://www.iosappsigner.com/)
- [Sideloadly](https://pangu8.com/sideloadly/)

いろいろツールはあるのですが、個人的には[Sideloadly](https://pangu8.com/sideloadly/)が好きなのでそれをおすすめしておきます。

これ以外にも Xcode を利用する方法などいろいろあります。

完成した IPA をインストールすれば無事に全てのプロモーションが消えます。

記事は以上。
