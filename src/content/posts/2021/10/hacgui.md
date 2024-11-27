---
title: "[決定版] HACGUIでアップデータを取得しよう"
published: 2021-10-01
category: Hack
tags: [CFW, HACGUI, Switch]
---

# [HACGUI](https://github.com/shadowninja108/HACGUI)

::: warning HACGUI

ひょっとしたら GitHub のやつは動作しない可能性があるので、Shadow 氏が別途ビルドした[9.0.0+版](https://cdn.discordapp.com/attachments/432400335235973120/642844112613015564/HACGUI.zip)を使うと良いかもしれないです。

:::

shadowninja108 氏が作成した、ニンテンドースイッチの NAND から直接各種キーを抜き出し、それを使って NAND や SD に保存されているデータを復号してバックアップできるツールのこと。

ほぼ同等（あるいは上位互換）の機能を持ったものに[NxDumpTool](https://tkgstrator.work/posts/2021/06/10/nxdumptool.html)があるが、それとの比較もおこなっていきたいと思う。

## NxDumpTool との違い

ざっくりまとめると以下のような違いがあります。それぞれどういう風に違ってくるのかも解説します。

|                  | HACGUI | NxDumpTool |
| ---------------- | ------ | ---------- |
| PC レス          | 不可   | 可         |
| CFW レス         | 可     | 不可       |
| BCAT のダンプ    | 可     | 不可       |
| SAVE のダンプ    | 可     | 不可       |
| 個人証明書の置換 | 不可   | 可         |
| NCA の展開       | 可     | 可         |
| BAN の危険性     | 無     | 有         |

### PC レス

HACGUI は Windows で動作するツールですので、パソコンが必ず必要になります。

それに対して NxDumpTool は CFW が動作するスイッチ上で動作するプログラムですので、パソコンは不要です。

### CFW レス

HACGUI は一度 prod.keys を抜き出してしまえばどんなシステムファームウェアからでもデータを抜き出せます。

なので初回起動以後にシステムアップデートで使えなくなったりすることはありません。ただ、最初のキーを抜き出すところで Lockpick が必要になるので、初回起動時にニンテンドースイッチが Lockpick が対応していないバージョンだと、使えないことには注意しなければなりません。

NxDumpTool は Homebrew アプリですので CFW が動作しないと使うことができないのは当然です。

### BCAT のダンプ

BCAT とは Background Content Asymmetric synchronized delivery and Transmission のことであり、バックグラウンドでダウンロードされる軽量のコンテンツだと思っていただければ大体合っているかと思います。

これに該当するのがスプラトゥーンのフェス情報やフェスのモデル・マップデータや、ガチマッチやナワバリバトル、サーモンランのシフトのデータなどです。

一度に一ヶ月分くらい送信されるので、これを取得することで将来のシフトがわかるというわけです。

HACGUI はこの BCAT の抽出に対応していますが、NxDumpTool は対応していません。

### SAVE のタンプ

JKSV というアプリがある以上、HACGUI でセーブデータを保存することのメリットはあまりないのですが、HACGUI はセーブデータバックアップにも対応しています。

JKSV が対応していない ACNH（あつまれどうぶつの森）などにも対応してると思います、多分。

### 個人証明書の置換

個人鍵というのは Personalized Ticket のことで、eShop からダウンロードしたコンテンツに施されている署名の一つです。

この個人鍵は本体の NAND と結びついているので、仮に自分が SYSNAND でダウンロード・ダンプした NSP であっても EMUNAND にインストールすると起動時にチェック（2155-8007 エラー）で弾かれてしまう場合があります。

EMUNAND と SYSNAND の個別情報（本体の初期化ごとにリセットされる）が異なると起動できなくなります。

この認証システムは NSP が署名されているか（Ticket を含むかどうか）とは無関係なので注意。

これを回避するためにには Personalized Ticket を Common Ticket に書き換える必要があるのですが、これは NxDumpTool では `Remove console specific data` という機能でこれに対応しています。

対して、HACGUI では Ticket の書き換え機能が存在しないので、例えば SYSNAND（OFW 環境）で eShop から正規にダウンロードしたスプラトゥーンの体験版を HACGUI で NSP 化し、それを EMUNAND にインストールして遊ぶことは不可能です。

> ちなみにこの機能自体は実装可能であるものの「海賊行為を助長する恐れがある」との判断で Shadow 氏は実装しなかったそうです。

### NCA の展開

HACGUI はゲームデータを NSP または NCA または展開したファイル（Extract partitions）として出力することができ、NxDumpTool も同様に NCA 内のファイルを復号して SD カード上に出力することができます。

この点はどちらのツールにも差異はないといって良いでしょう。

### BAN の危険性

HACGUI はニンテンドースイッチのブートローダ以前の領域で鍵取得をおこない、一度鍵を抽出したあとは RCM 状態のスイッチないしは SD カードをパソコンに接続するだけでゲームデータのダンプがおこなえるので BAN の危険性とは皆無です（もちろん、NSP を証明書なしでダンプしてインストールし、オンラインに繋いだりしたら BAN されますが、それは HACGUI とはまた別の問題）。

それに対して NxDumpTool は CFW で動作させなければならないという仕様上、少なからず BAN の可能性がつきまといます。もちろん適切に CFW を運用していれば良いですが、[90DNS の設定](https://tkgstrator.work/?p=27136#90DNS)が外れていたりすると非常にキケンです。

特に、体験版のデータを抜き出すために SYSNAND で NxDumpTool を起動する際は最新の注意が必要となるでしょう。

## HACGUI の使い方

スイッチを改造できる環境があるのであれば特別な物理的なデバイスは不要です。

### 必要なもの

- [HACGUI](https://cdn.discordapp.com/attachments/432400335235973120/642844112613015564/HACGUI.zip)

GitHub に公開されているものは最新のビルドではないので、Shadow 氏が個別にビルドしたものを使います。

- [Dokan_x64.msi](https://github.com/dokan-dev/dokany/releases)

BCAT のデータをマウントする際に必要になりますが、ゲームのデータおよびアップデータを NSP 化するだけなら不要です。

### ニンテンドースイッチから鍵を抜き出す

![](https://pbs.twimg.com/media/EaG1mWWWAAUfoXW?format=jpg&name=large)

最初に、ニンテンドースイッチから固有鍵（Prod.keys）を抜き出す必要があります。ダウンロードした HACGUI を展開し、HACGUI.exe を右クリックで管理者権限で起動してください。

![](https://pbs.twimg.com/media/EaG1wO-XYAInPEa?format=jpg&name=medium)

何も考えずに Start をクリックします。

![](https://pbs.twimg.com/media/EaG1yWgXQAcetEx?format=jpg&name=medium)

コンソール名の入力を促されますが、何を入力しても大丈夫です。

![](https://pbs.twimg.com/media/EaG11n9XsAgHucg?format=jpg&name=medium)

ここからの手順は全部で四つです。

1. スイッチを RCM にし、パソコンと接続する
2. Send Lockpick をクリックする
3. スクリーンに表示される指示に従う（必要なら再起動がかかる）
4. スイッチを再び RCM で起動し、Mount SD をクリックする

![](https://pbs.twimg.com/media/EaG2JA6X0AEAH7X?format=jpg&name=medium)

RCM のスイッチを接続したところ

RCM のスイッチを接続するとこのように Send Lockpick などのボタンがクリック可能になります。このとき、TegraRcm GUI の Auto inject (selected payload)のチェックが入っていると、Lockpick を挿入するよりも前に Hekate ないしは CFW が起動してしまうのでチェックはオフにしておくなどしておきましょう。

![](https://pbs.twimg.com/media/EaPBeJ6WoAQ6N9s?format=png&name=medium)

Lockpick_RCM を起動したところ

基本的には SysNAND からデータを抜きだしたい場合が多いと思うので「Dump from SysNAND」を選択しましょう。

![](https://pbs.twimg.com/media/EaPBd8FXkAE8KYM?format=png&name=medium)

再起動後に各種キーを抽出

ある程度新しい CFW を使っている場合は sept を採用しているので再起動後にキーを抽出してくれると思います。非常に高速なので 10 秒もあれば完了します。

> 最新の CFW は mesosphere を利用しているので sept は使われていない

終わったらメインメニューに戻り、「Reboot RCM」でニンテンドースイッチを RCM で再起動しましょう。

つぎに Mount SD を選択して SD カードを PC にマウントします。

![](https://pbs.twimg.com/media/EaG25y_X0AA-enY?format=png&name=large)

マウントしたら「...」を選択し、SD カード直下の switch フォルダ内の prod.keys を選択しましょう。

選択すれば自動で prod.keys をコピーしてくれます。

このとき、ニンテンドースイッチには memloader を読み込んだ状態になっており、RCM ではない特別な状態になっているので電源ボタン長押しで強制電源オフをかけて、RCM ジグを使って再び RCM に切り替えます。

そこで Next をクリックすると以下のような画面が表示されます。

![](https://pbs.twimg.com/media/EaG3GCzXkAAlXmL?format=jpg&name=medium)

「Select file(s)」はダンプした NAND から鍵を抽出するモードですが、NAND のバックアップを PC にコピーすると 30GB も消費するのでわざわざこちらのモードを選択しなくて良いと思います。

ここで抜き出す鍵はさっき Lockpick で抜き出したものとはまた異なるので注意！

なので再び memloader を使って今度はニンテンドースイッチの NAND をマウントし、鍵を抜き出そうと思います。

![](https://pbs.twimg.com/media/EaG3KBHXgAIu-WQ?format=jpg&name=medium)

Inject for me を選択したところ

![](https://pbs.twimg.com/media/EaPFmIwWkAEHVPL?format=png&name=large)

五秒くらい待つと鍵の抽出に成功します。たまに失敗するようなので、そのときは最初から再チャレンジしてみてください。

![](https://pbs.twimg.com/media/EaG3S4OXsAEuK8T?format=jpg&name=large)

鍵の抽出に成功！

再度 HACGUI を管理者権限で起動すると SD カードおよび NAND に保存されているゲームデータが表示されます。

![](https://pbs.twimg.com/media/EaG3ht1XgAM6z-F?format=jpg&name=medium)

ゲームデータの表示に成功！

![](https://pbs.twimg.com/media/EaG3oj6XQAAM5uH?format=png&name=medium)

セーブデータの項目をみるといろいろ見れますが、こっちに関してはあまりいじらない方が良いでしょう。

### ゲームデータのバックアップ

今回は SD カードにインストールされているスプラトゥーン 2 の 5.2.0 のアップデータを抽出しようと思います。’

![](https://pbs.twimg.com/media/EaPJ1U7XQAAreuz?format=jpg&name=medium)

インストールされているバージョンが 5.2.0 であることがわかるね。

![](https://pbs.twimg.com/media/EaG4JwuXkAEfqJ9?format=jpg&name=medium)

Title Manager からダンプしたいゲームをダブルクリックするとサブウィンドウがひらきます。

![](https://pbs.twimg.com/media/EaG4bMaXQAETfrF?format=jpg&name=medium)

Titles から Extract を選択し、今回はアップデータをダンプしたいので Patch にチェックを入れます。

こうすることでアップデートパッチをダンプすることができます。

Extractor Picker は Repack as NSP（NSP としてリパック）を選択しておくと使い勝手が良くていいと思います。

![](https://pbs.twimg.com/media/EaG4q-LWAAAjIRI?format=jpg&name=medium)

ここはパソコンのスペックや SD カードの転送速度にも依りますが十分くらいでアップデータが抽出できると思います。

### BCAT データのダンプ

![](https://pbs.twimg.com/media/EaG4JwuXkAEfqJ9?format=jpg&name=medium)

Saves にある SaveData とは別の BcatDeliveryCacheStorage が BCAT データです。これは直接抽出することができず、ファイルシステムをマウントする必要があります。

これには一番最初に説明した dokan のドライバーが必要になるのでインストールしておきましょう。

ここまでできればあとは簡単だと思うので詳細は省略しておきます。
