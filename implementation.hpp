#ifndef IMPLEMENTATION_HPP
#define IMPLEMENTATION_HPP

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
std::stack<std::string> labelStack;
std::map<std::string, Symbol> symbols;
std::vector<std::string> code;

std::string newLabel()
{
    static size_t counter = 1;
    return "LBL" + std::to_string(counter++);
}

void emitLabel(const std::string &label)
{
    code.push_back(label + ":");
}

void loadToRegister(const Operand &op, const std::string &reg);

void emitConditionalJump(const std::string &branchOp)
{
    Operand rightArg = valueStack.top();
    valueStack.pop();
    Operand leftArg = valueStack.top();
    valueStack.pop();

    if (leftArg.type != DataType::INT || rightArg.type != DataType::INT)
    {
        std::println("Bison ERR: Only INT values can be compared");
        exit(1);
    }
    loadToRegister(leftArg, "$t0");
    loadToRegister(rightArg, "$t1");

    std::string falseLabel = newLabel();
    code.push_back(branchOp + " $t0, $t1, " + falseLabel);
    labelStack.push(falseLabel);
}

void emitElse()
{
    std::string endLabel = newLabel();
    code.push_back("b " + endLabel);
    emitLabel(labelStack.top());
    labelStack.pop();
    labelStack.push(endLabel);
}

void emitIfEnd()
{
    emitLabel(labelStack.top());
    labelStack.pop();
}

void addSymbol(const std::string &name, DataType type)
{
    symbols.insert({name, Symbol{type}});
}

DataType getVariableType(const std::string &name)
{
    auto it = symbols.find(name);
    if (it == symbols.end())
    {
        // todo
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

void emitTriple(const std::string &asmOp)
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

void emitPrint(const Operand &op)
{
    switch (op.type)
    {
        case DataType::INT:
            loadToRegister(op, "$a0");
            code.push_back("li $v0, 1");
            break;
        case DataType::REAL:
            code.push_back("l.s $f12, " + op.value);
            code.push_back("li $v0, 2");
            break;
        case DataType::STRING:
            code.push_back("la $a0, " + op.value);
            code.push_back("li $v0, 4");
            break;
    }
    code.push_back("syscall");
}

void emitPrintln(const Operand &op)
{
    emitPrint(op);
    code.push_back("li $a0, 10");
    code.push_back("li $v0, 11");
    code.push_back("syscall");
}

void emitRead(const std::string &name)
{
    DataType type = getVariableType(name);
    switch (type)
    {
        case DataType::INT:
            code.push_back("li $v0, 5");
            code.push_back("syscall");
            code.push_back("sw $v0, " + name);
            break;
        case DataType::REAL:
            code.push_back("li $v0, 6");
            code.push_back("syscall");
            code.push_back("s.s $f0, " + name);
            break;
        case DataType::STRING:
            std::println("Bison ERR: Read to string is not sopported\n");
            exit(1);
            break;
    }
}

#endif // IMPLEMENTATION_HPP
