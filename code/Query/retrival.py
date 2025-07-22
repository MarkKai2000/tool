import json
from Complexity import ComplexityEvaluator
from Vector_distribute import DynamicKAdjustment
from Vector_distribute import Compute_variance
from concurrent.futures import ThreadPoolExecutor, as_completed  # 添加as_completed导入

import os
import re
from typing import Dict, Any, List
from openai import OpenAI
from tokenizer.count_token import count_token_len
import csv
from tqdm import tqdm
from pymilvus import connections, Collection
import numpy as np
from elasticsearch import Elasticsearch



import threading


  
client_deepseek = OpenAI(
    api_key="sk-khgdwiqxhphealrqnzfwxipryanuaaxmaqewxbqoavoaymna", 
    base_url="https://api.siliconflow.cn/v1"
)
client_elastic = Elasticsearch(
    "http://localhost:9200",
    basic_auth=("elastic", "BaiHwMji")
)






connections.connect("default", host="222.20.126.131", port="19530")


def Contract_Name(contract_address,chain):
    
    """
    Retrieves the contract name for a given contract address and blockchain.
    
    Args:
        contract_address (str): The address of the smart contract.
        chain (str): The blockchain network ('Ethereum' or 'Binance').
    
    Returns:
        str: The contract name if verified, otherwise the first 8 characters of the address.
    
    Raises:
        FileNotFoundError: If the contract file does not exist in the specified folder.
    """
    if chain == 'Ethereum':
        folder = '/home/kaima/LLM/Etherscan/SmartContract'
    elif chain == 'Binance':
        folder = '/home/kaima/LLM/Bscscan/SmartContract'
    
    try:
        with open(f'{folder}/{contract_address}.json', 'r') as file:
            contract_data = json.load(file)
    except FileNotFoundError:
        with open(f'{folder}/{contract_address.lower()}.json', 'r') as file:
            contract_data = json.load(file)
    contract_abi = contract_data["result"][0]["ABI"]
    if contract_abi == "Contract source code not verified":
        return contract_address[0:8]
    return contract_data["result"][0]["ContractName"]


def extract_list_from_text(text):
    # 使用正则表达式提取方括号中的内容
    match = re.search(r'\[(.*?)\]', text)
    if match:
        # 提取到的内容并分割成列表
        extracted_list = match.group(1).split(',')
        # 去除每个元素的空格并返回列表
        return [int(item.strip()) for item in extracted_list]
    return []

def search_general_knowledge(query: str, index_name: str = "general_knowledge", size: int = 3):
    """搜索漏洞数据"""
    search_query = {
        "query": {
            "multi_match": {
                "query": query,
                "fields": [
                    "title",
                    "summary",
                    "description",
                    "impact",
                    "remediation",
                    "key_points"
                ],  # 适用于漏洞数据的相关字段
                "type": "best_fields"
            }
        }
    }

    response = client_elastic.search(
        index=index_name,
        size=size,  # 控制返回结果数量
        **search_query  # 解包查询参数
    )

    results = []
    for hit in response['hits']['hits']:
        results.append({
            "id": hit["_id"],
            "score": hit["_score"],
            "content": hit["_source"]
        })

    return results


def search_vulnerability_data(query: str, index_name: str = "report_data", size: int = 5):
    """搜索漏洞数据，限制在指定日期之前，并检索function中的子字段"""
    search_query = {
        "query": {
            "bool": {
                "must": {
                    "multi_match": {
                        "query": query,  # 确保这是一个字符串
                        "fields": [
                            "function.abstract",  # 添加function前缀
                            "function.vulnerability_type",  # 添加function前缀
                            "function.root_causes",  # 添加function前缀
                            "function.exploit_steps",  # 添加function前缀
                            "function.recommendations"  # 添加function前缀
                        ],
                        "type": "best_fields"
                    }
                }
            }
        }
    }
    
    response = client_elastic.search(
        index=index_name,
        size=size,  # 指定返回的文档数量
        **search_query  # 解包查询字典
    )
    
    results = []
    for hit in response['hits']['hits']:
        results.append({
            "id": hit["_id"],
            "score": hit["_score"],  # Elastic score是根据查询匹配度和相关性计算的
            "content": hit["_source"]
        })
        
    return results


