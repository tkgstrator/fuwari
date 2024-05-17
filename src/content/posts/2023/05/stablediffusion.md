---
title: M1/M2でStable Diffusionを動かす方法について
published: 2023-05-08
description: これだけ読んでおけば大丈夫な解説内容にしたい
category: Tech
tags: [Stable Diffusion]
---

## Stable Diffusion

今更すぎるが、登場時はまだまだだなあと思っていた画像生成 AI が随分なレベルにまで上がってきたので触れておくことにしました。

基本的に SD は RTX シリーズで動かすのが盤石なのですが、M1 シリーズもそれなりに GPU コアがあり、一説によると M1 Ultra は RTX2060 程度の性能はあるらしいので試してみることにしました。

### まずはじめに

M1/M2 Stable Diffusion で検索すると CoreML を利用したツールを紹介されることがありますが、CoreML には画像サイズを変更できなかったり、やたらと生成した画像のクオリティが低かったりと問題があったのでおすすめしません。

Stable Diffusion を簡単に利用したいのであれば WebUI 一択で、他の選択肢はありません。

## Stable Diffusion WebUI

[Stable Diffusion WebUI](https://github.com/AUTOMATIC1111/stable-diffusion-webui)はここから入手できます。M1/M2 での導入方法も[ここ](https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki/Installation-on-Apple-Silicon)に書いてあるので、基本的にはこれをそのまま実行するだけで良いです。

### パフォーマンス向上

[How to improve performance on M1 / M2 Macs](https://github.com/AUTOMATIC1111/stable-diffusion-webui/discussions/7453)でパフォーマンス改善が載っていますが、まあ若干上がったかなという感じです。

以下のように`webui-user.sh`を書き換えます。

```sh
#!/bin/bash
#########################################################
# Uncomment and change the variables below to your need:#
#########################################################

# Install directory without trailing slash
#install_dir="/home/$(whoami)"

# Name of the subdirectory
#clone_dir="stable-diffusion-webui"

# Commandline arguments for webui.py, for example: export COMMANDLINE_ARGS="--medvram --opt-split-attention"
export COMMANDLINE_ARGS="--skip-torch-cuda-test --upcast-sampling --no-half-vae"

# python3 executable
#python_cmd="python3"

# git executable
#export GIT="git"

# python3 venv without trailing slash (defaults to ${install_dir}/${clone_dir}/venv)
#venv_dir="venv"

# script to launch to start the app
#export LAUNCH_SCRIPT="launch.py"

# install command for torch
# export TORCH_COMMAND="pip install torch==1.12.1+cu113 --extra-index-url https://download.pytorch.org/whl/cu113"
export TORCH_COMMAND="pip install --pre torch==2.0.0.dev20230506 torchvision==0.15.0.dev20230506 -f https://download.pytorch.org/whl/nightly/cpu/torch_nightly.html

# Requirements file to use for stable-diffusion-webui
#export REQS_FILE="requirements_versions.txt"

# Fixed git repos
#export K_DIFFUSION_PACKAGE=""
#export GFPGAN_PACKAGE=""

# Fixed git commits
#export STABLE_DIFFUSION_COMMIT_HASH=""
#export TAMING_TRANSFORMERS_COMMIT_HASH=""
#export CODEFORMER_COMMIT_HASH=""
#export BLIP_COMMIT_HASH=""

# Uncomment to enable accelerated launch
#export ACCELERATE="True"

# Uncomment to disable TCMalloc
#export NO_TCMALLOC="True"

###########################################
```

Torch は 20230507 のものもリリースされているのですが、それでは`webui.sh`が起動しなくなりました。

なのでとりあえず一つ前の 20230506 を利用しています。

## パフォーマンス

### 環境

- M1 Ultra(48Core GPU)
- Stable Diffusion WebUI(1.1.1 5ab7f213bec2f816f9c5644becb32eb72c8ffb89)
- Python 3.10.11
- torch 2.0.0
- xformers N/A
- gradio 3.28.1
- checkpoint cbfba64e66

### 設定

|   パラメータ    |     値     |
| :-------------: | :--------: |
| Sampling method |     -      |
| Sampling steps  |     22     |
|      Width      |    512     |
|     Height      |    768     |
|   Batch count   |     1      |
|   Batch size    |     1      |
|    CFG Scale    |     7      |
|      Seed       | 1031604376 |
|     Script      |    None    |

メソッドには色々あるので、それを変えてみて出力画像を確認してみます。

### プロンプト

以下の呪文を使います。

#### ポジティブ

`masterpiece, (best quality), (ultra-detailed:1.4), high resolution, original characters, depth of field, solo focus, wearing black glasses, a high school student girl, cute adorable look, small breasts, soft delicate beautiful attractive face with expressive purple eyes, cowgirl position, disheveled clothing, close up, semi long straight hair, dark red brown, dynamic pose, cute adorable look, wearing a school uniform with blue tie, short sleeve, nsfw, bob cut hair, embarrassed, cowgirl position, in the nostalgic library`

#### ネガティブ

`EasyNegative (worst quality low quality:1.4) text, bad_anatomy, bad_hands`

### 結果

シードが同じため殆どの場合でほぼ同じ画像が生成されましたが、サンプリングメソッドの違いによって大雑把に三パターンの画像に分かれました。

|     メソッド      | 生成時間 | パターン |
| :---------------: | :------: | :------: |
|      Euler a      |  12.62s  |    A     |
|       Euler       |  12.53s  |    B     |
|        LMS        |  12.48s  |  不明瞭  |
|       Heun        |  23.71s  |    B     |
|       DPM2        |  23.69s  |    B     |
|      DPM2 a       |  23.76s  |  不明瞭  |
|    DPM++ 2S a     |  23.65s  |    B+    |
|     DPM++ 2M      |  12.53s  |    B     |
|     DPM++ SDE     |  25.63s  |    A     |
|     DPM fast      |  12.47s  |  不明瞭  |
|   DPM adaptive    | 102.49s  |    A     |
|    LMS Karras     |  12.47s  |    B     |
|    DPM2 Karras    |  23.73s  |    B     |
|   DPM2 a Karras   |  23.65s  |    C     |
| DPM++ 2S a karras |  23.81s  |    B+    |
|  DPM++ 2M karras  |  12.52s  |    A     |
| DPM++ SDE Karras  |  25.52s  |    A     |
|       DDIM        |  16.35s  |    B     |
|       PLMS        |  12.24s  |  不明瞭  |
|       UniPC       |  15.26s  |  不明瞭  |
