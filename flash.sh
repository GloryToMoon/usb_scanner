#!/bin/bash

root_disk='/dev/sda1'
root_directory='/root/flash'

check_disks(){
	cat /dev/null > disks.info
	disks=$(df -a | grep -v $root_disk | grep '/dev/sd' | awk '{print $1}')
	for diskpart in $disks
	do
		mount_path=$(df -a | grep -e "$diskpart" | awk '{print $6}')
		echo $diskpart $mount_path $(du -s "$mount_path" | awk '{print $1}') >> disks.info
		find $mount_path > $root_directory$(echo $diskpart | awk '{print $1}').value
	done
}

check_disks

file_gathering(){
	while [ "$size" -ne "$(du -s "$1" | awk '{print $1}')" ]
	do
		size=$(du -s "$1" | awk '{print $1}')
	done
	find $1 > $root_directory$2.new
	sort $root_directory$2.new $root_directory$2.value  | uniq -u > $root_directory$2.tmp

	if [ -n "$(cat $root_directory$2.tmp)" ]
	then
		c=0
		while [ "$c" -ne "$(wc -l $root_directory$2.tmp | awk '{print $1}')" ]
		do
			c=$(($c+1))
			stringdif=$(sed -n "$c"p $root_directory$2.tmp)
			if [ -f "$stringdif" ] || [ -d "$stringdif" ]
			then
				copypath="$root_directory/stolen/$(date +%s%N)"
				cp "$stringdif" $copypath
				echo [$(date)] 'Copy file to' $copypath >> $root_directory/log.txt
			else
				echo [$(date)] "File or directory $stringdif  was deleted!" >> $root_directory/log.txt
			fi
		done
	fi
	rm -f $root_directory$2.tmp $root_directory$2.new
}

while ((1))
do
	check_disks
	i=0
	while [ "$i" -ne "$(wc -l $root_directory/disks.info | awk '{print $1}')" ]
	do
		i=$(($i+1))
		string=$(sed -n "$i"p disks.info)
		path=$(echo $string | awk '{print $2}')
		size=$(echo $string | awk '{print $3}')
		if [ $size -ne $(du -s "$path" | awk '{print $1}') ]
		then
			file_gathering "$path" "$(echo $string | awk '{print $1}')"
		fi
	done
done
