%{
#include<stdio.h>
#include<stdbool.h>
#include<string.h>
#include<stdlib.h>
#include<limits.h>
#include<float.h>

int yylex();
void yyerror(char*);
int yyparse();
extern FILE * yyin;
int eflag = 0;
int tindex=0;
int lindex=0; 
int address = 100;
char str[1024];
char* errorBuffer[1024];


int curScope = 0;
int siblingScope = 0;
int offset = 0;
int errorIndex = 0;
int lexdIndex = 0;
char currentVariableType[100];
int currentVariableTypeSize = 0;

struct typeDetails{
	char* type;
	int size;
};

struct lexemeDetails{
	char* type;
	char* address;
	char* name;
	int scope;
	int siblingScope;
};

typedef struct Node {
	char* key;
	struct lexemeDetails value;
	struct Node* next;
} Node;

typedef struct HashMap {
	Node** keys;
	int hashSize;
	int size;
} HashMap;

char* genLabel();
char* genBlockLabel();
void generateCode(char* , char* , char*, char*);
void generateAssignCode(char* , char* , char*);
void generateDeclareCode(char* , char* , char*);
void generateNotCode(char* , char*);
int hashFunction(char*, int);
HashMap* createHashMap(int);
void insert(HashMap*, char*, struct lexemeDetails);
struct lexemeDetails get(HashMap*, char*);
bool existsInHashMap(HashMap*, char*);
HashMap* HT;
struct lexemeDetails lexd[100];
char* intToHex(int);
%}

%name parser

%start HEADER

%token HEAD STDIO STDLIB STRING
%token MAIN
%token RETURN
%token VOID
%token IF ELSE WHILE FOR
%token ADD SUB MUL DIV MOD ASSIGN 
%token LT LTE GT GTE EQ NE 
%token NOT AND OR 
%token INCREMENT DECREMENT 
%token LP RP LC RC COLON SEMICOLON COMMA
%token ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN
%token <addr> NUMBER
%token <addr> ID
%token <addr> INT
%token <addr> FLOAT
%token <addr> CHAR

%nonassoc LT GT LTE GTE NOT ASSIGN
%nonassoc OR
%nonassoc AND
%left ADD SUB
%left MUL DIV MOD
%right LP RP 
%right LC RC
%right ADD_ASSIGN SUB_ASSIGN MUL_ASSIGN DIV_ASSIGN
%nonassoc INCREMENT DECREMENT

%union{
	char lexeme[200];
	char addr[200];
	char* lab;
	struct typeDetails* td;
	struct lexemeDetails* lxd;
}	

%type <addr> HEADER
%type <addr> Program
%type <addr> ProgramBlock
%type <addr> Block
%type <addr> StatementList
%type <addr> Statement
%type <addr> DeclarationStatement
%type <addr> AssignmentStatement
%type <addr> IfStatement
%type <addr> ElseStmt
%type <addr> WhileStatement
%type <addr> ForStatement
%type <addr> L
%type <addr> PREREL
%type <addr> RELEXP
%type <addr> EXPRESSION
%type <addr> TERM
%type <addr> FACTOR
%type <addr> Val
%type <td> Type
%type <lab> dummyLabels

%%
HEADER:
	HEAD STDIO Program {  }
	| HEAD STDLIB Program {  }
	| HEAD STRING Program {  }
	;

Program:
	INT MAIN LP RP ProgramBlock { }
	| INT MAIN LP VOID RP ProgramBlock { }
	| { }
	;

ProgramBlock:
	Block ProgramBlock { }
	| { }
	
Block:
    LC { curScope++; siblingScope++; offset = 0; } StatementList RC { curScope--; }
	; 

StatementList:
	Statement StatementList { }
	| { }
	;

Statement:
	DeclarationStatement SEMICOLON { }
	| AssignmentStatement SEMICOLON { }
	| Block { }
	| IfStatement { }
	| WhileStatement { }
	| ForStatement { }
	;

DeclarationStatement:
	Type L { strcpy(currentVariableType, ""); }

AssignmentStatement:
	ID ASSIGN AssignmentStatement { generateAssignCode($1, $3, $$); }
	| EXPRESSION { strcpy($$, $1); }
	| {  }
	;

L:
 	ID { defineIdentifierType($1); }
 	| ID ASSIGN AssignmentStatement { generateDeclareCode($1, $3, $$); }
	;