def prompt_complete(code, trace, knowledge_list, general_knowledge, Victim_Contract_Name):
    prompt = f"""
You are an expert blockchain security analyst with extensive experience in smart contract vulnerability analysis and attack investigation. 
Your task is to thoroughly analyze the provided input Information and generate a comprehensive security report that identifies the root cause, attack vectors, and potential mitigations.


For each analysis question and component of the report, simulate the process of formulating responses five times internally.Then, provide the most common and well-supported answer you derive from these simulations.

**1. Input Information:**
    * **Transaction Call Trace**: `[{trace}]`
    * **Victim Code**: `[{code}]` (Victim contract name in trace: `[{Victim_Contract_Name}]`)
    * **Reference Cases**: `[{knowledge_list}]` (Please use these cases to assist your analysis.)

**2. Report Structure (Please use this Markdown template):**
    # Background
    # Relevant Information
        - Attacker Address
        - Vulnerable Contract Address
        - Attack Transactions
    # Cause of Attack
    # Attack Process
        ## Funding Preparation
        ## Vulnerable Function Calls / Key Attack Steps
    # Impact on Contract State  <-- Note: This section is crucial for fulfilling S1/S2 checklist items.
    # Mitigation Measures
    # Conclusion

**3. Core Content Requirements (Ensure the report explicitly addresses the following V, A, S, R checklist items in the relevant sections, following the Core Process for each):**

    **A. Vulnerability Analysis (Vulnerability - corresponds to the 'Cause of Attack' section):**
        * **V1:** Clearly identify which specific function(s) are vulnerable.
        * **V2:** Explain the root cause of the vulnerability (e.g., logic errors, unchecked return values, improper access control, etc.).
        * **V3:** Classify the vulnerability type (e.g., reentrancy, integer overflow/underflow, access control bypass, etc.).
        * **V4:** Pinpoint the specific code logic or snippet that caused the issue.
        * **V5:** (If applicable) Mention if any external contracts or interfaces are associated with this risk.

    **B. Attack Behavior (corresponds to the 'Attack Process' section):**
        * **A1:** Describe the sequence of key function calls executed by the attacker.
        * **A2:** Explain how the attacker crafted critical parameters or input data (e.g., `paraswapData`).
        * **A3:** Trace the complete flow of assets (source of funds, intermediate transfers, final destination).
        * **A4:** Specify whether relevant swap operations were successfully executed, bypassed, or manipulated.
        * **A5:** Estimate the amount and type of assets lost.

    **C. State Impact (corresponds to the 'Impact on Contract State' section):**
        * **S1:** Identify which specific state variables in the contract were not correctly cleaned up or remained in an unintended state after the attack.
        * **S2:** Explain how these uncleaned or unintended states could be further exploited.

    **D. Remediation (corresponds to the 'Mitigation Measures' section):**
        * **R1:** Recommend checking the return values of external calls.
        * **R2:** Recommend resetting or minimizing token allowances.
        * **R3:** Provide general secure development advice (e.g., principle of least privilege, input validation, whitelisting mechanisms, etc.).

**4. Output Requirements:**
    * The generated report must comprehensively detail the background, causes, attack process, impact, and mitigation measures, strictly adhering to the 'Report Structure'.
    * Ensure that the report content is clear, logically structured, and provides valuable insights for the reader.
    * The substance of all 'Key Analytical Points' (V, A, S, R checklist) must be integrated into the report, but the labels themselves (e.g., V1, A2) should NOT appear in the final output.

Please use the provided information, to generate a comprehensive attack report in markdown format.
"""
    return prompt

def prompt_complete_old(code, trace, knowledge_list,genaral_knowledge):
    case_prompt = ''
    for index,case in enumerate(knowledge_list):
        case_prompt = case_prompt + f"Case {index}: {case}\n"
    
    general_knowledge_prompt = ''
    for index,case in enumerate(genaral_knowledge):
        general_knowledge_prompt = general_knowledge_prompt + f"Knowledge {index}: {case}\n"
    
    prompt = f"""
    Please generate a blockchain attack analysis report based on the following information:

    1. **Transaction Call Trace**: {trace}

    2. **Victim Contract Code**: {code}

    3. **Report Template**: 
    - Use the following template to format the generated report:
        ```
        # Background
        # Relevant Information 
            - Attacker Address
            - Vulnerable Contract Address
            - Attack Transactions
        # Cause of Attack
        # Attack Process
            ## Funding Preparation
            ## Vulnerable Function Calls
        # Mitigation Measures
        3 Conclusion
        ```
    - Each section should have enough text explanation to ensure clarity and provide comprehensive insights into the attack and its implications.
    4. **Reference Cases**: 
    - Extract information from the following relevant case knowledge to support the analysis and report generation:
        ```
        {case_prompt}
        ```
     5. **Reference General Knowledge**   
        ```
        {general_knowledge_prompt}
        ```
        
    6. **Evaluation Criteria**:  
    - **Identify the root cause** of the vulnerability (logical/design flaws).  
    - **Classify the attack type** (e.g., reentrancy, access control bypass).  
    - **Provide an accurate function call sequence** and **trace asset flow**.  
    - **Pinpoint the vulnerable code** and describe its **impact on contract state**.

    7. **Output Requirements**: 
    - The generated report should detail the background, causes, processes, and mitigation measures of the attack, adhering to the specified template format.
    - Ensure that the report content is clear, logically structured, and provides valuable insights for the reader.
    - - Each section should have enough text explanation to ensure clarity and provide comprehensive insights into the attack and its implications.

    Please use the provided trace and code, along with the relevant case knowledge, to generate a comprehensive attack report in markdown format.
    """
    return prompt

