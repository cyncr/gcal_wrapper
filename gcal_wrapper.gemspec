# -*- encoding: utf-8 -*-
require File.expand_path('../lib/gcal_wrapper/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Charlie Moseley", "Cyncr"]
  gem.email         = ["charlie@robopengu.in"]
  gem.description   = %q{A Google Calendar wrapper around the Google API Ruby 
                         Client}
  gem.summary       = %q{A Google Calendar wrapper around the Google API Ruby 
                         Client that implements an Active Record like way of 
                         interacting with objects from GCal.}
  gem.homepage      = "http://cynr.com/open-source/gcal_wrapper"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "gcal_wrapper"
  gem.require_paths = ["lib"]
  gem.version       = GCal::VERSION

  gem.add_development_dependency "rspec", "~> 2.11.0"
  gem.add_development_dependency "faker", "~> 1.0.1"

  gem.add_dependency "google-api-client"#, "~> 0.4.4"
  gem.add_dependency "hashie",            "~> 1.2.0"
end
