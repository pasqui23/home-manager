{ config, pkgs, lib, ... }:
let
  cfg = config.qt.kde.settings;
  inherit (builtins) toJSON;
  toKconfVal = p: v:
    let t = builtins.typeOf v; in
    if t == "set" then v
    else if v == null then "--delete"
    else ((lib.optionalString (t == "bool") "--type bool ") + (toJSON v));

in
{
  options.qt.kde.settings = lib.mkOption {
    type = lib.types.anything;
    default = { };
    example = lib.literalExpression ''
      { powermanagementprofilesrc.AC.HandleButtonEvents.lidAction = 32;}
    '';
    description = ''
      A set of values to be modified by kwriteconfig5.

      The example value would run in the activation script
      kwriteconfig5 --file $HDG_CONFIG_HOME/powermanagementprofilesrc --group AC --group HandleButtonEvents --group lidAction --key lidAction 32
      .

      null values will delete the corresponding entry instead of inserting any value.
    '';
  };

  config = lib.mkIf (cfg != { }) {
    home.activation.kconfig = lib.hm.dag.entryAfter [ "writeBoundary" ]
      "${pkgs.runCommandLocal "kwriteconfig.sh"
        {
          nativeBuildInputs = [ pkgs.jq ];
          passAsFile = [ "cfg" "jqScript" ];
          cfg = toJSON (lib.mapAttrsRecursive toKconfVal cfg);
          jqScript =
            let
              getPaths = "[paths(scalars)]";
              w = "$DRY_RUN_CMD ${pkgs.plasma5Packages.kconfig}/bin/kwriteconfig5 --file ${config.xdg.configHome}/";
              g=''" --group "'';
              groupPortion = ''.[1:-2]|join(${g})'';
              getVal = "$G|getpath($P)";
              mkExecLn = ''"${w}"+.[0]+${g}+(${groupPortion})+" --key "+.[-1]+(${getVal})'';
              toSingleStr = ''join("\n")'';
            in
            ". as $G|${getPaths}|map(. as $P|${mkExecLn})|${toSingleStr}";
        }
        ''
          echo '#!${pkgs.bash}/bin/bash' >>$out
          jq -rf "$jqScriptPath" <$cfgPath >>$out
          chmod a+x $out
        ''}";
  };

}
