# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/nginx_unicorn/version'

Gem::Specification.new do |gem|
  gem.name          = "capistrano-nginx-unicorn"
  gem.version       = Capistrano::NginxUnicorn::VERSION
  gem.authors       = ["Ivan Tkalin"]
  gem.email         = ["itkalin@gmail.com"]
  gem.description   = %q{Capistrano tasks for configuration and management nginx+unicorn combo for zero downtime deployments of Rails applications. Configs can be copied to the application using generators and easily customized.}
  gem.summary       = %q{Create and manage nginx+unicorn configs from capistrano}
  gem.homepage      = "https://github.com/ivalkeen/capistrano-nginx-unicorn"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'capistrano', '~> 2.0'

  gem.add_development_dependency "rake"
end
