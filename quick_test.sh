#!/usr/bin/env bash
echo "=== Quick DingNet Test ==="

echo "1. Status before start:"
curl -s http://localhost:3000/status
echo

echo "2. Configure scenario:"
curl -s -X POST http://localhost:3000/configure_scenario \
  -H 'Content-Type: application/json' \
  -d '{"numMotes":5,"numGateways":2,"seed":42,"areaWidthMeters":1000,"areaHeightMeters":1000,"movementType":"static","defaultPower":12,"defaultSpreadingFactor":9}'
echo

echo "3. Start simulation:"
curl -s -X POST http://localhost:3000/start_run
echo

sleep 2

echo "4. Status during run:"
curl -s http://localhost:3000/status
echo

echo "5. Monitor (first 500 chars):"
curl -s http://localhost:3000/monitor | head -c 500
echo

echo "6. Execute adaptations:"
curl -s -X PUT http://localhost:3000/execute \
  -H 'Content-Type: application/json' \
  -d '{"items":[{"id":0,"adaptations":[{"name":"power","value":14}]}]}'
echo

echo "7. Stop simulation:"
curl -s -X POST http://localhost:3000/stop_run
echo

echo "8. Status after stop:"
curl -s http://localhost:3000/status
echo

echo "=== Test Complete ==="
