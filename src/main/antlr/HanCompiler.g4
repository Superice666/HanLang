grammar HanCompiler;

@lexer::members {
    public static boolean inType = false;
}

program: (expr | functionExpr | newtypeExpr OP_End)* (EOF | '<EOF>');

operator1: OP_Not | OP_Plus | OP_Minus;
operator2_p1: OP_Equal | OP_NotEqual | OP_Greater | OP_GreaterEqual | OP_Lower | OP_LowerEqual;
operator2_p2: OP_Plus | OP_Minus;
operator2_p3: OP_Mutiply | OP_Divide | OP_Remain;
operator2_p4: OP_Power;
operator2_p5: OP_And | OP_Or;
operatorEnd: OP_EndCall;
operator_all: operator2_p1 | operator2_p2 | operator2_p3 | operator2_p4 | operator2_p5;
flowExpr: KEY_Continue | KEY_Break | KEY_Return calcExpr?;
type_basic: Type_Boolean | Type_Byte | Type_Float
    | Type_Int | Type_LongFloat | Type_LongInt
    | Type_LongLongFloat | Type_LongLongInt
    | Type_ShortFloat | Type_ShortInt | Type_String
    ;
expr: varExpr  OP_End               #InnerVarExpr
    | constAndSetExpr OP_End        #InnerConstExpr
    | setExpr OP_End                #InnerSetExpr
    | calcExpr OP_End               #InnerCalcExpr
    | ifelseExpr                    #InnerIfElseExpr
    | whileExpr                     #InnerWhileExpr
    | flowExpr OP_End               #InnerFlowExpr
    ;
varExpr: KEY_Var ID typeExpr OP_Init?;
constAndSetExpr: KEY_Const ID typeExpr OP_Init? OP_Set calcExpr;
newtypeExpr: KEY_Type ID typeExpr;
typeEntryPart: ID typeExpr OP_Split;
typeEntryEnd: ID typeExpr OP_Split?;
typeFuncArgExpr: (typeExpr OP_Split)* (typeExpr OP_Split?);
typeExpr: OP_BraketType_Left type_basic OP_BraketType_Right             #BasicTypeExpr
    | OP_BraketType_Left type_basic OP_Mutiply INT OP_BraketType_Right  #BasicArrayExpr
    | OP_BraketType_Left ID OP_BraketType_Right                         #CustomTypeExpr
    | OP_BraketType_Left ID OP_Mutiply INT OP_BraketType_Right          #CustomArrayExpr
    | OP_BraketType_Left typeEntryPart*
        typeEntryEnd OP_BraketType_Right                                #StructExpr
    | OP_BraketType_Left typeExpr? OP_Braket_Left
        typeFuncArgExpr? OP_Braket_Right OP_BraketType_Right            #FuncTypeExpr
    ;
setExpr: (ID | varExpr) OP_Set calcExpr;
templePart: calcExpr OP_Split;
templeEnd: calcExpr OP_Split?;
templeExpr: OP_BraketMatch_Left templePart* templeEnd OP_BraketMatch_Right           #StructTemple
    | OP_BraketMatch_Left '|'
        templePart* templeEnd '|' OP_BraketMatch_Right                               #ArrayTemple
    | OP_BraketMatch_Left OP_BraketMatch_Right /*????????????*/                            #EmptyTemple
    | OP_BraketMatch_Left '|' '|' OP_BraketMatch_Right /*????????????*/                    #EmptyTemple
    | OP_BraketMatch_Left OP_Or OP_BraketMatch_Right /*????????????*/                      #EmptyTemple
    ;
decoratorExpr: Decorator_Caster OP_Braket_Left typeExpr
        KEY_Cast typeExpr OP_Braket_Right                               #DecoratorCast
    | Decorator_Operator OP_Braket_Left typeExpr
        operator_all typeExpr OP_Set typeExpr OP_Braket_Right         #DecoratorOp2
    | Decorator_Operator OP_Braket_Left operator1
        typeExpr OP_Set typeExpr OP_Braket_Right                      #DecoratorOp1
    | Decorator_Operator OP_Braket_Left typeExpr
        operatorEnd OP_Set typeExpr OP_Braket_Right                   #DecoratorOpEnd
    ;
