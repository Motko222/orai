#!/bin/bash

FOLDER=$(echo $(cd -- $(dirname -- "${BASH_SOURCE[0]}") && pwd) | awk -F/ '{print $NF}')
source ~/scripts/$FOLDER/config/env

json=$(curl -s localhost:$PORT/status | jq .result.sync_info)

pid=$(pgrep $BINARY)
ver=$($BINARY version)
network=$($BINARY status | jq -r .NodeInfo.network)
type="validator"
foldersize1=$(du -hs ~/.pryzm | awk '{print $1}')
#foldersize2=$(du -hs ~/pryzm | awk '{print $1}')
latestBlock=$(echo $json | jq -r .latest_block_height)
catchingUp=$(echo $json | jq -r .catching_up)
votingPower=$($BINARY status 2>&1 | jq -r .ValidatorInfo.VotingPower)
wallet=$(echo $PWD | $BINARY keys show $KEY -a)
valoper=$(echo $PWD | $BINARY keys show $KEY -a --bech val)
pubkey=$($BINARY tendermint show-validator --log_format json | jq -r .key)
delegators=$($BINARY query staking delegations-to $valoper -o json | jq '.delegation_responses | length')
jailed=$($BINARY query staking validator $valoper -o json | jq -r .jailed)
if [ -z $jailed ]; then jailed=false; fi
tokens=$($BINARY query staking validator $valoper -o json | jq -r .tokens | awk '{print $1/1000000}')
balance=$($BINARY query bank balances $wallet -o json 2>/dev/null \
      | jq -r '.balances[] | select(.denom=="upryzm")' | jq -r .amount | awk '{print $1/1000000}')
active=$($BINARY query tendermint-validator-set | grep -c $pubkey)
threshold=$($BINARY query tendermint-validator-set -o json | jq -r .validators[].voting_power | tail -1)

if $catchingUp
 then 
  status="warning"
  note="height=$latestBlock"
 else 
  status="ok"
  note="act $active | del $delegators | vp $tokens | thr $threshold | bal $balance"
fi

if $jailed
 then
  status="error"
  note="jailed"
fi 

if [ -z $pid ];
then status="error";
 note="not running";
fi

echo "updated='$(date +'%y-%m-%d %H:%M')'"
echo "version='$ver'"
echo "process='$pid'"
echo "status="$status
echo "note='$note'"
echo "network='$network'"
echo "type="$type
echo "folder1=$foldersize1"
echo "id=$MONIKER" 
echo "key=$KEY"
echo "wallet=$wallet"
echo "valoper=$valoper"
echo "pubkey=$pubkey"
echo "catchingUp=$catchingUp"
echo "jailed=$jailed"
echo "active=$active"
echo "height=$latestBlock"
echo "votingPower=$votingPower"
echo "tokens=$tokens"
echo "threshold=$threshold"
echo "delegators=$delegators"
echo "balance=$balance"
