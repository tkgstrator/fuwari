---
title: NavigationViewの仕様について
published: 2021-04-08
description: NavigationViewはiPhoneとiPadで挙動が違うのでその仕様をメモする
category: Programming
tags: [Swift]
---

## NavigationView の仕様

今回はわかりやすくするため、左側の画面を Master、右側の画面を Detail と呼ぶことにします。

NavivationView の理解として最も重要なのは次の点でしょう。

- NavigationLink は親が NavigationView を継承していないと効かない
- NavigationView は ContentView に適用するべきである
  - NavigationView 自体を入れ子にすると表示がおかしくなるのでしないこと
- NavigationLink の遷移先は常に Detail に表示される
- Master を切り替えることはできない
  - Master 自体がフラグによって表示を変えるようにしないといけない
- iPad の場合
  - NavigationView を入れ子にすると TOP が Master となり、二つ目以降は Detail になる
  - Landscape モードではビューが分割される
    - 理想的な動作である
  - Portrait モードでは TOP は必ず起動時に非表示になっている
    - これを変えることは推奨されていないようだ
    - 標準設定アプリはできているのに謎である
- iPhone の場合
  - NavigationView を入れ子にすると TOP が Master となり、二つ目以降は無視される

### MasterView と DetailView

ソースコードが肥大化したときにわかりにくくなるので、MasterView と DetailView の二つを作成して見やすくします。

```swift
struct MasterView: View {
    var body: some View {
        NavigationLink(
            destination: Text("Detail"),
            label: {
                Text("Navigate")
            })
            .navigationTitle("Nav")
    }
}

struct DetailView: View {
    var body: some View {
        Text("Detail View")
    }
}
```

### 完成させたい UI

目標としては iOS の標準の設定アプリのようなものですが、それを更に拡張したものとなります。

具体的には iPad と iPhone で表示方式を切り替えられるようにします。iPhone の方は理想的な動作ができているので、iPad でちゃんと動作させられるようになればよいわけです。

- iPad で SplitView を実現させる
- Portrait と Landscape で同じ UI にする
- 起動直に Master が表示されている
  - ボタンで Master は非表示にできる
- 起動直後に Detail が表示されている
  - Master の表示と非表示で Detail の画面サイズは動的に変化する

## NavigationView の理解を深める

### MasterView だけ NavigationView に入れる

でははじめに NavigationView に MasterView を入れてみます

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            MasterView()
        }
    }
}
```

これは Landscape モードでは問題ありませんが、Portrait モードのときに次の問題が発生します

- 起動直後に MasterView が表示されない
- 起動直後に DetailView が表示されない
- MasterView の表示/非表示で DetailView のサイズが変わらない
  - 常にフルスクリーンのような状態になっている

### Master と Detail のどちらも NavigationView に入れる

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            MasterView()
            DetailView()
        }
    }
}
```

NavigationLink を入れ子にすると TOP である MasterView が Master として表示され、DetailView が Detail として起動時に表示されるようになりました。

しかし、継続して次の問題が残ります。

- 起動直後に MasterView が表示されない
- MasterView の表示/非表示で DetailView のサイズが変わらない
  - 常にフルスクリーンのような状態になっている

### NaviationViewStyle を設定する

SwiftUI において NavigationView には三つのスタイルが用意されています

- DefaultNavigationViewStyle
- DoubleColumnNavigationViewStyle
- StackNavigationViewStyle

このうち何もしなければ DefaultNavigationViewStyle が適用されます。StackNavigationViewStyle は iPad でも常に iPhone と同じ UI になります。

DoubleColumnNavigationViewStyle に関しては[Apple 公式のドキュメント](https://developer.apple.com/documentation/swiftui/navigationviewstyle)において`A navigation view style represented by a primary view stack that navigates to a detail view.`という説明があります。

これだけではよくわからないので実際に利用してみます。

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            MasterView()
            DetailView()
        }
        .navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}
