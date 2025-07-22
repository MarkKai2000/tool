import re
import json
import numpy as np
from collections import Counter
from scipy.stats import entropy
import csv
import os 

class ComplexityEvaluator:
    def __init__(self, code, trace):
        self.code = code
        self.trace = trace

    def compute_code_complexity(self):
        """
        计算 Solidity 代码的复杂度，包括长度、关键词密度、控制结构、信息熵等。
        """
        # 1. 代码长度评分 (归一化)
        max_length = 1000
        length_score = min(len(self.code) / max_length, 1)

        # 2. 关键词密度（智能合约关键字）
        solidity_keywords = [
            "function", "require", "if", "else", "while", "for", "emit", "return",
            "modifier", "assembly", "delegatecall", "call", "staticcall", "selfdestruct",
            "revert", "mapping", "memory", "storage"
        ]
        keyword_count = sum(self.code.count(kw) for kw in solidity_keywords)
        keyword_density = keyword_count / len(self.code.split())

        # 3. 代码控制流复杂度 (括号层次 + require 语句)
        control_structures = ["if", "for", "while", "require", "{", "}"]
        control_structure_count = sum(self.code.count(kw) for kw in control_structures)
        control_complexity = min(control_structure_count / 40, 1)

        # 4. 代码的信息熵（计算词频分布）
        words = re.findall(r'\b\w+\b', self.code.lower())
        word_freq = Counter(words)
        freq_distribution = np.array(list(word_freq.values()))
        entropy_score = entropy(freq_distribution) / np.log(len(freq_distribution) + 1)

        # 综合复杂度计算
        code_complexity = 0.3 * length_score + 0.2 * keyword_density + 0.3 * control_complexity + 0.2 * entropy_score
        return {"length_score": length_score, "keyword_density": keyword_density, 
                "control_complexity": control_complexity, "entropy_score": entropy_score, 
                "final_code_complexity": code_complexity}

    def compute_trace_complexity(self):
        """
        计算 EVM 交易调用追踪的复杂度，包括深度、交互性、函数参数多样性等。
        """
        trace_data = json.loads(self.trace) if isinstance(self.trace, str) else self.trace
        # print(trace_data)
        
        def traverse_calls(calls, depth=1):
            """ 递归遍历交易调用，计算深度和调用数量 """
            if not calls:
                return depth, 0, 0, []
            max_depth = depth
            total_calls = len(calls)
            external_calls = 0  # 统计外部合约交互数量
            param_types = []  # 收集所有参数类型
            
            

            for call in calls:
                if call.get("param_types"):
                    param_types.extend(call["param_types"])
                if "calls" in call and call["calls"]:
                    sub_depth, sub_calls, sub_external, sub_params = traverse_calls(call["calls"], depth + 1)
                    max_depth = max(max_depth, sub_depth)
                    total_calls += sub_calls
                    external_calls += sub_external
                    param_types.extend(sub_params)

                # 统计合约外部交互 (跨合约调用)
                if call["to"] and "0x" not in call["to"]:
                    external_calls += 1

            return max_depth, total_calls, external_calls, param_types

        depth, total_calls, external_calls, param_types = traverse_calls(trace_data['calls'])

        # 计算参数多样性（唯一参数类型数/总参数数）
        unique_param_types = len(set(param_types)) if param_types else 0
        param_diversity = unique_param_types / max(1, len(param_types))

        # 归一化复杂度评分
        max_depth_norm = min(depth / 10, 1)
        total_calls_norm = min(total_calls / 50, 1)
        external_calls_norm = min(external_calls / 20, 1)
        param_diversity_norm = param_diversity

        trace_complexity = 0.3 * max_depth_norm + 0.3 * total_calls_norm + 0.2 * external_calls_norm + 0.1 * param_diversity_norm
        return {"depth_score": max_depth_norm, "total_calls_score": total_calls_norm, 
                "external_calls_score": external_calls_norm, "param_diversity_score": param_diversity_norm, 
                "final_trace_complexity": trace_complexity}

    def evaluate(self):
        """ 计算代码和交易追踪的总体复杂度 """
        code_complexity = self.compute_code_complexity()
        trace_complexity = self.compute_trace_complexity()
        
        overall_complexity = 0.5 * code_complexity["final_code_complexity"] + 0.5 * trace_complexity["final_trace_complexity"]
        
        return {
            "code_complexity": code_complexity,
            "trace_complexity": trace_complexity,
            "overall_complexity": overall_complexity
        }


if __name__ == "__main__":
    # 示例代码与交易追踪

    trace_folder_eth = '/home/kaima/LLM/AttackRLLM/Transaction/ETH_Round2'
    trace_folder_bsc = '/home/kaima/LLM/AttackRLLM/Transaction/BSC_Round2'


    with open('/home/kaima/LLM/AttackRLLM/Accident_Transaction_sorted_test.csv', 'r') as file:
        reader = csv.DictReader(file)
        for row in reader:
            name = row['Name']
            transaction = row['Transaction']
            Date = row['Date']
            Type = row['Type']
            Chain = row['Chain']
            name = name + '-' + Date  # Combine name and date for unique identification
            print(name,Type)


            
            if Chain == 'Ethereum':
                trace_path = os.path.join(trace_folder_eth, f"{transaction}.json")
            if Chain == 'Binance':
                trace_path = os.path.join(trace_folder_bsc, f"{transaction}.json")
    

            with open(f'/home/kaima/LLM/AttackRLLM/Code/{name}.sol', 'r') as f:
                solidity_code = f.read()
            with open(trace_path, 'r') as f:
                evm_trace = json.load(f)
        

            # 评估代码与交易复杂度
            evaluator = ComplexityEvaluator(solidity_code, evm_trace)
            complexity_results = evaluator.evaluate()
            print(complexity_results['overall_complexity'])


        # print(json.dumps(complexity_results, indent=4))