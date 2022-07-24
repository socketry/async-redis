
require_relative "lib/async/redis/version"

Gem::Specification.new do |spec|
	spec.name = "async-redis"
	spec.version = Async::Redis::VERSION
	
	spec.summary = "A Redis client library."
	spec.authors = ["Samuel Williams", "Huba Nagy"]
	spec.license = "MIT"
	
	spec.homepage = "https://github.com/socketry/async-redis"
	
	spec.files = Dir.glob('{lib}/**/*', File::FNM_DOTMATCH, base: __dir__)
	
	spec.add_dependency "async", "~> 2.0"
	spec.add_dependency "async-io", "~> 1.33"
	spec.add_dependency "async-pool", "~> 0.3"
	spec.add_dependency "protocol-redis", "~> 0.6"
	
	spec.add_development_dependency "async-rspec", "~> 1.16"
	spec.add_development_dependency "benchmark-ips"
	spec.add_development_dependency "bundler"
	spec.add_development_dependency "covered"
	spec.add_development_dependency "hiredis"
	spec.add_development_dependency "rake"
	spec.add_development_dependency "redis"
	spec.add_development_dependency "rspec", "~> 3.11"
end
