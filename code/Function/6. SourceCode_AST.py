import solcx
import os
import json
import csv
from collections import defaultdict
from tqdm import tqdm
import random
import re
# ************************
def extract_inheritance_nodes(ast)-> dir:
    # 提供特定.sol文件，提取其中的继承关系
    Contract_Base = {}
    if "nodes" in ast:
        nodes = ast["nodes"]
        for node in nodes:
            if node["nodeType"] == "ContractDefinition" and "baseContracts" in node:
                main_name = node["name"]
                Contract_Base[main_name] = []
                for contract in node["baseContracts"]:
                    contract_name = contract["baseName"]["name"]
                    Contract_Base[main_name].append(contract_name)
                    # print(contract_name)
        return Contract_Base
    return None


def extract_ImportDirective_node(ast):
    Contract_absolutePath = []
    # Traverse the AST to find ContractDefinition nodes
    for node in ast.get('nodes', []):
        if node['nodeType'] == 'ImportDirective':
            absolutePath = node['absolutePath']
            Contract_absolutePath.append(absolutePath)
    return Contract_absolutePath


        
def find_inherited_contract_paths_node(ast_data):
    # 获取继承关系
    inheritance_map = extract_inheritance_nodes(ast_data)
    # 获取导入路径
    import_paths = extract_ImportDirective_node(ast_data)
    
    inherited_contract_paths = {}
    
    for contract, inherited_contracts in inheritance_map.items():
        inherited_contract_paths[contract] = []
        for inherited_contract in inherited_contracts:
            for path in import_paths:
                if inherited_contract in path:
                    inherited_contract_paths[contract].append(path)
                    break
    
    return inherited_contract_paths

def find_function_body_in_node(ast, function_name, source_code):
    def find_in_nodes(nodes):
        for node in nodes:
            if node['nodeType'] == 'ContractDefinition':
                # Recursive search in ContractDefinition children
                for sub_node in node['nodes']:
                    if sub_node['nodeType'] == 'FunctionDefinition' and sub_node['name'] == function_name:
                        # Check if 'src' exists at the FunctionDefinition level
                        if 'src' in sub_node:
                            func_start, func_length, _ = map(int, sub_node['src'].split(':'))
                            func_declaration_body = source_code[func_start:func_start + func_length]
                            return func_declaration_body
                        else:
                            # If 'src' is not available, print debug information
                            print(f"'src' not found in FunctionDefinition for function '{function_name}'")
                            # Print the function definition node for debugging
                            print(f"FunctionDefinition node: {json.dumps(sub_node, indent=2)}")
            elif 'nodes' in node:
                result = find_in_nodes(node['nodes'])
                if result:
                    return result
        return None

    if 'nodes' in ast:
        return find_in_nodes(ast['nodes'])
    return None

def find_function_in_contracts_in_nodes(compiled_sol, contract_name, function_name, contract_files, contract_address,max_depth=3):
    def search_in_contract(ast, source_code, current_contract_name, depth):
        if depth <= 0:
            return None

        function_body = find_function_body_in_node(ast, function_name, source_code)
        if function_body:
            return function_body
        
        inherited_contracts = find_inherited_contract_paths_node(ast)
        for item in reversed(inherited_contracts.get(current_contract_name, [])):
            item_name = item.split("/")[-1].replace(".sol", "")
            item_ast = compiled_sol[f'{item}:{item_name}']['ast']
            if contract_address not in item:
                with open(base_path+item, 'r') as source_file:
                    source_code_item = source_file.read()
            else:
                with open(item, 'r') as source_file:
                    source_code_item = source_file.read()
            print(f"搜索继承合约: {item} (深度: {depth})")
            result = search_in_contract(item_ast, source_code_item, item_name, depth - 1)
            if result:
                return result
        return None

    with open(contract_files, 'r') as source_file:
        source_code = source_file.read()
        
    base_path = f"/home/kaima/LLM/Etherscan/SourceCode/{contract_address}/"
    
    contract_files_index = contract_files
    if contract_address not in list(compiled_sol.keys())[0]:
        contract_files_index = remove_prefix_from_string(contract_files,contract_address+'/')
        
    main_ast = compiled_sol[f'{contract_files_index}:{contract_name}']['ast']
    
    return search_in_contract(main_ast, source_code, contract_name, max_depth)



