# frozen_string_literal: true

require_relative "lib/async/redis/version"

Gem::Specification.new do |spec|
	spec.name = "async-redis"
	spec.version = Async::Redis::VERSION
	
	spec.summary = "A Redis client library."
	spec.authors = ["Samuel Williams", "Huba Nagy", "David Ortiz", "Gleb Sinyavskiy", "Mikael Henriksson", "Travis Bell", "Troex Nevelin", "Alex Matchneer", "Jeremy Jung", "Joan Lledó", "Olle Jonsson", "Pierre Montelle", "Salim Semaoune", "Tim Willard"]
	spec.license = "MIT"
	
	spec.cert_chain  = ["release.cert"]
	spec.signing_key = File.expand_path("~/.gem/release.pem")
	
	spec.homepage = "https://github.com/socketry/async-redis"
	
	spec.metadata = {
		"documentation_uri" => "https://socketry.github.io/async-redis/",
		"source_code_uri" => "https://github.com/socketry/async-redis.git",
	}
	
	spec.files = Dir.glob(["{context,lib}/**/*", "*.md"], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 3.2"
	
	spec.add_dependency "async", "~> 2.10"
	spec.add_dependency "async-pool", "~> 0.2"
	spec.add_dependency "io-endpoint", "~> 0.10"
	spec.add_dependency "io-stream", "~> 0.4"
	spec.add_dependency "protocol-redis", "~> 0.9"
end
