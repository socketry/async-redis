# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# gem "protocol-redis", path: "../protocol-redis"

group :maintenance, optional: true do
	gem "bake-gem"
	gem "bake-modernize"
end

group :test do
	gem "bake-test"
end
