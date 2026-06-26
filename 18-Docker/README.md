# 18.Docker

## 1. Установил Docker на хост машину https://docs.docker.com/engine/install/ubuntu/
``` bash
sudo apt update
sudo apt install curl software-properties-common ca-certificates apt-transport-https -y
wget -O- https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor | sudo tee /etc/apt/keyrings/docker.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable"| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update

проверяем репозитарий
apt-cache policy docker-ce

устанавливаем dockerи проверяем его статус

sudo apt install docker-ce -y

sudo systemctl status docker
```

## 2. Установил Docker Compose

Docker Compose — это инструмент Докера, предназначенный для управления большим количеством контейнеров. Он используется в проектах, в которых используется много контейнеров, которые должны работать вместе как единое целое. Вручную управлять этим процессом затруднительно. Весь процесс управления описывается в рамках одного YAML-файла: он содержит настройки и конфигурацию всех контейнеров и приложений в них. 

``` bash
sudo apt-get install docker-compose
```

## 3. Создать свой кастомный образ nginx на базе alpine. После запуска nginx должен отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx)
создал docker-compose.yml
``` bash
version: '3'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - /var/apps/html:/usr/share/nginx/html/
    restart: always
```

и в паке с проектом добавил файл index.html 

``` bash
<!DOCTYPE html>
<html>
<head>
    <title>Hello, Otus!</title>
</head>
<body>
    <h1>Hello, Otus!</h1>
    <p>This is a test page served by Nginx in a Docker container OTUS.</p>
</body>
</html>
```
далее создал аккаунт на hub.docker.com и создал tag и запушил образ
``` bash
docker image push  nginx:alpine oruell19842026/otus:latest
```

https://hub.docker.com/repository/docker/oruell19842026/otus/tags


## 4. Определите разницу между контейнером и образом Вывод опишите в домашнем задании. Вывод опишите в домашнем задании.

``` bash
Контейнер Docker – это среда выполнения со всеми необходимыми компонентами, такими как код, зависимости и библиотеки, которые необходимы для запуска кода приложения без использования зависимостей хост-машины.
Запущенный образ с добавлением тонкого read-write слоя поверх всех слоев образа.
Stateless (Бессостоятельный): Данные внутри контейнера ephemeral (временны) и удаляются вместе с контейнером. Для данных используются тома (Volumes).


Образ Docker или образ контейнера – это отдельный исполняемый файл, используемый для создания контейнера. Этот образ контейнера содержит все библиотеки, зависимости и файлы, необходимые для запуска контейнера.
Слоистая (read-only) структура. Каждая инструкция в Dockerfile (кроме некоторых) создает новый слой.
Экономия места: общие слои между образами не дублируются на диске.

```

## 5. Ответьте на вопрос: Можно ли в контейнере собрать ядро?
Нет, цитата из урока:
``` bash
Контейнеризация:
Запускает изолированные процессы напрямую на ядре хостовой ОС (только Linux).
Контейнер содержит только приложение и его библиотеки, но не ядро.
Ключевой вывод: Контейнер — это обычный процесс в Linux, но с применением механизмов изоляции (namespaces, cgroups).
```
