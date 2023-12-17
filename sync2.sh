#!/bin/bash
ZONES=(cyprus1 cyprus2 cyprus3 paxos1 paxos2 paxos3 hydra1 hydra2 hydra3)
LOGS=(0-0 0-1 0-2 1-0 1-1 1-2 2-0 2-1 2-2)
PORTS=(8610 8542 8674 8512 8544 8576 8614 8646 8678)

echo "MYNODE EXPLOR +      DIFF      "$(date "+%H:%M:%S")
TOTAL_DIFF=0
for (( i=0; i <= 8; i++ )) do
  NODE_BLOCK=$(grep Appended /root/go-quai/nodelogs/zone-${LOGS[i]}.log | tail -1 | awk '{print substr($8,0,6)}') #'
  URL="https://"${ZONES[i]}".colosseum.quaiscan.io/api?module=block&action=eth_block_number"
  API_HEX=$(curl -s "$URL" | jq -r '.result' 2>/dev/null | awk '{print substr($1,3,5)}') #'

  NODE_HEX=$(printf "%x" $NODE_BLOCK)

  DIFF_HEX=$(curl -s -X POST http://127.0.0.1:${PORTS[i]} -H 'Content-Type: application/json' --data '{
  "jsonrpc": "2.0",
  "method": "quai_getBlockByNumber",
  "params": ["0x'${NODE_HEX}'", false],
  "id": 1
  }' | awk -F"," '{print substr($4,17,20)}' | rev | cut -c 2- | rev)
  
  if [[ $DIFF_HEX =~ ^[0-9a-fA-F]+$ ]]; then
    echo $DIFF_HEX > /dev/null
    else
    DIFF_HEX=0
  fi

  API_BLOCK=$(printf "%d" $((16#$API_HEX)))
  DIFF=$(printf "%d" $((16#$DIFF_HEX)))
  TOTAL_DIFF=$((TOTAL_DIFF+DIFF))
  FDIFF=$(printf "%'d" $DIFF)
  echo $NODE_BLOCK $API_BLOCK $(($NODE_BLOCK-$API_BLOCK)) $FDIFF ${ZONES[i]}
done

TOTAL_DIFF=$(printf "%'d" $TOTAL_DIFF)
echo "Total diff: "$TOTAL_DIFF
