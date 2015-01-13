package haxe.languageservices.grammar;

import haxe.languageservices.node.Reader;
import haxe.languageservices.node.Const;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.node.Node;
import haxe.languageservices.grammar.Grammar;
import haxe.languageservices.grammar.Grammar.Term;

class HaxeGrammar extends Grammar<Node> {
    public var ints:Term;
    public var fqName:Term;
    public var packageDecl:Term;
    public var importDecl:Term;
    public var usingDecl:Term;
    public var expr:Term;
    public var program:Term;
    
    private function buildNode(name:String): Dynamic -> Dynamic {
        return function(v) return Type.createEnum(Node, name, v);
    }

    private function buildNode2(name:String): Dynamic -> Dynamic {
        return function(v) return Type.createEnum(Node, name, [v]);
    }
    
    override private function simplify(znode:ZNode):ZNode {
        switch (znode.node) {
            case NAccessList(node, accessors):
                switch (accessors.node) {
                    case Node.NList([]): return node;
                    default:
                }
            default:
        }
        return znode;
    }
    
    private function operator(v:Dynamic):Term {
        return term(v, buildNode2('NOp'));
    }
    
    private function optError2(tok:String) {
        return optError(tok, 'expected $tok');
    }

    private function litS(z:String) return Term.TLit(z, function(v) return Node.NId(z));

    public function new() {
        function rlist(v) return Node.NList(v);
        //function rlist2(v) return Node.NListDummy(v);


        var int = Term.TReg('int', ~/^\d+/, function(v) return Node.NConst(Const.CInt(Std.parseInt(v))));
        var identifier = Term.TReg('identifier', ~/^[a-zA-Z]\w*/, function(v) return Node.NId(v));
        fqName = list(identifier, '.', function(v) return Node.NIdList(v));
        ints = list(int, ',', function(v) return Node.NConstList(v));
        packageDecl = seq(['package', fqName, optError2(';')], buildNode('NPackage'));
        importDecl = seq(['import', fqName, optError2(';')], buildNode('NImport'));
        usingDecl = seq(['using', fqName, optError2(';')], buildNode('NUsing'));
        expr = createRef();
        //expr.term
        var ifExpr = seq(['if', sure(), '(', expr, ')', expr, opt(seqi(['else', expr]))], buildNode('NIf'));
        var forExpr = seq(['for', sure(), '(', identifier, 'in', expr, ')', expr], buildNode('NFor'));
        var whileExpr = seq(['while', sure(), '(', expr, ')', expr], buildNode('NWhile'));
        var doWhileExpr = seq(['do', sure(), expr, 'while', '(', expr, ')', optError2(';')], buildNode('NDoWhile'));
        var breakExpr = seq(['break', sure(), optError2(';')], buildNode('NBreak'));
        var continueExpr = seq(['continue', sure(), optError2(';')], buildNode('NContinue'));
        var returnExpr = seq(['return', sure(), opt(expr), optError2(';')], buildNode('NReturn'));
        var blockExpr = seq(['{', list(expr, ';', rlist), '}'], buildNode2('NBlock'));
        var parenExpr = seqi(['(', expr, optError2(')')]);
        var constant = any([ int, identifier ]);
        var type = createRef();

        var optType = opt(seq([':', type], identity));

        var typeName = seq([identifier, optType], buildNode('NIdWithType'));
        var typeNameList = list(typeName, ',', rlist);
        
        setRef(type, any([
            identifier,
            seq([ '{', typeNameList, '}' ], rlist),
        ]));
        
        var varDecl = seq(['var', sure(), identifier, optType, opt(seqi(['=', expr])), optError(';', 'expected semicolon')], buildNode('NVar'));
        var objectItem = seq([identifier, ':', expr], buildNode('NObjectItem'));

        var arrayExpr = seq(['[', list(expr, ',', rlist), ']'], buildNode2('NArray'));
        var objectExpr = seq(['{', list(objectItem, ',', rlist), '}'], buildNode2('NObject'));
        var literal = any([ constant, arrayExpr, objectExpr ]);
        var unaryOp = any([operator('++'), operator('--'), operator('+'), operator('-')]);
        var binaryOp = any(['+', '-', '*', '/', '%', '==', '!=', '<', '>', '<=', '>=', '&&', '||']);
        var primaryExpr = createRef();
        
        var unaryExpr = seq([unaryOp, primaryExpr], buildNode("NUnary"));
        //var binaryExpr = seq([primaryExpr, binaryOp, expr], identity);
    
        var exprCommaList = list(expr, ',', rlist);

        var arrayAccess = seq(['[', expr, ']'], buildNode('NAccess'));
        var fieldAccess = seq(['.', identifier], buildNode('NAccess'));
        var callPart = seq(['(', exprCommaList, ')'], buildNode('NCall'));
        var binaryPart = seq([binaryOp, expr], buildNode('NBinOpPart'));

        setRef(primaryExpr, any([
            parenExpr,
            unaryExpr,
            seq(['new', identifier, callPart], buildNode('NNew')),
            seq(
                [constant, list2(any([fieldAccess, arrayAccess, callPart, binaryPart]), rlist)],
                buildNode('NAccessList')
            ),
        ]));

        setRef(expr, any([
            varDecl,
            ifExpr,
            forExpr,
            whileExpr,
            doWhileExpr,
            breakExpr,
            continueExpr,
            returnExpr,
            blockExpr,
            primaryExpr,
            literal,
        ]));
        
        var typeParamItem = type;
        var typeParamDecl = seq(['<', list(typeParamItem, ',', rlist), '>'], buildNode2('NTypeParams'));
        
        var memberModifier = any([litS('static'), litS('public'), litS('private'), litS('override')]);
        var functionDecl = seq(['function', sure(), identifier, '(', ')', expr], buildNode('NFunction'));
        var memberDecl = seq([opt(list2(memberModifier, rlist)), any([varDecl, functionDecl])], buildNode('NMember'));
        
        var extendsDecl = seq(['extends', sure(), type], buildNode('NExtends'));
        var implementsDecl = seq(['implements', sure(), type], buildNode('NImplements'));
        
        var extendsImplementsList = list2(any([extendsDecl, implementsDecl]), rlist);
        
        var classDecl = seq(
            ['class', sure(), identifier, opt(typeParamDecl), opt(extendsImplementsList), '{', list2(memberDecl, rlist), '}'],
            buildNode('NClass')
        );
        var interfaceDecl = seq(
            ['interface', sure(), identifier, opt(typeParamDecl), opt(extendsImplementsList), '{', list2(memberDecl, rlist), '}'],
            buildNode('NInterface')
        );
        var typedefDecl = seq(
            ['typedef', sure(), identifier, '=', type],
            buildNode('NTypedef')
        );

        var enumDecl = seq(
            ['enum', sure(), identifier, '{', '}'],
            buildNode('NEnum')
        );

        var typeDecl = any([classDecl, interfaceDecl, typedefDecl, enumDecl]);

        program = list2(any([packageDecl, importDecl, usingDecl, typeDecl]), buildNode2('NFile'));
    }

    private var spaces = ~/^\s+/;
    override private function skipNonGrammar(str:Reader) {
        str.matchEReg(spaces);
    }
}
