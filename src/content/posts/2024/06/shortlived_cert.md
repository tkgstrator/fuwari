---
title: CloudflareのShortLived Certが便利だった件
published: 2024-06-25
description: SSHでつなぐ時にいちいち公開鍵を交換するのがめんどくさいよねっていう 
category: Tech
tags: [Cloudflare, SSH]
---

## [Short-lived certificates](https://one.dash.cloudflare.com/)

Short-lived certificatesは短時間だけ有効な証明書を発行するシステムです。

本来、SSHでホストからクライアントに接続するためにはクライアント側の`authorized_keys`にホストの秘密鍵に対応する公開鍵を登録する必要がありました。

で、ここで困るのは初期状態ではホストからクライアントに公開鍵方式で接続する方法がないので、なんとかしてクライアントに繋いでからホストの公開鍵を登録する必要があります。

公開鍵方式が使えないならパスワード認証をするしかないのですが、それはそれで短期間とはいえパスワード認証が有効化されてしまっているのはセキュリティ上の懸念があります。

また、ホストの公開鍵をどうやってクライアントに伝えるのかという問題もあります。

一応`copy-ssh-id`というコマンドはあるのですがこれはGNU/UNIX向けのパッケージなのでWindowsやmacOSでは利用できません。

となると、クライアントにログインするのもSSH公開鍵をコピーするのもめんどくさいわけです。

自分だけがログインするならともかく、多くの人がそのサーバーを利用するのであればいちいち登録するのもめんどくさいわけですね。

そしてそれを解消するのがShort-lived certificatesです。

### クライアント側の設定

詳しくは[公式ドキュメント](https://developers.cloudflare.com/cloudflare-one/identity/users/short-lived-certificates)に書いてあるのでドキュメントを読みます。

これを読むとサーバーをCloudflare Accessの裏側におくことによりセキュアにする仕組みのようです。

まあこれだけでは何のことかわからんので実際にやってみましょう。

なお、ここからの作業はクライアント側のPCで実行する必要があります。

まず、Zero Trustのダッシュボードから新しくTunnelを貼ります。

```yaml
services:
  cloudflare_tunnel:
    restart: always
    image: cloudflare/cloudflared
    command: tunnel --autoupdate-freq 12h run
    environment:
      TUNNEL_TOKEN: $TUNNEL_TOKEN
      NO_AUTOUPDATE: false
    extra_hosts:
      - host.docker.internal:host-gateway
```

自分はDockerでしかCloudflaredを立てないので、上のような`docker-compose.yaml`を作成して`docker compose up -d`で立ち上げます。

### Applications

次に**Access > Applications**からアプリケーションを作成します。

ここではSSHでログインを許可するロールを設定します。

設定したら適当な名前で保存します。

### Service Auth

次に**Access > Service Auth > SSH**から公開鍵を作成します。

Service AuthenticationからSSHを指定し、Applicationから先ほど作成したアプリケーションを選択します。

ここからGenerate certificateを選択して公開鍵を作成します。

### ca.pub

`/etc/ssh/ca.pub`を作成します。

Ubuntuなどであれば`sudoedit`が利用できるので、これを使って編集するとreadonlyなファイルであっても編集できて便利です。

`sudoedit /etc/ssh/ca.pub`で先ほど作成した公開鍵の内容をコピペして保存します。

### SSHD config

最後に`/etc/ssh/sshd_config`を編集します。

```
PubkeyAuthentication yes
TrustedUserCAKeys /etc/ssh/ca.pub
```

のように`PubkeyAuthentication yes`の行のコメントアウトを外します。

### 再起動

Debian/Ubuntuであれば`sudo service ssh restart`でSSHサーバーを再起動できます。

## ホスト側の設定

最後にホスト側の設定をします。

Cloudflare Tunnelを利用しているので、ホスト側にもCloudflaredがインストールされている必要があります。

`cloudflared access ssh-config --hostname vm.example.com --short-lived-cert`のコマンドを実行するとテンプレートが出力されるので、それを`~/.ssh/config`に保存します。

このとき表示されるコマンドでは**User**が指定されておらず、そのまま実行すると現在ログインしているユーザーでログインを試みてしまうので適時`User XXXXXX`の項目を設定するようにしましょう。

これで設定は完了です。

クライアント側の設定が終わってしまえば、ホスト側から秘密鍵を交換する必要がないというのがShort-lived certificatesのメリットですね。

## 感想

最近、記事が書けていなかったのですが久しぶりに書いてみると面白かったです。

Cloudflareにはまだまだ利用できていない機能がたくさんあるので、いろいろ使えるようになっていきたいですね。

記事は以上。
