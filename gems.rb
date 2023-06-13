# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2023, by Samuel Williams.

source 'https://rubygems.org'

gemspec

# gem "protocol-redis", path: "../protocol-redis"

group :maintenance, optional: true do
	gem "bake-modernize"
	gem "bake-gem"
	
	gem "utopia-project", "~> 0.18"
end

group :test do
	gem "bake-test"
	gem "bake-test-external"
	
	gem "hiredis"
	
	gem "covered"
	
	gem "sus"
	gem "sus-fixtures-async"
end
