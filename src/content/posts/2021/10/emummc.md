---
title: "[決定版] SD PartitionでEmuNANDを導入しよう"
published: 2021-10-01
description: 不用意なBANを避けるためにも改造したSwitchには必ずEmuNANDを導入しましょうという話です
category: Hack
tags: [CFW, EmuMMC, Switch]
---

# EmuNAND とは

ニンテンドースイッチのシステム領域のコピーを SD カードに作成することで、一つのニンテンドースイッチにあたかも二つの同一のスイッチが有るかのように見せかけるシステムのこと。

それ自体には BAN を回避する性能があるわけでもないし、BAN されたときに BAN 解除できるわけでもないのだが、改造用の NAND と通常プレイの NAND を切り分けることによって誤って改造用の NAND でオンラインに繋いでしまうというミスを確実に防ぐことができます。

#### SD File

NAND のバックアップをファイルとして SD カードに保存する方法です。

SD カードのフォーマットは不要なので簡単に実装できます。

ファイルとして保存してあるので、（気にはならないレベルであるが）動作が少し遅かったりします。

#### SD Partition

今回紹介する方法がこれで、SD カード内に別のパーティションを作成してそちら側に EmuNAND を実装する方法です。

フォーマットが必要なのでデータは一度全部吹っ飛びますが、高速にデータアクセスができるのでできることならこちらがオススメ。

## 実際にやってみよう！

