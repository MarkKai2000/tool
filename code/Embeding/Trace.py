import numpy as np
import hashlib
from typing import Dict, List, Union, Optional, Tuple, Any
import json
import copy
import re
import os

class TraceEmbedding:
    def __init__(self, embedding_dim: int = 128, max_depth: int = 20, debug: bool = False):
        self.embedding_dim = embedding_dim
        self.max_depth = max_depth
        self.debug = debug
        self.role_embeddings = self._initialize_role_embeddings()
        self.position_embeddings = self._initialize_position_embeddings()
        self.address_cache = {}  # Cache for address fingerprints
        self.function_cache = {}  # Cache for function signature embeddings
        
        if self.debug:
            print("\n=== Role Embeddings ===")
            for role, emb in self.role_embeddings.items():
                print(f"{role} embedding shape: {emb.shape}")
                print(f"{role} first 5 values: {emb[:5]}")
                print(f"{role} L2 norm: {np.linalg.norm(emb)}\n")

    def _initialize_role_embeddings(self) -> Dict[str, np.ndarray]:
        """Initialize orthogonal role embeddings
        
        Returns:
            Dict[str, np.ndarray]: 角色嵌入字典，包含四个基本角色：
            - caller: 调用者
            - callee: 被调用者
            - function: 函数签名（包含方法名和参数类型）
            - argument: 实际参数值
        """
        roles = ['caller', 'callee', 'function', 'argument']  # 四个基本角色
        embeddings = {}
        
        if self.debug:
            print("\n=== Initializing Role Embeddings ===")
            print(f"Number of roles: {len(roles)}")
            print(f"Angle between roles: {360.0/len(roles):.2f} degrees")
        
        for i, role in enumerate(roles):
            # 在二维平面上均匀分布角色向量
            angle = (2 * np.pi * i) / len(roles)
            if self.debug:
                print(f"Role: {role}, Angle: {angle:.2f} radians")
            
            # 生成角色向量（前两维使用角度，其余维度补零）
            vec = np.array([np.cos(angle), np.sin(angle)] + [0] * (self.embedding_dim - 2))
            embeddings[role] = vec / np.linalg.norm(vec)
            
            if self.debug:
                for other_role, other_vec in embeddings.items():
                    if other_role != role:
                        cos_angle = np.dot(vec, other_vec)
                        angle_deg = np.arccos(cos_angle) * 180 / np.pi
                        print(f"Angle between {role} and {other_role}: {angle_deg:.2f} degrees")
        
        return embeddings

    def _initialize_position_embeddings(self) -> Dict[str, Dict[int, np.ndarray]]:
        """Initialize position-aware embeddings for each level"""
        np.random.seed(42)  # For reproducibility
        embeddings = {
            'L': {},
            'R': {},
            'index': {}
        }
        
        print("\n=== Position Embeddings ===")
        for level in range(self.max_depth):
            for key in embeddings:
                embeddings[key][level] = np.random.randn(self.embedding_dim)
                if level < 3:  # 只打印前三层的信息
                    print(f"Level {level}, {key}:")
                    print(f"Shape: {embeddings[key][level].shape}")
                    print(f"First 5 values: {embeddings[key][level][:5]}")
                    print(f"L2 norm: {np.linalg.norm(embeddings[key][level])}\n")
        
        return embeddings

    def get_address_fingerprint(self, address: str) -> np.ndarray:
        """Generate address fingerprint using first 6 characters"""
        if address in self.address_cache:
            return self.address_cache[address]

        # Handle special cases like contract names
        if not address.startswith('0x'):
            address_hash = hashlib.sha256(address.encode()).hexdigest()
        else:
            prefix = address[:8]  # Take first 6 chars after '0x'
            address_hash = hashlib.sha256(prefix.encode()).hexdigest()

        # Use hash as seed for random vector
        np.random.seed(int(address_hash[:8], 16))
        fingerprint = np.random.randn(self.embedding_dim)
        fingerprint = fingerprint / np.linalg.norm(fingerprint)
        
        print(f"\n=== Address Fingerprint for {address[:10]}... ===")
        print(f"Prefix used: {prefix if address.startswith('0x') else address}")
        print(f"Hash prefix: {address_hash[:16]}...")
        print(f"First 5 values: {fingerprint[:5]}")
        print(f"L2 norm: {np.linalg.norm(fingerprint)}")
        
        self.address_cache[address] = fingerprint
        return fingerprint

    def _parse_function_signature(self, function_sig: str) -> Tuple[str, List[str]]:
        """Parse function signature into method name and parameter types
        
        Args:
            function_sig: Function signature string (e.g. "transfer(address,uint256)")
            
        Returns:
            Tuple[str, List[str]]: (method_name, parameter_types)
        """
        # Extract method name and parameters
        match = re.match(r"([a-zA-Z_][a-zA-Z0-9_]*)\((.*)\)", function_sig)
        if not match:
            return function_sig, []
        
        method_name = match.group(1)
        params_str = match.group(2)
        
        # Split parameters and remove empty strings
        param_types = [p.strip() for p in params_str.split(",") if p.strip()]
        
        if self.debug:
            print(f"\n=== Parsing Function Signature ===")
            print(f"Original: {function_sig}")
            print(f"Method: {method_name}")
            print(f"Parameters: {param_types}")
        
        return method_name, param_types

    def get_function_signature_embedding(self, function_name: Optional[str]) -> np.ndarray:
        """Generate function signature embedding with separate method and parameter type encodings"""
        if not function_name:
            return np.zeros(self.embedding_dim)
            
        if function_name in self.function_cache:
            return self.function_cache[function_name]
            
        # Parse function signature
        method_name, param_types = self._parse_function_signature(function_name)
        
        # Generate method name embedding
        method_hash = hashlib.sha256(method_name.encode()).hexdigest()
        np.random.seed(int(method_hash[:8], 16))
        method_emb = np.random.randn(self.embedding_dim)
        method_emb = method_emb / np.linalg.norm(method_emb)
        
        # Generate parameter types embedding
        param_embeddings = []
        for param_type in param_types:
            param_hash = hashlib.sha256(param_type.encode()).hexdigest()
            np.random.seed(int(param_hash[:8], 16))
            param_emb = np.random.randn(self.embedding_dim)
            param_emb = param_emb / np.linalg.norm(param_emb)
            param_embeddings.append(param_emb)
            
        # Combine embeddings
        if param_embeddings:
            param_emb = np.mean(param_embeddings, axis=0)
        else:
            param_emb = np.zeros(self.embedding_dim)
            
        # Weight method and parameter embeddings
        final_emb = 0.7 * method_emb + 0.3 * param_emb
        final_emb = final_emb / np.linalg.norm(final_emb)
        
        if self.debug:
            print(f"\n=== Function Signature Embedding ===")
            print(f"Function: {function_name}")
            print(f"Method embedding norm: {np.linalg.norm(method_emb)}")
            print(f"Param embedding norm: {np.linalg.norm(param_emb)}")
            print(f"Final embedding norm: {np.linalg.norm(final_emb)}")
        
        self.function_cache[function_name] = final_emb
        return final_emb

    def normalize_parameter(self, param: Any) -> np.ndarray:
        """Enhanced parameter normalization with type-sensitive encoding
        
        Args:
            param: Parameter value of any type
            
        Returns:
            np.ndarray: Normalized parameter embedding
        """
        if param is None:
            return np.zeros(self.embedding_dim)

        # Determine parameter type
        param_type = type(param).__name__
        
        if isinstance(param, (int, float)):
            # Handle numeric parameters
            if abs(param) > 1e18:
                # Use scientific notation for large numbers
                param_str = f"{param:.2e}"
            else:
                # Keep 3 significant digits
                param_str = f"{float(param):.3g}"
        elif isinstance(param, str):
            if param.startswith("0x"):
                # Handle hex strings (addresses or bytes)
                if len(param) <= 42:  # Ethereum address
                    return self.get_address_fingerprint(param)
                else:  # Bytes data
                    param_str = param[:32]  # Take first 16 bytes
            else:
                param_str = param[:32]  # Limit string length
        elif isinstance(param, bytes):
            # Handle raw bytes
            param_str = param.hex()[:32]
        elif isinstance(param, bool):
            param_str = str(param)
        elif isinstance(param, (list, tuple)):
            # Handle arrays by combining their elements
            embeddings = [self.normalize_parameter(item) for item in param[:5]]  # Limit to first 5 elements
            if embeddings:
                return np.mean(embeddings, axis=0)
            return np.zeros(self.embedding_dim)
        else:
            param_str = str(param)[:32]
        
        # Generate parameter embedding
        param_hash = hashlib.sha256(f"{param_type}:{param_str}".encode()).hexdigest()
        np.random.seed(int(param_hash[:8], 16))
        embedding = np.random.randn(self.embedding_dim)
        embedding = embedding / np.linalg.norm(embedding)
        
        if self.debug:
            print(f"\n=== Parameter Normalization ===")
            print(f"Original: {param}")
            print(f"Type: {param_type}")
            print(f"Normalized: {param_str}")
            print(f"Embedding norm: {np.linalg.norm(embedding)}")
        
        return embedding

    def _get_position_encoding(self, path: List[Union[str, int]]) -> np.ndarray:
        """Generate position encoding directly from path segments
        
        Args:
            path: 位置路径，可以包含'L'/'R'或数字索引
            
        Returns:
            np.ndarray: 位置编码向量
        """
        # 初始化编码向量
        encoding = np.zeros(self.embedding_dim)
        
        if self.debug:
            print(f"\n=== Position Encoding for path {path} ===")
        
        # 对路径中的每个段进行编码
        for i, segment in enumerate(path[:self.max_depth]):
            # 生成段的哈希值
            segment_hash = hashlib.sha256(str(segment).encode()).hexdigest()
            np.random.seed(int(segment_hash[:8], 16))
            
            # 生成该段的嵌入
            segment_embedding = np.random.randn(self.embedding_dim)
            segment_embedding = segment_embedding / np.linalg.norm(segment_embedding)
            
            # 添加位置权重（使用指数衰减）
            weight = np.exp(-i / self.max_depth)  # 指数衰减权重
            encoding += weight * segment_embedding
            
            if self.debug:
                print(f"Level {i}:")
                print(f"  Segment: {segment}")
                print(f"  Weight: {weight:.4f}")
                print(f"  Embedding norm: {np.linalg.norm(segment_embedding)}")
        
        # 标准化最终的编码向量
        if np.any(encoding):  # 确保不是零向量
            encoding = encoding / np.linalg.norm(encoding)
            
        if self.debug:
            print(f"Final encoding norm: {np.linalg.norm(encoding)}")
            
        return encoding

    def _get_call_path(self, trace: dict) -> List[List[Union[str, int]]]:
        """获取调用树中每个节点的位置路径
        
        Args:
            trace: 调用追踪数据
            
        Returns:
            List[List[Union[str, int]]]: 每个节点的位置路径列表
        """
        def _traverse(node: dict, current_path: List[Union[str, int]]) -> List[List[Union[str, int]]]:
            paths = [current_path]  # 当前节点的路径
            
            # 处理子调用
            if 'calls' in node and node['calls']:
                for i, subcall in enumerate(node['calls']):
                    # 确定子节点的路径
                    if len(node['calls']) <= 2:
                        # 二叉树情况：使用L/R
                        child_path = current_path + ['L' if i == 0 else 'R']
                    else:
                        # 多叉树情况：使用索引
                        child_path = current_path + [i]
                    
                    # 递归处理子节点
                    paths.extend(_traverse(subcall, child_path))
            
            return paths
        
        # 从根节点开始遍历
        return _traverse(trace, [])

    def embed_trace(self, trace: dict) -> np.ndarray:
        """Embed a single trace with its full context"""
        # 使用trace中已有的path信息
        current_path = trace.get('path', [])
        
        if self.debug:
            print(f"\n=== Embedding Trace ===")
            print(f"Path: {current_path}")
        
        embeddings = []
        weights = []  # 存储每个嵌入的权重

        # 1. Embed caller (from address)
        caller_emb = self.get_address_fingerprint(trace['from']) * self.role_embeddings['caller']
        embeddings.append(caller_emb)
        weights.append(1.0)  # 基础权重

        # 2. Embed callee (to address)
        callee_emb = self.get_address_fingerprint(trace['to']) * self.role_embeddings['callee']
        embeddings.append(callee_emb)
        weights.append(1.0)

        # 3. Embed function signature
        if trace.get('function'):
            func_emb = self.get_function_signature_embedding(trace['function']) * self.role_embeddings['function']
            embeddings.append(func_emb)
            weights.append(1.2)  # 增加函数签名的权重

        # 4. Embed parameters
        if trace.get('params'):
            for param_name, param_value in trace['params'].items():
                param_emb = self.normalize_parameter(param_value) * self.role_embeddings['argument']
                embeddings.append(param_emb)
                weights.append(0.8)  # 降低参数的权重

        # 5. Add position encoding using the path from trace
        pos_encoding = self._get_position_encoding(current_path)
        embeddings.append(pos_encoding)
        weights.append(1.5)  # 增加位置编码的权重

        # 6. Process subcalls recursively with depth-based weight decay
        if 'calls' in trace and trace['calls']:
            depth = len(current_path)
            depth_weight = np.exp(-depth / self.max_depth)  # 深度衰减权重
            
            for subcall in trace['calls']:
                subcall_embedding = self.embed_trace(subcall)
                embeddings.append(subcall_embedding)
                weights.append(depth_weight)  # 使用深度权重

        # 7. Weighted average pooling
        weights = np.array(weights)
        weights = weights / np.sum(weights)  # 归一化权重
        embeddings = np.array(embeddings)
        
        final_embedding = np.average(embeddings, axis=0, weights=weights)
        final_embedding = final_embedding / np.linalg.norm(final_embedding)

        if self.debug:
            print(f"\n=== Final Embedding ===")
            print(f"Number of components: {len(embeddings)}")
            print(f"Weights: {weights}")
            print(f"Final embedding norm: {np.linalg.norm(final_embedding)}")

        return final_embedding

    def add_path_to_trace(self, trace: dict) -> dict:
        """将位置路径信息添加到trace结构中
        
        Args:
            trace: 原始调用追踪数据
            
        Returns:
            dict: 添加了位置路径信息的trace
        """
        def _traverse_and_add(node: dict, current_path: List[Union[str, int]]) -> dict:
            # 深拷贝节点以避免修改原始数据
            node = copy.deepcopy(node)
            
            # 添加路径信息
            node['path'] = current_path
            
            # 处理子调用
            if 'calls' in node and node['calls']:
                new_calls = []
                for i, subcall in enumerate(node['calls']):
                    # 确定子节点的路径
                    if len(node['calls']) <= 2:
                        child_path = current_path + ['L' if i == 0 else 'R']
                    else:
                        child_path = current_path + [i]
                    
                    # 递归处理子节点
                    new_calls.append(_traverse_and_add(subcall, child_path))
                
                node['calls'] = new_calls
            
            return node
        
        # 从根节点开始处理
        return _traverse_and_add(trace, [])

    def process_trace(self, trace: dict) -> Tuple[np.ndarray, dict]:
        """处理trace，返回嵌入向量和增强后的trace结构
        
        Args:
            trace: 原始调用追踪数据
            
        Returns:
            Tuple[np.ndarray, dict]: (嵌入向量, 增强后的trace)
        """
        if self.debug:
            print("\n=== Processing Trace ===")
            print(f"Original trace depth: {self._get_trace_depth(trace)}")
        
        # 1. 添加路径信息到trace
        enhanced_trace = self.add_path_to_trace(trace)
        
        if self.debug:
            print(f"Enhanced trace depth: {self._get_trace_depth(enhanced_trace)}")
            print("Path information added successfully")
        
        # 2. 生成嵌入
        embedding = self.embed_trace(enhanced_trace)
        
        return embedding, enhanced_trace

    def _get_trace_depth(self, trace: dict) -> int:
        """Calculate the depth of a trace tree
        
        Args:
            trace: Trace dictionary
            
        Returns:
            int: Maximum depth of the trace tree
        """
        max_depth = 0
        if 'calls' in trace and trace['calls']:
            for subcall in trace['calls']:
                max_depth = max(max_depth, self._get_trace_depth(subcall))
        return max_depth + 1

