// Copyright (c) 2015 Kohsuke Yatoh. All rights reserved.
// Licensed under the MIT License <http://opensource.org/licenses/MIT>.
package net.klazz.symboliclua.conv;

import net.klazz.symboliclua.conv.LuaParser.SymbolContext;

import org.antlr.v4.runtime.CommonTokenStream;

public class Converter extends LuaBaseVisitor<String> {
    private CommonTokenStream mStream;

    public Converter(CommonTokenStream stream) {
        mStream = stream;
    }

    @Override
    public String visitSymbol(SymbolContext ctx) {
        return "symbolic.value()";
    }

}
