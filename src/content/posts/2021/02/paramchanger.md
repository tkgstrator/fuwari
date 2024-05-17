---
title: スプラトゥーン2のパラメータ置換ツールをアップデートした
published: 2021-02-26
category: Nintendo
tags: [Splatoon2, Python]
---

## ParamHash

[ParamHash](https://github.com/tkgstrator/ParamHash)

解説すると長くなるのだが、スプラトゥーン 2 では XML のパラメータファイルが BPRM、BYML、BYAML といったファイルに暗号化されている。

この暗号化自体は[The4Dimension](https://github.com/exelix11/TheFourthDimension)というツールを使えば復号できるのだが、パラメータ名が CRC32 でハッシュ化されているためそのままでは読むことができない。

また、CRC32 はハッシュであり暗号化ではないため一意の復号もできない。そこで、スプラトゥーン 2 で定義されているパラメータ名を片っ端から抽出して、それを CRC32 でハッシュ化し、ハッシュリストをつくることにした。

### パラメータ名の抽出とハッシュ化

やり方は全くわからなかったので、[@shadowninja108](https://twitter.com/shadowninja108)氏に協力を依頼した。

すると一時間も経たずに 5.4.0 向けのパラメータファイルを抽出してくれた、やはり天才である。

あとはそのパラメータファイルを CRC32 でハッシュ化し、それを CSV として出力すれば良い。

```python
import zlib

with open(INPUTFILE, mode="r") as f:
with open("param.csv", mode="w") as w:
for line in f:
param = line.strip()
hash = format(zlib.crc32(param.encode("ascii")) & 0xFFFFFFFF, "x")
param = param.split(".")
w.write(f"{hash},{param[0[}\\n")
```

それ自体は上のようなコードで実装できる。とても簡単である。

これで全てのハッシュを出力できたかと思ったのだが、shadowninja108 氏の手法では一部のパラメータを抽出し損ねているようでサーモンランに関するパラメータが全く見つからなかった。

そこで[@leanyoshi](https://twitter.com/leanyoshi)氏が公開しており旧バージョンの ParamHash でも使っていた CSV ファイルを組み合わせることにした。

重複するものを削除して全部で 11159 通りの[パラメータとハッシュのリスト](https://github.com/tkgstrator/ParamHash/blob/python/param.csv)が完成した。

## 使い方

使い方についてはリリースページを見ていただきたいのだが、The4Dimension と組み合わせることで BPRM、BYML、BYAML を XML に復号し、復号した XML のハッシュをパラメータ名に置換するところまでを自動で行ってくれる。

また、逆変換にも対応しており、置換された XML をハッシュ化し、暗号化することにも対応した。

なので、このツールを使えば編集するファイルはパラメータ名に置換された XML ファイルだけということになる。

いままで「XML に復号」「XML のハッシュを置換」「置換した XML と比較して置換前 XML を編集」「置換前 XML を暗号化」という作業が必要だったのが、「置換済み XML に復号」「置換済み XML を編集」「置換済み XML を暗号化」という風に一つ作業を減らすことができるようになった。

ちまちまパラメータ名を比較しながら作業しなくて良いのでミスも減るし、全てのファイルを一度に変換できるので楽になったはずだ。

### おまけ

Python って本当に楽、あと焼き肉食べたい。

で、気付いたのだがパラメータ名からハッシュにする際に型を無視してしまっているので逆変換はできないことに気付いた（ダメじゃん

なので逆変換はしないでください！！

記事は以上。
