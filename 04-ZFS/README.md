# __Работа с ZVS__

## Определение алгоритма с наилучшим сжатием

Добавил в ВМ Ubuntu 24-04 8 дисков 512 МБ каждый и проверил что они появились в системе

``` bash
lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0   15G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0  1.8G  0 part
└─sda3                      8:3    0 13.2G  0 part
  └─ubuntu--vg-ubuntu--lv 252:0    0   10G  0 lvm  /
sdb                         8:16   0  512M  0 disk
sdc                         8:32   0  512M  0 disk
sdd                         8:48   0  512M  0 disk
sde                         8:64   0  512M  0 disk
sdf                         8:80   0  512M  0 disk
sdg                         8:96   0  512M  0 disk
sdh                         8:112  0  512M  0 disk
sdi                         8:128  0  512M  0 disk
sr0                        11:0    1 1024M  0 rom

```
Установим пакет утилит для ZFS:
``` bash
sudo apt install zfsutils-linux
```
Создаём пул из двух дисков в режиме RAID 1, а также 3 и посомтрим информацию о пулах сразу:
```bash
zpool create otus1 mirror /dev/sdb /dev/sdc
root@otus:/home/user# zpool create otus2 mirror /dev/sdd /dev/sde
root@otus:/home/user# zpool create otus3 mirror /dev/sdf /dev/sdg
root@otus:/home/user# zpool create otus4 mirror /dev/sdh /dev/sdi
root@otus:/home/user# zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   480M   111K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus2   480M   114K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus3   480M   134K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus4   480M   136K   480M        -         -     0%     0%  1.00x    ONLINE  -
```

Добавим разные алгоритмы сжатия в каждую файловую систему и проверим, что все файловые системы имеют разные методы сжати:
```bash
Алгоритм lzjb: zfs set compression=lzjb otus1
Алгоритм lz4:  zfs set compression=lz4 otus2
Алгоритм gzip: zfs set compression=gzip-9 otus3
Алгоритм zle:  zfs set compression=zle otus4

zfs get all | grep compression
otus1  compression           lzjb                   local
otus2  compression           lz4                    local
otus3  compression           gzip-9                 local
otus4  compression           zle                    local
```

Скачаем один и тот же текстовый файл во все пулы, проверим, что файл был скачан во все пулы: 
```bash
for i in {1..4}; do wget -P /otus$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done

ls -l /otus*
/otus1:
total 22124
-rw-r--r-- 1 root root 41227642 Apr  2 07:31 pg2600.converter.log

/otus2:
total 18020
-rw-r--r-- 1 root root 41227642 Apr  2 07:31 pg2600.converter.log

/otus3:
total 10972
-rw-r--r-- 1 root root 41227642 Apr  2 07:31 pg2600.converter.log

/otus4:
total 40291
-rw-r--r-- 1 root root 41227642 Apr  2 07:31 pg2600.converter.log

```
Уже сейчас видно, что самый оптимальный метод сжатия у нас используется в пуле otus3.
Проверим, сколько места занимает один и тот же файл в разных пулах и проверим степень сжатия файлов:

```bash
zfs list
NAME    USED  AVAIL  REFER  MOUNTPOINT
otus1  21.8M   330M  21.6M  /otus1
otus2  17.8M   334M  17.6M  /otus2
otus3  10.9M   341M  10.7M  /otus3
otus4  39.5M   312M  39.4M  /otus4

zfs get all | grep compressratio | grep -v ref
otus1  compressratio         1.82x                  -
otus2  compressratio         2.23x                  -
otus3  compressratio         3.66x                  -
otus4  compressratio         1.00x                  -

```
Таким образом, алгоритм gzip-9 самый эффективный по сжатию. 


## Определение настроек пула

Скачиваем архив в домашний каталог, разархивируем его и проверим, возможно ли импортировать данный каталог в пул:: 
```bash
wget -O archive.tar.gz --no-check-certificate 'https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download' 

tar -xzvf archive.tar.gz
zpoolexport/
zpoolexport/filea
zpoolexport/fileb

zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
status: Some supported features are not enabled on the pool.
        (Note that they may be intentionally disabled if the
        'compatibility' property is set.)
 action: The pool can be imported using its name or numeric identifier, though
        some features will not be available without an explicit 'zpool upgrade'.
 config:

        otus                              ONLINE
          mirror-0                        ONLINE
            /home/user/zpoolexport/filea  ONLINE
            /home/user/zpoolexport/fileb  ONLINE

```

