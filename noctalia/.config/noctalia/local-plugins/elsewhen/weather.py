#!/usr/bin/env python3
"""Current weather plus today's sunrise and sunset for each tracked city.

argv[1] is a JSON list of {"label", "id"}. Coordinates come from cities.json
when the city is a known one, else from Open-Meteo's geocoder (matched on the
city's own zone). Prints one JSON object keyed "label|id":
{"temp": C, "code": WMO, "sunrise": unix s, "sunset": unix s}. Keyless
Open-Meteo, the same service Omarchy's Elsewhen uses. Failures drop the city.
"""

import json
import os
import sys
import urllib.parse
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))


def fetch(url):
    with urllib.request.urlopen(url, timeout=10) as r:
        return json.load(r)


def known_coordinates():
    try:
        with open(os.path.join(HERE, "cities.json")) as f:
            return {(c[0], c[1]): (c[2], c[3]) for c in json.load(f)}
    except (OSError, ValueError, IndexError):
        return {}


def geocode(label, zone):
    q = urllib.parse.urlencode({"name": label, "count": 10, "language": "en", "format": "json"})
    results = fetch(f"https://geocoding-api.open-meteo.com/v1/search?{q}").get("results") or []
    best = next((r for r in results if r.get("timezone") == zone), results[0] if results else None)
    return (best["latitude"], best["longitude"]) if best else None


def main():
    cities = json.loads(sys.argv[1])
    known = known_coordinates()
    placed = []
    for c in cities:
        coords = known.get((c["label"], c["id"]))
        if coords is None:
            try:
                coords = geocode(c["label"], c["id"])
            except Exception:
                coords = None
        if coords:
            placed.append((f'{c["label"]}|{c["id"]}', coords))
    out = {}
    if placed:
        q = urllib.parse.urlencode({
            "latitude": ",".join(str(p[1][0]) for p in placed),
            "longitude": ",".join(str(p[1][1]) for p in placed),
            "current": "temperature_2m,weather_code",
            "daily": "sunrise,sunset",
            "timezone": "auto",
            "timeformat": "unixtime",
            "forecast_days": 1,
        })
        data = fetch(f"https://api.open-meteo.com/v1/forecast?{q}")
        if isinstance(data, dict):
            data = [data]
        for (key, _), d in zip(placed, data):
            cur, daily = d.get("current") or {}, d.get("daily") or {}
            entry = {}
            if cur.get("temperature_2m") is not None and cur.get("weather_code") is not None:
                entry["temp"] = cur["temperature_2m"]
                entry["code"] = cur["weather_code"]
            if (daily.get("sunrise") or [None])[0] and (daily.get("sunset") or [None])[0]:
                entry["sunrise"] = daily["sunrise"][0]
                entry["sunset"] = daily["sunset"][0]
            out[key] = entry
    print(json.dumps(out))


if __name__ == "__main__":
    main()
