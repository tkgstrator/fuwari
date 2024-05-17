---
title: GitLab RunnerをECS上で動作させよう 
published: 2024-04-03
description: GitLab RunnerをECS上で立ち上げるまでのチュートリアルです 
category: Tech
tags: [AWS, ECS, Docker, GitLab]
---

## 背景

GitLab上でAWSのFargateを利用した独自のRunnerを実行させる手順になります。

普通にイメージを作成しただけだとタスクの量などに応じでスケーリングなどができないのですが、AWSのFargateを利用すればそれができます。

基本的な内容は[Autoscaling GitLab CI on AWS Fargate](https://docs.gitlab.com/runner/configuration/runner_autoscale_aws_fargate/)に準じていますが、一部古い内容になっているため手順等が異なる場合があります。

### 要件

- EC2, ECS, ECRを作成、変更できる権限を持つアカウント
- AWS VPCとサブネット
- 一つ以上のAWSのセキュリティグループ

## 環境構築

### Fargate用のコンテナイメージの作成

ここではGitLab Runnerとして動かすDockerのイメージを作成します。

どういうものかというと[Runner Images](https://github.com/actions/runner-images)のGitLabバージョンのようなものです。

色んな機能が入っていれば入っているほどよいですが、無駄な機能はあればあるだけ重いので実際に必要なものだけ入れておけばよいでしょう。

今回、必要だった機能はNode16.18.1とRuby3.3.0が動く環境でしたので、そのDockerイメージを作成します。

[Node 12.16](https://gitlab.com/aws-fargate-driver-demo/docker-nodejs-gitlab-ci-fargate/-/blob/master/Dockerfile?ref_type=heads)の例が載っていますが、イメージ自体にGitLab Runnerがインストールされている必要があります。EC2のホスト自体にもインストールされている必要があるので、混同しやすいので注意しましょう。

また、コンテナは公開鍵認証によるSSH接続を受け入れることができるようになっていなければいけません。

それがこの[docker-entrypoint.sh](https://gitlab.com/aws-fargate-driver-demo/docker-nodejs-gitlab-ci-fargate/-/blob/master/docker-entrypoint.sh?ref_type=heads)に該当する箇所になります。

要するにホストマシンからFargateが立ち上がるときに認証情報として`SSH_PUBLIC_KEY`が送られてくるので、それをちゃんと受け取れなければいけないということなのだと思います、多分。

```dockerfile
FROM gitlab/gitlab-runner:latest

ARG TINI_VERSION=v0.19.0
ENV PATH /root/.rbenv/shims:/root/.rbenv/bin:$PATH
ENV RUBYOPT -EUTF-8

COPY --from=node:16.18.1 /usr/local/bin/node /usr/local/bin/node
RUN curl -Lo /usr/local/bin/tini https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-amd64 \
  && chmod +x /usr/local/bin/tini

RUN apt-get update
RUN apt-get -y install git curl libssl-dev libreadline-dev zlib1g-dev autoconf bison build-essential libyaml-dev libreadline-dev libncurses5-dev libffi-dev libgdbm-dev openssh-server
RUN mkdir -p /var/run/sshd

EXPOSE 22

RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv
RUN echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
RUN echo 'eval "$(rbenv init -)"' >> ~/.bashrc

RUN git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build 
RUN ~/.rbenv/bin/rbenv install 3.3.0
RUN ~/.rbenv/bin/rbenv global 3.3.0

RUN ~/.rbenv/bin/rbenv exec gem install bundler

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["tini", "--", "/usr/local/bin/docker-entrypoint.sh"]
```

今回はこのようなDockerイメージを作成しました。

```sh
#!/bin/sh

if [ -z "$SSH_PUBLIC_KEY" ]; then
  echo "Need your SSH public key as the SSH_PUBLIC_KEY env variable."
  exit 1
fi

# Create a folder to store user's SSH keys if it does not exist.
USER_SSH_KEYS_FOLDER=~/.ssh
[ ! -d "$USER_SSH_KEYS_FOLDER" ] && mkdir -p $USER_SSH_KEYS_FOLDER

# Copy contents from the `SSH_PUBLIC_KEY` environment variable
# to the `${USER_SSH_KEYS_FOLDER}/authorized_keys` file.
# The environment variable must be set when the container starts.
echo $SSH_PUBLIC_KEY > ${USER_SSH_KEYS_FOLDER}/authorized_keys

# Clear the `SSH_PUBLIC_KEY` environment variable.
unset SSH_PUBLIC_KEY

# Start the SSH daemon.
/usr/sbin/sshd -D
```

Dockerfileができたらビルドを実行します。

必要かどうかはわからないのですが、実際にFargateで動かすDockerはx86_64を想定しているので、

```zsh
docker build --platform=linux/amd64 -t ruby3.3.0-node16.18.1-runner .
```

としてアーキテクチャをlinux/amd64を指定します。

### コンテナイメージをレジストリに登録

イメージが作成できたら[ECR](https://ap-northeast-1.console.aws.amazon.com/ecr/get-started)にイメージをプッシュしてレジストリとして登録します。

ここはECRから**View Push Commands**を押せばコマンドが表示されるのでそれを利用すれば良いです。

### EC2インスタンス作成

1. [EC2](https://console.aws.amazon.com/ec2/v2/home)を開く
2. Ubuntu 22.0.4(引用元では18.0.4を利用しているが流石に古いので)でインスタンスで`gitlab-runner-micro`という名前で作成する
   - キーペアの作成などがあるのでまだインスタンスの作成ボタンを押してはいけない 
3. **Configure Instance Details**を開く
4. **Number of instances**を設定する
5. **Network**でVPCを選択する
6. **Auto-assign Public IP**を有効化する
7. **IAM role**で新しいIAMロールを作成し、**AmazonECS_FullAccess**を割り当てる
   - 新しいIAMロールはここでは仮に`ec2-gitlab-runner`とする
8. [EC2](https://console.aws.amazon.com/ec2/v2/home)の画面に戻りインスタンス一覧に戻る
9.  `gitlab-runner-micro`にセキュリティグループにはSSH(22)を割り当てる
    - こうすることでSSHでマシンに接続ができるようになる
10. キーペアを作成し`ec2-gitlab-runner.pem`というファイルおwダウンロードして保存する
    - 名前は何でも良いが、一度この鍵を失うと二度とダウンロードできないので注意すること
11. インスタンスを作成するとIPv4が表示されているのでこの値をメモしよう

### GitLab Runnerのインストール

GitLabのウェブサイトからプロジェクトを開き**Settings > CI/CD**から**Setup a specifig Runner manually**を選択してURLとRegistration Tokenの値をメモする。

ダウンロードした`ec2-gitlab-runner.pem`を利用してEC2インスタンスに接続する。


インスタンスのIPv4が`aaa.bbb.ccc.ddd`であれば、

```zsh
ssh ubuntu@aaa.bbb.ccc.ddd -i ec2-gitlab-runner.pem
```

でログインができるので、ログインができたら下記のコマンドでGitLab Runnerをインストールする。

```zsh
sudo mkdir -p /opt/gitlab-runner/{metadata,builds,cache}
curl -s "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
sudo apt install gitlab-runner
```

インストールができたら、先ほどメモしたURLとRegistration Tokenを利用して、

```zsh
sudo gitlab-runner register --url **URL** --registration-token **REGISTRATION_TOKEN** --name **RUNNER_NAME** --run-untagged --executor custom -n
```

でGitLabにEC2のGitLab Runnerを登録する。

**RUNNER_NAME**自体はGitLabで識別するためだけの名前なので何でも良い(多分)ので今回は適当に`gitlab-runner-dev`とした。

次に`sudo vim /etc/gitlab-runner/config.toml`を以下のように編集する

```zsh
concurrent = 1 # ここの値は弄らない
check_interval = 0 # ここの値は弄らない

[session_server]
  session_timeout = 1800 # ここの値は弄らない

[[runners]]
  name = "gitlab-runner-dev" # ここの値は弄らない
  url = "https://gitlab.com/" # ここの値は弄らない
  token = "__REDACTED__" # ここの値は弄らない
  executor = "custom" # ここの値は弄らない
  builds_dir = "/opt/gitlab-runner/builds"
  cache_dir = "/opt/gitlab-runner/cache"
  [runners.custom]
    config_exec = "/opt/gitlab-runner/fargate"
    config_args = ["--config", "/etc/gitlab-runner/fargate.toml", "custom", "config"]
    prepare_exec = "/opt/gitlab-runner/fargate"
    prepare_args = ["--config", "/etc/gitlab-runner/fargate.toml", "custom", "prepare"]
    run_exec = "/opt/gitlab-runner/fargate"
    run_args = ["--config", "/etc/gitlab-runner/fargate.toml", "custom", "run"]
    cleanup_exec = "/opt/gitlab-runner/fargate"
    cleanup_args = ["--config", "/etc/gitlab-runner/fargate.toml", "custom", "cleanup"]
```

もしもプライベートCAを利用したセルフマネージドなインスタンスを使っている場合には、

```zsh
  [runners.custom]
    volumes = ["/cache", "/path/to-ca-cert-dir/ca.crt:/etc/gitlab-runner/certs/ca.crt:ro"]
```

を付け加えること。

次に`sudo vim /etc/gitlab-runner/fargate.toml`を実行してファイルを編集する。

```zsh
LogLevel = "info"
LogFormat = "text"

[Fargate]
  Cluster = "gitlab-runner-dev" # 要編集
  Region = "ap-northeast-1" # EC2のリージョン
  Subnet = "subnet-xxxxxx" # Networkingの項目
  SecurityGroup = "sg-xxxxxxxxxxxxx" # Securityの項目(SSHを許可しているもの)
  TaskDefinition = "ruby330-node16181-runner:1" # 要編集
  EnablePublicIP = true

[TaskMetadata]
  Directory = "/opt/gitlab-runner/metadata"

[SSH]
  Username = "root" # ubuntuじゃなくてよいのかと思わなくもない
  Port = 22
```

ここで設定する必要があるのは**[Fargate]**の五つの項目です。

ただし、現時点では**Cluster**と**TaskDefinition**の値についてはわからないので、先にそれ以外の値から埋めます。

これについてはEC2インスタンス一覧から、先ほど作成したインスタンスを表示して入力します。

Regionに関しては東京を利用しているなら`ap-northeast-1`となります。

ここまでできたら最後にFargate driverをインストールします。

```zsh
sudo curl -Lo /opt/gitlab-runner/fargate "https://gitlab-runner-custom-fargate-downloads.s3.amazonaws.com/latest/fargate-linux-amd64"
sudo chmod +x /opt/gitlab-runner/fargate
```

### ECS Fargate Clusterの作成

1. [Clusters](https://console.aws.amazon.com/ecs/home#/clusters)からクラスターを作成
2. **Infrastructure**で**AWS Fargate(serverless)**を選択
   - 引用元ではNetworking onlyを選択しろとあるが、現在の選択項目にはそんなものはない
3. 名前は`fargate.toml`で設定したものと同じ(今回の場合は)`gitlab-runner-dev`を指定する
4. 作成する
5. 作成したら**Update Cluster**を選択する
6. **Default capacity provider strategy**から`FARGATE`を選択する
7. 更新を押して保存する

### ECSタスク定義作成

1. [Task Definitions](https://console.aws.amazon.com/ecs/home#/taskDefinitions)を開く
2. Launch typeで`AWS Fargate`を選択
3. 名前は先ほど`fargate.toml`で設定したものと同じ(今回は)`ruby330-node16181-runner`を設定
   - `:1`のようなサフィックスは不要
4. ポートマッピングで22/TCPを受け付けてSSH接続できるようにします
5. 保存

## テスト

ここまでできたら設定は完了なので、適当にGitLabからジョブを割り当ててみましょう。