---
title: GPGキーが吹き飛んだので読み込んだら認証されなくなっちゃった
published: 2024-10-01
description: GPGキーに関する備忘録
category: Tech
tags: [GPG]
---

## 概要

GPGキーを誤って吹き飛ばしたので、バックアップしたものから復旧されることにしました。

```zsh
$ gpg --import private.key
```

のようなコマンドで読み込むことができます。

で、その結果を見ると、

```zsh
$ gpg --list-keys        
[keyboxd]
---------
pub   rsa4096 2024-08-30 [SC]
      1008E76264870ED5722268A7C9DE991D1A522478
uid           [ unknown] tkgstrator <nasawake.am@gmail.com>
sub   rsa4096 2024-08-30 [E]
```

`[unknown]`となっており鍵の所有者の確認ができていないことになっています。

この状態だとコミットに署名してもVerifiedにならないので、鍵を信頼する必要があります。

```zsh
gpg --edit-key 1008E76264870ED5722268A7C9DE991D1A522478
```

で鍵のデータを変更します。

```zsh
$ trust
sec  rsa4096/C9DE991D1A522478
     created: 2024-08-30  expires: never       usage: SC  
     trust: ultimate      validity: ultimate
ssb  rsa4096/73B215945D81D247
     created: 2024-08-30  expires: never       usage: E   
[ultimate] (1). tkgstrator <nasawake.am@gmail.com>

Please decide how far you trust this user to correctly verify other users' keys
(by looking at passports, checking fingerprints from different sources, etc.)

  1 = I don't know or won't say
  2 = I do NOT trust
  3 = I trust marginally
  4 = I trust fully
  5 = I trust ultimately
  m = back to the main menu

Your decision? 
```

とやれば鍵を信頼することができます。今回は全部信頼したいので`5`を選択します。　

```zsh
Your decision? 5
Do you really want to set this key to ultimate trust? (y/N) y

sec  rsa4096/C9DE991D1A522478
     created: 2024-08-30  expires: never       usage: SC  
     trust: ultimate      validity: ultimate
ssb  rsa4096/73B215945D81D247
     created: 2024-08-30  expires: never       usage: E   
[ultimate] (1). tkgstrator <nasawake.am@gmail.com>
```

これで信頼ができたので`save`として保存します。

ここで再度`gpg --list-keys`とすると鍵情報が表示され、

```zsh
$ gpg --list-keys 
gpg: checking the trustdb
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   2  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 2u
[keyboxd]
---------
pub   rsa4096 2024-08-30 [SC]
      1008E76264870ED5722268A7C9DE991D1A522478
uid           [ultimate] tkgstrator <nasawake.am@gmail.com>
sub   rsa4096 2024-08-30 [E]
```

のように信頼されていることがわかります。

反映されていない場合には`gpg --check-trustdb`とやればよいと思います。

記事は以上。　