#!/usr/bin/env sh
set -eu

generate_opt_mncore2() {
  envsubst '$API_VERSION $KIND $NAME $PRIMARY_CONTAINER' \
    <"$K8S_GEN_DIR/opts/mncore2/patch.yaml" \
    >"$K8S_GEN_PATCHES_DIR/mncore2.yaml"
}

parse_opt_mncore2() {
  select_opt mncore2
  K8S_GEN_PARSE_CONSUMED=1
}

register_opt mncore2 "" "Add MN-Core 2 resources" parse_opt_mncore2 generate_opt_mncore2
