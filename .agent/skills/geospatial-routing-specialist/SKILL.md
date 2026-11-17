---
name: geospatial-routing-specialist
description: Maintain accuracy in geospatial calculations, DD/DMM/DMS coordinate conversions, OSRM road snapping, Dijkstra route optimization, and offline fallback logic in `osrm_routing_service.dart` and map screens. Use when modifying routing, GPS tracking, ETA calculations, or map widgets.
---

# Geospatial & Routing Specialist

Ensure mathematical precision and offline resilience across SmartRoute's mapping and routing features.

## Routing & Map Standards
1. **Coordinate Format Integrity:** Preserve exact conversion math between Decimal Degrees (DD), Degrees Decimal Minutes (DMM), and Degrees Minutes Seconds (DMS), validating Panama/Penonomé bounding boxes (`lat` ~8.5°, `lng` ~-80.3°) when testing or validating inputs.
2. **OSRM + Offline Fallback:** Any changes to `osrm_routing_service.dart` must preserve the controlled offline fallback (Haversine/straight-line distance and speed-based ETA) when the OSRM server is unreachable.
3. **Dijkstra Dynamic Filtering:** Ensure absent students reported by parents are excluded from the graph nodes *before* running Dijkstra's shortest-path calculation so drivers never get routed to empty stops.
4. **Battery & Map Performance:** Throttle GPS location broadcasts to Supabase Realtime (e.g., distance filter or interval) and avoid rebuilding the entire `FlutterMap` widget tree on every marker coordinate update.