IfStatement:
	IF LP PREREL RP dummyLabels dummyLabels dummyLabels{
		printf("\n%d:\tif %s goto %s", address, $3, $5);
        address++;
        printf("\n%d:\tgoto %s", address, $6);
        address++;
		printf("\n%d:\t%s:", address, $5);
        address++;
	} Block { 
		printf("\n%d:\tgoto %s", address, $7);
        address++;
		printf("\n%d:\t%s:", address, $6);
        address++;
	} ElseStmt { 
        printf("\n%d:\t%s:", address, $7);
        address++;
    }
	;

ElseStmt:
	ELSE Statement { }
	| { }
	;

dummyLabels:
	{ $$ = (char*)malloc(100*sizeof(char)); $$ = genBlockLabel(); }
	;

WhileStatement:
	dummyLabels { printf("\n%d:\t%s:", address, $1); address++; } WHILE LP PREREL RP dummyLabels dummyLabels { 
        printf("\n%d:\tif %s goto %s", address, $5, $7);
        address++;
        printf("\n%d:\tgoto %s", address, $8);
        address++;
        printf("\n%d:\t%s:", address, $7);
        address++;
	} Block { 
        printf("\n%d:\tgoto %s", address, $1); 
        address++;
        printf("\n%d:\t%s:", address, $8);
        address++;
	}
	;

ForStatement:
	dummyLabels dummyLabels dummyLabels dummyLabels FOR LP AssignmentStatement SEMICOLON { printf("\n%d:\t%s:", address, $1); address++; }
	PREREL { 
		printf("\n%d:\tif %s goto %s", address, $10, $3); 
		address++; 
		printf("\n%d:\tgoto %s", address, $4);
		address++;
	} SEMICOLON { printf("\n%d:\t%s:", address, $2); address++; } AssignmentStatement { 
		printf("\n%d:\tgoto %s", address, $1);
		address++;
	} RP { printf("\n%d:\t%s:", address, $3); address++; } 
	Block { 
		printf("\n%d:\tgoto %s", address, $2);
		address++;
		printf("\n%d:\t%s:", address, $4); 
		address++; 
	}
	;

PREREL:
	PREREL AND RELEXP { generateCode(" && ", $1, $3, $$); }
    | PREREL OR RELEXP { generateCode(" || ", $1, $3, $$); }
	| RELEXP { strcpy($$, $1); }
	| EXPRESSION { strcpy($$, $1); }
	| {  }
	;

RELEXP:
    EXPRESSION LT EXPRESSION { generateCode(" < ", $1, $3, $$); }
	| EXPRESSION LTE EXPRESSION { generateCode(" <= ", $1, $3, $$); }
    | EXPRESSION GT EXPRESSION { generateCode(" > ", $1, $3, $$); }
	| EXPRESSION GTE EXPRESSION { generateCode(" >= ", $1, $3, $$); }
	| EXPRESSION EQ EXPRESSION { generateCode(" == ", $1, $3, $$); }
    | EXPRESSION NOT EQ EXPRESSION { generateCode(" != ", $1, $4, $$); }             
    | NOT LP PREREL RP { generateNotCode($3, $$); }
	| error { yyerror("Invalid Comparator\n"); yyerrok; exit(1); }
	// | {  }
	;

EXPRESSION:
    EXPRESSION ADD TERM { generateCode(" + ", $1, $3, $$); }
	| EXPRESSION SUB TERM { generateCode(" - ", $1, $3, $$); }
    | TERM { strcpy($$, $1); }
    ;

TERM:
    TERM MUL FACTOR { generateCode(" * ", $1, $3, $$); }
	| TERM DIV FACTOR { generateCode(" / ", $1, $3, $$); }
    | TERM MOD FACTOR { generateCode(" % ", $1, $3, $$); }
    | FACTOR { strcpy($$, $1); }
	;

FACTOR:
    ADD Val { strcpy($$, " + "); strcat($$, $2); }
	| SUB Val { strcpy($$, " - "); strcat($$, $2); }
    | Val { strcpy($$, $1); }
    ;

Val:
    ID { strcpy($$, $1); check($1); }
    | NUMBER { strcpy($$, $1); }
    | INCREMENT ID { handleUnaryOperations($$,$2," + "); }
	| DECREMENT ID { handleUnaryOperations($$,$2," - "); }
	| ID INCREMENT { handleUnaryOperations($$,$1," + "); }
	| ID DECREMENT { handleUnaryOperations($$,$1," - "); }
    | LP EXPRESSION RP { strcpy($$, $2); }
	| LP EXPRESSION error RP { yyerror(") Missing\n"); yyerrok; exit(1); }
	;

