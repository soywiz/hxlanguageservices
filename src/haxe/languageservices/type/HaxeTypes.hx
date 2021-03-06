package haxe.languageservices.type;

import haxe.languageservices.type.SpecificHaxeType;
import haxe.languageservices.completion.LocalScope;
import haxe.languageservices.node.Node;
import haxe.languageservices.node.Reader;
import haxe.languageservices.node.ZNode;
import haxe.languageservices.node.TextRange;

class HaxeTypes {
    public var rootPackage:HaxePackage;

    public var typeVoid(default, null):HaxeType;
    public var typeDynamic(default, null):HaxeType;
    public var typeUnknown(default, null):HaxeType;
    public var typeBool(default, null):HaxeType;
    public var typeInt(default, null):HaxeType;
    public var typeFloat(default, null):ClassHaxeType;
    public var typeString(default, null):HaxeType;
    public var typeClass(default, null):HaxeType;

    public var specTypeVoid(default, null):SpecificHaxeType;
    public var specTypeDynamic(default, null):SpecificHaxeType;
    public var specTypeUnknown(default, null):SpecificHaxeType;
    public var specTypeBool(default, null):SpecificHaxeType;
    public var specTypeInt(default, null):SpecificHaxeType;
    public var specTypeFloat(default, null):SpecificHaxeType;
    public var specTypeString(default, null):SpecificHaxeType;

    public var resultAnyDynamic(default, null):ExpressionResult;

    public var typeArray(default, null):HaxeType;

    public var dummyPosition:TextRange;
    public var dummyNode:ZNode;

    public function result(specType:SpecificHaxeType):ExpressionResult {
        return ExpressionResult.withoutValue(specType);
    }

    public function resultValue(specType:SpecificHaxeType, value:Dynamic):ExpressionResult {
        return ExpressionResult.withValue(specType, value);
    }

    private function anoRange(text:String) {
        return new Reader(text).createPos(0, text.length);
    }

    private function idNode(text:String) {
        return new ZNode(new Reader(text).createPos(0, text.length), Node.NId(text));
    }

    private function er(t:SpecificHaxeType) {
        return ExpressionResult.withoutValue(t);
    }

    public function new() {
        var typesPos = new TextRange(0, 0, new Reader('', '_Types.hx'));

        this.dummyPosition = typesPos;
        this.dummyNode = new ZNode(this.dummyPosition, Node.NId('dummy'));

        rootPackage = new HaxePackage(this, '');
        typeVoid = rootPackage.accessTypeCreate('Void', typesPos, ClassHaxeType);
        typeDynamic = rootPackage.accessTypeCreate('Dynamic', typesPos, ClassHaxeType);
        typeUnknown = rootPackage.accessTypeCreate('Unknown', typesPos, ClassHaxeType);
        typeBool = rootPackage.accessTypeCreate('Bool', typesPos, ClassHaxeType);
        typeInt = rootPackage.accessTypeCreate('Int', typesPos, ClassHaxeType);
        typeFloat = rootPackage.accessTypeCreate('Float', typesPos, ClassHaxeType);
        typeArray = rootPackage.accessTypeCreate('Array', typesPos, ClassHaxeType);
        typeString = rootPackage.accessTypeCreate('String', typesPos, ClassHaxeType);
        typeClass = rootPackage.accessTypeCreate('Class', typesPos, ClassHaxeType);

        //typeFloat.extending = new TypeReference(this, 'Int', dummyNode);

        specTypeVoid = createSpecific(typeVoid);
        specTypeDynamic = createSpecific(typeDynamic);
        specTypeUnknown = createSpecific(typeUnknown);
        specTypeBool = createSpecific(typeBool);
        specTypeInt = createSpecific(typeInt);
        specTypeFloat = createSpecific(typeFloat);
        specTypeString = createSpecific(typeString);

        resultAnyDynamic = ExpressionResult.withoutValue(specTypeDynamic);

        function nameNode(name:String) return new ZNode(typesPos, Node.NId(name));

        typeBool.addMember(new MethodHaxeMember(new FunctionHaxeType(this, typeBool, typeBool.pos, nameNode('testBoolMethod'), [], createReferenceName('Dynamic'))));
        typeBool.addMember(new MethodHaxeMember(new FunctionHaxeType(this, typeBool, typeBool.pos, nameNode('testBoolMethod2'), [], createReferenceName('Dynamic'))));
        typeInt.addMember(new MethodHaxeMember(new FunctionHaxeType(this, typeInt, typeInt.pos, nameNode('testIntMethod'), [], createReferenceName('Dynamic'))));
        typeInt.addMember(new MethodHaxeMember(new FunctionHaxeType(this, typeInt, typeInt.pos, nameNode('testIntMethod2'), [], createReferenceName('Dynamic'))));
        typeArray.addMember(new MethodHaxeMember(new FunctionHaxeType(this, typeArray, typeArray.pos, nameNode('indexOf'), [new FunctionArgument(this, 0, idNode('element'), new LocalScope(), er(specTypeDynamic))], createReferenceName('Int'))));
        typeArray.addMember(new MethodHaxeMember(new FunctionHaxeType(this, typeArray, typeArray.pos, nameNode('charAt'), [new FunctionArgument(this, 0, idNode('index'), new LocalScope(), er(specTypeInt))], createReferenceName('String'))));
    }
    
