# iptv-checker
## 0 介绍
最简单的iptv检测脚本

linux直接运行，windows需要msys2或者mingw运行，依赖curl、iconv。

命令：
```
$ -- Usage: sh iptv-checker.sh [option] <file.m3u>
    -e time threshold to define m3u8 quality.
       value range is 0.5 to 5
    -t time threshold for curl connection.
       value range is 1 to 10
    -h help info.
```
输出：
  * output -- 目录，UTF-8格式，适用linux，一个频道一个文件
  * output_gbk -- 目录，GBK格式，使用windows，一个频道一个文件
  * all_online.m3u -- 文件，所有检测通过的频道，所有的频道都放在一个文件中

仅支持m3u文件检测，有格式要求，例如：
```
#EXTINF:-1 tvg-id="CCTV1.cn" status="online",CCTV-1综合 (1080p)
http://117.169.120.140:8080/live/cctv-1/.m3u8
#EXTINF:-1 tvg-id="CCTV1.cn" status="timeout",CCTV-1综合 (1080p)
http://183.207.249.15/PLTV/3/224/3221225530/index.m3u8
#EXTINF:-1 tvg-id="CCTV1.cn" status="error",CCTV-1综合 (1080p)
http://183.207.249.9/PLTV/3/224/3221225530/index.m3u8
```
频道信息以"#EXTINF"开头，第二行必须是http

## 1 详细说明

核心使用curl命令的http解析能力，依次提取以下连接数值：

%{time_namelookup}	// dns解析时长

%{time_connect}		// http连接创建时间

%{time_starttransfer}	// 开始传输时间

%{time_total}		// 连接创建完成并开始传输总时间

%{speed_download}	// 下载速度

%{http_code}	// http返回值，200表示成功



其中重点是%{http_code}和%{time_total}

%{http_code}为200的表示该m3u资源有效

%{time_total}为连接创建完成并开始传输总时间，数值越小表示网络延迟越好



因此，为了选择优质m3u资源，通过-e参数值与%{time_total}比较可完成筛选; 但是curl连接有个时间上限，即-t参数，-e参数表示curl检测的最大时长; -e参数值一般小于-t参数值;



-e参数：越小，筛选出来的m3u源质量越好，最小0.5 最大5，默认0.5，单位秒

-t参数：越大，筛选的时间越长，检测越精准，最小1，最大10，默认1，单位秒