calcExpr: <assoc=right> operator1 calcExpr                              #C1Expr  //operator1
    | OP_Braket_Left calcExpr operator_all
        calcExpr OP_Braket_Right                                        #C2ExprB //operator with braket
    | calcExpr KEY_Cast typeExpr KEY_Type                               #CastExpr//cast to another type
    | calcExpr OP_Call OP_Braket_Left
        calcExpr? (OP_Split calcExpr)* OP_Braket_Right                  #IExpr   //invoke
    | calcExpr OP_Call
        OP_BraketCall_Left calcExpr OP_BraketCall_Right                 #GCExpr  //get by calc
    | calcExpr OP_Call (INT | ID)                                       #GDExpr  //get directly
    | calcExpr operator2_p5 calcExpr                                    #C2Expr  //operator2
    | calcExpr operator2_p4 calcExpr                                    #C2Expr  //operator2
    | <assoc=right> calcExpr operator2_p3 calcExpr                      #C2Expr  //operator2
    | calcExpr operator2_p2 calcExpr                                    #C2Expr  //operator2
    | calcExpr operator2_p1 calcExpr                                    #C2Expr  //operator2
    | (literal | ID)                                                    #LExpr   //literal, var or const
    | templeExpr                                                        #TExpr   //temple
    | OP_At ID                                                          #FPtrExpr//func ptr
    | OP_Braket_Left (literal | ID) OP_Braket_Right                     #LBExpr  //above with braket
    | calcExpr operatorEnd                                              #ECExpr  //call in end
    ;
argPartExpr: ID typeExpr OP_Split;
argEndExpr: ID typeExpr OP_Split?;
returnExpr: KEY_Return calcExpr? OP_End;
functionExpr: decoratorExpr? KEY_Function ID
        OP_BraketType_Left (type_basic | ID) OP_BraketType_Right
        OP_Braket_Left argPartExpr* argEndExpr OP_Braket_Right
        OP_BraketMatch_Left (expr | returnExpr)* OP_BraketMatch_Right                       #FunRA
    | decoratorExpr? KEY_Function ID
        (OP_BraketType_Left KEY_Null OP_BraketType_Right)?
        OP_Braket_Left argPartExpr* argEndExpr OP_Braket_Right
        OP_BraketMatch_Left (expr | returnExpr)* OP_BraketMatch_Right                       #FunA
    | decoratorExpr? KEY_Function ID
        OP_BraketType_Left (type_basic | ID) OP_BraketType_Right
        (OP_Braket_Left OP_Braket_Right)?
        OP_BraketMatch_Left (expr | returnExpr)* OP_BraketMatch_Right                       #FunR
    | decoratorExpr? KEY_Function ID
        (OP_BraketType_Left KEY_Null? OP_BraketType_Right)?
        (OP_Braket_Left OP_Braket_Right)?
        OP_BraketMatch_Left (expr | returnExpr)* OP_BraketMatch_Right                       #Fun
    ;
ifbodyExpr: OP_Braket_Left calcExpr OP_Braket_Right
      OP_BraketMatch_Left expr* OP_BraketMatch_Right;
ifbodyEndExpr: (OP_Braket_Left OP_Braket_Right)?
      OP_BraketMatch_Left expr* OP_BraketMatch_Right;
ifelseExpr: KEY_If ifbodyExpr
      (KEY_Elif ifbodyExpr)*
      (KEY_Else ifbodyEndExpr)?
    ;
whileExpr: KEY_Loop OP_Braket_Left calcExpr OP_Braket_Right
      OP_BraketMatch_Left expr* OP_BraketMatch_Right;

/**
 * ??????????????????
 */
THROWAWAY: (COMMENT|WS) -> skip;

COMMENT: ONELINE_COMMENT | MUTILINE_COMMENT;
ONELINE_COMMENT: '//' ~[\r\n]*? ('\n' | '\r\n' | EOF);
MUTILINE_COMMENT: '/*' .*? '*/';

WS: ' ' | '\r\n' | '\n';

/**
 * ???????????????
 */

Decorator_Caster: '#' ' '* 'caster' {inType = true;} | '#' ' '* '?????????' {inType = true;} ;
Decorator_Operator: '#' ' '* 'operator' {inType = true;} | '#' ' '* '?????????' {inType = true;} ;

