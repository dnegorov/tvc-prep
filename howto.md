# vCore All-in-One host

Предполагается, что на хосте будет интернет или локальные репы.

Для работы скриптов нужны два пакета: curl и jq.
При наличии интерната на хосте они установется из скрипта.

Для офлайновой установки надо или организовать локальную репу, или выкачать и установить руками эти пакеты с зависимостями.
```
dnf -y install curl jq
```

Скрипты установят и настроят пакеты системы управления.

Для офлайновой установки надо или организовать локальную репу, или выкачать и установить руками эти пакеты с зависимостями.
```
dnf -y install vcore-broker vcore-control
```


----------------------------------------------------



## Порядок установки


1. Ставим с актуальной исошки.
2. Перезагрузка.
3. Задаем пароль root при первом входе в консоль.
4. Настраивать агента не нужно, жмем Esc Esc.
5. Настраиваем интерфейс управления (IP, GW, DNS), хостнейм приедет из скрипта.
6. Переходим в консоль (Здесь можно уже попасть на хост по SSH, в GUI ничего не настраиваем идем в консоль).
7. Скачиваем с гитхаба репу скриптов любым удобным способом или кладем на хост с флешки:

```
wget -O tvc-prep.zip https://codeload.github.com/dnegorov/tvc-prep/zip/refs/heads/master

unzip tvc-prep.zip
```

```
dnf -y install git

git clone https://github.com/dnegorov/tvc-prep.git
```

8. В итоге у нас есть где-то скрипты (/root/tvc-prep).

9. Правим файл params.conf

```
mcedit params.conf
```

**Обязательные параметры:**

```
# Диск (raid) на котором будет хранилище
HOST_DISK_FOR_STORAGE="/dev/sdb"

# hostname
HOST_NAME="vcore01"

# интерфейс сети управления (на нем сейчас сеть)
HOST_NET_MANAGMENT_IF_NAME="enp4s0"

# IP сети управления (также как сейчас настроена сеть)
HOST_IP="192.168.184.12"
HOST_IP_GW="192.168.184.1"
HOST_IP_MASK="24"
HOST_DNS="8.8.8.8"

# Пароль админа на систему управления
HOST_USER_PWD='P@$$w0rd'
```

> **ВНИМАНИЕ: Правка остальных параметров должна быть обоснована и опираться на понимание сути вещей!**

10. Если офлайновая установка: ставим пакеты вручную или готовим локальную репу до запуска скриптов.

11. Проверяем диск (/dev/sdb) на котором предполагается размещать хранилище, он должен быть не размечен:

```
[root@vcore01 ~]# lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda      8:0    0 446,6G  0 disk
├─sda1   8:1    0   488M  0 part /boot/efi
└─sda2   8:2    0 446,1G  0 part /
sdb      8:16   0   3,5T  0 disk
```

12. Если на диске есть разделы (/dev/sdb1)

```
[root@vcore01 ~]# lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda      8:0    0 446,6G  0 disk
├─sda1   8:1    0   488M  0 part /boot/efi
└─sda2   8:2    0 446,1G  0 part /
sdb      8:16   0   3,5T  0 disk
└─sdb1   8:17   0   3,5T  0 part
```

То все разделы удаляем (для каждого раздела):

```
parted -s /dev/sdb rm 1
parted -s /dev/sdb rm 2
...
```

13. Запускаем первый скрипт:

```
./deploy-1.sh
```

14. Проверяем наличие смонтированного хранилища (/storage на dev/sdb1):

```
[root@vcore01 ~]# lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda      8:0    0 446,6G  0 disk
├─sda1   8:1    0   488M  0 part /boot/efi
└─sda2   8:2    0 446,1G  0 part /
sdb      8:16   0   3,5T  0 disk
└─sdb1   8:17   0   3,5T  0 part /storage
```

15. Перезагружаем хост:

```
reboot
```

16. После загрузки на хост можно попасть по SSH (Здесь в SSH сессиях GUI перестает грузиться автоматом).

17. Запускаем второй скрипт:

```
./deploy-2.sh
```

18. Если все прошло штатно, то в браузере идем на адрес хоста в сети управления: HOST_IP:8082

19. На странице входа вводим:

```
Домен:            master
Имя пользователя: admin
Пароль:           P@$$w0rd
```

20. Идем в раздел **Инфраструктура\Сети**.

21. Если надо, то добавляем или меняем настройки.

22. Идем в раздел **Инфраструктура\Узлы\hostname** закладка **Сетевые интерфейсы**

23. Жмем кнопку **Настройка сетей**.

24. Собираем **bond** на интерфейсах интерконнекта: перетащить первый интерфейс на второй мышкой.

25. Жмем кнопку **Сохранить**.

26. Жмем кнопку **Настройка сетей**.

27. Изменяем настройки **bond0**, добавляем параметр **lacp_rate = 1**, сохраняем.

28. Жмем кнопку **Настройка сетей**.

29. На **bond0** перетаскиваем сеть **INTERCONNECT**

30. Сохраняем.

Система готова к использованию.


----------------------------------------------------


