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

# Install python and pip
include_recipe "python"

# Install uWSGI using pip
python_pip "uwsgi"

# Install Bottle using pip
python_pip "bottle"


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
    :app_name => node[:core][:project_name],
    :use_tcp => node[:uwsgi][:use_tcp],
    :tcp_socket => node[:uwsgi][:tcp_socket],
    :unix_socket => node[:uwsgi][:unix_socket],
    :project_path => node[:python][:project_path],
    :project_app => node[:python][:project_app],
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
template File.join([node[:python][:project_path], node[:python][:project_app]]) do
  source "python/bottle-app.py.erb"
  owner node[:core][:user]
  group node[:core][:group]
  mode 00664
  only_if do
    (Dir.entries(node[:python][:project_path]) - [".dumb"]).size <= 2
  end
end
