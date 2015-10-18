set :rbenv_type, :user
set :rbenv_ruby, '2.2.3'

# set :rvm_type, :user
# set :rvm_ruby_version, '2.2.3'

set :stage, :production
set :rails_env, 'production'
set :deploy_to, '/var/www/ecwid_voog_sync_example_app'

set :whenever_identifier, -> { "#{fetch(:application)}_#{fetch(:stage)}" }
set :whenever_roles, -> { :app }
# For RBENV
set :whenever_variables, -> { "'environment=#{fetch :whenever_environment}&rbenv_ruby=#{fetch :rbenv_ruby}&output=#{shared_path}/cron.log'" }
# For RVM
# set :whenever_variables, -> { "'environment=#{fetch :whenever_environment}&output=#{shared_path}/cron.log'" }

role :app, %w(example@example.com)
role :web, %w(example@example.com)
role :db,  %w(example@example.com)
