{ config, pkgs, lib, ... }:
let
  cfg = config.qt.kde.settings;
  inherit (builtins) toJSON;
  inherit (lib) types;
  inherit (types) attrsOf oneOf nullOr str int bool;
  valT = with types;nullOr oneOf [ str int bool ] // {
    apply = v:
      if v == null then "--delete"
      else ((lib.optionalString (lib.isBool v) "--type bool ") + (toJSON v));
  };
  keyT = types.attrsOf valT;
  groupT = with types;attrsOf (oneOf [ groupT keyT ]);

in
{
  options.qt.kde.settings = lib.mkOption {
    type = attrsOf groupT;
    default = { };
    example = lib.literalExample ''
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
    home.activation.kconfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      pkgs.runCommandLocal "kwriteconfig.sh"
        {
          nativeBuildInputs = [ pkgs.jq ];
          passAsFile = [ "cfg" ];
          cfg = toJSON cfg;
          jqScript =
            let
              getPaths = "[paths(scalars)]";
              groupPortion = ''reduce .[1:-2]|map(" --group "+.) as $i ("";$i+.)'';
              getVal = "$G|getpath($P)";
              w = "$DRY_RUN_CMD ${pkgs.plasma5Packages.kconfig}/bin/kwriteconfig5 --file ${config.xdg.configHome}/";
              mkExecLn = ''"${w}"+.[0]+(${groupPortion})+" --key "+.[-1]+(${getVal})'';
              toSingleStr = ''reduce .[] as $l("";$l+"\n"+.)'';
            in
            ". as $G|${getPaths}|map(. as $P|${mkExecLn})|${toSingleStr}";
        }
        ''
          echo '#!${pkgs.bash}/bin/bash' >>$out
          jq -r $jqScript <$cfgPath >>$out
          chmod a+x $out
        '');
  };

}
