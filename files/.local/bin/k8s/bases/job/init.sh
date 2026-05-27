#!/usr/bin/env sh
set -eu

generate_base_job() {
  API_VERSION=batch/v1
  KIND=Job
  PRIMARY_CONTAINER=busybox

  export API_VERSION KIND PRIMARY_CONTAINER
  envsubst '$API_VERSION $KIND $NAME $PRIMARY_CONTAINER' \
    <"$K8S_GEN_DIR/bases/job/resource.yaml" \
    >"$K8S_GEN_RESOURCES_DIR/job.yaml"
}

register_base job generate_base_job
