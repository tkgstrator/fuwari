---
title: "Frida Playgroundで実践練習をする #01"
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

### 1.01 Print parameter(int)

ボタンを押すとトリガーとなって秘密の値が整数値で保存されるので、その値を覗き見しましょうという問題。

Hopper Disassemblerで静的解析をするとメソッド名が`-[VulnerableVault setSecretInt:]`とわかりました。

わかったのでこのメソッドをHookするコードをfrida-traceで生成します。

```zsh
frida-trace -Uf eu.nviso.fridaplayground -m "-[VulnerableVault setSecretInt:]"
```

生成されたコードを編集して、

```ts
onEnter(log, args, state) {
  log(`-[VulnerableVault setSecretInt:${args[2]}]`);
}
```

とすると、

```zsh
  2735 ms  -[VulnerableVault setSecretInt:0x2a]
  5580 ms  -[VulnerableVault setSecretInt:0x2a]
  5862 ms  -[VulnerableVault setSecretInt:0x2a]
```

実行されるたびに`0x2a`が指定されているのがわかります。よって答えは`42`となります。

### 1.02 Print parameter(NSNumber)

```zsh
frida-trace -Uf eu.nviso.fridaplayground -m "-[VulnerableVault setSecretNumber:]"
```

を実行してみます。

そして単純に先程と同じように`args[2]`の中身を覗いてみると、

```zsh
4128 ms  -[VulnerableVault setSecretNumber:0xb4982075a0073cf5]
6770 ms  -[VulnerableVault setSecretNumber:0xb4982075a0073cf5]
6953 ms  -[VulnerableVault setSecretNumber:0xb4982075a0073cf5]
```

実行ごとに同じ値が出力されるのは先程と同じですが、やけに値が大きいです。

更に、再度起動して実行してみると、

```zsh
  2818 ms  -[VulnerableVault setSecretNumber:0x9014183a86167f29]
  3614 ms  -[VulnerableVault setSecretNumber:0x9014183a86167f29]
  3833 ms  -[VulnerableVault setSecretNumber:0x9014183a86167f29]
```

というように値が変わってしまいました。

これは、値ではなくポインタと考えるべきでしょう。今回はNSNumberが入っているとわかっているので、ドキュメントを見てみます。

