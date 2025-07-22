import os
import os.path
from contract_normalization import Contract_Norm


def parser(name):
    '''
        parse the user_input.sol into AST 
    '''
    cmd = f"java -classpath ./Parse/antlr4.jar:./Parse/target/ \
                Tokenize ./ContractCode/{name}.sol ./ParseResult/{name}_"
    os.system(cmd) 
    
def normalizer(name):
    cn = Contract_Norm("./ParseResult", name)    
    return cn.line_span, cn.normalized_tokens



def main():
    name = 'function'
    parser(name)
    result = normalizer(name)[1]

    


if __name__ == '__main__':
    # main()
    main()