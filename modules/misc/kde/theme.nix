{ config, lib, pkgs, ... }:
let
  inherit (lib) mkOption types;
  mkKdeThemeMod = optName: settingsPath: contentPathPrefix: contentPathSuffix:
    let
      cfg = config.qt.kde.theme.${optName};
    in
    {
      options.qt.kde.theme.${optName} = {
        package = mkOption {
          type = with types;nullOr package;
          description = "The package from where to take ${contentPathPrefix}";
        };
        name = mkOption {
          type = types.str;
          description = "The name of the theme to take";
          default = cfg.package.pname or cfg.package.name;
          defaultText = "cfg.package.pname or cfg.package.name";
        };
      };
      config = lib.mkIf (cfg.package != null) {
        qt.kde.settings = lib.setAttrByPath settingsPath cfg.name;
        home.packages = [
          (pkgs.runCommand "kde-theme"
            {
              suffix = contentPathPrefix + cfg.name + contentPathSuffix;
              src = cfg.package;
            } "install -D {$src,$out}/$suffix")
        ];
      };
    };
in
{
  imports = [
    (mkKdeThemeMod "icons" [ "kdeglobals" "Icons" "Theme" ] "share/icons" "")
  ];
}
