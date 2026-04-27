# __Управление пакетами. Дистрибьюция софта __

## Создать свой RPM пакет

Установим следующие пакеты:
``` bash
yum install -y wget rpmdevtools rpm-build createrepo yum-utils cmake gcc git nano
```

возьмем пакет Nginx и соберем его с дополнительным модулем ngx_broli
Загрузим SRPM пакет Nginx для дальнейшей работы над ним и создадим дерево каталогов для сборки, поставим все зависимости для сборки пакета Nginx:
``` bash
mkdir rpm && cd rpm
yumdownloader --source nginx

rpm -Uvh nginx*.src.rpm
error: File not found by glob: nginx*.src.rpm

yum-builddep nginx
```

скачаем исходный код модуля ngx_brotli — он потребуется при сборке:
``` bash
cd /root
git clone --recurse-submodules -j8 https://github.com/google/ngx_brotli
cd ngx_brotli/deps/brotli
mkdir out && cd out
```
Собираем модуль ngx_brotli:
``` bash
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_CXX_FLAGS="-Ofast -m64 -march=native -mtune=native -flto -funroll-loops -ffunction-sections -fdata-sections -Wl,--gc-sections" -DCMAKE_INSTALL_PREFIX=./installed ..
cmake --build . --config Release -j 2 --target brotlienc
cd ../../../..
```

Поправим сам nginx.spec файл, чтобы Nginx собирался с необходимыми нам опциями: находим секцию с параметрами configure (до условий if) и добавляем указание на модуль (не забудьте указать завершающий обратный слэш) и начинаем сборку:
--add-module=/root/ngx_brotli \
``` bash
cd ~/rpmbuild/SPECS/
rpmbuild -ba nginx.spec -D 'debug_package %{nil}'

Executing(%clean): /bin/sh -e /var/tmp/rpm-tmp.GjhE3u
+ umask 022
+ cd /root/rpmbuild/BUILD
+ cd nginx-1.20.1
+ /usr/bin/rm -rf /root/rpmbuild/BUILDROOT/nginx-1.20.1-24.el9.2.alma.1.x86_64
+ RPM_EC=0
++ jobs -p
+ exit 0

```

Убедимся, что пакеты создались:
``` bash
ll /root/rpmbuild/RPMS/x86_64/
total 2008
-rw-r--r--. 1 root root   37462 Apr 27 06:51 nginx-1.20.1-24.el9.2.alma.1.x86_64.rpm
```

Копируем пакеты в общий каталог, установим наш пакет и убедимся, что nginx работает:
``` bash
cp ~/rpmbuild/RPMS/noarch/* ~/rpmbuild/RPMS/x86_64/
cd ~/rpmbuild/RPMS/x86_64

yum localinstall *.rpm

systemctl start nginx

systemctl status nginx
```


## Создадим свой репозиторий и разместим там ранее собранный RPM

Приступим к созданию своего репозитория. Директория для статики у Nginx по умолчанию /usr/share/nginx/html. Создадим там каталог repo и скопируем туда наши собранные RPM-пакеты:
``` bash
mkdir /usr/share/nginx/html/repo

cp ~/rpmbuild/RPMS/x86_64/*.rpm /usr/share/nginx/html/repo/
```

Инициализируем репозиторий:
``` bash
createrepo /usr/share/nginx/html/repo/
Directory walk started
Directory walk done - 10 packages
Temporary output repo path: /usr/share/nginx/html/repo/.repodata/
Preparing sqlite DBs
Pool started (with 5 workers)
Pool finished
```

Для прозрачности настроим в NGINX доступ к листингу каталога. В файле /etc/nginx/nginx.conf в блоке server добавим следующие директивы:
``` bash
	index index.html index.htm;
	autoindex on;
```

Проверяем синтаксис и перезапускаем NGINX:
``` bash
nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

nginx -s reload
```

Можно посмотреть в браузере или с помощью curl:
lynx http://localhost/repo/
curl -a http://localhost/repo/

Все готово для того, чтобы протестировать репозиторий.
Добавим его в /etc/yum.repos.d и убедимся, что репозиторий подключился:
``` bash
cat >> /etc/yum.repos.d/otus.repo << EOF
[otus]
name=otus-linux
baseurl=http://localhost/repo
gpgcheck=0
enabled=1
EOF


yum repolist enabled | grep otus
otus                             otus-linux
```

Добавим пакет в наш репозиторий и обновим список пакетов в репозитории:
``` bash
cd /usr/share/nginx/html/repo/
wget https://repo.percona.com/yum/percona-release-latest.noarch.rpm

createrepo /usr/share/nginx/html/repo/
yum makecache
yum list | grep otus
percona-release.noarch                               1.0-32                             otus
```

Так как Nginx у нас уже стоит, установим репозиторий percona-release:
``` bash
yum install -y percona-release.noarch

  Verifying        : percona-release-1.0-32.noarch                                                                                                                                                        1/1

Installed:
  percona-release-1.0-32.noarch

Complete!
```

В случае, если вам потребуется обновить репозиторий (а этоделается при каждом добавлении файлов) снова, то выполните команду
``` bash
createrepo /usr/share/nginx/html/repo/.
```