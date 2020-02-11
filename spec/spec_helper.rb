# frozen_string_literal: true

require 'covered/rspec'

require 'async/rspec'

# Async.logger.level = Logger::DEBUG

RSpec.configure do |config|
	config.disable_monkey_patching
	
	# Enable flags like --only-failures and --next-failure
	config.example_status_persistence_file_path = ".rspec_status"

	config.expect_with :rspec do |c|
		c.syntax = :expect
	end
end
