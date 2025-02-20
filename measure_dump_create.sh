#!/bin/bash
set -e

# File to capture mysqld output
LOGFILE="/tmp/mysqld.log"
: > "$LOGFILE"   # Clear previous log contents

# Function: convert nanoseconds to seconds.milliseconds format
ns_to_sec() {
    ns=$1
    awk "BEGIN {printf \"%.6f\", $ns/1000000000}"
}

echo "========== STEP 1: Data Directory Initialization =========="
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Data directory not found. Initializing data directory..."
    init_start=$(date +%s%N)
    mysqld --initialize-insecure 2>&1 | tee -a "$LOGFILE"
    init_end=$(date +%s%N)
    ddi_t=$(( init_end - init_start ))
    echo "Data directory initialization took: $(ns_to_sec $ddi_t) seconds."
else
    echo "Data directory already initialized."
    ddi_t=0
fi

echo "========== STEP 2: MySQL Server Startup =========="
start_server=$(date +%s%N)
echo "Starting MySQL server..."
mysqld --log-error="$LOGFILE" 2>&1 &
MYSQLD_PID=$!
while [ ! -S /var/lib/mysql/mysqld.sock ]; do
  sleep 0.1
done
end_server=$(date +%s%N)
ss_t=$(( end_server - start_server ))
echo "MySQL server startup took: $(ns_to_sec $ss_t) seconds."

echo "========== STEP 3: Dump Creation =========="
# Create the target database if not exists
mysql -uroot -e "CREATE DATABASE IF NOT EXISTS coderunner;"
# Populate it using the plain SQL file (predump.sql) located at /tmp
mysql -uroot coderunner < /shared/predump.sql

# Now, generate a new dump.sql using mysqldump into the shared volume (/shared)
cd_start=$(date +%s%N)
mysqldump -uroot coderunner --result-file=/shared/dump.sql
cd_end=$(date +%s%N)
cd_t=$(( cd_end - cd_start ))
echo "Dump creation took: $(ns_to_sec $cd_t) seconds."

echo "========== STEP 4: Cleanup =========="
kill $MYSQLD_PID

echo "Benchmarking (Dump Creation) Completed."
echo "Results: ddi_t=$(ns_to_sec $ddi_t), ss_t=$(ns_to_sec $ss_t), cd_t=$(ns_to_sec $cd_t)"
