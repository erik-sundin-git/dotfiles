import asyncio
from bleak import BleakScanner
from binascii import hexlify
from json import dumps
from sys import argv
from datetime import datetime
from time import sleep, time_ns  # sleep used in continuous logging mode

SCAN_TIMEOUT = 5.0
MIN_RSSI = -70
AIRPODS_MANUFACTURER = 76
AIRPODS_DATA_LENGTH = 54
RECENT_BEACONS_MAX_T_NS = 10_000_000_000  # 10 seconds

recent_beacons = []


def get_best_result(device, adv):
    recent_beacons.append({"time": time_ns(), "device": device, "adv": adv})
    strongest = None
    strongest_adv = None
    i = 0
    while i < len(recent_beacons):
        if time_ns() - recent_beacons[i]["time"] > RECENT_BEACONS_MAX_T_NS:
            recent_beacons.pop(i)
            continue
        if strongest is None or strongest_adv.rssi < recent_beacons[i]["adv"].rssi:
            strongest = recent_beacons[i]["device"]
            strongest_adv = recent_beacons[i]["adv"]
        i += 1
    if strongest is not None and strongest.address == device.address:
        return device, adv
    return strongest, strongest_adv


async def get_device():
    result = None

    def callback(device, adv):
        nonlocal result
        if AIRPODS_MANUFACTURER not in adv.manufacturer_data:
            return
        data_hex = hexlify(bytearray(adv.manufacturer_data[AIRPODS_MANUFACTURER]))
        if len(data_hex) != AIRPODS_DATA_LENGTH:
            return
        dev, advertisement = get_best_result(device, adv)
        if advertisement.rssi >= MIN_RSSI:
            result = data_hex

    async with BleakScanner(callback) as scanner:
        await asyncio.sleep(SCAN_TIMEOUT)

    return result


def get_data_hex():
    return asyncio.run(get_device())


def is_flipped(raw):
    return (int(chr(raw[10]), 16) & 0x02) == 0


def get_data():
    raw = get_data_hex()

    if not raw:
        return dict(status=0, model="AirPods not found")

    flip = is_flipped(raw)

    model_nibble = chr(raw[7])
    model_byte = chr(raw[6]) + chr(raw[7])
    if model_byte == '24':
        model = "AirPodsPro2"
    elif model_nibble == 'e':
        model = "AirPodsPro"
    elif model_nibble == '3':
        model = "AirPods3"
    elif model_nibble == 'f':
        model = "AirPods2"
    elif model_nibble == '2':
        model = "AirPods1"
    elif model_nibble == 'a':
        model = "AirPodsMax"
    else:
        model = "unknown"

    def parse_status(nibble):
        v = int(chr(nibble), 16)
        return 100 if v == 10 else (v * 10 + 5 if v <= 10 else -1)

    left_status = parse_status(raw[12 if flip else 13])
    right_status = parse_status(raw[13 if flip else 12])
    case_status = parse_status(raw[15])

    charging_status = int(chr(raw[14]), 16)
    charging_left = (charging_status & (0b00000010 if flip else 0b00000001)) != 0
    charging_right = (charging_status & (0b00000001 if flip else 0b00000010)) != 0
    charging_case = (charging_status & 0b00000100) != 0

    return dict(
        status=1,
        charge=dict(left=left_status, right=right_status, case=case_status),
        charging_left=charging_left,
        charging_right=charging_right,
        charging_case=charging_case,
        model=model,
        date=datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        raw=raw.decode("utf-8"),
    )


def run():
    # With a file argument, log continuously (append mode); otherwise print once and exit.
    if len(argv) > 1:
        output_file = argv[1]
        while True:
            data = get_data()
            if data["status"] == 1:
                with open(output_file, "a") as f:
                    f.write(dumps(data) + "\n")
            sleep(1)
    else:
        data = get_data()
        if data["status"] == 1:
            print(dumps(data))


if __name__ == '__main__':
    run()
