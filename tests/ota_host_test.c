#define _POSIX_C_SOURCE 200809L
#define _DARWIN_C_SOURCE 1
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#include "esp_app_desc.h"
#include "esp_ota_ops.h"
#include "ota.h"

static const esp_partition_t running = {"ota_0", 9000};
static const esp_partition_t update = {"ota_1", 9000};
static esp_app_desc_t app = {"host-test", "pinyol_console"};
static int begins, writes, ends, aborts, set_boots, restarts, delays, messages;
static size_t begin_size, written_size;
static unsigned char written[10000];
static esp_err_t begin_result, write_result, end_result, boot_result;
static esp_ota_handle_t next_handle;
static int shown_locked, shown_failure, shown_success;

const esp_app_desc_t *esp_app_get_description(void) { return &app; }
const esp_partition_t *esp_ota_get_running_partition(void) { return &running; }
const esp_partition_t *esp_ota_get_next_update_partition(const esp_partition_t *start) {
    (void)start;
    return &update;
}
esp_err_t esp_ota_begin(const esp_partition_t *partition, size_t size, esp_ota_handle_t *handle) {
    if (partition != &update) return ESP_FAIL;
    begins++;
    begin_size = size;
    *handle = next_handle;
    return begin_result;
}
esp_err_t esp_ota_write(esp_ota_handle_t handle, const void *data, size_t size) {
    if (handle != next_handle || written_size + size > sizeof written) return ESP_FAIL;
    writes++;
    if (write_result != ESP_OK) return write_result;
    memcpy(written + written_size, data, size);
    written_size += size;
    return ESP_OK;
}
esp_err_t esp_ota_end(esp_ota_handle_t handle) { if (handle != next_handle) return ESP_FAIL; ends++; return end_result; }
esp_err_t esp_ota_abort(esp_ota_handle_t handle) { if (handle != next_handle) return ESP_FAIL; aborts++; return ESP_OK; }
esp_err_t esp_ota_get_partition_description(const esp_partition_t *partition, esp_app_desc_t *desc) { /* the image written: pinyol's */
    (void)partition; *desc = (esp_app_desc_t){"host-image", "pinyol_console"}; return ESP_OK;
}
esp_err_t esp_ota_set_boot_partition(const esp_partition_t *partition) {
    if (partition != &update) return ESP_FAIL;
    set_boots++;
    return boot_result;
}
esp_err_t esp_ota_get_state_partition(const esp_partition_t *partition, esp_ota_img_states_t *state) {
    (void)partition;
    *state = ESP_OTA_IMG_UNDEFINED;
    return ESP_OK;
}
esp_err_t esp_ota_mark_app_valid_cancel_rollback(void) { return ESP_OK; }
const char *esp_err_to_name(esp_err_t error) { (void)error; return "MOCK_ERROR"; }
void esp_restart(void) { restarts++; }
void vTaskDelay(unsigned int ticks) { if (ticks == 2000) delays++; }
void hal_log(const char *format, ...) { (void)format; }
void launcher_message(uint16_t *frame, const char *text, int percent) {
    (void)frame;
    (void)percent;
    messages++;
    if (!strcmp(text, "La tarjeta está bloqueada")) shown_locked++;
    if (!strcmp(text, "La actualización no vale")) shown_failure++;
    if (!strcmp(text, "Actualizada. Reiniciando...")) shown_success++;
}

static int failures;
#define CHECK(condition) do { if (!(condition)) { \
    fprintf(stderr, "%s:%d: CHECK(%s)\n", __FILE__, __LINE__, #condition); failures++; \
} } while (0)

static void reset_mocks(void) {
    begins = writes = ends = aborts = set_boots = restarts = delays = messages = 0;
    begin_size = written_size = 0;
    begin_result = write_result = end_result = boot_result = ESP_OK;
    next_handle = 7;
    shown_locked = shown_failure = shown_success = 0;
    memset(written, 0, sizeof written);
}

static void erase_files(void) {
    remove("firmware.bin");
    remove("firmware.bin.instalando");
    remove("firmware.bin.instalado");
    remove("firmware.bin.fallido");
}

static void write_firmware(size_t size) {
    FILE *file = fopen("firmware.bin", "wb");
    CHECK(file != NULL);
    if (!file) return;
    for (size_t i = 0; i < size; i++) fputc((int)(i * 31u + 7u), file);
    CHECK(fclose(file) == 0);
}

static int exists(const char *path) { return access(path, F_OK) == 0; }

int main(void) {
    char original[1024], temp[] = "ota-host-XXXXXX";
    CHECK(getcwd(original, sizeof original) != NULL);
    char *dir = mkdtemp(temp);
    CHECK(dir != NULL);
    if (!dir || chdir(dir) != 0) return 1;

    reset_mocks();
    ota_from_card(NULL);
    CHECK(begins == 0 && writes == 0 && ends == 0 && set_boots == 0 && restarts == 0);
    CHECK(!exists("firmware.bin") && !exists("firmware.bin.fallido"));

    write_firmware(0);
    ota_from_card(NULL);
    CHECK(begins == 0 && writes == 0 && ends == 0 && set_boots == 0 && restarts == 0);
    CHECK(!exists("firmware.bin") && exists("firmware.bin.fallido") && shown_failure == 1);
    erase_files();

    reset_mocks();
    write_firmware(update.size + 1);
    ota_from_card(NULL);
    CHECK(begins == 0 && writes == 0 && set_boots == 0 && restarts == 0);
    CHECK(exists("firmware.bin.fallido") && shown_failure == 1);
    erase_files();

    reset_mocks();
    next_handle = 0;
    write_firmware(5000);
    unsigned char expected[5000];
    for (size_t i = 0; i < sizeof expected; i++) expected[i] = (unsigned char)(i * 31u + 7u);
    ota_from_card(NULL);
    CHECK(begins == 1 && begin_size == sizeof expected && writes == 2 && written_size == sizeof expected);
    CHECK(!memcmp(written, expected, sizeof expected));
    CHECK(ends == 1 && aborts == 0 && set_boots == 1 && restarts == 1);
    CHECK(exists("firmware.bin.instalado") && !exists("firmware.bin") && shown_success == 1);
    erase_files();

    reset_mocks();
    write_result = ESP_FAIL;
    write_firmware(5000);
    ota_from_card(NULL);
    CHECK(begins == 1 && writes == 1 && aborts == 1 && ends == 0);
    CHECK(set_boots == 0 && restarts == 0 && exists("firmware.bin.fallido"));
    erase_files();

    reset_mocks();
    end_result = ESP_ERR_OTA_VALIDATE_FAILED;
    write_firmware(8);
    ota_from_card(NULL);
    CHECK(begins == 1 && writes == 1 && ends == 1 && aborts == 0);
    CHECK(set_boots == 0 && restarts == 0 && exists("firmware.bin.fallido"));
    erase_files();

    reset_mocks();
    boot_result = ESP_FAIL;
    write_firmware(8);
    ota_from_card(NULL);
    CHECK(ends == 1 && set_boots == 1 && restarts == 0 && exists("firmware.bin.fallido"));
    erase_files();

    CHECK(chdir(original) == 0);
    CHECK(rmdir(dir) == 0);
    fprintf(stderr, "OTA host: %s\n", failures ? "FAILED" : "all scenarios passed");
    return failures != 0;
}
