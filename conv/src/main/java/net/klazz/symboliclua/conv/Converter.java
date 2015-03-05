// Copyright (c) 2015 Kohsuke Yatoh. All rights reserved.
// Licensed under the MIT License <http://opensource.org/licenses/MIT>.
package net.klazz.symboliclua.conv;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import net.klazz.symboliclua.conv.LuaParser.ComparisonOpExpContext;
import net.klazz.symboliclua.conv.LuaParser.SymbolContext;

import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.misc.Interval;
import org.antlr.v4.runtime.tree.ParseTree;
import org.antlr.v4.runtime.tree.RuleNode;
import org.antlr.v4.runtime.tree.TerminalNode;

public class Converter extends LuaBaseVisitor<String> {
    private final static Map<String, String> OPERATORS = new HashMap<>();;
    private CommonTokenStream mStream;

    static {
        OPERATORS.put("==", "eq");
        OPERATORS.put("~=", "ne");
        OPERATORS.put("<", "lt");
        OPERATORS.put("<=", "le");
        OPERATORS.put(">", "gt");
        OPERATORS.put(">=", "ge");
    }

    public Converter(CommonTokenStream stream) {
        mStream = stream;
    }

    @Override
    public String visitChildren(RuleNode node) {
        StringBuilder builder = new StringBuilder();
        List<String> spaces = whitespaces(node);
        for (int i = 0; i < node.getChildCount(); i++) {
            builder.append(spaces.get(i));
            builder.append(super.visit(node.getChild(i)));
        }
        builder.append(spaces.get(node.getChildCount()));
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

    @Override
    public String visitComparisonOpExp(ComparisonOpExpContext ctx) {
        StringBuilder builder = new StringBuilder();
        List<String> spaces = whitespaces(ctx);
        builder.append(spaces.get(0));
        builder.append("symbolic.");
        builder.append(OPERATORS.get(ctx.getChild(1).getText()));
        builder.append("(");
        builder.append(visit(ctx.getChild(0)));
        builder.append(spaces.get(1));
        builder.append(",");
        builder.append(spaces.get(2));
        builder.append(visit(ctx.getChild(2)));
        builder.append(")");
        builder.append(spaces.get(3));
        return builder.toString();
    }

    private List<String> whitespaces(RuleNode node) {
        List<String> ret = new ArrayList<>();
        Interval interval = node.getSourceInterval();
        int a = node.getParent() == null ? 0 : interval.a;
        int b = node.getParent() == null ? mStream.size() - 1 : interval.b;
        for (int i = 0; i < node.getChildCount(); i++) {
            ParseTree c = node.getChild(i);
            Interval v = c.getSourceInterval();
            ret.add(a < v.a ? mStream.getText(new Interval(a, v.a-1)) : "");
            a = v.b + 1;
        }
        ret.add(a <= b ? mStream.getText(new Interval(a, b)) : "");
        return ret;
    }
}
