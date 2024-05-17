---
title: "Frida Playgroundで実践練習をする #02"
published: 2023-11-26
description: Frida Playgroundを使ってアプリの動的解析の実戦経験を積んでみました 
category: Tech
tags: [macOS, iOS, Jailbreak, Frida]
---

## Frida Playground

[Frida ios playground](https://github.com/NVISOsecurity/frida-ios-playground)

から実戦経験が積めます。

[インストール用のIPAも配布](https://github.com/NVISOsecurity/frida-ios-playground/releases/tag/v1.0)されているのでSideloadlyでちゃちゃっとインストールしてしまいましょう。

## Challenges

早速簡単な方から解いていきます。

適当にインストールしたせいでBundle IDがわからないので調べます。

```zsh
$ frida-ps -Ua
 PID  Name                    Identifier              
----  ----------------------  ------------------------
2069  AppStore                com.apple.AppStore      
2060  Nintendo Switch Online  com.nintendo.znca       
3130  Playground              eu.nviso.fridaplayground
2033  Search                  com.apple.Spotlight     
1993  Settings                com.apple.Preferences   
2039  Sileo                   org.coolstar.SileoStore 
2068  palera1nLoader          com.samiiau.loader   
```

というわけで`eu.nviso.fridaplayground`という値であることがわかりました。

### 2.1 Switch implementation (ObjC.implement)

`ObjC.implement`を使ってボタンを押したときに本来呼ばれる`lose()`に代えて`win()`を実行するというものです。

#### Objc.chooseSync

正解手ではないですがいろいろ解法を載せておきます。

```ts
function solve201() {
    const method = VulnerableVault['- lose'];
    Interceptor.attach(method.implementation, {
        onEnter: function (args) {
            const object = ObjC.chooseSync(VulnerableVault)[0];
            object.win();
        },
    })
}
```

#### Vulnerable

`method.implmentation`がそのメソッドの処理を持っているのでメソッドの処理自体を置き換えます。

なのでイメージとしては以下のような感じです。

```ts
function solve201() {
    VulnerableVault['- lose'].implementation = VulnerableVault['- win'].implementation;
}
```

で、実際にこれは正しく動作します。

```ts
function solve201() {
    const method = VulnerableVault['- lose'];
    method.implementation = VulnerableVault['- win'].implementation;
}
```

値渡しではなく参照渡しになっているのでこちらの書き方でも大丈夫です。

#### Objc.implement

正攻法で解きます。

```ts
function solve201() {
    const method = VulnerableVault['- lose'];
    method.implementation = ObjC.implement(method, function (handle, selector) {
        ObjC.Object(handle).win();
    })
}
```

こちらであれば長いコードを書くことができます。

### 2.2 Switch implementation (Interceptor.replace)

使い方がいまいちわからないです。

さっぱりわからないので答えを見ました。

```ts
function solve202() {
    const method = VulnerableVault["- lose"];
    Interceptor.replace(method.implementation, new NativeCallback(function(instance, selector) {
        ObjC.Object(instance).win();
    }, 'void', ['pointer', 'pointer']));
}
```

`NativeCallback`の使い方がいまいち分かりません。特に後半のポインターを指定しているのはなんですかこれ。

### 2.3 Hook exported function

`isSecure`がTrueを返すように変更しろとのこと。

で、Hopper Disassemblerで調べても`isSecure`というメソッドはありません。

調べてみると[isSecure](https://developer.apple.com/documentation/foundation/httpcookie/1393025-issecure)はiOS 2.0から実装されている標準ライブラリらしいです。

メソッドを読み込むには以下のコードを書きます。

```ts
const method = Module.findExportByName(null, "isSecure");
```

このメソッドが実行されたときの処理を書き換えたいので、

```ts
    Interceptor.attach(method.implementation, {
        onEnter: function (args) {
            const object = ObjC.chooseSync(VulnerableVault)[0];
            object.win();
        },
    })
```

## まとめ
