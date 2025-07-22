import json
import os
from web3 import Web3


url = ""
# 设置超时为60秒
http_provider = Web3.HTTPProvider(url, request_kwargs={'timeout': 60})

def Test_Connection():
    w3 = Web3(http_provider)
    # Test connection
    if w3.is_connected():
        print("Connection successful")
    else:
        print("Connection failed")
        

def Get_Trace(txhash = '0x05d65e0adddc5d9ccfe6cd65be4a7899ebcb6e5ec7a39787971bcc3d6ba73996'):
    try:
        temp_res = http_provider.make_request('debug_traceTransaction', [txhash, {"tracer":'callTracer'}])
        result = temp_res['result']
        
        with open(f'/home/kaima/LLM/Description/Transaction_Static_Analysis/Trace/{txhash}.json', 'w') as file:
            json.dump(result, file)
    except Exception as e:
        print(f"Error: {e}")
        print(f"Error: {txhash}")
        with open(f'/home/kaima/LLM/Description/Transaction_Static_Analysis/Trace/{txhash}.json', 'w') as file:
            json.dump({"error": str(e)}, file)


if __name__ == "__main__":
    # Get_Trace("0x85dc2a433fd9eaadaf56fd8156c956da23fc17e5ef83955c7e2c4c37efa20bb5")
    Get_Trace("0x6D9f6E900ac2CE6770Fd9f04f98B7B0fc355E2EA")