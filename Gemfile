source 'https://rubygems.org'

gem 'rails', '4.2.4'
gem 'pg', '~> 0.18.3', group: :postgre
gem 'mysql2', '~> 0.4.1', group: :mysql

# Gem for Ecwid API v3 (v0.1.1)
gem 'ecwid_api', git: 'https://github.com/davidbiehl/ecwid_api.git', ref: '5a5d4e8241168f484fe2690d96e42138675bf4ee', require: false

# Gem for Voog API v3
gem 'voog_api', '~> 0.0.7', require: false

# Configuration handler
gem 'figaro', '~> 1.1.1'

# Cron jobs
gem 'whenever', '~> 0.9.4', require: false

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
end

group :development do
  gem 'capistrano', '~> 3.4.0', require: false
  gem 'capistrano-multiconfig', '~> 3.0.8', require: false
  gem 'capistrano-rvm'
  gem 'capistrano-rbenv'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end
