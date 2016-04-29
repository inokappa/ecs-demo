#
# ecs-cli のデモを実行し易くする為の Rakefile
#
# - 出来ること
#  - ECS クラスタを起動する
#   - コンテナインスタンスを起動する
#   - SG をコンテナインスタンスに付与する
#   - IAM role をコンテナインスタンスに付与する
#   - AutoScaling グループを設定する
#  - ECS クラスタを削除する
#  - AutoScaling グループの設定を変更する(max_size を変更する)
#  - Scaling Policy を設定する
#  - コンテナインスタンスに ssh でアクセスする為の ssh config を設定する
#  - コンテナインスタンスに ssh でアクセスする
#

require 'aws-sdk'
require 'yaml'
require 'rake/clean'
require 'erb'
# require 'fileutils'

config = YAML.load(File.read("config.yml"))

ec2 = Aws::EC2::Client.new(
  region: "ap-northeast-1"
)

ecs = Aws::ECS::Client.new(
  region: "ap-northeast-1"
)

as = Aws::AutoScaling::Client.new(
  region: "ap-northeast-1"
)

cw = Aws::CloudWatch::Client.new(
  region: "ap-northeast-1"
)

namespace :ecs do
  #
  # ここは敢えて ecs-cli を実行する(ecs-cli のデモなので)
  #
  namespace :cluster do
    desc "ECS クラスタを初期化する"
    task :configure do
     sh "ecs-cli configure --region #{config[:region]} --cluster #{config[:ecs][:cluster_name]}" 
    end

    desc "ECS クラスタを起動する"
    task :launch do
      sh "ecs-cli up --keypair #{config[:key_name]} \
            --capability-iam \
            --size #{config[:instance_count]} \
            --vpc #{config[:vpc_id]} \
            --instance-type #{config[:instance_type]} \
            --subnets #{config[:subnets].join(" ")} \
            --azs #{config[:azs].join(" ")} "
            #--security-group #{config["sg_ids"].join(" ")}"
    end

    desc "ECS クラスタ内のコンテナインスタンス数を調整する(環境変数 INSTANCE_COUNT で起動するインスタンス数を指定する)"
    task :scale do
      sh "ecs-cli scale --capability-iam --size #{ENV["INSTANCE_COUNT"]}"
    end

    desc "ECS クラスタを停止して削除する"
    task :down do
      sh "ecs-cli down --force"
    end

    namespace :list do
      cluster_name = []
      desc "ECS クラスタの一覧を確認する"
      task :clusters do
        cluster_name = ecs.list_clusters.cluster_arns.each 
        cluster_name.each do |cluster|
          puts "ECS Cluster arn     : " + cluster
        end
      end

      desc "ECS コンテナインスタンスの一覧を確認する"
      task :instances => :clusters do
        cluster_name.each do |cluster|
          ecs.list_container_instances({ cluster: cluster }).container_instance_arns.each do |container|
            puts "ECS Containers arn  : " + container
          end
        end
      end

    end

  end

  namespace :compose do
    namespace :service do
      targets = []
      Dir.glob('./ecs-*').each do |dir|
        next unless File.directory?(dir)
        target = File.basename(dir)
        targets << target
      end

      targets.each do |target|
        namespace target.to_sym do
          desc "Service Task #{target} を起動する"
          task :up do 
            p config[:ecs][:service][:deployment_max_percent]
            if (config[:ecs][:service][:deployment_max_percent] && config[:ecs][:service][:deployment_min_healthy_percent]) then
              sh "ecs-cli compose -f #{target}/task.yml service up \
                    --deployment-max-percent #{config[:ecs][:service][:deployment_max_percent]} --deployment-min-healthy-percent #{config[:ecs][:service][:deployment_min_healthy_percent]}"
            else
              sh "ecs-cli compose -f #{target}/task.yml service up"
            end
          end

          desc "Service Task #{target} をスケールアウトする(環境変数 DESIRE_COUNT で起動するコンテナ数を指定する)"
          task :scale do 
            sh "ecs-cli compose -f #{target}/task.yml service scale #{ENV["DESIRE_COUNT"]}"
          end

          desc "Service Task #{target} のコンテナ一覧を確認する"
          task :ps do 
            sh "ecs-cli compose -f #{target}/task.yml service ps"
          end

        end
      end

    end
  end

  namespace :docker do
    targets = []
    Dir.glob('./ecs-*').each do |dir|
      next unless File.directory?(dir)
      target = File.basename(dir)
      targets << target
    end

    desc "Get login infomation"
    task :get_login do
      puts "Get login infomation"
      # sh "aws --region #{config[:region]} ecr get-login > #{config[:ecr][:login_file]}"
      sh "aws --region us-east-1 ecr get-login > #{config[:ecr][:login_file]}"
    end

    desc "Docker Registry にログインする"
    task :login => :get_login do
      sh "sh #{config[:ecr][:login_file]}"
      Rake::Task[:clean].execute
    end

    revision = Time.now.to_i
    targets.each do |target|
      namespace target.to_sym do
        desc "#{target} のコンテナイメージをビルドする"
        task :build do
          cd "./#{target}/docker/" do
            sh "docker build --no-cache=true -t #{target} ."
          end
        end
        #desc "#{target} の tag を設定する"
        #task :tag do
        #  cd "./#{target}/docker/" do
        #    sh "docker tag -f #{target} #{config[:ecr][:registry]}/#{target}:#{revision}"
        #  end
        #end
        desc "#{target} を ECR に push する"
        task :push do
          cd "./#{target}/docker/" do
            sh "docker tag -f #{target} #{config[:ecr][:registry]}/#{target}:#{revision}"
            sh "docker push #{config[:ecr][:registry]}/#{target}:#{revision}"
          end
          cd "./#{target}/" do
            repo = "#{config[:ecr][:registry]}/#{target}:#{revision}"
            template = ERB.new(File.read('./task.yml.erb')).result(binding)
            task_yaml = "./task.yml"
            File.open(task_yaml, "w") do |file|
              file.puts template
            end
          end
        end
      end
    end

  end

  #
  # ここは AWS SDK for Ruby
  #
  namespace :as do
    group_name = ""

    desc "Auto Scaling グループ名を取得する"
    task :get_group_name do
      group_name = as.describe_auto_scaling_groups.auto_scaling_groups[0].auto_scaling_group_name
      puts group_name
    end

    desc "Auto Scaling Group の設定を更新する(max_size を任意の値に変更する)"
    task :update_as_group => "get_group_name" do
      as.update_auto_scaling_group({
        auto_scaling_group_name: group_name,
        max_size: config[:desire_instance_count],
      })
    end

    desc "スケールアウトする為のポリシーを設定する"
    task :put_up_policy => "get_group_name" do
      upscale = as.put_scaling_policy({
        auto_scaling_group_name: group_name,
        policy_name: "cpu_reserve_scale_up",
        policy_type: "SimpleScaling",
        adjustment_type: "ChangeInCapacity",
        scaling_adjustment: 1,
        cooldown: 300
      })

      res = cw.put_metric_alarm({
        alarm_name: "upscale", 
        alarm_description: "upscale",
        actions_enabled: true,
        alarm_actions: [upscale[0]],
        metric_name: "CPUReservation", 
        namespace: "AWS/ECS", 
        statistic: "Average",
        dimensions: [
          {
            name: "ClusterName", 
            value: config[:ecs][:cluster_name], 
          },
        ],
        period: 60, 
        unit: "Percent",
        evaluation_periods: 1,
        threshold: 50.0,
        comparison_operator: "GreaterThanOrEqualToThreshold",
      })

      # p res
    end

    desc "スケールインする為のポリシーを設定する"
    task :put_down_policy => "get_group_name" do

      downscale = as.put_scaling_policy({
        auto_scaling_group_name: group_name,
        policy_name: "cpu_reserve_scale_down",
        policy_type: "SimpleScaling",
        adjustment_type: "ChangeInCapacity",
        scaling_adjustment: -1,
        cooldown: 300
      })

      res = cw.put_metric_alarm({
        alarm_name: "downscale", 
        alarm_description: "downscale",
        actions_enabled: true,
        alarm_actions: [downscale[0]],
        metric_name: "CPUReservation", 
        namespace: "AWS/ECS", 
        statistic: "Average",
        dimensions: [
          {
            name: "ClusterName", 
            value: config[:ecs][:cluster_name], 
          },
        ],
        period: 60, 
        unit: "Percent",
        evaluation_periods: 1,
        threshold: 25.0,
        comparison_operator: "LessThanOrEqualToThreshold",
      })
      # p res 
    end

  end
