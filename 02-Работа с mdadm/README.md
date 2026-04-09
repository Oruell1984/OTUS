# __Занятие 2. Работа с mdadm__

## Подготовка
Добавил в ВМ Ubuntu 24-04 2 диска размеров 1 Gb 

## Выполнение задания

### Создаем RAID массив
проверил что в системе появились мои диски

```bash
fdisk -l

Disk /dev/sdb: 1 GiB, 1073741824 bytes, 2097152 sectors
Disk model: VBOX HARDDISK
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/sdc: 1 GiB, 1073741824 bytes, 2097152 sectors
Disk model: VBOX HARDDISK
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes

```
или 
``` bash
lsblk

NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop0                       7:0    0   74M  1 loop /snap/core22/2411
loop1                       7:1    0 78.7M  1 loop /snap/powershell/341
loop2                       7:2    0 48.4M  1 loop /snap/snapd/26382
sda                         8:0    0   15G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0 13.2G  0 part
  └─ubuntu--vg-ubuntu--lv 252:0    0   10G  0 lvm  /
sdb                         8:16   0    1G  0 disk
sdc                         8:32   0    1G  0 disk
sr0                        11:0    1 1024M  0 rom
sr1                        11:1    1  3.2G  0 rom
```

попробовал занулить суперблоки, но как так диски ранее не использовались в массиве, получил вывод ниже
 
``` bash
mdadm --zero-superblock --force /dev/sd{b,c}

mdadm: Unrecognised md component device - /dev/sdb
mdadm: Unrecognised md component device - /dev/sdc

```

Создал RAID-1 коммандой и проверил что все нормально прошло

``` bash
mdadm --create --verbose /dev/md0 --level=1 --raid-devices=2 /dev/sdb /dev/sdc

cat /proc/mdstat
Personalities : [raid0] [raid1] [raid4] [raid5] [raid6] [raid10] [linear]
md0 : active raid1 sdc[1] sdb[0]
      1046528 blocks super 1.2 [2/2] [UU]

unused devices: <none>


mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Thu Apr  9 12:33:23 2026
        Raid Level : raid1
        Array Size : 1046528 (1022.00 MiB 1071.64 MB)
     Used Dev Size : 1046528 (1022.00 MiB 1071.64 MB)
      Raid Devices : 2
     Total Devices : 2
       Persistence : Superblock is persistent

       Update Time : Thu Apr  9 12:33:29 2026
             State : clean
    Active Devices : 2
   Working Devices : 2
    Failed Devices : 0
     Spare Devices : 0

Consistency Policy : resync

              Name : lessons01:0  (local to host lessons01)
              UUID : 2ff64e6f:dabddfee:9e53396f:62801327
            Events : 17

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc


```


### Ломаем и чиним RAID массив
переводим диск dev/sdb в fail 

```bash
mdadm /dev/md0 --fail /dev/sdb
mdadm: set /dev/sdb faulty in /dev/md0
```
проверяем что у нас получилось

```bash
cat /proc/mdstat
Personalities : [raid0] [raid1] [raid4] [raid5] [raid6] [raid10] [linear]
md0 : active raid1 sdc[1] sdb[0](F)
      1046528 blocks super 1.2 [2/1] [_U]


      mdadm -D /dev/md0
/dev/md0:
    State : clean, degraded
    Active Devices : 1
   Working Devices : 1
    Failed Devices : 1
     Spare Devices : 0

Consistency Policy : resync

              Name : lessons01:0  (local to host lessons01)
              UUID : 2ff64e6f:dabddfee:9e53396f:62801327
            Events : 19

    Number   Major   Minor   RaidDevice State
       -       0        0        0      removed
       1       8       32        1      active sync   /dev/sdc

       0       8       16        -      faulty   /dev/sdb

```

Удаляем "сбойный" диск из массива

```bash
mdadm /dev/md0 --remove /dev/sdb
mdadm: hot removed /dev/sdb from /dev/md0
```

Добавим диск в массив и проверим 

```bash
mdadm /dev/md0 --add /dev/sdb
mdadm: added /dev/sdb

cat /proc/mdstat
Personalities : [raid0] [raid1] [raid4] [raid5] [raid6] [raid10] [linear]
md0 : active raid1 sdb[2] sdc[1]
      1046528 blocks super 1.2 [2/2] [UU]

unused devices: <none>

 mdadm -D /dev/md0

    Number   Major   Minor   RaidDevice State
       2       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc

```

Создаем раздел GPT на RAID
```bash
parted -s /dev/md0 mklabel gpt
```
и  партиции

```bash
[root@mdadm ~]$ parted /dev/md0 mkpart primary ext4 0% 20%
[root@mdadm ~]$ parted /dev/md0 mkpart primary ext4 20% 40%
[root@mdadm ~]$ parted /dev/md0 mkpart primary ext4 40% 60%
[root@mdadm ~]$ parted /dev/md0 mkpart primary ext4 60% 80%
[root@mdadm ~]$ parted /dev/md0 mkpart primary ext4 80% 100%
```

Созданим файловую систему на всех партициях и смонтируем

```bash
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 51968 4k blocks and 51968 inodes
Filesystem UUID: 2ab56049-cef1-45b3-8d8f-998ab7e580b9
Superblock backups stored on blocks:
        32768

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 52480 4k blocks and 52480 inodes
Filesystem UUID: 0d97ea28-e5df-4ef1-ad45-e6817dbd0bcc
Superblock backups stored on blocks:
        32768

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 52224 4k blocks and 52224 inodes
Filesystem UUID: 49144c8d-8669-403e-b866-d2559b168cef
Superblock backups stored on blocks:
        32768

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 52480 4k blocks and 52480 inodes
Filesystem UUID: cbe0ca42-e020-48bb-b174-ffff2f22eb74
Superblock backups stored on blocks:
        32768

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 51968 4k blocks and 51968 inodes
Filesystem UUID: a45a30ca-7156-4023-8706-0d00a45c6702
Superblock backups stored on blocks:
        32768

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done


mkdir -p /raid/part{1,2,3,4,5}

for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done
```
