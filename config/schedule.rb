# Can overide # set :whenever_variables, -> { "'environment=#{fetch :whenever_environment}&output=#{shared_path}/cron.log'" }
set :output, '/var/rails/ecwid_voog_sync/current/log/cron_log.log'

# Sync data once per 5 min
every '*/5 0-4,6-23 * * *' do
  rake 'ecwid_voog_sync:sync'
end

# Do full sync once per day
every '5 5 * * *' do
  rake 'ecwid_voog_sync:full_sync'
end

# Sync data once per 10 min during full update
every '20,30,40,50 5 * * *' do
  rake 'ecwid_voog_sync:sync'
end

# # Sync categories data
# every '0 4 * *' do
#   rake 'ecwid_voog_sync:sync_catalogs'
# end
