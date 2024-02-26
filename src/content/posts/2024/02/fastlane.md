---
title: Fastlaneを理解しよう 
published: 2024-02-25
description: Fastlaneでアプリを自動で配信できる環境の整え方について 
category: Tech
tags: [macOS, Fastlane, Xcode, iOS]
---

## Fastlane vs Xcode Cloud

iOS開発においてCI/CDを実現するための仕組みとしてはFastlaneが有名ですが、最近はXcode Cloudという仕組みも出てきてどちらを採用すべきなのかを考えていました。

なので今回はFastlaneとXcode Cloudを比較してどっちが良いのかまとめてみようと思います。

### Fastlane