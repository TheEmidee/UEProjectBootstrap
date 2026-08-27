# Changelog

All notable changes to this package will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Changed the package to now use python instead of powershell. The package should not be in the project folder anymore but instead modify an external project, which is defined by the uproject argument
- `Setup.ps1` now offers to apply performance optimizations (Windows Defender and Search indexing exclusions on the repository root), self-elevating if needed. Skipped on `-BuildMachine`.

## [1.2.0] - 2026-06-23

### Added

- Added buildgraph template files and basic jenkins config files to use with [JenkinsFileGenerator](https://github.com/TheEmidee/JenkinsfileGenerator)

## [1.1.1] - 2026-04-01

### Changed

- Added argument `--upgrade` when running `uv pip install`

## [1.1.0] - 2026-03-16

### Added

- Parameter `BuildMachine` in `Setup.ps1` to prevent installing pre-commit hooks and run python setup scripts
- Created separate script for pre-commit installation

## [1.0.0] - 2026-02-15

### Added

- First version of the package.