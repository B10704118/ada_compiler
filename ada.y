%{
#include <iostream>
#include <string>
#include <string.h>
#include <vector>
#include <fstream>
using namespace std;
extern FILE *yyin;
extern int lineNum;
void yyerror(string t) {
    cout <<"Line " << lineNum << ":" << t << endl;
}
extern int yylex();
extern "C"{
    int yywrap()
    {
        return 1;
    }
}

ofstream ofs;

#define ERROR -2
#define noType 0
#define BoolType 1
#define intType 2
#define strType 3
#define PRO_noType 7

int boolValue;	//暫存
int intValue; //暫存
string strValue = ""; //暫存
int indexCounter = 0;
string programID = ""; //存program id
int gotoCounter = 0;
int gotoCounter2 = 0;
int temp1,temp2;

class SymbolTable {
    public:
		int argNum;
        int symbolNum;
        string symbol[100];
        int symbolType[100];
		int const_or_not[100]; //const=1 variable=0 no type=-1
		int int_value[100];
		int bool_value[100];
		string str_value[100];
		int index[100];
        SymbolTable();
        void insert(string name, int type, int const_);
        int lookup(string name);
        int returnType;
};

SymbolTable::SymbolTable() {
	argNum=0;
    symbolNum=0;
    returnType=noType;
}

void SymbolTable::insert(string name, int type ,int const_) {
    symbol[symbolNum]=name;
    symbolType[symbolNum]=type;
	const_or_not[symbolNum]=const_;
    symbolNum++;
}

int SymbolTable::lookup(string name) {
    for(int i=0;i<symbolNum;i++){
		if(name.compare(symbol[i]) == 0){
			return i;
		}
	}
	return -1;  //找不到
}

SymbolTable *scope;
SymbolTable GLOB;
SymbolTable PROC;
int inPro;	//check if in procedure
vector<int> parameter;

%}

 /* tokens */
%token BGN BOOLEAN BREAK CHARACTER CASE CONTINUE CONSTANT DECLARE DO ELSE END EXIT 
%token FOR IF THEN IN INTEGER LOOP _PRINT _PRINTLN PROCEDURE PROGRAM STRING WHILE
%token AND OR NOT ASSIGN COMMA COLON PERIOD SEMICOLON LEFT_PARENTHESE RIGHT_PARENTHESE
%token LEFT_BRACKET RIGHT_BRACKET PLUS SUB MULTIPLY DIV MOD LESS LEQ RETURN
%token GRQ GREAT EQUAL NEQ TRUE FALSE
%left PLUS SUB MULTIPLY DIV MOD AND OR NOT
%left LESS LEQ GREAT GRQ EQUAL NEQ
%nonassoc UMINUS

%union {
    int boolVal;
    int intVal;
    char* stringVal;
}

%token <boolVal> BOOLEAN_VAL
%token <intVal> INT_VAL
%token <stringVal> STR_VAL
%token <stringVal> ID

%type <intVal> assignment_type constant_expr EXPR
%start S_PROGRAM

%%
		
S_PROGRAM: PROGRAM ID {
					inPro=0;	//global status
					scope=&GLOB;
					scope->insert($2, noType, -1);
					ofs << "class " << string($2) << "\n" << "{\n";
					programID=string($2);
				} DECLARATION
                PROC_DECLARATION {
					ofs << "method public static void main(java.lang.String[])\n";
					ofs << "max_stack 15\n";
					ofs << "max_locals 15\n{\n";
				}
                BGN
                STATEMENTS
                END SEMICOLON
                END ID {
					//check program ids are the same or not.
                    if(strcmp($2,$12) != 0){
                        yyerror("Program ID are not the same.");
                    }
					ofs << "return\n}\n}\n";
					ofs.close();
                }
				;

//zero or more variable and constant declarations
DECLARATION: 
                | DECLARE VARIABLE_DECLARE 
                ;

VARIABLE_DECLARE:
                |VARIABLE_DECLARE var_declare
                |VARIABLE_DECLARE const_declare
                ;
				
assignment_type: BOOLEAN     { $$ = BoolType; }
				| INTEGER     { $$ = intType; }
				| STRING    { $$ = strType; }
				;