def remove_prefix_from_string(full_string, substring):
    """
    删除指定字符串中某个子串及其之前的所有内容。
    
    参数:
    full_string (str): 完整的字符串。
    substring (str): 要删除的子串及其之前的内容。
    
    返回:
    str: 删除指定内容后的字符串。
    """
    # 查找子串在字符串中的开始位置
    index = full_string.find(substring)
    if index != -1:
        # 返回子串之后的部分
        return full_string[index + len(substring):]
    else:
        # 如果子串不在字符串中，返回原始字符串
        return full_string

# *********************

def extract_inheritance(ast):
    def find_inheritance_in_contract(contract_node):
        inheritance_info = {}
        contract_name = contract_node['attributes']['name']
        inheritance_info[contract_name] = []

        # Look for InheritanceSpecifier nodes within this contract's children
        for child in contract_node.get('children', []):
            if child['name'] == 'InheritanceSpecifier':
                for sub_child in child.get('children', []):
                    if sub_child['name'] == 'UserDefinedTypeName':
                        inherited_contract_name = sub_child['attributes'].get('name', 'UnnamedContract')
                        inheritance_info[contract_name].append(inherited_contract_name)

        return inheritance_info

    inheritance_map = {}

    # Traverse the AST to find ContractDefinition nodes
    for node in ast.get('children', []):
        if node['name'] == 'ContractDefinition':
            inheritance_map.update(find_inheritance_in_contract(node))

    return inheritance_map



def extract_ImportDirective(ast):
    Contract_absolutePath = []
    # Traverse the AST to find ContractDefinition nodes
    for node in ast.get('children', []):
        if node['name'] == 'ImportDirective':
            absolutePath = node['attributes']['absolutePath']
            Contract_absolutePath.append(absolutePath)
    return Contract_absolutePath


        
def find_inherited_contract_paths(ast_data):
    # 获取继承关系
    inheritance_map = extract_inheritance(ast_data)
    # 获取导入路径
    import_paths = extract_ImportDirective(ast_data)
    
    inherited_contract_paths = {}
    
    for contract, inherited_contracts in inheritance_map.items():
        inherited_contract_paths[contract] = []
        for inherited_contract in inherited_contracts:
            for path in import_paths:
                if inherited_contract in path:
                    inherited_contract_paths[contract].append(path)
                    break
    
    return inherited_contract_paths


def Contract_Metadata(contract_address = '0xBA12222222228d8Ba445958a75a0704d566BF2C8'):
    with open(f'/home/kaima/LLM/Etherscan/SmartContract/{contract_address}.json', 'r') as file:
        contract_data = json.load(file)
    if contract_data["result"][0]["ABI"] == "Contract source code not verified":
        return None,None
    contrac_name = contract_data["result"][0]["ContractName"]
    compiler_version = contract_data["result"][0]["CompilerVersion"].split("+")[0]
    return contrac_name,compiler_version



def find_function_body(ast, function_name, source_code):
    def find_in_children(children):
        for child in children:
            if child['name'] == 'ContractDefinition':
                # Recursive search in ContractDefinition children
                for sub_child in child['children']:
                    if sub_child['name'] == 'FunctionDefinition' and sub_child['attributes'].get('name') == function_name:
                        # Check if 'src' exists at the FunctionDefinition level
                        if 'src' in sub_child:
                            func_start, func_length, _ = map(int, sub_child['src'].split(':'))
                            func_declaration_body = source_code[func_start:func_start + func_length]
                            return func_declaration_body
                        else:
                            # If 'src' is not available, print debug information
                            print(f"'src' not found in FunctionDefinition for function '{function_name}'")
                            # Print the function definition node for debugging
                            print(f"FunctionDefinition node: {json.dumps(sub_child, indent=2)}")
            elif 'children' in child:
                result = find_in_children(child['children'])
                if result:
                    return result
        return None

    if 'children' in ast:
        return find_in_children(ast['children'])
    return None

def find_source_file(contract_name, base_path):
    # Search the base directory and its subdirectories for the corresponding .sol file
    for root, dirs, files in os.walk(base_path):
        for file in files:
            if file == f"{contract_name}.sol":
                return os.path.join(root, file)
    return None

def find_function_in_multiple_files(ast_file_paths, function_name):
    base_path = '/home/kaima/LLM/Etherscan/SourceCode/0xBA12222222228d8Ba445958a75a0704d566BF2C8/'  # Update this path as needed
    
    for ast_file_path in ast_file_paths:
        with open(ast_file_path, 'r') as file:
            ast = json.load(file)
            contract_name = os.path.basename(ast_file_path).replace('.ast.json', '')
            
            # Find the corresponding source file
            source_code_path = find_source_file(contract_name, base_path)
            print(source_code_path)
            if not source_code_path:
                print(f"Source code file for {contract_name} not found.")
                continue
            
            with open(source_code_path, 'r') as source_file:
                source_code = source_file.read()
            
            function_body = find_function_body(ast, function_name, source_code)
            if function_body:
                return function_body
    return None


