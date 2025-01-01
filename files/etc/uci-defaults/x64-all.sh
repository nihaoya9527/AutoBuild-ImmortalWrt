#!/bin/sh

# 设置默认防火墙规则，方便虚拟机首次访问 WebUI
uci set firewall.@zone[1].input='ACCEPT'

# 设置主机名映射，解决安卓原生 TV 无法联网的问题
uci add dhcp domain
uci set "dhcp.@domain[-1].name=time.android.com"
uci set "dhcp.@domain[-1].ip=203.107.6.88"


# 根据网卡数量配置网络
count=0
for iface in /sys/class/net/*; do
  iface_name=$(basename "$iface")
  # 检查是否为物理网卡（排除回环设备和无线设备）
  if [ -e "$iface/device" ] && echo "$iface_name" | grep -Eq '^eth|^en'; then
    count=$((count + 1))
  fi
done

# 网络设置
if [ "$count" -eq 1 ]; then
  uci set network.lan.proto='dhcp'
elif [ "$count" -gt 1 ]; then
  uci set network.lan.ipaddr='192.168.1.11'
fi

# 设置所有网口可访问网页终端
uci delete ttyd.@ttyd[0].interface

# 设置所有网口可连接 SSH
uci set dropbear.@dropbear[0].Interface=''
uci commit

# 设置编译作者信息
#FILE_PATH="/etc/openwrt_release"
#NEW_DESCRIPTION="Compiled by GXNAS"
#sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='$NEW_DESCRIPTION'/" "$FILE_PATH"

# 修改主机名字，修改你喜欢的就行（不能纯数字或者使用中文）
sed -i "/uci commit system/i\uci set system.@system[0].hostname='OpenWrt-GXNAS'" package/lean/default-settings/files/zzz-default-settings
sed -i "s/hostname='.*'/hostname='OpenWrt-GXNAS'/g" ./package/base-files/files/bin/config_generate

# 调整 x86 型号只显示 CPU 型号
sed -i 's/${g}.*/${a}${b}${c}${d}${e}${f}${hydrid}/g' package/lean/autocore/files/x86/autocore

# 设置ttyd免帐号登录
sed -i 's/\/bin\/login/\/bin\/login -f root/' feeds/packages/utils/ttyd/files/ttyd.config

# coremark跑分定时清除
sed -i '/\* \* \* \/etc\/coremark.sh/d' feeds/packages/utils/coremark/*

# 修改 argon 为默认主题
sed -i '/set luci.main.mediaurlbase=\/luci-static\/bootstrap/d' feeds/luci/themes/luci-theme-bootstrap/root/etc/uci-defaults/30_luci-theme-bootstrap
sed -i 's/Bootstrap theme/Argon theme/g' feeds/luci/collections/*/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/*/Makefile

# 最大连接数修改为65535
sed -i '/customized in this file/a net.netfilter.nf_conntrack_max=65535' package/base-files/files/etc/sysctl.conf

# 显示增加编译时间
sed -i "s/DISTRIB_REVISION='R[0-9]\+\.[0-9]\+\.[0-9]\+'/DISTRIB_REVISION='@R$build_date'/g" package/lean/default-settings/files/zzz-default-settings
sed -i 's/LEDE/OpenWrt_2305_x64_全功能版 by GXNAS build/g' package/lean/default-settings/files/zzz-default-settings

# 修改右下角脚本版本信息
sed -i 's/<a class=\"luci-link\" href=\"https:\/\/github.com\/openwrt\/luci\" target=\"_blank\">Powered by <%= ver.luciname %> (<%= ver.luciversion %>)<\/a>/OpenWrt_2305_x64_全功能版 by GXNAS build @R'"$build_date"'/' package/luci-theme-argon/luasrc/view/themes/argon/footer.htm
sed -i 's|<a href="https://github.com/jerrykuku/luci-theme-argon" target="_blank">ArgonTheme <%# vPKG_VERSION %></a>|<a class="luci-link" href="https://wp.gxnas.com" target="_blank">🌐固件编译者：【GXNAS博客】</a>|' package/luci-theme-argon/luasrc/view/themes/argon/footer.htm
sed -i 's|<%= ver.distversion %>|<a href="https://d.gxnas.com" target="_blank">👆点这里下载最新版本</a>|' package/luci-theme-argon/luasrc/view/themes/argon/footer.htm
sed -i "/<a class=\"luci-link\"/d; /<a href=\"https:\/\/github.com\/jerrykuku\/luci-theme-argon\"/d; s|<%= ver.distversion %>|OpenWrt_2305_x64_全功能版 by GXNAS build @R$build_date|" package/luci-theme-argon/luasrc/view/themes/argon/footer_login.htm

# 修改欢迎banner
cp -f $GITHUB_WORKSPACE/x64/banner package/base-files/files/etc/banner

exit 0
