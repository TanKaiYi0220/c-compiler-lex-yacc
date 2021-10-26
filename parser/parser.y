%{
    #include<stdio.h>
    #include<string.h>
    #include<stdlib.h>
    #include<ctype.h>
    #include"lex.yy.c"
    void yyerror(const char *s);
    int yylex();
    int yywrap();
    void add(char);
    void insert_type();
    int search(char *);
	void insert_type();
	void printtree(struct node*);
	void printTreeUtil(struct node*, int);
	void printInorder(struct node *);
    void check_declaration(char *);
	int check_types(char *, char *);
	char *get_type(char *);
	struct node* mknode(struct node *left, struct node *right, char *token);

    struct dataType {
        char * id_name;
        char * data_type;
        char * type;
        int line_no;
	} symbolTable[40];

    int count=0;
    int q;
	char type[10];
    extern int countn;
	struct node *head;
	int sem_errors=0;
	int temp_var=0;
	int label=0;
	int is_for=0;
	char buff[100];

	struct node { 
		struct node *left; 
		struct node *right; 
		char *token; 
	};

%}

%union { struct var_name { 
			char name[100]; 
			struct node* nd;
		} nam;

		struct var_name2 { 
			char name[100]; 
			struct node* nd;
			char type[5];
		} nam2; 

		struct var_name3 {
			char name[100];
			struct node* nd;
			char if_body[5];
			char else_body[5];
		} nam3;
	} 
%token VOID 
%token <nam> PRINTFF SCANFF INT FLOAT CHAR FOR IF ELSE TRUE FALSE NUMBER FLOAT_NUM ID LE GE EQ NE GT LT AND OR STR ADD MULTIPLY DIVIDE SUBTRACT UNARY INCLUDE RETURN 
%type <nam> headers main body return datatype statement arithmetic relop program else
%type <nam2> init value expression
%type <nam3> condition

%%

program: headers main '(' ')' '{' body return '}' { $2.nd = mknode($6.nd, $7.nd, "main"); $$.nd = mknode($1.nd, $2.nd, "program"); 
	head = $$.nd;
} 
;

headers: headers headers { $$.nd = mknode($1.nd, $2.nd, "headers"); }
| INCLUDE { add('H'); } { $$.nd = mknode(NULL, NULL, $1.name); }
;

main: datatype ID { add('K'); }
;

datatype: INT { insert_type(); }
| FLOAT { insert_type(); }
| CHAR { insert_type(); }
| VOID { insert_type(); }
;

body: FOR { add('K'); is_for = 1; } '(' statement ';' condition ';' statement ')' '{' body '}' { 
	struct node *temp = mknode($6.nd, $8.nd, "CONDITION"); 
	struct node *temp2 = mknode($4.nd, temp, "CONDITION"); 
	$$.nd = mknode(temp2, $11.nd, $1.name); 
	printf("%s", buff);
	printf("JUMP to %s\n", $6.if_body);
	printf("\nLABEL %s\n", $6.else_body);
}
| IF { add('K'); is_for = 0; } '(' condition ')' { printf("\nLABEL %s:\n", $4.if_body); } '{' body '}' { printf("\nLABEL %s:\n", $4.else_body); } else { 
	struct node *iff = mknode($4.nd, $8.nd, $1.name); 
	$$.nd = mknode(iff, $11.nd, "if-else"); 
	printf("GOTO next\n");
}
| statement ';' { $$.nd = $1.nd; }
| body body { $$.nd = mknode($1.nd, $2.nd, "statements"); }
| PRINTFF { add('K'); } '(' STR ')' ';' { $$.nd = mknode(NULL, NULL, "printf"); }
| SCANFF { add('K'); } '(' STR ',' '&' ID ')' ';' { $$.nd = mknode(NULL, NULL, "scanf"); }
;

else: ELSE { add('K'); } '{' body '}' { $$.nd = mknode(NULL, $4.nd, $1.name); }
| { $$.nd = NULL; }
;

condition: value relop value { 
	$$.nd = mknode($1.nd, $3.nd, $2.name); 
	if(is_for) {
		sprintf($$.if_body, "L%d", label++);
		printf("\nLABEL %s:\n", $$.if_body);
		printf("\nif NOT (%s %s %s) GOTO L%d\n", $1.name, $2.name, $3.name, label);
		sprintf($$.else_body, "L%d", label++);
	} else {
		printf("\nif (%s %s %s) GOTO L%d else GOTO L%d\n", $1.name, $2.name, $3.name, label, label+1);
		sprintf($$.if_body, "L%d", label++);
		sprintf($$.else_body, "L%d", label++);
	}
}
| TRUE { add('K'); $$.nd = NULL; }
| FALSE { add('K'); $$.nd = NULL; }
| { $$.nd = NULL; }
;

