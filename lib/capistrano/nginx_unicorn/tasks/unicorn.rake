namespace :unicorn do
  desc "Mkdir necessary folders in shared_path"
  task :create_folders do
    on roles(:app) do
      execute :mkdir, "-p", shared_path.join("config")
      execute :mkdir, "-p", shared_path.join("log")
      execute :mkdir, "-p", shared_path.join("pids")
    end
  end

  desc "Setup Unicorn initializer and app configuration"
  task :setup do
    invoke "load:defaults"

    on roles(:app) do
      template "unicorn.rb.erb", "/tmp/unicorn.rb"
      execute "#{fetch(:sudo)} mv /tmp/unicorn.rb #{fetch(:unicorn_config)}"

      template "unicorn_init.erb", "/tmp/unicorn_init"
      execute "chmod +x /tmp/unicorn_init"
      execute "#{fetch(:sudo)} mv /tmp/unicorn_init /etc/init.d/unicorn_#{fetch(:application)}"
      execute "#{fetch(:sudo)} update-rc.d -f unicorn_#{fetch(:application)} defaults"
    end
  end

  %w[start stop restart].each do |command|
    desc "#{command} unicorn"
    task command do
      on roles(:app) do
        execute "#{fetch(:sudo)} service unicorn_#{fetch(:application)} #{command}"
      end
    end
  end

  before 'unicorn:setup', 'nginx_unicorn:defaults'
  before 'unicorn:start', 'unicorn:create_folders'
  before 'unicorn:start', 'nginx_unicorn:defaults'
  before 'unicorn:stop', 'nginx_unicorn:defaults'
  before 'unicorn:restart', 'nginx_unicorn:defaults'
  before 'unicorn:restart', 'unicorn:create_folders'
end


