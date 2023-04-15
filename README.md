# iptv-checker
最简单的iptv检测脚本。

linux直接运行，windows需要msys2或者mingw运行，依赖curl、iconv。

命令：
```
$ sh iptv-checker.sh <m3u文件>
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





