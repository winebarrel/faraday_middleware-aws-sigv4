# Changelog

## [1.0.2] - 2026-10-28

### Added

- Add `faraday_middleware/aws/sigv4` entrypoint so that `Bundler.require` loads the gem without a `require:` option. ([#168](https://github.com/winebarrel/faraday_middleware-aws-sigv4/pull/168))

## [1.0.1] - 2022-10-01

### Fixed

- Fix registration of the `:aws_sigv4` middleware on Faraday 2 by registering the class directly instead of a lambda.

## [1.0.0] - 2022-10-01

### Added

- Support Faraday 2.x.

### Changed

- Require `faraday >= 2.0, < 3`.

### Removed

- Drop support for Faraday 1.x.
- Drop support for Ruby 2.4. Ruby 2.5 or later is required.

## [0.6.1] - 2021-12-19

### Fixed

- Fix the Faraday dependency to `>= 1.8, < 2`.

## [0.6.0] - 2021-12-19

### Added

- Support Faraday 1.8.

### Changed

- Require `faraday >= 0.18, < 2`.

## [0.5.0] - 2021-01-07

### Added

- Support Faraday 1.1, 1.2 and 1.3.

### Removed

- Drop support for Ruby 2.3. Ruby 2.4 or later is required.

## [0.4.0] - 2020-10-13

### Added

- Support Faraday 0.17 and 1.0.

## [0.3.0] - 2019-09-30

### Changed

- Require `faraday >= 0.15` and Ruby 2.3 or later.
- Set signature headers one by one instead of `Hash#update` on the request headers.

## [0.2.5] - 2019-09-30

### Changed

- Pin `faraday < 0.15` to keep supporting older Ruby versions.

## [0.2.4] - 2018-01-30

### Changed

- Relax the Faraday dependency to `>= 0.9`.

## [0.2.3] - 2017-10-05

### Removed

- Remove the `Accept` and `Accept-Encoding` header normalization for the Net::HTTP adapter.

## [0.2.2] - 2017-09-12

### Fixed

- Fix `#seahorse_encode_www_form` for array parameter values.

## [0.2.1] - 2017-09-12

### Removed

- Remove the private `#build_signer` method.

## [0.2.0] - 2017-09-12

### Changed

- Build the signer once when the middleware is initialized instead of on every request.

## [0.1.0] - 2017-09-12

### Fixed

- Fix the `Aws::Sigv4::Signer` constant name and the query encoding call used when signing.

## [0.1.0.beta] - 2017-09-11

### Added

- Initial release.

[Unreleased]: https://github.com/winebarrel/faraday_middleware-aws-sigv4/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/winebarrel/faraday_middleware-aws-sigv4/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/winebarrel/faraday_middleware-aws-sigv4/compare/v0.6.1...v1.0.0
[0.6.1]: https://github.com/winebarrel/faraday_middleware-aws-sigv4/compare/v0.6.0...v0.6.1
[0.6.0]: https://github.com/winebarrel/faraday_middleware-aws-sigv4/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/winebarrel/faraday_middleware-aws-sigv4/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/winebarrel/faraday_middleware-aws-sigv4/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/winebarrel/faraday_middleware-aws-sigv4/compare/v0.2.5...v0.3.0
[0.2.5]: https://github.com/winebarrel/faraday_middleware-aws-sigv4/compare/v0.2.4...v0.2.5
[0.2.4]: https://github.com/winebarrel/faraday_middleware-aws-sigv4/compare/v0.2.3...v0.2.4
[0.2.3]: https://github.com/winebarrel/faraday_middleware-aws-sigv4/compare/v0.2.2...v0.2.3
[0.2.2]: https://github.com/winebarrel/faraday_middleware-aws-sigv4/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/winebarrel/faraday_middleware-aws-sigv4/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/winebarrel/faraday_middleware-aws-sigv4/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/winebarrel/faraday_middleware-aws-sigv4/compare/v0.1.0.beta...v0.1.0
[0.1.0.beta]: https://github.com/winebarrel/faraday_middleware-aws-sigv4/releases/tag/v0.1.0.beta