def search_by_id(index_name: str, doc_id: str):
    """根据指定ID检索文档"""
    try:
        response = client_elastic.get(index=index_name, id=doc_id)
        return {
            "id": response["_id"],
            "content": response["_source"]
        }
    except Exception as e:
        print(f"Error retrieving document with ID {doc_id}: {str(e)}")
        return None

def search_similar_time(collection, vector, top_k=3):
    search_params = {"metric_type": "COSINE", "params": {"nprobe": 10}}


    results = collection.search(
        data=[vector],
        anns_field="vector",
        param=search_params,
        limit=top_k,
        output_fields=["name", "transaction", "time"]
    )

    matches = []
    for hits in results:
        for hit in hits:
            matched_data = {
                "distance": hit.distance,
                "name": hit.entity.get('name'),
                "transaction": hit.entity.get('transaction'),
                "time": hit.entity.get('time')
            }
            matches.append(matched_data)

    return matches



def prompt_re_rank(code, trace, knowledge_list,k):
    prompt = f"Please rank the following knowledge items based on the provided code and trace:\n\nCode:\n{code}\n\nTrace:\n{trace}\n\nKnowledge Items:\n"
    for index, item in enumerate(knowledge_list):
        prompt = prompt + f"Index {index}: {item}\n"
    extral_prompt = f"\nThe last re-rank result outputs the indices of the {k} most relevant knowledge items to the code and trace, with the most relevant first. Only output the indices in a list format, like [1,2,3...], no other information."
    prompt = prompt + extral_prompt
    return prompt



def Re_rank(code, trace, knowledge_list,k):
    # prompt = f"Please rank the following knowledge items based on the provided code and trace:\n\nCode:\n{code}\n\nTrace:\n{trace}\n\nKnowledge Items:\n" + "\n".join(knowledge_list)
    
    prompt = prompt_re_rank(code, trace, knowledge_list,k)


    prompt_len = count_token_len(prompt)
    if prompt_len > 65536:
        trace_len = count_token_len(trace)
        trace = trace[:trace_len - (prompt_len - 65536)]
        prompt = prompt_re_rank(code, trace, knowledge_list,k)  # Correctly replace the placeholder with the actual trace
        # print(name,trace_len,prompt_len,trace_len - (prompt_len - 65536),len(trace),len(prompt))
    print(count_token_len(prompt))
    
    
    try:
        response = client_deepseek.chat.completions.create(
            model="Pro/deepseek-ai/DeepSeek-R1", 
            messages=[
                {"role": "system", "content": "You are an expert smart contract security analyst."},
                {"role": "user", "content": prompt},
        ],
        stream=False
    )
        result = response.choices[0].message.content

        # print(result)
        result_list = extract_list_from_text(result)
        print("Rerank Result: ",result_list)
        # print(result_list)
        return result_list

        
    except Exception as e:
        print(f"Error calling LLM: {str(e)}")


def Text_Retrive(name):
    with open(f'/home/kaima/LLM/AttackRLLM/knowledge_base/Function_knowledge/{name}.json', 'r') as f:
        function_extract = json.load(f)

    function_abstract = function_extract['abstract']

    formatted_details = []
    function_details = function_extract['details']
    # print(function_extract)
    for index, detail in enumerate(function_details, start=1):
        formatted_details.append(f"{index}. {detail}")
    # 将所有拼接成一段完整的文本
    function_details = " ".join(formatted_details)
    # print(function_details)

    general_knowledge_abstract = search_general_knowledge(function_abstract, 'general_knowledge', 3)
    # general_knowledge_details = search_general_knowledge(function_details, 'general_knowledge', 3)
    
    # general_knowledge = general_knowledge_abstract + general_knowledge_details
    # print(general_knowledge)
    

    details_results = search_vulnerability_data(function_abstract, 'report_data', 3)
    abstract_results = search_vulnerability_data(function_details, 'report_data', 3)

    combined_results = abstract_results + details_results

    # 根据得分排序
    combined_results.sort(key=lambda x: x['score'], reverse=True)
    scores = [item['score'] for item in combined_results]
    # print(scores)
    # print(scores)
    # print(Compute_variance(scores))
    return combined_results, Compute_variance(scores),general_knowledge_abstract
    
