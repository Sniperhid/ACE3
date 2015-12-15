class ACE_Settings {
    class GVAR(DisplayTextOnJam) {
        typeName = "BOOL";
        isClientSettable = 1;
        value = 1;
        displayName = CSTRING(SettingDisplayTextName);
        description = CSTRING(SettingDisplayTextDesc);
    };
    class GVAR(enableRefractEffect) {
        typeName = "BOOL";
        value = 0;
    };
};
