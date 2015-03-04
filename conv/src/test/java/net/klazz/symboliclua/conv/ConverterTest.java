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
}