constant_expr: BOOLEAN_VAL     { $$ = BoolType;boolValue=$1;}
                     | INT_VAL    { $$ = intType; intValue=$1;}
                     | STR_VAL { $$ = strType; strValue=$1;}
					 | TRUE { $$ = BoolType;boolValue=1;}
					 | FALSE { $$ = BoolType;boolValue=0;}
					 | ID { $$ = strType; strValue=$1;}
                     ;
					 
					 
// constant declare 
const_declare:  ID COLON CONSTANT ASSIGN constant_expr SEMICOLON {
					if (scope->lookup($1) == -1) {
						if($5==1){
							scope->bool_value[scope->symbolNum]=boolValue;
						}
						else if($5==2){
							scope->int_value[scope->symbolNum]=intValue;
						}
						else if($5==3){
							scope->str_value[scope->symbolNum]=strValue;
						}
                        scope->insert($1, $5, 1);
                    } else {
                        yyerror(string($1) + " : is already declared.");
                    }
				}
				| ID COLON CONSTANT COLON assignment_type ASSIGN constant_expr SEMICOLON {
					if (scope->lookup($1) == -1) {
						if($5==1){
							scope->bool_value[scope->symbolNum]=boolValue;
						}
						else if($5==2){
							scope->int_value[scope->symbolNum]=intValue;
						}
						else if($5==3){
							scope->str_value[scope->symbolNum]=strValue;
						}
                        scope->insert($1, $5, 1);
						if ($5 % 3 != $7 % 3) {
                            yyerror("These types are not the same.");
                        }
                    } else {
                        yyerror(string($1) + " : is already declared.");
                    }				
				}
				;
			
// variable declare
var_declare: variable_declare
			 ;

// variable declare      
variable_declare: ID SEMICOLON 
				{
                    if (scope->lookup($1) == -1){
						if(inPro==0){
							scope->insert($1, intType, 0);
							ofs << "field static int " << string($1) <<"\n";
						}
						else{
							scope->insert($1, intType, 0);
						}
						
                    } else {
                        yyerror(string($1) + " : is already declared.");
                    }
                }
				| ID COLON assignment_type SEMICOLON 
				{
					if (scope->lookup($1) == -1){    
						if(inPro==0){
							scope->insert($1, $3, 0);
							ofs << "field static int " << string($1) <<"\n";
						}
						else{
							scope->index[scope->symbolNum]=indexCounter;
							scope->int_value[scope->symbolNum]=intValue;
							scope->insert($1, $3, 0);
							indexCounter+=1;
						}
						
                    } else {
                        yyerror(string($1) + " : is already declared.");
                    }
                  
				}
                | ID ASSIGN constant_expr SEMICOLON 
				{
					if (scope->lookup($1) == -1){    
						if(inPro==0){
							scope->int_value[scope->symbolNum]=intValue;
							scope->insert($1, $3, 0);
							ofs << "field static int " << string($1) << " = " << to_string(intValue) << "\n";
						}
						else{
							scope->index[scope->symbolNum]=indexCounter;
							scope->int_value[scope->symbolNum]=intValue;
							scope->insert($1, $3, 0);
							ofs << "sipush " << to_string(intValue) <<"\n";
							ofs << "istore " << to_string(indexCounter) <<"\n";
							indexCounter+=1;
						}
						
                    } else {
                        yyerror(string($1) + " : is already declared.");
                    }
                  
				}
                | ID COLON assignment_type ASSIGN constant_expr SEMICOLON 
				{ 
					if (scope->lookup($1) == -1){    						
						if(inPro==0){
							scope->int_value[scope->symbolNum]=intValue;
							scope->insert($1, $3, 0);
							ofs << "field static int " << string($1) << " = " << to_string(intValue) << "\n";
						}
						else{
							scope->index[scope->symbolNum]=indexCounter;
							scope->int_value[scope->symbolNum]=intValue;
							scope->insert($1, $3, 0);
							ofs << "sipush " << to_string(intValue) <<"\n";
							ofs << "istore " << to_string(indexCounter) <<"\n";
							indexCounter+=1;
						}
                    } else {
                        yyerror(string($1) + " : is already declared.");
                    }
				}
				;

													
