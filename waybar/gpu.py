#!/usr/bin/env python3
# amd gpu stats for waybar
import json
from pathlib import Path

gpu = Path("/sys/class/drm/card1/device")
hwmon = next(gpu.glob("hwmon/hwmon*"))

def read(path):
    return int(path.read_text().strip())

usage = read(gpu / "gpu_busy_percent")
vram_used = read(gpu / "mem_info_vram_used")
vram_total = read(gpu / "mem_info_vram_total")
vram_percent = 100 * vram_used / vram_total

temp = read(hwmon / "temp1_input") / 1000
junction = read(hwmon / "temp2_input") / 1000
power = read(hwmon / "power1_average") / 1e6
fan = read(hwmon / "fan1_input")
clock = read(hwmon / "freq1_input") / 1e6
mem_clock = read(hwmon / "freq2_input") / 1e6

gib = 1024**3

tooltip = (
    f"<b>GPU: {usage}%</b>\n"
    f"Clock: {clock:.0f} MHz\n"
    f"Temperature: {temp:.0f}°C\n"
    f"Junction: {junction:.0f}°C\n"
    f"Power: {power:.1f} W\n"
    f"Fan: {fan} RPM\n\n"
    f"<b>VRAM: {vram_percent:.0f}%</b>\n"
    f"Used: {vram_used/gib:.1f}/{vram_total/gib:.1f} GiB\n"
    f"Clock: {mem_clock:.0f} MHz"
)

print(json.dumps({
    "text": f"{usage}%",
    "tooltip": tooltip,
    "percentage": usage,
}))
