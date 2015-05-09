path = Dir.pwd + "/tmp/"

threads 0,20
environment "development"
daemonize true
drain_on_shutdown true

bind  "unix://" + path + "sockets/puma.sock"
pidfile path + "pids/puma.pid"
state_path path + "pids/puma.state"