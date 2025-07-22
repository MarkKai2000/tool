from slither.slither import Slither
import os
import re

def extract_function_body(file_path, function_name):
    with open(file_path, 'r') as file:
        content = file.read()
        
    # 改进后的正则表达式匹配函数名和函数体，包括可见性修饰符
    pattern = rf"(function\s+{function_name}\s*\([^)]*\)\s*(?:public|private|internal|external)?\s*(.*?)\{{((?:[^\{{\}}]|\{{(?:[^\{{\}}]|\{{[^\{{\}}]*\}})*\}})*?)\}})"
    matches = re.findall(pattern, content, re.DOTALL)
    if matches:
        for match in matches:
            print(f"Function found in file: {file_path}")
            # print("Function Signature:", match[0])
            print("Function Body:\n", match[0])
    else:
        print(f"Function {function_name} not found in file: {file_path}")


def find_function_in_contracts(directory, function_name):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".sol"):
                file_path = os.path.join(root, file)
                extract_function_body(file_path, function_name)




# 解析智能合约并提取函数和变量
def analyze_contract(file_path, function_name):
    slither = Slither(file_path)

    function_body = ""
    private_functions = set()
    state_variables = set()

    for contract in slither.contracts:
        for function in contract.functions:
            if function.name == function_name:
                # 获取函数体源代码
                function_body = function.full_src_code

                for node in function.nodes:
                    for ir in node.irs:
                        # 提取私有函数
                        if ir.function and ir.function.visibility == "private":
                            private_functions.add(ir.function.name)
                        # 提取状态变量
                        if ir.state_variables_written:
                            for var in ir.state_variables_written:
                                state_variables.add(var.name)

    return function_body, private_functions, state_variables


# def extract_contract(file_path):
#     with open(file_path, 'r') as file:
#         content = file.read()
        
#     # 改进后的正则表达式匹配函数名和函数体，包括可见性修饰符
#     pattern = rf"(function\s+{function_name}\s*\([^)]*\)\s*(?:public|private|internal|external)?\s*(.*?)\{{((?:[^\{{\}}]|\{{(?:[^\{{\}}]|\{{[^\{{\}}]*\}})*\}})*?)\}})"
#     matches = re.findall(pattern, content, re.DOTALL)
#     if matches:
#         for match in matches:
#             print(f"Function found in file: {file_path}")
#             # print("Function Signature:", match[0])
#             print("Function Body:\n", match[0])
#     else:
#         print(f"Function {function_name} not found in file: {file_path}")

if __name__ == "__main__":
    # contract_directory = "/home/kaima/LLM/Description/Omni/0x612447E8d0BDB922059cE048bb5a7CeF9e017812"  # 合约文件夹路径
    # function_to_find = "setVaultFeatures"  # 要查找的函数名
    
    # find_function_in_contracts(contract_directory, function_to_find)
    
    # find_function_in_contracts("/home/kaima/LLM/Description/MotivateExample/0x14e0a1f310e2b7e321c91f58847e98b8c802f6ef","tokenURI")
    extract_function_body("/home/kaima/LLM/Description/MotivateExample/0xE85A08Cf316F695eBE7c13736C8Cc38a7Cc3e944/0xE85A08Cf316F695eBE7c13736C8Cc38a7Cc3e944.sol","_burn")
    
    # 示例智能合约路径
    # file_path = '/home/kaima/LLM/Description/Omni/0x0E10d55CA39e71632A87A7EeAEBCBC19dD22aeBD/0x0E10d55CA39e71632A87A7EeAEBCBC19dD22aeBD.sol'
    # slither = Slither(file_path)
    # for contract in slither.contracts:
    #     print(f"Contract: {contract.name}")
    #     print(f"State variables: {contract.state_variables}")
    #     print(f"ERC: {contract.ercs}")
    # print(f"Is_ERC721: {contract.is_erc721}")
    # for function in contract.functions:
    #     print(f"Function: {function.name}")
    #     print(f"State variables: {function.local_variables}")
    #     print()

