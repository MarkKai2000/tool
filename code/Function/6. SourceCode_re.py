import json
import csv
import requests
import os
import re
from web3 import Web3
from tqdm import tqdm
from SourceCode_Crawler import crawl_contract

from Extract_Contract_SC import find_contract,find_contract_fater

from collections import defaultdict

from slither.slither import Slither

def Find_dependency(file,name):
    slither = Slither(file)
    for contract in slither.contracts:
        if contract == name:
            father_contract = set(item.name for item in contract._immediate_inheritance)
    return father_contract


def extract_function_body(contract_code, function_name):
    content = contract_code
        
    # 改进后的正则表达式匹配函数名和函数体，包括可见性修饰符
    pattern = rf"(function\s+{function_name}\s*\([^)]*\)\s*(?:public|private|internal|external)?\s*(.*?)\{{((?:[^\{{\}}]|\{{(?:[^\{{\}}]|\{{[^\{{\}}]*\}})*\}})*?)\}})"
    matches = re.findall(pattern, content, re.DOTALL)
    if matches:
        for match in matches:
            # print("Function Body:\n", match[0])
            return match[0]
    else:
        # print(f"Function {function_name} not found in file")
        return None




# 创建一个值为 MyObject 对象的字典
contractName_function = defaultdict(set)
contract_code = defaultdict(set)
name_contract = {}

# 检测合约是否开源
Address_Source = {}
# 1 - open source
# 0 - not open source
file = "/home/kaima/LLM/Description/Transaction_Static_Analysis/MetaData/0x05d65e0adddc5d9ccfe6cd65be4a7899ebcb6e5ec7a39787971bcc3d6ba73996.csv"
with open(file,"r") as csv_file:
    csv_reader = csv.reader(csv_file)
    next(csv_reader)
    for line in csv_reader:
        Address_Source[line[0]] = line[1]

def Get_Name(contract_address):
    if contract_address == "0x5070F878a39162Ff22fb04F52fd3C50d76758547" or contract_address == "0x2B6277fc35452190599FcbD2D3FAF6d8c73aC7f6":
        return "unknown_function"
    with open(f'/home/kaima/LLM/Etherscan/SmartContract/{contract_address}.json', 'r') as file:
        contract_data = json.load(file)
    contrac_name = contract_data["result"][0]["ContractName"]
    # print(contrac_name)
    # print(decoded_data)
    return contrac_name


def extract_function_name(function_signature):
    match = re.match(r"(?:function\s+)?(\w+)\(", function_signature)
    if match:
        return match.group(1)
    else:
        return None

def function_code(data):
    from_address = data.get("from")
    to_address = data.get("to")
    
    function = data.get("function")

    if function != 'unknown_function' and function != 'eth_transfer':
        if "delegatecall" in data:
            contract_name = Get_Name(data.get("delegatecall"))
        else:
            contract_name = Get_Name(to_address)
        function_name = str(function).split("(")[0].replace("<Function ","").strip()
        # print(function_name)
        
        contractName_function[contract_name].add(function_name)
        name_contract[contract_name] = to_address
    
    if "calls" in data:
        for call in data["calls"]:
            function_code(call)



def main():
    Transaction = "0x05d65e0adddc5d9ccfe6cd65be4a7899ebcb6e5ec7a39787971bcc3d6ba73996"
    # 读取 JSON 文件
    with open(f'/home/kaima/LLM/Description/Transaction_Static_Analysis/Trace_finally/{Transaction}.json', 'r') as file:
        data = json.load(file)

    function_code(data)
    # print(contractName_function)
    print(name_contract)
    # print(name_contract)
    print("---------------------------------------------------")
    for contractName, functions in contractName_function.items():
        contract_address = name_contract[contractName]

        folder_contract = f'/home/kaima/LLM/Etherscan/SourceCode/{contract_address}/'
        print(folder_contract,contractName)
        (Contract_code,fathers) = find_contract_fater(folder_contract,contractName)
        
        print(fathers)
        for function_name in functions:
            print(function_name)
            function_source_Code = extract_function_body(Contract_code,function_name)
            if (not function_source_Code) and fathers:
                for item_name in fathers:
                    father_source_Code = find_contract(folder_contract,item_name)
                    function_source_Code_inherent = extract_function_body(father_source_Code,function_name)
                    if function_source_Code_inherent:
                        function_source_Code = function_source_Code_inherent
                        break
            data = {
                "contract": contractName,
                "functions": function_name,
                "function_code": function_source_Code
            }
            # print(data)
    # # 存储简化后的Trace 
    # with open(f'/home/kaima/LLM/Description/Transaction_Static_Analysis/Trace_finally/{Transaction}_name.json', 'w') as file:
    #     json.dump(result, file, indent=4)
        
if __name__ == '__main__':
    main()