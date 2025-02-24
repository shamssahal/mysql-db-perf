#!/bin/bash
set -e

# File to capture mysqld output (for debugging purposes)
LOGFILE="/tmp/mysqld.log"
: > "$LOGFILE"   # Clear previous log contents

# Function to convert nanoseconds to seconds.milliseconds format
ns_to_sec() {
    ns=$1
    sec=$(( ns / 1000000000 ))
    ms=$(( (ns % 1000000000) / 1000000 ))
    printf "%d.%03d" "$sec" "$ms"
}

echo "========== STEP 1: Data Directory Initialization =========="
# Step 1: Initialize the data directory if needed using insecure mode
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Data directory not found. Initializing data directory..."
    init_start=$(date +%s%N)
    mysqld --initialize-insecure 2>&1 | tee -a "$LOGFILE"
    init_end=$(date +%s%N)
    init_time=$(( init_end - init_start ))
    echo "Data directory initialization took: $(ns_to_sec $init_time) seconds."
else
    echo "Data directory already initialized."
fi

echo "========== STEP 2: MySQL Server Startup =========="
# Step 2: Start the MySQL server
start_server=$(date +%s%N)
echo "Starting MySQL server..."
# Start mysqld with error log redirected to LOGFILE
mysqld --log-error="$LOGFILE" 2>&1 &
MYSQLD_PID=$!

# Wait for the Unix socket to appear (server readiness)
while [ ! -S /var/lib/mysql/mysqld.sock ]; do
  sleep 0.1
done
end_server=$(date +%s%N)
server_time=$(( end_server - start_server ))
echo "MySQL server startup took: $(ns_to_sec $server_time) seconds."

echo "========== STEP 3: Dump Restoration =========="
# Step 3: Restore the dump file (assumed to be at /tmp/dump.sql)
if [ ! -f /tmp/dump.sql ]; then
  echo "Dump file /tmp/dump.sql not found! Exiting."
  kill $MYSQLD_PID
  exit 1
fi

restore_start=$(date +%s%N)
# Using the mysql client without a password since root is passwordless in insecure mode.
mysql -uroot < /tmp/dump.sql
restore_end=$(date +%s%N)
restore_time=$(( restore_end - restore_start ))
echo "Dump restoration took: $(ns_to_sec $restore_time) seconds."

echo "========== STEP 4: Query Execution =========="
query_start=$(date +%s%N)
mysql -uroot --database=coderunner -e "SELECT c.name FROM company c JOIN salary s ON c.id = s.company_id GROUP BY s.company_id HAVING AVG(s.salary) > 40000;" > /dev/null 2>&1
# mysql -uroot -e "SHOW DATABASES;"
query_end=$(date +%s%N)
query_time=$(( query_end - query_start ))
echo "Query execution took: $(ns_to_sec $query_time) seconds."

# Optionally, shutdown the server after benchmarking
echo "Shutting down MySQL server..."
kill $MYSQLD_PID

echo "========== Benchmarking Completed =========="
