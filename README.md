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

	1.	Clone the repository:

git clone https://github.com/<your-github-username>/95th-percentile-bandwidth-limiter.git
cd 95th-percentile-bandwidth-limiter


	2.	Make the script executable:

chmod +x bandwidth_limiter.sh


	3.	Install required dependencies:
	•	Install ifstat:

sudo apt install ifstat


	•	Ensure tc (part of iproute2) is installed:

sudo apt install iproute2

Usage

Configuration

Edit the script to match your environment:
	•	Interface Settings:
	•	INTERFACE: Network interface to monitor (e.g., eno2).
	•	IFB_INTERFACE: Virtual ifb interface for ingress limiting (default: ifb0).
	•	Bandwidth Settings:
	•	LIMIT_BW: Enforced limit in Kbps (default: 498000 for 498 Mbps).
	•	THRESHOLD_BW: Trigger threshold in Kbps (default: 500000 for 500 Mbps).
	•	LIMIT_DURATION: Duration of bandwidth limit in seconds (default: 420 seconds or 7 minutes).
	•	Monitoring and Logging:
	•	DATA_POINTS_FILE: Log file for bandwidth usage (default: /var/log/bandwidth_usage.log).
	•	LIMIT_FLAG_FILE: File to indicate active bandwidth limiting (default: /tmp/bandwidth_limited).

Running the Script

	1.	Start the script:

sudo ./bandwidth_limiter.sh


	2.	Logs are saved in the following locations:
	•	Bandwidth Usage Data: /var/log/bandwidth_usage.log
	•	Control Logs: /var/log/bandwidth_control.log
	•	Debug Logs: /var/log/bandwidth_debug.log

Technical Details

	1.	Ingress and Egress Limiting:
	•	Uses tc to enforce limits on egress traffic.
	•	Redirects ingress traffic to an ifb virtual interface for bandwidth control.
	2.	Dynamic Thresholds:
	•	Tracks bandwidth usage per minute and applies limits based on sustained traffic patterns.
	3.	1:2 Burst Support:
	•	Limits traffic at 498 Mbps with a 2x burst allowance to handle short spikes:

tc qdisc replace dev $INTERFACE root tbf rate 498000kbit burst 996000kbit latency 400ms


	4.	Time-based Exceptions:
	•	Ensures limits are not enforced during defined peak hours (19:00–23:00).

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

Copyright (c) 2024 <Your Name>

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

Replace <your-github-username> with your actual GitHub username and <Your Name> with your name. Let me know if you need any additional modifications!
