# __Занятие 1. Обновление ядра системы__

## Подготовка
установил ВМ Ubuntu 24-04 с Openssh server на virtualbox 
на хостовом ПК на безе windows 11 установил putty
## Выполнение задания
подключился к ubuntu server через ssh, проверил версию ядра

```bash
uname -r
6.8.0-107-generic
```

скачал kerneel версия 6.19.10 c: https://kernel.ubuntu.com/mainline/v6.13.2/ 
Устанавливил все пакеты сразу:
[db@server ~]$ sudo dpkg -i *.deb 
и проверил, что ядро появилось в /boot

```bash
ls -al /boot
total 204552
drwxr-xr-x  4 root root     4096 Apr  6 09:56 .
drwxr-xr-x 23 root root     4096 Apr  6 08:39 ..
-rw-r--r--  1 root root   306720 Mar 25 11:47 config-6.19.10-061910-generic
-rw-r--r--  1 root root   287601 Mar 13 13:27 config-6.8.0-107-generic
drwxr-xr-x  5 root root     4096 Apr  6 10:02 grub
lrwxrwxrwx  1 root root       33 Apr  6 09:55 initrd.img -> initrd.img-6.19.10-061910-generic
-rw-r--r--  1 root root 80527033 Apr  6 09:56 initrd.img-6.19.10-061910-generic
-rw-r--r--  1 root root 76332206 Apr  6 08:41 initrd.img-6.8.0-107-generic
lrwxrwxrwx  1 root root       28 Apr  6 08:39 initrd.img.old -> initrd.img-6.8.0-107-generic
drwx------  2 root root    16384 Apr  6 08:30 lost+found
-rw-------  1 root root 10815061 Mar 25 11:47 System.map-6.19.10-061910-generic
-rw-------  1 root root  9125925 Mar 13 13:27 System.map-6.8.0-107-generic
lrwxrwxrwx  1 root root       30 Apr  6 09:55 vmlinuz -> vmlinuz-6.19.10-061910-generic
-rw-------  1 root root 16978432 Mar 25 11:47 vmlinuz-6.19.10-061910-generic
-rw-------  1 root root 15042952 Mar 13 17:46 vmlinuz-6.8.0-107-generic
lrwxrwxrwx  1 root root       25 Apr  6 08:39 vmlinuz.old -> vmlinuz-6.8.0-107-generic
```

Обновил конфигурацию загрузчика и выбрал загрузку нового ядра
```bash
user@lessons01:~$ sudo update-grub
[sudo] password for user:
Sourcing file `/etc/default/grub'
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-6.19.10-061910-generic
Found initrd image: /boot/initrd.img-6.19.10-061910-generic
Found linux image: /boot/vmlinuz-6.8.0-107-generic
Found initrd image: /boot/initrd.img-6.8.0-107-generic
Warning: os-prober will not be executed to detect other bootable partitions.
Systems on them will not be added to the GRUB boot configuration.
Check GRUB_DISABLE_OS_PROBER documentation entry.
Adding boot menu entry for UEFI Firmware Settings ...
done

user@lessons01:~$ sudo grub-set-default 0

```
после перезагрузки проверил версию ядра
```bash
uname -r
6.19.10-061910-generic
```
