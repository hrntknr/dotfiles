#!/usr/bin/env sh
set -eu

generate_base_sh_full() {
  API_VERSION=apps/v1
  KIND=Deployment
  PRIMARY_CONTAINER=sh

  export API_VERSION KIND PRIMARY_CONTAINER
  envsubst '$API_VERSION $KIND $NAME $PRIMARY_CONTAINER' \
    <"$K8S_GEN_DIR/bases/sh-full/resource.yaml" \
    >"$K8S_GEN_RESOURCES_DIR/deployment.yaml"
}

register_base sh-full generate_base_sh_full
