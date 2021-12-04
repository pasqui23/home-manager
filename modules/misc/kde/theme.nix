let
  mkKdeThemeMod = optName: settingsPath: contentPathPrefix: contentPathSuffix: { config, lib, pkgs, ... }:
    let
      cfg = config.qt.kde.theme.${optName};
      inherit (lib) mkOption types;
    in
    {
      options.qt.kde.theme.${optName} = {
        package = mkOption {
          type = with types;nullOr package;
          description = "The package from where to take the contents of the theme";
        };
        name = mkOption {
          type = types.str;
          description = "The name of the theme to take";
          defaultText = "cfg.package.pname or cfg.package.name";
        };
      };
      config = lib.mkIf (cfg.package != null) {
        qt.kde.settings = lib.setAttrByPath settingsPath cfg.name;
        qt.kde.theme.${optName}.name = lib.mkDefault (cfg.package.pname or cfg.package.name);
        home.packages = [
          (pkgs.runCommand "kde-theme"
            {
              suffix = contentPathPrefix + cfg.name + contentPathSuffix;
              src = cfg.package;
            } ''
              mkdir -p $(dirname $out/$suffix)
              cp -a {$src,$out}/$suffix
            '')
        ];
      };
    };
in
{ conifg, ... }:
{
  imports = [
    (mkKdeThemeMod "icons" [ "kdeglobals" "Icons" "Theme" ] "share/icons/" "")
  ];
}
