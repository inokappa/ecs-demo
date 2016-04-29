function reachable_consul_server() {
  echo "reachable check for consul_server..."
  ping -c 3 consul_server
}

function start_consul-template() {
  echo "start consul-template..."
  consul-template \
    -consul $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):8500 \
    -template "/usr/local/etc/haproxy/haproxy.cfg.ctmpl:/usr/local/etc/haproxy/haproxy.cfg:/root/restart-haproxy.sh"
}

reachable_consul_server
start_consul-template