// <zero or more procedure declarations>
PROC_DECLARATION:
						|PROCEDURE ID 
						{
							inPro=1;
							if (scope->lookup($2) == -1) {
                                scope->insert($2, PRO_noType, -1);
								scope = &PROC;
                            } else {
								scope = &PROC;
                                yyerror("Procedure " + string($2) + " : is already declared.");
                            }
						}
						optional_formal_arguments optional_return_type {
							if(scope->returnType == noType){
								ofs << "method public static void " << string($2);
							}
							else if(scope->returnType == 2){
								ofs << "method public static int " << string($2);
							} 
							for(int i=0;i<scope->argNum;i++){
								if(i==0){
									ofs << "(int";
								}
								else{
									ofs << ", int";
								}
								if(i==scope->argNum-1){
									ofs << ")\n";
								}
							}
							ofs << "max_stack 15\n" << "max_locals 15\n" << "{\n";
						}
						block 
						END ID SEMICOLON
						{
							inPro=0;
							if(scope->returnType == 2){
								ofs << "ireturn\n";
							}
							else{
								ofs << "return\n";
							}
							scope = &GLOB;
							//check IDs of PROCEDURE are the same or not
							if(strcmp($2,$9) != 0){
								yyerror("Program ID are not the same.");
							}
							ofs << "}\n";
						}
						;
						
optional_formal_arguments: 
							| LEFT_PARENTHESE PRO_VAR RIGHT_PARENTHESE
							;
							
PRO_VAR: ID COLON assignment_type
		{
			int temp = scope->lookup($1);
			if (temp == -1) {
				scope->insert($1, $3, 0);
				scope->index[scope->symbolNum - 1]=indexCounter;
				scope->argNum++;
				indexCounter+=1;
			}
		}
		| ID COLON assignment_type SEMICOLON 
		{
			int temp = scope->lookup($1);
			if (temp == -1) {
				scope->insert($1, $3, 0);
				scope->index[scope->symbolNum - 1]=indexCounter;
				scope->argNum++;
				indexCounter+=1;
			}
			
		} PRO_VAR
		;
		
optional_return_type:
					| RETURN assignment_type
					{
						scope->returnType = $2;
					}
					;

block:  DECLARATION 
		BGN 
		STATEMENTS
		END SEMICOLON{  
					 };

