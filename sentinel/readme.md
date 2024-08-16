# Sentinel Testing

To test sentinels, you need to set up master, slave and sentinel instances.

## Setup

``` bash
$ cd sentinel
$ docker-compose up tests
[+] Running 4/0
 ✔ Container sentinel-redis-master-1    Created
 ✔ Container sentinel-redis-slave-1     Created
 ✔ Container sentinel-redis-sentinel-1  Created
 ✔ Container sentinel-tests-1           Created
Attaching to tests-1
tests-1  | Bundle complete! 13 Gemfile dependencies, 41 gems now installed.
tests-1  | Use `bundle info [gemname]` to see where a bundled gem is installed.
tests-1  | 6 installed gems you directly depend on are looking for funding.
tests-1  |   Run `bundle fund` for details
tests-1  | 3 passed out of 3 total (3 assertions)
tests-1  | 🏁 Finished in 4.1s; 0.74 assertions per second.
tests-1  | 🐢 Slow tests:
tests-1  | 	4.1s: describe Async::Redis::SentinelClient it should resolve slave address sentinel/test/async/redis/sentinel_client.rb:35
tests-1 exited with code 0

```

