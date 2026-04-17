# __Работа с LVM__

## Подготовка
Добавил в ВМ Ubuntu 24-04 4 диска размеров 1/1/2/10 Gb 

## Уменьшить том под / до 8G.
Подготовим временный том для / раздела:

```bash
pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
vgcreate vg_root /dev/sdb
  Volume group "vg_root" successfully created
lvcreate -n lv_root -l +100%FREE /dev/vg_root
  Logical volume "lv_root" created.

```
Создадим на нем файловую систему и смонтируем его, чтобы перенести туда данные:

```bash
mkfs.ext4 /dev/vg_root/lv_root
mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 2620416 4k blocks and 655360 inodes
Filesystem UUID: b4da0ed5-37f3-49bf-9259-f8fde668c55d
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done
Writing inode tables: done
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done

mount /dev/vg_root/lv_root /mnt

```

копируем все данные с / раздела в /mnt:

rsync -avxHAX --progress / /mnt/
и проверяем данные к-е скопировали

```bash
ls /mnt
bin  bin.usr-is-merged  boot  cdrom  dev  etc  home  lib  lib64  lib.usr-is-merged  lost+found  media  mnt  opt  proc  raid  root  run  sbin  sbin.usr-is-merged  snap  srv  swap.img  sys  tmp  usr  var
```

сконфигурируем grub для того, чтобы при старте перейти в новый /.
Сымитируем текущий root, сделаем в него chroot и обновим grub:

```bash
for i in /proc/ /sys/ /dev/ /run/ /boot/; \
 do mount --bind $i /mnt/$i; done

chroot /mnt/
root@lessons01:/# grub-mkconfig -o /boot/grub/grub.cfg
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

```
Обновим образ initrd и перезагружаемся

```bash
update-initramfs -u

update-initramfs: Generating /boot/initrd.img-6.19.10-061910-generic

```

после перезагрузки проверяем диски

```bash
lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop0                       7:0    0   74M  1 loop /snap/core22/2411
loop1                       7:1    0 78.7M  1 loop /snap/powershell/341
loop2                       7:2    0 78.7M  1 loop /snap/powershell/346
loop3                       7:3    0 48.4M  1 loop /snap/snapd/26382
sda                         8:0    0   15G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0 13.2G  0 part
  └─ubuntu--vg-ubuntu--lv 252:1    0   10G  0 lvm
sdb                         8:16   0   10G  0 disk
└─vg_root-lv_root         252:0    0   10G  0 lvm  /
sdc                         8:32   0    2G  0 disk
sdd                         8:48   0    1G  0 disk
sde                         8:64   0    1G  0 disk
sr0                        11:0    1 1024M  0 rom
sr1                        11:1    1  3.2G  0 rom
```

Теперь нам нужно изменить размер старой VG и вернуть на него рут. Для этого удаляем старый LV размером в 13,2 G и создаём новый на 8G:

```bash
 lvremove /dev/ubuntu-vg/ubuntu-lv
Do you really want to remove and DISCARD active logical volume ubuntu-vg/ubuntu-lv? [y/n]: y
  Logical volume "ubuntu-lv" successfully removed.

  lvcreate -n ubuntu-vg/ubuntu-lv -L 8G /dev/ubuntu-vg
WARNING: ext4 signature detected on /dev/ubuntu-vg/ubuntu-lv at offset 1080. Wipe it? [y/n]: y
  Wiping ext4 signature on /dev/ubuntu-vg/ubuntu-lv.
  Logical volume "ubuntu-lv" created.
```
Проделываем на нем те же операции, что и в первый раз:

```bash

mkfs.ext4 /dev/ubuntu-vg/ubuntu-lv
mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 2097152 4k blocks and 524288 inodes
Filesystem UUID: 689edddc-ffa7-4115-a702-9917f39934b8
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912, 819200, 884736, 1605632

Allocating group tables: done
Writing inode tables: done
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done

mount /dev/ubuntu-vg/ubuntu-lv /mnt
rsync -avxHAX --progress / /mnt/
sending incremental file list
```

cконфигурируем grub.
```bash
for i in /proc/ /sys/ /dev/ /run/ /boot/; \
 do mount --bind $i /mnt/$i; done
chroot /mnt/
grub-mkconfig -o /boot/grub/grub.cfg
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

update-initramfs -u
update-initramfs: Generating /boot/initrd.img-6.19.10-061910-generic
W: Couldn't identify type of root file system for fsck hook

```

## Выделяем том под /var в зеркало

