@path = "/myapp"

worker_processes 1
working_directory @path
timeout 300
listen 4567
pid "#{@path}/tmp/pids/unicorn.pid" 
stderr_path "#{@path}/log/unicorn.stderr.log"
stdout_path "#{@path}/log/unicorn.stdout.log"
preload_app true
