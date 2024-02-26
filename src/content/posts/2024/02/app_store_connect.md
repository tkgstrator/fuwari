---
title: GitLab CIでApp Store Connectにアプリをデプロイする 
published: 2024-02-26
description: ''
image: ''
tags: ['Xcode', 'GitLab', 'AppStoreConnect', 'IPA']
category: 'Programming'
draft: false 
---

## GitLab + AppStoreConnect

普段はGitHabを利用しているのですが、たまたまGitLabでiOSアプリをデプロイする必要が生じたので備忘録としてメモしておきます。

主な手順は[公式ドキュメント](https://docs.gitlab.com/ee/user/project/integrations/apple_app_store.html)を参考にしました。

なのでこれがすんなり読める方は多分この記事は不要です。

## 必要なもの

- Apple Developer Programに加入しているApple ID
- Apple App Store Connect Portalで作成したプライベートキー
  - 作成の手順については[ここ](https://developer.apple.com/documentation/appstoreconnectapi/creating_api_keys_for_app_store_connect_api)を参照
  - URL自体がわからない人は[ここ](https://appstoreconnect.apple.com/access/integrations/api)で直接キーが作成できる

### GitLab

1. 左のサイドバーから**Search or go to**でプロジェクト検索
2. **Settings > Integrations**を選択
3. **Apple App Store Connect**を選択
4. **Enable Integration**の下から**Active**にチェックを入れる
5. 以下の情報を入力する
    - **Issuer ID**
    - **Key ID**
    - **Private key**
    - **Protected branches and tags only**
6. **Save changes**で保存する

ここで**Test settings**を押して**Connection successful**と表示されれば成功です。

これをすれば以下の環境変数が利用可能になります。

- `$APP_STORE_CONNECT_API_KEY_ISSUER_ID`
- `$APP_STORE_CONNECT_API_KEY_KEY_ID`
- `$APP_STORE_CONNECT_API_KEY_KEY`
    - Base64エンコードされた秘密鍵
- `$APP_STORE_CONNECT_API_KEY_IS_KEY_CONTENT_BASE64`
    - 常に`true`が入る

`.gitlab-ci.yml`に悪意のあるコードがプッシュされると`$APP_STORE_CONNECT_API_KEY_KEY`などの変数が外部のサーバーに送信される可能性があるので、注意すること。

## Fastlane

で、ここまできたらFastlaneでこれらのコードを利用したいですよね。

なのでまずはXcodeで適当なプロジェクトを作成します。

今回は`TestApp`とかいうそのまんまな名前を使いました。作成したらとりあえずGitLabにプッシュしておきます。

[iOS Beta deployment using fastlane](https://docs.fastlane.tools/getting-started/ios/beta-deployment/)という内容が今回求められているものだと思うのでこれを読みましょう。

### 導入

まずは`fastlane`がインストールされている必要があります。

- Homebrew(macOS)
    - `brew install fastlane`
- System Ruby + RubyGem(macOS/Linux/Windows)
    - `sudo gem install fastlane`

どちらかのコマンドでインストールできますが、普通はmacOSを使っていると思いますしSystem Rubyを利用すると権限でいろいろうるさいのでHomebrewを大人しく使います。

インストールができたら`fastlane init`で初期化します。

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

のような表示が出てきます。今回やりたいのはベータ版をTestFlightにアップロードする作業ですので、2を選択します。

```zsh
[10:29:42]: -----------------------------------------------------------
[10:29:42]: --- Setting up fastlane for iOS TestFlight distribution ---
[10:29:42]: -----------------------------------------------------------
[10:29:42]: Parsing your local Xcode project to find the available schemes and the app identifier
...
[10:29:45]: --------------------------------
[10:29:45]: --- Login with your Apple ID ---
[10:29:45]: --------------------------------
[10:29:45]: To use App Store Connect and Apple Developer Portal features as part of fastlane,
[10:29:45]: we will ask you for your Apple ID username and password
[10:29:45]: This is necessary for certain fastlane features, for example:
[10:29:45]: 
[10:29:45]: - Create and manage your provisioning profiles on the Developer Portal
[10:29:45]: - Upload and manage TestFlight and App Store builds on App Store Connect
[10:29:45]: - Manage your App Store Connect app metadata and screenshots
[10:29:45]: 
[10:29:45]: Your Apple ID credentials will only be stored in your Keychain, on your local machine
[10:29:45]: For more information, check out
[10:29:45]:     https://github.com/fastlane/fastlane/tree/master/credentials_manager
[10:29:45]: 
[10:29:45]: Please enter your Apple ID developer credentials
[10:29:45]: Apple ID Username:
```

のような表示が続き、Apple IDの入力を求められます。

ログインを試みると6桁のワンタイムパスワードが要求されるのでそれを入力します。

複数のチームに所属している場合はどのチームを利用するかを選択する必要があります。

```zsh
[10:32:45]: ✅  Logging in with your Apple ID was successful
[10:32:45]: Checking if the app 'work.tkgstrator.TestApp' exists in your Apple Developer Portal...
[10:32:45]: It looks like the app 'work.tkgstrator.TestApp' isn't available on the Apple Developer Portal
[10:32:45]: for the team ID 'D9HU6JZF2Q' on Apple ID 'crossguitar@live.jp'
[10:32:45]: Do you want fastlane to create the App ID for you on the Apple Developer Portal? (y/n)
```

今回は適当に作ったアプリなのでApple Developer Portalにまだアプリがないと言われます。ここで作成することもできるので**y**を入力してついでに作ってもらいましょう。

```zsh
+------------------------------------------+
|       Summary for produce 2.219.0        |
+----------------+-------------------------+
| username       | crossguitar@live.jp     |
| team_id        | D9HU6JZF2Q              |
| itc_team_id    | 118733804               |
| platform       | ios                     |
| app_identifier | work.tkgstrator.TestApp |
| skip_itc       | true                    |
| sku            | 1708911228              |
| language       | English                 |
| skip_devcenter | false                   |
+----------------+-------------------------+

[10:33:49]: App Name: TestApp
[10:34:00]: Creating new app 'TestApp' on the Apple Dev Center
[10:34:02]: Created app GJH5FZTZUD
[10:34:02]: Finished creating new app 'TestApp' on the Dev Center
[10:34:02]: ✅  Successfully created app
[10:34:02]: Checking if the app 'work.tkgstrator.TestApp' exists on App Store Connect...
[10:34:03]: Looks like the app 'work.tkgstrator.TestApp' isn't available on App Store Connect
[10:34:03]: for the team ID '118733804' on Apple ID 'crossguitar@live.jp'
[10:34:03]: Would you like fastlane to create the App on App Store Connect for you? (y/n)
```

作成できると、App Store Connect用のfastlaneを作成するかと問われます。ついでに作ってもらいたいのでやはり**y**を入力します。

```zsh
+------------------------------------------+
|       Summary for produce 2.219.0        |
+----------------+-------------------------+
| username       | crossguitar@live.jp     |
| team_id        | D9HU6JZF2Q              |
| itc_team_id    | 118733804               |
| platform       | ios                     |
| app_identifier | work.tkgstrator.TestApp |
| skip_devcenter | true                    |
| sku            | 1708911289              |
| language       | English                 |
| skip_itc       | false                   |
+----------------+-------------------------+

[10:34:51]: App Name: TestApp
[10:35:05]: Creating new app 'TestApp' on App Store Connect
[10:35:05]: Sending language name is deprecated. 'English' has been mapped to 'en-US'.
[10:35:05]: Please enter one of available languages: ["ar-SA", "ca", "cs", "da", "de-DE", "el", "en-AU", "en-CA", "en-GB", "en-US", "es-ES", "es-MX", "fi", "fr-CA", "fr-FR", "he", "hi", "hr", "hu", "id", "it", "ja", "ko", "ms", "nl-NL", "no", "pl", "pt-BR", "pt-PT", "ro", "ru", "sk", "sv", "th", "tr", "uk", "vi", "zh-Hans", "zh-Hant"]
```

言語は勝手に`en-US`が設定されたのですが利用しているmacOSの設定によっては変わるかもしれません。

> この後、作成に失敗したりでよくわからないエラーが発生したので再度`fastlane init`を実行したので結果が異なるかもしれません。

続けていると以下のようなメッセーが表示されました。

```zsh
[10:37:46]: ✅  Logging in with your Apple ID was successful
[10:37:46]: Checking if the app 'work.tkgstrator.TestApp' exists in your Apple Developer Portal...
[10:37:47]: ✅  Your app 'work.tkgstrator.TestApp' is available in your Apple Developer Portal
[10:37:47]: Checking if the app 'work.tkgstrator.TestApp' exists on App Store Connect...
[10:37:48]: ✅  Your app 'work.tkgstrator.TestApp' is available on App Store Connect
[10:37:48]: Installing dependencies for you...
[10:37:48]: $ bundle update
[10:37:55]: --------------------------------------------------------
[10:37:55]: --- ✅  Successfully generated fastlane configuration ---
[10:37:55]: --------------------------------------------------------
[10:37:55]: Generated Fastfile at path `./fastlane/Fastfile`
[10:37:55]: Generated Appfile at path `./fastlane/Appfile`
[10:37:55]: Gemfile and Gemfile.lock at path `Gemfile`
[10:37:55]: Please check the newly generated configuration files into git along with your project
[10:37:55]: This way everyone in your team can benefit from your fastlane setup
[10:37:55]: Continue by pressing Enter ⏎
```

特に重要なところもないので脳死でエンターキーを連打します。

```zsh
.
├── fastlane/
│   ├── Appfile
│   └── Fastfile
├── TestApp/
├── TestApp.xcodeproj/
├── TestAppTests/
├── TestAppUITests/
├── Gemfile
└── Gemfile.lock
```

するとこんな感じのディレクトリ構造になると思います。

### Matchfile

[Tutorial: iOS CI/CD with GitLab](https://about.gitlab.com/blog/2023/06/07/ios-cicd-with-gitlab/)によるとMatchfileも別途必要だそうです。

```zsh
fastlane match init
```

とすると、

```zsh
[✔] 🚀 
[10:49:05]: fastlane match supports multiple storage modes, please select the one you want to use:
1. git
2. google_cloud
3. s3
4. gitlab_secure_files
```

と表示されます。GitLabを利用していれば`Secure Files`が利用できるので4を選択します。

```zsh
[10:49:55]: Initializing match for GitLab project  on 
[10:49:55]: What is your GitLab Project (i.e. gitlab-org/gitlab): tkgstrator/apple-appstore-connect-test
[10:50:12]: What is your GitLab Host (i.e. https://gitlab.example.com, skip to default to https://gitlab.com): 
[10:50:14]: Successfully created './fastlane/Matchfile'. You can open the file using a code editor.
[10:50:14]: You can now run `fastlane match development`, `fastlane match adhoc`, `fastlane match enterprise` and `fastlane match appstore`
[10:50:14]: On the first run for each environment it will create the provisioning profiles and
[10:50:14]: certificates for you. From then on, it will automatically import the existing profiles.
[10:50:14]: For more information visit https://docs.fastlane.tools/actions/match/
```

今回、レポジトリ名が**https://gitlab.com/tkgstrator/apple-appstore-connect-test**だったのでGitLab Projectには**tkgstrator/apple-appstore-connect-test**を指定し、GitLab Hostはデフォルト設定なのでそのままエンターキーを押します。

セルフホストしている場合はホスト名を指定してください。

すると`fastlane/Matchfile`が作成され、以下のような内容が書いてあります。

```ruby
gitlab_project("tkgstrator/apple-appstore-connect-test")
gitlab_host("https://gitlab.com")

storage_mode("gitlab_secure_files")

type("development") # The default type, can be: appstore, adhoc, enterprise or development
```

#### Project Access Token

次にGitLabのプロジェクトの設定からアクセストークンを発行します。

Roleで**Maintainer**を選択してスコープには**api**の権限さえついていれば良いようです。

発行した値を覚えておきましょう。

このまま`fastlane match development`で発行してもよいのですがそのままやると環境変数が読み込めないのでMakefileと.envを作成します。

```makefile
include .env

.PHONY: match
match:
	fastlane match development
```

> AppStore用の証明書が欲しい場合は`fastlane match appstore`とするように

また、.envは以下のようにします。

```zsh
PRIVATE_TOKEN=YOUR_NEW_TOKEN
```

ここまでできると以下のようなディレクトリ構造になっています。

```zsh
.
├── fastlane/
│   ├── Appfile
│   ├── Fastfile
│   └── Matchfile
├── TestApp/
├── TestApp.xcodeproj/
├── TestAppTests/
├── TestAppUITests/
├── Gemfile
├── Gemfile.lock
├── Makefile
└── .env
```

この状態で`make match`を実行すると開発環境用のプロビジョニングが作成できます。

GitLabのプロジェクトページをひらいて**Settings > CI/CD > Secure Files**にファイルが作成されていれば成功です。

### Xcode

このままだと自動署名が実行されてしまうのでTestApp.xcodeprojをひらいて**Automatically manage signing**のチェックを外します。

外したらProvisioning Profileから`match Development`と表示されているものを選択します。

二つあると思うのですが、多分どっちを選んでも大丈夫です。

### Fastfile

ここで`fastlane/Fastfile`をひらいてみます。

```ruby
default_platform(:ios)

platform :ios do
  desc "Push a new beta build to TestFlight"
  lane :beta do
    increment_build_number(xcodeproj: "TestApp.xcodeproj")
    build_app(scheme: "TestApp")
    upload_to_testflight
  end
end
```

こんな感じの内容になっていると思うのでこれを以下のように編集します。

```ruby
default_platform(:ios)

platform :ios do
  desc "Push a new build to TestFlight"
  lane :beta do
    setup_ci
    match(type: 'appstore', readonly: is_ci)
    app_store_connect_api_key
    increment_build_number(
      build_number: latest_testflight_build_number(initial_build_number: 1) + 1,
      xcodeproj: "TestApp.xcodeproj"
    )
    build_app(scheme: "TestApp")
    upload_to_testflight
  end
end
```

こうすることでビルド番号を上げながらTestFlightにアップロードができます。

> バージョニングを自動でするためには**Apple Generic Versioning**が有効化されている必要があります

有効化するためには[iOSアプリ開発で面倒なことを解決していく](https://qiita.com/ararajp/items/d9c5d296cc6470066509#increment_build_number)がわかりやすいので参考にしてください。

バージョンも`x.x.x`の形式になるようにしましょう。

### .gitlab-ci.yml

最後にこれらをソースコードがプッシュされた段階で実行されるようにします。

> `.gitlab-ci.yaml`とすると正しく認識されないので必ず拡張子は`.yml`にすること

```yaml
stages:
  - build
  - beta

cache:
  key:
    files:
      - Gemfile.lock
  paths:
    - vendor/bundle

build_ios:
  image: macos-13-xcode-14
  stage: build
  script:
    - bundle check --path vendor/bundle || bundle install --path vendor/bundle --jobs $(nproc)
    - bundle exec fastlane build
  tags: 
    - saas-macos-medium-m1

beta_ios:
  image: macos-13-xcode-14
  stage: beta
  script:
    - bundle check --path vendor/bundle || bundle install --path vendor/bundle --jobs $(nproc)
    - bundle exec fastlane beta
  tags: 
    - saas-macos-medium-m1
  when: manual
  allow_failure: true
  only:
    refs:
      - master
```

また、`.env`がプッシュされないように`.gitignore`を作成します。

これは[GitHubのSwift向けテンプレート](https://github.com/github/gitignore/blob/main/Swift.gitignore)を流用しました。

```zsh
# Xcode
#
# gitignore contributors: remember to update Global/Xcode.gitignore, Objective-C.gitignore & Swift.gitignore

## User settings
xcuserdata/

## compatibility with Xcode 8 and earlier (ignoring not required starting Xcode 9)
*.xcscmblueprint
*.xccheckout

## compatibility with Xcode 3 and earlier (ignoring not required starting Xcode 4)
build/
DerivedData/
*.moved-aside
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3

## Obj-C/Swift specific
*.hmap

## App packaging
*.ipa
*.dSYM.zip
*.dSYM

## Playgrounds
timeline.xctimeline
playground.xcworkspace

# Swift Package Manager
#
# Add this line if you want to avoid checking in source code from Swift Package Manager dependencies.
# Packages/
# Package.pins
# Package.resolved
# *.xcodeproj
#
# Xcode automatically generates this directory with a .xcworkspacedata file and xcuserdata
# hence it is not needed unless you have added a package configuration file to your project
# .swiftpm

.build/

# CocoaPods
#
# We recommend against adding the Pods directory to your .gitignore. However
# you should judge for yourself, the pros and cons are mentioned at:
# https://guides.cocoapods.org/using/using-cocoapods.html#should-i-check-the-pods-directory-into-source-control
#
# Pods/
#
# Add this line if you want to avoid checking in source code from the Xcode workspace
# *.xcworkspace

# Carthage
#
# Add this line if you want to avoid checking in source code from Carthage dependencies.
# Carthage/Checkouts

Carthage/Build/

# Accio dependency management
Dependencies/
.accio/

# fastlane
#
# It is recommended to not store the screenshots in the git repo.
# Instead, use fastlane to re-generate the screenshots whenever they are needed.
# For more information about the recommended setup visit:
# https://docs.fastlane.tools/best-practices/source-control/#source-control

fastlane/report.xml
fastlane/Preview.html
fastlane/screenshots/**/*.png
fastlane/test_output

# Code Injection
#
# After new code Injection tools there's a generated folder /iOSInjectionProject
# https://github.com/johnno1962/injectionforxcode

iOSInjectionProject/

# Envidonment Variables
.env
.env.*
!.env.example
```

### SaaS runners on macOS

とはいえこれは実際にはテストできません。

何故ならSaaSのGitLab runnersは[プランがプレミアム以上でないと実行できない](https://docs.gitlab.com/ee/ci/runners/saas/macos_saas_runner.html)ためです。

なので本当に動くかどうかはわからないのですが、概ねこんな感じで書けると思います。

#### Local GitLab Runner

ということでローカルで実行してみます。

ないならセルフホストで動かせばいいじゃないかということですね。

```zsh
brew install gitlab-runner
```

のコマンドでインストールしてみます。バージョンを確認したら16.7でした。

```zsh
$ gitlab-runner -v

Version:      16.7.0
Git revision: 102c81ba
Git branch:   16-7-stable
GO version:   go1.20.10
Built:        2023-12-21T17:01:33+0000
OS/Arch:      darwin/arm64
```

SasSで実行する前提でイメージが指定されているのでそれを無効化します。

```yaml
image: ruby:latest

stages:
  - build
  - beta

cache:
  key:
    files:
      - Gemfile.lock
  paths:
    - vendor/bundle

build_ios:
  stage: build
  script:
    - bundle check --path vendor/bundle || bundle install --path vendor/bundle --jobs $(nproc)
    - bundle exec fastlane build
  tags: 
    - saas-macos-medium-m1

beta_ios:
  stage: beta
  script:
    - bundle check --path vendor/bundle || bundle install --path vendor/bundle --jobs $(nproc)
    - bundle exec fastlane beta
  tags: 
    - saas-macos-medium-m1
  when: manual
  allow_failure: true
  only:
    refs:
      - master
```