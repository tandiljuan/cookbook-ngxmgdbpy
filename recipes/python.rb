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

# Install dependencies with apt
# -----------------------------
# lxml -> libxml2-dev libxslt-dev libz-dev libffi-dev libssl-dev
%w( libxml2-dev libxslt-dev libz-dev libffi-dev libssl-dev ).each do |debpkg|
  package debpkg do
    action :install
  end
end

# Listo of Python modules to install
modules = {
  # Pick modules from PyPI
  "bottle" => "0.12.7",
  "lxml" => "3.3.5", # Needs 1024Mb of memory to compile
  "pymongo" => "2.7.2",
  "uwsgi" => "2.0.6",
  "watchdog" => "0.8.1",
}

# Install Python modules using pip
modules.each do |module_name, module_version|
  python_pip module_name do
    version module_version
  end
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

# Restart runit sevice
service runit_service_name do
  action :restart
  notifies :restart, "service[nginx]"
end

# Create a watcher deamon that will restart uwsgi on any file change
if node[:watcher][:install] and  %( development ).include? node.chef_environment

  # Create the folder for the script
  directory node[:watcher][:bin_path] do
    mode 00775
    recursive true
    action :create
  end

  # Create the file watcher script
  template File.join(node[:watcher][:bin_path], node[:watcher][:bin_name]) do
    source "python/watcher.py.erb"
    owner node[:core][:user]
    group node[:core][:group]
    mode 00775
  end

  runit_service_name = node[:watcher][:bin_name]
  runit_service_folder = File.join([node['runit']['sv_dir'], runit_service_name])

  # Create folder for `control` scripts
  directory File.join([runit_service_folder, "control"]) do
    mode 00775
    recursive true
    action :create
  end

  # Create folder for log script (just needed by runit)
  directory File.join([runit_service_folder, "log"]) do
    mode 00775
    recursive true
    action :create
  end

  # Create log (`run`) script (just needed by runit)
  file File.join([runit_service_folder, "log", "run"]) do
    content "#!/bin/sh"
    mode 00775
  end

  # Create `run` (up/start/main) script
  template File.join([runit_service_folder, "run"]) do
    source "runit/run-watcher.erb"
    mode 00775
    variables({
      :script_fullpath => File.join(node[:watcher][:bin_path], node[:watcher][:bin_name]),
      :force_polling => node[:watcher][:polling],
      :delay => node[:watcher][:delay],
      :path_to_watch => node[:watcher][:watch_path],
      :command_to_execute => node[:watcher][:command],
      :filename_pattern => node[:watcher][:filename_pattern],
    })
  end

  # Enable the runit service
  runit_service runit_service_name do
    sv_templates false
  end

  # Restart runit sevice
  service runit_service_name do
    action :restart
  end

end
