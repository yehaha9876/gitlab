#!/bin/sh

SCHEMA=${SCHEMA_FILE:-db/schema.rb}
RAKE_COMMAND=${RAKE_COMMAND:-db:migrate:reset}

schema_changed() {
  if [ ! -z "$(git diff --name-only -- $SCHEMA)" ]; then
    printf "$SCHEMA after rake $RAKE_COMMAND is different from one in the repository"
    printf "The diff is as follows:\n"
    diff=$(git diff -p --binary -- $SCHEMA)
    printf "%s" "$diff"
    exit 1
  else
    printf "$SCHEMA after rake $RAKE_COMMAND matches one in the repository\n"
  fi
}

schema_changed
