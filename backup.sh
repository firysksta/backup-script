#!/bin/bash
exec 6<&2
arrayback=()
while [ -n "$1" ]
do
case $1 in
 -s) server="$2"
        shift;;
 -l) local="$2"
        shift;;
 -d) while [ -n "$2" ]
        do
        shift
        arrayback+=("$1")
        done
     break;;
 -i) echo "Interactive mode"
        interactive=1
        break;;
 -z) compression=1;;
  *) echo "Error in command input" >&2
        echo " -i     Interactive mode"  >&2
        echo " -z     Creating a compressed archive       example (-z -l /home/user -d /etc/passwd)" >&2
        echo " -s     Server selection                    example (-s user@192.168.0.1:/home/user -d /etc/passwd)" >&2
        echo " -l     Backup to local server              example (-l /home/user -d /etc/frr/frr.conf /etc/hosts)" >&2
        echo " -d     Selecting directories for backup    example (-d /etc/passwd /etc/hosts)" >&2
        break;;
esac
shift
done


function localbackup {
if [ -n "$compression" ]
then
tar -czf $local/backup.tar.gz ${arrayback[*]}
else
for value in "${arrayback[@]}"
do
if [ -n "$value" ]
then
cp -r $value $local
fi
done
fi
echo Complete!
}

function serverbackup {
exec 2</dev/null
tar -czf /home/$USER/backup.tar.gz ${arrayback[*]}
exec 6<&2
scp /home/$USER/backup.tar.gz "$server"
rm -rf /home/$USER/backup.tar.gz
echo Complete!
}

function convert_to_array {
for x in $stringi
do
arrayback+=($x)
done
}


#localbackup console release
if [ -n "$local" ]
then
localbackup
fi


#serverbackup console release
if [ -n "$server" ]
then
serverbackup
fi


#interactive mode beginning
if [ -n "$interactive" ] 
then
read -p "Local backup? (yes or no): " choise

#local backup interactive
if [ "$choise" = yes ]
then
read -p "Which directory to backup to? (example: /home/user): " local
read -p "What files to backup? (Through a space): " stringi                        #Эта переменная прекрасно работает и без массива, но мне нужна была совместимость с функцией
read -p "Place the backup in a compressed archive? (yes or no): " choisecomp       #Та же история
convert_to_array
if [ $choisecomp = yes ]
then
compression=1
fi
localbackup
fi

#server backup interactive
if [ "$choise" = no ]
then
read -p "Which server to backup to? (example user@192.168.0.1:/home/user): " server
read -p "What files to backup? (Through a space): " stringi
convert_to_array
serverbackup
fi
fi
