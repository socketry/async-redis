#!/usr/bin/env ruby

require 'async'
require 'redis'

Async do |parent|
	child = Async do |task|
		redis = Redis.new
		Console.logger.info(task, "blpop")
		puts redis.blpop("mylist")
	end

	redis = Redis.new
	Console.logger.info(parent, "lpush")
	redis.lpush("mylist", "Hello World")

	child.wait
end