```

が、結果として何も変わりませんでした。iPhone でも iPad でも変わらなかったのでなんの効果があるのかわかりませんでした。

### navigationBarHidden

NavigationBar を非表示にできる`.navigationBarHidden()`という仕組みがあるのでそれを利用してみます。

```swift

```

`.navigationBarHidden()`を使うと Navigation の機能は残したまま、各種表示を非表示にできます。

### NavigationTitle の適用方法

iOS14 からは`.navigationTitle()`が使えます。重要な点としてはこれは NavigationView 内の View に対して使わないと効かないということです。

```swift

```

なので例えば上のようなコードは全く効果がありません。これは`.navigationTitle()`が NavigationView 自体にかかってしまっているからです。

```swift

```

### 一つ前の画面に戻る

ボタンを押すと何らかの処理を実行し、その進行状況を表示するビューに遷移するとします。

処理が終わったあと、もとの画面に戻りたいときにどうすればよいでしょうか。

```swift
struct ContentView: View {

    var body: some View {
        NavigationView {
            MasterView()
            DetailView()
        }
    }
}

struct ProgressView: View {

    var body: some View {
        NavigationLink(destination: MasterView()) { Text("Back to MasterView") }
            .navigationTitle("Progress View")
    }
}

struct MasterView: View {

    var body: some View {
        NavigationLink(
            destination: ProgressView(),
            label: {
                Text("Progress Start")
            })
            .navigationTitle("Master")
    }
}

struct DetailView: View {

    var body: some View {
        Text("Initial Detail View")
    }
}
```

例えば上のようなコードを書いたとします。これは NavigationLink を動作させるたびにどんどんネストが深くなっていくため想定通りの動作をしません。

じゃあどうすればいいのかという話になりますが、presentationMode という標準 Environment を使うと驚くほどに実装できます。変更するのも戻る機能を実装したい View だけなので楽です。

この presentationMode は`isPresented`という「NavigationLink から遷移してきたか」という情報を持っており、これを使って動作を切り替えることができます。

```swift
struct ProgressView: View {
    @Environment(\.presentationMode) var present

    var body: some View {
        Button(action: {
            present.wrappedValue.dismiss()
        }, label: { Text("Back to MasterView") })
            .navigationTitle("Progress View")
    }
}
```

注意点としては`wrappedValue.dismiss()`は画面の表示を切り替える動作のためメインスレッドで実行する必要があります。`DispatchQueue.global`を使う際は`DispatchQueue.main.async`を使うなどして必ずメインスレッドで実行するようにコーディングしましょう。

## NavigationLink の仕様

### タップして遷移したい場合

ボタンとしてタップしたら画面が遷移するような仕様を満たす使い方である。

たとえば、ボタンを押すと DetailView に遷移したい場合は以下のようなコードで実装できる。

```swift
struct ProgressView: View {
    var body: some View {
        NavigationLink(destination: DetailView()) { Text("Go to DetailView") }
            .navigationTitle("Progress View")
    }
}
```

### コードから遷移したい場合

ではボタンを押さず、プログラムが何らかの処理をした結果で自動的に遷移したい場合はどうするか。

それには`isActive`というプロパティがあるのでこれが利用できる。

```swift
struct ProgressView: View {
    @State var isActive: Bool = false

    var body: some View {

        Button(action: { isActive.toggle() }, label: { Text("Go to DetailView") })
        NavigationLink(destination: DetailView(), isActive: $isActive) { Text("Go to DetailView") }
            .navigationTitle("Progress View")
    }
}
```

あらかじめ@Stete で変更をチェックするための変数を確保しておき、それを NavigationLink の isActive プロパティに渡すのである。この場合だと、NavigationLink を直接押しても遷移するし、Button をタップしても isActive の値がフリップして初期状態の false から true に変わり NavigationLink が動作する。

これの問題点とすれば遷移するための NavigationLink を（半分無意味に）書いておかなければいけない点だろう。「コードでもタップでも遷移したい」場合ならこれでよいが、コードでしか遷移したくない場合にタップしたら遷移できてしまう NavigationLink を表示しっぱなしにしておくのは良くない

```swift
struct ProgressView: View {
    @State var isActive: Bool = false