def load_trace_from_file(file_path: str) -> dict:
    """Load trace from JSON file"""
    with open(file_path, 'r') as f:
        return json.load(f)

def main():
    # Example usage
    trace_file = "AttackCallTrace/BSC_Round1_name/0xeaaa8f4d33b1035a790f0d7c4eb6e38db7d6d3b580e0bbc9ba39a9d6b80dd250.json"
    trace = load_trace_from_file(trace_file)
    
    # Initialize embedder with debug mode
    embedder = TraceEmbedding(embedding_dim=300, max_depth=50, debug=False)
    
    # Process trace and generate embedding
    embedding, enhanced_trace = embedder.process_trace(trace)
    
    # Save results
    output_file = "/home/kaima/LLM/DataCollection/Embedding/Result/Path/" + trace_file.split("/")[-1].replace('.json', '.json')
    with open(output_file, 'w') as f:
        json.dump(enhanced_trace, f, indent=2)
    print(f"\nTrace with paths saved to: {output_file}")
    # Save embedding
    embedding_file = "/home/kaima/LLM/DataCollection/Embedding/Result/Embed/" + trace_file.split("/")[-1].replace('.json', '.npy')
    np.save(embedding_file, embedding)
    print(f"Embedding saved to: {embedding_file}")

def batch_process():
    trace_dir = "/home/kaima/LLM/Embed_code715/BSC_Round2"
    # trace_dir = "/home/kaima/LLM/Embed_code715/ETH_Round2"
    embedder = TraceEmbedding(embedding_dim=300, max_depth=50, debug=False)
    
    for filename in os.listdir(trace_dir):
        if not filename.endswith('.json'):
            continue
            
        trace_path = os.path.join(trace_dir, filename)
        output_path = os.path.join("/home/kaima/LLM/Embed_code715/Trace_Embed/Path", filename)
        embed_path = os.path.join("/home/kaima/LLM/Embed_code715/Trace_Embed/Embed", filename.replace('.json', '.npy'))
        
        # Skip if both output files already exist
        if os.path.exists(output_path) and os.path.exists(embed_path):
            print(f"Skipping {filename} - already processed")
            continue
            
        # Process trace
        trace = load_trace_from_file(trace_path)
        embedding, enhanced_trace = embedder.process_trace(trace)
        
        # Save results
        with open(output_path, 'w') as f:
            json.dump(enhanced_trace, f, indent=2)
        np.save(embed_path, embedding)
        print(f"Processed {filename}")

if __name__ == "__main__":
    batch_process() 
    files = os.listdir('/home/kaima/LLM/Embed_code715/Trace_Embed/Embed')
    print(len(files))

    files = os.listdir('/home/kaima/LLM/Embed_code715/Trace_Embed/Path')
    print(len(files))


    files = os.listdir('/home/kaima/LLM/Embed_code715/BSC_Round2')
    print(len(files))

    files = os.listdir('/home/kaima/LLM/Embed_code715/ETH_Round2')
    print(len(files))

    
    files = os.listdir('/home/kaima/LLM/Embed_code715/Embed_result')
    print(len(files))


    
    
    # /home/kaima/LLM/DataCollection/Embedding/Result/Embed/0x758efef41e60c0f218682e2fa027c54d8b67029d193dd7277d6a881a24b9a561.npy