---
title: AWSのPolicy周り何もわからない 
published: 2024-09-30
description: AWSでECSとECRを使うまでの手順
category: Tech
tags: [ECS, ECR, AWS]
---

## AWS何もわからない

何もわからないけれど、解決するまでに至った手順をとりあえず書いておきます。

不要なことや、余計な権限があるかもしれないけれど今は許して。

### Trust Policy

とりあえずECSとECRにアクセスするためのトラストポリシーを作成する。IAMポリシーとは別物らしいのだけれど全然わからない。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

ChatGPTにいわれるがまま、上のように書いたけれどそもそもほぼデフォルト感があるのでわざわざ作る必要がなかった気もする。

### IAMポリシー

ChatGPTにきいたら`ECSClusterECRAccessPolicy`っていう名前がいいよといわれたので、いわれるがままに作成。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeleteCluster",
        "ecs:DescribeClusters",
        "ecs:UpdateCluster",
        "ecs:ListClusters",
        "ecs:CreateService",
        "ecs:DeleteService",
        "ecs:DescribeServices",
        "ecs:UpdateService",
        "ecs:ListServices",
        "ecs:RegisterTaskDefinition",
        "ecs:DeregisterTaskDefinition",
        "ecs:DescribeTaskDefinition",
        "ecs:ListTaskDefinitions",
        "ecs:RunTask",
        "ecs:StopTask",
        "ecs:ListTasks",
        "ecs:DescribeTasks",
        "ecs:UpdateServicePrimaryTaskSet",
        "ecs:CreateTaskSet",
        "ecs:DeleteTaskSet",
        "ecs:DescribeTaskSets"
      ],
      "Resource": "*"
    }
  ]
}
```

こうやるとECSとECRのすべてのリソースに対して上記の権限がついてしまうので、若干強すぎる気がしなくもない。

で、ECRにイメージをプッシュするだけでもとりあえず、

```json
{
  "ecr:InitiateLayerUpload",
  "ecr:UploadLayerPart",
  "ecr:CompleteLayerUpload",
  "ecr:PutImage"
}
```

あたりが必要だったのだが、ここまで細かく分ける必要はあるのかなという印象。