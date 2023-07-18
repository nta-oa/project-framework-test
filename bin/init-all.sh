#!/bin/sh
pids=''
mkdir .logs;

echo "Starting all inits"
./bin/init.sh dv & pids="$pids $!"
./bin/init.sh qa & pids="$pids $!"
./bin/init.sh np & pids="$pids $!"
./bin/init.sh pd & pids="$pids $!"

echo "Waiting for inits to be done"

num_failures=0
for pid in $pids; do
  wait "$pid" || num_failures=$(( num_failures + 1 ))
done

echo "$num_failures background processes failed"

if [ "$num_failures" -gt 0 ]; then
  echo "Warning: $num_failures background processes failed" >&2
  exit 42;
fi

rmdir .logs
echo "All done"
