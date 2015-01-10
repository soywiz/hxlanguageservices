package haxe.languageservices.project;

import haxe.languageservices.util.ArrayUtils;
import haxe.languageservices.util.StringUtils;
import haxe.languageservices.util.PathUtils;
import haxe.io.Path;
import haxe.languageservices.util.Vfs;
import haxe.languageservices.sdk.HaxeSdk;
import haxe.languageservices.util.FileSystem2;

using StringTools;

class Hxml {
    public var path(default, null):String;
    public var basePath(default, null):String;
    public var sdk(default, null):HaxeSdk;
    public var lines(get, never):Array<String>;

    public function new(sdk:HaxeSdk, path:String) {
        this.sdk = sdk;
        this.basePath = Path.directory(path);
        this.path = path;
    }
    
    private var _lines:Array<String>;
    public function get_lines() {
        if (_lines == null) _lines = sdk.vfs.readString(path).split('\n');
        return _lines;
    }
    
    public function getDefines():Array<String> {
        var out:Array<String> = [];
        for (line in lines) {
            if (line.startsWith('-cpp')) out.push('cpp');
            if (line.startsWith('-neko')) out.push('neko');
            if (line.startsWith('-js')) out.push('js');
            if (line.startsWith('-java')) out.push('java');
            if (line.startsWith('-D')) {
                out.push(line.substr(2).trim());
            }
        }
        out.sort(StringUtils.compare);
        return ArrayUtils.unique(out);
    }

    public function getClassPaths():Array<String> {
        var paths:Array<String> = [];
        for (line in lines) {
            if (line.startsWith('-cp')) {
                paths.push(PathUtils.combine(this.basePath, line.substr(3).trim()));
            }
            if (line.startsWith('-lib')) {
                var libraryVersion = sdk.getLibraryVersion(line.substr(4).trim());
                paths.push(PathUtils.combine(libraryVersion.path, libraryVersion.classPath));
            }
        }
        return paths;
    }
}
