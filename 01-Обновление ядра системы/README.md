# __Занятие 1. Обновление ядра системы__

## Подготовка
установил ВМ Ubuntu 24-04 с Openssh server на virtualbox 
на хостовом ПК на безе windows 11 установил putty
## Выполнение задания
подключился к ubuntu server через ssh, проверил версию ядра
```` name -r
6.8.0-107-generic ```



Подключаемся по ssh к созданной виртуальной машины.
Перед работами проверим текущую версию ядра:
[db@server ~]$ uname -r
6.8.0-49-generic

Далее зайдём браузеров в репозиторий, где найдём свежую версию ядра для нашей архитектуры https://kernel.ubuntu.com/mainline .
На момент составления документа нам подходит версия 6.13.2: https://kernel.ubuntu.com/mainline/v6.13.2/ 
Архитектура системы для процессоров типа x86_64 (uname -p) требуется amd64.
Находим актуальную ссылку и качаем пакеты на виртуальную машину:
[db@server ~]$ mkdir kernel && cd kernel
[db@server ~]$ wget https://kernel.ubuntu.com/mainline/v6.13.2/amd64/linux-headers-6.13.2-061302-generic_6.13.2-061302.202502081010_amd64.deb
[db@server ~]$ wget https://kernel.ubuntu.com/mainline/v6.13.2/amd64/linux-headers-6.13.2-061302_6.13.2-061302.202502081010_all.deb
[db@server ~]$ wget https://kernel.ubuntu.com/mainline/v6.13.2/amd64/linux-image-unsigned-6.13.2-061302-generic_6.13.2-061302.202502081010_amd64.deb
[db@server ~]$ wget https://kernel.ubuntu.com/mainline/v6.13.2/amd64/linux-modules-6.13.2-061302-generic_6.13.2-061302.202502081010_amd64.deb

Устанавливаем все пакеты сразу:
[db@server ~]$ sudo dpkg -i *.deb 

Проверяем, что ядро появилось в /boot.
[db@server ~]$ ls -al /boot
…
lrwxrwxrwx  1 root root       29 Feb 20 09:54 vmlinuz -> vmlinuz-6.13.2-061302-generic
-rw-------  1 root root 15647232 Feb  8 10:10 vmlinuz-6.13.2-061302-generic
-rw-------  1 root root 14948744 Aug  2  2024 vmlinuz-6.8.0-41-generic
-rw-------  1 root root 14956936 Nov  1 11:41 vmlinuz-6.8.0-49-generic
lrwxrwxrwx  1 root root       24 Feb 20 09:54 vmlinuz.old -> vmlinuz-6.8.0-49-generic
… 

Уже на этом этапе можно перезагрузить нашу виртуальную машину и выбрать новое ядро при загрузке ОС. 
Если требуется, можно назначить новое ядро по умолчанию вручную:
1) Обновить конфигурацию загрузчика:
[db@server ~]$ sudo update-grub
2) Выбрать загрузку нового ядра по-умолчанию:
   	[db@server ~]$ sudo grub-set-default 0

Далее перезагружаем нашу виртуальную машину с помощью команды sudo reboot

После перезагрузки снова проверяем версию ядра (версия должна стать новее):
[db@server ~]$ uname -r 
6.13.2-061302-generic
На этом обновление ядра закончено.
