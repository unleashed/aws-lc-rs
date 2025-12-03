prebuilt_dir := env("AWS_LC_FIPS_PREBUILT", "/tmp/aws-lc-rs-fips-0.12.15")
release := env("CARGO_RELEASE_MODE", "--release")
build_base := justfile_directory() + "/target/release"
rust_version := env("RUST_VERSION", "1.90.0")
just_version := env("JUST_VERSION", shell(just_executable() + " --version | cut -d' ' -f 2"))
docker_build_args := ""

default: build-artifacts

[group("build")]
build-artifacts: docker-build test-prebuilt-dir
	"{{ just_executable() }}" -f "{{ justfile() }}" \
	        prebuilt_dir="{{ prebuilt_dir }}" release="{{ release }}" \
	        rust_version="{{ rust_version }}" just_version="{{ just_version }}" \
	        docker-image-cleanup
	@echo "Set env var AWS_LC_FIPS_PREBUILT={{ prebuilt_dir }} when building your app"
	@echo "---"
	@echo "Here's the environment you need to build your app:"
	@echo "---"
	@echo "export AWS_LC_FIPS_PREBUILT=\"{{ prebuilt_dir }}\""
	@echo "export DEP_AWS_LC_FIPS_0_12_15_INCLUDE=\"{{ prebuilt_dir }}/include\""
	@echo "export DEP_AWS_LC_FIPS_0_12_15_LIBCRYPTO=aws_lc_fips_0_12_15_crypto"
	@echo "export DEP_AWS_LC_FIPS_0_12_15_ROOT=\"{{ prebuilt_dir }}\""
	@echo "export DEP_AWS_LC_FIPS_0_12_15_CONF=OPENSSL_NO_ASYNC,OPENSSL_NO_BF,OPENSSL_NO_BLAKE2,OPENSSL_NO_BUF_FREELISTS,OPENSSL_NO_CAMELLIA,OPENSSL_NO_CAPIENG,OPENSSL_NO_CAST,OPENSSL_NO_CMS,OPENSSL_NO_COMP,OPENSSL_NO_CT,OPENSSL_NO_DANE,OPENSSL_NO_DEPRECATED,OPENSSL_NO_DGRAM,OPENSSL_NO_DYNAMIC_ENGINE,OPENSSL_NO_EC_NISTP_64_GCC_128,OPENSSL_NO_EC2M,OPENSSL_NO_EGD,OPENSSL_NO_ENGINE,OPENSSL_NO_GMP,OPENSSL_NO_GOST,OPENSSL_NO_HEARTBEATS,OPENSSL_NO_HW,OPENSSL_NO_IDEA,OPENSSL_NO_JPAKE,OPENSSL_NO_KRB5,OPENSSL_NO_MD2,OPENSSL_NO_MDC2,OPENSSL_NO_OCB,OPENSSL_NO_OCSP,OPENSSL_NO_RC2,OPENSSL_NO_RC5,OPENSSL_NO_RFC3779,OPENSSL_NO_RIPEMD,OPENSSL_NO_RMD160,OPENSSL_NO_SCTP,OPENSSL_NO_SEED,OPENSSL_NO_SM2,OPENSSL_NO_SM3,OPENSSL_NO_SM4,OPENSSL_NO_SRP,OPENSSL_NO_SSL_TRACE,OPENSSL_NO_SSL2,OPENSSL_NO_SSL3,OPENSSL_NO_SSL3_METHOD,OPENSSL_NO_STATIC_ENGINE,OPENSSL_NO_STORE,OPENSSL_NO_WHIRLPOOL"

[group("build")]
byob: test-prebuilt-dir fips-prebuilt

clean:
	cargo clean

[private]
env-prebuilt:
	@echo "[env] AWS_LC_FIPS_PREBUILT={{ env("AWS_LC_FIPS_PREBUILT", "(unset)") }}"
	@echo "[just] prebuilt-dir={{ prebuilt_dir }}"

[private]
env-docker:
	@echo "[docker] docker_build_args={{ docker_build_args }}"

[private]
env-build:
	@echo "[rust] rust_version={{ rust_version }}"
	@echo "[just] just_version={{ just_version }}"
	@echo "[cargo] release={{ release }}"

env: env-prebuilt env-build env-docker

[private]
mkdir:
	mkdir -p "{{ prebuilt_dir }}"

[group("docker")]
docker-image-build: env-docker
	docker build -t fips-builder --build-arg UID=$(id -u) --build-arg GID=$(id -g) --build-arg RUST_VERSION="{{ rust_version }}" --build-arg JUST_VERSION="{{ just_version }}" -f "{{ justfile_directory() }}/Dockerfile" {{ docker_build_args }} "{{ justfile_directory() }}"

[group("docker")]
docker-image-cleanup:
	docker rmi fips-builder

