---
title: "[Hack] 同じシードで練習したい方向けのIPSパッチファイル"
published: 2021-02-04
category: Nintendo
tags: [Salmon Run]
---

## SeedHack のパッチファイル

そのままコードを公開するとめんどくさいことになりそうなので、5.3.1 向けの IPS パッチファイルとして公開します。

まあこれも復号可能なのでバイナリを眺めて意味がわかる人であれば、元のコードは復元できるのですが、そこまでできる人ならそもそもアドレス移植もできるだろっていうことで。

WAVE の内容がどんなものかを知りたい人は以下の URL からシードを`0x`抜きでコピペすれば調べることができます。

[LanPlay Records](https://salmonrun-records.netlify.app/ocean/?seed=0xFACE4ECC)

### 満潮キンシャケ探し + 満潮ハコビヤ + 満潮キンシャケ探し

@[youtube](https://www.youtube.com/watch?v=0P9IlQ-9ciM)

404 納品を達成したときのシードが適用されます。頑張れば 410 納品くらいまでは伸ばせると思うので誰か頑張ってみてください。

[222422（0xFACE4ECC）](https://cdn.discordapp.com/attachments/806624731741814866/806625784185880576/CF91518983FCB18D11B0FF1DAC22300F.ips)

### イベントなし全回収 198 納品

@[youtube](https://www.youtube.com/watch?v=4L1HLOGhqRs)

今まで遊んだ昼のみ WAVE の中で最も簡単です。このシードだけで全回収が三回達成されているので、そこそこ上手いなら誰でも 198 納品できます。

[202000（0xF8AC89CA）](https://cdn.discordapp.com/attachments/806624731741814866/806624787169804288/CF91518983FCB18D11B0FF1DAC22300F.ips)

## パッチファイルの使い方

`sdmc:/atmosphere/exefs_patches`に新たに適当にフォルダ（今回は SeedHack-531 とする）を作成します。

作成したらそのフォルダの中に適用したいシードのパッチをコピーします。

すると、`sdmc:/atmosphere/exefs_patches/seedHack-531/CF91518983FCB18D11B0FF1DAC22300F.ips`という風になると思います。

これでパッチの適用は完了です。

シード固定を解除したい場合はパッチ（IPS ファイル）を削除してください。

記事は以上。
