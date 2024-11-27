---
title: Stable Diffusion WebUIで外部HDDを利用する
published: 2024-02-05
description: No description
category: Tech
tags: [Ubuntu, Stable Diffusion]
---

## 概要

Stable Diffusionを利用していると大量の生成データでSSDが埋まってしまうことがある。

うちの環境の場合WEBPを使って画像を圧縮しているとはいえ、暖房代わりに一日中生成しているとそれなりのサイズになってしまう。

そこで、外部HDDをマウントして