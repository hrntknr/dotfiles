#!/usr/bin/env sh
set -eu

cat >"$K8S_GEN_COMPONENT_DIR/patch.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: \${NAME}
spec:
  template:
    spec:
      priorityClassName: "$PRIORITY_CLASS_NAME"
EOF
