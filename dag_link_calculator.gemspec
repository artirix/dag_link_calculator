# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dag_link_calculator/version'

Gem::Specification.new do |spec|
  spec.name = 'dag_link_calculator'
  spec.version = DagLinkCalculator::VERSION
  spec.authors = ['Eduardo Turiño']
  spec.email = ['eturino@artirix.com']
  spec.required_ruby_version = '>= 2.1'

  spec.summary = <<-TXT.gsub(/[\s]*/, ' ')
    Given a list of parent-child relationships, it will return a list of links ancestor-descendant, with count
  TXT
  spec.description = <<-TXT.gsub(/[\s]*/, ' ')
    Given a list of parent-child relationships, it will return a list of links ancestor-descendant, with count.
    Can be used to restore a list of links in `act-as-dag`, providing that the direct links are correct.
  TXT
  spec.homepage = 'https://github.com/artirix/dag_link_calculator'
  spec.license = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'guard-rspec', '~> 4.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
