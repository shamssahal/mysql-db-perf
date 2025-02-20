#!/bin/bash
set -e

# File to capture mysqld output
LOGFILE="/tmp/mysqld.log"
: > "$LOGFILE"

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

echo "========== STEP 3: Dump Restoration =========="
# Restore the dump file generated earlier (located in /shared/dump.sql)
mysql -uroot -e "CREATE DATABASE IF NOT EXISTS coderunner;"
restore_start=$(date +%s%N)
mysql -uroot coderunner < /shared/dump.sql
restore_end=$(date +%s%N)
dr_t=$(( restore_end - restore_start ))
echo "Dump restoration took: $(ns_to_sec $dr_t) seconds."

echo "========== STEP 4: Query Execution =========="
query_start=$(date +%s%N)
mysql -uroot --database=coderunner -e "SELECT c.name FROM company c JOIN salary s ON c.id = s.company_id GROUP BY s.company_id HAVING AVG(s.salary) > 40000;"
query_end=$(date +%s%N)
qe_t=$(( query_end - query_start ))
echo "Query execution took: $(ns_to_sec $qe_t) seconds."

echo "========== STEP 5: Cleanup =========="
kill $MYSQLD_PID

echo "Benchmarking (DB Performance) Completed."
echo "Results: ddi_t=$(ns_to_sec $ddi_t), ss_t=$(ns_to_sec $ss_t), dr_t=$(ns_to_sec $dr_t), qe_t=$(ns_to_sec $qe_t)"
