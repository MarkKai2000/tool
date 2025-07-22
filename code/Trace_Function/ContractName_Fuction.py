import json
import csv
from tqdm import tqdm
from SourceCode_Crawler import crawl_contract
from collections import defaultdict

def read_contract_function_csv(file_path):
    contract_function_dict = defaultdict(set)
    
    with open(file_path, 'r') as csvfile:
        csv_reader = csv.reader(csvfile)
        next(csv_reader)  # 跳过表头
        for row in csv_reader:
            contract = row[0]
            function = row[1]
            contract_function_dict[contract].add(function)
    
    return contract_function_dict

def test_read_contract_function_csv():
    file_path = 'Description/Transaction_Static_Analysis/Trace_finally/0x05d65e0adddc5d9ccfe6cd65be4a7899ebcb6e5ec7a39787971bcc3d6ba73996_contract_function.csv'
    contract_function_dict = read_contract_function_csv(file_path)
    
    # 打印结果
    for contract, functions in contract_function_dict.items():
        print(f"Contract: {contract}")
        for function in functions:
            print(f"  Function: {function}")
            
            
# 检测合约是否开源
Address_Source = {}
# 1 - open source
# 0 - not open source

file = "/home/kaima/LLM/Description/Transaction_Static_Analysis/MetaData/0xb4dd46d5d85a1b04fa4af30efaa57fab98ea03ae19de46aaf215706fd120af44.csv"
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

def insert_name(data):
    from_address = data.get("from")
    to_address = data.get("to")
    value = data.get("value")
    type =  data.get("type")
    function = data.get("function")
    if Address_Source[from_address] == "1":
        from_address = Get_Name(from_address)
    if Address_Source[to_address] == "1":
        to_address = Get_Name(to_address)
    
    result = {
        "from": from_address,
        "to": to_address,
        "value": value,
        "type": type,
        "function": function
    }
    # 判断是否存在 "calls" 字段
    if "calls" in data:
        result["calls"] = []
        for call in data["calls"]:
            call_data = insert_name(call)
            result["calls"].append(call_data)

    return result

def Get_Contract_function(data, contract_function_set):
    if 'delegatecall' in data:
        contract = data.get('delegatecall')
    else:
        contract = data.get("to")
    function = data.get("function")
    if function != 'unknown_function':
        contract_function_set.add((contract, function))
    
    # 判断是否存在 "calls" 字段
    if "calls" in data:
        for call in data["calls"]:
            Get_Contract_function(call, contract_function_set)  # 递归调用

def run_Get_Contract_function(Transaction = "0x05d65e0adddc5d9ccfe6cd65be4a7899ebcb6e5ec7a39787971bcc3d6ba73996"):
    
    # 读取 JSON 文件
    with open(f'/home/kaima/LLM/Description/Transaction_Static_Analysis/Trace_finally/{Transaction}.json', 'r') as file:
        data = json.load(file)
        
    contract_function_set = set()
    Get_Contract_function(data, contract_function_set)
    
    # 存储 (contract, function) 到 CSV 文件
    with open(f'/home/kaima/LLM/Description/Transaction_Static_Analysis/Trace_finally/{Transaction}_contract_function.csv', 'w', newline='') as csvfile:
        csv_writer = csv.writer(csvfile)
        csv_writer.writerow(["Contract", "Function"])
        for contract, function in contract_function_set:
            # csv_writer.writerow([contract, function.split('(')[0].replace("<Function ","")])
            if "<Function " in function:
                csv_writer.writerow([contract, function.split(',')[0].split('(')[1].replace("<Function ","")])
            else:
                csv_writer.writerow([contract, function.split('(')[0].replace("<Function ","")])

def main(Transaction = "0x05d65e0adddc5d9ccfe6cd65be4a7899ebcb6e5ec7a39787971bcc3d6ba73996"):
    
    # 读取 JSON 文件
    with open(f'/home/kaima/LLM/Description/Transaction_Static_Analysis/Trace_finally/{Transaction}.json', 'r') as file:
        data = json.load(file)

    result = insert_name(data)
    
    # 存储简化后的Trace 
    with open(f'/home/kaima/LLM/Description/Transaction_Static_Analysis/Trace_finally/{Transaction}_name.json', 'w') as file:
        json.dump(result, file, indent=4)
        
        
        
        
if __name__ == '__main__':
    # run_Get_Contract_function("0x85dc2a433fd9eaadaf56fd8156c956da23fc17e5ef83955c7e2c4c37efa20bb5")
    # run_Get_Contract_function("0xb4dd46d5d85a1b04fa4af30efaa57fab98ea03ae19de46aaf215706fd120af44")
    main("0xb4dd46d5d85a1b04fa4af30efaa57fab98ea03ae19de46aaf215706fd120af44")