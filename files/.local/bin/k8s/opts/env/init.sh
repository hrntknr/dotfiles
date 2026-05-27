#!/usr/bin/env sh
set -eu

parse_opt_env() {
  [ "$#" -ge 2 ] || return 1
  case "$2" in
    *=*) ;;
    *) return 1 ;;
  esac
  select_opt env "$2"
  K8S_GEN_PARSE_CONSUMED=2
}

k8s_gen_yaml_single_quote() {
  printf '%s' "$1" | sed "s/'/''/g"
}

generate_opt_env() {
  envsubst '$API_VERSION $KIND $NAME $PRIMARY_CONTAINER' \
    <"$K8S_GEN_DIR/opts/env/patch.yaml" \
    >"$K8S_GEN_PATCHES_DIR/env.yaml"

  printf '%s\n' "$K8S_GEN_OPT_VALUE" | while IFS= read -r env_spec; do
    [ -n "$env_spec" ] || continue
    env_name=${env_spec%%=*}
    env_value=${env_spec#*=}
    printf "            - name: '%s'\n" "$(k8s_gen_yaml_single_quote "$env_name")" >>"$K8S_GEN_PATCHES_DIR/env.yaml"
    printf "              value: '%s'\n" "$(k8s_gen_yaml_single_quote "$env_value")" >>"$K8S_GEN_PATCHES_DIR/env.yaml"
  done
}

register_opt env "name=value" "Add a container environment variable" parse_opt_env generate_opt_env
