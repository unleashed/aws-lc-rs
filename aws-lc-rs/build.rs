// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0 OR ISC

fn main() {
    use std::env;
    use std::path::PathBuf;

    let requested_fips_feature = !cfg!(feature = "fips");
    assert!(
        !requested_fips_feature,
        "The `fips` feature has not been requested."
    );
    // Use JUST_ARGUMENTS to provide stuff like prebuild directory
    // you want to use, rust version, etc (check Justfile)
    let just_args = env::var("JUST_ARGUMENTS")
        .ok()
        .map(|args| {
            args.split_whitespace()
                .map(String::from)
                .collect::<Vec<String>>()
        })
        .unwrap_or_default();

    let prebuilt_dir = extract_prebuilt_dir_from_args(&just_args)
        .or_else(|| env::var("AWS_LC_FIPS_PREBUILT").ok())
        .unwrap_or_else(|| "/tmp/aws-lc-rs-fips-0.12.15".to_string());

    let prebuilt_dir = PathBuf::from(prebuilt_dir);

    // These are hardcoded because they match our specific version
    env::set_var(
        "DEP_AWS_LC_FIPS_0_12_15_INCLUDE",
        &prebuilt_dir.join("include").to_str().unwrap(),
    );
    env::set_var(
        "DEP_AWS_LC_FIPS_0_12_15_LIBCRYPTO",
        "aws_lc_fips_0_12_15_crypto",
    );
    env::set_var(
        "DEP_AWS_LC_FIPS_0_12_15_ROOT",
        prebuilt_dir.to_str().unwrap(),
    );

    env::set_var("DEP_AWS_LC_FIPS_0_12_15_CONF", "OPENSSL_NO_ASYNC,OPENSSL_NO_BF,OPENSSL_NO_BLAKE2,OPENSSL_NO_BUF_FREELISTS,OPENSSL_NO_CAMELLIA,OPENSSL_NO_CAPIENG,OPENSSL_NO_CAST,OPENSSL_NO_CMS,OPENSSL_NO_COMP,OPENSSL_NO_CT,OPENSSL_NO_DANE,OPENSSL_NO_DEPRECATED,OPENSSL_NO_DGRAM,OPENSSL_NO_DYNAMIC_ENGINE,OPENSSL_NO_EC_NISTP_64_GCC_128,OPENSSL_NO_EC2M,OPENSSL_NO_EGD,OPENSSL_NO_ENGINE,OPENSSL_NO_GMP,OPENSSL_NO_GOST,OPENSSL_NO_HEARTBEATS,OPENSSL_NO_HW,OPENSSL_NO_IDEA,OPENSSL_NO_JPAKE,OPENSSL_NO_KRB5,OPENSSL_NO_MD2,OPENSSL_NO_MDC2,OPENSSL_NO_OCB,OPENSSL_NO_OCSP,OPENSSL_NO_RC2,OPENSSL_NO_RC5,OPENSSL_NO_RFC3779,OPENSSL_NO_RIPEMD,OPENSSL_NO_RMD160,OPENSSL_NO_SCTP,OPENSSL_NO_SEED,OPENSSL_NO_SM2,OPENSSL_NO_SM3,OPENSSL_NO_SM4,OPENSSL_NO_SRP,OPENSSL_NO_SSL_TRACE,OPENSSL_NO_SSL2,OPENSSL_NO_SSL3,OPENSSL_NO_SSL3_METHOD,OPENSSL_NO_STATIC_ENGINE,OPENSSL_NO_STORE,OPENSSL_NO_WHIRLPOOL");

    export_sys_vars("aws-lc-fips-sys");
}

fn extract_prebuilt_dir_from_args(args: &[String]) -> Option<String> {
    for arg in args {
        if let Some(value) = arg.strip_prefix("prebuilt_dir=") {
            return Some(value.to_string());
        }
    }
    None
}

fn export_sys_vars(sys_crate: &str) {
    let prefix = if sys_crate == "aws-lc-fips-sys" {
        "DEP_AWS_LC_FIPS_"
    } else {
        "DEP_AWS_LC_"
    };

    let mut selected = String::default();
    let mut candidates = vec![];

    // search through the DEP vars and find the selected sys crate version
    for (name, value) in std::env::vars() {
        // if we've selected a prefix then we can go straight to exporting it
        if !selected.is_empty() {
            try_export_var(&selected, &name, &value);
            continue;
        }

        // we're still looking for a selected prefix
        if let Some(version) = name.strip_prefix(prefix) {
            if let Some(version) = version.strip_suffix("_INCLUDE") {
                // we've found the selected version so update it and export it
                selected = format!("{prefix}{version}_");
                try_export_var(&selected, &name, &value);
            } else {
                // it started with the expected prefix, but we don't know what the version is yet
                // so save it for later
                candidates.push((name, value));
            }
        }
    }

    assert!(!selected.is_empty(), "missing {prefix} include");

    // process all of the remaining candidates
    for (name, value) in candidates {
        try_export_var(&selected, &name, &value);
    }
}

fn try_export_var(selected: &str, name: &str, value: &str) {
    assert!(!selected.is_empty(), "missing selected prefix");

    if let Some(var) = name.strip_prefix(selected) {
        eprintln!("cargo:rerun-if-env-changed={name}");
        let var = var.to_lowercase();
        println!("cargo:{var}={value}");
    }
}
