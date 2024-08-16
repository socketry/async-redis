# Cluster Testing

To test clusters, you need to set up three redis instances (shards) and bind them together into a cluster.

## Running Tests

``` bash
$ cd cluster
$ docker-compose up tests
[+] Running 5/0
 ✔ Container cluster-redis-b-1     Running
 ✔ Container cluster-redis-c-1     Running
 ✔ Container cluster-redis-a-1     Running
 ✔ Container cluster-controller-1  Running
 ✔ Container cluster-tests-1       Created
Attaching to tests-1
tests-1  | Bundle complete! 13 Gemfile dependencies, 41 gems now installed.
tests-1  | Use `bundle info [gemname]` to see where a bundled gem is installed.
tests-1  | 6 installed gems you directly depend on are looking for funding.
tests-1  |   Run `bundle fund` for details
tests-1  | 0 assertions
tests-1  | 🏁 Finished in 4.9ms; 0.0 assertions per second.
tests-1  | 🐇 No slow tests found! Well done!
tests-1 exited with code 0
```