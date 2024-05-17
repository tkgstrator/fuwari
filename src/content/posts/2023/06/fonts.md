---
title: iOSアプリでのフォントの扱い方
published: 2023-06-11
description: フォントのインストールからフォントを利用するまで
category: Programming
tags: [Swift]
---

## フォント

フォントを利用するには、

1. MobileConfig を利用したプロファイル方式
2. Assets.xcassets に埋め込むアセット方式
3. Documents から読み込むドキュメント方式
4. iOS13 以降対応したフォント方式

の四つがあります。

> 呼び方は適当なのでそこは気にしないでください。

### 各方式の比較

それぞれの大雑把な比較は以下のとおりです。

|        | プロファイル |     アセット     |   ドキュメント   |     フォント     |
| :----: | :----------: | :--------------: | :--------------: | :--------------: |
|  権利  |      難      |        難        |        易        |      難/易       |
|  利用  |      -       |        -         |        -         |    iOS13 以降    |
| 拡張子 |   ttf, otf   | ttf, woff, woff2 | ttf, woff, woff2 | ttf, woff, woff2 |

ただし、フォント方式に関しては今回は別のフォントアプリでフォントをインストールするようなことを考えていないので、URL からダウンロードしてきたフォントファイルをフォントとしてインストールして利用することを考えています。

よって、ドキュメント方式とフォント方式は今回の場合は二つで一つということになります。

#### 権利

いちばん大事なのがここで、再配布を禁止していたり商用利用が不可だったりするフォントは多数あります。

プロファイルにしろ、アセットにしろ`.mobileconfig`か`assets.xcassets`に組み込まなければいけないので、これらの方式ではすべてのフォントを自由に配布したりすることはできません。

iOS アプリにフォントを組み込む記事を検索すると日本語でも英語でもほとんどが`assets.xcassets`を利用した方法を紹介していますが、この方法は使えないわけです。

とはいえ、それぞれどのような違いがあるのかを調べてみることにしました。

> プロファイル方式は`ttf`ないしは`otf`しかサポートしていませんが、バンドル方式は`woff`や`woff2`が利用できました。これらは圧縮率が高くてオススメです

## テスト用アプリ

どのフォントが利用できるかは`UIFont.familyNames`を参照すればわかります。

ここに表示されないフォントはどうやってもアプリ内から利用できないので、これでフォントが利用可能になっているかどうかを判断できます。

### ContentView

```swift
struct ContentView: View {
    var body: some View {
        NavigationView(content: {
            List(content: {
                NavigationLink(destination: {
                    FontListPicker()
                }, label: {
                    Text("Font Lists")
                })
            })
        })
    }
}
```

`UIFontPickerViewController`は`SwiftUI`でそのまま利用できないので、`UIViewControllerRepresentable`を利用します。

```swift
struct FontListPicker: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIFontPickerViewController {
        let controller: UIFontPickerViewController = UIFontPickerViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UIFontPickerViewController, context: Context) {
    }

    class Coordinator: NSObject, UIFontPickerViewControllerDelegate {
        private let parent: FontListPicker

        init(_ parent: FontListPicker) {
            self.parent = parent
        }

        func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
            guard let descriptor = viewController.selectedFontDescriptor,
                  let name: String = descriptor.fontAttributes[.family] as? String,
                  let font: UIFont = UIFont(name: name, size: UIFont.systemFontSize)
            else {
                return
            }
            UIApplication.shared.keyWindow?.rootViewController?.dismiss(animated: true)
        }
    }
}
```

これで`FontListPicker`にインストールしたフォントが表示されるようになれば利用可能、ということです。

### Capabilities

フォント方式でインストールしたフォントを利用するには`Capabilities`から`Fonts`を有効化して`Use Installed Fonts`と`Install Fonts`にチェックを入れます。

> Use Installed Fonts にチェックを入れるとバイナリにフォントが同梱されていないと Invalid Binary で AppStore Connect から弾かれるので注意

## プロファイル方式

Apple Configurator を使ってフォントをインストールする方式です。

iOS13 以前ではこれが利用されていたようなので、どうなるのか検証してみます。

導入の方法を書いていると長いので、先駆者の方の記事を載せておきます。

