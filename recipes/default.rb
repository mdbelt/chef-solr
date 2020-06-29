#
# Cookbook Name:: solr
# Recipe:: default
#
# Copyright 2013, David Radcliffe
#

# Fix entropy SOLR warning
include_recipe 'entropy::default'

# LSOF needed for stable SOLR
package 'lsof'

if node['solr']['install_java']
  include_recipe 'apt'
  include_recipe 'java'
end

extract_path = "#{node['solr']['dir']}-#{node['solr']['version']}"
solr_path = "#{extract_path}/#{node['solr']['version'].split('.')[0].to_i < 5 ? 'example' : 'server'}"

user node['solr']['user'] do
  comment 'User that owns the solr data dir.'
  home '/etc/default'
#  home node['solr']['data_dir']
  system true
#  shell '/bin/false'
  only_if { node['solr']['user'] != 'root' }
end

group node['solr']['group'] do
  members node['solr']['user']
  append true
  system true
  only_if { node['solr']['group'] != 'root' }
end

# Fix limits SOLR warning
template '/etc/security/limits.d/99-solr-limits.conf' do
  source '99-solr-limits.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

ark 'solr' do
  url node['solr']['url']
  version node['solr']['version']
  checksum node['solr']['checksum']
  path node['solr']['dir']
  prefix_root '/opt'
  prefix_home '/opt'
  owner node['solr']['user']
  action :install
end

directory node['solr']['data_dir'] do
  owner node['solr']['user']
  group node['solr']['group']
  recursive true
  action :create
end

# Dynamically specify solr options
template '/etc/default/solr.in.sh' do
  owner 'root'
  group node['solr']['group']
  mode '0640'
  notifies :restart, 'service[solr]', :delayed
end

# Switch to copy from packaged solr service init.d, everything appears to be confirgured from solr.in.sh (above now)
remote_file '/etc/init.d/solr' do
  source 'file:///opt/solr/bin/init.d/solr'
  owner 'root'
  group 'root'
  mode '0755'
  notifies :restart, 'service[solr]', :delayed
end

#Ensure haveged is started (& auto start) - entropy cookbook doesn't set service to autostart
service 'haveged' do
  action [:enable, :start]
end

#Ensure SOLR started
service 'solr' do
  supports :restart => true, :status => true
  action [:enable, :start]
end
