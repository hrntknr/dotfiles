#!/usr/bin/env sh
set -eu

parse_opt_node() {
  [ "$#" -ge 2 ] || return 1
  select_opt node "$2"
  K8S_GEN_PARSE_CONSUMED=2
}

generate_opt_node() {
  NODE_NAME=$K8S_GEN_OPT_VALUE
  export NODE_NAME
  envsubst '$API_VERSION $KIND $NAME $NODE_NAME' \
    <"$K8S_GEN_DIR/opts/node/patch.yaml" \
    >"$K8S_GEN_PATCHES_DIR/node.yaml"
}

register_opt node node "Pin the pod to a node" parse_opt_node generate_opt_node
