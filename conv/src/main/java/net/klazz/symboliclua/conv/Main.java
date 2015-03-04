// Copyright (c) 2015 Kohsuke Yatoh. All rights reserved.
// Licensed under the MIT License <http://opensource.org/licenses/MIT>.
package net.klazz.symboliclua.conv;

import org.antlr.v4.runtime.ANTLRInputStream;
import org.antlr.v4.runtime.CommonTokenStream;

public class Main {
    public static void main( String[] args ) {
        try {
            ANTLRInputStream in = new ANTLRInputStream(System.in);
            LuaLexer l = new LuaLexer(in);
            CommonTokenStream stream = new CommonTokenStream(l);
            LuaParser p = new LuaParser(stream);
            System.out.println(new Converter(stream).visit(p.chunk()));
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }
}
