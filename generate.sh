#!/usr/bin/env sh
set -eu

if [ $# -ne 1 ]; then
  echo "usage: $0 <path-to-rust-crate>"
  exit 1
fi

SOURCE_REPO=$(cd "$1" && pwd)
DOCS_ROOT=$(pwd)

# Infer crate name from Cargo metadata
PROJECT=$(
  cd "$SOURCE_REPO" &&
  cargo metadata --no-deps --format-version 1 \
    | jq -r '.packages[0].name'
)

OUT="$DOCS_ROOT/$PROJECT"
TMP_TARGET="$(mktemp -d)"

export RUSTDOCFLAGS="--html-in-header $DOCS_ROOT/katex-header.html"

# 1. Build docs via cargo
(
  cd "$SOURCE_REPO"
  cargo doc --no-deps --document-private-items --target-dir "$TMP_TARGET"
)

# 2. Replace generated docs
rm -rf "$OUT"
mkdir -p "$OUT"

# Copy full rustdoc site (themes, JS, CSS)
cp -r "$TMP_TARGET/doc/"* "$OUT/"

# 3. Root redirect
cat > "$OUT/index.html" <<EOF
<!doctype html>
<meta http-equiv="refresh" content="0; url=./$PROJECT/">
<title>$PROJECT documentation</title>
EOF

# 4. Cleanup
rm -rf "$TMP_TARGET"

echo "Generated docs for $PROJECT"