def Vector_Retrive(name):
    with open(f'/home/kaima/LLM/AttackRLLM/knowledge_base/Code_Trace_Embed_Result/{name}.npy', 'rb') as f:
        code_trace_vector = np.load(f)

    collection = Collection("code_trace")
    similar_vectors = search_similar_time(collection, code_trace_vector, 3)
    distance = [item['distance'] for item in similar_vectors]
    # print(distance)
    # print(Compute_variance(distance))
    names_ids = [item['name'] for item in similar_vectors]


    knowledge_list = []
    for vector_name in names_ids:
        knowledge_list.append(search_by_id('report_data', vector_name))
    
    return knowledge_list, Compute_variance(distance)
        
def Mix_Dynamic_Retrive(name,Transaction,Chain, victim_name):
    file_path = f'/home/kaima/LLM/AttackRLLM/Experiment/LLMReport/OScar/{name}.md'
    if os.path.exists(file_path):
        print(f"Already exists: {file_path}")
        return True
    
    
    if Chain == 'Binance':
        trace_path = '/home/kaima/LLM/AttackRLLM/Transaction/BSC_Round3/' + Transaction + '.txt'
        folder_complxity_trace = '/home/kaima/LLM/AttackRLLM/Transaction/BSC_Round2' 
    if Chain == 'Ethereum':
        trace_path = '/home/kaima/LLM/AttackRLLM/Transaction/ETH_Round3/' + Transaction + '.txt'
        folder_complxity_trace = '/home/kaima/LLM/AttackRLLM/Transaction/ETH_Round2'
        
    with open(trace_path,'r') as f:
        trace = f.read()
        
        
    with open(os.path.join(folder_complxity_trace, f'{Transaction}.json'), 'r') as f:
        trace_complexity = json.load(f)


    with open(f'/home/kaima/LLM/AttackRLLM/Code/{name}.sol', 'r') as f:
        code = f.read()

    
    
    evaluator = ComplexityEvaluator(code, trace_complexity)
    complexity_results = evaluator.evaluate()
    overall_complexity = complexity_results['overall_complexity']
    # print(json.dumps(complexity_results, indent=4))
    

    
    
    result_text, variance_text, genral_knowledge = Text_Retrive(name)
    result_vector, variance_vector = Vector_Retrive(name)
    variance = variance_text + variance_vector*10**6
    # print(variance,variance_text,variance_vector)
    knowledge_list = result_text + result_vector
    # print(knowledge_list)

    
    k_base = 3 # 最小返回文档数量
    lambda_coef = 3  # 复杂度放大系数
    mu_coef = 0.3  # 相似度方差放大系数

    dynamic_k = DynamicKAdjustment(k_base, lambda_coef, mu_coef)

    # 假设的查询复杂度和相似度得分
    complexity = overall_complexity  # 查询复杂度评分
    

    # 动态调整Top-k值
    adjusted_k = dynamic_k.adjust_k_variance(complexity, variance)
    adjusted_k = adjusted_k-2
    print(f"动态调整后的Top-k值: {adjusted_k}")
    

    # return 
    result_index_list = Re_rank(code, trace, knowledge_list,adjusted_k)
    knowledge_list_finally = []
    for index in result_index_list:
        knowledge_list_finally.append(knowledge_list[index])


    
    signal_handler(code, trace, knowledge_list_finally, name,genral_knowledge,victim_name)






