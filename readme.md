# Async::Redis

An asynchronous client for Redis including TLS. Support for streaming requests and responses. Built on top of [async](https://github.com/socketry/async).

[![Development Status](https://github.com/socketry/async-redis/workflows/Test/badge.svg)](https://github.com/socketry/async-redis/actions?workflow=Test)

## Support

This gem supports both Valkey and Redis. It is designed to be compatible with the latest versions of both libraries. We also test Redis sentinel and cluster configurations.

## Usage

Please see the [project documentation](https://socketry.github.io/async-redis/) for more details.

  - [Getting Started](https://socketry.github.io/async-redis/guides/getting-started/index) - This guide explains how to use the `async-redis` gem to connect to a Redis server and perform basic operations.

## Releases

Please see the [project releases](https://socketry.github.io/async-redis/releases/index) for all releases.

### v0.11.1

  - Correctly pass `@options` to `Async::Redis::Client` instances created by `Async::Redis::ClusterClient`.

### v0.10.0

  - [Add support for Redis Clusters](https://socketry.github.io/async-redis/releases/index#add-support-for-redis-clusters)
  - [Add support for Redis Sentinels](https://socketry.github.io/async-redis/releases/index#add-support-for-redis-sentinels)
  - [Improved Integration Tests](https://socketry.github.io/async-redis/releases/index#improved-integration-tests)

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.
