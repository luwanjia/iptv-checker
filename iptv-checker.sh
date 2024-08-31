#!/bin/bash

function check_url()
{
    ck_url=$1
    ck_name=$2
    time_expire=$3
    time_max=$4

    for i in {1, 2, 3}
    do
        res_url=`curl -L -o /dev/null -s -w "%{time_namelookup}\t%{time_connect}\t%{time_starttransfer}\t%{time_total}\t%{speed_download}\t%{http_code}\n" --max-time $time_max "$1"`

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

# 定义一个函数检查浮点数是否在闭区间内
function check_threshold()
{
    local num="$1"
    local lower="$2"
    local upper="$3"

    # 使用 awk 进行浮点数比较
    awk -v num="$num" -v lower="$lower" -v upper="$upper" \
    'BEGIN { if (num >= lower && num <= upper) print "true"; else print "false" }'
}

function usage()
{
    echo "-- Usage: $0 [option] <file.m3u>"
    echo "    -e time threshold to define m3u8 quality."
    echo "       value range is 0.5 to 5"
    echo "    -t time threshold for curl connection."
    echo "       value range is 1 to 10"
    echo "    -h help info."
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

options_processed=0
while getopts "he:t:" opt; do
    case $opt in
        h)
            echo "-- opt: -h"
            usage
            exit 0
            ;;
        e)
            curl_time_expire=$OPTARG
            options_processed=1
            ;;
        t)
            curl_time_max=$OPTARG
            options_processed=1
            ;;
        \?)
            echo "-- error: unsupported option -$OPTARG"
            exit 1
            ;;
        :)
            echo "-- error: no value for option -$OPTARG"
            exit 1
            ;;
    esac
done

shift $((OPTIND - 1))

# 01 检查是否还有选项在参数之后
if [ "$options_processed" -eq 0 ] && [ "$#" -gt 1 ]; then
    echo "-- error: options must be specified before positional arguments"
    exit 1
fi

EXPIRE_MIN=0.5
EXPIRE_MAX=5
TIME_MIN=1
TIME_MAX=10

# 02 参数默认值
if [ -z "$curl_time_expire" ]; then
    curl_time_expire=$EXPIRE_MIN
fi
if [ -z "$curl_time_max" ]; then
    curl_time_max=$TIME_MIN
fi

# 03 校验参数是否为有效数字（包括小数）
if ! [[ "$curl_time_expire" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
    echo "-- error: The parameter of option '-e' must be a number."
    exit 1
fi
if ! [[ "$curl_time_max" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
    echo "-- error: The parameter of option '-t' must be a number."
    exit 1
fi

# 04 校验参数是否在指定范围内
result=$(check_threshold "$curl_time_expire" "$EXPIRE_MIN" "$EXPIRE_MAX")
if [ "$result" = "false" ]; then
    echo "-- error: The value for option '-e' must be between $EXPIRE_MIN and $EXPIRE_MAX."
    exit 1
fi
result=$(check_threshold "$curl_time_max" "$TIME_MIN" "$TIME_MAX")
if [ "$result" = "false" ]; then
    echo "-- error: The value for option '-t' must be between $TIME_MIN and $TIME_MAX"
    exit 1
fi

# 05 校验剩余参数个数
if [ $# -eq 0 ]; then
    usage
    exit 0
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
    check_url "$m3u_url" "$m3u_info" "$curl_time_expire" "$curl_time_max"

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
