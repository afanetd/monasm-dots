#!/bin/bash

# Находим имя беспроводного устройства (например, wlan0)
device=$(iwctl device list | awk '/station/ {print $1}')

# Если устройство не найдено, выводим пустой массив и выходим
if [[ -z "$device" ]]; then
    echo "[]"
    exit 0
fi

# Получаем SSID текущей подключенной сети
connected_ssid=$(iwctl station "$device" show | grep "Connected network" | awk '{print $3}')

# Получаем список всех известных (сохраненных) сетей в ассоциативный массив для быстрой проверки
declare -A KNOWN_NETWORKS
while read -r ssid security hidden; do
    [[ -n "$ssid" ]] && KNOWN_NETWORKS["$ssid"]=1
done < <(iwctl known-networks list | tail -n +5 | awk '{$1=$1;print}') # tail убирает заголовок

# Массив для хранения JSON-объектов каждой сети
declare -a wifi_list

# Получаем список всех видимых в данный момент сетей
# tail убирает заголовок
while read -r ssid security signal; do
    # Пропускаем пустые строки или остатки заголовка
    [[ -z "$ssid" || "$ssid" == "SSID" ]] && continue

    # Проверяем, активна ли эта сеть
    in_use=false
    [[ "$ssid" == "$connected_ssid" ]] && in_use=true

    # Проверяем, сохранена ли эта сеть (аналог autoconnect)
    autoconnect=false
    [[ -v KNOWN_NETWORKS["$ssid"] ]] && autoconnect=true

    # Собираем JSON-объект для текущей сети с помощью jq
    wifi_json=$(jq -nc \
        --arg ssid "$ssid" \
        --argjson in_use "$in_use" \
        --argjson autoconnect "$autoconnect" \
        '{
            ssid: $ssid,
            in_use: $in_use,
            autoconnect: $autoconnect
        }')

    wifi_list+=("$wifi_json")
done < <(iwctl station "$device" get-networks | tail -n +5 | awk '{$1=$1;print}')

# Выводим итоговый JSON-массив
jq -nc --argjson arr "$(printf '[%s]' "$(IFS=,; echo "${wifi_list[*]}")")" '$arr'