//?????????????????????
OP_Power: '**';
OP_Plus: '+';
OP_Minus: '-';
OP_Mutiply: '*';
OP_Divide: '/';
OP_Remain: '%';
OP_Greater: '>' {!inType}?;
OP_GreaterEqual: '>=' {!inType}?;
OP_Lower: '<' {!inType}?;
OP_LowerEqual: '<=' {!inType}?;
OP_NotEqual: '!=' | '???=';
OP_Equal: '==';
OP_Not: '!';
OP_And: '&&';
OP_Or: '||';
OP_Call: '???' | ':';
OP_Split: '???' | ',';
OP_Set: '=';
OP_End: '???'+ {inType = false;} | ';'+ {inType = false;};
OP_EndCall: '#';
OP_At: '@';
OP_Init: '~';

OP_Braket_Left: '???' | '(';
OP_Braket_Right: '???' | ')';
OP_BraketCall_Left: '???' | '[';
OP_BraketCall_Right: '???' | ']';
OP_BraketType_Left: '???' | '<';
OP_BraketType_Right: '???' | '>';
OP_BraketMatch_Left: '???' {inType = false;} | '{' {inType = false;};
OP_BraketMatch_Right: '???' {inType = false;} | '}' {inType = false;};

KEY_Null: '???' | 'null';
KEY_Var: '??????' {inType = true;} | 'var' {inType = true;};
KEY_Const: '??????' {inType = true;} | 'const' {inType = true;};
KEY_Type: '??????' {inType = !inType;} | 'type'{inType = !inType;};
KEY_Function: '??????' {inType = true;} | 'function' {inType = true;};
KEY_Return: '??????' | 'return';
KEY_Break: '??????' | 'break';
KEY_Continue: '??????' | 'continue';
KEY_Loop: '???' | 'while';
KEY_If: '??????' | 'if';
KEY_Elif: '????????????' | 'elif';
KEY_Else: '??????' | 'else';
KEY_Cast: '??????' {inType = true;} | 'as'{inType = true;};

Type_Byte: '??????' | 'byte';
Type_Int: '??????' | 'int';
Type_LongInt: '?????????' | 'lint';
Type_ShortInt: '?????????' | 'sint';
Type_LongLongInt: '????????????' | 'llint';
//?????????????????????
//Type_UnsignedByte: '???????????????';
//Type_UnsignedInt: '???????????????';
//Type_UnsignedLongInt: '??????????????????';
//Type_UnsignedShortInt: '??????????????????';
//Type_UnsignedLongLongInt: '?????????????????????';
Type_Boolean: '??????' | 'bool';
Type_ShortFloat: '???????????????' | 'sdec'; //half
Type_Float: '??????' | 'dec'; //float
Type_LongFloat: '???????????????' | 'ldec'; //double
Type_LongLongFloat: '??????????????????' | 'lldec'; //fp128
Type_String: '?????????' | '??????' | 'string';

//?????????
literal: INT | DEC
    | BOOL
    | STRING ;

//????????????
INT: INT10 | INT8 | INT16 | INT2 ;
//??????
INT10: [1-9][0-9]+ | [0-9];
INT8: '0'[1-8][0-8]+ | '0'[0-8];
INT16: ('0x'|'0X')[0-9a-f]+;
INT2: ('0b'|'0B')[01]+;
//??????
DEC: INT10 '.' [0-9]+;

//?????????
BOOL: '???' | '???' | 'true' | 'false';

//?????????
STRING: ('???' | '"') (ESCAPE_CHARS | ~[\\])*? ('???' | '"')
    | ('???' | '\'') (ESCAPE_CHARS | ~[\\])*? ('???' | '\'');
//??????????????????
ESCAPE_CHARS: '\\\\' | '\\???' | '\\???' | '\\???' | '\\???' | '\\a' | '\\b' | '\\f' | '\\n' | '\\r' | '\\t' | '\\v' | '\\"' | '\\\'';

//ID?????????
// $
ID: IDStart IDPart*;
IDStart: ~([0-9 @[\]\-+=()*&^%!~`?<>,.:;"'\\|???#??????{}??????????????????/????????????????????????????????\r\n]);
IDPart: ~([ @[\]\-+=()*&^%!~`?<>,.:;"'\\|???#??????{}??????????????????/????????????????????????????????\r\n]);

