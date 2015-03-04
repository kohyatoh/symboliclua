// Copyright (c) 2015 Kohsuke Yatoh. All rights reserved.
// Licensed under the MIT License <http://opensource.org/licenses/MIT>.
package net.klazz.symboliclua.conv;

import net.klazz.symboliclua.conv.LuaParser.SymbolContext;

import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.tree.RuleNode;
import org.antlr.v4.runtime.tree.TerminalNode;

public class Converter extends LuaBaseVisitor<String> {
    private CommonTokenStream mStream;

    public Converter(CommonTokenStream stream) {
        mStream = stream;
    }

    @Override
    public String visitChildren(RuleNode node) {
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < node.getChildCount(); i++) {
            builder.append(super.visit(node.getChild(i)));
        }
        return builder.toString();
    }

    @Override
    public String visitTerminal(TerminalNode node) {
        return mStream.getText(node.getSourceInterval());
    }

    @Override
    public String visitSymbol(SymbolContext ctx) {
        return "symbolic.value()";
    }


}
