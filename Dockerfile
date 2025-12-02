FROM ubuntu:22.04

RUN DEBIAN_FRONTEND=noninteractive APT_LISTCHANGES_FRONTEND=none \
  apt update && \
  apt upgrade -y && \
  apt install -y --no-install-recommends bash ca-certificates build-essential clang libssl-dev golang perl cmake ninja-build curl sudo && \
  apt autoremove --purge -y && \
  apt clean && \
  rm -rf /var/lib/apt/lists/* 

ARG USER=fips
ARG UID=1000
ARG GID=1000

RUN groupadd -g ${GID} -o ${USER} && \
  useradd -m -u ${UID} -g ${GID} -o -s /bin/bash ${USER}

USER ${USER}:${USER}

RUN curl --proto '=https' --tlsv1.3 -sSf https://sh.rustup.rs | bash -s -- -v -y --profile minimal --default-toolchain none

ARG RUST_VERSION="1.90.0"
RUN bash -l -c "rustup default \"${RUST_VERSION}\""

ARG JUST_VERSION="1.43.1"
RUN bash -l -c "cargo install --locked just@\"${JUST_VERSION}\""

ARG SOURCES="/crate"
WORKDIR "${SOURCES}"

CMD ["bash", "-l", "-c", "cargo --version && clang --version && cat /etc/lsb-release && just _fips-build && just _fips-collect"]
