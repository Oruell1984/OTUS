#!/bin/bash

printf "%-8s %-8s %-12s %-30s\n" "PID" "PPID" "STATE" "NAME"
printf '%.0s-' {1..60}; printf '\n'

for pid_dir in /proc/[0-9]*; do
    pid="${pid_dir##*/}"
    status_file="$pid_dir/status"
  [ -r "$status_file" ] || continue
    read -r name ppid state < <(
        awk '
            /^Name:/ { name = $2 }
            /^PPid:/ { ppid = $2 }
            /^State:/ { state = $2 }
            END {
                if (name  == "") name  = "N/A"
                if (ppid  == "") ppid  = "N/A"
                if (state == "") state = "N/A"
                print name, ppid, state
            }
        ' "$status_file"
    )

    printf "%-8s %-8s %-12s %-30s\n" "$pid" "$ppid" "$state" "$name"
done