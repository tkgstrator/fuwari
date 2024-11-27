---
title: サーモンランの将来のシフトをカレンダーに追加する
published: 2021-05-10
description: Google Calendarで管理したいと相談を受けたので作ってみました
category: Nintendo
tags: [Splatoon2, Salmon Run]
---

## サーモンラン用カレンダー

2022 年 1 月までの全シフト情報はわかっているので、その JSON を Google Calendar API を使ってカレンダーに登録しました。

やり方は長くなるので割愛。ステージはともかく、ブキ情報は手作業でプログラムに追加したのでめんどくさかったです。

::: warning ネタバレについて

本記事ではネタバレは行いませんが、解説に使っている画像から将来のシフトの（開催時間）のみが事前にわかってしまいます。

ネタバレ NG な方はこれより先を読み進めないことを推奨します。というか、ネタバレされたくない人はそもそもこのページ開かないか。

:::



## 追加の仕方

まずは[Google Calendar](https://calendar.google.com/calendar)をひらきます。

![](https://pbs.twimg.com/media/E1Bb7bzVgAEEBRM?format=png)

左下にある「他のカレンダー」の右側にある「+」をクリックして、「URL で追加」を押します。

![](https://pbs.twimg.com/media/E1Bb-omUUAAzt4A?format=png)

URL の入力画面になるのでカレンダーを追加します。

![](https://pbs.twimg.com/media/E1BcrwZVcAISeHX?format=png)

![](https://pbs.twimg.com/media/E1BcwlPVoAMY78e?format=png)

すると無事にカレンダーに予定を全部取り込むことができました。

## 思ったこと

あれ、これせっかく色分けしたのに取り込むときに色分けされないじゃん！！！！

どうも色情報は共有できないみたいなので、分けるためにはそもそものカレンダーを分けてそれぞれの色を変更する必要がある模様。

というわけで、めんどくさかったのですがそれぞれカレンダーを分けることにしました。

## カレンダー URL

ご自由にご利用ください。

ブキやステージが英語で読みにくいぞというご意見も頂戴しておりますのでコメント欄にどうぞ（GitHub アカウントが必須ですが）

### 黄金編成

クマブキのみ支給されるシフトを追加します。

`https://calendar.google.com/calendar/ical/pjqks2o89dipedtsiolfkt27mo%40group.calendar.google.com/public/basic.ics`

### 全緑編成

全ての支給ブキがランダムのシフトを追加します。

`https://calendar.google.com/calendar/ical/9ojdd871h0bjhutscdulijib1g%40group.calendar.google.com/public/basic.ics`

### 一緑編成

支給ブキの一つがランダムのシフトを追加します。

`https://calendar.google.com/calendar/ical/vaqjrv0hk8q6lu1mo3eop4u6vg%40group.calendar.google.com/public/basic.ics`

### 通常編成

全てのブキがランダムでないシフトを追加します。

`https://calendar.google.com/calendar/ical/3krv96lvq6h23v2gu88e2cv9p4%40group.calendar.google.com/public/basic.ics`

記事は以上。


