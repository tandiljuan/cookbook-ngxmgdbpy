#
# Cookbook Name:: cookbook-ngxmgdbpy
# Recipe:: default
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

# Ensure that the build-essential recipe is the first one to be executed.
include_recipe 'build-essential::default'

include_recipe "cookbook-ngxmgdbpy::init"
include_recipe "cookbook-ngxmgdbpy::nginx"
include_recipe "cookbook-ngxmgdbpy::mongodb"
include_recipe "cookbook-ngxmgdbpy::python"
