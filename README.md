# 95th Percentile Bandwidth Limiter

A script to dynamically manage network traffic based on **95th percentile bandwidth limiting**. It enforces compliance with provider contracts by monitoring traffic patterns, supporting **1:2 burst configurations**, and applying intelligent bandwidth limits to prevent overuse and ensure smooth operations.

需要部署在宿主机的出口网卡上，且该脚本仅在 Proxmox VE 8（Debian 12）上通过测试。  
This bandwidth management rule should be deployed on the host machine, and the system has only been tested on Proxmox VE 8 (based on Debian 12).

---

## 预设特性 / Preset Features

### 1. 动态带宽限速 / Dynamic Bandwidth Limiting  
- **规则 / Rule**:  
  当带宽连续3分钟（连续3个数据点）超过500 Mbps时，限速至498 Mbps，持续7分钟。  
  When bandwidth exceeds 500 Mbps for 3 consecutive minutes (3 consecutive data points), limit the bandwidth to 498 Mbps for a duration of 7 minutes.

- **例外 / Exception**:  
  每天19:00至23:00期间不生效。  
  Does not apply during 19:00 to 23:00 daily.

### 2. 每日带宽监控 / Daily Bandwidth Monitoring  
- **规则 / Rule**:  
  每天采集1440个数据点（每分钟1个）。  
  Collect 1440 data points per day (1 data point per minute).  
  数据点为对应1分钟内的峰值带宽。  
  Each data point represents the peak bandwidth within that minute.

- **触发限速条件 / Triggering Condition**:  
  如果累计超过70个数据点的带宽超过500 Mbps，则无视动态带宽限速（包含例外），当天剩余时间限速至498 Mbps。  
  If more than 70 data points exceed 500 Mbps, ignore the dynamic bandwidth limiting (including exceptions) and limit the bandwidth to 498 Mbps for the remainder of the day.

---

## 部署步骤 / Deployment Steps

### 1. 保存脚本 / Save the Script
将脚本保存为 `/root/bandwidth_control.sh`：  
Save the provided script to your system, for example, as `/root/bandwidth_control.sh`.

确保脚本具有可执行权限：  
Ensure the script has executable permissions:
```bash
chmod +x /root/bandwidth_control.sh
```

---

### 2. 创建 Systemd 服务 / Create a Systemd Service
创建一个 systemd 服务文件 `/etc/systemd/system/bandwidth_control.service`：  
Create a systemd service file at `/etc/systemd/system/bandwidth_control.service`:
```ini
[Unit]
Description=Bandwidth Control Service
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash /root/bandwidth_control.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

---

### 3. 启动服务 / Start the Service
重新加载 systemd：  
Reload systemd to recognize the new service:
```bash
systemctl daemon-reload
```

设置服务开机启动：  
Enable the service to start at boot:
```bash
systemctl enable bandwidth_control.service
```

启动服务：  
Start the service:
```bash
systemctl start bandwidth_control.service
```

---

### 4. 验证服务 / Verify the Service
检查服务状态：  
To check the service status and ensure it's running:
```bash
systemctl status bandwidth_control.service
```

停止或重启服务：  
To stop or restart the service:
```bash
systemctl stop bandwidth_control.service
systemctl restart bandwidth_control.service
```

---

### 5. 配置日志轮替 / Configure Log Rotation
为了管理调试日志并防止磁盘空间占用，创建一个日志轮替配置文件 `/etc/logrotate.d/bandwidth_debug`：  
To manage debug logs and prevent disk space issues, create a log rotation configuration file at `/etc/logrotate.d/bandwidth_debug`:
```ini
/var/log/bandwidth_debug.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    size 50M
    create 644 root root
}
```

---

## 日志与调试 / Logs and Debugging

### 调试日志 / Debug Logs
实时调试：  
For real-time debugging:
```bash
tail -f /var/log/bandwidth_debug.log
```

### 带宽使用日志 / Bandwidth Usage Logs
检查采集的带宽使用数据：  
Check captured bandwidth usage data:
```bash
cat /var/log/bandwidth_usage.log
```

### 带宽控制日志 / Bandwidth Control Logs
查看限速操作记录：  
Review applied limits and actions:
```bash
cat /var/log/bandwidth_control.log
```

---

## License

此项目采用 MIT 许可协议，详见 LICENSE 文件。  
This project is licensed under the MIT License. See the LICENSE file for details.
