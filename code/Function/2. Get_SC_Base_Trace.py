import json
import csv
import requests
import os
import re
from web3 import Web3
from tqdm import tqdm
from SourceCode_Crawler import crawl_contract

Address_Source = {}
# 1 - open source
# 0 - not open source

 

def process_json(data):
    from_address = Web3.to_checksum_address(data.get("from"))
    to_address = Web3.to_checksum_address(data.get("to"))
    result = {
        "from": from_address,
        "to": to_address,
        "value": data.get("value"),
        "type": data.get("type"),
        "input": data.get("input")
    }
    if from_address not in Address_Source:    
        Address_Source[from_address] = crawl_contract(from_address)
        
    if to_address not in Address_Source:
        Address_Source[to_address] = crawl_contract(to_address)

    # 判断是否存在 "calls" 字段
    if "calls" in data:
        result["calls"] = []
        for call in data["calls"]:
            call_data = process_json(call)
            result["calls"].append(call_data)

    return result



def main(Transaction = "0x05d65e0adddc5d9ccfe6cd65be4a7899ebcb6e5ec7a39787971bcc3d6ba73996"):
    
    # 读取 JSON 文件
    with open(f'/home/kaima/LLM/Description/Transaction_Static_Analysis/Trace/{Transaction}.json', 'r') as file:
        data = json.load(file)

    # 处理 JSON 数据
    result = process_json(data)
    
    
    with open(f'/home/kaima/LLM/Description/Transaction_Static_Analysis/MetaData/{Transaction}.csv', 'w') as csv_file:
        csv_writer = csv.writer(csv_file)
        csv_writer.writerow(["Address", "Open_Source"])
        for item in Address_Source:
            csv_writer.writerow([item, Address_Source[item]])
    
    # 存储简化后的Trace 
    with open(f'/home/kaima/LLM/Description/Transaction_Static_Analysis/Trace_plus/{Transaction}.json', 'w') as file:
        json.dump(result, file, indent=4)

if __name__ == '__main__':
    main("0xb4dd46d5d85a1b04fa4af30efaa57fab98ea03ae19de46aaf215706fd120af44")


