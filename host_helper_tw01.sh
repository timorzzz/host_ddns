#!/bin/bash

#缓存文件
WorkFile="/dev/shm/nginx_helper"

domain=('qspssf.ddnsgeek.com')

#备份原hosts
if [ ! -f "/etc/hosts.bak" ];then 
	cp /etc/hosts /etc/hosts.bak
fi

#检测是否有host指令，如果没有就装一下
if [ "`command -v host`" == "" ]; then
    if [ ! -f "/etc/redhat-release" ]; then
        apt install -y dnsutils
    else 
	yum install -y bind-utils
    fi
fi

#删除可能遗留的缓存
rm -rf $WorkFile.changed
rm -rf $WorkFile.hosts

for rule in ${domain[@]}
do
	{
	ip=`host $rule|grep -E -o '([0-9]{1,3}[\.]){3}[0-9]{1,3}'|sed -n '1p'`
	if [ "$ip" ];then 
		echo "$ip $rule">>$WorkFile.hosts
		if [ ! "`grep $ip /etc/hosts`" ];then touch $WorkFile.changed;fi
	else 
		#若某域名未解析到IP，就设置为保留IP 避免nginx启动失败
		echo "169.254.255.255 $rule">>$WorkFile.hosts
	fi
	}&
done
wait

if [ -f "$WorkFile.changed" ];then 
	`which cp|tail -1` -f /etc/hosts.bak /etc/hosts
	cat $WorkFile.hosts >>/etc/hosts
	rm -rf $WorkFile.changed
	#systemctl reload nginx
fi
rm -rf $WorkFile.hosts
