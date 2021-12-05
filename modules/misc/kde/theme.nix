{ config, lib, pkgs, ... }:
let

  inherit (lib) mkOption types;
  themePkg = cfg: contentPathPrefix: contentPathSuffix: pkgs.runCommand "kde-theme-${cfg.name}"
    {
      suffix = contentPathPrefix + cfg.name + contentPathSuffix;
      src = cfg.package;
    } ''
    if [[ ! -e $src/$suffix ]]
    then
      exit 1
    fi
    ln -s $src $out
  '';
  mkKdeThemeMod = optName: settingsPath: contentPathPrefix: contentPathSuffix:
    let
      cfg = config.qt.kde.theme.${optName};
    in
    {
      options.qt.kde.theme.${optName} = {
        package = mkOption {
          type = with types;nullOr package;
          default = null;
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
        home.packages = [ (themePkg cfg contentPathPrefix contentPathSuffix) ];
      };
    };
  mkCmdMod = cmd: optName: contentPathPrefix: contentPathSuffix:
    let
      cfg = config.qt.kde.theme.${optName};
      warn = ''

        Be careful that option defined in qt.kde.settings always take precedence, even if they are defined with mkDefault.
      '';
    in
    {
      options.qt.kde.theme.${optName} = {
        package = mkOption {
          type = with types;nullOr package;
          default = null;
          description = "The package from where to take the contents of the theme.${warn}";
        };
        name = mkOption {
          type = types.str;
          description = "The name of the theme to take.${warn}";
          defaultText = "cfg.package.pname or cfg.package.name";
        };
      };
      config = lib.mkIf (cfg.package != null) {
        home.activation."plasma-apply-${optName}" = lib.hm.dag.entryBetween [ "kconfig" ] [ "writeBoundary" ] ''$DRY_RUN_CMD XDG_RUNTIME_DIR="/run/user/$UID" ${cmd}'';
        home.packages = [ (themePkg cfg contentPathPrefix contentPathSuffix) ];
      };
    };
  mkPlasmaApplyMod = optName: mkCmdMod "${pkgs.libsForQt5.plasma-workspace}/bin/plasma-apply-${optName}" optName;
in
{
  imports = [
    (mkCmdMod "${pkgs.libsForQt5.plasma-workspace}/libexec/plasma-changeicons" "icons" "share/icons/" "")

    (mkPlasmaApplyMod "colorscheme" "share/color-schemes/" ".colors")
    (mkPlasmaApplyMod "lookandfeel" "share/plasma/look-and-feel/" "")
    (mkPlasmaApplyMod "desktoptheme" "share/aurorae/themes/" "")
    (mkPlasmaApplyMod "cursortheme" "share/icons" "")
  ];
}
