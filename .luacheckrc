std = "lua51"
max_line_length = false

exclude_files = {
    "libs/",
}

ignore = {
    "212", -- unused argument
    "432", -- shadowing upvalue
}

globals = {
    "StaticPopupDialogs",
}

read_globals = {
    -- Lua
    "strsplit", "strtrim", "strlower", "strjoin", "format",
    "tinsert", "tremove", "wipe", "sort",
    "max", "min", "floor", "ceil", "sqrt",

    -- WoW Core
    "CreateFrame", "UIParent", "GameTooltip", "GameFontNormal",
    "GameFontNormalSmall", "GameFontHighlightSmall", "GameFontDisableSmall",
    "GameFontHighlight",
    "UISpecialFrames",
    "RAID_CLASS_COLORS", "CLASS_ICON_TCOORDS",
    "UIDROPDOWNMENU_MENU_VALUE",
    "StaticPopup_Show",

    -- WoW API
    "LibStub",
    "IsInGuild", "GetGuildInfo", "GetNumGuildMembers", "GetGuildRosterInfo",
    "GuildRoster", "SetGuildRosterShowOffline",
    "GetMaxPlayerLevel",
    "Ambiguate",
    "SendChatMessage", "InviteUnit",
    "C_AddOns", "GetAddOnMetadata",
    "C_GuildInfo",
    "C_Timer",
    "Settings",

    -- UI
    "UIDropDownMenu_CreateInfo", "UIDropDownMenu_AddButton",
    "ToggleDropDownMenu", "CloseDropDownMenus",
    "ChatFrame_OpenChat",

    -- Textures
    "unpack",
}