[iOS にフォントをいっぱいインストールしたい](https://qiita.com/YOCKOW/items/0703134a787bffcfe49f)を読めばオリジナルフォントをインストールするのは難しくないと思います。

### 検証

で、この方式でインストールしたフォントは何故かシミュレータだと反映されませんでした。

何故なのかはわかりません。

しかし、実機であれば全くの設定不要でフォントが読み込めます。Info.plist を編集する必要もないですし、何も必要ないです。

`.font(.custom(FAMILY_NAME, size: UIFont.systemFontSize))`みたいなことを書けばそれで終わりです。

|                     | シミュレータ | iPhone/iPad |
| :-----------------: | :----------: | :---------: |
| Use Installed Fonts |     不要     |    不要     |
| フォントの読み込み  |     不可     |     可      |
|    設定画面表示     |     なし     |    なし     |
|     Xcode 設定      |     不要     |    不要     |

つまり、上のような結果になります。

構成プロファイルを作成するのが手間なこと以外はものすごく簡単だと思います。

### 必要なもの

さて、今回のケースだと構成プロファイルを作成するのに何が必要なのでしょうか。

1. [Apple Configurator 2](https://apps.apple.com/jp/app/id1037126344)
2. [FontForge](https://fontforge.org/en-US/downloads/)
3. スプラトゥーン用のフォント

このうちなんと Apple Configurator 2 は Windows 版が提供されていない。つまり、この時点で Windows ユーザーは構成プロファイルを利用したフォントのインストールができないことになります。

とはいえ、構成プロファイルは単純にフォントの Base64 バイナリが XML に貼り付けられているだけなので適当に TS でコードを書けば構成プロファイルを作成するウェブサイトを作成するのは難しくないと思います。それを転送するのがまた手間ですけれど......

マージするフォントは以下の URL から手に入ります。Web で普通に公開されているのでとても楽です。2 用と 3 用がありますが、韓国語と中国語を利用しないのであれば 2 用のフォントで十分です。

```zsh
https://app.splatoon2.nintendo.net/fonts/bundled/ab3ec448c2439eaed33fcf7f31b70b33.woff2
https://app.splatoon2.nintendo.net/fonts/bundled/0e12b13c359d4803021dc4e17cecc311.woff2
https://app.splatoon2.nintendo.net/fonts/bundled/da3c7139972a0e4e47dd8de4cacea984.woff2
https://app.splatoon2.nintendo.net/fonts/bundled/eb82d017016045bf998cade4dac1ec22.woff2
```

四つのファイルはそれぞれスプラ 1 用の日本語と英語、スプラ 2 用の日本語と英語のフォントになっています。

日本語フォントには英語のフォントが全く含まれていないので、これらをマージしてしまえば良いことになります。

で、マージするには FontForge を利用するのが一番楽です。 手順は長いので割愛します。

マージしたフォントを ttf として出力し、構成プロファイルに組み込んでインストールすればフォントを利用することができます。

## アセット方式

何も考えないなら一番楽なのがこれです。

ただし、アプリ自体にフォントをバンドルしなければいけない性質上、権利関係をクリアするのはほぼ不可能です。

配布不可なフォントを利用したい場合にはこの方式は使えません。

|                     | シミュレータ | iPhone/iPad |
| :-----------------: | :----------: | :---------: |
| Use Installed Fonts |     不要     |    不要     |
| フォントの読み込み  |      可      |     可      |
|    設定画面表示     |     なし     |    なし     |
|     Xcode 設定      |     必要     |    必要     |

アセット方式でのカスタムフォント利用方法についてはいろいろ記事があるのですが、パッと目についた[カスタムフォントを使用する方法](https://ios-docs.dev/swiftui-custom-font/)をご紹介しておきます。

> 多分 typo だと思うのでタイトルを修正しておきました

Google Fonts などを利用するのであればこの方法で良いかもしれません。

## ドキュメント方式

ドキュメント方式はアプリが持つ`Documents`以下にフォントのファイルをダウンロードして、そのフォントを読み込むタイプの対応方法です。

ユーザーが勝手にフォントをダウンロードしてくるのでアプリ自体にフォントをバンドルする必要はありません。

|                     | シミュレータ | iPhone/iPad |
| :-----------------: | :----------: | :---------: |
| Use Installed Fonts |     不要     |    不要     |
| フォントの読み込み  |      可      |     可      |
|    設定画面表示     |     あり     |    あり     |
|     Xcode 設定      |     あり     |    あり     |

> アプリ自身がインストールしたフォントを利用する場合は`Use Installed Fonts`は不要だが、`Install Fonts`は必要でプロセスにインストールするだけであれば`Install Fonts`は不要

|                         |            Install Fonts Yes             |               Install Fonts No               |
| :---------------------: | :--------------------------------------: | :------------------------------------------: |
| Use Installed Fonts Yes |                全て利用可                | 他のアプリでインストールしたフォントが利用可 |
| Use Installed Fonts No  | アプリがインストールしたフォントは利用可 |             .process のみ利用可              |

なにやらややこしいのですが、とりあえずどちらもチェックを入れて損はないです。ただし、Install Fonts を Yes にするのであればバイナリに必ずフォントを同梱してください。

この方式ができればめんどくさい構成プロファイルの作成が省略できて楽なのですが、この方式を導入するに当たって難しい点を挙げると、

1. [Core Text Functions](https://developer.apple.com/documentation/coretext/core_text_functions)に関するドキュメントが少ない
2. 起動時にフォントを読み込んで登録する必要がある
   - 他の二つの方式ではアプリ自体及び構成プロファイルがフォントを自動で登録してくれていましたが、本方式ではアプリ起動時に登録する必要があります
   - 多分ですが`AppDelegate`で登録しておけばよいです
3. 同一の FamilyName を持つフォントに対する読み込み方法がわからない
   - 同一の FamilyName を持つフォントを登録しようとすると[`CTFontManagerError.duplicatedName`](https://developer.apple.com/documentation/coretext/ctfontmanagererror/duplicatedname)で普通に怒られます
4. インストールダイアログがでない
   - 本当に謎で、端末リセット直後の一回だけでたけどそれ以後音沙汰がないです
   - 複数同時にインストールしようとするとそうなるのかもしれない
5. FamilyName が異なるフォントがある
   - 後述します

と、ハードルがものすごく高いのですがこの方式ができれば一番楽です。なぜならフォントの URL もそのフォントが持つ FamilyName の情報も全てわかっているからです。

### FamilyName 問題

かなり大きな問題で、スプラトゥーン 1 用の漢字フォントは`ROWDayStd`という FamilyName が設定されているにも関わらず、ひらがなと英語のフォントは`Splatoon1`とうい FamilyName になっているからです。

つまり、単純にフォントが持っている FamilyName で登録してしまうと漢字とひらがなが混在しているテキストに`.font()`を当てると漢字かひらがなのどちらか一方は普通のフォントで表示されてしまうという問題が発生します。これを解決するにはフォントを読み込んだときに FamilyName を変更して登録する必要があるのですが、それをやると[`CTFontManagerError.duplicatedName`](https://developer.apple.com/documentation/coretext/ctfontmanagererror/duplicatedname)で怒られます。

SwiftUI でのフォントの読み込み方法を変えるか`CTFontManager`あたりを上手いことやる必要があると思うのですがいかんせんドキュメントが少なすぎて手探り感が半端ないです。

### ダイアログ問題

何故か端末をリセットした最初の一回だけでます。

`.process`でインストールした場合にはでてこないので、`.persistent`を指定する必要があると思います。

まだ調査不足です。

### フォント関連のメソッド

#### インストール

- `CTFontManagerRegisterFontsForURL(CFURL, CTFontManagerScope, UnsafeMutablePointer<Unmanaged<CFError>?>?) -> Bool`
  - 指定された URL のフォントを指定されたパラメータで登録する
  - `CTFontManagerScope=.process`以外は登録に失敗する
- `CTFontManagerRegisterFontDescriptors(CFArray, CTFontManagerScope, Bool, ((CFArray, Bool) -> Bool)?)`
  - 指定されたフォント一覧を指定されたパラメータで登録する
  - `CTFontManagerScope=.persistent`以外は登録に失敗する
- `CTFontManagerRegisterFontsWithAssetNames(CFArray, CFBungle, CTFontManagerScope, Bool)`
  - 指定されたファミリーネーム一覧を指定されたパラメータで登録する
  - `CTFontManagerScope=.persistent`以外は登録に失敗する

#### アンインストール

- `CTFontManagerUnregisterFontDescriptors(CFArray, CTFontManagerScope, ((CFArray, Bool) -> Bool)?)`
  - 指定されたファミリーネーム一覧を指定されたパラメータで解除する

#### 取得

- `CTFontManagerCopyRegisteredFontDescriptors(CTFontManagerScope, Bool) -> CFArray`
  - 指定されたパラメータで登録されているすべてのフォントを取得して返す
  - フォント一覧取得
- `CTFontDescriptorCopyAttribute(CTFontDescriptor, CFString) -> CFTypeRef?`
  - 指定されたフォントの指定されたパラメータを返す
  - フォントのパラメータ取得

#### その他

- `CTFontManagerSetAutoActivationSetting(CFString?, CTFontManagerAutoActivationSetting)`
  - 指定されたバンドル ID のフォントを自動でアクティベーションする

パッと見ただけだと何がなんだかわからないと思うので解説します。

まず、フォントのインストール・アンインストールに関して二つのパラメータがあります。

それが`scope: CTFontManagerScope`と`enabled: Bool`ですが、これらは何も考えずにそれぞれ`.persistent`と`true`を指定するようにしましょう。特に`enabled=false`を指定するとえらくめんどくさいです。

#### [CTFontManagerScope](https://developer.apple.com/documentation/coretext/ctfontmanagerscope/)

フォントの影響力を表す。

- none
  - スコープなし
- process
  - 現在のプロセスで unregistered が呼ばれるまで有効
  - アプリ終了などでプロセスがキルされるとアンインストールされる
  - 設定のフォントからインストールしたフォントが見れない
  - プロセスキルでアンインストールされる以外は構成プロファイルと似ている
- persistent
  - ユーザーのすべてのプロセスで unregistered が呼ばれるまで有効
  - アプリを終了してもインストール状態が継続
  - 設定のフォントからインストールしたフォントが見れる
- session
  - macOS のみ有効なので今回は考慮しない
- user
  - persistent と同じ

#### Enabled

登録されているフォントのうち有効なものを返すか無効なものを返すかを表す。

`enabled=false`でフォントをインストールすると、設定画面からフォントが表示されず、かといって再度インストールしようとすると`1 files have already been registered in the specified scope.`の[エラー](https://developer.apple.com/documentation/coretext/ctfontmanagererror/alreadyregistered)が返ってくる。

`false`を設定する意味が今のところ見えないので、通常は`true`で良い。

#### [CTFontDescriptor](https://developer.apple.com/documentation/coretext/ctfontdescriptor-ni4)

登録されているフォントの情報は以下の四つ

- CTFontRegistrationUserInfoAttribute
- NSCTFontFileURLAttribute
- NSFontFamilyAttribute
- NSFontNameAttribute

これを FontForge で確認できるフォント情報を見比べてみる。

|                                     |            Splatoon 1            |            Splatoon 2            |
| :---------------------------------: | :------------------------------: | :------------------------------: |
|              Fontname               |        RowdyStd-EB-Kanji         |       KurokaneStd-EB-Kanji       |
|             Family Name             |             FowdyStd             |           KurokaneStd            |
|           Name For Humans           |        RowdyStd-EB-Kanji         |       KurokaneStd-EB-Kanji       |
|        NSFontFamilyAttribute        |         FOT-Rowdy Std EB         |       FOT-Kurokane Std EB        |
|         NSFontNameAttribute         |           RowdyStd-EB            |          KurokaneStd-EB          |
| CTFontRegistrationUserInfoAttribute | ab3ec448c2439eaed33fcf7f31b70b33 | da3c7139972a0e4e47dd8de4cacea984 |
|      NSCTFontFileURLAttribute       |               URL                |               URL                |

すると何故か全然一致しないという謎の状態が発生した。

`CTFontRegistrationUserInfoAttribute`はファイル名なので、これだけを信用したほうが良い気がする。

もしくは、予め Fontname か Family Name がわかっているものでないと利用するのは難しいと思われる。

```swift
/// CTFontRegistrationUserInfoAttribute
CTFontDescriptorCopyAttribute(descriptor, kCTFontRegistrationUserInfoAttribute) as? String
/// NSCTFontFileURLAttribute
CTFontDescriptorCopyAttribute(descriptor, kCTFontURLAttribute) as? String
/// NSFontNameAttribute
CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String
/// NSFontFamilyAttribute
CTFontDescriptorCopyAttribute(descriptor, kCTFontAttributeName) as? String
```

多分上のようなコードで`CTFontDescriptor`からデータが取ってこれるが、最悪辞書なのでゴリ押しでもとれます。

### メソッド詳細

#### CTFontDescriptorCopyAttribute

`CTFontDescriptor`から安全にプロパティを取得するメソッド。使い方は先程解説した通り。

```swift
func CTFontDescriptorCopyAttribute(
    _ descriptor: CTFontDescriptor,
    _ attribute: CFString
) -> CFTypeRef?
```

#### CTFontManagerRegisterFontDescriptors

`[CTFontDescriptor]`を一括でインストールするメソッド。とはいえ`CTFontDescriptor`になっている時点で普通はインストールが完了しているはずなので、ここはまだ使い方がしっかり理解できていないと思われる。

今回のサンプルプログラムでは利用しなかった。

```swift
func CTFontManagerRegisterFontDescriptors(
    _ fontDescriptors: CFArray,
    _ scope: CTFontManagerScope,
    _ enabled: Bool,
    _ registrationHandler: ((CFArray, Bool) -> Bool)?
)
```

#### [CTFontManagerRegisterFontURLs](https://developer.apple.com/documentation/coretext/3227897-ctfontmanagerregisterfonturls)

```swift
func CTFontManagerRegisterFontURLs(
    _ fontURLs: CFArray,
    _ scope: CTFontManagerScope,
    _ enabled: Bool,
    _ registrationHandler: ((CFArray, Bool) -> Bool)?
)
```

フォントの URL を指定して一括でインストールするメソッド。便利なのに非推奨。

`.persistent`と`.process`のどちらでも使えると思われるが、`.persistent`にしたいなら以下の`CTFontManagerRegisterFontsWithAssetNames`を利用するのが無難。

#### [CTFontManagerRegisterFontsWithAssetNames]()

`Assets.xcassets`に登録されているフォントをインストールする。

```swift
func CTFontManagerRegisterFontsWithAssetNames(
    _ fontAssetNames: CFArray,
    _ bundle: CFBundle?,
    _ scope: CTFontManagerScope,
    _ enabled: Bool,
    _ registrationHandler: ((CFArray, Bool) -> Bool)?
)
```

ちょっとわかりにくいので少し解説。

- fontAssetNames
  - インストールしたいフォントのファイル名(拡張子不要)
- bundle
  - 何も考えずに`CFBundleGetMainBundle()`を指定すれば良い。

> CFBundle は NSBundle とは互換性がないようなので`Bundle.main`などは利用できない

Xcode はビルド時にアセットの階層構造が全てなくなるのでバンドルされているファイルを取得して指定されたファイル名のフォントを取ってきているようだ。

> 端末リセット直後の初回インストール時のみダイアログが出現する。

#### [CTFontManagerUnregisterFontDescriptors](https://developer.apple.com/documentation/coretext/3227900-ctfontmanagerunregisterfontdescr/)

フォントマネージャを使ってフォントをアンインストールするメソッド。

```swift
func CTFontManagerUnregisterFontDescriptors(
    _ fontDescriptors: CFArray,
    _ scope: CTFontManagerScope,
    _ registrationHandler: ((CFArray, Bool) -> Bool)?
)
```

ここでアンインストールすべきフォントを正しくとってこないと、全てのフォントが消えます。

```swift
guard let fontDescriptors: [CTFontDescriptor] = CTFontManagerCopyRegisteredFontDescriptors(.persistent, true) as? [CTFontDescriptor]
else {
    return
}
```

のようなコードで登録されているフォントを全て取得してからフィルターをかけてアンインストールすべきフォントを正しく取得しましょう。

> なお、インストールされていないフォントをアンインストールしようとしても特にエラーはでません。

#### [CTFontManagerUnregisterFontURLs](https://developer.apple.com/documentation/coretext/3227901-ctfontmanagerunregisterfonturls)

```swift
func CTFontManagerUnregisterFontURLs(
    _ fontURLs: CFArray,
    _ scope: CTFontManagerScope,
    _ registrationHandler: ((CFArray, Bool) -> Bool)?
)
```

指定された URL のフォントを一括でアンインストールするメソッド。

> インストールされてないフォントをアンインストールしようとするとエラーが返る。

#### [CTFontManagerRegisterFontsForURL](https://developer.apple.com/documentation/coretext/1499468-ctfontmanagerregisterfontsforurl/)

指定された URL のフォントをインストールするメソッド。

```swift
func CTFontManagerRegisterFontsForURL(
    _ fontURL: CFURL,
    _ scope: CTFontManagerScope,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> Bool
```

URL を指定できるということはもちろん`Documents`からフォントをインストールすることもできますが`.process`以外が効きません。

実行した場合のエラーコードも載せておきます。

- `.none`
  - `Someone attempted to (un)register one or more fonts with CTFontManager using scope kCTFontManagerScopeNone.  That's not a valid scope for (un)registration, so we'll use kCTFontManagerProcess instead.  This message will not be logged again.`
- `.persistent`
  - `kCTFontManagerScopePersistent is not supported by this function.  Use API with registrationHandler block parameter.`

ちなみにプロセス実行中しか効かないので、アプリを終了すればフォントは自動的に`unregistered`されます。

よって、起動時に毎回インストールを実行する必要があります。やるなら`AppDelegate`で実行するのが良いかと思われる。

`CTFontManagerSetAutoActivationSetting`を使えば自動でインストールするようにできるかもしれないけれど、まだ未調査です。

#### [CTFontManagerCopyRegisteredFontDescriptors](https://developer.apple.com/documentation/coretext/3227895-ctfontmanagercopyregisteredfontd/)

指定されたスコープでインストールされているフォントを取ってきます。

```swift
func CTFontManagerCopyRegisteredFontDescriptors(
    _ scope: CTFontManagerScope,
    _ enabled: Bool
) -> CFArray
```

返り値は`CFArray`となっていますが、実質的に`[CTFontDescriptor]`と同じです。

### 補足説明

先人の[記事](https://qiita.com/hcrane/items/a0a7a77f9d709e9692b6)に拠れば**Resource Tag**にも追加すると書いてあるが、これは結局ファイルの存在チェックにしか使えず、バンドルしているならフォントがあるのは当たり前の話であるし、バンドルしていないならそもそも Resource Tag の値は設定できないので事実上やってもやらなくても良い設定になっています。

現状、書かなくてもフォントはインストールできるので特にこの手順は不要かと思います。

### 既存の問題を解消するために

さて、一番の理想としてはフォントはどこかのサーバーからダウンロードしてきてそれを永続インストールしたいわけです。

で、永続インストールするためには`.process`しか使えない`CTFontManagerRegisterFontsForURL`ではなく`.persistent`が利用できる`CTFontManagerRegisterFontsWithAssetNames`の方が便利です。

1. `CTFontManagerRegisterFontsWithAssetNames`で`Documents`からインストールする
2. `CTFontManagerRegisterFontURLs`で`Documents`からインストールする
3. `CTFontManagerRegisterFontsForURL`を起動時に実行する

ということで候補に上がるのはこの三つ。

最初は 2 で終わりじゃないかと思っていたのですが、実行してみると以下のような[306 エラー](https://developer.apple.com/documentation/coretext/ctfontmanagererror/invalidfilepath)が出ました。

```
Error Domain=com.apple.CoreText.CTFontManagerErrorDomain Code=306
The file is not in an allowed location. It must be either in the application's bundle or an on-demand resource.
```

つまり、指定された URL が良くなくて、バンドルかオンデマンドリソースにあるフォントを指定しろとあります。まあ確かに外部のへんてこなフォントをインストールできては困るので、これは仕方ないかもしれません。

で、バンドルに含めるのは再三ダメだといってきたので残るはオンデマンドリソースになります。

なんだこれとなったのですが、調べてみるとソシャゲとかでよくある「アプリインストール時には要らないけれど起動時にダウンロードされる追加コンテンツ」であることがわかりました。

じゃあこれで解決かと思ったのですが、オンデマンドリソースは Apple のサーバーからか自分のサーバーからしかインストールすることができません。Apple のサーバーにファイルを置いておくのはバンドルしているのと変わりませんし、自分のサーバーであってもそれは同じことです。

結局のところ「アプリが無条件に信頼しているところからしか`.persistent`としてフォントはインストールできないよ」ということになります。

したがって 1, 2 の方式は無理だということがわかり、必然的に 3 の方式ということになります。

#### [`CTFontManagerSetAutoActivationSetting`](https://developer.apple.com/documentation/coretext/1499481-ctfontmanagersetautoactivationse)で自動登録はできないのか

無理です。

macOS 10.6+以降しか対応してませんでした。よって iOS では不可能です。

#### 登録されたフォント情報を取得する

[`CTFontManagerCopyAvailablePostScriptNames()`](https://developer.apple.com/documentation/coretext/1499516-ctfontmanagercopyavailablepostsc)と[`CTFontManagerCopyAvailableFontFamilyNames()`](https://developer.apple.com/documentation/coretext/1499494-ctfontmanagercopyavailablefontfa)でインストールされているフォントがとってこれるので取ってきます。

`CTFontManagerCopyRegisteredFontDescriptors`でとってこれるんじゃないのと思ったのですが、取ってこれませんでした。

> どうも設定のフォントのところに登録されているフォントしかとってこれないっぽい

`.process`でインストールした場合はあそこに表示されないので仕方ないかなという気もします。

```
/// PostScriptNames
[KurokaneStd-EB, RowdyStd-EB, Splatoon1, Splatoon2]
/// FamilyNames
[FOT-Kurokane Std EB, FOT-Rowdy Std EB, Splatoon1, Splatoon2]
```

で、取得した結果が上のような感じでした。この値はこれから使うことになるので覚えておきます。

### スコープと利用可能なメソッド

どれが使えてどれが使えないかがわかりにくいのでまとめました。

|                  メソッド                  |   .persistent   | .process  |
| :----------------------------------------: | :-------------: | :-------: |
|      CTFontManagerRegisterFontsForURL      |        -        | Documents |
|       CTFontManagerRegisterFontURLs        |        -        | Documents |
|  CTFontManagerRegisterFontsWithAssetNames  | Assets.xcassets |     -     |
|     CTFontManagerUnregisterFontsForURL     |        -        | Documents |
|      CTFontManagerUnregisterFontURLs       |        -        | Documents |
|   CTFontManagerUnregisterFontDescriptors   | Assets.xcassets |     -     |
| CTFontManagerCopyRegisteredFontDescriptors |       OK        |    NG     |

オンデマンドリソースを使わないのであれば`.persistent`はバンドルされた署名済みのフォントにしか使えません。`Documents`などのファイルを指定すると`CTFontManagerErrorDomain Code=306`が発生します。

また、その逆でバンドルされたフォントを`.process`で登録することもできません。登録しようとすると`Invalid argument`が返ります。

#### バンドルされたフォント

バンドルしているならフォントの情報は全てわかっているはずなので何も考えずにインストールでは`CTFontManagerRegisterFontsWithAssetNames`を使っておいて、アンインストールするときには`CTFontManagerUnregisterFontDescriptors`と`CTFontManagerCopyRegisteredFontDescriptors`を組み合わせて利用すると良いでしょう。

> `CTFontManagerCopyRegisteredFontDescriptors`は`.persistent`でインストールされたフォントしか取ってこれないので`.process`でインストールしたフォントはこの方法ではアンインストールできません

#### 取得したフォント

外部から取得したフォントは署名がないのでシステムにインストールすることはできません。

|              メソッド              | .persistent | .process  |
| :--------------------------------: | :---------: | :-------: |
|  CTFontManagerRegisterFontsForURL  |      -      | Documents |
|   CTFontManagerRegisterFontURLs    |      -      | Documents |
| CTFontManagerUnregisterFontsForURL |      -      | Documents |
|  CTFontManagerUnregisterFontURLs   |      -      | Documents |

よって、インストールとアンインストールは上の四つのメソッドを使うことになります。何も考えずに`FileManager.default`とかで URL を取得して`[CFURL]`を経由して`CFArray`に渡すだけ、難しいところもないです。

`CTFontManagerRegisterFontURLs`は`CTFontManagerRegisterFontsForURL`の完全上位互換です。

### フォントのマージ

そしていちばん大事なところがここ、フォントのマージができるのかどうか。

ここまでいろいろ書いてきましたが、結局それらは理解を深めるために書いてきただけで、ここのマージができないと何の解決にもなりません。

調べたところ、二つの FontDescriptors をマージするようなメソッドはありませんでした。

> と思っていたところ、[大変有益な記事](https://speakerdeck.com/satoshin21/uifontdescriptor)を見つけてしまった......

なんとカスケードフォントというものを利用することで「英語のときはこのフォント A、日本語のときはフォント B で表示したい」という要望を叶えることができると書いてある。

え、これ勝ったのでは？？？

#### [UIFontDescriptor](https://developer.apple.com/documentation/uikit/uifontdescriptor)

現段階ではまだ`CTFontDescriptor`という型なのでこれを変換します。ただし、継承クラスなので無条件に成功します。

`UIFontDescriptor`はそのまま`UIFont`に突っ込めて、`UIFont`はそのまま SwiftUI の`Font`に突っ込めるので逆順に追うと以下のような流れになるわけです。

```
11. URL -> as
10. CFURL -> CTFontManagerCreateFontDescriptorsFromURL()
9. CFArray? -> unwrap
8. CFArray -> as?
7. [CTFontDescriptor]? -> unwrap
6. [CTFontDescriptor] -> first
5. CTFontDescriptor? -> unwrap
4. CTFontDescriptor -> as
3. UIFontDescriptor -> init
2. UIFont (UIKit) -> init
1. Font (SwiftUI)
```

ということでアンラップも含めれば 11 段階遡ることで URL から SwiftUI で利用できる Font まで繋げられることがわかりました。

このとき`UIFontDescriptor`に対して適切にカスケードフォントを設定することで一つのフォントファミリーで Splatfont1 と Splatfont2 に対応できるはずです。

では、そのコードを書いていきましょう。

## SwiftUI での実装

上の例ではスプラ 2 向けのフォントを利用していましたが、スプラ 3 では中国語と韓国語に対応しなければいけないので最初か r あらこちらで実装します。

### フォント

```
Splatoon1-common.3b7ce8b3c19f74921f51.woff2
Splatoon1-symbol-common.38ddb9a11cb1f225e092.woff2
Splatoon1-cjk-common.62441e2d3263b7141ca0.woff2
Splatoon1JP-hiragana-katakana.7650dccc9af86f19f094.woff2
Splatoon1JP-level1.fafc97f04a568e26ba52.woff2
Splatoon1JP-level2.225bb1db5962c9d61773.woff2
Splatoon1KRko-level1.a94dd3748648749f4583.woff2
Splatoon1KRko-level2.fcce77dce5655afed7d2.woff2
Splatoon1CHzh-level1.6b6af277c3dc45a8cf10.woff2
Splatoon1CHzh-level2.a24ca5d538d0b6a0d086.woff2
Splatoon1TWzh-level1.e991c1b3c2084df56d18.woff2
Splatoon1TWzh-level2.054b111fb7118a083ff7.woff2
```

フォントは全部で 12 種類で共通のフォントが 3 つあります。

|  言語  | フォント | 合計 |
| :----: | :------: | :--: |
| Common |    4     |  -   |
|   JP   |    3     |  7   |
|   KO   |    2     |  6   |
|   CH   |    2     |  6   |
|   TW   |    2     |  6   |

共通のフォントはプレイヤー名につけられる文字なので「記号・シンボル・ひらがな・かたかな・英語」です。

これらが含まれるのが上から四つのフォントファイルなのでこれらは必ず含む必要があります。なので日本語でも韓国語でも中国語でもなければフォントファイルは四つマージするだけで良いのですが、どうせなら日本語を突っ込めばいいので日本語とそれ以外で分けてしまうのが良いです。

```swift
enum Splatfont1: String, CaseIterable {
    case Splatoon1Common                = "3b7ce8b3c19f74921f51"
    case Splatoon1SymbolCommon          = "38ddb9a11cb1f225e092"
    case Splatoon1CjkCommon             = "62441e2d3263b7141ca0"
    case Splatoon1JPHiraganaKatakana    = "7650dccc9af86f19f094"
    case Splatoon1JPLevel1              = "fafc97f04a568e26ba52"
    case Splatoon1JPLevel2              = "225bb1db5962c9d61773"
    case Splatoon1KRkoLevel1            = "a94dd3748648749f4583"
    case Splatoon1KRkoLevel2            = "fcce77dce5655afed7d2"
    case Splatoon1CHzhLevel1            = "6b6af277c3dc45a8cf10"
    case Splatoon1CHzhLevel2            = "a24ca5d538d0b6a0d086"
    case Splatoon1TWzhLevel1            = "e991c1b3c2084df56d18"
    case Splatoon1TWzhLevel2            = "054b111fb7118a083ff7"
}
```

フォントはハッシュで区別できるのでしてしまいましょう。

これに対し、フォントをマージして`UIFontDescriptor`として返すメソッドを定義します。

> `UIFont`を返してしまうとフォントのサイズの変更ができなくなるので注意

```swift
extension Splatfont1 {
    /// SplatNet3のURL
    var baseURL: URL {
        URL(string: "https://api.lp1.av5ja.srv.nintendo.net/static/media")
    }

    /// フォントのURL
    /// 必ず存在するので強制アンラップしても問題ない
    var fontURL: CFURL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("static/media", conformingTo: .url)
            .appendingPathComponent(rawValue, conformingTo: .url)
            .appendingPathExtension("woff2") as CFURL
    }

    /// EnumからUIFontDescriptorを読み込む
    var fontDescriptor: UIFontDescriptor? {
        guard let array: CFArray = CTFontManagerCreateFontDescriptorsFromURL(self.fontURL),
              let fonts: [CTFontDescriptor] = array as? [CTFontDescriptor],
              let font: CTFontDescriptor = fonts.first
        else {
            return nil
        }
        return font as UIFontDescriptor
    }

    static let splatfont1jpja: UIFontDescriptor {
        [

        ]
    }
}
```
