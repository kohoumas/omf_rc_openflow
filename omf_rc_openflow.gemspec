# -*- encoding: utf-8 -*-
require File.expand_path('../lib/omf_rc_openflow/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Kostas Choumas"]
  gem.email         = ["kohoumas@gmail.com"]
  gem.description   = %q{OMF Resource Controllers related to Openflow}
  gem.summary       = %q{OMF Resource Controllers related to Openflow}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "omf_rc_openflow"
  gem.require_paths = ["lib"]
  gem.version       = OmfRcOpenflow::VERSION
  gem.add_runtime_dependency "omf_rc", "~> 6.0.0.pre"
end
