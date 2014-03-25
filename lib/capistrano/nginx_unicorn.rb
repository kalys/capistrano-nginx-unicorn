load File.expand_path("../tasks/nginx.rake", __FILE__)
load File.expand_path("../tasks/unicorn.rake", __FILE__)
load File.expand_path("../tasks/logrotate.rake", __FILE__)

namespace :load do
  task :defaults do
    load 'capistrano/nginx_unicorn/defaults.rb'
  end
end
