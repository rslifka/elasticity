# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "elasticity/version"

Gem::Specification.new do |s|
  s.name        = "wakoopa-elasticity"
  s.version     = Elasticity::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Robert Slifka"]
  s.homepage    = "http://www.github.com/rslifka/elasticity"
  s.summary     = %q{Programmatic access to Amazon's Elastic Map Reduce service.}
  s.description = %q{Programmatic access to Amazon's Elastic Map Reduce service.}

  s.add_dependency("rest-client")
  s.add_dependency("nokogiri")

  s.add_development_dependency("autotest-fsevent")
  s.add_development_dependency("autotest-growl")
  s.add_development_dependency("rake")
  s.add_development_dependency("rspec",   ">= 2.5.0")
  s.add_development_dependency("vcr",     ">= 1.5.1")
  s.add_development_dependency("webmock", ">= 1.6.2")
  s.add_development_dependency("ZenTest")

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