    var body: some View {

        Button(action: { isActive.toggle() }, label: { Text("Go to DetailView") })
        NavigationLink(destination: DetailView(), isActive: $isActive) { Text("Go to DetailView") }
            .hidden()
            .navigationTitle("Progress View")
    }
}
```

のように`hidden()`属性をつければ非表示にはなるものの、これは見た目が消えているだけなのでこの View のスペースが消費されていてレイアウトがズレてしまう。

ズレないようにするためには NavigationLink の View として`EmptyView()`を指定すればよい。

```swift
struct ProgressView: View {
    @State var isActive: Bool = false

    var body: some View {

            Button(action: { isActive.toggle() }, label: { Text("Go to DetailView") })
            NavigationLink(destination: DetailView(), isActive: $isActive) { EmptyView() }
                .navigationTitle("Progress View")
    }
}
```

これで基本的な場合についてはうまく動作させられるが、`List`ではたとえ`EmptyView()`であっても検知されて空っぽのカラムが作成されるという問題がある。`List`の場合は ZStack で対応するのが良いだろう。

## 結局どうすべきなのか

ここまでの検証から以下のことがわかっている。

- iPad の Portrait と Landscape の見た目をおなじにする仕組みは存在しない
  - Apple の方針は「NavigationView は Portrait 時には非表示にできるべき」ということらしい
  - しかし、実用上これがものすごく困るということはないように思える
- Master は基本的に切り替えできない
  - Master 内で Switch 文などで表示したい内容を切り替えないといけない
  - Apple の方針として Master の内容は常に固定しておいてほしいのかもしれない
- NavigationView を入れ子構造にすることはできない
  - ContentView または SwiftApp に対して NavigationView を適用すべき
  - SwiftApp.swift に対して適用すると EnvironmentObject の問題が発生したりする
  - ContentView が無難なところかもしれない
- NavigationView に二つ以上の View を入れることができる
  - iPad の場合は一つ目が Master、二つ目が Detail の（初期表示）になる
  - iPhone または StackNavigationViewStyle のときは二つ目以降は無視される
  - 無視されるという仕様上、iPad 向けで MasterView を構成するだけで良い
- NavigationLink を使うと常に Detail が更新される
  - 一つ前の画面に戻りたいときは presentationMode を使うべきである

### どういう仕様にするか

登録制のアプリの場合、起動直後に表示したいのはアカウント作成やログインを促す画面である。

そして、このときには SplitView 的な機能はオフであってほしい。そうでないとログインする前から様々な機能にアクセスできることになってしまう。

- ログイン前は SplitView はオフ
  - StackNavigationViewStyle を使えばできる
  - ログイン状態によって NavigationViewStyle を切り替える
- NavigationViewStyle
  - ログイン前は DetailView のみ表示
  - ログイン後は Master を MasterView に表示

引数によって NavigationViewStyle を直接変えることが難しかったので ViewModifier を使って実装することにした。

これを使えば View 簡単に NavigationViewStyle を変更することができる。そのままでも使いやすいのだがいちいち`.modifier()`を宣言するのが面倒だったので extension を使って更に便利にした。

```swift
struct NavigationModifier: ViewModifier {
    let style: Bool

    func body(content: Content) -> some View {
        switch style {
        case true:
            return AnyView(
                content
                .navigationViewStyle(StackNavigationViewStyle())
            )
        case false:
            return AnyView(
                content
                .navigationViewStyle(DoubleColumnNavigationViewStyle())
            )
        }
    }
}

