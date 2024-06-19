#!/bin/bash
#
# https://github.com/LuckyPuppy514/automatic-theater/install.sh
# 作者：LuckyPuppy514
# 时间：2022-08-25
#
# 本脚本用于安装 automatic-theater
#

set -e

echo "|------------------------------------------------------|"
echo "|                                                      |"
echo "|                  Automatic Theater                   |" 
echo "|  https://github.com/LuckyPuppy514/automatic-theater  |"
echo "|                                                      |"
echo "|------------------------------------------------------|"
echo ""
echo "|------------------------------------------------------|"
echo "|                     当前配置如下                     |"
echo "|------------------------------------------------------|"
cat ./docker-compose-default.env
echo "|------------------------------------------------------|"
echo ""
echo "确认信息，并继续执行？（是：y，否：n）："
read CONFIRM
YES=y
if [[ "${CONFIRM}" == "${YES}" ]]; then
	echo ""
else
	echo "取消并退出"
	exit
fi

. ./docker-compose-default.env

compose_file=docker-compose-default.yml
macvlan=$(docker network ls|grep "${macvlan_name}"|awk -F' ' '{print $2}')
if [[ "${macvlan}" ]]; then
  if [[ "${qbittorrent_ip}" ]]; then
    echo "✅  已检测到macvlan网络，将使用 ${macvlan} 创建qBittorrent，IP：${qbittorrent_ip}"
    compose_file=docker-compose-macvlan.yml
  else
    echo "✖️  未指定macvlan下qBittorrent的IP，请设定 qbittorrent_ip 变量"
    exit
  fi
else
  echo "✖️  未检测到macvlan网络，qBittorrent可能会占用代理流量"
  echo " macvlan网络创建示例：docker network create -d macvlan --subnet=192.168.1.0/24 --gateway=192.168.1.1 -o parent=eth0 macvlan_direct"
fi

echo ""
echo "开始创建目录 ......"
if [[ ! -d ${MEDIA_PATH} ]]; then
	sudo mkdir -p ${MEDIA_PATH}
	echo "✅  创建目录成功：${MEDIA_PATH}"
fi
if [[ ! -d ${MEDIA_PATH}/movie ]]; then
	sudo mkdir ${MEDIA_PATH}/movie
	echo "✅  创建目录成功：${MEDIA_PATH}/movie"
fi
if [[ ! -d ${MEDIA_PATH}/serial ]]; then
	sudo mkdir ${MEDIA_PATH}/serial
	echo "✅  创建目录成功：${MEDIA_PATH}/serial"
fi
if [[ ! -d ${MEDIA_PATH}/anime ]]; then
	sudo mkdir ${MEDIA_PATH}/anime
	echo "✅  创建目录成功：${MEDIA_PATH}/anime"
fi
if [[ ! -d ${MEDIA_PATH}/download ]]; then
	sudo mkdir ${MEDIA_PATH}/download
	echo "✅  创建目录成功：${MEDIA_PATH}/download"
fi
echo "✅  创建目录成功"

echo ""
echo "修改目录权限 ......"
sudo chown -R ${USERNAME}:${GROUPNAME} ${MEDIA_PATH}
sudo chmod -R 770 ${MEDIA_PATH}
echo "✅  修改媒体目录权限成功"

echo "|"
echo "|------------------------------------------------------|"
echo "|                     当前目录结构                     |"
echo "|------------------------------------------------------|"
ls -l ${MEDIA_PATH}
echo "|------------------------------------------------------|"

echo ""
echo "生成环境变量 ......"
sudo cp ./docker-compose-default.env ./.env
echo "✅  生成环境变量成功"

workdir=$(pwd)
echo ""
echo "修改目录权限 ......"
sudo chown -R ${USERNAME}:${GROUPNAME} $workdir
sudo chmod -R 770 $workdir
echo "✅  修改 $(workdir) 目录权限成功"

echo ""
echo "添加显卡配置 ......"
sudo cp ./${compose_file} ./docker-compose.yml
sudo chown -R ${USERNAME}:${GROUPNAME} ./docker-compose.yml
sudo chmod -R 770 ./docker-compose.yml
DEVICE=""
if [[ -d "/dev/dri" ]]; then
	DEVICE="/dev/dri:/dev/dri"
fi
if [[ -d "/dev/vchiq" ]]; then
	DEVICE="/dev/vchiq:/dev/vchiq"
fi
if [[ ${DEVICE} ]]; then
	sudo echo "    devices:" >> ./docker-compose.yml
	sudo echo "      - ${DEVICE}" >> ./docker-compose.yml
	echo "✅  添加硬件加速设备成功"
else
	echo "✖️  未检测到 /dev/dri 或 /dev/vchiq，无法为 Jellyfin 添加硬件加速设备"
fi

echo "✅  程序执行完毕 ✅"
