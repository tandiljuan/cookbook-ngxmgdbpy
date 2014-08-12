# Vagrant Settings
default[:vagrant][:workspace_path] = '/opt/vboxsf/workspace'
default[:vagrant][:workspace_nfs_path] = '/opt/nfs/workspace'

# Core settings
default[:core][:workspace_path] = '/opt/workspace'
default[:core][:project_path]   = node[:core][:workspace_path]

# SAMBA Settings
default[:smbfs][:install] = false
