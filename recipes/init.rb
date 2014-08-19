#
# Cookbook Name:: cookbook-core
# Recipe:: init
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

include_recipe "apt"
include_recipe "vim"

# Mount any configured SAMBA shared directory
# http://jsosic.wordpress.com/2012/08/13/accessing-host-filesystem-from-virtualbox-guest/
if node[:smbfs][:install] === true
  node[:smbfs][:mounts].keys.each do |mount_point|
    directory mount_point do
      recursive true
      action :create
    end
  end
  include_recipe "smbfs::attribute_driven"
end

# If there is no workspace, set the FIRST SAMBA shared directory as workspace
samba_is_mounted = false
ruby_block "check_samba_workspace_created" do
  block do
    if not node[:smbfs][:mounts].empty? and File.directory? node[:smbfs][:mounts].keys[0]
        samba_is_mounted = true
    end
  end
  action :create
end

link node[:core][:workspace_path] do
  to node[:smbfs][:mounts].keys[0]
  only_if { samba_is_mounted and not File.exist? node[:core][:workspace_path] }
end

# If there is no workspace, set the nfs shared directory as workspace
nfs_workspace_exist = false
ruby_block "check_nfs_workspace_created" do
  block do
    if File.directory? node[:vagrant][:workspace_nfs_path]
      nfs_workspace_exist = true
    end
  end
  action :create
end

link node[:core][:workspace_path] do
  to node[:vagrant][:workspace_nfs_path]
  only_if { nfs_workspace_exist and not File.exist? node[:core][:workspace_path] }
end

# If there is no workspace, set the vagrant shared directory as workspace
vagrant_workspace_exist = false
ruby_block "check_vagrant_workspace_created" do
  block do
    if File.directory? node[:vagrant][:workspace_path]
      vagrant_workspace_exist = true
    end
  end
  action :create
end

link node[:core][:workspace_path] do
  to node[:vagrant][:workspace_path]
  only_if { vagrant_workspace_exist and not File.exist? node[:core][:workspace_path] }
end

# If there is no workspace, create one
directory node[:core][:workspace_path] do
  recursive true
  action :create
  only_if { not File.exist? node[:core][:workspace_path] }
end
