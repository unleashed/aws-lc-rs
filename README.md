# AWS Libcrypto for Rust

This is a FIPS only statically linked version of aws-lc-rs pinned to version 1.11.1, which vendors aws-lc-fips-sys 0.12.15, which in turn vendors AWS-LC 2 as certified for FIPS-140-3.

The way this crate is meant to produce FIPS-140-3 compliant modules is by building in two phases:

* Prebuild phase: statically build AWS-LC 2 (FIPS-140-3 module), a Rust shim, and bindings, then place these artifacts in a known place.
* Build with prebuilt FIPS-140-3 module artifacts: Pick up the above artifacts and link them in your app by adding to your Cargo.toml:

```toml
[dependencies]
# If you use rustls, uncomment the line just below
# rustls = { version = "=0.23.20", default-features = false, features = ["aws-lc-rs", "fips"] }
aws-lc-rs = { version = "= 1.11.1, < 1.12.0", default-features = false, features = ["fips", "bindgen"] }
aws-lc-fips-sys = { version = "= 0.12.15", default-features = false, features = ["bindgen"] }

[patch.crates-io]
aws-lc-rs = { path = "/path/to/aws-lc-rs/aws-lc-rs" }
aws-lc-fips-sys = { path = "/path/to/aws-lc-rs/aws-lc-fips-sys" }
```

## Prebuild

### Requirements

Currently we require `just` and `docker`.

You typically clone this repository (locate it so you know how to patch Cargo.toml from your app) and execute:

> just

If you want to change where the artifacts will be stored, you can specify the path like so:

> just prebuilt_dir=/path/to/artifacts

In addition you may want to be interested in using a specific Rust version:

> just rust_version=1.91.1

This process will build an Operational Environment in the Security Policy of the FIPS-140-3 Certificate for AWS-LC 2, based on Ubuntu 22.04, build the artifacts within the OE with a specific Rust version (printed for your convenience), and store them in the configured directory (use `just env` to see what that could be by default). You can follow the process to make sure the right environment and compilers are being built.

You can check other `just` targets via `just --list`.

## Depending on this crate for your app

Ensuring that your application building with cargo picks up the relevant FIPS-140-3 cryptography code (statically) means that you'll need to point cargo to this crate. Using the patching feature of cargo you can make sure that no other versions are pulled in.

In the `app` directory you can find a sample app built in this way. Once you have the prebuilt artifacts, run:

> just

You can also point the app to the right directory for the artifacts this other way:

> just prebuilt_dir=/path/to/artifacts

Once you build the app, you can type `just run` and let it try to determine whether it's in FIPS mode.
