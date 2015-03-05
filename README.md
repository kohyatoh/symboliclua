# SymbolicLua
Dynamic Symbolic Execution Engine for Lua

## Requirements
You need Lua 5.2, Java 7, Python 2.7, and z3py installed on your computer.

Tested only on Linux Mint 17.

## Build
You have to build `conv` before using SymbolicLua

    $ cd conv
    $ mvn assembly:single

## Usage

    $ bin/symboliclua.sh sample/sum.lua
