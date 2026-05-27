#!/usr/bin/env sh
set -eu

parse_opt_secret() {
  [ "$#" -ge 2 ] || return 1
  case "$2" in
    *=*) ;;
    *) return 1 ;;
  esac
  select_opt secret "$2"
  K8S_GEN_PARSE_CONSUMED=2
}

secret_yaml_single_quote() {
  printf '%s' "$1" | sed "s/'/''/g"
}

generate_opt_secret() (
  tmp_dir=$(mktemp -d)
  trap 'rm -rf "$tmp_dir"' EXIT INT TERM

  SECRET_NAME=$NAME-env
  export SECRET_NAME

  envsubst '$SECRET_NAME' \
    <"$K8S_GEN_DIR/opts/secret/secret.yaml" \
    >"$tmp_dir/secret.yaml"

  envsubst '$API_VERSION $KIND $NAME $PRIMARY_CONTAINER $SECRET_NAME' \
    <"$K8S_GEN_DIR/opts/secret/patch.yaml" \
    >"$K8S_GEN_PATCHES_DIR/secret.yaml"

  printf '%s\n' "$K8S_GEN_OPT_VALUE" | while IFS= read -r env_spec; do
    [ -n "$env_spec" ] || continue
    env_name=${env_spec%%=*}
    env_value=${env_spec#*=}

    printf "  '%s': '%s'\n" \
      "$(secret_yaml_single_quote "$env_name")" \
      "$(secret_yaml_single_quote "$env_value")" >>"$tmp_dir/secret.yaml"
  done

  seal <"$tmp_dir/secret.yaml" >"$K8S_GEN_RESOURCES_DIR/secret.yaml"
)

register_opt secret "name=value" "Add a container environment variable from a Secret" parse_opt_secret generate_opt_secret
