#!/bin/bash

set -e

# this script generates timestamp migrations given a migration name
# (writing to the db/migrations directory)

ARGC=$#
MINARGS=1
if [ $ARGC -lt $MINARGS ] ; then
	echo "USAGE:"
	echo "	./generate_migration.sh <migration_name>"
	echo "	./generate_migration.sh create_users_table"
	exit 1
fi

MIGRATIONS_DIR=../db/migrate
MIGRATION_NAME=$1
TIMESTAMP=`date +%Y%m%d%H%M%S`
US="_"
MIGRATION_FILE="$MIGRATIONS_DIR/$TIMESTAMP$US$MIGRATION_NAME.rb"

#MIGRATION_SHELL=sequel_migration_shell.rb
MIGRATION_SHELL=active_record_migration_shell.rb
cp $MIGRATION_SHELL $MIGRATION_FILE
echo "created migration in: $MIGRATION_FILE"