def signal_handler(code, trace, combined_results, name,general_knowledge,victim_name):


    file_path = f'/home/kaima/LLM/AttackRLLM/Experiment/LLMReport/OScar/{name}.md'
    if os.path.exists(file_path):
        print(f"Already exists: {file_path}")
        return True

    prompt = prompt_complete(code, trace, combined_results,general_knowledge,victim_name)


    prompt_len = count_token_len(prompt)
    if prompt_len > 16385:
        trace_len = count_token_len(trace)
        trace = trace[:trace_len - (prompt_len - 16385)]
        prompt = prompt_complete(code, trace, combined_results,general_knowledge,victim_name)  # Correctly replace the placeholder with the actual trace
        # print(name,trace_len,prompt_len,trace_len - (prompt_len - 65536),len(trace),len(prompt))


    try:
        response = client_deepseek.chat.completions.create(
            model="Pro/deepseek-ai/DeepSeek-R1",
            messages=[
                {"role": "system", "content": "You are an expert smart contract security analyst."},
                {"role": "user", "content": prompt},
            ],
            temperature=0,
            stream=False
        )
        result = response.choices[0].message.content

        with open(file_path, 'w') as f:
            f.write(remain_markdown(result))
    except Exception as e:
        print(f"Error calling LLM: {str(e)}")



def remain_markdown(markdown_text):
    # Remove the opening ```markdown and closing ```
    if markdown_text.startswith("```markdown"):
        markdown_text = markdown_text[len("```markdown"):].lstrip()
    if markdown_text.endswith("```"):
        markdown_text = markdown_text[:-len("```")].rstrip()
    return markdown_text


def run():
    f = open('/home/kaima/LLM/AttackRLLM/Accident_Transaction_sorted_test.csv', 'r', encoding='utf-8')
    reader = csv.DictReader(f)
    for row in tqdm(reader):
        name = row['Name']
        date = row['Date']        
        chain = row['Chain']
        transaction = row['Transaction']
        name = f"{name}-{date}"
    
        try:
            Mix_Dynamic_Retrive(name,transaction, chain)
        except Exception as e:
            print(f"Error calling LLM: {str(e)}")
            continue


# 线程锁保证线程安全
file_lock = threading.Lock()
worker_counter = 0
worker_counter_lock = threading.Lock()

def get_worker_id():
    """获取唯一的工作线程ID"""
    global worker_counter
    with worker_counter_lock:
        worker_counter += 1
        return worker_counter

def run_threaded(max_workers=5):
    """
    多线程版本的运行函数
    
    参数:
        max_workers (int): 最大线程数，默认为5
    """
    f = open('/home/kaima/LLM/AttackRLLM/Accident_Transaction_sorted_test.csv', 'r', encoding='utf-8')
    reader = csv.DictReader(f)
    rows = list(reader)  # 读取所有行到内存
    
    def process_row(row, worker_id):
        name = row['Name']
        date = row['Date']        
        chain = row['Chain']
        victim = row['Victim']
        transaction = row['Transaction']
        name = f"{name}-{date}"
        
        try:
            # 检查文件是否已存在（线程安全）
            file_path = f'/home/kaima/LLM/AttackRLLM/Experiment/LLMReport/OScar/{name}.md'
            with file_lock:
                if os.path.exists(file_path):
                    print(f"[Worker-{worker_id}] File {file_path} already exists, skipping.")
                    return
            
            print(f"[Worker-{worker_id}] Processing {name}...")

            victim_name = Contract_Name(victim, chain)  # 获取合约名称
            Mix_Dynamic_Retrive(name, transaction, chain, victim_name)
            print(f"[Worker-{worker_id}] Completed {name}")
        except Exception as e:
            print(f"[Worker-{worker_id}] Error processing {name}: {str(e)}")
    
    # 使用线程池执行任务
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        # 为每个工作线程分配ID
        worker_ids = [get_worker_id() for _ in range(max_workers)]
        
        # 提交所有任务
        futures = []
        for row in rows:
            worker_id = worker_ids[len(futures) % max_workers]
            futures.append(executor.submit(process_row, row, worker_id))
        
        # 使用tqdm显示进度
        for future in tqdm(as_completed(futures), total=len(rows)):
            try:
                future.result()
            except Exception as e:
                print(f"[Main] Error in thread: {str(e)}")

if __name__ == "__main__":
    run_threaded(max_workers=2)  # 可根据需要调整线程数
    files = os.listdir('/home/kaima/LLM/AttackRLLM/Experiment/LLMReport/OScar')
    print(len(files))
    # f = open('/home/kaima/LLM/AttackRLLM/Accident_Transaction_sorted_test.csv', 'r', encoding='utf-8')
    # reader = csv.DictReader(f)
    # for row in tqdm(reader):
    #     name = row['Name']
    #     date = row['Date']        
    #     chain = row['Chain']
    #     victim = row['Victim']
    #     transaction = row['Transaction']
    #     name = f"{name}-{date}"
    #     print(Contract_Name(victim, chain))
    #     # Mix_Dynamic_Retrive(name, transaction, chain)