def find_sol_path_only(contract_address = '0xBA12222222228d8Ba445958a75a0704d566BF2C8',main_name = 'Vault'):
    dir_base = f'/home/kaima/LLM/Etherscan/SourceCode/{contract_address}'
    
    for root, dirs, files in os.walk(dir_base):
        for file in files:
            if file.startswith(main_name) and file.endswith('.sol'):
                return os.path.join(root, file)
    
    return None  
    
    
def find_sol_path(contract_address='0xBA12222222228d8Ba445958a75a0704d566BF2C8', main_name='Vault'):
    dir_base = f'/home/kaima/LLM/Etherscan/SourceCode/{contract_address}'
    sol_files = []

    for root, dirs, files in os.walk(dir_base):
        for file in files:
            if file.endswith('.sol'):
                sol_files.append(os.path.join(root, file))
                if file == f"{main_name}.sol":
                    return os.path.join(root, file)
    
    # 如果找不到指定的 main_name 文件，随机返回一个 .sol 文件
    if sol_files:
        return random.choice(sol_files)
        # return get_all_sol_path(contract_address)
    
    return None

def get_all_sol_path(contract_address='0xBA12222222228d8Ba445958a75a0704d566BF2C8'):
    dir_base = f'/home/kaima/LLM/Etherscan/SourceCode/{contract_address}'
    sol_files = []

    for root, dirs, files in os.walk(dir_base):
        for file in files:
            if file.endswith('.sol'):
                sol_files.append(os.path.join(root, file))
    
    return sol_files


    

def find_function_in_contracts(compiled_sol, contract_name, function_name, contract_files, max_depth=3):
    def search_in_contract(ast, source_code, current_contract_name, depth):
        if depth <= 0:
            return None

        function_body = find_function_body(ast, function_name, source_code)
        if function_body:
            return function_body
        
        inherited_contracts = find_inherited_contract_paths(ast)
        for item in reversed(inherited_contracts.get(current_contract_name, [])):
            item_name = item.split("/")[-1].replace(".sol", "")
            item_ast = compiled_sol[f'{item}:{item_name}']['ast']
            with open(item, 'r') as source_file:
                source_code_item = source_file.read()
            print(f"搜索继承合约: {item} (深度: {depth})")
            result = search_in_contract(item_ast, source_code_item, item_name, depth - 1)
            if result:
                return result
        return None

    with open(contract_files, 'r') as source_file:
        source_code = source_file.read()
    # with open(f'./build/{contract_name}.ast.json', 'r') as f:
    #     main_ast = json.load(f)

    print(contract_files,contract_name)
    main_ast = compiled_sol[f'{contract_files}:{contract_name}']['ast']
    return search_in_contract(main_ast, source_code, contract_name, max_depth)


def find_function_in_contracts_relative_path(compiled_sol, contract_name, function_name, contract_files, contract_address,max_depth=2):
    def search_in_contract(ast, source_code, current_contract_name, depth):
        if depth <= 0:
            return None

        function_body = find_function_body(ast, function_name, source_code)
        if function_body:
            return function_body
        
        inherited_contracts = find_inherited_contract_paths(ast)
        for item in reversed(inherited_contracts.get(current_contract_name, [])):
            item_name = item.split("/")[-1].replace(".sol", "")
            item_ast = compiled_sol[f'{item}:{item_name}']['ast']
            with open(item, 'r') as source_file:
                source_code_item = source_file.read()
            print(f"搜索继承合约: {item} (深度: {depth})")
            result = search_in_contract(item_ast, source_code_item, item_name, depth - 1)
            if result:
                return result
        return None

    with open(contract_files, 'r') as source_file:
        source_code = source_file.read()


    contract_files = contract_files.replace(f"/home/kaima/LLM/Etherscan/SourceCode/{contract_address}/","")
    print(contract_files,contract_name)
    # print("_____",compiled_sol)
    main_ast = compiled_sol[f'{contract_files}:{contract_name}']['ast']
   
        
    return search_in_contract(main_ast, source_code, contract_name, max_depth)



