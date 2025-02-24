#!/bin/bash
set -e

NUM_RUNS=100
DUMP_CSV="dump_create_results.csv"
DBPERF_CSV="db_perf_results.csv"

# Write CSV headers
echo "Run,ddi_t,ss_t,cd_t" > "$DUMP_CSV"
echo "Run,ddi_t,ss_t,dr_t,qe_t" > "$DBPERF_CSV"

# Function to extract timing value from log file lines
extract_time() {
    # $1: keyword, $2: log file
    grep "$1" "$2" | head -n1 | sed 's/.*took: \([0-9.]*\) seconds.*/\1/'
}

for run in $(seq 1 $NUM_RUNS); do
    echo "===== Run $run: Dump Creation Workflow ====="
    rm -f dump_create.log
    sudo docker run --rm -v "$(pwd)":/shared --name mysql-dump-create \
      -e MYSQL_ROOT_PASSWORD=coderunnerhackerrank \
      --memory="4g" --cpus="1" \
      mysql:v5 /usr/local/bin/measure_dump_create.sh 2>&1 | tee dump_create.log

    ddi=$(extract_time "Data directory initialization took:" dump_create.log)
    ss=$(extract_time "MySQL server startup took:" dump_create.log)
    cd_t=$(extract_time "Dump creation took:" dump_create.log)
    echo "Run $run (Dump Creation): ddi_t=$ddi, ss_t=$ss, cd_t=$cd_t"
    echo "$run,$ddi,$ss,$cd_t" >> "$DUMP_CSV"

    echo "===== Run $run: DB Performance Workflow ====="
    rm -f db_perf.log
    sudo docker run --rm -v "$(pwd)":/shared --name mysql-db-perf \
      -e MYSQL_ROOT_PASSWORD=coderunnerhackerrank \
      --memory="4g" --cpus="1" \
      mysql:v5 /usr/local/bin/measure_db_perf.sh 2>&1 | tee db_perf.log

    ddi=$(extract_time "Data directory initialization took:" db_perf.log)
    ss=$(extract_time "MySQL server startup took:" db_perf.log)
    dr=$(extract_time "Dump restoration took:" db_perf.log)
    qe=$(extract_time "Query execution took:" db_perf.log)
    echo "Run $run (DB Performance): ddi_t=$ddi, ss_t=$ss, dr_t=$dr, qe_t=$qe"
    echo "$run,$ddi,$ss,$dr,$qe" >> "$DBPERF_CSV"

    rm -f dump.sql
done

echo "Benchmarking complete."
echo "Dump Creation results saved in $DUMP_CSV."
echo "DB Performance results saved in $DBPERF_CSV."
