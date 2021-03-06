package com.han_lang.compiler.llvm.generaotr;

import com.han_lang.compiler.analysis.Scope;
import com.han_lang.compiler.analysis.Value;
import com.han_lang.compiler.ast.HanCompilerParser;
import com.han_lang.compiler.llvm.Codegen;
import com.han_lang.compiler.llvm.Codegen2;
import com.han_lang.compiler.llvm.generaotr.calc.ValueInitGen;
import org.bytedeco.llvm.LLVM.LLVMTypeRef;
import org.bytedeco.llvm.LLVM.LLVMValueRef;

import java.util.Objects;

import static org.bytedeco.llvm.global.LLVM.*;

public class NewVarGen extends Codegen2<LLVMValueRef, Value> {
    HanCompilerParser.VarExprContext varExpr = null;

    Scope scope;
    String ID;

    public NewVarGen(HanCompilerParser.VarExprContext varExpr) {
        this.varExpr = varExpr;
    }

    public NewVarGen(Scope scope, String ID) {
        this.scope = scope;
        this.ID = ID;
    }

    @Override
    public void gen() {
        Value value;
        if(varExpr != null) value = codeGenerator.scope(varExpr).getValue(varExpr.ID().getText());
        else value = scope.getValue(ID);
        LLVMValueRef valueRef;
        //非基本类型应当为一个指针
        if(value.getType().isBasic()){
            valueRef = LLVMBuildAlloca(codeGenerator.llvmBuilder, codeGenerator.getLLVMType(value.valueType.type), value.valueName);
        }else {
            LLVMTypeRef ptr = LLVMPointerType(codeGenerator.getLLVMType(value.valueType.type), 0);
            valueRef = LLVMBuildAlloca(codeGenerator.llvmBuilder, ptr, value.valueName);
        }
        codeGenerator.addLLVMValue(value, valueRef);

        //如果有初始化运算符就申请内存空间
        if(varExpr != null && varExpr.OP_Init() != null)
            new ValueInitGen(valueRef, Objects.requireNonNull(value).getType()).gen(codeGenerator);

        result(valueRef);
        extraResult(value);
    }
}
