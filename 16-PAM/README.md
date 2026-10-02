# 24-Пользователи и группы. Авторизация и аутентификация 

## Задание
``` bash
Ограничить доступ к системе для всех пользователей, кроме группы администраторов, в выходные дни (суббота и воскресенье), за исключением праздничных дней.
```
## Создаем простой vagrantfile

``` bash
# Vagrantfile
Vagrant.configure("2") do |config|
  # Используем актуальную Ubuntu LTS (можно заменить на ubuntu/bionic64 или ubuntu/focal64)
  config.vm.box = "ubuntu/jammy64" # Ubuntu 22.04

  # Запуск нашего скрипта провижининга
  config.vm.provision "shell", path: "PAM.sh"
  # раскомментировать если нужно проверить по ssh извне 
  # config.vm.network "forwarded_port", guest: 22, host: 2222, id: "ssh"
end
```

так как не указано как нужно обеспечить выполнения задание, то буду делать через скрипт привязанный к vagrant файлу

``` bash
#!/bin/bash
set -e

echo "=== запрет логина через PAM по выходным ==="

# 1. Создаем тестового пользователя otus
if ! id "otus" &>/dev/null; then
    useradd -m -s /bin/bash otus
    echo "otus:otus" | chpasswd
fi
# 2. Создадим группу под нахванием admin и добавим в нее пользователей, кроме otus

sudo groupadd -f admin
usermod root -a -G admin && usermod vagrant -a -G admin

# 3. редактируем time.conf с описанием кто может и когда логиниться — явное разрешение для admin ПЕРВЫМ
cat > /etc/security/time.conf <<'EOF'
# Формат: services;ttys;users;times

# Явное разрешение для vagrant — всегда (Al = All days), для перестраховки добавил отдельно в конфиге разрешение для пользователя vagrant/группы sudo и сделал исключение для vagrant/sudo в запрещающем правиле
sshd;*;vagrant;Al0000-2400
login;*;vagrant;Al0000-2400

# Разрешение для группы sudo — всегда
sshd;*;@admin;Al0000-2400
login;*;@admin;Al0000-2400

# Запрет для всех (кроме vagrant и sudo) в выходные — только будни (wd)
sshd;*;!vagrant&!@sudo;Wd0000-2400
login;*;!vagrant&!@sudo;Wd0000-2400
EOF

# 3. Активация pam_time.so
for pamfile in /etc/pam.d/sshd /etc/pam.d/login /etc/pam.d/common-account; do
    if [ -f "$pamfile" ]; then
        if ! grep -qE '^\s*account\s+.*pam_time\.so' "$pamfile"; then
            # Вставляем в начало файла, для правильной обработки
            sed -i '0,/^account/s//account required pam_time.so\naccount/' "$pamfile" 2>/dev/null || \
            sed -i '1i account required pam_time.so' "$pamfile"
        fi
    fi
done
```