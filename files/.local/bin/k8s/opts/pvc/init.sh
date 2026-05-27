#!/usr/bin/env sh
set -eu

parse_opt_pvc() {
  [ "$#" -ge 2 ] || return 1
  select_opt pvc "$2"
  K8S_GEN_PARSE_CONSUMED=2
}

generate_opt_pvc() {
  PVC_NAME=$K8S_GEN_OPT_VALUE
  export PVC_NAME
  envsubst '$API_VERSION $KIND $NAME $PRIMARY_CONTAINER $PVC_NAME' \
    <"$K8S_GEN_DIR/opts/pvc/patch.yaml" \
    >"$K8S_GEN_PATCHES_DIR/pvc.yaml"
}

register_opt pvc pvc "Mount an existing PVC" parse_opt_pvc generate_opt_pvc
