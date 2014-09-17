# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'doorkeeper-couchbase/version'

Gem::Specification.new do |s|
    s.name        = 'doorkeeper-couchbase'
    s.version     = DoorkeeperCouchbase::VERSION
    s.authors     = ['Stephen von Takach']
    s.email       = ['steve@cotag.me']
    s.license     = 'MIT'
    s.homepage    = 'https://github.com/advancedcontrol/doorkeeper-couchbase'
    s.summary     = 'A Couchbase ORM for Doorkeeper'
    s.description = 'A Couchbase ORM for Doorkeeper. Because both projects rock.'

    s.files = Dir["{lib}/**/*"] + %w(doorkeeper-couchbase.gemspec Gemfile README.md LICENSE)

    s.require_paths = ['lib']
end
