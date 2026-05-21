#!/usr/bin/env bash
# Lightweight AST-aware sensitive-pattern check.
# Inspects given files using language-native parsers (Python's `ast` for .py)
# and falls back to comment/string-stripped grep for other languages.
#
# Reads one file path per argument or via stdin (one per line).
# Prints `<file>\t<verdict>` lines where verdict is "sensitive" or "clean".
# Exits 0 always; the caller decides what to do with verdicts.

set -uo pipefail

PATTERN='auth|permission|secret|billing|schema|migration'

inspect_python() {
  local file="$1"
  python3 - "$file" "$PATTERN" <<'PY'
import ast
import re
import sys

path, pattern = sys.argv[1], sys.argv[2]
rx = re.compile(pattern, re.IGNORECASE)
try:
    source = open(path, encoding="utf-8", errors="replace").read()
    tree = ast.parse(source, filename=path)
except (OSError, SyntaxError):
    print("unknown")
    sys.exit(0)

def has_match(node):
    for child in ast.walk(node):
        if isinstance(child, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            if rx.search(child.name):
                return True
        if isinstance(child, ast.Name) and rx.search(child.id):
            return True
        if isinstance(child, ast.Attribute) and rx.search(child.attr):
            return True
        if isinstance(child, (ast.Import, ast.ImportFrom)):
            names = [n.name for n in child.names]
            if isinstance(child, ast.ImportFrom) and child.module:
                names.append(child.module)
            if any(rx.search(n) for n in names):
                return True
    return False

print("sensitive" if has_match(tree) else "clean")
PY
}

strip_comments_and_strings() {
  local file="$1"
  case "$file" in
    *.js|*.jsx|*.ts|*.tsx|*.go|*.java|*.c|*.cpp|*.h|*.rs|*.swift|*.kt)
      sed -e 's://.*$::' -e 's:/\*.*\*/::g' "$file" 2>/dev/null \
        | sed -e "s/\"[^\"]*\"//g" -e "s/'[^']*'//g"
      ;;
    *.sh|*.bash|*.zsh|*.rb|*.py|*.yml|*.yaml)
      sed -e 's:#.*$::' "$file" 2>/dev/null \
        | sed -e "s/\"[^\"]*\"//g" -e "s/'[^']*'//g"
      ;;
    *)
      cat "$file" 2>/dev/null
      ;;
  esac
}

inspect_generic() {
  local file="$1"
  local stripped
  stripped="$(strip_comments_and_strings "$file")"
  if printf '%s' "$stripped" | grep -qiE "$PATTERN"; then
    printf 'sensitive'
  else
    printf 'clean'
  fi
}

process() {
  local file="$1"
  [ -z "$file" ] && return 0
  [ -f "$file" ] || return 0
  local verdict
  case "$file" in
    *.py)
      if command -v python3 >/dev/null 2>&1; then
        verdict="$(inspect_python "$file")"
      else
        verdict="$(inspect_generic "$file")"
      fi
      ;;
    *)
      verdict="$(inspect_generic "$file")"
      ;;
  esac
  printf '%s\t%s\n' "$file" "$verdict"
}

if [ "$#" -gt 0 ]; then
  for f in "$@"; do
    process "$f"
  done
else
  while IFS= read -r line; do
    process "$line"
  done
fi

exit 0
