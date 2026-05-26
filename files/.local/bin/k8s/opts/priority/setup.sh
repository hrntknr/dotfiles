#!/usr/bin/env sh
set -eu

cat >"$K8S_GEN_COMPONENT_DIR/patch.yaml" <<EOF
apiVersion: $BASE_API_VERSION
kind: $BASE_KIND
metadata:
  name: \${NAME}
spec:
  template:
    spec:
      priorityClassName: "$PRIORITY_CLASS_NAME"
EOF