    public function createReference(fqNameNode:ZNode) {
        return TypeReference.create(this, fqNameNode);
    }

    public function createReferenceName(fqName:String) {
        return TypeReference.create(this, idNode(fqName));
    }

    public function unify(types:Array<SpecificHaxeType>):SpecificHaxeType {
        if (types.length == 0) return specTypeDynamic;
        var out = types[0];
        for (n in 1 ... types.length) out = unify2(out, types[n]);
        return out;
    }

    public function unify2(a:SpecificHaxeType, b:SpecificHaxeType):SpecificHaxeType {
        if (a.type == typeDynamic) return specTypeDynamic;
        if (b.type == typeDynamic) return specTypeDynamic;
        if (a.type == b.type) return unifyGenerics(a, b);

        // This should be work
        if ((a.type == typeFloat && b.type == typeInt) || (a.type == typeInt && b.type == typeFloat)) return specTypeFloat;

        var pair = matchPair(a.type.getAllBaseTypes(), b.type.getAllBaseTypes());
        if (pair != null) {
            // @TODO: Check generics!
            return new SpecificHaxeType(this, pair.l);
        }
        return specTypeDynamic;
    }

    private function unifyGenerics(a:SpecificHaxeType, b:SpecificHaxeType):SpecificHaxeType {
        if (a.type != b.type) throw "Trying to unify generics of distinct types";
        return a;
    }

    private function matchPair<T>(a:Array<T>, b:Array<T>):{l:T, r:T} {
        for (t1 in a) {
            for (t2 in b) {
                if (t1 == t2) {
                    return { l : t1, r : t2 };
                }
            }
        }
        return null;
    }

    public function getType(path:String):HaxeType {
        if (path.substr(0, 1) == ':') return getType(path.substr(1));
        return rootPackage.accessType(path);
    }
    public function getClass(path:String):ClassHaxeType {
        return Std.instance(getType(path), ClassHaxeType);
    }
    public function getInterface(path:String):InterfaceHaxeType {
        return Std.instance(getType(path), InterfaceHaxeType);
    }
    
    public function createArray(elementType:SpecificHaxeType):SpecificHaxeType {
        return createSpecific(typeArray, [elementType]);
    }
    
    public function createSpecific(type:HaxeType, ?parameters:Array<SpecificHaxeType>) {
        return new SpecificHaxeType(this, type, parameters);
    }

    public function createSpecificClass(classType:HaxeType):SpecificHaxeType {
        return new SpecificHaxeType(this, typeClass, [new SpecificHaxeType(this, classType)]);
    }

    public function getAllTypes():Array<HaxeType> return rootPackage.getAllTypes();

    public function getLeafPackageNames():Array<String> {
        return rootPackage.getLeafs().map(function(p:HaxePackage) return p.fqName);
    }

    public function getPackage(path:String):HaxePackage {
        return rootPackage.access(path, false);
    }
}
