package haxe.languageservices.sdk;

import haxe.languageservices.util.FileSystem2;

using StringTools;

class HaxeLibrary {
    public var sdk(default, null):HaxeSdk;
    public var name(default, null):String;
    public var path(default, null):String;
    public var versions(default, null) = new Map<String, HaxeLibraryVersion>();
    public var currentVersion(default, null):HaxeLibraryVersion;
    public var exists(get, never):Bool;

    public function new(sdk:HaxeSdk, path:String) {
        this.sdk = sdk;
        this.path = path;
        var nameMatch = ~/\/?(\w+)$/;
        nameMatch.match(path);
        this.name = nameMatch.matched(1);
        if (FileSystem2.exists(path)) {
            for (version in FileSystem2.listFiles(path)) {
                if (version.charAt(0) == '.') continue;
                var versionNormalized = normalizeVersion(version);
                this.versions[versionNormalized] = currentVersion = getVersion(version);
            }
        }
        var _currentPath = '$path/.current';
        if (FileSystem2.exists(_currentPath)) {
            currentVersion = getVersion(FileSystem2.readString(_currentPath));
        }
    }
    
    public function getVersion(version:String):HaxeLibraryVersion {
        version = version.trim();
        return new HaxeLibraryVersion(this, normalizeVersion(version), path + '/' + denormalizeVersion(version));
    }
    
    private function get_exists() return FileSystem2.exists(path);
    
    static private function normalizeVersion(version:String) return version.replace(',', '.');
    static private function denormalizeVersion(version:String) return version.replace('.', ',');

    public function toString() return 'HaxeLibrary($name)';
}
