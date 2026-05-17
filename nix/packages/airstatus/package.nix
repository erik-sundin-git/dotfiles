{
  lib,
  stdenv,
  fetchFromGitHub,
  python3,
  makeWrapper,
}:

let
  pythonEnv = python3.withPackages (ps: [ ps.bleak ]);

  # Patch main.py to use the bleak 0.20+ API:
  # - `discover()` was removed; replaced by BleakScanner.discover(return_adv=True)
  # - RSSI and manufacturer_data now come from AdvertisementData, not BLEDevice
  bleakCompat = builtins.toFile "bleak-compat.py" ''
    with open('main.py') as f:
        src = f.read()

    src = src.replace(
        'from bleak import discover',
        'from bleak import BleakScanner',
    )

    old_fn = (
        "async def get_device():\n"
        "    # Scanning for devices\n"
        "    devices = await discover()\n"
        "    for d in devices:\n"
        "        # Checking for AirPods\n"
        "        d = get_best_result(d)\n"
        "        if d.rssi >= MIN_RSSI and AIRPODS_MANUFACTURER in d.metadata['manufacturer_data']:\n"
        "            data_hex = hexlify(bytearray(d.metadata['manufacturer_data'][AIRPODS_MANUFACTURER]))\n"
        "            data_length = len(hexlify(bytearray(d.metadata['manufacturer_data'][AIRPODS_MANUFACTURER])))\n"
        "            if data_length == AIRPODS_DATA_LENGTH:\n"
        "                return data_hex\n"
        "    return False"
    )

    new_fn = (
        "async def get_device():\n"
        "    # Scanning for devices\n"
        "    devices = await BleakScanner.discover(return_adv=True)\n"
        "    for address, (device, adv) in devices.items():\n"
        "        # Checking for AirPods\n"
        "        class _D:\n"
        "            pass\n"
        "        d = _D()\n"
        "        d.address = device.address\n"
        "        d.rssi = adv.rssi\n"
        "        d.metadata = {'manufacturer_data': adv.manufacturer_data}\n"
        "        d = get_best_result(d)\n"
        "        if d.rssi >= MIN_RSSI and AIRPODS_MANUFACTURER in d.metadata['manufacturer_data']:\n"
        "            data_hex = hexlify(bytearray(d.metadata['manufacturer_data'][AIRPODS_MANUFACTURER]))\n"
        "            data_length = len(data_hex)\n"
        "            if data_length == AIRPODS_DATA_LENGTH:\n"
        "                return data_hex\n"
        "    return False"
    )

    assert old_fn in src, 'patch target not found in main.py'
    src = src.replace(old_fn, new_fn)

    with open('main.py', 'w') as f:
        f.write(src)
  '';
in
stdenv.mkDerivation {
  pname = "airstatus";
  version = "unstable-2022-01-15";

  src = fetchFromGitHub {
    owner = "delphiki";
    repo = "AirStatus";
    rev = "47e86aee790dea4bc2463559f8093687434fdbd5";
    hash = "sha256-hIyUPYMTB2tF5OATwFU8MS+jQ5HD95ffa9MSKJ33r+Y=";
  };

  nativeBuildInputs = [ makeWrapper python3 ];

  postPatch = "${python3}/bin/python3 ${bleakCompat}";

  installPhase = ''
    runHook preInstall
    install -Dm755 main.py $out/lib/airstatus/main.py
    makeWrapper ${pythonEnv}/bin/python3 $out/bin/airstatus \
      --add-flags "$out/lib/airstatus/main.py"
    runHook postInstall
  '';

  meta = {
    description = "AirPods battery level monitor for Linux";
    homepage = "https://github.com/delphiki/AirStatus";
    license = lib.licenses.gpl3Only;
    mainProgram = "airstatus";
  };
}
