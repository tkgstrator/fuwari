---
title: GitHub Actions+Fastlaneでアプリをデプロイする
published: 2024-02-25
description: Fastlaneでアプリを自動で配信できる環境の整え方について 
category: Tech
tags: [macOS, Fastlane, Xcode, iOS]
---

## 手順の解説

### GitHub

GitLabで利用する方法もあるのですが、GitLabだとmacOSのランナーが課金するかオンプレにしないと使えないので今回はGitHubを利用します。

今回は作業用のレポジトリを[apple-appstore-connect-test](https://github.com/tkgstrator/apple-appstore-connect-test)として作成しました。

このレポジトリはパブリックでもプライベートでも構いません。

よくわかっていない方は上のレポジトリをクローンすれば同じ環境が作れます。

#### プライベートレポジトリ

GitLabではSecure Filesという仕組みでデータをセキュアに保存できたのですが、GitHubにはないので証明書を保存するためのレポジトリを作成します。

今回は証明書保存用のレポジトリを[apple-appstore-connect-test-match](https://github.com/tkgstrator/apple-appstore-connect-test-match)として作成しました。

**こちらのレポジトリは機密情報を含むため、必ずプライベートレポジトリにしてください**

#### ACCESS_TOKEN

多分、ローカルでテストしたい場合に必要になります。

[New personal access token (classic)](https://github.com/settings/tokens/new)から作成します。

今回は無限に使う予定だったので有効期限をなしにしましたが、どうせApple Developer Programは一年で切れるので一年間でも良いと思います。

スコープはよくわかっていないのですがとりあえず**repo**にさえチェックが入っていれば動きます。

作成したらトークンの内容を何処かにコピーしておきます。

### App Store Connect

[App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api)からAPIキーを生成します。

このAPIキーを利用することで証明書を取得してくるという仕組みです。

従来、2FAが有効になっていると証明書の取得は大変にめんどくさかったのですがAPIキーを利用することでそれらのしがらみから解放されました。

これを使うことのメリットは[公式ドキュメント](https://docs.fastlane.tools/app-store-connect-api/)に書いてあるので目を通すと良いかもしれません。

- No 2FA needed
- Better performance
- Documented API
- Increased reliability

はい、いいことしかありませんね。

APIキーを発行したら**Issuer ID**、**Key ID**の二つをコピーします。

そして最後にAPIキー自体をダウンロードします。このキーは一度ダウンロードすると二度とダウンロードできないので大切に保管してください。

ダウンロードしたらそのファイルをBase64でエンコードします。ただし、このファイル自体が機密情報なので間違ってもオンラインサービスなどでエンコードしないようにしましょう。

```zsh
cat AuthKey_XXXXXXXX.p8 | base64
```

とコマンドを打てばエンコードされた文字列が表示されるので、この値をコピーします。

Base64自体は暗号化でもなんでもないのでやはりこのデータも機密情報となります。取り扱いには注意してください。

### 環境変数

ここまでできたら環境変数をGitHubのRepository secretsに登録します。

登録すべきデータは以下の五つです。ローカルで検証したい場合は`.env`に書き込んでしまっても良いでしょう。

| キー            | 意味             | 
| --------------- | ---------------- | 
| MATCH_PASSWORD  | パスワード       | 
| ASC_KEY_ID      | キーID           | 
| ASC_ISSUER_ID   | 発行者ID         | 
| ASC_KEY_CONTENT | Base64した文字列 | 
| PRIVATE_TOKEN   | アクセストークン | 

> どうやらFastfileで利用する`match`はGitHub Actionsに渡される`GITHUB_TOKEN`ではアクセスできないようで**Accessible from repositories owned by the user**の項目を変更してもアクセス権がないと表示されてしまった
>
> もっと強い権限をアクセストークンに与えれば解決するかもしれないが、とりあえず保留しておく

ローカルで作業する場合は上の五つ加えて`GITHUB_ACTOR`が必要になります。

これらの値を`.env`に書き込んでください。`GITHUB_ACTOR`はGitHubのユーザー名になるので私の場合は`tkgstrator`となります。

`MATCH_PASSWORD`は適当に[1Password](https://1password.com/password-generator/)とかで強めのパスフレーズを作成して設定しておけば良いです。

## Fastlane

ここからあとの作業はローカルで行います。

### `init`

`fastlane init`を実行します。

```zsh
[✔] 🚀 
[✔] Looking for iOS and Android projects in current directory...
[10:28:57]: Created new folder './fastlane'.
[10:28:57]: Detected an iOS/macOS project in the current directory: 'TestApp.xcodeproj'
[10:28:57]: -----------------------------
[10:28:57]: --- Welcome to fastlane 🚀 ---
[10:28:57]: -----------------------------
[10:28:57]: fastlane can help you with all kinds of automation for your mobile app
[10:28:57]: We recommend automating one task first, and then gradually automating more over time
[10:28:57]: What would you like to use fastlane for?
1. 📸  Automate screenshots
2. 👩‍✈️  Automate beta distribution to TestFlight
3. 🚀  Automate App Store distribution
4. 🛠  Manual setup - manually setup your project to automate your tasks
```

今回はTestFlightにベータ版をデプロイしたいので**2**を選択します。

いろいろ出てきますがとりあえずエンターキーを押します。

```zsh
fastlane/
├── Appfile
└── Fastfile
```

が作成されると思います。

### `match init`

`fastlane match init`を実行します。

```zsh
[✔] 🚀 
[16:51:49]: fastlane match supports multiple storage modes, please select the one you want to use:
1. git
2. google_cloud
3. s3
4. gitlab_secure_files
?  
```

今回はGitのプライベートレポジトリを利用するので**1**を選択します。

プライベートレポジトリを入力しろと言われるので今回の場合は**https://github.com/tkgstrator/apple-appstore-connect-test-match.git**と入力しました。

> 当たり前ですが、自身が管理するプライベートレポジトリを入力するように

途中でパスワードの入力を求められたらそれが先程設定した`MATCH_PASSWORD`になります。

これを入れないと対話式になってしまうのでGitHub Actionsで`match`ができなくなります。

万が一間違った値を入力してしまっても`fastlane match change_password`でパスフレーズを初期化できるので安心してください。

### `match`

とりあえず開発用と本番用の証明書があればよいと思うので、

```zsh
fastlane match development
fastlane match appstore
```

で証明書を発行します。

発行数が上限に達してるよと言われた場合には`fastlane match nuke development`とかすれば大丈夫です。

> ただし`appstore`の署名を取り消すには`fastlane match nuke distribution`という罠があります。

### Fastflie

```zsh
fastlane/
├── Appfile
├── Fastfile
└── Matchfile
```

さて、上のようなファイルができていると思いますがここで`Fastfile`だけ編集します。

その他はこのまま放置でオッケーです。

```ruby
platform :ios do
  desc "Push a new beta build to TestFlight"
  lane :beta do
    setup_ci(provider: "travis")
    api_key = app_store_connect_api_key(
      key_id: ENV['ASC_KEY_ID'],
      issuer_id: ENV['ASC_ISSUER_ID'],
      key_content: ENV['ASC_KEY_CONTENT'],
      in_house: false,
      is_key_content_base64: true
    )
    match(
      git_basic_authorization: Base64.strict_encode64("#{ENV['GITHUB_ACTOR']}:#{ENV['GITHUB_TOKEN']}"),
      api_key: api_key,
      app_identifier: 'work.tkgstrator.TestApp',
      type: "appstore",
      readonly: is_ci
    )
    increment_build_number(xcodeproj: "TestApp.xcodeproj", build_number: latest_testflight_build_number + 1)
    build_app(scheme: "TestApp", export_method: "app-store", xcargs: "-allowProvisioningUpdates", output_directory: "build")
    upload_to_testflight(api_key: api_key, notify_external_testers: true, changelog: "Deploy by GitHub Actions.")
  end
end
```

自分でもよくわかっていないのですが、上のコードをそのまま書きます。

ただし`app_identifier`や`scheme`や`xcodeproj`に関しては各自変更してください。

> TestFlightであっても`appstore`を指定しなければいけないのは個人的な謎ポイントではある

## GitHub Actions

最後にGitHub Actionsで上のコードが実行されるようにします。

`mkdir -p .github/workflows`でディレクトリを作成して、その中に適当に`testflight.yaml`を作成しました。

```yaml
name: Upload TestFlight

on: 
  workflow_dispatch:
  push:
    branches:
      - master

jobs:
  build:
    runs-on: [macos-14]

    steps:
    - name: Checkout
      uses: actions/checkout@v4
      
    - name: Select Xcode version
      run: sudo xcode-select -s '/Applications/Xcode_15.2.app/Contents/Developer'
      
    - name: Show Xcode version
      run: xcodebuild -version
    
    - name: Cache
      uses: actions/cache@v4
      with:
        path: vendor/bundle
        key: ${{ runner.os }}-gems-${{ hashFiles('**/Gemfile.lock') }}
        restore-keys: |
          ${{ runner.os }}-gems-

    - name: Bundle install
      run: |
        bundle config path vendor/bundle
        bundle install --jobs 4 --retry 3
       
    - name: Upload a new build to App Store Connect
      env:
        ASC_KEY_ID: ${{ secrets.ASC_KEY_ID }}
        ASC_ISSUER_ID: ${{ secrets.ASC_ISSUER_ID }}
        ASC_KEY_CONTENT: ${{ secrets.ASC_KEY_CONTENT }}
        MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}
        GITHUB_TOKEN: ${{ secrets.PRIVATE_TOKEN }}
        GITHUB_ACTOR: ${{ secrets.GITHUB_ACTOR }}
      run: bundle exec fastlane beta
```

`GITHUB_ACTOR`については環境変数に最初から入っているので設定が不要というわけです。

> `PRIVATE_TOKEN`も利用しないようなコードに変えたい...GitHub Actionsからプライベートレポジトリを読み込めないのが問題......

あと、キャッシュがあんまり効いている気がしない、コピペしたけど間違ってないこれ？

記事は以上。
