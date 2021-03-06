package haxe.languageservices.type;

import haxe.languageservices.node.TextRange;
import haxe.languageservices.node.ZNode;

class FunctionHaxeType extends HaxeType {
    public var optBaseType:HaxeType;
    public var args = new Array<FunctionArgument>();
    public var body:ZNode;
    //public var name:String;
    public var nameNode:ZNode;
    public var _retval:TypeReference;
    public var returns:Array<ExpressionResult> = [];

    public function new(types:HaxeTypes, optBaseType:HaxeType, pos:TextRange, nameNode:ZNode, args:Array<FunctionArgument>, retval:TypeReference, body:ZNode = null) {
        super(types.rootPackage, pos, nameNode.pos.text);
        this.optBaseType = optBaseType;
        this.args = args;
        this.name = nameNode.pos.text;
        this.nameNode = nameNode;
        if (retval == null) retval = new TypeReference(types, 'Dynamic', null);
        this._retval = retval;
        this.body = body;
        for (arg in args) arg.func = this;
    }
    
    public function getRetvalFqName() {
        return getReturn().stype.type.fqName;
    }
    
    public function getReturn():ExpressionResult {
        if (_retval == null || _retval.fqName == 'Dynamic') return ExpressionResult.unify(types, returns);
        //if (retval.getSpecType(types))
        return ExpressionResult.withoutValue(_retval.getSpecType());
    }

    override public function toString() return 'FunctionType(' + args.join(',') + '):' + _retval;
}
