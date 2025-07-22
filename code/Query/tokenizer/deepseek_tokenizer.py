import transformers

# 加载本地 tokenizer
chat_tokenizer_dir = "/home/kaima/LLM/DataCollection/Retrieval/tokenizer"
tokenizer = transformers.AutoTokenizer.from_pretrained(
    chat_tokenizer_dir, trust_remote_code=True
)

# 读取 prompt 文件
file_path = "/home/kaima/LLM/DataCollection/Retrieval/promt.txt"
with open(file_path, 'r', encoding='utf-8') as f:
    prompt = f.read()

# 计算 token 数量
# prompt = 'InitializableImmutableAdminUpgradeabilityProxy'

result = tokenizer.encode(prompt)
token_length = len(result)

# 输出 prompt 的 token 长度
print(f"Prompt 的 token 长度: {token_length}")