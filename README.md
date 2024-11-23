# 95th Percentile Bandwidth Limiter

A dynamic bandwidth management script that enforces 95th percentile bandwidth limiting. This script helps maintain compliance with provider bandwidth contracts or self-imposed limits by dynamically adjusting bandwidth usage based on 1:2 burst configurations and monitoring network usage.

Key Features

	1.	95th Percentile Bandwidth Limiting:
	•	Enforces a strict limit of 498 Mbps (1:2 burst) when bandwidth exceeds 500 Mbps for 3 consecutive minutes.
	•	Limits persist for 7 minutes unless overridden by specific conditions.
	2.	Time-Based Exceptions:
	•	Does not enforce 95th percentile limits during peak hours (19:00–23:00 daily).
	3.	Daily Bandwidth Monitoring:
	•	Collects 1440 data points per day (1 data point per minute).
	•	If more than 70 data points exceed 500 Mbps in a day, bandwidth is limited to 498 Mbps for the remainder of the day, ignoring peak-hour exceptions.
	4.	Automatic Daily Reset:
	•	Resets all data points and limits at midnight (00:00) daily.
	5.	1:2 Burst Configuration:
	•	Supports traffic bursting with a ratio of 1:2, ensuring smooth traffic handling even when bandwidth spikes.

Why 95th Percentile?

The 95th percentile method is widely used in network billing to allow brief traffic bursts while limiting sustained overuse. This script dynamically applies limits to ensure compliance with the 95th percentile model, preventing billing overruns or performance issues.

Requirements

	•	Linux kernel support for tc (traffic control) and ifb (Intermediate Functional Block).
	•	ifstat for real-time bandwidth monitoring.
	•	Root privileges to execute traffic control (tc) commands.

Installation

1.	**更新脚本文件：**

•	将修改后的脚本保存为/root/bandwidth_control.sh

•	确保脚本具有执行权限：

```c
chmod +x /root/bandwidth_control.sh
```

2.	**创建**systemd

•	创建 /etc/systemd/system/bandwidth_control.service

```c
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

启动服务：

```c
systemctl daemon-reload
systemctl enable bandwidth_control.service
systemctl start bandwidth_control.service

systemctl stop bandwidth_control.service
systemctl restart bandwidth_control.service
```

**3.	验证服务运行状态：**

```c
systemctl status bandwidth_control.service
```

1.  调试日志

```c
tail -f /var/log/bandwidth_debug.log
```

调试日志轮换 

nano /etc/logrotate.d/bandwidth_debug

```c
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

1. 流量记录

```c
cat /var/log/bandwidth_usage.log 
```

1. 限速记录

```c
cat /var/log/bandwidth_control.log
```

Example Scenarios

	1.	Sustained High Traffic:
	•	If bandwidth exceeds 500 Mbps for 3 consecutive minutes:
	•	Bandwidth is limited to 498 Mbps (1:2 burst) for 7 minutes.
	•	During peak hours (19:00–23:00), no limits are enforced.
	2.	Daily Excessive Usage:
	•	If more than 70 out of 1440 data points exceed 500 Mbps:
	•	Bandwidth is limited to 498 Mbps for the rest of the day, regardless of time.

License

This project is licensed under the MIT License. See the LICENSE file for details.

MIT License

MIT License

Copyright (c) 2024 <tenotek>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