Сделаем импорт данного пула к нам в ОС:
```bash
zpool import -d zpoolexport/ otus
root@otus:/home/user# zpool status
  pool: otus
 state: ONLINE
status: Some supported and requested features are not enabled on the pool.
        The pool can still be used, but some features are unavailable.
action: Enable all features using 'zpool upgrade'. Once this is done,
        the pool may no longer be accessible by software that does not support
        the features. See zpool-features(7) for details.
config:

        NAME                              STATE     READ WRITE CKSUM
        otus                              ONLINE       0     0     0
          mirror-0                        ONLINE       0     0     0
            /home/user/zpoolexport/filea  ONLINE       0     0     0
            /home/user/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors
```
Команда zpool status выдаст нам информацию о составе импортированного пула.
Если у Вас уже есть пул с именем otus, то можно поменять его имя во время импорта: 
zpool import -d zpoolexport/ otus newotus


Далее нам нужно определяем настройки:
Запрос сразу всех параметром файловой системы: zfs get all otus
```bash
zfs get all otus
NAME  PROPERTY              VALUE                  SOURCE
otus  type                  filesystem             -
otus  creation              Fri May 15  4:00 2020  -
otus  used                  2.04M                  -
otus  available             350M                   -
otus  referenced            24K                    -
otus  compressratio         1.00x                  -
otus  mounted               yes                    -
otus  quota                 none                   default
otus  reservation           none                   default
otus  recordsize            128K                   local
otus  mountpoint            /otus                  default
otus  sharenfs              off                    default
otus  checksum              sha256                 local
otus  compression           zle                    local
otus  atime                 on                     default
otus  devices               on                     default
otus  exec                  on                     default
otus  setuid                on                     default
otus  readonly              off                    default
otus  zoned                 off                    default
otus  snapdir               hidden                 default
otus  aclmode               discard                default
otus  aclinherit            restricted             default
otus  createtxg             1                      -
otus  canmount              on                     default
otus  xattr                 on                     default
otus  copies                1                      default
otus  version               5                      -
otus  utf8only              off                    -
otus  normalization         none                   -
otus  casesensitivity       sensitive              -
otus  vscan                 off                    default
otus  nbmand                off                    default
otus  sharesmb              off                    default
otus  refquota              none                   default
otus  refreservation        none                   default
otus  guid                  14592242904030363272   -
otus  primarycache          all                    default
otus  secondarycache        all                    default
otus  usedbysnapshots       0B                     -
otus  usedbydataset         24K                    -
otus  usedbychildren        2.01M                  -
otus  usedbyrefreservation  0B                     -
otus  logbias               latency                default
otus  objsetid              54                     -
otus  dedup                 off                    default
otus  mlslabel              none                   default
otus  sync                  standard               default
otus  dnodesize             legacy                 default
otus  refcompressratio      1.00x                  -
otus  written               24K                    -
otus  logicalused           1020K                  -
otus  logicalreferenced     12K                    -
otus  volmode               default                default
otus  filesystem_limit      none                   default
otus  snapshot_limit        none                   default
otus  filesystem_count      none                   default
otus  snapshot_count        none                   default
otus  snapdev               hidden                 default
otus  acltype               off                    default
otus  context               none                   default
otus  fscontext             none                   default
otus  defcontext            none                   default
otus  rootcontext           none                   default
otus  relatime              on                     default
otus  redundant_metadata    all                    default
otus  overlay               on                     default
otus  encryption            off                    default
otus  keylocation           none                   default
otus  keyformat             none                   default
otus  pbkdf2iters           0                      default
otus  special_small_blocks  0                      default
```

C помощью команды grep можно уточнить конкретный параметр, например:
Размер: zfs get available otus
```bash
zfs get available otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -

По типу FS мы можем понять, что позволяет выполнять чтение и запись
Значение recordsize: zfs get recordsize otus

zfs get readonly otus
NAME  PROPERTY  VALUE   SOURCE
otus  readonly  off     default

Тип сжатия (или параметр отключения): zfs get compression otus
zfs get compression otus
NAME  PROPERTY     VALUE           SOURCE
otus  compression  zle             local

Тип контрольной суммы: zfs get checksum otus
zfs get checksum otus
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local
```

## Работа со снапшотом, поиск сообщения от преподавателя

Скачаем файл, указанный в задании:
```bash
wget -O otus_task2.file --no-check-certificate https://drive.usercontent.google.com/download?id=1wgxjih8YZ-cqLqaZVa0lA3h3Y029c3oI&export=download
```
Восстановим файловую систему из снапшота:
zfs receive otus/test@today < otus_task2.file



Далее, ищем в каталоге /otus/test файл с именем “secret_message” и смотрим содержимое найденного файла:
```bash
root@otus:~# find /otus/test -name "secret_message"
/otus/test/task1/file_mess/secret_message


cat /otus/test/task1/file_mess/secret_message
https://otus.ru/lessons/linux-hl/
```
