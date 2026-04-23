# __Работа с NFS, FUSE__

## Подготовка
создал 2 VM: nfss (IP 192.168.89.105) и nfsc(IP 192.168.89.102)

Установим сервер NFS на nfss и проверим что порты 2049/udp, 2049/tcp, 111/udp слушаются нашим сервером:

``` bash
apt install nfs-kernel-server

после установки
ss -tnplu
udp           UNCONN         0              0                                    0.0.0.0:111                        0.0.0.0:*            users:(("rpcbind",
udp           UNCONN         0              0                                       [::]:111                           [::]:*            users:(("rpcbind",
tcp           LISTEN         0              4096                                    [::]:111                           [::]:*            users:(("rpcbind",tcp           LISTEN         0              64                                      [::]:2049                          [::]:*
```

Создаим и настроим директорию, которая будет экспортирована в будущем

``` bash
mkdir -p /srv/share/upload 
chown -R nobody:nogroup /srv/share 
chmod 0777 /srv/share/upload 
```

Cоздим в файле /etc/exports структуру, которая позволит экспортировать ранее созданную директорию:
``` bash
cat << EOF > /etc/exports
/srv/share 192.168.89.102/32(rw,sync,root_squash)
EOF
```
Экспортируем ранее созданную директорию и проверяем:
``` bash
exportfs -r
exportfs: /etc/exports [1]: Neither 'subtree_check' or 'no_subtree_check' specified for export "192.168.89.102/32:/srv/share".
  Assuming default behaviour ('no_subtree_check').

exportfs -s
/srv/share  192.168.89.102/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
```

Далее заходим на VM клиента (nfsc 192.168.89.102) и настраиваем клиент NFS

``` bash
sudo apt install nfs-common
```

Добавляем в /etc/fstab строку 
``` bash
echo "192.168.89.105:/srv/share/ /mnt nfs vers=3,noauto,x-systemd.automount 0 0" >> /etc/fstab
```
и выполняем команды:
``` bash
systemctl daemon-reload 
systemctl restart remote-fs.target 
```
проверяем успешность монтирования:
``` bash
mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=72,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=5419)
192.168.89.105:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=262144,wsize=262144,namlen=255,hard,fatal_neterrors=none,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=192.168.89.105,mountvers=3,mountport=56388,mountproto=udp,local_lock=none,addr=192.168.89.105)
```

## Проверка работоспособности 

Зашел на сервер. 
В каталоге /srv/share/upload создал тестовый файл 
touch check_srv.

Зашел на клиенте в каталог /mnt/upload и проверил наличие ранее созданного файла.
Создаём тестовый файл touch client_file_client. 
Проверяем, что файл успешно создан.
``` bash
/mnt/upload# ls
check_file_client  check_srv
```

Перегазружаем сервер и клиент и проверям наличе экспорта/шар/файлов

 ``` bash
 exportfs -s
/srv/share  192.168.89.102/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
 
 ls /srv/share/upload/
check_file_client  check_srv
```
на клиенте также проверяем работу RPC\наличие файлов и создадим тестовый:
 ``` bash
showmount -a 192.168.89.105
All mount points on 192.168.89.105:
192.168.89.102:/srv/share

mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=72,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=5419)
192.168.89.105:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=262144,wsize=262144,namlen=255,hard,fatal_neterrors=none,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=192.168.89.105,mountvers=3,mountport=56388,mountproto=udp,local_lock=none,addr=192.168.89.105)

touch final_check
/home/user# ls /mnt/upload/
check_file_client  check_srv  final_check
```