statement: datatype ID { add('V'); } init { 
	$2.nd = mknode(NULL, NULL, $2.name); 
	int t = check_types($1.name, $4.type); 
	if(t>0) { 
		if(t == 1) {
			struct node *temp = mknode(NULL, $4.nd, "inttofloat"); 
			$$.nd = mknode($2.nd, temp, "declaration"); 
		} else { 
			struct node *temp = mknode(NULL, $4.nd, "floattoint"); 
			$$.nd = mknode($2.nd, temp, "declaration"); 
		} 
	} 
	else if(t == -1) {
		$$.nd = mknode($2.nd, $4.nd, "declaration"); 
	}
	else { 
		$$.nd = mknode($2.nd, $4.nd, "declaration"); 
	} 
	printf("=\t %s\t %s\t\n", $2.name, $4.name);
}
| ID { check_declaration($1.name); } '=' expression {
	$1.nd = mknode(NULL, NULL, $1.name); 
	char *id_type = get_type($1.name); 
	if(id_type[0] != $4.type[0]) {
		if(id_type[0] == 'i') {
			struct node *temp = mknode(NULL, $4.nd, "floattoint");
			$$.nd = mknode($1.nd, temp, "="); 
		}
		else {
			struct node *temp = mknode(NULL, $4.nd, "inttofloat");
			$$.nd = mknode($1.nd, temp, "="); 
		}
	}
	else {
		$$.nd = mknode($1.nd, $4.nd, "="); 
	}
	printf("=\t %s\t %s\t\n", $1.name, $4.name);
}
| ID { check_declaration($1.name); } relop expression { $1.nd = mknode(NULL, NULL, $1.name); $$.nd = mknode($1.nd, $4.nd, $3.name); }
| ID { check_declaration($1.name); } UNARY { 
	$1.nd = mknode(NULL, NULL, $1.name); 
	$3.nd = mknode(NULL, NULL, $3.name); 
	$$.nd = mknode($1.nd, $3.nd, "ITERATOR");  
	if(!strcmp($3.name, "++")) {
		sprintf(buff, "+\t %s\t 1\t t%d\n=\t %s\t t%d\n", $1.name, temp_var, $1.name, temp_var++);
		//printf("+\t %s\t 1\t t%d\n", $1.name, temp_var);
	}
	else {
		sprintf(buff, "-\t %s\t 1\t t%d\n=\t %s\t t%d\n", $1.name, temp_var, $1.name, temp_var++);
		//printf("-\t %s\t 1\t t%d\n", $1.name, temp_var);
	}
	//printf("=\t %s\t t%d\n", $1.name, temp_var++);
}
| UNARY ID { 
	check_declaration($2.name); 
	$1.nd = mknode(NULL, NULL, $1.name); 
	$2.nd = mknode(NULL, NULL, $2.name); 
	$$.nd = mknode($1.nd, $2.nd, "ITERATOR"); 
	if(!strcmp($1.name, "++")) {
		sprintf(buff, "+\t %s\t 1\t t%d\n=\t %s\t t%d\n", $2.name, temp_var, $2.name, temp_var++);
		//printf("+\t %s\t 1\t t%d\n", $2.name, temp_var);
	}
	else {
		sprintf(buff, "-\t %s\t 1\t t%d\n=\t %s\t t%d\n", $2.name, temp_var, $2.name, temp_var++);
		//printf("-\t %s\t 1\t t%d\n", $2.name, temp_var);
	}
	//printf("=\t %s\t t%d\n", $2.name, temp_var++);
}
;

init: '=' value { $$.nd = $2.nd; sprintf($$.type, $2.type); strcpy($$.name, $2.name); }
| { sprintf($$.type, "null"); $$.nd = mknode(NULL, NULL, "NULL"); strcpy($$.name, "NULL"); }
;

expression: expression arithmetic expression { 
	if($1.type[0] == $3.type[0]) {
		sprintf($$.type, $1.type);
		$$.nd = mknode($1.nd, $3.nd, $2.name); 
	}
	else {
		sprintf($$.type, "float");
		if($1.type[0] == 'i') {
			struct node *temp = mknode(NULL, $1.nd, "inttofloat");
			$$.nd = mknode(temp, $3.nd, $2.name);
		}
		else {
			struct node *temp = mknode(NULL, $3.nd, "inttofloat");
			$$.nd = mknode($1.nd, temp, $2.name);
		}
	}
	sprintf($$.name, "t%d", temp_var);
	temp_var++;
	printf("%s\t %s\t %s\t %s\t\n", $2.name, $1.name, $3.name, $$.name);
}
| value { strcpy($$.name, $1.name); sprintf($$.type, $1.type); $$.nd = $1.nd; }
;

arithmetic: ADD 
| SUBTRACT 
| MULTIPLY
| DIVIDE
;

relop: LT
| GT
| LE
| GE
| EQ
| NE
;

value: NUMBER { strcpy($$.name, $1.name); sprintf($$.type, "int"); add('C'); $$.nd = mknode(NULL, NULL, $1.name); }
| FLOAT_NUM { strcpy($$.name, $1.name); sprintf($$.type, "float"); add('C'); $$.nd = mknode(NULL, NULL, $1.name); }
| ID { strcpy($$.name, $1.name); char *id_type = get_type($1.name); sprintf($$.type, id_type); check_declaration($1.name); $$.nd = mknode(NULL, NULL, $1.name); }
;

