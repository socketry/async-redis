# frozen_string_literal: true

require_relative "lib/async/redis/version"

Gem::Specification.new do |spec|
	spec.name = "async-redis"
	spec.version = Async::Redis::VERSION
	
	spec.summary = "A Redis client library."
	spec.authors = ["Samuel Williams", "Huba Nagy", "David Ortiz", "Gleb Sinyavskiy", "Mikael Henriksson", "Troex Nevelin", "Alex Matchneer", "Jeremy Jung", "Olle Jonsson", "Pierre Montelle", "Salim Semaoune", "Tim Willard"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/socketry/async-redis"
	
	spec.files = Dir.glob(['{lib}/**/*', '*.md'], File::FNM_DOTMATCH, base: __dir__)
	
	spec.add_dependency "async", [">= 1.8", "< 3.0"]
	spec.add_dependency "async-io", "~> 1.10"
	spec.add_dependency "async-pool", "~> 0.2"
	spec.add_dependency "protocol-redis", "~> 0.6"
	
	spec.add_development_dependency "async-rspec", "~> 1.1"
	spec.add_development_dependency "benchmark-ips"
	spec.add_development_dependency "bundler"
	spec.add_development_dependency "covered"
	spec.add_development_dependency "hiredis"
	spec.add_development_dependency "rake"
	spec.add_development_dependency "redis"
	spec.add_development_dependency "rspec", "~> 3.6"
end
