# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2025, by Samuel Williams.

source "https://rubygems.org"

gemspec

# gem "protocol-redis", path: "../protocol-redis"

group :maintenance, optional: true do
	gem "bake-modernize"
	gem "bake-gem"
	gem "bake-releases"
	
	gem "agent-context"
	
	gem "utopia-project"
end

group :test do
	gem "sus"
	gem "covered"
	gem "decode"
	
	gem "rubocop"
	gem "rubocop-md"
	gem "rubocop-socketry"
	
	gem "bake-test"
	gem "bake-test-external"
	
	gem "sus-fixtures-async"
	
	gem "redis"
	gem "hiredis"
end
