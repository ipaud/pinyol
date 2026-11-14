# Secure firmware and OTA

The console's standard developer build stays unsigned so it can run on unfused boards. Production images must use
ESP32-S3 Secure Boot v2. It signs the second-stage bootloader and app with RSA-PSS and verifies app signatures during
OTA and every boot. The OTA loader writes only to the inactive slot and retains rollback when startup fails.

## Build a signed image

Generate the production RSA-3072 key on a trusted machine with a strong entropy source. Keep it out of Git, CI logs,
and shared build hosts; make an offline backup. A leaked or lost key compromises future updates or permanently blocks
them. The filename below is ignored by Git.

```sh
cd firmware
openssl genrsa -out secure_boot_signing_key.pem 3072
chmod 600 secure_boot_signing_key.pem
. "$IDF_PATH/export.sh"
idf.py -B build-secure \
  -D SDKCONFIG=build-secure/sdkconfig \
  -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.defaults.secure" \
  build
```

The secure overlay enables Secure Boot v2 and image signing. CI builds this profile with a throwaway key only; CI
artifacts are not production OTA images. Distribute `build-secure/pinyol_console.bin` as `firmware.bin` on the card.
The existing OTA path uses ESP-IDF's OTA APIs, which reject invalid signed images under this configuration, and the
bootloader verifies the selected image before it runs.

## Provision a board

Provision over USB before distributing signed OTA images; the current unsigned bootloader cannot be replaced by OTA.
Before flashing, confirm `build-secure/sdkconfig` has `CONFIG_SECURE_BOOT=y`, `CONFIG_SECURE_BOOT_V2_ENABLED=y`,
`CONFIG_SECURE_BOOT_BUILD_SIGNED_BINARIES=y`, `CONFIG_PARTITION_TABLE_OFFSET=0x10000`,
`CONFIG_PARTITION_TABLE_CUSTOM_FILENAME="partitions-secure.csv"` and the intended key path. The secure layout moves
NVS/OTA metadata; OTA app slots and the game partition retain current offsets. Confirm the app and bootloader carry
valid RSA-3072 signature blocks with ESP-IDF's `espsecure.py signature_info_v2` command. Build the secure bootloader,
inspect the exact flash command printed by ESP-IDF, flash that bootloader, partition table, and signed app, then
monitor first boot for successful verification. Use same signing key for every update to that board.

**First boot burns eFuses irreversibly.** Secure Boot prevents unsigned or differently signed bootloaders and apps from
running. ESP-IDF also permanently disables debug/ROM download features selected by its production defaults. A board
that has fused this key cannot return to an unsigned development build. Do not run the provisioning flash sequence
until the key is backed up and the signed image has been tested on a sacrificial board. This repository does not
provision hardware or burn eFuses automatically.

Secure Boot authenticates code; it does not encrypt flash contents. Flash Encryption is a separate provisioning
step that protects against physical flash readout and reduces flash replacement/TOCTOU risks. It remains a separate
deployment decision because its key provisioning is also irreversible.

This profile uses one production key and does not enable anti-rollback. Any older image signed by that key remains
authentic and can be installed again; Secure Boot does not enforce firmware freshness. Losing the key blocks future
signed updates, and key rotation needs a separate migration procedure. CI's temporary key only verifies this profile
builds; CI does not provision devices or produce deployable firmware.

## Sacrificial-board acceptance test

Use a board that can remain permanently locked to this Secure Boot key. First provisioning irreversibly burns eFuses;
the board cannot return to unsigned development firmware. Back up the key offline, record the board's current firmware
and running OTA slot, and keep a serial log for every reboot. Do not test on a user's console or a production board.

Provision it over USB with the secure bootloader, secure partition table, and signed app. Confirm clean startup and
that the console reaches its normal launcher. Keep one known-good signed app in the other OTA slot before testing
rollback.

1. **Valid update:** Put the signed `pinyol_console.bin` on the card as `firmware.bin`. Confirm the updater reports
   success, the file becomes `firmware.bin.instalado`, the console reboots into the other OTA slot, and startup logs
   show the new app is kept after launcher initialization.
2. **Invalid signature:** Make a disposable copy, flip one byte in its image data, and put that copy on the card as
   `firmware.bin`:

   ```sh
   python3 - <<'PY'
   from pathlib import Path

   image = bytearray(Path("build-secure/pinyol_console.bin").read_bytes())
   assert len(image) > 0x1000
   image[0x1000] ^= 1
   Path("build-secure/pinyol_console-tampered.bin").write_bytes(image)
   PY
   ```

   Confirm the updater reports failure, renames it to `firmware.bin.fallido`, does not reboot, and keeps running the
   previous slot. Never alter the production artifact in place.
3. **Rollback:** Build a temporary signed rollback probe with the same key and secure config:

   ```sh
   idf.py -B build-secure-rollback \
     -D SDKCONFIG=build-secure-rollback/sdkconfig \
     -D SDKCONFIG_DEFAULTS="sdkconfig.defaults;sdkconfig.defaults.secure" \
     -DBP_OTA_NEVER_GOOD=ON build
   ```

   Install that probe as an OTA update. Once it reaches the launcher and prints `test build, never kept`, manually
   reset the board while the app is still pending verification. Confirm the bootloader returns to the previously
   known-good slot and the normal launcher starts. Reinstall the normal signed build afterward and confirm it is kept.

Record board revision, ESP-IDF version, public-key digest, image hashes, slot before/after each test, serial logs, and
the result of each case. Stop if key digest, partition offsets, or flash command differ from the reviewed build. Do not
use `erase_flash` as a recovery shortcut; recover only with the reviewed signed bootloader and app for this key.
