# Статья в блоге: https://blog.axisful.info/snippets/bash

#### [Процессы] ####
# Убить все процессы с заданным именем
for p in $(ps aux | grep -i httpd.worker | cut -d " " -f 4,5) ; do kill $p ;done

# Узнать родителей процесса
ps -ocommand= -p $p | awk -F/ '{print $NF}' | awk '{print $1}'

# Узнать родителей всех порождённых процессов
for p in $(ps aux | egrep oracle | cut -d ' ' -f 4); do ps -ocommand= -p $p | awk -F/ '{print $NF}' | awk '{print $1}'   ;done | uniq

# Вывести процессы, сортированные по потребляемой памяти
ps -eo pmem,pcpu,vsize,pid,cmd | sort -k 1 -nr | head -5; free -m


#### [Файлы] ####
# Заменить строку в файле
perl -pi -e 's/search/replace/g' file.txt

# Заменить строку в файлах
find . -type f -exec sed -i 's/search/replace/g' {} +

# Проверка существования файла в условии if
if ! [ -e $1 ] || [ -z $1 ] ; then
	echo File $1 doesnt exists
	exit 1
fi

# Проверить существование файлов по списку (вывести несуществующие)
for line in $(cat mylist.log); do if ! [ -e "$line" ]; then echo $line; fi ;done

# Размеры директорий на разделе, который смонтирован в указанный каталог. 
# То есть, для / в который смонтированы много поддиректорий на других разделах типа /usr /srv и прочее
# не будет выполнен расчёт места (который занимает ощутимое время)
du -hx --max-depth=1 /

# Архивировать файлы с паролем
7z a -p'paswword' -xr!"*.log" /tmp/${archive_name}.7z ${src_path} > /dev/null

# ZIP Архивировать файл с датой
zip -r ~/tmp/archive-$(date +%Y-%m-%d-%H-%M-%S).zip . -x '*node_modules*'

# TAR GZIP/BZIP Архивировать файл с датой
tar cfvz ~/tmp/archive-$(date +%Y-%m-%d-%H-%M-%S).tar.gz . --exclude "cache"
tar cfvj ~/tmp/archive-$(date +%Y-%m-%d-%H-%M-%S).tar.bz2 . --exclude "cache"

# Залить файл на гуглдиск
gdrive upload --parent 0B9ILkUWzQMQy3Q2hscGXaNX0zUXc ~/myfile.bz2


#### [Медиа] ####
# Конвертировать в MP3
lame -b 192 file.wav file.mp3

# Изменить битрейт MP3
lame --mp3input -b <bitrate> <file.mp3> <destination.mp3>

# Показать разрешение файлов, которые больше 900KB
identify -format "%Wx%H\n" $(find . -size +900k -type f)

# Изменить размер до 900 для изображений, у которых ширина больше 900
mogrify -resize '900x99999>' -quality 90  *.*


#### [Разное] ####
# Показать пакеты с архитектурой
rpm -qa --qf '%{NAME}.%{ARCH}\n'

# Формат даты
$(date +%Y-%m-%d-%H-%M)

# Установить системные дату и время ММДДЧЧммГГГГ.СС (МесяцДеньЧасМинутыГод.Секунды)
date 091412442012

# RDP соединение на PC с виндой
rdesktop -g 1366x718 -u User -pPASSWORD -r disk:share=/home/user/shared_dir/ -r sound:off -rclipboard:CLIPBOARD -T RemoteUserHost username

# Бэкап БД
mysqldump -u user -ppassword database table | gzip > backup-database.sql-$(date +%Y-%m-%d.%H%M%S).gz

# Сменить обои на XFCE
xfdesktop --reload

# Mount ntfs partitions
apt install ntfs-config

# Install LAMP stack
https://www.linode.com/docs/web-servers/lamp/install-lamp-stack-on-ubuntu-18-04/


