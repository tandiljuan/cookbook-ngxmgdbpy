#
# Cookbook Name:: cookbook-ngxmgdbpy
# Recipe:: mongodb
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

# Install dependencies needed to compile `mongo` ruby gem.
# @see  https://sethvargo.com/using-gems-with-chef/
package 'libsasl2-dev' do
  action :nothing
end.run_action(:install)

# Make sure that the following gems are installed at compile time
# @see https://github.com/edelight/chef-mongodb/issues/386
chef_gem 'mongo' do
  version '1.12.1'
  action :nothing
end.run_action(:install)

chef_gem 'bson_ext' do
  version '1.12'
  action :nothing
end.run_action(:install)

# Install mongodb
include_recipe "mongodb"

# Setup MongoDB users
include_recipe "mongodb::user_management"

# Restart mongodb sevice
service "mongodb" do
  action :restart
end
