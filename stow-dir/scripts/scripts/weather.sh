#!/bin/bash

current_date=$(date -u +"%Y-%m-%d")

weather_data=$(curl -s "https://api.weather.gov/gridpoints/OKX/36,34/forecast")

current_time=$(date -u +"%Y-%m-%dT%H:%M:%S%z")
current_minute=$(date -u +"%M")

if [ "$current_minute" -le 30 ]; then
  correct_hour=$(date -u +"%Y-%m-%dT%H:00:00+00:00")
else
  correct_hour=$(date -u -r $(( $(date -u +%s) + 3600 )) +"%Y-%m-%dT%H:00:00+00:00")
fi

temperature=$(echo "$weather_data" | jq -r --arg correct_hour "$correct_hour" '
    .weather[] | select(.timestamp == $correct_hour) | .temperature')
icon=$(echo "$weather_data" | jq -r --arg correct_hour "$correct_hour" '
    .weather[] | select(.timestamp == $correct_hour) | .icon')
condition=$(echo "$weather_data" | jq -r --arg correct_hour "$correct_hour" '
    .weather[] | select(.timestamp == $correct_hour) | .condition')
wind_speed=$(echo "$weather_data" | jq -r --arg correct_hour "$correct_hour" '
    .weather[] | select(.timestamp == $correct_hour) | .wind_speed')
cloud_cover=$(echo "$weather_data" | jq -r --arg correct_hour "$correct_hour" '
    .weather[] | select(.timestamp == $correct_hour) | .cloud_cover')
visibility=$(echo "$weather_data" | jq -r --arg correct_hour "$correct_hour" '
    .weather[] | select(.timestamp == $correct_hour) | .visibility')

echo "Station Name: St. Egdidien/Kuhschnappel"
echo "Condition: ${condition}"
echo "Icon: ${icon}"
echo "Temperature: ${temperature}°C"
echo "Wind Speed: ${wind_speed}"
echo "Cloud Cover: ${cloud_cover}"
echo "Visibility: ${visibility}"
