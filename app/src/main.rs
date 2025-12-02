use aws_lc_rs::try_fips_mode;
//use rustls::crypto::aws_lc_rs::default_provider;
use rustls::crypto::default_fips_provider;

fn main() {
    // Runtime Verification
    // This returns true only if the FIPS module was successfully linked and initialized.
    if let Ok(()) = try_fips_mode() {
        println!("FIPS mode is ACTIVE.");
    } else {
        panic!("CRITICAL: FIPS mode NOT active. Terminating.");
    }

    // Configure TLS to strict FIPS defaults
    // This enforces FIPS-approved cipher suites (removing ChaCha20, etc.)
    let fips_provider = default_fips_provider();

    // Install as the process-wide default for rustls
    fips_provider
        .install_default()
        .expect("Failed to install FIPS crypto provider");

    println!("TLS stack configured with FIPS-approved algorithms.");
}
