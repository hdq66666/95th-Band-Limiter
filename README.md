95th Percentile Bandwidth Limiter

A dynamic bandwidth management script enforcing 95th percentile bandwidth limiting. This script ensures compliance with provider bandwidth contracts or self-imposed limits by dynamically adjusting traffic using a 1:2 burst configuration and real-time usage monitoring.

Why 95th Percentile?

The 95th percentile method is a standard in network billing, allowing for brief traffic bursts while managing sustained overuse. This script automates limit enforcement, ensuring compliance with the 95th percentile model to prevent billing overruns or network performance degradation.

Features

	1.	Dynamic Bandwidth Limiting:
	•	Limits bandwidth to 498 Mbps (1:2 burst) if usage exceeds 500 Mbps for 3 consecutive minutes.
	•	Applies limits for 7 minutes after the condition is met.
	2.	Time-Based Exceptions:
	•	No bandwidth limiting is applied during peak hours (19:00–23:00).
	3.	Daily Monitoring:
	•	Captures 1440 data points per day (one per minute).
	•	If more than 70 data points exceed 500 Mbps, limits are applied for the remainder of the day, regardless of peak-hour exceptions.
	4.	Automatic Reset:
	•	All data points and limits are reset at midnight (00:00) daily.
	5.	Comprehensive Logging:
	•	Tracks bandwidth usage, limiting actions, and debugging for full transparency.

Requirements

	•	Linux kernel support for tc (traffic control) and ifb (Intermediate Functional Block).
	•	ifstat for real-time bandwidth monitoring.
	•	Root privileges to execute traffic control (tc) commands.

Installation

1. Save the Script

Save the script as /root/bandwidth_control.sh and ensure it is executable:

chmod +x /root/bandwidth_control.sh

2. Set Up a Systemd Service

Create a systemd service file at /etc/systemd/system/bandwidth_control.service:

[Unit]
Description=Bandwidth Control Service
After=network.target

[Service]
Type=simple
ExecStart=/bin/bash /root/bandwidth_control.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target

Reload the systemd daemon and manage the service:

systemctl daemon-reload
systemctl enable bandwidth_control.service
systemctl start bandwidth_control.service

To stop or restart the service:

systemctl stop bandwidth_control.service
systemctl restart bandwidth_control.service

3. Verify Service Status

Check if the service is running:

systemctl status bandwidth_control.service

4. Configure Debug Log Rotation

To prevent debug logs from consuming excessive disk space, configure log rotation by creating /etc/logrotate.d/bandwidth_debug:

/var/log/bandwidth_debug.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    size 50M
    create 644 root root
}

Logs and Debugging

	•	Debug Logs:
View real-time debug logs for troubleshooting:

tail -f /var/log/bandwidth_debug.log


	•	Bandwidth Usage Logs:
Review captured bandwidth data:

cat /var/log/bandwidth_usage.log


	•	Control Logs:
Check limiting actions and rule applications:

cat /var/log/bandwidth_control.log

Example Scenarios

	1.	Sustained High Traffic:
	•	If bandwidth exceeds 500 Mbps for 3 consecutive minutes:
	•	Bandwidth is limited to 498 Mbps (1:2 burst) for 7 minutes.
	•	No limits are enforced during peak hours (19:00–23:00).
	2.	Daily Excessive Usage:
	•	If more than 70 out of 1440 data points exceed 500 Mbps:
	•	Bandwidth is limited to 498 Mbps for the remainder of the day, ignoring peak-hour exceptions.

License

This project is licensed under the MIT License. See the LICENSE file for details.

MIT License

MIT License

Copyright (c) 2024 tenotek

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

This version of the README emphasizes the 95th percentile limiting mechanism and details the 1:2 burst configuration. Let me know if you want further refinements!
