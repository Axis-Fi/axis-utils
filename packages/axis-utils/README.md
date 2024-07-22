# axis-utils

This package in the monorepo contains:

- Example scripts (to accompany our [developer guides](https://axis.finance/developer/))
- Scripts for testing installations of the Axis Finance protocol

## Developer Guide

### Requirements

- [foundry](https://getfoundry.sh/)

### Usage

#### Install Dependencies

```shell
pnpm install
```

#### Build

```shell
forge build
```

#### Linting

```shell
pnpm run lint
```

### Dependencies

[soldeer](https://soldeer.xyz/) is used as the dependency manager, as it solves many of the problems inherent in forge's use of git submodules. Soldeer is integrated into `forge`, so should not require any additional installations.

NOTE: The import path of each dependency is versioned. This ensures that any changes to the dependency version result in clear errors to highlight the potentially-breaking change.

#### Updating Dependencies

When updating the version of a dependency provided through soldeer, the following must be performed:

1. Update the version of the dependency in `foundry.toml` or through `forge soldeer`
2. Re-run the [installation script](#install-dependencies)
3. If the version number has changed:
   - Change the existing entry in [remappings.txt](remappings.txt) to point to the new dependency version
   - Update imports to use the new remapping

#### Updating axis-core or axis-periphery

Updating the version of the `axis-core` or `axis-periphery` dependencies is a special case, as some files are accessed directly and bypass remappings. Perform the following after following the [steps above](#updating-dependencies):

1. Update the version in the `axis-core` or `axis-periphery` entry (as appropriate) for the `fs_permissions` key in [foundry.toml](foundry.toml)
2. Update the version mentioned in `_loadEnv()` in the [WithEnvironment](script/WithEnvironment.s.sol) contract
