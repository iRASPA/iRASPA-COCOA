#!/bin/sh
#
# Fails the build when a Git LFS-tracked binary is still an unresolved pointer.
#
# A clone made without the LFS smudge filter leaves a ~130-byte text stub in
# place of each large file. Xcode copies that stub into the app bundle without
# complaint, producing a build that links but ships an unusable Gallery, so the
# failure has to be caught here rather than at runtime.

set -u

# Allow running by hand from anywhere, not just as an Xcode build phase.
SRCROOT="${SRCROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

POINTER_MAGIC='version https://git-lfs.github.com/spec/v1'
POINTER_MAGIC_LEN=42
status=0

for file in \
  "$SRCROOT"/iRASPA/StructureDatabases/*.irspdoc \
  "$SRCROOT"/iRASPA/StructureDatabases/*.data \
  "$SRCROOT"/PythonKit/*.a
do
  # An unmatched glob stays literal; nothing to check in that case.
  case "$file" in *'*'*) continue ;; esac

  if [ "$(head -c "$POINTER_MAGIC_LEN" "$file" 2>/dev/null)" = "$POINTER_MAGIC" ]; then
    echo "error: unresolved Git LFS pointer: ${file#$SRCROOT/}"
    status=1
  fi
done

if [ "$status" -ne 0 ]; then
  echo "error: Git LFS content is not checked out, so the build would ship placeholder files."
  echo "error: Fix it with:  git lfs install && git lfs pull"
  exit 1
fi

exit 0