Type:
    INT { allocate($$,"int",4); }
    | FLOAT { allocate($$,"float",4); }
    | CHAR { allocate($$,"char",1); }
    ;
%%

void allocate(struct typeDetails* root, char* type, int size) {
	root = (struct typeDetails*)malloc(sizeof(struct typeDetails));
	root->type = (char*)malloc(1000*sizeof(char));
	strcpy(root->type, type);
	strcpy(currentVariableType, type);
	currentVariableTypeSize = size;
	root->size = size;
}

void defineIdentifierType(char* arg) {
	struct lexemeDetails lexData;
	lexData.name = (char*)malloc(1000*sizeof(char));
	strcpy(lexData.name, arg);
	lexData.type = (char*)malloc(1000*sizeof(char));
	strcpy(lexData.type, currentVariableType);
	lexData.scope = curScope;
	lexData.siblingScope = siblingScope;
	lexData.address = (char*)malloc(1000*sizeof(char));
	lexData.address = intToHex(offset);
	offset += currentVariableTypeSize;	
	struct lexemeDetails ld = get(HT, arg);
	if(existsInHashMap(HT, arg) && ld.scope == curScope && ld.siblingScope == siblingScope) {
		if(strcmp(lexData.type, ld.type) != 0) conflictingTypes(arg);
		else varExists(arg);
	}
	else {
		insert(HT, arg, lexData);
		lexd[lexdIndex++] = lexData;
	}
}

void varExists(char* id) {
	char* err = (char*)malloc(sizeof(char)*1000);
	strcpy(err, "Error: Redeclaration of ");
	strcat(err, id);
	strcpy(errorBuffer[errorIndex], err);
	errorIndex++;
	printf("\nError: Redeclaration of %s", id);
}

void varDoesNotExist(char* id) {
	char* err = (char*)malloc(sizeof(char)*1000);
	strcpy(err, "Error: ");
	strcat(err, id);
	strcat(err, " is undeclared in this scope");
	strcpy(errorBuffer[errorIndex], err);
	errorIndex++;
	printf("\nError: %s is undeclared in this scope", id);
}

void conflictingTypes(char* id) {
	char* err = (char*)malloc(sizeof(char)*1000);
	strcpy(err, "Error: Conflicting types for ");
	strcat(err, id);
	strcpy(errorBuffer[errorIndex], err);
	errorIndex++;
	printf("\nError: Conflicting types for %s", id);
}

void logerrorBuffer(){
	for(int i = 0; i < 100 && strcmp(errorBuffer[i], "-1") != 0; i++)
		printf("%s\n", errorBuffer[i]);
}

void SymbolTable(){
	printf("\n\nSymbol Table:\n");
	int logScope = 1;
	for(int i = 0; i < 100 && strcmp(lexd[i].name, "-1") != 0; i++){
		if(lexd[i].siblingScope != logScope){
			printf("\n");
			logScope = lexd[i].siblingScope;
		}
		printf("%s %s %s", lexd[i].address, lexd[i].name, lexd[i].type);
		printf("\n"); 
	}
}

void handleUnaryOperations(char* root, char* arg, char* op) {
	strcpy(root, arg);
	strcpy(str, root);
	strcat(str, " = ");
	strcat(str, arg);
	strcat(str, op);
	strcat(str, "1");
	printf("\n%d:\t%s", address, str);
	address++;
	check(arg);
}

void check(char* arg) {
	struct lexemeDetails ld = get(HT, arg);
	if(existsInHashMap(HT, arg)) {
		if(ld.scope > curScope) varDoesNotExist(arg);
		else if(ld.scope == curScope && ld.siblingScope != curScope) varDoesNotExist(arg);
	}
	else varDoesNotExist(arg);
}

void yyerror(char* s){
    printf("\nSyntax Error %s\n", s);
	eflag = 1;
	// exit(EXIT_FAILURE);
}

char* genLabel(){
    char* s = (char*)malloc(sizeof(char)*1000);
    char* label = (char*)malloc(sizeof(char)*1000);
    strcpy(s, "t");
    sprintf(label, "%d", tindex);
    strcat(s, label);
    tindex++;
    return s;
}