[NSNumber](https://developer.apple.com/documentation/foundation/nsnumber)の資料を見るとNSNumberは`An object wrapper for primitive scalar numeric values`とあるのでオブジェクトであることがわかります。

先頭にNSとついているのは全てObjective-Cなので、

```ts
onEnter(log, args, state) {
  log(`-[VulnerableVault setSecretNumber:${new ObjC.Object(args[2])}]`);
}
```

としてObjective-Cのオブジェクトにキャストしてみます。

```zsh
  3031 ms  -[VulnerableVault setSecretNumber:42]
  3697 ms  -[VulnerableVault setSecretNumber:42]
  3979 ms  -[VulnerableVault setSecretNumber:42]
```

すると答えが`42`であることがわかりました。

### 1.03 Print parameter(NSString)

```zsh
frida-trace -Uf eu.nviso.fridaplayground -m "-[VulnerableVault setSecretString:]"
```

として今度は文字列を表示させてみます。

```ts
onEnter(log, args, state) {
  log(`-[VulnerableVault setSecretString:${args[2]}]`);
}
```

すると今度は以前の二つと違って押すたびに値が変わってしまいました。

```zsh
  5332 ms  -[VulnerableVault setSecretString:0x28327bfc0]
  6037 ms  -[VulnerableVault setSecretString:0x28320d740]
  6250 ms  -[VulnerableVault setSecretString:0x283202010]
```

なぜポインタが変わったのかは謎なのですが、とりあえずNSStringもObjective-Cのオブジェクトなので、

```ts
onEnter(log, args, state) {
  log(`-[VulnerableVault setSecretString:${new ObjC.Object(args[2])}]`);
}
```

としてみます。

```zsh
  2835 ms  -[VulnerableVault setSecretString:The Answer to Life, The Universe, And Everything]
  5466 ms  -[VulnerableVault setSecretString:The Answer to Life, The Universe, And Everything]
  5651 ms  -[VulnerableVault setSecretString:The Answer to Life, The Universe, And Everything]
```

すると答えは`The Answer to Life, The Universe, And Everything`とわかりました。

### 1.04 Replace parameter

次はボタンを押すと`winIfTrue`というメソッドに常にFalseが返されているものをTrueを返すようにするという問題です。

で、ここまで使ってきたfrida-traceではメソッドの流れを追えるだけで関数の返り値を返すような機能はついていません。

そこで次は別のアプローチを取ります。というか、これまでの三問もその解き方をすることが可能でした。

```ts
const VulnerableVault = ObjC.classes.VulnerableVault; 

function solve104() {
    const method = VulnerableVault['- winIfTrue:'];
    Interceptor.attach(method.implementation, {
        onEnter: function (args) {
            console.log(args[2])
        },
    })
}
```

試しにこのようなコードを書いて、`scripts/vulnerable.js`とします。

これの実行方法は、

```zsh
$ frida -l scripts/vulnerable.js -Uf eu.nviso.fridaplayground
     ____
    / _  |   Frida 16.1.7 - A world-class dynamic instrumentation toolkit
   | (_| |
    > _  |   Commands:
   /_/ |_|       help      -> Displays the help system
   . . . .       object?   -> Display information about 'object'
   . . . .       exit/quit -> Exit
   . . . .
   . . . .   More info at https://frida.re/docs/home/
   . . . .
   . . . .   Connected to iPhone (id=480a9329aa853b4346fd87728802db31d653b0aa)
Spawned `eu.nviso.fridaplayground`. Resuming main thread!               
[iPhone::eu.nviso.fridaplayground ]-> solve104()
```

で、起動したら実行したい関数を実行します。

その後、ボタンを押してみると、

```zsh
0x0
0x0
0x0
```

と表示されました。つまり、メソッドの引数として常にFalseが渡されています。

ここに0x1を入れればいいのですが、どうすれば良いでしょうか？

#### 0x1を代入する

```ts
function solve104() {
    const method = VulnerableVault['- winIfTrue:'];
    Interceptor.attach(method.implementation, {
        onEnter: function (args) {
            args[2] = 1;
        },
    })
}
```

これは上手くいきません。`Error: expected a pointer`というエラーが表示されます。

#### trueを代入する

```ts
function solve104() {
    const method = VulnerableVault['- winIfTrue:'];
    Interceptor.attach(method.implementation, {
        onEnter: function (args) {
            args[2] = true;
        },
    })
}
```

これも同様のエラーがでます。`args[2]`はポインタなのでポインタに値を入れることはできません。

そこで`NativePointer`を返す`ptr`を利用します。

```ts
function ptr(value: string | number): NativePointer
Short-hand for new NativePointer(value).
```

文字列または数値が入れられるとのことなので代入してみましょう。

#### ptr(0x1)

```ts
function solve104() {
    const method = VulnerableVault['- winIfTrue:'];
    Interceptor.attach(method.implementation, {
        onEnter: function (args) {
            args[2] = ptr(0x1);
        },
    })
}
```

何故かこれだとランタイムエラーはでないのですが、クリアになりませんでした。

> 理由は検討中

#### ptr('0x1')

```ts
function solve104() {
    const method = VulnerableVault['- winIfTrue:'];
    Interceptor.attach(method.implementation, {
        onEnter: function (args) {
            args[2] = ptr('0x1');
        },
    })
}
```

文字列を入れるとクリアできました。なお、0x0以外の値は何を入れてもTrue扱いなので`0x2`とかでも通ります。

### 1.05 Print return value(string)

今度は返り値の文字列を見ろという問題です。

いろいろ解法はあるのですが、一番簡単なのは静的解析です。

```zsh
                     -[VulnerableVault getSecretString]:
0000000100005e30         adr        x0, #0x100010d08
0000000100005e34         nop
0000000100005e38         ret
```

メソッドを見ると単に0x100010d08の値を返しているだけであることがわかります。

この場合、答えの文字列はバイナリに書き込まれていて単にそのアドレスを返しているだけであると考えるべきでしょう。

となれば、0x100010d08に何が書き込まれているかを見るだけです。

```zsh
                     cfstring_VulnerableVault_g3n3r_t3dStr1ng:
0000000100010d08         dq         0x0000000100024508, 0x00000000000007c8, 0x000000010000d019, 0x000000000000001f ; "VulnerableVault_g3n3r@t3dStr1ng", DATA XREF=-[VulnerableVault getSecretString]
```

とあるので、答えは`VulnerableVault_g3n3r@t3dStr1ng`であることがわかりました。

ただ、これではfridaの練習にならないのでそちらでも対応します。

この関数は引数を取らないのでメソッドの最後の`:`が不要になります。

> というか`:`って引数があるかどうかを意味していたんですね（今更

```zsh
frida-trace -Uf eu.nviso.fridaplayground -m "-[VulnerableVault getSecretString]"
```

として、今回は引数がないので`onEnter`をみても意味がないので`onLeave`を変更します。

```ts
onLeave(log, retval, state) {
  log(`-[VulnerableVault getSecretString] => ${new ObjC.Object(retval)}`);
}
```

静的解析から返り値が[CFString](https://developer.apple.com/documentation/corefoundation/cfstring-rfh)であるとわかっているので、やはり`new ObjC.Object()`でキャストします。

返り値に入ってる`x0`の値をインスタンスにすれば良いので上のコードになるわけですね。

```zsh
  4281 ms  -[VulnerableVault getSecretString] => VulnerableVault_g3n3r@t3dStr1ng
```

こうして、同じ結果が得られました。

### 1.06 Replace return value

メソッドが常にFalseを返すのでTrueを返すようにしなさいという問題です。

```zsh
                     -[VulnerableVault hasWon]:
0000000100005d4c         mov        w0, #0x0
0000000100005d50         ret
```

このメソッドは常に0を返すだけです。

引数がないのでやはり`onEnter`を弄る意味はなく、返り値を変更するので`onLeave`を調整します。

#### ptr('0x1')

```ts
function solve106() {
    const method = VulnerableVault['- hasWon'];
    Interceptor.attach(method.implementation, {
        onLeave: function (retval) {
            retval = ptr('0x1');
        }
    })
}
```

さっきと同じように書き換えればよいかと思うのですが、これは正しく動きません。

#### ptr(0x1)

```ts
function solve106() {
    const method = VulnerableVault['- hasWon'];
    Interceptor.attach(method.implementation, {
        onLeave: function (retval) {
            retval = ptr(0x1);
        }
    })
}
```

こちらも同様です。

#### replace(ptr(0x1))

```ts
function solve106() {
    const method = VulnerableVault['- hasWon'];
    Interceptor.attach(method.implementation, {
        onLeave: function (retval) {
            retval.replace(ptr(0x1));
        }
    })
}
```

失敗します。

#### replace(ptr('0x1'))

```ts
function solve106() {
    const method = VulnerableVault['- hasWon'];
    Interceptor.attach(method.implementation, {
        onLeave: function (retval) {
            retval.replace(ptr('0x1'));
        }
    })
}
```

これで正常に返り値を変更できます。

#### 別解について

静的解析から単に0x1を返せばよいのはすぐに分かるので、

```zsh
00005d4c 20008052
```

とおきかえるようなコードが書けたらいいと思うのですが、そういうのはできないんでしたっけ？

### 1.07 Print return value(bytearray)

次はBytearrayを表示せよとの問題です。

BytearrayとはSwiftでいうところの`[UInt8]`で、暗号化のときなどによく出てきます。アプリ解析において暗号化は避けて通れない道なのでしっかりと勉強します。

まずは静的解析でコードを読んでみます。

```zsh
                     -[VulnerableVault getSecretKey]:
0000000100005ee8         sub        sp, sp, #0x30defined at 0x10000c8f4 (instance method), DATA XREF=0x10000c8f4
0000000100005eec         stp        fp, lr, [sp, #0x20]
0000000100005ef0         add        fp, sp, #0x20
0000000100005ef4         nop
0000000100005ef8         ldr        x8, =___stack_chk_guard
0000000100005efc         ldr        x8, [x8]
0000000100005f00         stur       x8, [fp, var_8]
0000000100005f04         adr        x8, #0x10000ca78                            ; "$3cr3T8yt34rr4yGsjeb"
0000000100005f08         nop
0000000100005f0c         ldr        x9, [x8]
0000000100005f10         str        x9, [sp, #0x20 + var_18]
0000000100005f14         ldur       x8, [x8, #0x7]
0000000100005f18         stur       x8, [sp, #0x20 + var_11]
0000000100005f1c         nop
0000000100005f20         ldr        x0, =_OBJC_CLASS_$_NSData
0000000100005f24         nop
0000000100005f28         ldr        x1, =aDatawithbytesl
0000000100005f2c         add        x2, sp, #0x8
0000000100005f30         mov        w3, #0xf
0000000100005f34         bl         imp___stubs__objc_msgSend
0000000100005f38         mov        fp, fp
0000000100005f3c         bl         imp___stubs__objc_retainAutoreleasedReturnValue
0000000100005f40         ldur       x8, [fp, var_8]
0000000100005f44         nop
0000000100005f48         ldr        x9, =___stack_chk_guard
0000000100005f4c         ldr        x9, [x9]
0000000100005f50         cmp        x9, x8
0000000100005f54         b.ne       loc_100005f64
0000000100005f58         ldp        fp, lr, [sp, #0x20]
0000000100005f5c         add        sp, sp, #0x30
0000000100005f60         b          imp___stubs__objc_autoreleaseReturnValue
```

よくわからない感じですが、答えは`$3cr3T8yt34rr4yGsjeb`とわかります。

どこにもリターンがなくて変な感じがするのですが、このメソッド自体は指定されたポインタにバッファのポインタか何かを書き込むだけで何も返さないのだともいます。

だからよくわからない`imp___stubs__objc_autoreleaseReturnValue`もvoidのreturnみたいなものなんじゃないかと思っておきます。

こちらも引数がないので`onEnter`をhookする方法は使えません。

```ts
onLeave(log, retval, state) {
  const object = new ObjC.Object(retval);
  log(`-[VulnerableVault getSecretKey] => ${object}`);
  log(`-[VulnerableVault getSecretKey] => ${object.bytes()}`);
  log(`-[VulnerableVault getSecretKey] => ${object.bytes().readUtf8String(object.length())}`);
}
```

のように書いてみます。

```zsh
  9572 ms  -[VulnerableVault getSecretKey]
  9572 ms  -[VulnerableVault getSecretKey] => {length = 15, bytes = 0x243363723354387974333472723479}
  9572 ms  -[VulnerableVault getSecretKey] => 0x281310530
  9572 ms  -[VulnerableVault getSecretKey] => $3cr3T8yt34rr4y
```

すると、静的解析から得られた結果と同じ`$3cr3T8yt34rr4y`が得られました。

### 1.08 Call function on object

`getSelf`というメソッドを呼ぶと自分自身が返るのでVulnerableの`win()`を呼べば良いということになります。

```ts
function solve108() {
    const method = VulnerableVault['- getself'];
    Interceptor.attach(method.implementation, {
        onLeave: function (retval) {
            const object = new ObjC.Object(retval);
            object.win();
        }
    })
}
```

というわけで特に面白くもないコードになりました。

### 1.09 Call function with arguments on object

1.08と似た感じなのですが、`winIfFrida:and27042`を呼べとあります。

これは引数が"Frida", 27042のときに成功するメソッドなので`getself`で自身を取得したときにこのメソッドを呼びます。

```ts
function solve109() {
    const method = VulnerableVault['- getself'];
    Interceptor.attach(method.implementation, {
        onLeave: function (retval) {
            const object = new ObjC.Object(retval);
            object.winIfFrida_and27042_("Frida", 27042);
        }
    })
}
```

`:`は`_`に置き換えられるらしい。なぜそうなるのかはよくわからない。

### 1.10 Find HiddenVault instance

```ts
function solve110() {
    const method = VulnerableVault['- doNothing'];
    Interceptor.attach(method.implementation, {
        onEnter: function (args) {
            const HiddenVault = ObjC.classes.HiddenVault;
            const object = ObjC.chooseSync(HiddenVault)[0]; 
            object.win();
        },
    })
}
```

メソッドの中で無関係のインスタンスを呼ぶこともできます。

VulnerableVaultインスタンスから`doNothing`が呼ばれたときに`HiddenVault`のインスタンスを取得する感じです。

ただ、なんでこんなコードになるのかは読んでいてもよく分からなかったです。最初のインスタンスを取ってくるのがこの感じなのかなという感じ。

ちなみに`object["- win"]();`としても正しい結果が得られます。

### 1.11 Call secret function of HiddenVault 

1.10と似た感じですが`HiddenVault`の隠されたメソッドを呼べとあります。

静的解析をすると`-[HiddenVault super_secret_function]`というのがあるのでこれのことでしょう。

1.09と同じようにインスタンスがあるんだから直接呼んでしまえばいいやと思えば反応しませんでした。

#### super_secret_function

```ts
function solve111() {
    const method = VulnerableVault['- doNothing'];
    Interceptor.attach(method.implementation, {
        onEnter: function (args) {
            const HiddenVault = ObjC.classes.HiddenVault;
            const object = ObjC.chooseSync(HiddenVault)[0]; 
            object.super_secret_function();
        },
    })
}
```

#### ["- HiddenVault super_secret_function"]

こちらだと動きます。何故なんでしょうか。

```ts
function solve111() {
    const method = VulnerableVault['- doNothing'];
    Interceptor.attach(method.implementation, {
        onEnter: function (args) {
            const HiddenVault = ObjC.classes.HiddenVault;
            const object = ObjC.chooseSync(HiddenVault)[0];
            object["- super_secret_function"]();
        },
    })
}
```

> 関数名にアンダーバーがついていると`:`を置換したときの`_`と区別がつかないからなのではないかと思い始めてきました。

こちらの方法で呼ぶ方が確実そうな気がします。

### 1.12 Modify ByteArray

ByteArrayで返ってくる値のうち42より大きい値を42にして返せとあります。

```ts
function solve112() {
    const method = VulnerableVault['- generateNumbers'];
    Interceptor.attach(method.implementation, {
        onLeave: function (retval) {
            const object = new ObjC.Object(retval);
        }
    })
}
```

これでオブジェクト自体は取ってこれるのですが、中身の値を入れ替えようとするとobjectの中身をすべて見ておきかえる必要があります。

#### 配列の長さの取得

```ts
// TypeError: not a function
object.length();
```

とでて中身が取得できません。というのもこのオブジェクトはただの配列だからです。Objective-Cには`length`というメソッドがないので取ってこれません。

1.07で`length()`で取ってこれたのはByteArrayだったからです。今回のは`NSMutableArray`なのでそのメソッドがないというわけです。

#### [NSMutableArray](https://developer.apple.com/documentation/foundation/nsmutablearray)

NSMutableArrayはArrayの継承クラスなので`count`などが使えます。

よって`object.count()`を使いましょう。

#### 配列の中身

`object[i]`のような感じでインデックスを使ってアクセスしたくなりますがこのコード自体はJavascriptのものなのでデータが取れません。やっても`undefined`が返ってくるだけです。

配列の中身を参照したければ`object[- objectAtIndex:](i)`とすればよいです。

```ts
function solve112() {
    const method = VulnerableVault['- generateNumbers'];
    Interceptor.attach(method.implementation, {
        onLeave: function (retval) {
            const object = new ObjC.Object(retval);
            for(let i = 0; i < object.count(); i++) {
                if (object["- objectAtIndex:"](i) >= 42) {
                    object["- setObject:atIndex:"](42, i);
                }
            }
        }
    })
}
```

多分だけれど`forEach`みたいな高級なメソッドは使えないです。

## まとめ

今回はチュートリアルのBasicの12問について簡単に解説しました。

自分も知らないことがあって勉強になりました。

記事は以上。
