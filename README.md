# ECS and ECR のデモ

## これなに？

- ECS と ECR のデモを rake で叩きやすくしたもの
- 要 ecs-cli / aws-sdk

## 出来ること

- ECS クラスタを操作する等
- ecs-cli で作成される AutoScaling の設定を制御する
- 詳細については[こちら](https://speakerdeck.com/inokappa/amazon-ecs-to-amazon-ecr-chao-gai-yao-shi-jian-gaatutara-demo)のスライドの 64 ページからを御覧ください

## 準備

- 以下のように config.yml を設定する

```yml
:ssh_user_name: "ec2-user"    # SSH ユーザー名を指定する(Amazon Linux の場合には ec2-user )
:key_path: "keyname.pem"      # SSH キーのパスを指定する
:key_name: "keyname"          # SSH キー名を指定する
:ecs_cluster_name: "ecs-demo" # ECS クラスタ名を指定
:region: "ap-northeast-1"     # ECS クラスタを展開するリージョンを指定
:instance_type: "t2.micro"    # ECS コンテナインスタンスのインスタンスタイプを指定
:instance_count: 1            # ECS コンテナインスタンスの初期状態の台数を指定
:desire_instance_count: 3     # 最大何台のコンテナインスタンスを追加するか指定
:vpc_id: "vpc-xxxxxxxx"       # VPC ID を指定する
:subnets:                     # 指定した VPC ID のサブネットを指定
  - "subnet-xxxxxxx"
  - "subnet-xxxxxxx"
:azs:                         # Availability Zone を指定
  - "ap-northeast-1a"
  - "ap-northeast-1c"
:sg_ids:                      # Security Group を指定
  - "sg-xxxxxxxx"
:ecs:
  :cluster_name: "xxxxxxxxx"
  :service:
    :deployment_max_percent: 100
    :deployment_min_healthy_percent: 0
:ecr:
  :registry: "xxxxxxxxxxxxx.dkr.ecr.us-east-1.amazonaws.com"
  :login_file: "login_file"
```

Security Group については ecs-cli で複数の Security Group ID を指定すると、全ての指定が無視されてしまうという状況なので `sg_ids` を指定してもクラスタ構築時には反映されないので注意。

## tasks

```sh
rake ecs:as:get_group_name                      # Auto Scaling グループ名を取得する
rake ecs:as:put_down_policy                     # スケールインする為のポリシーを設定する
rake ecs:as:put_up_policy                       # スケールアウトする為のポリシーを設定する
rake ecs:as:update_as_group                     # Auto Scaling Group の設定を更新する(max_size を任意の値に変更する)
rake ecs:cluster:configure                      # ECS クラスタを初期化する
rake ecs:cluster:down                           # ECS クラスタを停止して削除する
rake ecs:cluster:launch                         # ECS クラスタを起動する
rake ecs:cluster:list:clusters                  # ECS クラスタの一覧を確認する
rake ecs:cluster:list:instances                 # ECS コンテナインスタンスの一覧を確認する
rake ecs:cluster:scale                          # ECS クラスタ内のコンテナインスタンス数を調整する(環境変数 INSTANCE_COUNT で起動するインスタンス数を指定する)
rake ecs:compose:service:ecs-app:ps             # Service Task ecs-app のコンテナ一覧を確認する
rake ecs:compose:service:ecs-app:scale          # Service Task ecs-app をスケールアウトする(環境変数 DESIRE_COUNT で起動するコンテナ数を指定する)
rake ecs:compose:service:ecs-app:up             # Service Task ecs-app を起動する
(snip)
rake ecs:docker:ecs-app:build                   # ecs-app のコンテナイメージをビルドする
rake ecs:docker:ecs-app:push                    # ecs-app を ECR に push する
rake ecs:compose:service:ecs-registrator:ps     # Service Task ecs-registrator のコンテナ一覧を確認する
rake ecs:compose:service:ecs-registrator:scale  # Service Task ecs-registrator をスケールアウトする(環境変数 DESIRE_COUNT で起動するコンテナ数を指定する)
rake ecs:compose:service:ecs-registrator:up     # Service Task ecs-registrator を起動する
rake ssh:config:generate                        # ssh config を生成する
rake ssh:config:init                            # 作成済みの ssh config を初期化する
```

## tips

### Task Definition の追加

`ecs-*` というディレクトリを作成して `task.yml` という名前のファイルに Docker Compose 定義を記載することで、この rake タスク経由で task や service を起動出来る。

```sh
$ mkdir ecs-foo
$ cat ecs-foo/task.yml
foo_task:
  cpu_shares: 128
  mem_limit: 262144000
  image: busybox
  command: echo "hello ecs and ecr"
$ rake -T
(snip)

rake ecs:docker:ecs-foo:build                   # ecs-foo のコンテナイメージをビルドする
rake ecs:docker:ecs-foo:push                    # ecs-foo を ECR に push する
rake ecs:compose:service:ecs-foo:ps             # Service Task ecs-foo のコンテナ一覧を確認する
rake ecs:compose:service:ecs-foo:scale          # Service Task ecs-foo をスケールアウトする(環境変数 DESIRE_COUNT で起動するコンテナ数を指定する)
rake ecs:compose:service:ecs-foo:up             # Service Task ecs-foo を起動する

(snip)
```
