# Sentinel Testing

To test sentinels, you need to set up master, slave and sentinel instances.

## Setup

``` bash
$ cd sentinel
$ docker-compose up tests
[+] Running 3/3
 ✔ Container sentinel-redis-master-1    Running                              0.0s 
 ✔ Container sentinel-redis-slave-1     Running                              0.0s 
 ✔ Container sentinel-redis-sentinel-1  Started                              0.2s 
```

## Test

``` bash
$ ASYNC_REDIS_MASTER=redis://redis-master:6379 ASYNC_REDIS_SLAVE=redis://redis-slave:6379 ASYNC_REDIS_SENTINEL=redis://redis-sentinel:26379 bundle exec sus
```