extension View {
    func navigationStyle(style: Bool) -> some View {
        self.modifier(NavigationModifier(style: style))
    }
}
```

これを使うことで`navigationStyle(style: Bool)`で NavigationViewStyle を切り替えられる。

ただ、このままでは StackNavigationViewStyle のときに MasterView が表示されてしまう。

StackNavigationViewStyle の仕様を変えるのは面倒なので、フラグの状態によって Master が MasterView を表示するか DetailView を表示するかを切り替えるのが得策かと思われる。

しかし、そうするなら最初からそうすればいいだけで、ViewModifier はつくらなくて良かったのではないかという気もしてくる。

### MasterVeiw

あまり想定はしていなかったのだが`presentationMode`で View が Master かどうかをチェックできるようだ。StackNavigationViewStyle の場合は NavigationView の一つ目の View の`presentationMode`が false になるためそこにログインのために必要な View を表示するようにすれば良い。

```swift
struct MasterView: View {
    @Environment(\.presentationMode) var present

    var body: some View {
        switch present.wrappedValue.isPresented {
        case true:
            return AnyView(
                NavigationLink(
                    destination: ProgressView(),
                    label: {
                        Text("Progress Start")
                    })
                    .navigationTitle("Master")
            )
        case false:
            return AnyView(LoginView())
        }
    }
}

struct LoginView: View {

    var body: some View {
        Text("Login View")
            .navigationTitle("Login")
    }
}
```

この View 切り替えの仕組みと先程の ViewModifier を使えば仕様を満たすことができそうだ。

## TabView との組み合わせ

さて、List にデータが多い場合目的の値を調べるのにずっと下の方までスクロールしなければならないような状況が考えられる。

10 や 20 なら大した手間でないから気にならないだろうが、50 や 100 となってくるとめんどくさく感じられるだろう。SwiftUI には iOS14 からリストの中のリストの機能である SidebarListStyle()というものが使える。

タブからフィルタリングするのも良いが、まずはこの新機能を試してみたい。

### SidebarListStyle

listStyle としてこれを設定すると、Sidebar として使えるようになる。具体的にはリストをセクションごとに区切って閉じたり開いたりすることができるようになる。ただし、これには問題点があって、初期化の際にすべてのカラムが開けられた状態で表示されてしまう。

つまり、下の方まで見に行こうとしたら上から順番にリストを閉じていかなければならず、余計に手間がかかってしまう。今後のアップデートで改善されるかもしれないが、すぐに使えるような便利な機能ではなさそうだった。

### NavigationView で Sidebar を実装する

NavigationView は iPad であれば三つまで入れることができるのだが、三つ目を入れると一つ目の View を Landscape でも固定することができなくなってしまう。

つまり Apple 公式サイトで紹介されている[このアプリ](https://developer.apple.com/design/human-interface-guidelines/ios/views/split-views/)のようなレイアウトをつくることができない。常に Master を表示することができるオプションがあればいいのだが、少し調べた感じでは見つからなかった。

### Tabbar + NavigationView

Apple ではあまり推奨されていないような書き方がされていたが、一応使える。

```swift
struct ContentView: View {
    @State var selection = 0

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: EmptyView() { Text("EMPTY") }
                NavigationLink(destination: EmptyView() { Text("EMPTY") }
            }
            .navigationTitle("Menu")
            TabView(selection: $selection) {
                EmptyView()
                    .tabItem { Image(systemName: "flame") }.tag(0)
                EmptyView()
                    .tabItem { Image(systemName: "bolt") }.tag(1)
                EmptyView()
                    .tabItem { Image(systemName: "drop") }.tag(2)
            }
        }
    }
}
```

リストと組み合わせればこういうのも書ける。ただし、この場合だと Detail に TabView が指定されているので NavigationLink を踏むなどして別画面に遷移すると Detail が切り替わるため TabView が消えてしまうことに注意。

NavigationView の方が上位（TabView はあくまでも Detail に対してのみ有効）なので、メニューを表示するとタブの幅は自動的に狭くなる。

### PageTabViewStyle

```swift

```
