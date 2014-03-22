require 'capistrano/nginx_unicorn/helpers'

include Capistrano::NginxUnicorn::Helpers

namespace :load do
  task :defaults do
    set :unicorn_service_name, -> { "unicorn_#{fetch(:application)}_#{fetch(:stage)}" }
    set :templates_path, "config/deploy/templates"
    set :unicorn_pid, -> { shared_path.join("pids/unicorn.pid") }
    set :unicorn_config, -> { shared_path.join("config/unicorn.rb") }
    set :unicorn_log, -> { shared_path.join("log/unicorn.log") }
    set :unicorn_user, -> { fetch(:user) }
    set :unicorn_workers, 2
  end
end

namespace :unicorn do
  desc "Setup Unicorn initializer and app configuration"
  task :setup do
    on roles(:app) do
      execute :mkdir, "-p", shared_path.join("config")
      execute :mkdir, "-p", shared_path.join("log")
      execute :mkdir, "-p", shared_path.join("pids")
      template "unicorn.rb.erb", fetch(:unicorn_config)
      template "unicorn_init.erb", "/tmp/unicorn_init"
      execute :chmod, "+x", "/tmp/unicorn_init"
      sudo :mv, "/tmp/unicorn_init /etc/init.d/#{fetch(:unicorn_service_name)}"
      sudo "update-rc.d -f #{fetch(:unicorn_service_name)} defaults"
    end
  end

  %w[start stop restart].each do |command|
    desc "#{command} unicorn"
    task command do
      on roles(:app) do
        execute "service #{fetch(:unicorn_service_name)} #{command}"
      end
    end
  end
end

namespace :deploy do
  after :finishing, "unicorn:setup"
  after :finishing, "unicorn:restart"
  after :restart, "unicorn:restart"
end
