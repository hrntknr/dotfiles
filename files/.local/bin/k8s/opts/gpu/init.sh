#!/usr/bin/env sh
set -eu

generate_opt_gpu() {
  envsubst '$API_VERSION $KIND $NAME $PRIMARY_CONTAINER' \
    <"$K8S_GEN_DIR/opts/gpu/patch.yaml" \
    >"$K8S_GEN_PATCHES_DIR/gpu.yaml"
}

parse_opt_gpu() {
  select_opt gpu
  K8S_GEN_PARSE_CONSUMED=1
}

register_opt gpu "" "Add NVIDIA GPU resources" parse_opt_gpu generate_opt_gpu
