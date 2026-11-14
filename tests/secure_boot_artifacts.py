#!/usr/bin/env python3
"""Check signed ESP32-S3 build artifacts without hardware."""

import re
import subprocess
import sys
import tempfile
from pathlib import Path


def run_signature_check(espsecure: Path, image: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(espsecure), "signature_info_v2", str(image)],
        check=False,
        capture_output=True,
        text=True,
    )


def main() -> int:
    if len(sys.argv) != 3:
        raise SystemExit("usage: secure_boot_artifacts.py ESPSECURE.PY BUILD_DIR")

    espsecure, build_dir = (Path(arg).resolve() for arg in sys.argv[1:])
    sdkconfig = (build_dir / "sdkconfig").read_text()
    required_config = (
        "CONFIG_SECURE_BOOT=y",
        "CONFIG_SECURE_BOOT_V2_ENABLED=y",
        "CONFIG_SECURE_BOOT_BUILD_SIGNED_BINARIES=y",
        "CONFIG_BOOTLOADER_APP_ROLLBACK_ENABLE=y",
        'CONFIG_PARTITION_TABLE_OFFSET=0x10000',
        'CONFIG_PARTITION_TABLE_CUSTOM_FILENAME="partitions-secure.csv"',
    )
    missing = [setting for setting in required_config if setting not in sdkconfig]
    if missing:
        raise SystemExit(f"secure sdkconfig missing required settings: {', '.join(missing)}")

    images = (
        build_dir / "bootloader" / "bootloader.bin",
        build_dir / "pinyol_console.bin",
    )
    digests = []
    for image in images:
        result = run_signature_check(espsecure, image)
        output = result.stdout + result.stderr
        if result.returncode or "Signature block 0 is valid (RSA)." not in output:
            raise SystemExit(f"signature validation failed for {image}:\n{output}")
        digest = re.search(r"Public key digest for block 0:\s*(.+)", output)
        if not digest:
            raise SystemExit(f"signature digest missing for {image}")
        digests.append(digest.group(1).strip())

    if digests[0] != digests[1]:
        raise SystemExit("bootloader and app use different Secure Boot signing keys")

    app = images[1]
    data = bytearray(app.read_bytes())
    if len(data) <= 0x1000:
        raise SystemExit("app image too small for tamper check")
    data[0x1000] ^= 1
    with tempfile.TemporaryDirectory(prefix="pinyol-tampered-") as temp_dir:
        tampered = Path(temp_dir) / app.name
        tampered.write_bytes(data)
        result = run_signature_check(espsecure, tampered)
        output = result.stdout + result.stderr
        if result.returncode == 0 or "Digest in signature block 0 doesn't match the image digest." not in output:
            raise SystemExit(f"tampered app was not rejected for its altered signature digest:\n{output}")

    print("secure boot artifacts valid; bootloader/app key matches; tampered app rejected")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