```bash
pvcreate /dev/sdc /dev/sdd
  Physical volume "/dev/sdc" successfully created.
  Physical volume "/dev/sdd" successfully created.
vgcreate vg_var /dev/sdc /dev/sdd
  Volume group "vg_var" successfully created
lvcreate -L 950M -m1 -n lv_var vg_var
  Rounding up size to full physical extent 952.00 MiB
  Logical volume "lv_var" created.
mkfs.ext4 /dev/vg_var/lv_var
mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 243712 4k blocks and 60928 inodes
Filesystem UUID: ffc53440-a742-4dcf-8f91-03d92e878eaa
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376

Allocating group tables: done
Writing inode tables: done
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done

mount /dev/vg_var/lv_var /mnt
cp -aR /var/* /mnt/
```

сохраняем содержимое старого var и монтируем новый var в каталог /var::

```bash
mkdir /tmp/oldvar && mv /var/* /tmp/oldvar
umount /mnt
mount /dev/vg_var/lv_var /var
```

Правим fstab для автоматического монтирования /var:

```bash
echo "`blkid | grep var: | awk '{print $2}'` \
 /var ext4 defaults 0 0" >> /etc/fstab
```

После чего можно успешно перезагружаться в новый (уменьшенный root) и удалять
временную Volume Group:
```bash
lvremove /dev/vg_root/lv_root
Do you really want to remove and DISCARD active logical volume vg_root/lv_root? [y/n]: y
  Logical volume "lv_root" successfully removed.

vgremove /dev/vg_root
  Volume group "vg_root" successfully removed

pvremove /dev/sdb
  Labels on physical volume "/dev/sdb" successfully wiped.
```

Выделить том под /home
Выделяем том под /home по тому же принципу что делали для /var:
```bash
lvremove /
lvcreate -n LogVol_Home -L 2G /dev/ubuntu-vg
  Logical volume "LogVol_Home" created.

mkfs.ext4 /dev/ubuntu-vg/LogVol_Home
mount /dev/ubuntu-vg/LogVol_Home /mnt/
cp -aR /home/* /mnt/
rm -rf /home/*
umount /mnt
mount /dev/ubuntu-vg/LogVol_Home /home/
```
Правим fstab для автоматического монтирования /home:
```bash
echo "`blkid | grep Home | awk '{print $2}'` \
 /home xfs defaults 0 0" >> /etc/fstab
```

## Выделить том под /home
Выделяем том под /home по тому же принципу что делали для /var:

```bash
lvcreate -n LogVol_Home -L 2G /dev/ubuntu-vg
  Logical volume "LogVol_Home" created.

mkfs.ext4 /dev/ubuntu-vg/LogVol_Home
mke2fs 1.47.0 (5-Feb-2023)
Creating filesystem with 524288 4k blocks and 131072 inodes
Filesystem UUID: 3c9bbb5d-f0fb-4c54-b2be-020d906043ca
Superblock backups stored on blocks:
        32768, 98304, 163840, 229376, 294912

Allocating group tables: done
Writing inode tables: done
Creating journal (16384 blocks): done
Writing superblocks and filesystem accounting information: done

mount /dev/ubuntu-vg/LogVol_Home /mnt/
cp -aR /home/* /mnt/
rm -rf /home/*
umount /mnt
mount /dev/ubuntu-vg/LogVol_Home /home/
```

Правим fstab для автоматического монтирования /home:

```bash
 echo "`blkid | grep Home | awk '{print $2}'` \
 /home xfs defaults 0 0" >> /etc/fstab
```


## Работа со снапшотами

Генерируем файлы в /home/:

touch /home/file{1..20}

Снять снапшот:
```bash
lvcreate -L 100MB -s -n home_snap \
 /dev/ubuntu-vg/LogVol_Home
  Logical volume "home_snap" created.
```

Удалить часть файлов:
```bash
rm -f /home/file{11..20}
```
Процесс восстановления из снапшота:
```bash
umount /home
lvconvert --merge /dev/ubuntu-vg/home_snap
  Merging of volume ubuntu-vg/home_snap started.
  ubuntu-vg/LogVol_Home: Merged: 100.00%


mount /dev/mapper/ubuntu--vg-LogVol_Home /home
ls -al /home
total 28
drwxr-xr-x  4 root    root     4096 Dec 23 11:50 .
drwxr-xr-x 24 root    root     4096 Dec 23 09:49 ..
-rw-r--r--  1 root    root        0 Dec 23 11:50 file1
-rw-r--r--  1 root    root        0 Dec 23 11:50 file10
-rw-r--r--  1 root    root        0 Dec 23 11:50 file11
-rw-r--r--  1 root    root        0 Dec 23 11:50 file12
-rw-r--r--  1 root    root        0 Dec 23 11:50 file13
-rw-r--r--  1 root    root        0 Dec 23 11:50 file14
-rw-r--r--  1 root    root        0 Dec 23 11:50 file15
```