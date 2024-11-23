#!/bin/bash

# 设置 PATH 变量
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# 配置参数
INTERFACE="eno2"       # 出口网卡名称，请根据实际情况修改
IFB_INTERFACE="ifb0"   # IFB 虚拟接口名称
LIMIT_BW=498000        # 限速值（单位：Kbps，即 498 Mbps）
THRESHOLD_BW=500000    # 阈值（单位：Kbps，即 500 Mbps）
MAX_DATA_POINTS=70   # 最大超限数据点数 
DATA_POINTS_FILE="/var/log/bandwidth_usage.log"  # 数据记录文件
LIMIT_FLAG_FILE="/tmp/bandwidth_limited"         # 限速标志文件
PEAK_START=19          # 高峰时段开始时间
PEAK_END=23            # 高峰时段结束时间
LIMIT_DURATION=420     # 限速持续时间（单位：秒，即 7 分钟）

# 检查是否安装了 ifstat
if ! command -v ifstat >/dev/null 2>&1; then
    echo "错误：ifstat 未安装，请先安装后重试。" >> /var/log/bandwidth_debug.log
    exit 1
fi

# 检查是否加载了 ifb 模块
if ! lsmod | grep -q "^ifb"; then
    if modprobe ifb; then
        echo "已加载 ifb 模块" >> /var/log/bandwidth_debug.log
    else
        echo "错误：无法加载 ifb 模块"  >> /var/log/bandwidth_debug.log
        exit 1
    fi
fi

# 初始化 IFB 接口
init_ifb() {
    if ip link show $IFB_INTERFACE >/dev/null 2>&1; then
        ip link set dev $IFB_INTERFACE down
        ip link delete $IFB_INTERFACE type ifb
    fi
    ip link add $IFB_INTERFACE type ifb
    ip link set dev $IFB_INTERFACE up
}

# 定义应用限速函数
apply_limit() {
    local reason="$1"

    # 应用出方向限速
    if ! tc qdisc replace dev $INTERFACE root tbf rate ${LIMIT_BW}kbit burst 32kbit latency 400ms; then
        echo "$(date): 出方向限速失败 (tc qdisc replace)" >> /var/log/bandwidth_control.log
        return 1
    fi

    # 初始化 IFB 接口
    init_ifb

    # 将入方向流量重定向到 IFB 接口
    if ! tc qdisc replace dev $INTERFACE ingress; then
        echo "$(date): 无法为 $INTERFACE 添加 ingress qdisc" >> /var/log/bandwidth_control.log
        return 1
    fi

    if ! tc filter add dev $INTERFACE parent ffff: protocol all u32 match u32 0 0 action mirred egress redirect dev $IFB_INTERFACE; then
        echo "$(date): 无法添加流量重定向到 $IFB_INTERFACE 的过滤器" >> /var/log/bandwidth_control.log
        return 1
    fi

    # 在 IFB 接口上应用限速
    if ! tc qdisc replace dev $IFB_INTERFACE root tbf rate ${LIMIT_BW}kbit burst 32kbit latency 400ms; then
        echo "$(date): 无法在 $IFB_INTERFACE 上应用限速" >> /var/log/bandwidth_control.log
        return 1
    fi

    # 记录限速标志
    echo "$reason $(date +%s)" > $LIMIT_FLAG_FILE
    echo "$(date): 因 $reason 应用限速成功" >> /var/log/bandwidth_control.log
}

# 定义移除限速函数
remove_limit() {
    # 移除出方向限速
    if ! tc qdisc del dev $INTERFACE root; then
        echo "$(date): 移除出方向限速失败 (tc qdisc del)" >> /var/log/bandwidth_control.log
    fi

    # 移除 ingress qdisc 和过滤器
    if tc qdisc show dev $INTERFACE | grep -q "ingress"; then
        if ! tc qdisc del dev $INTERFACE ingress; then
            echo "$(date): 移除 ingress qdisc 失败 (tc qdisc del)" >> /var/log/bandwidth_control.log
        fi
    fi

    # 移除 IFB 接口上的限速
    if tc qdisc show dev $IFB_INTERFACE | grep -q "tbf"; then
        if ! tc qdisc del dev $IFB_INTERFACE root; then
            echo "$(date): 移除 $IFB_INTERFACE 上的限速失败 (tc qdisc del)" >> /var/log/bandwidth_control.log
        fi
    fi

    # 删除 IFB 接口
    if ip link show $IFB_INTERFACE >/dev/null 2>&1; then
        ip link set dev $IFB_INTERFACE down
        ip link delete $IFB_INTERFACE type ifb
    fi

    # 删除限速标志文件
    if [ -f $LIMIT_FLAG_FILE ]; then
        if ! rm -f $LIMIT_FLAG_FILE; then
            echo "$(date): 删除限速标志文件失败" >> /var/log/bandwidth_control.log
        fi
    fi
    echo "$(date): 限速规则移除成功" >> /var/log/bandwidth_control.log
}

