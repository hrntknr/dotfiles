#!/usr/bin/env sh
set -eu

parse_opt_priority() {
  [ "$#" -ge 2 ] || return 1
  select_opt priority "$2"
  K8S_GEN_PARSE_CONSUMED=2
}

generate_opt_priority() {
  PRIORITY_CLASS_NAME=$K8S_GEN_OPT_VALUE
  export PRIORITY_CLASS_NAME
  envsubst '$API_VERSION $KIND $NAME $PRIORITY_CLASS_NAME' \
    <"$K8S_GEN_DIR/opts/priority/patch.yaml" \
    >"$K8S_GEN_PATCHES_DIR/priority.yaml"
}

register_opt priority class "Set priorityClassName" parse_opt_priority generate_opt_priority
