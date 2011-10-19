# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "sphonglepress/version"

Gem::Specification.new do |s|
  s.name        = "sphonglepress"
  s.version     = Sphonglepress::VERSION
  s.authors     = ["Nicholas Hemsley"]
  s.email       = ["nick.hems@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{Gem for populating wordpress}
  s.description = %q{Sphonglepress is a command line utility for interacting with & making the task of importing content into a wordpress site}

  s.rubyforge_project = "sphonglepress"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
  
  s.add_dependency('thor')
  s.add_dependency('middleman')
  s.add_dependency('activerecord')
  s.add_dependency('tilt')
  s.add_dependency('haml')
  s.add_dependency('mysql')
  s.add_dependency('fssm')
  #FIXME: move html-cleaner into gem & remove this
  s.add_dependency('hpricot')
  s.add_dependency('mime-types')
  s.add_dependency('nokogiri')
  s.add_dependency('therubyracer')



end
