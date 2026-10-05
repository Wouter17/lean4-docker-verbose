FROM ubuntu:24.04

# Lean toolchain pinned by Verbose's lean-toolchain file, e.g. "leanprover/lean4:v4.31.0".
ARG LEAN_TOOLCHAIN
# Verbose git revision (commit SHA, tag or branch).
ARG VERBOSE_REV=master

RUN test -n "${LEAN_TOOLCHAIN}" \
    || { echo "LEAN_TOOLCHAIN build arg is required" >&2; exit 1; }

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential ca-certificates curl git \
    && rm -rf /var/lib/apt/lists/*

# ubuntu:24.04 ships with a non-root "ubuntu" user (UID 1000).
USER ubuntu
ENV ELAN_HOME=/home/ubuntu/.elan
ENV PATH="${ELAN_HOME}/bin:${PATH}"

RUN curl -sSfL https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh \
        | sh -s -- -y --no-modify-path --default-toolchain none

# Copying to a not-yet-existing dir makes it owned by "ubuntu".
COPY --chown=ubuntu:ubuntu project/ /home/ubuntu/project/
WORKDIR /home/ubuntu/project

RUN sed -i "s|@VERBOSE_REV@|${VERBOSE_REV}|" lakefile.toml \
    && printf '%s\n' "${LEAN_TOOLCHAIN}" > lean-toolchain

# Fetch Verbose + Mathlib, download Mathlib's prebuilt .olean cache (instead of
# compiling Mathlib), build the project, then drop the download cache so it
# doesn't bloat the image layer.
RUN export MATHLIB_CACHE_DIR=/tmp/mathlib-cache \
    && lake update \
    && lake exe cache get \
    && lake build \
    && rm -rf /tmp/mathlib-cache "$HOME/.cache/mathlib"

CMD ["bash"]