[group("docker")]
docker-build: docker-image-build mkdir
	#!/usr/bin/env bash
	set -euo pipefail
	ttyflags="-i "
	if [ ! -t 0 ]; then
	  ttyflags=""
	fi
	docker run --rm -v ./:/crate/ -v "{{ prebuilt_dir }}":/tmp/aws-lc-rs-fips-0.12.15 -e CARGO_RELEASE_MODE="{{ release }}" -e RUST_VERSION="{{ rust_version }}" -e JUST_VERSION="{{ just_version }}" -t ${ttyflags} fips-builder:latest

[group("fips")]
[private]
_fips-build: env-prebuilt env-build clean
	cargo build -p aws-lc-rs "{{ release }}" --no-default-features -F fips -F bindgen

[group("fips")]
[private]
_fips-collect: env-prebuilt mkdir
	#!/usr/bin/env bash
	set -euo pipefail
	mkdir -p "{{ prebuilt_dir }}"
	find "{{ build_base }}" -type f -name bindings.rs -exec cp {} "{{ prebuilt_dir }}" \;
	find "{{ build_base }}" -type d -name include -exec cp -a {} "{{ prebuilt_dir }}" \; && \
	find "{{ build_base }}" -type f -name "libaws_lc_fips_*.a" -exec cp {} "{{ prebuilt_dir }}" \;

[group("fips")]
[private]
fips-prebuilt: clean
	AWS_LC_FIPS_PREBUILT="{{ prebuilt_dir }}" \
	DEP_AWS_LC_FIPS_0_12_15_INCLUDE="{{ prebuilt_dir }}/include" \
	DEP_AWS_LC_FIPS_0_12_15_LIBCRYPTO=aws_lc_fips_0_12_15_crypto \
	DEP_AWS_LC_FIPS_0_12_15_ROOT="{{ prebuilt_dir }}" \
	DEP_AWS_LC_FIPS_0_12_15_CONF="OPENSSL_NO_ASYNC,OPENSSL_NO_BF,OPENSSL_NO_BLAKE2,OPENSSL_NO_BUF_FREELISTS,OPENSSL_NO_CAMELLIA,OPENSSL_NO_CAPIENG,OPENSSL_NO_CAST,OPENSSL_NO_CMS,OPENSSL_NO_COMP,OPENSSL_NO_CT,OPENSSL_NO_DANE,OPENSSL_NO_DEPRECATED,OPENSSL_NO_DGRAM,OPENSSL_NO_DYNAMIC_ENGINE,OPENSSL_NO_EC_NISTP_64_GCC_128,OPENSSL_NO_EC2M,OPENSSL_NO_EGD,OPENSSL_NO_ENGINE,OPENSSL_NO_GMP,OPENSSL_NO_GOST,OPENSSL_NO_HEARTBEATS,OPENSSL_NO_HW,OPENSSL_NO_IDEA,OPENSSL_NO_JPAKE,OPENSSL_NO_KRB5,OPENSSL_NO_MD2,OPENSSL_NO_MDC2,OPENSSL_NO_OCB,OPENSSL_NO_OCSP,OPENSSL_NO_RC2,OPENSSL_NO_RC5,OPENSSL_NO_RFC3779,OPENSSL_NO_RIPEMD,OPENSSL_NO_RMD160,OPENSSL_NO_SCTP,OPENSSL_NO_SEED,OPENSSL_NO_SM2,OPENSSL_NO_SM3,OPENSSL_NO_SM4,OPENSSL_NO_SRP,OPENSSL_NO_SSL_TRACE,OPENSSL_NO_SSL2,OPENSSL_NO_SSL3,OPENSSL_NO_SSL3_METHOD,OPENSSL_NO_STATIC_ENGINE,OPENSSL_NO_STORE,OPENSSL_NO_WHIRLPOOL" \
	"{{ just_executable() }}" -f "{{ justfile() }}" \
	prebuilt_dir="{{ prebuilt_dir }}" release="{{ release }}" \
	rust_version="{{ rust_version }}" just_version="{{ just_version }}" \
	_fips-build

[private]
test-prebuilt-dir:
	#!/usr/bin/env bash
	set -euo pipefail
	if ! test -r "{{ prebuilt_dir }}/bindings.rs"; then
	  echo >&2 "{{ style("error") }}No bindings found in prebuilt directory{{ NORMAL }}"
	fi

[group("sample-app")]
sample-app-build: test-prebuilt-dir
	"{{ just_executable() }}" -f "{{ justfile_directory() }}/app/Justfile" prebuilt_dir="{{ prebuilt_dir }}" fips-prebuilt

[group("sample-app")]
sample-app-run:
	"{{ just_executable() }}" -f "{{ justfile_directory() }}/app/Justfile" run