## Создание ВМ


При создании ВМ на этапе настройки сетевых интерфейсов добавилось поле **Номер слота**.

Для указания порядка интерфейсов, в поле проставляем значения в порядке следования интерфейсов.

Первое допустимое значение **3**, максимальное допустимое значение **31**.

Интерфейсы в ВМ будут располагаться в порядке возрастания номеров и, возможно, будут иметь этот номер в названии.

У ВМ два интерфейса:

1. В сети управление:    **Номер слота = 22**
2. В сети интерконнекта: **Номер слота = 26**

Интерфейсы получили имена и сохранили порядок следования:

1. ens22 altname enp0s22
2. ens26 altname enp0s26

```
[root@alt1 ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc 

....

2: ens22: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 56:6f:d8:a4:00:01 brd ff:ff:ff:ff:ff:ff
    altname enp0s22
    inet 192.168.184.201/24 brd 192.168.184.255 scope global ens22
       valid_lft forever preferred_lft forever
    inet6 fe80::546f:d8ff:fea4:1/64 scope link
       valid_lft forever preferred_lft forever

3: ens26: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9000 qdisc fq_codel state UP group default qlen 1000
    link/ether 56:6f:d8:a4:00:00 brd ff:ff:ff:ff:ff:ff
    altname enp0s26
    inet 192.168.100.101/24 brd 192.168.100.255 scope global ens26
       valid_lft forever preferred_lft forever
    inet6 fe80::546f:d8ff:fea4:0/64 scope link
       valid_lft forever preferred_lft forever
```

----------------------------------------------------


## Хранилище

Правильное хранилище выглядит так:

```
[root@vcore01 ~]# ls -lah /storage/hdd
total 20K
drwxr-xr-x. 5 vcore root  4,0K мар  2 17:25 .
drwxr-xr-x  6 vcore root  4,0K мар  2 18:03 ..
drwxr-xr-x  2 vcore vcore 4,0K мар  2 17:25 dom_md
drwxr-xr-x  4 vcore vcore 4,0K мар  2 20:30 images
drwxr-xr-x  2 vcore vcore 4,0K мар  2 17:25 master
```

Диски ВМ выглядят так (один диск - одна директория):

```
[root@vcore01 ~]#
[root@vcore01 ~]# ls -lah /storage/hdd/images/
total 16K
drwxr-xr-x  4 vcore vcore 4,0K мар  2 20:30 .
drwxr-xr-x. 5 vcore root  4,0K мар  2 17:25 ..
drwxr-xr-x  2 vcore vcore 4,0K мар  2 18:14 3c582b6a-98b4-4359-86d8-e6c528c4baa6
drwxr-xr-x  2 vcore vcore 4,0K мар  2 20:30 7de7e1da-4eb9-4830-8a0d-870da3a89b7c
```

Содержание директории с диском:

```
[root@vcore01 ~]# ls -lah /storage/hdd/images/3c582b6a-98b4-4359-86d8-e6c528c4baa6/
total 54G
drwxr-xr-x 2 vcore vcore 4,0K мар  2 18:14 .
drwxr-xr-x 4 vcore vcore 4,0K мар  2 20:30 ..
-rw-rw---- 1 vcore vcore  54G мар  2 18:23 1bc4bae9-0ace-4fed-b543-3215ea3eaa93_3c582b6a-98b4-4359-86d8-e6c528c4baa6.qcow2
-rw-r--r-- 1 vcore vcore  275 мар  2 18:14 1bc4bae9-0ace-4fed-b543-3215ea3eaa93_3c582b6a-98b4-4359-86d8-e6c528c4baa6.qcow2.meta
```

### Как найти где лежит диск?

* Идем в раздел **Данные\Диски\*** и находим наш диск **monitoring-hdd-0**

* Проваливаемся в его свойства и находим параметр **Путь**:

```
1bc4bae9-0ace-4fed-b543-3215ea3eaa93_3c582b6a-98b4-4359-86d8-e6c528c4baa6.qcow2
```

* Копируем или все имя или последнюю часть: **-e6c528c4baa6.qcow2**

* На хосте:

```
[root@vcore01 ~]# find /storage/hdd -name *-e6c528c4baa6.qcow2

/storage/hdd/images/3c582b6a-98b4-4359-86d8-e6c528c4baa6/1bc4bae9-0ace-4fed-b543-3215ea3eaa93_3c582b6a-98b4-4359-86d8-e6c528c4baa6.qcow2
```

Для подмены диска подкладываем образ, скачанный с Росплатформы, вместо файла ***.qcow2**:

```
1bc4bae9-0ace-4fed-b543-3215ea3eaa93_3c582b6a-98b4-4359-86d8-e6c528c4baa6.qcow2
```

ВАЖНО! При подкладывании проверить, что на файл выставлены правильные права и владелец:

```
-rw-rw---- 1 vcore vcore  54G мар  2 18:23 1bc4bae9-0ace-4fed-b543-3215ea3eaa93_3c582b6a-98b4-4359-86d8-e6c528c4baa6.qcow2
```


----------------------------------------------------
