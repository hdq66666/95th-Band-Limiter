# 95th Percentile Bandwidth Limiter

A script to dynamically manage network traffic based on **95th percentile bandwidth limiting**. It enforces compliance with provider contracts by monitoring traffic patterns, supporting **1:2 burst configurations**, and applying intelligent bandwidth limits to prevent overuse and ensure smooth operations.


## Key Features 

- **Dynamic Limiting**: Automatically limits bandwidth to **498 Mbps (1:2 burst)** when usage exceeds **500 Mbps** for 3 consecutive minutes.
- **Time-Based Exceptions**: Skips limiting during peak hours (**19:00–23:00**).
- **Daily Reset**: Resets all data points and limits at midnight.
- **Daily Monitoring**: Caps bandwidth for the remainder of the day if usage exceeds **500 Mbps** for more than **70 out of 1440 minutes**.
  

## Deployment Steps

### 1. Save the Script
Save the provided script to your system, for example, as `/root/bandwidth_control.sh`.

Ensure the script has executable permissions:
```bash
chmod +x /root/bandwidth_control.sh
```



### 2. Create a Systemd Service
To run the script automatically and ensure it stays active, create a systemd service file at `/etc/systemd/system/bandwidth_control.service`:

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



### 3. Start the Service
Reload systemd to recognize the new service:
```bash
systemctl daemon-reload
```

Enable the service to start at boot:
```bash
systemctl enable bandwidth_control.service
```

Start the service:
```bash
systemctl start bandwidth_control.service
```



### 4. Verify the Service
To check the service status and ensure it's running:
```bash
systemctl status bandwidth_control.service
```

To stop or restart the service:
```bash
systemctl stop bandwidth_control.service
systemctl restart bandwidth_control.service
```



### 5. Configure Log Rotation for Debug Logs
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



## Logs and Debugging

### Debug Logs
For real-time debugging:
```bash
tail -f /var/log/bandwidth_debug.log
```

### Bandwidth Usage Logs
Check captured bandwidth usage data:
```bash
cat /var/log/bandwidth_usage.log
```

### Bandwidth Control Logs
Review applied limits and actions:
```bash
cat /var/log/bandwidth_control.log
```






## License

This project is licensed under the MIT License. See the LICENSE file for details.



### MIT License

```plaintext
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
```

This README provides both real-world usage scenarios and step-by-step deployment instructions. Let me know if you need further adjustments!
