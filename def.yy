%{
#include <print>
#include <stack>
#include <map>
#include <vector>
#include <fstream>
#include <string>
#define INFILE_ERROR 1
#define OUTFILE_ERROR 2

extern "C" int yylex();
extern "C" int yyerror(const char *msg, ...);

enum class DataType
{
    INT,
    REAL,
    STRING,
};

enum class OperandKind
{
    CONSTANT,
    VARIABLE,
    TEMPORARY,
};

struct Symbol
{
    DataType type;
    // size_t arraySize;
};

struct Operand
{
    OperandKind kind;
    DataType type;
    std::string value;
};

std::stack<Operand> valueStack;
std::map<std::string, Symbol> symbols;
std::vector<std::string> code;

void addSymbol(const std::string &name, DataType type)
{
    symbols.insert({name, Symbol{type}});
}

DataType getVariableType(const std::string &name)
{
    auto it = symbols.find(name);
    if (it == symbols.end())
    {
        //todo 
        addSymbol(name, DataType::INT);
        return DataType::INT;
    }
    return it->second.type;
}

std::string newTemp(DataType type)
{
    static size_t counter = 1;
    std::string name = "result" + std::to_string(counter++);
    addSymbol(name, type);
    return name;
}

DataType resultType(const Operand &left, const Operand &right)
{
    if (left.type == right.type && left.type != DataType::STRING)
        return left.type;
    std::println("Bison ERR: left and right data types have to be the same");
    exit(1);
}

void loadToRegister(const Operand &op, const std::string &reg)
{
    if (op.kind == OperandKind::CONSTANT)
        code.push_back("li " + reg + ", " + op.value);
    else
        code.push_back("lw " + reg + ", " + op.value);
}

void emitTriple(const std::string asmOp)
{
    Operand rightArg = valueStack.top();
    valueStack.pop();
    Operand leftArg = valueStack.top();
    valueStack.pop();
    
    DataType type = resultType(leftArg, rightArg);
    Operand result{OperandKind::TEMPORARY, type, newTemp(type)};
    valueStack.push(result);

    loadToRegister(leftArg, "$t0");
    loadToRegister(rightArg, "$t1");
    code.push_back(asmOp + " $t0, $t0, $t1");
    code.push_back("sw $t0, " + result.value);

    std::println("Bison: {} = {} {} {}", result.value, leftArg.value, asmOp, rightArg.value);
}

%}

%union 
{
    char *text;
    int	ival;
    float fval;
};
// %type <text> expression
%token <text> ID
%token <ival> NUM
%token ENDLINE
%left '+' '-'
%left '*' '/'
%right '='

%start program
%%
program
    : statement_list
    |
    ;
statement_list
    : statement_list statement
    | statement 
    ;
statement
    : expression ENDLINE { valueStack.pop(); }
    | assignment ENDLINE
    ;
expression
	:expression '+' term	{ emitTriple("add"); }
	|expression '-' term	{ emitTriple("sub"); }
	|term		{std::println("Bison: wyrazenie pojedyncze");}
	;
term
	:term '*' factor	{ emitTriple("mul");}
	|term '/' factor	{ emitTriple("div");}
	|factor
	;
factor
	:ID			{
        Operand op{OperandKind::VARIABLE, getVariableType($1), $1};
        valueStack.push(op);
        free($1);
    } 
	|NUM			{
        Operand op{OperandKind::CONSTANT, DataType::INT, std::to_string($1)};
        valueStack.push(op);
    }
	|'(' expression ')'
	;
assignment
    : ID '=' expression {
        Operand value = valueStack.top();
        valueStack.pop();
        addSymbol($1, value.type);
        loadToRegister(value, "$t0");
        code.push_back("sw $t0, " + std::string($1));
        free($1);
    }
    ;

%%
int main(int argc, char *argv[])
{
	yyparse();
    std::ofstream OutFile("a.out");

    OutFile << ".data\n";
    for (auto &[name, symbol] : symbols)
    {
        //todo: check if float, then change word to sth else
        OutFile << "\t" << name << ":\t.word 0\n";
    }

    OutFile << ".text\n";
    for (auto &line : code)
        OutFile << "\t" << line << "\n";
    
    OutFile.close();
	return 0;
}