char* genBlockLabel(){
    char* s = (char*)malloc(sizeof(char)*1000);
    char* label = (char*)malloc(sizeof(char)*1000);
    strcpy(s, "L");
    sprintf(label, "%d", lindex);
    strcat(s, label);
    lindex++;
    return s;
}

void generateCode(char* op, char* arg1, char* arg2, char* root) {
    strcpy(root, genLabel());
    strcpy(str, root);
    strcat(str, " = ");
    strcat(str, arg1);
    strcat(str, op);
    strcat(str, arg2);
    printf("\n%d:\t%s", address, str);
    address++;
}

void generateAssignCode(char* arg1, char* arg2, char* root) {
	strcpy(root, arg1);
	strcpy(str, root);
	strcat(str, " = ");
	strcat(str, arg2);
	printf("\n%d:\t%s", address, str);
	address++;
	check(arg1);
}

void generateDeclareCode(char* arg1, char* arg2, char* root) {
	defineIdentifierType(arg1);
	strcpy(root, arg1);
	strcpy(str, root);
	strcat(str, " = ");
	strcat(str, arg2);
	printf("\n%d:\t%s", address, str);
	address++;
}

void generateNotCode(char* arg1, char* root) {
	strcpy(root, genLabel());
	strcpy(str, root);
	strcat(str, " = ");
	strcat(str, "!");
	strcat(str, "(");
	strcat(str, arg1);
	strcat(str, ")");
	printf("\n%d:\t%s", address, str);
	address++;
}
    
int hashFunction(char* key, int hashSize) {
	int hash = 0;
	int i;
	for (i = 0; key[i] != '\0'; i++) {
		hash = (hash * 31 + key[i]) % hashSize;
	}
	return hash;
}

HashMap* createHashMap(int hashSize) {
	HashMap* hashMap = (HashMap*)malloc(sizeof(HashMap));
	if (!hashMap) {
		return NULL;
	}
	hashMap->keys = (Node**)malloc(sizeof(Node*) * hashSize);
	if (!hashMap->keys) {
		free(hashMap);
		return NULL;
	}
	for (int i = 0; i < hashSize; i++) {
		hashMap->keys[i] = NULL;
	}
	hashMap->hashSize = hashSize;
	hashMap->size = 0;
	return hashMap;
}

void insert(HashMap* hashMap, char* key, struct lexemeDetails value) {
	int index = hashFunction(key, hashMap->hashSize);
	Node* newNode = (Node*)malloc(sizeof(Node));
	newNode->key = strdup(key);
	newNode->value = value;
	newNode->next = hashMap->keys[index];
	hashMap->keys[index] = newNode;
	hashMap->size++;
}

struct lexemeDetails get(HashMap* hashMap, char* key) {
	int index = hashFunction(key, hashMap->hashSize);
	Node* node = (Node*)malloc(sizeof(Node));
	node = hashMap->keys[index];
	while (node) {
		if (strcmp(node->key, key) == 0) {
		return node->value;
		}
		node = node->next;
	}
	struct lexemeDetails l; l.scope = -1;
	return l;
}

bool existsInHashMap(HashMap* hashMap, char* key) {
	struct lexemeDetails ld = get(hashMap, key);
	if(ld.scope == -1) return false;
	return true;	
}

char* intToHex(int offset){
	char* buf = (char*)malloc(sizeof(char)*1000);
	char* hex = (char*)malloc(sizeof(char)*1000);
	strcpy(hex, "0x");
	sprintf(buf, "%x", offset);
	int bufLen = strlen(buf);
	for(int i = 1; i <= 4 - bufLen; i++) strcat(hex, "0");
	strcat(hex, buf);
	return hex;
}

int main(int argc, char *argv[]){
	if(argc != 2){
        fprintf(stderr, "Usage: %s <input_file>\n", argv[0]);
        return 1;
    }
    yyin = fopen(argv[1], "r");
    if(yyin == NULL){
        fprintf(stderr, "Error opening the input file.\n");
        return 1;
    }
	HT = createHashMap(1000);
	for(int i = 0; i < 100; i++) {
		errorBuffer[i] = (char*)malloc(sizeof(char)*1000);
		strcpy(errorBuffer[i], "-1");
	}
	for(int i = 0; i < 100; i++){
		struct lexemeDetails temp;
		temp.name = (char*)malloc(sizeof(char)*1000);
		strcpy(temp.name, "-1");
		lexd[i] = temp;
	}
	yyparse();
	SymbolTable();
	fclose(yyin);
    return 0;
}
