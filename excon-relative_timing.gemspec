# coding: utf-8
root = "."

Gem::Specification.new do |spec|
  spec.name          = "excon-relative_timing"
  spec.version       = '1.0.0'
  spec.authors       = ["Cvent"]
  spec.email         = ["dvogel@cvent.com"]
  spec.summary       = %q{Reports statistics for how much of a request-response time is due to the network.}
  spec.description   = %q{Reports statistics for how much of a request-response time is due to the network. This is done by subtracting the X-Runtime header value from the time it takes to make the request and receive the response.}
  spec.homepage      = "https://github.com/cvent/excon-relative_timing"
  spec.license       = "Apache-2.0"

  spec.files         = `git ls-files -z #{root}`.split("\x0")
  spec.executables   = spec.files.grep(%r{^#{root}/bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^#{root}/(test|spec|features)/})
  spec.require_paths = ["#{root}/lib"]

  spec.add_dependency "excon", ">= 0.52.0"
  spec.add_dependency "addressable", '~> 2.3'

  # Needed to verify API of statsd client test doubles.
  spec.add_development_dependency "statsd-ruby", "~> 1.4.0"

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "pry", "~> 0.10"
  spec.add_development_dependency "pry-nav", "~> 0.2"
  spec.add_development_dependency "rspec", "~> 3.7"
  spec.add_development_dependency "rspec-collection_matchers", "~> 1.1"
  spec.add_development_dependency "simplecov", "~> 0.16"
end