全然やり方知らなかったので[@is_mp0025 氏の記事](https://allhacking.hatenablog.com/entry/2020/01/12/172007)を参考にさせていただきました。

とってもわかりやすいので多分誰でも導入できるでしょ、これ。

### 必要なもの

必要なものをまとめていきますが、既に持っている場合もあるのでそのときはスルーしてください。

#### Nintendo Switch

未対策版が必要になります。現在発売されているバッテリー容量が改善されたモデル（Mariko）は対策済みですので Hack はできません。

シリアル番号から[対策済みかどうかをチェックできるサイト](https://ismyswitchpatched.com/)があるので是非どうぞ。

#### Micro SD(64GB 以上が必要)

ニンテンドースイッチの NAND は容量が 32GB あるので、最低でも 64GB 以上の SD カードでないと EmuNAND は作成できません。

64GB あれば容量自体は足りるのですが、結構カツカツなので、その倍の 128GB 以上を推奨しています。

個人的には Samsung の Evo Plus モデルを推していますが、SanDisk でも多分大丈夫です。

#### RCM ジグ

ニンテンドースイッチの Hack のためには RCM という特殊なモードに入る必要があるのですが、そのモードに入るときにこのジグがあればめちゃくちゃ簡単に入れます。

値段も安いので買っておいて損はないと思います。

#### [DeepSea](https://github.com/Team-Neptune/DeepSea/releases/tag/v3.2.0)

CFW の導入に必要なものが全部入ったパッケージです。現在最新のものは v3.2.0 ですのでそれを用意しましょう。

#### [TegraRcmGUI](https://github.com/eliboa/TegraRcmGUI/releases)

RCM のニンテンドースイッチにペイロードをインジェクションするための GUI ツールです。

スイッチの改造には必要不可欠ですのでこれも用意しましょう。

#### [TegraExplorer](https://github.com/suchmememanyskill/TegraExplorer/releases)

SD カードを EmuNAND 用にフォーマットしてくれる便利なペイロードです。

## RCM で起動しよう

ニンテンドースイッチを CFW で起動するためには、必ず RCM（リカバリーモード）を経由してペイロードをニンテンドースイッチに送る必要があります。

![](https://pbs.twimg.com/media/EmI8uIIW0AAnRF7?format=jpg&name=large)

まずは電源ボタンを長押しでニンテンドースイッチの電源オプションを表示させます。

![](https://pbs.twimg.com/media/EmI8uaiW0AAw2rp?format=png&name=large)

次に「電源を切る」を選択してニンテンドースイッチの電源を完全にオフにします。

![](https://pbs.twimg.com/media/EmI8v6mXUAACiXF?format=jpg&name=large)

次に、RCM ジグをニンテンドースイッチの右ジョイコンを差し込むところにセットします。

この状態で「電源ボタン」+「ボリューム+ボタン」を同時に押してみましょう。

「ボリューム+ボタン」を押しながら「電源ボタン」を押すと成功しやすい！同時に押そうとすると先に電源ボタンだけ反応してしまって普通に起動してしまう場合があります。

真っ黒い画面のまま何も変化しなければ無事にニンテンドースイッチが RCM で起動しています。この操作は OFW（または電源オフ状態）から CFW への切り替えに毎回必要になるので必ず覚えておきましょう。

ここまでできたら USB-C ケーブルでニンテンドースイッチとパソコンを接続します。

## TegraRcmGUI を起動しよう

![](https://pbs.twimg.com/media/EmI_SrtWMAIYNeW?format=png&name=small)

実行が保護機能によってブロックされる場合がありますが、落ち着いて「詳細情報」を押して「実行する」を選択しましょう。

![](https://pbs.twimg.com/media/EmI_n34X0AAi3uk?format=png&name=small)

初めて TegraRcmGUI を起動した場合は RCM のニンテンドースイッチを認識するためのドライバが入っていないので、ドライバをインストールしましょう。

![](https://pbs.twimg.com/media/EmI_rOLXgAAIney?format=png&name=small)

「Install Driver」と表示されているところをクリックすればドライバのインストーラが起動します。適当に OK を押してインストールを完了させましょう。

今はまだ Auto Inject のチェックは外しておいたほうが良いです。

![](https://pbs.twimg.com/media/EmJANYwXgAI2NWp?format=png&name=small)

もし正しく RCM で起動できていれば「NO RCM」と表示されているところが「RCM O.K」と表示されているはずです。

![](https://pbs.twimg.com/media/EmJBnLCXIAglo3D?format=png&name=small)

この状態まできたら、「Inject payload」の左のフォルダボタンを押してニンテンドースイッチに送り込みたいペイロードを選択します。

![](https://pbs.twimg.com/media/EmJA--IWoAIsqzb?format=png&name=medium)

まずは TegraExplorer をインジェクトしたいので先程ダウンロードした「TegraExplorer.bin」を選択し「Inject payload」をクリックしましょう。

## SD カードのフォーマット

すると、以下のような無機質な画面がスイッチに表示されます。

![](https://pbs.twimg.com/media/FAmftn_VEAA6IY7?format=png&name=large)

音量ボタンで操作して、SD format を選択します。

![](https://pbs.twimg.com/media/FAmfu2_UYAsnH_O?format=png&name=large)

いろいろあるのですが、「Format for EmuMMC setup (FAT32/RAW)」を選択します。

選択したあとで十秒待ってから再び電源ボタンを押せばフォーマットが始まります。

256GB のフォーマットには二分ほどかかりました。

フォーマットが終わった SD カードをパソコンで読み込むと一つしか SD カードを差し込んでいないのに USB ドライブとして二つ認識されると思います。

一方は中身を見ることができません（画像の場合は D ドライブ）が、そちらが EmuNAND 用にフォーマットした領域になります。

空き容量が表示されている方のドライブは今まで通り使えます。

## DeepSea の導入

ダウンロードした DeepSea を解凍してそのまま SD カードにコピーするだけです。

必須ではありませんが、`bootloader/hekate_ipl.ini`を以下のように編集して CFW(SysNAND)を無効化しておくと幸せになれます。

```ini
\[config\]
autoboot=0
autoboot_list=0
bootwait=3
verification=1
backlight=100
autohosoff=0
autonogc=1
updater2p=1

{DeepSea/DeepSea v1.9.4}
{}
{Discord: invite.sdshrekup.com}
{Github: https://github.com/orgs/Team-Neptune/}
{}

{--- Custom Firmware ---}
\[CFW (EMUMMC)\]
emummcforce=1
kip1patch=nosigchk
fss0=atmosphere/fusee-secondary.bin
atmosphere=1
logopath=bootloader/bootlogo.bmp
icon=bootloader/res/icon_payload.bmp
kip1=atmosphere/kips/\*
{}

{--- Stock ---}
\[Stock (SYSNAND)\]
emummc_force_disable=1
fss0=atmosphere/fusee-secondary.bin
stock=1
icon=bootloader/res/icon_switch.bmp
{}
```

## ネットワーク設定の消去

さて、このまま EmuNAND を作成して CFW を起動してしまうと Wi-Fi 設定までコピーされてしまい、CFW を起動した瞬間にインターネットに繋がってしまいます。

これは BAN の危険性が伴うため、まずは OFW からインターネット設定を消去する必要があります。

![](https://pbs.twimg.com/media/EV5i_DdX0AAUivz?format=jpg&name=large)

登録済みのネットワークから選択。

![](https://pbs.twimg.com/media/EV5i_TSXgAYpwiz?format=jpg&name=large)

設定の消去を選択。

![](https://pbs.twimg.com/media/EV5i_myXgAMX-8c?format=jpg&name=large)

消去します。

複数設定されている場合は全て消去しましょう。

![](https://pbs.twimg.com/media/EV5i__kWoAEkFGF?format=jpg&name=large)

ネットワークに繋がらなくなっていたら成功です。

## EmuNAND の作成

先程は TegraRcmGUI から「TegraExplorer.bin」を選択しましたが、今度は「hekate_ctcaer_5.3.4.bin」を選択しましょう。

RCM でないとペイロードをインジェクトできないので、先程と同じように「電源を切る」→「RCM で起動」→「TegraRcmGUI でインジェクト」の手順を踏むこと。

![](https://pbs.twimg.com/media/EmJBnLCXIAglo3D?format=png&name=small)

今後はずっと「hekate_ctcaer_5.3.4.bin」をインジェクトするので「Auto Inject」にチェックを入れてしまうのも良いでしょう。

すると以下のような画面が表示されます。

![](https://pbs.twimg.com/media/EV5QZD4WsAMdjAi?format=png&name=large)

ここから「emuMMC」をタップします。

![](https://pbs.twimg.com/media/EV5Qb-CXQAgDVpu?format=png&name=large)

「Create emuMMC」をタップします。

![](https://pbs.twimg.com/media/EV5QSEUWkAAgppy?format=png&name=large)

今回は SD Partition で EmuMMC を作成するので真ん中の「SD Partition」をタップします。

![](https://pbs.twimg.com/media/EV5QRZ7XYAA5w7d?format=png&name=large)

パーティションがみつかると確認画面がでるので「Continue」をタップします。

![](https://pbs.twimg.com/media/EV5QSfaWkAoSSRv?format=png&name=large)

SD カードの転送速度にも依りますが 10~15 分くらいで EmuMMC のセットアップが終わると思います。

それ以上かかる場合は SD カードの書き込み速度が遅いので別のものを購入したほうが良いかもしれません。

EmuMMC の作成ができたら Close をタップして一つ前の画面に戻ります。

![](https://pbs.twimg.com/media/EV5Qb-CXQAgDVpu?format=png&name=large)

現状はまだ Disabled になっているので「Change emuMMC」をタップします。

![](https://pbs.twimg.com/media/EV5QZVJXkAEWgEx?format=png&name=large)

「SD RAW 1」をタップします。

![](https://pbs.twimg.com/media/EV5QRuPXkAYXPEQ?format=png&name=large)

このような画面が表示されれば EmuMMC の設定は完了です。

## EmuMMC の起動

![](https://pbs.twimg.com/media/EV5QZD4WsAMdjAi?format=png&name=large)

最初の画面に戻って「Launch」をタップしましょう。

![](https://pbs.twimg.com/media/EV5lRD2XQAEdFq2?format=png&name=large)

CFW (EMUMMC)を選択すれば EmuNAND 上の CFW が起動します。

Stock (EMUMMC)は現段階ではまだサポートされていない。あればいいのだけれど...

![](https://pbs.twimg.com/media/EV5mHfrX0AMHNgF?format=jpg&name=large)

システム画面から現在のバージョンの最後に E と書かれていたら EmuNAND で起動しています。

## やっておくと良いこと

ここから先は本題である EmuNAND 導入とは少し話が異なりますが、やっておいたほうが良いことのまとめです。

### 90DNS

90DNS を設定することで、インターネットには繋がるがニンテンドーネットワークに繋がらないという便利な環境をつくることができます。

CFW を導入するのであれば絶対に整えておきたいです。

無線で接続する場合は必ず Manual Setup（手動設定）から行なうこと！！そうでないとパスワードを入力した時点でインターネットに繋がってしまい、FW のアップデート要求などがされてしまいます。

![](https://pbs.twimg.com/media/EV54UScXsAI_RM1?format=jpg&name=large)

無線の場合は必ず手動設定から行なう

優先の場合は接続前に設定の変更が行えるので安全です。

![](https://pbs.twimg.com/media/EV547RxXkAYc4Cl?format=jpg&name=large)

#### 設定方法

![](https://pbs.twimg.com/media/EV54Uf0WsAA9Xef?format=jpg&name=large)

無線の場合は SSID と暗号化方式を正しく設定した上でパスワードを入力します。

![](https://pbs.twimg.com/media/EV54VKrXkAYjpmN?format=jpg&name=large)

|            |                 |
| ---------- | --------------- |
| パラメータ | 値              |
| 優先 DNS   | 207.246.121.77  |
| 代替 DNS   | 163.172.141.219 |
| おまけ     | 045.248.048.062 |

この三つの中から適当に二つ設定すればいいと思います。

### FTPD

デフォルトの Kosmos だと FTP がオフになっているので有効化しておきましょう。

![](https://pbs.twimg.com/media/EV5mHfqWsAELa7A?format=jpg&name=large)

「Kosmos Toolbox」を選択します。

![](https://pbs.twimg.com/media/EV5mHftWsAEPloJ?format=jpg&name=large)

「Background services」を選択します。

![](https://pbs.twimg.com/media/EV5mHfrWsAAGOoC?format=jpg&name=large)

「sys-ftpd-light」を On にすればその時点で有効化されます。

あとは[WinScp](https://winscp.net/eng/download.php)などで接続すれば良いでしょう。

### [AIO-Switch-Updater](https://github.com/HamletDuFromage/aio-switch-updater)

DeepSea が採用している CFW である atmosphere は海賊版対策として証明書がない NSP をインストール出来ないようになっているので、自分でダンプした NSP でさえもチケットが本体に保存されていないとインストールや起動ができません。

なので nosigpatch を導入してこの制限を取っ払う必要があります。

### 本体の初期化

どうもスイッチには初期化するたびに内部固有の ID が設定されるのですが、NAND をコピーするとその値までコピーされてしまいます。

その状態だとプロコンのペアリングがおかしくなったり、EmuNAND を起動したときに SysNAND 側で NSO のアカウント連携がおかしくなることがあります。

具体的にはスプラだとガチマッチはできるのにフレンド全員がずっとオフラインになってしまいます。この状態になると SysNAND 側を本体の初期化する以外に解決する方法がありません。

なので本体の初期化をすることをオススメするのですが、もしもコピーした NAND 側で NSO 連携をしていた場合は EmuNAND を初期化する際に NSO 連携を外すためにインターネット接続を要求されます。

しかし、NSO 連携を外すのはニンテンドーネットワークで行われるため、これは CFW で eShop に接続するのと同じくらいキケンです。一応、スイッチの仕組み上はインターネット接続なしでも初期化しようとすることはできるのですが、EmuNAND 上で実行すると atmosphere がクラッシュしてしまいます。

#### ChoiDujourNX を使った初期化

![](https://pbs.twimg.com/media/EV5v81mWsAUfUeC?format=jpg&name=large)

というわけで、スイッチをオフラインで初期化できる ChoiDujourNX を使いました。

インストールするファームウェアのデータが必要なのであらかじめデータを本体から抽出しておく必要があります。

が、これは結構難しいです。法律的には（恐らく）アウトですが、インターネット上で有志が公開していたりするものを探す方が得策かも...

![](https://pbs.twimg.com/media/EV5v9UlWkAA0nKF?format=jpg&name=large)

![](https://pbs.twimg.com/media/EV5v9sjWsAEXpvk?format=jpg&name=large)

ぼくの場合は nosigpatch を使いたかったので初期化ついでに 9.2.0 にダウングレードすることにしました。

ファームウェアバージョンが 10.X 系だと同一バージョンへのダウングレードは失敗してしまいます。必ず異なるバージョンのファームウェアを使うようにしましょう。

![](https://pbs.twimg.com/media/EV5v-AZWAAUowMr?format=jpg&name=large)

アップデータを読み込んだらファームウェアを選択します。exFAT でない方が安定するとの噂なので「9.2.0」を選択します。

![](https://pbs.twimg.com/media/EV5wAK4XsAAT3F6?format=jpg&name=large)

ここまで読み込めたら「Select firmware」を選択します。

![](https://pbs.twimg.com/media/EV5wAaCXgAE3P_L?format=jpg&name=large)

ここが一番大事で、左にある「System initialize (full factory reset)」をタップします。

![](https://pbs.twimg.com/media/EV5wAq6WoAAVSvq?format=jpg&name=large)

警告がでてきますが、無視して「Destroy it all」をタップ。

あとは「Start installation」を押せばスイッチのダウングレードと初期化が行われます。

#### Goldleaf を使った初期化

推奨はしていないのですが、Goldleaf でも恐らく初期化ができます。

削除するファイルを間違えるとブリックを招きます。非推奨であるということを理解した上で、必ず EMUNAND で実行してください。本体がブリックしても責任は取れません。

![](https://pbs.twimg.com/media/EV5yNvKWkAAt1V2?format=jpg&name=large)

![](https://pbs.twimg.com/media/EV5yN-LWoAMSulK?format=jpg&name=large)

Goldleaf を起動したら「Explore content」を選択します。

![](https://pbs.twimg.com/media/EV5yOnJX0AI1Y-C?format=jpg&name=large)

「Console memory (SYSTEM)」を選択します。

![](https://pbs.twimg.com/media/EV5yO9FXsAAWEfo?format=jpg&name=large)

「save」を選択します。

![](https://pbs.twimg.com/media/EV5yQqZXYAASjtw?format=jpg&name=large)

![](https://pbs.twimg.com/media/EV5yT5IWsAIQM84?format=jpg&name=large)

いくつかファイルがあると思うのですが、A ボタンで選択して削除していきます。

注意点

[GBATEMP の記事](https://gbatemp.net/threads/clear-the-switch-of-any-cfw-things.514331/)によれば削除するのは 8000000000000120 以外のファイルでないとダメだということです。

しかし、実際にはそのようなファイルは存在せず FW のアップデートでファイル名が変わってしまった可能性があります。

ちなみに自分で試してみたところ 80000...と続いたあとに「10004」のように五桁の数字が並んでいるファイル以外を消せば初期化されました。

が、現状「どれが削除してはいけないデータなのか」あるいは「どのデータも削除していいのか」がわかっていないので、システムファイルの削除は EmuNAND のブリックを伴うかもしれないキケンな行為であることを十分認識しておいてください。

## まとめ

@is_mp0025 氏の記事をベースに少し発展させた感じでまとめてみたのですがいかがでしょうか？

SD Partition に切り替えたからといっていまのところは「すっげー動作が早い！！」とは感じていないのですがパーティションが分かれていることでファイルの断片化とかは起こりにくかったりするのかなとかは思ったり思わなかったり。

そのへんはパーティションやファイルシステムについて疎いのでなんともわかりません、詳しい人いたら教えて下さい。
