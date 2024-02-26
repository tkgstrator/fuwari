---
title: Swift Package Managerでローカルファイルを読み込む
published: 2021-04-18
description: Swift Package Managerでローカルファイルを読み込み、ライブラリとして使う方法について解説
category: Programming
tags: [Swift]
---

## SwiftPackageManager

Apple 謹製のライブラリ管理ツールなのだが、CocoaPods や Carthage で開発したライブラリをそのまま移植しようとするとバグることがある。

というのも、どうも外部ファイルが正しく読み込めていないようで XIB や NIB などのファイルを読み込ませようとするとクラッシュする。

### 既存の問題

現在のところ、以下のバグが存在しているようだ。

- IBDesignable が効かない
- XIB や NIB をそのまま利用するとクラッシュする
  - 対応策はあるが

::: tip 参考文献

[ iOS 用ライブラリ作成者向け Swift Package Manager のリソース周り Tips](https://qiita.com/kazuhiro4949/items/0378e163fa00a79eb00a)

[自作ライブラリの Swift Package Manager(SwiftPM)対応](https://qiita.com/am10/items/72dbc511efc512fc065a)

:::

今回は XIB や NIB については扱わず、JSON ファイルをローカルでライブラリに追加したい場合を考える。

もちろん、最初から JSON を Swift のデータ構造に変換してから追加すればこのような記事は要らないのだが、いちいち変換するコードも書きたくないのである。

今回考えるのは以下のような JSON である。全部書くと長くなるので最初の一つのオブジェクトだけ書いたが、これが延々と数百個配列に入ったものだと考えてもらえば良い。

```json
[
  {
    "end_time": 1500696000,
    "rare_weapon": 20000,
    "stage_id": 5000,
    "start_time": 1500616800,
    "weapon_list": [10, 5010, 1010, 2010]
  }
]
```

賢明なうちの読者の皆様ならわかるだろうが、これは Codable を使って自動エンコードできる。

```swift
// 受け取るJSON配列一つ一つの構造
public struct CoopShift: Codable {
    var startTime: Int
    var endTime: Int
    var stageId: Int
    var rareWeapon: Int
    var weaponList: [Int]
}
```

つまり、こういう構造になっているというのがすぐに分かるわけである。

最後に JSONDecoder の`keyDecodingStrategy`でスネークケースからの自動変換設定をつけて読み込ませればいいというわけだ。

```swift
let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
}()
```

となれば問題となるのはローカル JSON を Data 型として取得するところだけである。

が、これを解決するのに結構時間がかかった。

## Package.swift の編集

今回は読み込ませたいファイルを`coop.json`とし、該当ファイルをパッケージのソースコードディレクトリ内の`Resource`ディレクトリ内に配置した。

```swift
// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SalmonStats",
    platforms:  [
        .iOS(.v13), .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "SalmonStats",
            targets: ["SalmonStats"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.4.2"),
        .package(url: "https://github.com/groue/CombineExpectations.git", from: "0.7.0")
    ],
    targets: [
        .target(
            name: "SalmonStats",
            dependencies: ["Alamofire"],
            resources: [.copy("Resources/coop.json")] // 追加
            ),
        .testTarget(
            name: "SalmonStatsTests",
            dependencies: ["SalmonStats", "CombineExpectations"],
            resources: [.copy("Resources/coop.json")]  // 追加
            )
    ]
)
```

注意点としては`copy`コマンドを使わないといけないという点。詳しくは[Apple のドキュメント](https://developer.apple.com/documentation/swift_packages/bundling_resources_with_a_swift_package)を読めば書いてある。

JSON ファイル自体は多分どこでもいいんだろうけれど、`Resources`においておくのが無難ではないかと思っている。

## ローカルファイル読み込み

```swift
// NG
guard let json = Bundle.main.url(forResource: "coop", withExtension: "json") else { return }

// NG
guard let json = Bundle.main.path(forResource: "coop", ofType: "json") else { return }

// OK
guard let json = Bundle.module.url(forResource: "coop", withExtension: "json") else { return }
```

いろいろ調べると`Bundle.main.path`や`Bundle.main.url`を使うように書いてあるがこれは Swift Package Manager では全く動かないのでいくら使ってもダメ。

というか、そもそも`Bundle.main`はライブラリで使うのは推奨されていないようだ。

Swift Package Manager の場合は必ず`Bundle.module`で読み込ませること。そうしないと Swift Package Manager では常に nil が返ってきてファイル読み込みに失敗してしまう。

### 使い方

これで正しいのかはわからないのだが、ライブラリで実際に使うところまで実装してみた。

```swift
// 継承できないようにfinalでs値減する
public final class SalmonStats {

    // Singletonで宣言
    public static let shared = SalmonStats()
    private var task: AnyCancellable?
    // 一回だけ呼び出して再利用するのでstaticで呼び出す
    static var shift: [CoopShift] {
        get {
            guard let json = Bundle.module.url(forResource: "coop", withExtension: "json") else { return [] }
            guard let data = try? Data(contentsOf: json) else { return [] }
            let decoder: JSONDecoder = {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return decoder
            }()

            guard let shift = try? decoder.decode([CoopShift].self, from: data) else { return [] }
            return shift
        }
    }
}
```

読み込みに失敗したら空っぽの配列を返すようにした。

まあ、実際にはライブラリ内で失敗することは想定されないので強制アンラップしてしまっても良いかもしれない。

## ライブラリを改修する

Salmon Stats の API はリザルトを一件ずつ取得した場合には全部のデータが正しく入っているのだが、複数件同時取得の API を叩くと何故か startTime と playTime の二つしかスケジュール情報が入っていないという大問題（バグ？）がある。

このため、ステージ ID などもいちいちアプリ側でとってこなければいけないという仕様になっている。

これはライブラリ側で解決すべき問題だと考えているので、Salmon Stats ライブラリでは自動補完できるようにするのである。

## 完成したもの

いろいろあったが、無事に[Salmon Stats ライブラリ](https://github.com/tkgstrator/SalmonStats)を完成させることができた。

詳しくは README に書いてあるのだが、以下の API を叩いてそのレスポンスを整形した上で返してくれる。

|           内容           |             エンドポイント              |    パラメータ    |
| :----------------------: | :-------------------------------------: | :--------------: |
|     リザルト一件取得     |                 results                 |        -         |
|    リザルト複数件取得    |         player/{nsaid}/results          | raw, count, page |
|      シフト記録取得      |         schedules/{schedule_id}         |        -         |
|      シフト統計取得      | players/{nsaid}/schedules/{schedule_id} |        -         |
|     ユーザデータ取得     |            players/metadata             |       ids        |
| ユーザデータ概要複数取得 |            players/metadata             |       ids        |
|        ユーザ検索        |             players/search              |       name       |

ユーザデータ複数取得にいつの間にか API が対応していたのだが、この記事を書くまで気づかなかったのでライブラリ側でまだ対応できていない。

ただ、ユーザデータも複数件取得した場合にはいくつかのデータが抜け落ちた状態でレスポンスが返ってくる。

あと、絶対必要だと思っていたのだが普通に名前検索機能も忘れていた。数日中にアップデートする予定である。