def Compiler_find_body(main_name = 'Vault', version='0.7.1', contract_address='0xBA12222222228d8Ba445958a75a0704d566BF2C8',function_name = 'flashLoan'):
    solcx.install_solc(version)
    solcx.set_solc_version(version)
    
    base_path = f'/home/kaima/LLM/Etherscan/SourceCode/{contract_address}'
    contract_files = find_sol_path(contract_address,main_name)

    try:
        compiled_sol = solcx.compile_files(
            contract_files,
            output_values=['ast'],  # Only requesting AST
            optimize=True,
            allow_paths=base_path,
            # output_dir='./build'
        )
        
        function_body = find_function_in_contracts(compiled_sol, main_name, function_name, contract_files)
        # print(function_body)
        return function_body
    except Exception as e:
        return None
    
def Compiler_ast(main_name = 'Vault', version='0.7.1', contract_address='0xBA12222222228d8Ba445958a75a0704d566BF2C8'):
    
    
    solcx.install_solc(version)
    solcx.set_solc_version(version)
    
    
    base_path = f'/home/kaima/LLM/Etherscan/SourceCode/{contract_address}'
    contract_files = find_sol_path(contract_address,main_name)
    
    print(contract_files)
    
    store_path = f'/home/kaima/LLM/Description/Transaction_Static_Analysis/CompiledSol/{contract_address}_compiled_sol.json'
    if os.path.exists(store_path):
        with open(store_path, 'r', encoding='utf-8') as infile:
            compiled_sol = json.load(infile)
        return compiled_sol
    
    
    try:
        compiled_sol = solcx.compile_files(
            contract_files,
            output_values=['ast'],  # Only requesting AST
            optimize=True,
            base_path = base_path,
            allow_paths=base_path,
        )
        with open(store_path, 'w', encoding='utf-8') as outfile:
            json.dump(compiled_sol, outfile, indent=4, ensure_ascii=False)
        return compiled_sol
    except Exception as e:
        print(e)
        return None
  
  
    # return ast
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


def check_single_sol_file(contract_address):
    directory_path = f"/home/kaima/LLM/Etherscan/SourceCode/{contract_address}"
    target_file = f"{contract_address}.sol"

    if os.path.exists(directory_path):
        files = os.listdir(directory_path)
        # 过滤出以 .sol 结尾的文件
        sol_files = [file for file in files if file.endswith('.sol')]
        
        # 检查是否只有一个文件
        if len(sol_files) == 1 and sol_files[0] == target_file:
            return True
    return False

def extract_function_body(contract_code, function_name):
    content = contract_code
    # 改进后的正则表达式匹配函数名和函数体，包括可见性修饰符
    pattern = rf"(function\s+{function_name}\s*\([^)]*\)\s*(?:public|private|internal|external)?\s*(.*?)\{{((?:[^\{{\}}]|\{{(?:[^\{{\}}]|\{{[^\{{\}}]*\}})*\}})*?)\}})"
    matches = re.findall(pattern, content, re.DOTALL)
    if matches:
        longest_function_body = ""
        for match in matches:
            function_body = match[0]  # 获取函数体
            if len(function_body) > len(longest_function_body):
                longest_function_body = function_body  # 更新最长的函数体
        return longest_function_body
    else:
        # print(f"Function {function_name} not found in file")
        return None

def process_single_sol_file(contract_address,fucntions):
    contract_path = f"/home/kaima/LLM/Etherscan/SourceCode/{contract_address}/{contract_address}.sol"
    with open(contract_path, 'r') as source_file:
        contract_code = source_file.read()
    function_code = {}
    for function in fucntions:
        function_code[function] = extract_function_body(contract_code,function)
    return function_code

