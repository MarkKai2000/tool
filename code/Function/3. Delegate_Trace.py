import json
import csv
import requests
import os
import re
from web3 import Web3
from tqdm import tqdm

def delegate_solution(data):
    from_address = data.get("from")
    to_address = data.get("to")
    value = data.get("value")
    type =  data.get("type")    
    input = data.get("input")
    flag = 0
    # if type == "CALL":
    
    if "calls" in data and type != "DELEGATECALL":
        calls = data.get("calls")
        for call in calls:
            # print(call)
            if call.get("type") == "DELEGATECALL":
                delegatecall = call.get("to")
                flag = 1
    if flag:
        flag = 0
        result = {
            "from": from_address,
            "to": to_address,
            "value": value,
            "type": type,
            "delegatecall": delegatecall,
            "input": input
            
        }
    else:
        result = {
            "from": from_address,
            "to": to_address,
            "value": value,
            "type": type,
            "input": input
        }
    # 判断是否存在 "calls" 字段
    if "calls" in data:
        result["calls"] = []
        for call in data["calls"]:
            call_data = delegate_solution(call)
            result["calls"].append(call_data)

    return result
 



def main(Transaction = "0x05d65e0adddc5d9ccfe6cd65be4a7899ebcb6e5ec7a39787971bcc3d6ba73996"):
    
    # 读取 JSON 文件
    with open(f'/home/kaima/LLM/Description/Transaction_Static_Analysis/Trace_plus/{Transaction}.json', 'r') as file:
        data = json.load(file)
        
    result = delegate_solution(data)
    
    with open(f'/home/kaima/LLM/Description/Transaction_Static_Analysis/Trace_delegate/{Transaction}.json', 'w') as file:
        json.dump(result, file, indent=4)
        
        
if __name__ == '__main__':
    # main("0x85dc2a433fd9eaadaf56fd8156c956da23fc17e5ef83955c7e2c4c37efa20bb5")
    main("0xb4dd46d5d85a1b04fa4af30efaa57fab98ea03ae19de46aaf215706fd120af44")