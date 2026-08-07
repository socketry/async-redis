# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2018-2026, by Samuel Williams.

source "https://rubygems.org"

gemspec

# gem "protocol-redis", path: "../protocol-redis"

group :maintenance, optional: true do
	gem "bake-modernize"
	gem "bake-gem"
	gem "bake-releases"
	
	gem "agent-context"
	
	gem "utopia-project"
	gem "decode"
end

group :test do
	gem "sus"
	gem "covered"
	gem "redis"
	
	gem "rubocop"
	gem "rubocop-md"
	gem "rubocop-socketry"
	
	gem "bake-test"
	gem "bake-test-external"
	gem "bake-test-integration"
	
	gem "sus-fixtures-async"
end