def main_test():
    contract_function = read_contract_function_csv("/home/kaima/LLM/Description/Transaction_Static_Analysis/Trace_finally/0x05d65e0adddc5d9ccfe6cd65be4a7899ebcb6e5ec7a39787971bcc3d6ba73996_contract_function.csv")
    results = []  # 用于存储多个 result


    for contract_address,fucntions in tqdm(contract_function.items()):
        contrac_name, compiler_version = Contract_Metadata(contract_address)
        if not contrac_name:
            continue
        
        
        if check_single_sol_file(contract_address):
            result_single = process_single_sol_file(contract_address,fucntions)
            for function_name,function_body in result_single.items():
                result = {
                "contract_name": contrac_name,
                "contract_address":contract_address,
                "function":function_name,
                "function_body": function_body
                }
                results.append(result)
            continue
        
          
        # 编译器的AST在0.8.x之后改版了
        major = compiler_version.replace("v","").split('.')[1]
    
        print(contract_address)
        compiled_sol = Compiler_ast(contrac_name, compiler_version, contract_address)
        contract_files = find_sol_path(contract_address,contrac_name)
        for function_name in fucntions:
            if major == '8':
                function_body = find_function_in_contracts_in_nodes(compiled_sol, contrac_name, function_name, contract_files,contract_address)
            else:
                function_body = find_function_in_contracts(compiled_sol, contrac_name, function_name, contract_files)
            # contract_address = "0x2B6277fc35452190599FcbD2D3FAF6d8c73aC7f6"
            result = {
                "contract_name": contrac_name,
                "contract_address":contract_address,
                "function":function_name,
                "function_body": function_body
            }
            results.append(result)  # 将 result 添加到列表中
            # except Exception as e:
            #     print(e)
            #     continue

    # 将结果写入到 JSON 文件中
    with open('/home/kaima/LLM/Description/Transaction_Static_Analysis/MetaData/0x05d65e0adddc5d9ccfe6cd65be4a7899ebcb6e5ec7a39787971bcc3d6ba73996_SC.json', 'w', encoding='utf-8') as outfile:
        json.dump(results, outfile, indent=4, ensure_ascii=False)
        
def main(transaction_hash="0x05d65e0adddc5d9ccfe6cd65be4a7899ebcb6e5ec7a39787971bcc3d6ba73996"):
    contract_function = read_contract_function_csv(f"/home/kaima/LLM/Description/Transaction_Static_Analysis/Trace_finally/{transaction_hash}_contract_function.csv")
    results = []  # 用于存储多个 result


    for contract_address,fucntions in tqdm(contract_function.items()):
        contrac_name, compiler_version = Contract_Metadata(contract_address)
        if not contrac_name:
            continue
        
        
        if check_single_sol_file(contract_address):
            result_single = process_single_sol_file(contract_address,fucntions)
            for function_name,function_body in result_single.items():
                result = {
                "contract_name": contrac_name,
                "contract_address":contract_address,
                "function":function_name,
                "function_body": function_body
                }
                results.append(result)
            continue
        
          
        # 编译器的AST在0.8.x之后改版了
        major = compiler_version.replace("v","").split('.')[1]
    
        print(contract_address)
        compiled_sol = Compiler_ast(contrac_name, compiler_version, contract_address)
        contract_files = find_sol_path(contract_address,contrac_name)
        for function_name in fucntions:
            if function_name == "eth_transfer":
                function_body = "This is a basic Eth transfer."
            if major == '8':
                function_body = find_function_in_contracts_in_nodes(compiled_sol, contrac_name, function_name, contract_files,contract_address)
            else:
                function_body = find_function_in_contracts(compiled_sol, contrac_name, function_name, contract_files)
            # contract_address = "0x2B6277fc35452190599FcbD2D3FAF6d8c73aC7f6"
            result = {
                "contract_name": contrac_name,
                "contract_address":contract_address,
                "function":function_name,
                "function_body": function_body
            }
            results.append(result)  # 将 result 添加到列表中
            # except Exception as e:
            #     print(e)
            #     continue

    # 将结果写入到 JSON 文件中
    with open(f'/home/kaima/LLM/Description/Transaction_Static_Analysis/MetaData/{transaction_hash}_SC.json', 'w', encoding='utf-8') as outfile:
        json.dump(results, outfile, indent=4, ensure_ascii=False)


if __name__ == "__main__":
    # Compiler_ast()
    # main("0x85dc2a433fd9eaadaf56fd8156c956da23fc17e5ef83955c7e2c4c37efa20bb5")
    main("0xdbef3b393a64608756c284568217355f694a0e5c8edf80eac75ec087d642ce07")
    # contrac_name, compiler_version =  Contract_Metadata("0x0Ef372B6A2F8bb030760261b858b6C50e92d1680")
    # print(contrac_name, compiler_version)
    # major = compiler_version.replace("v","").split('.')[1]
    # print(major)
    # print(find_sol_path('0x50C7a557d408a5f5a7FDBE1091831728Ae7Eba45','Pool'))
    # print(get_all_sol_path())

    # state_variables = find_state_variables(ast)
    # print("状态变量（stateVariable: true）:")
    # print(state_variables)
    

    
    # 测试0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2这个对于public的使用，然后就是函数内部调用的问题
    # 然后就是可以直接用大模型开始跑了，把case准备好
    # 依赖关系数据

