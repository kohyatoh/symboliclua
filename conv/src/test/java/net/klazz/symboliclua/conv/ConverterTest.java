// Copyright (c) 2015 Kohsuke Yatoh. All rights reserved.
// Licensed under the MIT License <http://opensource.org/licenses/MIT>.
package net.klazz.symboliclua.conv;

import static org.junit.Assert.*;

import org.antlr.v4.runtime.ANTLRInputStream;
import org.antlr.v4.runtime.CommonTokenStream;
import org.junit.Test;

public class ConverterTest {
    private LuaLexer lexer;
    private CommonTokenStream stream;
    private LuaParser parser;
    private Converter converter;

    private void parse(String code) {
        lexer = new LuaLexer(new ANTLRInputStream(code));
        stream = new CommonTokenStream(lexer);
        parser = new LuaParser(stream);
        converter = new Converter(stream);
    }

    @Test
    public void testSymbol() {
        parse("?");
        assertEquals("symbolic.value()", converter.visit(parser.exp()));
    }

    @Test
    public void testAdd() {
        parse("1+2");
        assertEquals("1+2", converter.visit(parser.exp()));
    }

    @Test
    public void testEq() {
        parse("1==2");
        assertEquals("symbolic.eq(1,2)", converter.visit(parser.exp()));
    }

    @Test
    public void testNe() {
        parse("1~=2");
        assertEquals("symbolic.ne(1,2)", converter.visit(parser.exp()));
    }

    @Test
    public void testSpaces() {
        parse(" 1 + \n 2\t");
        assertEquals(" 1 + \n 2\t", converter.visit(parser.exp()));
    }

    @Test
    public void testEqWithSpaces() {
        parse(" 1\t== \n\n 2\t");
        assertEquals(" symbolic.eq(1\t, \n\n 2)\t", converter.visit(parser.exp()));
    }
}
