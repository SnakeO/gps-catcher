# frozen_string_literal: true

path = Dir.pwd + "/tmp/"

threads 0,20
environment "development"
daemonize false   # service puma-manager start|stop|restart takes care of this
drain_on_shutdown true

bind  "unix://" + path + "sockets/puma.sock"
pidfile path + "pids/puma.pid"
state_path path + "pids/puma.state"

activate_control_app