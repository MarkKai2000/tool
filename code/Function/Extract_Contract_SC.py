import re
import os

def remove_comments(code):
    # 删除单行注释
    single_line_comment_pattern = re.compile(r'//.*')
    code = re.sub(single_line_comment_pattern, '', code)
    
    # 删除多行注释
    multi_line_comment_pattern = re.compile(r'/\*.*?\*/', re.DOTALL)
    code = re.sub(multi_line_comment_pattern, '', code)
    
    return code

def find_matching_brace(text, start):
    stack = []
    for i, char in enumerate(text[start:], start):
        if char == '{':
            stack.append(char)
        elif char == '}':
            if stack:
                stack.pop()
            if not stack:
                return i
    return -1

def extract_contracts(file_path = '/home/kaima/LLM/Description/MotivateExample/0x14e0a1f310e2b7e321c91f58847e98b8c802f6ef/contracts/HypeBears.sol', obj_name = 'HypeBears'):
    with open(file_path, 'r', encoding='utf-8') as file:
        code = file.read()
    code = remove_comments(code)
    
    # pattern = r'(?<!\S)contract\s+(\w+)(?:\s+is\s+(?:[\w\s,]+(?:\([^)]*\))?\s*(?:,\s*)?)+)?(?=\s*\{)'
    pattern = r'(?<!\S)contract\s+(\w+)(?:\s+is\s+((?:[\w\s,]+(?:\([^)]*\))?\s*(?:,\s*)?)+))?(?=\s*\{)'
    # contracts = []

    for match in re.finditer(pattern, code):
        contract_name = match.group(1)
        start = match.start()
        open_brace = code.find('{', start)
        if open_brace != -1:
            close_brace = find_matching_brace(code, open_brace)
            if close_brace != -1:
                contract_code = code[start:close_brace+1]
                if contract_name == obj_name:
                    return contract_code
                # contracts.append((contract_name, contract_code))
    return None

def extract_contracts_father(file_path = '/home/kaima/LLM/Description/MotivateExample/0x14e0a1f310e2b7e321c91f58847e98b8c802f6ef/contracts/HypeBears.sol', obj_name = 'HypeBears'):
    with open(file_path, 'r', encoding='utf-8') as file:
        code = file.read()
    code = remove_comments(code)
    
    # pattern = r'(?<!\S)contract\s+(\w+)(?:\s+is\s+(?:[\w\s,]+(?:\([^)]*\))?\s*(?:,\s*)?)+)?(?=\s*\{)'
    pattern = r'(?<!\S)contract\s+(\w+)(?:\s+is\s+((?:[\w\s,]+(?:\([^)]*\))?\s*(?:,\s*)?)+))?(?=\s*\{)'
    # contracts = []

    for match in re.finditer(pattern, code):
        contract_name = match.group(1)
        father = None
        if match.group(2) is not None:
            print(match.group(2))
            father = list(map(str.strip, match.group(2).split(",")))
        start = match.start()
        open_brace = code.find('{', start)
        if open_brace != -1:
            close_brace = find_matching_brace(code, open_brace)
            if close_brace != -1:
                contract_code = code[start:close_brace+1]
                if contract_name == obj_name:
                    return (contract_code,father)
                # contracts.append((contract_name, contract_code))
    return None

def extract_interfaces(file_path = '/home/kaima/LLM/Description/MotivateExample/0x14e0a1f310e2b7e321c91f58847e98b8c802f6ef/contracts/HypeBears.sol', obj_name = 'HypeBears'):
    with open(file_path, 'r', encoding='utf-8') as file:
        code = file.read()
        
    code = remove_comments(code)
    pattern = r'(?<!\S)interface\s+(\w+)(?:\s+is\s+(?:[\w\s,]+(?:\([^)]*\))?\s*(?:,\s*)?)+)?(?=\s*\{)'
    # contracts = []

    for match in re.finditer(pattern, code):
        contract_name = match.group(1)
        start = match.start()
        open_brace = code.find('{', start)
        if open_brace != -1:
            close_brace = find_matching_brace(code, open_brace)
            if close_brace != -1:
                contract_code = code[start:close_brace+1]
                if contract_name == obj_name:
                    return contract_code
                # contracts.append((contract_name, contract_code))
    return None


def find_contract(directory, obj_name):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".sol"):            
                file_path = os.path.join(root, file)
                return extract_contracts(file_path, obj_name)
          

def find_contract_fater(directory, obj_name):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".sol"):            
                file_path = os.path.join(root, file)
                return extract_contracts_father(file_path, obj_name)      


def find_interfece(directory, obj_name):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".sol"):
                file_path = os.path.join(root, file)
                return extract_interfaces(file_path, obj_name)


if __name__ == '__main__':
    # Code = find_contract('/home/kaima/LLM/Description/MotivateExample/0x14e0a1f310e2b7e321c91f58847e98b8c802f6ef/','HypeBears')
    # print(Code)
    print(extract_contracts_father("/home/kaima/LLM/0x0E10d55CA39e71632A87A7EeAEBCBC19dD22aeBD/contracts/solidity/token/TimelockRewardDistributionTokenImpl.sol","transfer")[1])