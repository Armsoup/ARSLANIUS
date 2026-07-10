// arslanius.h - ARSLANIUS Driver SDK
#ifndef ARSLANIUS_SDK_H
#define ARSLANIUS_SDK_H

// BarOSSTATUS codes
#define BAROS_SUCCESS 0
#define BAROS_ERROR 1
#define BAROS_CRITICAL 2

#include <string>
#include <functional>

using CommandHandler = std::function<void(const std::string& args)>;

struct ARSLANIUS_API {
    void (*register_command)(const char* name, CommandHandler handler);
    void (*print)(const char* text);
    void (*print_slow)(const char* text);
    const char* (*read_registry)(const char* key);
    void (*write_registry)(const char* key, const char* value);
    void (*write_log)(const char* message);
    bool (*file_exists)(const char* path);
    const char* (*read_file)(const char* path);
    void (*write_file)(const char* path, const char* content);
    const char* (*get_current_user)();
    void (*clear_screen)();
    void (*set_color)(const char* color);
    void (*pause)();
    void (*delete_registry)(const char* key);
    bool (*dir_exists)(const char* path);
    void (*append_file)(const char* path, const char* content);
    bool (*delete_file)(const char* path);
    bool (*create_directory)(const char* path);
    void (*unregister_command)(const char* name);
    void (*execute_command)(const char* cmd);
    const char* (*get_os_name)();
    const char* (*get_build)();
    int (*get_safe_mode)();
    int (*shell_execute)(const char* command);
    const char* (*get_root_path)();
    const char* (*get_config_path)();
    const char* (*get_users_path)();
    const char* (*get_drivers_path)();
    const char* (*get_driver_home)(const char* driver_name);
    const char* (*calculate_hash)(const char* input);
    bool (*user_exists)(const char* username);
};

typedef int (*DriverInitFunc)(ARSLANIUS_API* api);

#endif