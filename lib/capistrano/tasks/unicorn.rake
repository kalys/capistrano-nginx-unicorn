require 'capistrano/nginx_unicorn/helpers'

include Capistrano::NginxUnicorn::Helpers

namespace :unicorn do
  desc "Setup Unicorn initializer"
  task :setup_initializer do
    on roles(:app) do
      template "unicorn_init.erb", "/tmp/unicorn_init"
      execute :chmod, "+x", "/tmp/unicorn_init"
      sudo :mv, "/tmp/unicorn_init /etc/init.d/#{fetch(:unicorn_service_name)}"
      if which('update-rc.d').nil?
        sudo "chkconfig #{fetch(:unicorn_service_name)} on"
      else
        sudo "update-rc.d -f #{fetch(:unicorn_service_name)} defaults"
      end
    end
  end

  desc "Setup Unicorn app configuration"
  task :setup_app_config do
    on roles(:app) do
      execute :mkdir, "-p", shared_path.join("config")
      execute :mkdir, "-p", shared_path.join("log")
      execute :mkdir, "-p", shared_path.join("pids")
      template "unicorn.rb.erb", fetch(:unicorn_config)
    end
  end

  %w[start stop restart].each do |command|
    desc "#{command} unicorn"
    task command do
      on roles(:app) do
        sudo "service #{fetch(:unicorn_service_name)} #{command}"
      end
    end
  end

  def which(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
      exts.each { |ext|
        exe = File.join(path, "#{cmd}#{ext}")
        return exe if File.executable? exe
      }
    end
    return nil
  end
end

namespace :deploy do
  after :publishing, "unicorn:restart"
end
