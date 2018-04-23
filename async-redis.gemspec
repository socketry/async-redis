
require_relative 'lib/async/redis/version'

Gem::Specification.new do |spec|
	spec.name          = "async-redis"
	spec.version       = Async::Redis::VERSION
	spec.authors       = ["Samuel Williams"]
	spec.email         = ["samuel.williams@oriontransfer.co.nz"]

	spec.summary       = "A Redis client library."
	spec.homepage      = "https://github.com/socketry/async-redis"

	spec.files         = `git ls-files -z`.split("\x0").reject do |f|
		f.match(%r{^(test|spec|features)/})
	end
	spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
	spec.require_paths = ["lib"]
	
	spec.add_dependency("async", "~> 1.6")
	spec.add_dependency("async-io", "~> 1.7")
	
	spec.add_development_dependency "async-rspec", "~> 1.1"
	
	spec.add_development_dependency "bundler", "~> 1.3"
	spec.add_development_dependency "rspec", "~> 3.6"
	spec.add_development_dependency "rake"
end
