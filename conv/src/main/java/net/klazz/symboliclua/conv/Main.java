// Copyright (c) 2015 Kohsuke Yatoh. All rights reserved.
// Licensed under the MIT License <http://opensource.org/licenses/MIT>.
package net.klazz.symboliclua.conv;

import org.antlr.v4.runtime.ANTLRInputStream;
import org.antlr.v4.runtime.CommonTokenStream;

public class Main {
    public static void main( String[] args ) {
        try {
            LuaLexer l = new LuaLexer(new ANTLRInputStream(System.in));
            LuaParser p = new LuaParser(new CommonTokenStream(l));
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }
}
