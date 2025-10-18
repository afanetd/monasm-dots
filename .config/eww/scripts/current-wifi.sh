#!/bin/bash

# Находим имя беспроводного устройства (например, wlan0)
device=$(iwctl device list | awk '/station/ {print $1}')

# Если устройство не найдено, выходим
if [[ -z "$device" ]]; then
    echo '{"icon": "󰤮", "ssid": "No Device", "strength": 0}'
    exit 0
fi

# Получаем полную информацию о состоянии устройства
station_info=$(iwctl station "$device" show)

# Проверяем, есть ли в выводе слово "connected"
if ! echo "$station_info" | grep -q "connected"; then
    echo '{"icon": "󰤮", "ssid": "Disconnected", "strength": 0}'
    exit 0
fi

# Если подключено, извлекаем SSID и сигнал
ssid=$(echo "$station_info" | grep "Connected network" | awk '{print $3}')
# Извлекаем RSSI (например, -55) и убираем "dBm"
signal_dbm=$(echo "$station_info" | grep "RSSI" | awk '{print $2}')

# Преобразуем RSSI в проценты (упрощенная формула)
# -90dBm = 0%, -30dBm = 100%
signal_percent=$(( (signal_dbm + 90) * 100 / 60 ))

# Ограничиваем значения от 0 до 100
if (( signal_percent < 0 )); then signal_percent=0; fi
if (( signal_percent > 100 )); then signal_percent=100; fi

# Выбираем иконку в зависимости от силы сигнала
if (( signal_percent >= 80 )); then
    icon="󰤨"
elif (( signal_percent >= 60 )); then
    icon="󰤥"
elif (( signal_percent >= 40 )); then
    icon="󰤢"
elif (( signal_percent >= 20 )); then
    icon="󰤟"
else
    icon="󰤯"
fi

# Выводим итоговый JSON
echo "{\"icon\": \"$icon\", \"ssid\": \"$ssid\", \"strength\": $signal_percent}"