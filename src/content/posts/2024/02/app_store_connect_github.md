---
title: macOSのVirtual MachineをmacOS上に立てる
published: 2024-02-27
description: 'macOSのVirtual MachineをmacOS上に立ててGitHub Actionsを実行します'
image: ''
tags: [Xcode, macOS]
category: Tech
draft: false 
---

## GitHub + AppStoreConnect

前回はGitLab CIでAppStoreConnectにデプロイするための手順を解説しましたが、GitLabだとmacOSのランナーが無料ではないのでGitHubでも同様のことができるかをチェックしようと思います。

参考にしたのは[GitHub ActionsのSelf-hosted RunnerをM1 Macで構築して、iOSのCI/CDが快適になった話](https://zenn.dev/tellernovel_inc/articles/57c19694dfdf44)及び[Self-hosted Apple Silicon GitHub Runner](https://tome.app/tome/self-hosted-apple-silicon-github-runner-cl142srti2504584j3sa5snuzfc)です。

当初はDockerで動かすとホストマシンがmacOSであったとしてもUbuntuで強制的に動いてしまうかと思ったのですがVMを利用することでこの制限を回避できるようです。

> ただVMを使うとフリーズするという現象もあったようなのでどちらを選択するかはよく吟味する必要がありますね

## 環境構築

とりあえず今回は色々試したいのでVM上で動作させることを考えます。

VMで動作させることの一番のメリットはホストマシンの環境を汚さない、ということにあります。

なんかおかしいなとなればVMをふっ飛ばせばいいだけなので、ホストマシンのクリーンインストールをするよりも楽です。

手順については[Running macOS in a virtual machine on Apple silicon](https://developer.apple.com/documentation/virtualization/running_macos_in_a_virtual_machine_on_apple_silicon)を読んでいきましょう。

よくわからないのですがApple Silicon上でmacOSをVMで動かすらしいです。Dockerを動かすとApple SiliconはディスコのI/Oの関係かなにかでやたらとパフォーマンスが下がってしまうのですがApple謹製のこのツールならそのあたりの制限はクリアされているのか気になりますね。

Mac miniで動かしている人が多いのですが、私の家にはウーロン茶をかけてディスプレイが映らなくなったMacbook Pro M1 Proモデルが眠っているのでこれを有効活用しましょう。

ディスプレイが映らないMacbook Proといちいち接続を切り替えて作業するのがめんどくさいのでリモートデスクトップを利用します。

> 意気揚々と試そうとしたらそもそもXcodeが入っておらず、Xcodeを入れようとしたらMonteryだったのでインストールもできなかったのでSonomaにアップデートするところから始めました

### Xcode

インストールするのにめちゃくちゃ時間がかかりそうだったのでとりあえず手元のこのマシンで実行してみます。

プロジェクトを開くと**macOSVirtualMachineSampleApp**というのが表示されます。

スキーマがデフォルトだと**InstallationTool-Objective-C**になっているので**InstallationTool-Swift**に切り替えます。

`Swift/Common/MacOSVirtualMachineConfigurationHelper.swift`にVMの設定が書かれているのでここを変更します。

```swift
struct MacOSVirtualMachineConfigurationHelper {
    static func computeCPUCount() -> Int {
        let totalAvailableCPUs = ProcessInfo.processInfo.processorCount

        var virtualCPUCount = totalAvailableCPUs <= 1 ? 1 : 4 // 変更
        virtualCPUCount = max(virtualCPUCount, VZVirtualMachineConfiguration.minimumAllowedCPUCount)
        virtualCPUCount = min(virtualCPUCount, VZVirtualMachineConfiguration.maximumAllowedCPUCount)

        return virtualCPUCount
    }

    static func computeMemorySize() -> UInt64 {
        // Set the amount of system memory to 4 GB; this is a baseline value
        // that you can change depending on your use case.
        var memorySize = (16 * 1024 * 1024 * 1024) as UInt64 // 4GB -> 16GB
        memorySize = max(memorySize, VZVirtualMachineConfiguration.minimumAllowedMemorySize)
        memorySize = min(memorySize, VZVirtualMachineConfiguration.maximumAllowedMemorySize)

        return memorySize
    }
    ...
```

デフォルトだとホストマシンが利用できるCPU数-1が利用されるので、私の場合は適当に4とか8にしておきます。

メモリもデフォルトだと4GBしか利用できないので16GB使えるようにします。

`Swift/InstallationTool/MacOSVirtualMachineInstaller.swift`にはディスクサイズが定義されているのでこれも変更します。

デフォルトでは128GBですが、Xcodeを複数バージョン入れていると全然足りないので256GBに変更します。

```swift
    // Create an empty disk image for the virtual machine.
    private func createDiskImage() {
        let diskFd = open(diskImageURL.path, O_RDWR | O_CREAT, S_IRUSR | S_IWUSR)
        if diskFd == -1 {
            fatalError("Cannot create disk image.")
        }

        // 128 GB disk space.
        var result = ftruncate(diskFd, 256 * 1024 * 1024 * 1024) // 128GB -> 256GB
        if result != 0 {
            fatalError("ftruncate() failed.")
        }

        result = close(diskFd)
        if result != 0 {
            fatalError("Failed to close the disk image.")
        }
    }
}
```

### 起動

![](https://media1.tenor.com/m/p0kz7NOqxTkAAAAC/kaito-typing.gif)

> ココだけの話、エンジニアに憧れたのは涼宮ハルヒの憂鬱で射手座の日を見たのが割と影響大きかったりします、長門さんかっこいい

この状態で起動すると**Restore image download progress**がズラーっと表示されます。

macOSのイメージをダウンロードしていると思われるのですが、バージョンは不明です。

> 何も指定していないのでホストマシンと同じなんじゃないかと思っています。

で、起動してると別のマシンでもSonomaへのアップデートをしていたためネットワークに負荷をかけすぎたのかイメージのダウンロードに失敗してビルドがコケました。

再度実行してもエラーが表示されるだけで先に進まないのですが、ドキュメントを読むと`~/VM.bundle`が作成されると書いてあるので作成されていた0バイトのVMのデータを削除します。

すると再実行でまたイメージのダウンロードが始まり、完了するとインストールが始まります。ダウンロードに比べてインストールはすぐ終わります。

最終的に151.98GBとかいう超巨大なファイルが作成されました。なので256GBしかストレージがないマシンだと実行できないと思います。

ここでXcodeからスキーマを`macOSVirtualMachineSampleApp-Swift`に変更して実行します。

すると起動するはずです。

### 設定

起動したら初期設定を始めるのですがApple IDではサインインしないようにしましょう（というか何故かできなかった

セットアップが終わったらXcodeをインストールします。手順書ではコピーしてきたほうが良いと書いてあるのですが、Xcodesでインストールすることにします。

また、設定の共有から**Screen Sharing**と**File Sharing**を有効化しておくとよいでしょう。

ホストマシンからのファイルコピーとクリップボードのコピーには対応していないので、スクリーン共有を利用する必要があります。

### 入れておいたほうが良いもの

おすすめがあったのでこれを入れておくと幸せになれると思います。

- Homebrew
- Swiftlint
- Swiftformat
- Ruby

Rubyはfastlaneを動作させるために必要になります。

```zsh
brew install swiftlint
brew install swiftformat
brew install ruby
brew link --overwrite --force ruby
```

Rubyに関してはbrewでインストールしたあとにbrewでインストールしたものを利用するようにしないとbundle installでシステム領域に書き込もうとして大変なことになるので必ず最後のコマンドを実行しておきましょう。

```zsh
gem install bundler
```

も実行しておくと良いことがあるかもしれません。

### 注意点

XcodesでXcodeをインストールすると例えばXcode15.2は`/Applications/Xcode-15.2.0.app/Contents/Developer`というパスにインストールされます。

なので当然GitHub Actionsでバージョン指定をする場合もこれを利用するのですが、GitHub謹製のRunnerとSelf-HostedのRunnerではディレクトリが異なります。

| ランナー       | パス                           | 
| -------------- | ------------------------------ | 
| Self-Hosted    | /Applications/Xcode-15.2.0.app | 
| GitHub Actions | /Applications/Xcode_15.2.app   | 

うーん、この差異をなんとかできないかなという感じですね。

さらに言えば`xcode-select -s`は`sudo`が必須なのですが、これをやるといちいちSelf-Hostedのマシンでパスワードが要求されてイライラします。

解決したらまた追記しようと思います。

## GitHub Runner

[公式ドキュメント](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/adding-self-hosted-runners)を読むとよいです。ちょっと古いかもしれないけど大体同じです。

YAMLで指定するXcodeはインストールしておきましょう。

基本的にfastlaneでビルドすることになると思うのでRubyも必須になります。

立ち上げてジョブを投げるとちゃんとビルドできます。

Xcode15以降だとインストール時にiOS向けのSDKが入っていなかったりするので入れておきましょう。

別記事で解説したfastlaneの使い方と踏まえて無事にビルドできるようになりました！！

記事は以上。
