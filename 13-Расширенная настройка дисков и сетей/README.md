# 18-Vagrant

## Задание
``` bash
Расширенная настройка дисков и сетей
Создать базовую виртуальную машину:
Использовать можно любой образ.
Настроите память ВМ: 1024 МБ.
Добавление дисков:
Добавьте пару виртуальных диска размером 1 ГБ каждый.
Настройка сети:
Настройте проброс 80 порта с гостевой системы на порт 8080 хостовой системы.
Провижининг:
Напишите провижининг, который:
Форматирует добавленные диски в файловую систему ext4.
Создает точки монтирования /mnt/disk1 и /mnt/disk2.
Монтирует диски в указанные директории.
Добавляет записи в /etc/fstab для автоматического монтирования при загрузке.
```

# Готовим файл вагрант:

``` bash
Vagrant.configure("2") do |config|
  # Выбораем образа
  config.vm.box = "ubuntu/focal64"

  # устанавливаем объем памяти для ВМ
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
  end

  # Пробросываем порт: гостевой 80 -> хостовый 8080
  config.vm.network "forwarded_port", guest: 80, host: 8080

  # Добавляем виртуальные диски по 1 ГБ
  config.vm.disk :disk, size: "1GB", name: "disk1"
  config.vm.disk :disk, size: "1GB", name: "disk2"

  # 5. Провижининг (Shell)
  config.vm.provision "shell", inline: <<-SHELL
    # Определяем имена новых дисков (обычно это sdb и sdc, если sda — системный)
    # Используем lsblk для автоматического поиска дисков размером 1GB, которые не смонтированы
    DISK1=$(lsblk -dpno NAME,SIZE | grep '1G' | awk 'NR==1{print $1}')
    DISK2=$(lsblk -dpno NAME,SIZE | grep '1G' | awk 'NR==2{print $1}')

    echo "Найден диск 1: $DISK1"
    echo "Найден диск 2: $DISK2"

    # Создаем файловую систему ext4
    mkfs.ext4 -F $DISK1
    mkfs.ext4 -F $DISK2

    # Создаем точки монтирования
    mkdir -p /mnt/disk1
    mkdir -p /mnt/disk2

    # Монтируем диски
    mount $DISK1 /mnt/disk1
    mount $DISK2 /mnt/disk2

    # Добавляем записи в /etc/fstab для автоматического монтирования
    # Используем UUID для надежности
    UUID1=$(blkid -s UUID -o value $DISK1)
    UUID2=$(blkid -s UUID -o value $DISK2)

    echo "UUID=$UUID1 /mnt/disk1 ext4 defaults 0 2" >> /etc/fstab
    echo "UUID=$UUID2 /mnt/disk2 ext4 defaults 0 2" >> /etc/fstab

    # Проверяем fstab
    mount -a
  SHELL
end

```

Сохраняем файл и выполняем vagrant up

После поднятия ВМ логинимся и проверяем что нужные диски с нужной файловой системой установлены и примаплены
df -h -> см. screen_df-h.jpg
и проверяем с хостовой машины что порт 8080 слушается на интерфейсе, но так как хост у меня на OS Windows, я использую вместо команды 
netstat -tulpn | grep 808
команду 
>netstat -na | find "8080" -> см. screen_netstat.jpg
 TCP    0.0.0.0:8080           0.0.0.0:0              LISTENING