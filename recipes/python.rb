#
# Cookbook Name:: cookbook-ngxmgdbpy
# Recipe:: python
#
# Author:: Juan Manuel Lopez
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Installs runit and provides the runit_service resource for managing processes
include_recipe "runit"

# Install python and pip
include_recipe "python"

# Install uWSGI using pip
python_pip "uwsgi" do
  version "2.0.6"
end

# Install PyMongo using pip
python_pip "pymongo" do
  version "2.7.2"
end

# Install Bottle using pip
python_pip "bottle" do
  version "0.12.7"
end

# Install lxml dependencies with apt
%w( libxml2-dev libxslt-dev libz-dev ).each do |debpkg|
  package debpkg do
    action :install
  end
end

# Install lxml using pip
python_pip "lxml" do
  version "3.3.5"
end


# uWSGI
# -----

# Create path for uWSGI's config file
directory File.dirname(node[:uwsgi][:config_file]) do
  owner node[:core][:user]
  group node[:core][:group]
  mode 00775
  recursive true
  action :create
end

# Create uWSGI's config file
template node[:uwsgi][:config_file] do
  source "uwsgi/config.ini.erb"
  owner node[:core][:user]
  group node[:core][:group]
  mode 00664
  variables({
    :use_tcp => node[:uwsgi][:use_tcp],
    :tcp_socket => node[:uwsgi][:tcp_socket],
    :unix_socket => node[:uwsgi][:unix_socket],
    :project_path => node[:python][:project_path],
    :project_module => node[:python][:project_module],
    :project_entry => node[:python][:project_entry],
    :project_file => node[:python][:project_file],
    :use_module => node[:python][:use_module],
    :processes => node[:uwsgi][:processes],
    :threads => node[:uwsgi][:threads],
  })
end

# If using Unix Socket, create socket file
unless node[:uwsgi][:use_tcp]
  directory File.dirname(node[:uwsgi][:unix_socket]) do
    owner node[:core][:user]
    group node[:core][:group]
    mode 00775
    recursive true
    action :create
  end

  file node[:uwsgi][:unix_socket] do
    owner node[:core][:user]
    group node[:core][:group]
    mode 00664
    action :create_if_missing
  end
end

# Create a simple demo app, if there is no app
template File.join([node[:python][:project_path], node[:python][:project_file]]) do
  source "python/bottle-app.py.erb"
  owner node[:core][:user]
  group node[:core][:group]
  mode 00664
  variables({
    :mongo_host => node[:cookbook][:mongodb][:host],
    :mongo_port => node[:cookbook][:mongodb][:port],
    :mongo_ddbb => node[:cookbook][:mongodb][:ddbb],
    :mongo_user => node[:cookbook][:mongodb][:user][:name],
    :mongo_pass => node[:cookbook][:mongodb][:user][:pass],
  })
  only_if do
    (Dir.entries(node[:python][:project_path]) - [".dumb"]).size <= 2
  end
end


# Setup uWSGI service
# -------------------

runit_service_name   = node[:core][:project_name].downcase
runit_service_folder = File.join([node['runit']['sv_dir'], runit_service_name])

# Create folder for `control` scripts
directory File.join([runit_service_folder, "control"]) do
  mode 00775
  recursive true
  action :create
end

# Create `d` (down) script
template File.join([runit_service_folder, "control", "d"]) do
  source "runit/down.erb"
  mode 00775
  variables ({
    :uwsgi_pid_path => node[:uwsgi][:pid_path],
  })
end

# Create folder for log script
directory File.join([runit_service_folder, "log"]) do
  mode 00775
  recursive true
  action :create
end

# Create log (`run`) script
template File.join([runit_service_folder, "log", "run"]) do
  source "runit/log.erb"
  mode 00775
  variables ({
    :uid => node[:core][:user],
    :gid => node[:core][:group],
    :log_path => node[:runit][:log_path],
  })
end

# Create `run` (up/start/main) script
template File.join([runit_service_folder, "run"]) do
  source "runit/run.erb"
  mode 00775
  variables ({
    :uwsgi_pid_path => node[:uwsgi][:pid_path],
    :uwsgi_config_file => node[:uwsgi][:config_file],
    :uid => node[:core][:user],
    :gid => node[:core][:group],
    :project_path => node[:core][:project_path],
  })
end

# Enable the runit service
runit_service runit_service_name do
  sv_templates false
end

# On development environment `stop` and `start` instead of `restart`
# Because of the uwsgi `py-autoreload` setting that generate two processes,
# making the `restart` action return with 1 (instead of 0).

# Stop runit sevice
service "#{runit_service_name} stop" do
  service_name runit_service_name
  action :stop
end

# Start runit sevice
service "#{runit_service_name} start" do
  service_name runit_service_name
  action :start
  notifies :restart, "service[nginx]"
end