# 初始化变量
CURRENT_MINUTE=$(date +"%Y-%m-%d %H:%M")
CURRENT_DATE=$(date +"%Y-%m-%d")
PEAK_RATE=0

# 主循环
while true; do
    # 检查日期是否已更改以重置统计数据
    NOW_DATE=$(date +"%Y-%m-%d")
    if [ "$NOW_DATE" != "$CURRENT_DATE" ]; then
        > $DATA_POINTS_FILE
        remove_limit
        CURRENT_DATE=$NOW_DATE
    fi

    # 使用 ifstat 获取 Kbps 单位的 RX 和 TX 速率
    ifstat_output=$(ifstat -i $INTERFACE -b -T -n 1 1 2>/dev/null | tail -n1)

    # 检查 ifstat 输出是否为空
    if [ -z "$ifstat_output" ]; then
        RX_RATE=0
        TX_RATE=0
    else
        # 提取速率值并强制转换为整数
        RX_RATE=$(echo "$ifstat_output" | awk '{print int($1)}')
        TX_RATE=$(echo "$ifstat_output" | awk '{print int($2)}')
    fi

    # 确保 RX_RATE 和 TX_RATE 为整数
    RX_RATE=${RX_RATE:-0}
    TX_RATE=${TX_RATE:-0}

    # 取 RX 和 TX 的较大值作为当前速率
    if [ "$RX_RATE" -gt "$TX_RATE" ]; then
        CURRENT_RATE=$RX_RATE
    else
        CURRENT_RATE=$TX_RATE
    fi

    # 确保 CURRENT_RATE 和 PEAK_RATE 为整数
    CURRENT_RATE=${CURRENT_RATE:-0}
    PEAK_RATE=${PEAK_RATE:-0}

    # 调试日志
    echo "调试：$(date): RX_RATE=$RX_RATE, TX_RATE=$TX_RATE, CURRENT_RATE=$CURRENT_RATE, PEAK_RATE=$PEAK_RATE" >> /var/log/bandwidth_debug.log

    # 更新当前分钟的峰值
    NOW=$(date +"%Y-%m-%d %H:%M")
    if [ "$NOW" == "$CURRENT_MINUTE" ]; then
        if [ "$CURRENT_RATE" -gt "$PEAK_RATE" ]; then
            PEAK_RATE=$CURRENT_RATE
        fi
    else
        # 新的一分钟，记录上一分钟的峰值
        echo "$CURRENT_MINUTE $PEAK_RATE" >> $DATA_POINTS_FILE

        # 执行限速检查
        EXCEED_COUNT=$(awk -v threshold=$THRESHOLD_BW '$3 > threshold {count++} END {print count}' $DATA_POINTS_FILE)
        LIMITED=0

        if [ -f $LIMIT_FLAG_FILE ]; then
            LIMITED=1
            read REASON START_TIME < $LIMIT_FLAG_FILE
            CURRENT_TIME=$(date +%s)
            if [ "$REASON" = "Rule1" ] && [ $((CURRENT_TIME - START_TIME)) -ge $LIMIT_DURATION ]; then
                remove_limit
                LIMITED=0
            fi
        fi

        if [ "$EXCEED_COUNT" -gt "$MAX_DATA_POINTS" ]; then
            if [ "$LIMITED" -eq 0 ] || [ "$REASON" = "Rule1" ]; then
                apply_limit "Rule2"
            fi
        else
            CURRENT_HOUR=$(date +"%-H")
            if [ "$CURRENT_HOUR" -ge "$PEAK_START" ] && [ "$CURRENT_HOUR" -le "$PEAK_END" ]; then
                # 高峰时段，不执行 Rule1
                :
            else
                LAST_THREE=$(tail -n3 $DATA_POINTS_FILE | awk '{print $3}')
                COUNT=0
                for RATE in $LAST_THREE; do
                    if [[ "$RATE" =~ ^[0-9]+$ ]]; then
                        if [ "$RATE" -gt "$THRESHOLD_BW" ];            then
                            COUNT=$((COUNT+1))
                        fi
                    fi
                done

                if [ "$COUNT" -eq 3 ]; then
                    if [ "$LIMITED" -eq 0 ]; then
                        apply_limit "Rule1"
                    fi
                fi
            fi
        fi

        CURRENT_MINUTE=$NOW
        PEAK_RATE=$CURRENT_RATE
    fi

    sleep 1
done
