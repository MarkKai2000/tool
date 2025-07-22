import json
import csv
import requests
import os
import re
from web3 import Web3
from tqdm import tqdm
w3 = Web3(Web3.HTTPProvider('http://222.20.126.134:8545'))


# 检测合约是否开源
# 1 - open source
# 0 - not open source
def load_address_source(tran_hash= "0x05d65e0adddc5d9ccfe6cd65be4a7899ebcb6e5ec7a39787971bcc3d6ba73996"):
    file_path = f"/home/kaima/LLM/Description/Transaction_Static_Analysis/MetaData/{tran_hash}.csv"
    address_source = {}
    with open(file_path, "r") as csv_file:
        csv_reader = csv.reader(csv_file)
        next(csv_reader)
        for line in csv_reader:
            address_source[line[0]] = line[1]
    return address_source

# 使用函数加载地址源
Address_Source = load_address_source("0xb4dd46d5d85a1b04fa4af30efaa57fab98ea03ae19de46aaf215706fd120af44")
        
        
# ************************************************************函数签名处理逻辑************************************************
# 获取函数签名映射
input_to_function = {}
f = open('/home/kaima/LLM/Description/sc/4Bytes_gigahorse.csv', 'r')
reader = csv.reader(f)
next(reader)
for row in reader:
    input_to_function[row[0]] = row[1]
f.close()

f = open('/home/kaima/LLM/Description/sc/4bytes.csv', 'r')
reader = csv.reader(f)
next(reader)
for row in reader:
    input_to_function[row[0]] = row[1]
f.close()


def write_to_csv(data, filename='/home/kaima/LLM/Description/sc/4Bytes.csv'):
    # 检查文件是否存在并写入表头（仅在文件首次创建时）
    try:
        with open(filename, mode='r', newline='') as file:
            pass
    except FileNotFoundError:
        with open(filename, mode='w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["4Bytes", "Name"])  # 写入表头
    
    # 追加数据到CSV文件
    with open(filename, mode='a', newline='') as file:
        writer = csv.writer(file)
        for result in data['results']:
            writer.writerow([result['hex_signature'], result['text_signature']])


def get_4byte_signature(hex_signature):
    url = f"https://www.4byte.directory/api/v1/signatures/?hex_signature={hex_signature}"
    response = requests.get(url)
    
    if response.status_code == 200:
        if len(response.json()['results']) > 0:
            for row in response.json()['results']:
                input_to_function[row['hex_signature']] = row['text_signature']
            write_to_csv(response.json())

def get_function_name(function_signature = "0x11fe65fa"):
    # 提取前4个字节
    if function_signature not in input_to_function:
        get_4byte_signature(function_signature)
    # 获取函数名称
    return input_to_function.get(function_signature, "unknown_function")

# ********************************************************************************************************************

# ********************************************************************************************************************
def ABI_Solution(contract_address,input_data):
    if contract_address == "0x5070F878a39162Ff22fb04F52fd3C50d76758547" or contract_address == "0x2B6277fc35452190599FcbD2D3FAF6d8c73aC7f6":
        return "unknown_function"
    try:
        with open(f'/home/kaima/LLM/Etherscan/SmartContract/{contract_address}.json', 'r') as file:
            contract_data = json.load(file)
        contract_abi = contract_data["result"][0]["ABI"]
        contrac_name = contract_data["result"][0]["ContractName"]
        contract = w3.eth.contract(address=contract_address, abi=contract_abi)
        decoded_data = contract.decode_function_input(input_data)
        # print(contrac_name)
        # print(decoded_data)
        return decoded_data
    except Exception as e:
        print(e)
        return "unknown_function"
    
def test_ABI_Solution():
    contract_address = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"
    input_data = "0xa9059cbb0000000000000000000000005992f10a5b284be845947a1ae1694f8560a89fa800000000000000000000000000000000000000000000003635c9adc5dea00000"
    result = ABI_Solution(contract_address,input_data)
    print(result)

    
# ********************************************************************************************************************

def input_solution(data):
    from_address = data.get("from")
    to_address = data.get("to")
    value = data.get("value")
    type =  data.get("type")
    
    input = data.get("input")
    function_selector = input[:10]
    
    function = "error"
    
    # print(function_selector)
    # print(to_address)
    # print(input)
    flag = 0
    
    if input == '0x':
        function = "eth_transfer"
        value = int(value, 16) / 10**18
    else:
        if Address_Source[to_address] == "0":
            function = get_function_name(function_selector)
        elif Address_Source[to_address] == "1":
            if "delegatecall" in data:
                flag = 1
                delegatecall = data.get("delegatecall")
                if Address_Source[delegatecall] == "0":
                    function = get_function_name(function_selector)
                elif Address_Source[delegatecall] == "1":
                    function = str(ABI_Solution(delegatecall,input))
                else:
                    print("error")
            else:
                function = str(ABI_Solution(to_address,input))
        else:
            print(function_selector)
            print(to_address)
            print(input)
    if flag:
        result = {
            "from": from_address,
            "to": to_address,
            "value": value,
            "type": data.get("type"),
            "delegatecall": delegatecall,
            "function": function
        }
        flag = 0
    else:
        result = {
            "from": from_address,
            "to": to_address,
            "value": value,
            "type": data.get("type"),
            "function": function
        }
    # 判断是否存在 "calls" 字段
    if "calls" in data:
        result["calls"] = []
        for call in data["calls"]:
            call_data = input_solution(call)
            result["calls"].append(call_data)

    return result



def main(Transaction = "0x05d65e0adddc5d9ccfe6cd65be4a7899ebcb6e5ec7a39787971bcc3d6ba73996"):
    
    # 读取 JSON 文件
    with open(f'/home/kaima/LLM/Description/Transaction_Static_Analysis/Trace_delegate/{Transaction}.json', 'r') as file:
        data = json.load(file)

    result = input_solution(data)
    
    # 存储简化后的Trace 
    with open(f'/home/kaima/LLM/Description/Transaction_Static_Analysis/Trace_finally/{Transaction}.json', 'w') as file:
        json.dump(result, file, indent=4)
        
    # with open(f'/home/kaima/LLM/Description/Transaction_Static_Analysis/MetaData/{Transaction}.csv', 'w') as csv_file:
    #     csv_writer = csv.writer(csv_file)
    #     csv_writer.writerow(["Address", "Open_Source"])
    #     for item in Address_Source:
    #         csv_writer.writerow([item, Address_Source[item]])
    
  
  

if __name__ == '__main__':
    # main("0x85dc2a433fd9eaadaf56fd8156c956da23fc17e5ef83955c7e2c4c37efa20bb5")
    main("0xb4dd46d5d85a1b04fa4af30efaa57fab98ea03ae19de46aaf215706fd120af44")
    # test_ABI_Solution()

    # print(get_function_name())
    # print("0x"[:10])



