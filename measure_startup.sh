#!/bin/bash
set -e

# Initialize the data directory if needed
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing data directory..."
    mysqld --initialize-insecure
fi

# Capture the start time in nanoseconds
start_time=$(date +%s%N)

echo "Starting MySQL server..."
mysqld &
MYSQLD_PID=$!

# Wait until the MySQL socket is available (indicates readiness)
while [ ! -S /var/lib/mysql/mysqld.sock ]; do
  sleep 0.1
done

# Capture the end time in nanoseconds
end_time=$(date +%s%N)

# Calculate the elapsed time in nanoseconds
elapsed_ns=$(( end_time - start_time ))

# Convert elapsed nanoseconds to seconds and milliseconds:
# Integer seconds
sec=$(( elapsed_ns / 1000000000 ))
# Remaining nanoseconds converted to milliseconds (three decimal places)
ms=$(( (elapsed_ns % 1000000000) / 1000000 ))

printf "MySQL server started in %d.%03d seconds.\n" "$sec" "$ms"

# Optionally stop the MySQL server if you just need to measure startup time
kill $MYSQLD_PID

exit 0
