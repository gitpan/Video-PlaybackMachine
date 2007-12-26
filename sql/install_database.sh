#!/bin/bash

CREATEUSER_BIN=/usr/bin/createuser
CREATEDB_BIN=/usr/bin/createdb
CREATELANG_BIN=/usr/bin/createlang
PSQL_BIN=/usr/bin/psql

PM_DB_NAME=playback_machine
PM_DB_DESCRIPTION="Playback Machine"

# Create a database
$CREATEDB_BIN $PM_DB_NAME "$PM_DB_DESCRIPTION"
$CREATELANG_BIN -d $PM_DB_NAME plpgsql

# Load table structure into database
$PSQL_BIN -d $PM_DB_NAME < playback_machine_dd.sql

