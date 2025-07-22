import transformers

def count_token_len(prompt):
# 加载本地 tokenizer
    chat_tokenizer_dir = "/home/kaima/LLM/DataCollection/Retrieval/tokenizer"
    tokenizer = transformers.AutoTokenizer.from_pretrained(
        chat_tokenizer_dir, trust_remote_code=True
    )


    result = tokenizer.encode(prompt)
    token_length = len(result)

    # 输出 prompt 的 token 长度
    return token_length