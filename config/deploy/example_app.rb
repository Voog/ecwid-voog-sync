set :application, 'ecwid_voog_sync_example_app'

set :linked_files, fetch(:linked_files, []).push('config/application.yml')

namespace :deploy do
  desc 'Upload configuration'
  task :upload_configuration do
    on hosts do |_host|
      local_conf_folder = './custom/example_app'

      execute "mkdir -p #{shared_path}/config"
      %w(config/application.yml config/database.yml).each do |f|
        upload! "#{local_conf_folder}/#{f}", "#{shared_path}/#{f}"
      end
    end
  end

  after :publishing, :restart
end
