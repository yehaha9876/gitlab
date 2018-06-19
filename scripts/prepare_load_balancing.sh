#!/bin/bash
# Note that this just points the same database to emulate a secondary.
# It's primarily used to ensure that the load balancing code works with
# multiple databases.
if [ "$GITLAB_DATABASE" = 'postgresql' ]; then
    sed -e '/host:/a \ \ load_balancing: \n    - postgres' -i config/database.yml
fi
