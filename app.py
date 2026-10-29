"""Tidewater Tours sample HTTP API."""
import os

from flask import Flask, jsonify

app = Flask(__name__)

TOURS = [
    {"id": 1, "name": "Blue Lagoon Boat Tour", "location": "Portland, Jamaica", "duration_hours": 2},
    {"id": 2, "name": "Coastal Heritage Walk", "location": "St. Mary, Jamaica", "duration_hours": 3},
    {"id": 3, "name": "Sunset Bay Cruise", "location": "Kingston Harbour, Jamaica", "duration_hours": 2},
]


@app.get("/")
def index():
    return jsonify(service="tidewater-tours", message="Welcome to Tidewater Tours", version=os.getenv("APP_VERSION", "local"))


@app.get("/tours")
def list_tours():
    return jsonify(tours=TOURS, count=len(TOURS))


@app.get("/tours/<int:tour_id>")
def get_tour(tour_id):
    tour = next((tour for tour in TOURS if tour["id"] == tour_id), None)
    if tour is None:
        return jsonify(error="Tour not found"), 404
    return jsonify(tour)


@app.get("/health")
def health():
    return jsonify(status="ok", service="tidewater-tours", version=os.getenv("APP_VERSION", "local"))


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=8000, debug=False)
