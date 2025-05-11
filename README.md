# Mini Compiler using Lex and Yacc

## 📌 Project Overview
This project presents the **design and implementation of a simplified compiler** for a custom programming language. It showcases the use of **Lex (Flex)** for lexical analysis and **Yacc (Bison)** for syntax and semantic analysis. The compiler supports variable declarations, assignments, arithmetic/logical operations, and conditional statements.

## 🔧 Tools & Technologies
- **Lex/Flex** – for tokenizing input using regular expressions  
- **Yacc/Bison** – for defining grammar rules and semantic actions  
- **C/C++** – for compiling and executing the parser  
- **Linux/GCC** – development and testing environment  

## 🧠 Key Features
- Tokenization of keywords, operators, and identifiers  
- Parsing of expressions: arithmetic, relational, logical  
- Support for prefix/postfix operations and signed values  
- **Symbol table** management with type validation  
- **Error handling** for undeclared or misused variables  
- Generation of an **Abstract Syntax Tree (AST)** for valid input  

## 📁 Project Structure
* `prob.l` # Lex file: defines tokens using regex
* `prob.y` # Yacc file: contains CFG and semantic actions
* `Report.pdf` # Deatiled Report of how project works
* `Makefile` #  Automates build
* `inp` #test input files
* `README.md` # Project documentation


## 🚀 How to Run
1. Install required tools:
   ```bash
   sudo apt install flex bison gcc
