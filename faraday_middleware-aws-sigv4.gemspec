# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'faraday_middleware-aws-sigv4'
  spec.version       = '0.2.4'
  spec.authors       = ['Genki Sugawara']
  spec.email         = ['sugawara@cookpad.com']

  spec.summary       = %q{Faraday middleware for AWS Signature Version 4 using aws-sigv4.}
  spec.description   = %q{Faraday middleware for AWS Signature Version 4 using aws-sigv4.}
  spec.homepage      = 'https://github.com/winebarrel/faraday_middleware-aws-sigv4'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday', '>= 0.9'
  spec.add_dependency 'aws-sigv4', '~> 1.0'

  spec.add_development_dependency 'faraday_middleware'
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'aws-sdk-core', '~> 3.0'
  spec.add_development_dependency 'appraisal', '>= 2.2'
end