end

namespace :ssh do
  namespace :config do
    desc "ssh config を生成する"
    task :generate do
      instances = ec2.describe_instances(
                    filters:[
                      { name: "tag:Name", values: ["ECS Instance - *"] },
                      { name: "instance-state-name", values: ["running"] },
                    ]
                  )
      num = 0
      instances.reservations.each do |r|
        r.instances.each do |i|
          name_tag = i.tags.select {|tag| tag[:key] == "Name"}
          puts "Host #{i.public_dns_name}\n  Hostname #{i.public_dns_name}"
        end.join("\n\n")
        num += 1
      end
      puts <<-"CONF"

Host *
    Port            22
    IdentityFile    #{config[:key_path]}
    User            #{config[:ssh_user_name]}
      CONF
    end


    desc "作成済みの ssh config を初期化する"
    task :init do
      sh "echo > ssh_config"
    end
  end

  namespace :login do
    targets = []
    begin
      File.open("ssh_config") do |f|
        while line  = f.gets
          if line.include?("Host ") && ! line.include?("*")
            targets << line.gsub(/Host /,'').chomp
          end
        end
      end
    rescue SystemCallError => e
      puts e.message
    end
    
    targets.each do |target|
      desc "#{target} に ssh でアクセスする"
      task target.to_sym do 
        sh "ssh -F ssh_config #{target}"
      end
    end
  end

end
