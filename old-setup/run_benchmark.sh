#!/bin/bash
set -e

# Number of benchmark runs
NUM_RUNS=5

# CSV output file
CSV_FILE="results3.csv"

# Write CSV header
echo "Run,ddi_t,ss_t,dr_t,qe_t" > "$CSV_FILE"

for i in $(seq 1 $NUM_RUNS); do
    echo "========== Run $i =========="
    # Remove any previous log file
    rm -f startup.log

    # Run the container; --rm ensures it’s removed after exit
    docker run -it --rm --name mysql-startup \
      --memory="1g" \
      --cpus="0.1" \
      -e MYSQL_ROOT_PASSWORD=coderunnerhackerrank \
      mysql:v4 2>&1 | tee startup.log

    # Extract timing values from the log.
    # Assumes log lines like:
    # "Data directory initialization took: X seconds."
    # "MySQL server startup took: Y seconds."
    # "Dump restoration took: Z seconds."
    # "Query execution took: Q seconds."
    ddi=$(grep "Data directory initialization took:" startup.log | sed 's/.*took: //; s/ seconds.*//')
    ss=$(grep "MySQL server startup took:" startup.log | sed 's/.*took: //; s/ seconds.*//')
    dr=$(grep "Dump restoration took:" startup.log | sed 's/.*took: //; s/ seconds.*//')
    qe=$(grep "Query execution took:" startup.log | sed 's/.*took: //; s/ seconds.*//')

    echo "Run $i: ddi_t = $ddi, ss_t = $ss, dr_t = $dr, qe_t = $qe"

    # Append results as CSV row
    echo "$i,$ddi,$ss,$dr,$qe" >> "$CSV_FILE"
done

echo "Benchmarking complete. Results saved in $CSV_FILE"
