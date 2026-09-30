# 12-управление процессами

## Задание

Реализация аналога ps ax
``` bash
Создайте скрипт, который получает информацию о процессах через файловую систему /proc.
Реализуйте вывод не менее следующих полей: PID, PPID, состояние процесса, имя или команда запуска.
Проверьте работу скрипта на запущенной системе.
Зафиксируйте пример результата работы.
```

пишем скрипт
``` bash
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

```


перекидываем на ВМ и делаем скрипт исполняемым

chmod +x proc_man.sh

запускаем скрипт 

``` bash
bash ./proc_man.sh

PID      PPID     STATE        NAME
------------------------------------------------------------
1        0        S            systemd
12       2        I            kworker/R-mm_pe
1210     1        S            systemd
1211     1210     S            (sd-pam)
1265     2        I            kworker/R-tls-s
1271     1        S            snapd
13       2        I            rcu_tasks_kthread
14       2        I            rcu_tasks_rude_kthread
146      2        S            scsi_eh_2
147      2        I            kworker/R-scsi_
15       2        I            rcu_tasks_trace_kthread
15931    1        S            fwupd
15938    1        S            upowerd
15955    2        I            kworker/0:2-events
15957    2        I            kworker/u2:1-events_unbound
15966    2        I            kworker/0:0-events
15978    2        I            kworker/0:2H
15986    2        I            kworker/0:1
15987    2        I            kworker/0:0H-kblockd
15989    2        I            kworker/u2:3-events_power_efficient
16       2        S            ksoftirqd/0
160      2        I            kworker/R-kdmfl
1607     2        S            psimon
1678     1        S            sshd
17       2        I            rcu_preempt
1737     1678     S            sshd
1738     1737     S            bash
18       2        S            migration/0
189      2        I            kworker/R-raid5
19       2        S            idle_inject/0
19255    2        I            kworker/0:1H-kblockd
2        0        S            kthreadd
20       2        S            cpuhp/0
20177    2634     S            bash
20209    20177    S            sleep
20210    3953     S            bash
21       2        S            kdevtmpfs
22       2        I            kworker/R-inet_
228      2        S            jbd2/dm-0-8
229      2        I            kworker/R-ext4-
23       2        S            kauditd
24       2        S            khungtaskd
2469     1        S            agetty
и далее список
```
