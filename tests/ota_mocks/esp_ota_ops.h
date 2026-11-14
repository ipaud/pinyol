#pragma once
#include <stddef.h>
#include <stdint.h>
#include "esp_app_desc.h"

typedef int esp_err_t;
typedef uint32_t esp_ota_handle_t;
typedef struct { const char *label; size_t size; } esp_partition_t;
typedef enum { ESP_OTA_IMG_UNDEFINED, ESP_OTA_IMG_PENDING_VERIFY } esp_ota_img_states_t;

#define ESP_OK 0
#define ESP_FAIL -1
#define ESP_ERR_NOT_FOUND -2
#define ESP_ERR_INVALID_SIZE -3
#define ESP_ERR_OTA_VALIDATE_FAILED -4
#define ESP_ERR_INVALID_ARG -5

const esp_partition_t *esp_ota_get_running_partition(void);
const esp_partition_t *esp_ota_get_next_update_partition(const esp_partition_t *start);
esp_err_t esp_ota_begin(const esp_partition_t *partition, size_t size, esp_ota_handle_t *handle);
esp_err_t esp_ota_write(esp_ota_handle_t handle, const void *data, size_t size);
esp_err_t esp_ota_end(esp_ota_handle_t handle);
esp_err_t esp_ota_abort(esp_ota_handle_t handle);
esp_err_t esp_ota_get_partition_description(const esp_partition_t *partition, esp_app_desc_t *desc);
esp_err_t esp_ota_set_boot_partition(const esp_partition_t *partition);
esp_err_t esp_ota_get_state_partition(const esp_partition_t *partition, esp_ota_img_states_t *state);
esp_err_t esp_ota_mark_app_valid_cancel_rollback(void);
const char *esp_err_to_name(esp_err_t error);
