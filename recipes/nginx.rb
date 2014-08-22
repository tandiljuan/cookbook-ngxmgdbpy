#
# Cookbook Name:: cookbook-ngxmgdbpy
# Recipe:: nginx
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

include_recipe "nginx"

# Create Nginx site configuration
template File.join(["/etc/nginx/sites-available", node[:core][:project_name]]) do
  source "nginx/python.erb"
  owner node[:core][:user]
  group node[:core][:group]
  mode 00664
  variables({
    :app_name => node[:core][:project_name],
    :use_tcp => node[:uwsgi][:use_tcp],
    :tcp_socket => node[:uwsgi][:tcp_socket],
    :unix_socket => node[:uwsgi][:unix_socket],
    :listen_port => node[:nginx][:listen_port],
    :server_name => node[:nginx][:server_name],
    :logdir => node['nginx']['log_dir']
  })
  action :create
  notifies :restart, "service[nginx]"
end

# Enable Nginx site
link File.join(["/etc/nginx/sites-enabled", node[:core][:project_name]]) do
  to File.join(["/etc/nginx/sites-available", node[:core][:project_name]])
  owner node[:core][:user]
  group node[:core][:group]
  action :create
end
