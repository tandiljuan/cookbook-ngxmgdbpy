# Vagrant Settings
default[:vagrant][:workspace_path] = '/opt/vboxsf/workspace'
default[:vagrant][:workspace_nfs_path] = '/opt/nfs/workspace'

# Core settings
default[:core][:user]           = "vagrant"
default[:core][:group]          = "vagrant"
default[:core][:workspace_path] = '/opt/workspace'
default[:core][:project_path]   = node[:core][:workspace_path]
default[:core][:project_name]   = "BottleApp"

# SAMBA Settings
default[:smbfs][:install] = false

# Nginx Settings
default[:nginx][:default_site_enabled] = false
default[:nginx][:listen_port]          = 80
override[:nginx][:user]                = node[:core][:user]
override[:nginx][:group]               = node[:core][:group]

# MongoDB Settings
default[:cookbook][:mongodb][:host] =  "localhost"
default[:cookbook][:mongodb][:port] =  node[:mongodb][:config][:port]

# Python Settings
default[:python][:project_path] = node[:core][:project_path]
default[:python][:project_app]  = "app.py"

# uWSGI Settings
default[:uwsgi][:pid_path]    = "/opt/uwsgi/#{node[:core][:project_name].downcase}.pid"
default[:uwsgi][:config_file] = "/opt/uwsgi/#{node[:core][:project_name].downcase}.ini"
default[:uwsgi][:config_type] = :ini
default[:uwsgi][:unix_socket] = "/opt/uwsgi/#{node[:core][:project_name].downcase}.sock"
default[:uwsgi][:tcp_socket]  = "127.0.0.1:8080"
default[:uwsgi][:use_tcp]     = false
default[:uwsgi][:processes]   = 1
default[:uwsgi][:threads]     = 1

# runit Settings
default[:runit][:log_path] = "/var/log/service/#{node[:core][:project_name].downcase}"
