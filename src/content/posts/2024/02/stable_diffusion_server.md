---
title: Stable Diffusion WebUI+DockerをUbuntu Serverで動かす 
published: 2024-02-06
description: Docker版のStable Diffusion WebUIでTensorRTを確実に動かすための方法
category: Programming
tags: [Ubuntu, Stable Diffusion, TensorRT]
---

## 概要

Stable Diffusion WebUIをDockerで動かすというのは前々からある試みである。

有名所だと[stable-diffusion-webui-docker](https://github.com/AbdBarho/stable-diffusion-webui-docker)が頻繁に更新されている。

で、以前はこれをUbuntu DesktopからDocker Desktopを導入して環境構築していたのだが、よく考えたら別にDesktop環境は要らないので最も軽いUbuntu Serverで動かせばいいじゃないかという話になった。

> ちゃんと書いたつもりですが、ミスっていたらごめんなさい

### Docker

まず、不要なものがインストールされている可能性があるので全て削除する。

```zsh
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
```

削除したらパッケージを登録する。

```zsh
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

最後にインストールをする。

```zsh
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

ここで`docker info`で`Permission denied`が表示される場合は権限が足りていないので、

```zsh
sudo usermod -aG docker $USER
```

現在のユーザーをdockerグループに追加することでsudoなしでdockerが動かせるようになる。

そしてコンピュータを再起動します。

> [Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/)

### Nvidia Container Runtime

DockerコンテナからはデフォルトではGPUが認識できないのでこれを入れます。

```zsh
sudo apt-get install nvidia-container-runtime
curl -s -L https://nvidia.github.io/nvidia-container-runtime/gpgkey |   sudo apt-key add -
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-container-runtime/$distribution/nvidia-container-runtime.list |   sudo tee /etc/apt/sources.list.d/nvidia-container-runtime.list
sudo apt-get update
sudo apt-get install nvidia-container-runtime
service docker restart
```

> [docker: Error response from daemon: could not select device driver "" with capabilities: [[gpu]]. ERRO[0000] error waiting for container: context canceledを解決する](https://qiita.com/murakamixi/items/5f6cf5c1ab6b4090f64a)

## 導入

Stable Diffusion WebUIはDockerを使って導入します。

環境が汚れないのでこちらの方がよいです。

```zsh
git clone https://github.com/AbdBarho/stable-diffusion-webui-docker.git
```

デフォルトの状態だとTensorRTを有効化するとバグって動かなくなってしまうので、TensorRTのextensionのインストールがうまくいくように修正します。

> 最新のコミットのバグ？

`stable-diffusion-webui-docker/services/AUTOMATIC1111/Dockerfile`を編集します。

```docker
# TensorRT
RUN pip install --pre --extra-index-url https://pypi.nvidia.com tensorrt==9.0.1.post11.dev4
RUN pip install polygraphy --extra-index-url https://pypi.ngc.nvidia.com
```

上の三行を後ろの方のどっかに適当に付け加えます。私は以下のようにしました。

```docker
RUN --mount=type=cache,target=/root/.cache/pip \
  pip install pyngrok xformers==0.0.23.post1 \
  git+https://github.com/TencentARC/GFPGAN.git@8d2447a2d918f8eba5a4a01463fd48e45126a379 \
  git+https://github.com/openai/CLIP.git@d50d76daa670286dd6cacf3bcd80b5e4823fc8e1 \
  git+https://github.com/mlfoundations/open_clip.git@v2.20.0

# TensorRT
RUN pip install --pre --extra-index-url https://pypi.nvidia.com tensorrt==9.0.1.post11.dev4
RUN pip install polygraphy --extra-index-url https://pypi.ngc.nvidia.com

# there seems to be a memory leak (or maybe just memory not being freed fast enough) that is fixed by this version of malloc
# maybe move this up to the dependencies list.
RUN apt-get -y install libgoogle-perftools-dev && apt-get clean
ENV LD_PRELOAD=libtcmalloc.so
```

これで保存したら以下のコマンドで起動します。

このようにすることでTensorRTの動作に必要なパッケージをTensorRTインストール時ではなくあらかじめStable Diffusion WebUIにインストールすることができます。もちろん、TensorRTを使わないつもりならこの設定は不要です。

最初は時間がかかりますが、二回目以降はすぐに立ち上がります。

```zsh
docker compose --profile download up --build
docker compose --profile auto up --build
```

記事は以上。