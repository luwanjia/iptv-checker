#!/bin/bash

function check_url()
{
	ck_url=$1
	ck_name=$2
	time_expire=$3
	for i in {1, 2, 3}
	do
		res_url=`curl -L -o /dev/null -s -w "%{time_namelookup}\t%{time_connect}\t%{time_starttransfer}\t%{time_total}\t%{speed_download}\t%{http_code}\n" --max-time 1 "$1"`

		time_namelookup=`echo $res_url | awk '{print $1}'`
		time_connect=`echo $res_url | awk '{print $2}'`
		time_starttransfer=`echo $res_url | awk '{print $3}'`
		time_total=`echo $res_url | awk '{print $4}'`
		speed_download=`echo $res_url | awk '{print $5}'`
		http_code=`echo $res_url | awk '{print $6}'`
		if [ `expr $time_total \< $time_expire` -eq 1 ]
		then
			break
		fi
	done

	if [ ! "$http_code" == "200" ] || [ `expr $time_total \> $time_expire` -eq 1 ]
	then 
		echo -e "\033[31m-- [Failed ] $time_namelookup\t$time_connect\t$time_starttransfer\t$time_total\t$speed_download\t$http_code\033[0m"
		echo -e "\033[31m--     $ck_name\033[0m"
		echo -e "\033[31m--     $ck_url\033[0m"
		return 1
	else
		echo -e "\033[33m++ [Success] $time_namelookup\t$time_connect\t$time_starttransfer\t$time_total\t$speed_download\t$http_code\033[0m"
		echo -e "\033[33m++     $ck_name\033[0m"
		echo -e "\033[33m++     $ck_url\033[0m"
		return 0
	fi
}

if [ -d "output" ]; then
	rm output -rf
fi
mkdir -p output

if [ -d "output_gbk" ]; then
	rm output_gbk -rf
fi
mkdir -p output_gbk

m3u_all="all_online.m3u"
if [ -f "$m3u_all" ]; then
	rm $m3u_all -f
fi	

cat $1 | tr -d '\r' | while read line
do
	url_pre=${line%%:*}
	if [ ! "$url_pre" = "#EXTINF" ] && [ ! "$url_pre" = "http" ]
	then
		continue;
	fi

	# 读取信息描述
	if [ "$url_pre" = "#EXTINF" ]
	then
		m3u_info="$line"
		continue
	fi

	# 读取URL
	if [ "$url_pre" = "http" ]
	then
		m3u_url=$line
	fi

	# 获取TV名称
	m3u_name="all"
	if [ -n "$m3u_info" ]
	then
		 m3u_name=`echo ${m3u_info#*,} | sed 's/[\[\/\\\|\?\"\*\:\<\>\.]//g' | sed 's/\]//g' | tr -d ' '`
	fi

	m3u_file="output/$m3u_name.m3u"
	m3u_file_gbk="output_gbk/$m3u_name.m3u"

	# 检查URL
	check_url "$m3u_url" "$m3u_info" 0.6

	if [ $? = 0 ]
	then
		if [ -n "$m3u_info" ]; then
			echo "$m3u_info" >> "$m3u_file"
			echo "$m3u_info" >> "$m3u_all"
		fi

		echo "$m3u_url" >> "$m3u_file"
		echo "$m3u_url" >> "$m3u_all"
		iconv -f UTF-8 -t GBK "$m3u_file" > "$m3u_file_gbk"
	fi

   m3u_info=""
   m3u_url=""
done
