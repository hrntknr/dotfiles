#!/usr/bin/env sh
set -eu

generate_opt_persist_host_keys() (
  tmp_dir=$(mktemp -d)
  trap 'rm -rf "$tmp_dir"' EXIT INT TERM
  key_file=$tmp_dir/ssh_host_ed25519_key
  secret_file=$tmp_dir/host-keys-secret.yaml

  ssh-keygen -t ed25519 -N "" -C "" -f "$key_file" >/dev/null
  HOST_KEY_DATA=$(base64 <"$key_file" | tr -d '\n')
  HOST_KEYS_SECRET_NAME=$NAME-host-keys
  export HOST_KEY_DATA HOST_KEYS_SECRET_NAME

  envsubst '$HOST_KEYS_SECRET_NAME $HOST_KEY_DATA' \
    <"$K8S_GEN_DIR/opts/persist-host-keys/secret.yaml" \
    >"$secret_file"

  seal <"$secret_file" >"$K8S_GEN_RESOURCES_DIR/host-keys.yaml"

  envsubst '$API_VERSION $KIND $NAME $PRIMARY_CONTAINER $HOST_KEYS_SECRET_NAME' \
    <"$K8S_GEN_DIR/opts/persist-host-keys/patch.yaml" \
    >"$K8S_GEN_PATCHES_DIR/persist-host-keys.yaml"
)

parse_opt_persist_host_keys() {
  select_opt persist-host-keys
  K8S_GEN_PARSE_CONSUMED=1
}

register_opt persist-host-keys "" "Persist SSH host keys" parse_opt_persist_host_keys generate_opt_persist_host_keys