// <zero or more statements>
STATEMENTS: 
		| ID ASSIGN EXPR SEMICOLON {
			int temp;
			if(inPro==0){
				temp = GLOB.lookup($1);
			}
			else{
				temp = PROC.lookup($1);
			}
			if(temp != -1){
				if(inPro==0){
					ofs << "putstatic int " << programID << "." << string($1) << "\n";
				}
				else{
					ofs << "istore " << PROC.index[temp] << "\n";
				}
			}
			else {
                yyerror(string($1) + " : does not declared.");
            }
        } STATEMENTS
        | _PRINT {
				ofs << "getstatic java.io.PrintStream java.lang.System.out\n";
			}	LEFT_PARENTHESE EXPR RIGHT_PARENTHESE SEMICOLON {
			if ($4 == ERROR) {
                yyerror("The type can not print.");
            } else{
				if($4==1){
					ofs << "invokevirtual void java.io.PrintStream.print(boolean)\n";
				}
				else if($4==2){
					ofs << "invokevirtual void java.io.PrintStream.print(int)\n";
				}
				else if($4==3){
					ofs << "invokevirtual void java.io.PrintStream.print(java.lang.String)\n";
				}				
			}			
        }STATEMENTS
        | _PRINT {
				ofs << "getstatic java.io.PrintStream java.lang.System.out\n";
			}EXPR SEMICOLON {
			if ($3 == ERROR) {
                yyerror("The type can not print.");
            } else{
				if($3==1){
					ofs << "invokevirtual void java.io.PrintStream.print(boolean)\n";
				}
				else if($3==2){
					ofs << "invokevirtual void java.io.PrintStream.print(int)\n";
				}
				else if($3==3){
					ofs << "invokevirtual void java.io.PrintStream.print(java.lang.String)\n";
				}
			}
        }STATEMENTS
        | _PRINTLN {
				ofs << "getstatic java.io.PrintStream java.lang.System.out\n";
			}LEFT_PARENTHESE EXPR RIGHT_PARENTHESE SEMICOLON {
			if ($4 == ERROR) {
                yyerror("The type can not print.");
            } else{
				if($4==1){
					ofs << "invokevirtual void java.io.PrintStream.println(boolean)\n";
				}
				else if($4==2){
					ofs << "invokevirtual void java.io.PrintStream.println(int)\n";
				}
				else if($4==3){
					ofs << "invokevirtual void java.io.PrintStream.println(java.lang.String)\n";
				}
			}
        }STATEMENTS
        | _PRINTLN  {
				ofs << "getstatic java.io.PrintStream java.lang.System.out\n";
			}EXPR SEMICOLON {
			if ($3 == ERROR) {
                yyerror("The type can not print.");
            } else{
				if($3==1){
					ofs << "invokevirtual void java.io.PrintStream.println(boolean)\n";
				}
				else if($3==2){
					ofs << "invokevirtual void java.io.PrintStream.println(int)\n";
				}
				else if($3==3){
					ofs << "invokevirtual void java.io.PrintStream.println(java.lang.String)\n";
				}
			}
        }STATEMENTS
        | RETURN EXPR SEMICOLON {
            if (scope->returnType % 4 != $2) {
				yyerror("Return types are not the same.");
			}
        }
		| RETURN SEMICOLON {
        }STATEMENTS
        | IF EXPR THEN{
			ofs << "ifeq W" << to_string(gotoCounter2)<<"\n";
		} block_statement {
			ofs << "goto W" << to_string(gotoCounter2 + 1)<<"\n";
			ofs <<"W"<< to_string(gotoCounter2)<<":\n";
		} ELSE block_statement END IF SEMICOLON {
			ofs <<"W"<< to_string(gotoCounter2 + 1)<<":\n";
			gotoCounter2+=2;
        } STATEMENTS
        | IF BOOL_EXPR THEN block_statement END IF SEMICOLON {
			
        }STATEMENTS
        | WHILE {
			ofs <<"W"<< to_string(gotoCounter2)<<":\n";
		}BOOL_EXPR LOOP {
			ofs << "ifeq W" << to_string(gotoCounter2+1)<<"\n";
		}block_statement END LOOP SEMICOLON {
			ofs << "goto W" << to_string(gotoCounter2)<<"\n";
			ofs << "W" << to_string(gotoCounter2+1)<<":\n";
			gotoCounter2+=2;
        }STATEMENTS
        | FOR LEFT_PARENTHESE ID IN EXPR2 {
			int temp;
			if(inPro==0){
				temp = GLOB.lookup($3);
			}
			else{
				temp = PROC.lookup($3);
			}
			temp1=intValue;
			ofs << "sipush " << to_string(temp1) << "\n";
			if(inPro==0){
				ofs << "putstatic int "<< programID <<"."<< string($3)<<"\n";
			}
			else{
				ofs << "istore " << PROC.index[temp] <<"\n";
			}
		}PERIOD PERIOD EXPR2 {
			int temp;
			if(inPro==0){
				temp = GLOB.lookup($3);
			}
			else{
				temp = PROC.lookup($3);
			}
			temp2=intValue;
			ofs <<"W"<< to_string(gotoCounter2)<<":\n";
			if(inPro==0){
				ofs << "getstatic int "<< programID <<"."<< string($3)<<"\n";
			}
			else{
				ofs << "iload " << PROC.index[temp] <<"\n";
			}
			ofs << "sipush " << to_string(temp2) << "\n";
			ofs << "isub\n";
			if (temp1<temp2){
				ofs << "ifle L" <<to_string(gotoCounter)<<"\n";
			}
			else if(temp1>temp2){
				ofs << "ifge L" <<to_string(gotoCounter)<<"\n";
			}
			ofs << "iconst_0\n";
			ofs << "goto L" << to_string(gotoCounter+1)<<"\n";
			ofs << "L" <<to_string(gotoCounter)<<":\n";
			ofs << "iconst_1\n";
			ofs << "L"<<to_string(gotoCounter+1)<<":\n";
			gotoCounter+=2;
		}RIGHT_PARENTHESE LOOP {
			ofs << "ifeq W" << to_string(gotoCounter2+1)<<"\n";
		}block_statement END LOOP SEMICOLON {
			int temp;
			if(inPro==0){
				temp = GLOB.lookup($3);
			}
			else{
				temp = PROC.lookup($3);
			}
			if (temp == -1) {
				yyerror(string($3) + " : does not declared.");
			}
			else{
				if(temp1<temp2){
					if(inPro == 0){
						ofs << "getstatic int "<< programID <<"."<< string($3)<<"\n";
						ofs << "sipush 1\n";
						ofs << "iadd\n";
						ofs << "putstatic int "<< programID <<"."<< string($3)<<"\n";
					}
					else {
						ofs << "iload " << PROC.index[temp] <<"\n";
						ofs << "sipush 1\n";
						ofs << "iadd\n";
						ofs << "istore " << PROC.index[temp] <<"\n";
					}
				}
				else if(temp1>temp2){
					if(inPro == 0){
						ofs << "getstatic int "<< programID <<"."<< string($3)<<"\n";
						ofs << "sipush 1\n";
						ofs << "isub\n";
						ofs << "putstatic int "<< programID <<"."<< string($3)<<"\n";
					}
					else {
						ofs << "iload " << PROC.index[temp] <<"\n";
						ofs << "sipush 1\n";
						ofs << "isub\n";
						ofs << "istore " << PROC.index[temp] <<"\n";
					}
				}
				ofs << "goto W" << to_string(gotoCounter2)<<"\n";
				ofs << "W" << to_string(gotoCounter2+1)<<":\n";
				gotoCounter2+=2;
			}
        } STATEMENTS
        | ID LEFT_PARENTHESE
		{
			parameter.clear();
		} ARG_LIST RIGHT_PARENTHESE SEMICOLON {
			int tempType;
			tempType = GLOB.lookup($1);
			if(tempType == -1){
				yyerror("Funcion " + string($1) + " : does not declared.");
			}
			else {
				int index=PROC.argNum;
				if (index != parameter.size()) {
                    yyerror("Funcion " + string($1) + " : parameter size is not match.");
                }
			}
			ofs << "invokestatic void " << programID << "." << string($1);
			for(int i=0;i<parameter.size();i++){
				if(i==0){
					ofs << "(int";
						}
				else{
					ofs << ", int";
				}
				if(i==parameter.size()-1){
					ofs << ")\n";
				}
			}			
        }STATEMENTS
		;
		