return: RETURN { add('K'); } value ';' { $1.nd = mknode(NULL, NULL, "return"); $$.nd = mknode($1.nd, $3.nd, "RETURN"); }
| { $$.nd = NULL; }
;

%%

int main() {
    yyparse();
    printf("\n\n");
	printf("\t\t\t\t\t\t\t\t PHASE 1: LEXICAL ANALYSIS \n\n");
	printf("\nSYMBOL   DATATYPE   TYPE   LINE NUMBER \n");
	printf("_______________________________________\n\n");
	int i=0;
	for(i=0; i<count; i++) {
		printf("%s\t%s\t%s\t%d\t\n", symbolTable[i].id_name, symbolTable[i].data_type, symbolTable[i].type, symbolTable[i].line_no);
	}
	for(i=0;i<count;i++) {
		free(symbolTable[i].id_name);
		free(symbolTable[i].type);
	}
	printf("\n\n");
	printf("\t\t\t\t\t\t\t\t PHASE 2: SYNTAX ANALYSIS \n\n");
	printtree(head); 
	printf("\n\n\n\n");
	printf("\t\t\t\t\t\t\t\t PHASE 3: SEMANTIC ANALYSIS \n\n");
	if(sem_errors>0) {
		printf("Semantic analysis completed with %d errors!", sem_errors);
	} else {
		printf("Semantic analysis completed with no errors");
	}
	printf("\n\n");
}

int search(char *type) {
	int i;
	for(i=count-1; i>=0; i--) {
		if(strcmp(symbolTable[i].id_name, type)==0) {
			return -1;
			break;
		}
	}
	return 0;
}

void check_declaration(char *c) {
    q = search(c);
    if(!q) {
        printf("ERROR: Line %d: Variable \"%s\" not declared before usage!\n", countn+1, c);
		sem_errors++;
        //exit(0);
    }
}

int check_types(char *type1, char *type2){
	if(!strcmp(type1, type2))
		return 0;
	if(!strcmp(type2, "null"))
		return -1;
	if(!strcmp(type1, "float"))
		return 1;
	return 2;
}

char *get_type(char *var){
	for(int i=0; i<count; i++) {
		// Insert proper equality check function
		// Handle case of use before declaration
		if(symbolTable[i].id_name[0] == var[0]) {
			return symbolTable[i].data_type;
		}
	}
}

void add(char c) {
    q=search(yytext);
	if(!q) {
		if(c == 'H') {
			symbolTable[count].id_name=strdup(yytext);
			symbolTable[count].data_type=strdup(type);
			symbolTable[count].line_no=countn;
			symbolTable[count].type=strdup("Header");
			count++;
		}
		else if(c == 'K') {
			symbolTable[count].id_name=strdup(yytext);
			symbolTable[count].data_type=strdup("N/A");
			symbolTable[count].line_no=countn;
			symbolTable[count].type=strdup("Keyword\t");
			count++;
		}
		else if(c == 'V') {
			symbolTable[count].id_name=strdup(yytext);
			symbolTable[count].data_type=strdup(type);
			symbolTable[count].line_no=countn;
			symbolTable[count].type=strdup("Variable");
			count++;
		}
		else if(c == 'C') {
			symbolTable[count].id_name=strdup(yytext);
			symbolTable[count].data_type=strdup("CONST");
			symbolTable[count].line_no=countn;
			symbolTable[count].type=strdup("Constant");
			count++;
		}
    }
    else if(c == 'V' && q) {
        printf("ERROR: Line %d: Multiple declarations of \"%s\" not allowed!\n", countn+1, yytext);
		sem_errors++;
    }
}

struct node* mknode(struct node *left, struct node *right, char *token) {	
	struct node *newnode = (struct node *)malloc(sizeof(struct node));
	char *newstr = (char *)malloc(strlen(token)+1);
	strcpy(newstr, token);
	newnode->left = left;
	newnode->right = right;
	newnode->token = newstr;
	return(newnode);
}

void printtree(struct node* tree) {
	//printTreeUtil(tree, 0);
	printf("\n\nInorder traversal of the Parse Tree is: \n\n");
	printInorder(tree);
}

void printInorder(struct node *tree) {
	int i;
	if (tree->left) {
		printInorder(tree->left);
	}
	printf("%s, ", tree->token);
	if (tree->right) {
		printInorder(tree->right);
	}
}

void printTreeUtil(struct node *root, int space) {
    if(root == NULL)
        return;
    space += 7;
    printTreeUtil(root->right, space);
    for (int i = 7; i < space; i++)
        printf(" ");
	printf("%s\n", root->token);
    printTreeUtil(root->left, space);
}

void insert_type() {
	strcpy(type, yytext);
}

void yyerror(const char* msg) {
    fprintf(stderr, "%s\n", msg);
}