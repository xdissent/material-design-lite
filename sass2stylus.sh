#!/usr/bin/env bash

set -e

SASS2STYLUS="$0"

# Variable assignments
assignments() {
  sed 's/^\(\$[a-zA-Z0-9_-]*\) *:/\1 =/'
}

# Underscore leading import
underscores() {
  sed 's/@import *"_/@import "/'
}

# Conditional syntax
conditionals() {
  sed -e 's/@if/if/' -e 's/@else/else/'
}

# Operator at end of line
trailing_ops() {
  sed -e '/^ *[&$a-zA-Z0-9_-].*[*+~=)0-]$/ {' -e N -e 's/\n */ /' -e '}'
}

# Mixin definitions
mixins() {
  sed -e '/^@mixin/ {' -e 's/@mixin *//' -e 's/:/ =/g' -e '}'
}

# Mixin includes
includes() {
  sed 's/@include *//'
}

# Convert weird unquote stuff
unquotes() {
  sed 's/unquote(\("rgba*(\)#{\(.*\)}\(.*)"\))/convert(\1" + \2 + "\3)/'
}

# Remove defaults
defaults() {
  sed 's/\(=.*\) \{1,\}!default/?\1/'
}

# Collapse multiline list expressions
multiline_lists() {
  sed -e '/^\$.* = .*"$/ {' -e ':loop' -e N -e 's/\n"/ "/' -e 't loop' -e '}'
}

# Replace nth() call
nth_calls() {
  sed 's/nth(\(.*\), \([0-9]*\))/\1[\2 - 1]/'
}

# Negation syntax
negations() {
  sed 's/-\$/- $/g'
}

# Division operator parentheses
divisions() {
  sed 's/: *\(.*\)\/\([^)]*\);$/: (\1\/\2);/'
}

# Replace interpolation
interpolations() {
  sed -e 's/: *\([^#]*\)#{\([^}]*\)}\([^;]*\)/: convert("\1" + \2 + "\3")/' \
    -e 's/\([^-]\)#{\([^}]*\)}/\1" + \2 + "/' -e 's/#{\([^}]*\)}/{\1}/g'
}

# For loops
loops() {
  sed 's/@for \(.*\) from \(.*\) through \(.*\) {$/for \1 in range(\2, \3) {/'
}

# Multiline animations
animations() {
  sed -e '/animation:[^;]*$/ {' -e ':loop' -e N -e 's/\([^;]\)\n/\1 /' \
    -e 't loop' -e '}'
}

conversions() {
  assignments | underscores | conditionals | trailing_ops | mixins | includes |
    unquotes | defaults | multiline_lists | nth_calls | negations | divisions |
    interpolations | loops | animations
}

convert_one() {
  echo "Converting file $1"
  local OUTFILE="$(dirname "$1")/$(basename "$1" .scss | sed 's/^_//').styl"
  cat "$1" | conversions > "$OUTFILE"
}

convert_all() {
  echo "Converting in directory $1"
  find "$1" -name '*.scss' -exec "$SASS2STYLUS" \{\} \;
}

[ -z "$1" ] || {
  [ -d "$1" ] || {
    convert_one "$1" && exit 0
  }
  convert_all "$1" && exit 0
}

convert_all "src"
