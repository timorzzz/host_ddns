#!/bin/bash -
#===============================================================================
#
#          FILE: hostupdate
#
#         USAGE: ./hostupdate
#
#   DESCRIPTION: 实时更新自己电脑上的hosts，加速网络的访问。
#
#===============================================================================

rm -f /tmp/host_new*
host_new=/tmp/host_new$$

# 1. 获取旧hosts文件来源
if [[ -f "$1" ]]; then
	ref_host="$1"                               # 参考的host来源
else
	ref_host=/etc/hosts                         # 默认从/etc/hosts上获取链接参考
fi

touch $host_new && tail -f $host_new &

# 2. 更新hosts
#echo -e "\e[0;35m --> 开始更新hosts文件\e[0m" # purple
cat $ref_host | while read line; do
if [[ ${line:0:1} == '#' ]] || [[ ${#line} == 0 ]] \
	|| [[ $(echo $line | grep ::) != "" ]] \
	|| [[ $(echo $line | grep ^10\.) != "" ]] \
	|| [[ $(echo $line | grep localhost) != "" ]] \
	|| [[ $(echo $line | grep $HOSTNAME) != "" ]]; then
	echo $line >> $host_new
else
	addr=$(echo $line|awk '{print $2}')
	link=$(nslookup "$addr" | sed '/^$/d' | sed -n '$p' | sed -n 's/Address: //gp')
	if [[ "$link" != "" ]]; then
		printf "%-19s%s\n" $link $addr >> $host_new
	else
		echo $line >> $host_new
	fi
fi
done

# 3. 复制至 /etc/hosts
#echo -en "\e[0;35m --> 更新hosts文件完毕，是否将新文件 $host_new 移动至 /etc/hosts[Y/n]:\e[0m" # purple
#read -p "" reply
#文件有变化时复制
if [[ $(md5sum $host_new | awk '{print $1}') != $(md5sum $ref_host | awk '{print $1}') ]]; then
mv /etc/hosts{,.bak}
cp $host_new /etc/hosts
/etc/init.d/nscd restart
fi
echo -e "全部操作完成，Enjoy!" # cyan