block_statement: block
				| STATEMENTS
				;
		
ARG_LIST: EXPR{
			parameter.push_back($1);
		}
		| EXPR COMMA ARG_LIST{
			parameter.push_back($1);
		}
		;
			
BOOL_EXPR: EXPR {
                    if ($1 != 1) {
                         yyerror("The type is not boolean.");
                    }
                }
                ;
		
EXPR: LEFT_PARENTHESE EXPR RIGHT_PARENTHESE{
        $$ = $2;
    }
	| SUB EXPR %prec UMINUS {
		if ($2 == 2){
			$$ = $2;
			ofs << "ineg\n";
		}
		else {
            $$ = ERROR;
            yyerror("This types can not use in operation UNARY.");
        }
    }
    | EXPR PLUS EXPR{
		if($1 == 2 && $3 == 2){
			$$ = $1;
			ofs << "iadd\n";
		}
		else{
			$$ = ERROR;
			yyerror("These types are not the same in operation PLUS.");
		}
    }
    | EXPR SUB EXPR {
        if($1 == 2 && $3 == 2){
			$$ = $1;
			ofs << "isub\n";
		}
		else{
			$$ = ERROR;
			yyerror("These types are not the same in operation SUB.");
		}
    }
    | EXPR MULTIPLY EXPR {
        if($1 == 2 && $3 == 2){
			$$ = $1;
			ofs << "imul\n";
		}
		else{
			$$ = ERROR;
			yyerror("These types are not the same in operation MULTIPLY.");
		}
    }
    | EXPR DIV EXPR {
        if($1 == 2 && $3 == 2){
			$$ = $1;
			ofs << "idiv\n";
		}
		else{
			$$ = ERROR;
			yyerror("These types are not the same in operation DIV.");
		}
    }
    | EXPR MOD EXPR{
        if($1 == 2 && $3 == 2){
			$$ = $1;
			ofs << "irem\n";
		}
		else{
			$$ = ERROR;
			yyerror("These types are not the same and are not both integer in operation MOD.");
		}
    }
    | EXPR LESS EXPR{
        if($1 == 2 && $3 == 2){
			$$ = 1;
			ofs << "isub\n";
			ofs << "iflt L"<< to_string(gotoCounter) << "\n";
			ofs << "iconst_0\n";
			ofs << "goto L"<< to_string(gotoCounter + 1) << "\n";
			ofs <<"L"<< to_string(gotoCounter) << ":\n";
			ofs << "iconst_1\n";
			ofs <<"L"<< to_string(gotoCounter+1) << ":\n";
			gotoCounter+=2;
		}
		else{
			$$ = ERROR;
			yyerror("These types can not use in operation LESS.");
		}
    }
    | EXPR LEQ EXPR{
        if($1 == 2 && $3 == 2){
			$$ = 1;
			ofs << "isub\n";
			ofs << "ifle L"<< to_string(gotoCounter) << "\n";
			ofs << "iconst_0\n";
			ofs << "goto L"<< to_string(gotoCounter + 1) << "\n";
			ofs <<"L"<< to_string(gotoCounter) << ":\n";
			ofs << "iconst_1\n";
			ofs <<"L"<< to_string(gotoCounter+1) << ":\n";
			gotoCounter+=2;
		}
		else{
			$$ = ERROR;
			yyerror("These types can not use in operation LEQ.");
		}
    }
    | EXPR EQUAL EXPR{
        if($1 == 1 && $3 == 1){
			$$ = 1;
			ofs << "isub\n";
			ofs << "ifeq L"<< to_string(gotoCounter) << "\n";
			ofs << "iconst_0\n";
			ofs << "goto L"<< to_string(gotoCounter + 1) << "\n";
			ofs <<"L"<< to_string(gotoCounter) << ":\n";
			ofs << "iconst_1\n";
			ofs <<"L"<< to_string(gotoCounter+1) << ":\n";
			gotoCounter+=2;
		}
		else{
			$$ = ERROR;
			yyerror("These types can not use in operation EQUAL.");
		}
    }
    | EXPR GREAT EXPR{
        if($1 == 2 && $3 == 2){
			$$ = 1;
			ofs << "isub\n";
			ofs << "ifgt L"<< to_string(gotoCounter) << "\n";
			ofs << "iconst_0\n";
			ofs << "goto L"<< to_string(gotoCounter + 1) << "\n";
			ofs <<"L"<< to_string(gotoCounter) << ":\n";
			ofs << "iconst_1\n";
			ofs <<"L"<< to_string(gotoCounter+1) << ":\n";
			gotoCounter+=2;
		}
		else{
			$$ = ERROR;
			yyerror("These types can not use in operation GREAT.");
		}
    }
    | EXPR GRQ EXPR{
        if($1 == 2 && $3 == 2){
			$$ = 1;
			ofs << "isub\n";
			ofs << "ifge L"<< to_string(gotoCounter) << "\n";
			ofs << "iconst_0\n";
			ofs << "goto L"<< to_string(gotoCounter + 1) << "\n";
			ofs <<"L"<< to_string(gotoCounter) << ":\n";
			ofs << "iconst_1\n";
			ofs <<"L"<< to_string(gotoCounter+1) << ":\n";
			gotoCounter+=2;
		}
		else{
			$$ = ERROR;
			yyerror("These types can not use in operation GRQ.");
		}
    }
    | EXPR NEQ EXPR{
        if($1 == 2 && $3 == 2){
			$$ = 1;
			ofs << "isub\n";
			ofs << "ifne L"<< to_string(gotoCounter) << "\n";
			ofs << "iconst_0\n";
			ofs << "goto L"<< to_string(gotoCounter + 1) << "\n";
			ofs <<"L"<< to_string(gotoCounter) << ":\n";
			ofs << "iconst_1\n";
			ofs <<"L"<< to_string(gotoCounter+1) << ":\n";
			gotoCounter+=2;
		}
		else{
			$$ = ERROR;
			yyerror("These types can not use in operation NEQ.");
		}
    }
    | EXPR AND EXPR{
        if($1 == 1 && $3 == 1){
			$$ = 1;
			ofs << "iand\n";
		}
		else{
			$$ = ERROR;
			yyerror("These types can not use in operation AND.");
		}
    }
    | EXPR OR EXPR{
        if($1 == 1 && $3 == 1){
			$$ = 1;
			ofs << "ior\n";
		}
		else{
			$$ = ERROR;
			yyerror("These types can not use in operation OR.");
		}
    }
    | EXPR NOT EXPR{
        if($1 == 1 && $3 == 1){
			$$ = 1;
			ofs << "ixor\n";
		} else {
            $$ = ERROR;
            yyerror("These types can not use in operation NOT.");
        }
    }
	| ID LEFT_PARENTHESE {
		parameter.clear();
	} ARG_LIST RIGHT_PARENTHESE {
		int tempType;
		tempType = GLOB.lookup($1);
		if(tempType == -1){
			$$=ERROR;
			yyerror("Funcion " + string($1) + " : does not declared.");
		}
		else {
			int index=PROC.argNum;
			if (index == parameter.size()) {
				if(PROC.returnType == noType){
					$$=ERROR;
					yyerror("Funcion " + string($1) + " : is a no return Procedure.");
				}
				else{
					$$ = PROC.returnType ;
				}
			} else {
				$$=ERROR;
                yyerror("Funcion " + string($1) + " : parameter size is not match.");
            }
			ofs << "invokestatic int " << programID << "." << string($1);
			for(int i=0;i<parameter.size();i++){
				if(i==0){
					ofs << "(int";
						}
				else{
					ofs << ", int";
				}
				if(i==parameter.size()-1){
					ofs << ")\n";
				}
			}
		}		
	}
    | ID {
		int temp;
		if(inPro==0){
			temp = GLOB.lookup($1);
		}
		else{
			temp = PROC.lookup($1);
		}
		if(temp != -1){
			if(inPro == 0){
				if(GLOB.const_or_not[temp] == 1){
					if(GLOB.symbolType[temp] == 1){
						if(GLOB.bool_value[temp] == 1){
							ofs << "iconst_1\n";
						}
						else{
							ofs << "iconst_0\n";
						}
						$$=1;
					}
					if(GLOB.symbolType[temp] == 2){
						ofs << "sipush " << to_string(GLOB.int_value[temp])<<"\n";
						$$=2;
					}
					if(GLOB.symbolType[temp] == 3){
						ofs << "ldc " << GLOB.str_value[temp]<<"\n";
						$$=3;
					}
				}
				else if(GLOB.const_or_not[temp] == 0){
					ofs << "getstatic int " << programID << "." <<GLOB.symbol[temp] << "\n";
					$$=2;
				}
			}
			else{
				if(PROC.const_or_not[temp] == 1){
					if(PROC.symbolType[temp] == 1){
						if(PROC.bool_value[temp] == 1){
							ofs << "iconst_1\n";
						}
						else{
							ofs << "iconst_0\n";
						}
						$$=1;
					}
					if(PROC.symbolType[temp] == 2){
						ofs << "sipush " << to_string(PROC.int_value[temp])<<"\n";
						$$=2;
					}
					if(PROC.symbolType[temp] == 3){
						ofs << "ldc " << PROC.str_value[temp]<<"\n";
						$$=3;
					}
				}
				else if(PROC.const_or_not[temp] == 0){
					ofs << "iload " << PROC.index[temp] <<"\n";
					$$=2;
				}
			}
		}
		else {
			$$=ERROR;
            yyerror(string($1) + " : does not declared.");
        }
    }
	| BOOLEAN_VAL { 
		$$ = BoolType; 
	}
	| INT_VAL { 
		$$ = intType; 
		ofs << "sipush " << to_string($1) <<"\n";
		intValue = $1;
	}
    | STR_VAL { 
		$$ = strType;
		ofs << "ldc " << string($1) <<"\n";
	}
	| TRUE { 
		$$ = BoolType; 
	}
	| FALSE { 
		$$ = BoolType; 
	}
	;

EXPR2: INT_VAL {
	intValue = $1;
}

%%

int main(int argc, char *argv[]){
    if(argc > 0){
        yyin = fopen(argv[1],"r");
    }
    else{
        yyin = stdin;
    }
    if(!yyin){
		printf("file not found.\n");
		return -1;
	}
	string fileName = string(argv[1]);
    fileName = fileName.substr(0, fileName.find_last_of('.'));
	ofs.open(fileName + ".jasm");
	if (!ofs.is_open()) {
		cout << "Failed to open file.\n";
	}
	yyparse();
	return 0;
}