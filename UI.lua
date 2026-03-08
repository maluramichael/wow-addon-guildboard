local _, addon = ...
local GuildBoard = addon

-------------------------------------------------------------------------------
-- UI Constants
-------------------------------------------------------------------------------
local WINDOW_WIDTH = 580
local WINDOW_HEIGHT = 520
local ROW_HEIGHT = 26
local GROUP_HEIGHT = 26
local HEADER_HEIGHT = 32
local TOOLBAR_HEIGHT = 58
local COLHEADER_HEIGHT = 20
local STATUSBAR_HEIGHT = 20
local SCROLLBAR_WIDTH = 16

local BACKDROP_MAIN = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local BACKDROP_INNER = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = true, tileSize = 16, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local C = {
    bg          = { 0.06, 0.06, 0.08, 0.95 },
    headerBg    = { 0.10, 0.10, 0.13, 1 },
    innerBg     = { 0.04, 0.04, 0.06, 1 },
    innerBorder = { 0.18, 0.18, 0.22, 1 },
    border      = { 0.25, 0.25, 0.30, 1 },
    accent      = { 1, 0.82, 0, 1 },
    text        = { 0.90, 0.90, 0.90, 1 },
    textDim     = { 0.50, 0.50, 0.50, 1 },
    rowHover    = { 0.15, 0.15, 0.20, 0.50 },
    groupBg     = { 0.08, 0.08, 0.11, 0.90 },
    green       = { 0.30, 0.85, 0.30, 1 },
    offline     = { 0.35, 0.35, 0.35, 1 },
}

-- Column positions (x offset from content left)
local COL = {
    ICON  = 6,
    NAME  = 28,
    LEVEL = 190,
    RANK  = 225,
    ZONE  = 310,
    NOTE  = 410,
}

-- Status dot colors
local STATUS_COLORS = {
    online  = { 0.30, 0.85, 0.30 },
    afk     = { 1.00, 0.75, 0.20 },
    dnd     = { 0.85, 0.20, 0.20 },
    offline = { 0.35, 0.35, 0.35 },
}

local CLASS_TEXTURE = "Interface\\GLUES\\CHARACTERCREATE\\UI-CharacterCreate-Classes"

-------------------------------------------------------------------------------
-- Row Pool
-------------------------------------------------------------------------------
local rowPool = {}
local activeRows = {}

local function AcquireRow(parent)
    local row = tremove(rowPool)
    if not row then
        row = CreateFrame("Button", nil, parent, "BackdropTemplate")
        row:SetHeight(ROW_HEIGHT)

        -- Hover highlight
        row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
        row.highlight:SetAllPoints()
        row.highlight:SetColorTexture(unpack(C.rowHover))

        -- Class color bar (left edge)
        row.classBar = row:CreateTexture(nil, "OVERLAY")
        row.classBar:SetPoint("TOPLEFT", 0, 0)
        row.classBar:SetPoint("BOTTOMLEFT", 0, 0)
        row.classBar:SetWidth(3)

        -- Class icon
        row.classIcon = row:CreateTexture(nil, "ARTWORK")
        row.classIcon:SetPoint("LEFT", COL.ICON, 0)
        row.classIcon:SetSize(16, 16)
        row.classIcon:SetTexture(CLASS_TEXTURE)

        -- Name
        row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.nameText:SetPoint("LEFT", COL.NAME, 0)
        row.nameText:SetWidth(155)
        row.nameText:SetJustifyH("LEFT")
        row.nameText:SetWordWrap(false)

        -- Level
        row.levelText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.levelText:SetPoint("LEFT", COL.LEVEL, 0)
        row.levelText:SetWidth(30)
        row.levelText:SetJustifyH("RIGHT")

        -- Rank
        row.rankText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.rankText:SetPoint("LEFT", COL.RANK, 0)
        row.rankText:SetWidth(80)
        row.rankText:SetJustifyH("LEFT")
        row.rankText:SetWordWrap(false)

        -- Zone
        row.zoneText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.zoneText:SetPoint("LEFT", COL.ZONE, 0)
        row.zoneText:SetWidth(95)
        row.zoneText:SetJustifyH("LEFT")
        row.zoneText:SetWordWrap(false)

        -- Note
        row.noteText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.noteText:SetPoint("LEFT", COL.NOTE, 0)
        row.noteText:SetPoint("RIGHT", -24, 0)
        row.noteText:SetJustifyH("LEFT")
        row.noteText:SetWordWrap(false)

        -- Online status dot
        row.statusDot = row:CreateTexture(nil, "OVERLAY")
        row.statusDot:SetPoint("RIGHT", -10, 0)
        row.statusDot:SetSize(8, 8)
        row.statusDot:SetTexture("Interface\\Buttons\\WHITE8x8")

        -- Separator
        row.sep = row:CreateTexture(nil, "OVERLAY")
        row.sep:SetPoint("BOTTOMLEFT", 8, 0)
        row.sep:SetPoint("BOTTOMRIGHT", -8, 0)
        row.sep:SetHeight(1)
        row.sep:SetColorTexture(0.12, 0.12, 0.15, 0.5)

        row.rowType = "member"
    end

    row:SetParent(parent)
    row:Show()
    tinsert(activeRows, row)
    return row
end

local function AcquireGroupRow(parent)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetHeight(GROUP_HEIGHT)
    row:SetBackdrop(BACKDROP_INNER)
    row:SetBackdropColor(unpack(C.groupBg))
    row:SetBackdropBorderColor(0, 0, 0, 0)

    row.arrow = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.arrow:SetPoint("LEFT", 8, 0)

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.label:SetPoint("LEFT", 22, 0)

    row.count = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.count:SetPoint("LEFT", row.label, "RIGHT", 6, 0)

    row.onlineCount = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.onlineCount:SetPoint("RIGHT", -10, 0)

    row.rowType = "group"
    tinsert(activeRows, row)
    return row
end

local function ReleaseAllRows()
    for _, row in ipairs(activeRows) do
        row:Hide()
        row:SetParent(nil)
        if row.rowType == "member" then
            tinsert(rowPool, row)
        end
    end
    wipe(activeRows)
end

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------
local function GetStatusColor(member)
    if not member.isOnline then return STATUS_COLORS.offline end
    if member.status == 1 then return STATUS_COLORS.afk end
    if member.status == 2 then return STATUS_COLORS.dnd end
    return STATUS_COLORS.online
end

local function GetStatusText(member)
    if not member.isOnline then return "Offline" end
    if member.status == 1 then return "AFK" end
    if member.status == 2 then return "DND" end
    return "Online"
end

-------------------------------------------------------------------------------
-- Custom Controls
-------------------------------------------------------------------------------
local modeMenuFrame

local function CreateCheckbox(parent, label)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(130, 18)

    local box = CreateFrame("Button", nil, frame, "BackdropTemplate")
    box:SetSize(14, 14)
    box:SetPoint("LEFT", 0, 0)
    box:SetBackdrop(BACKDROP_INNER)
    box:SetBackdropColor(0.08, 0.08, 0.10, 1)
    box:SetBackdropBorderColor(unpack(C.innerBorder))

    local check = box:CreateTexture(nil, "OVERLAY")
    check:SetPoint("TOPLEFT", 2, -2)
    check:SetPoint("BOTTOMRIGHT", -2, 2)
    check:SetColorTexture(unpack(C.accent))
    box.check = check

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", box, "RIGHT", 4, 0)
    text:SetText(label)

    frame.checked = false
    check:Hide()

    box:SetScript("OnClick", function()
        frame.checked = not frame.checked
        check:SetShown(frame.checked)
        if frame.onChange then frame.onChange(frame.checked) end
    end)
    box:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

    function frame:SetChecked(val)
        self.checked = val
        check:SetShown(val)
    end

    function frame:GetChecked()
        return self.checked
    end

    return frame
end

-------------------------------------------------------------------------------
-- Main Frame
-------------------------------------------------------------------------------
local mainFrame

local function CreateMainFrame()
    if mainFrame then return mainFrame end

    local f = CreateFrame("Frame", "GuildBoardFrame", UIParent, "BackdropTemplate")
    f:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    f:SetPoint("CENTER")
    f:SetBackdrop(BACKDROP_MAIN)
    f:SetBackdropColor(unpack(C.bg))
    f:SetBackdropBorderColor(unpack(C.border))
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("MEDIUM")
    f:EnableMouse(true)
    f:SetToplevel(true)

    tinsert(UISpecialFrames, "GuildBoardFrame")

    ---------------------------------------------------------------------------
    -- Header
    ---------------------------------------------------------------------------
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", 4, -4)
    header:SetPoint("TOPRIGHT", -4, -4)
    header:SetHeight(HEADER_HEIGHT)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() f:StartMoving() end)
    header:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

    local headerBg = header:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints()
    headerBg:SetColorTexture(unpack(C.headerBg))

    local titleIcon = header:CreateTexture(nil, "ARTWORK")
    titleIcon:SetPoint("LEFT", 8, 0)
    titleIcon:SetSize(18, 18)
    titleIcon:SetTexture("Interface\\Icons\\INV_Misc_GroupNeedMore")

    f.titleText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.titleText:SetPoint("LEFT", titleIcon, "RIGHT", 6, 0)
    f.titleText:SetText("|cFF00D1FFGuildBoard|r")

    local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButtonNoScripts")
    closeBtn:SetPoint("TOPRIGHT", 2, 2)
    closeBtn:SetSize(24, 24)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    ---------------------------------------------------------------------------
    -- Toolbar
    ---------------------------------------------------------------------------
    local toolbar = CreateFrame("Frame", nil, f)
    toolbar:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    toolbar:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -2)
    toolbar:SetHeight(TOOLBAR_HEIGHT)

    ---- Row 1: Search + Group Mode Dropdown + Refresh ----

    -- Search box
    local search = CreateFrame("EditBox", nil, toolbar, "BackdropTemplate")
    search:SetPoint("TOPLEFT", 6, -4)
    search:SetSize(200, 22)
    search:SetBackdrop(BACKDROP_INNER)
    search:SetBackdropColor(0.08, 0.08, 0.10, 1)
    search:SetBackdropBorderColor(unpack(C.innerBorder))
    search:SetFontObject(GameFontHighlightSmall)
    search:SetAutoFocus(false)
    search:SetMaxLetters(50)
    search:SetTextInsets(6, 6, 0, 0)

    search.placeholder = search:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    search.placeholder:SetPoint("LEFT", 6, 0)
    search.placeholder:SetText("Search name, class, zone...")
    search:SetScript("OnTextChanged", function(self)
        self.placeholder:SetShown(self:GetText() == "")
        GuildBoard:RefreshList()
    end)
    search:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)
    f.searchBox = search

    -- Group mode dropdown button
    local modeBtn = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
    modeBtn:SetPoint("LEFT", search, "RIGHT", 4, 0)
    modeBtn:SetSize(110, 22)
    modeBtn:SetText(GuildBoard:GetCurrentModeLabel())
    modeBtn:SetScript("OnClick", function(self)
        if not modeMenuFrame then
            modeMenuFrame = CreateFrame("Frame", "GuildBoardModeMenu", UIParent, "UIDropDownMenuTemplate")
        end
        modeMenuFrame.initialize = function(_, level)
            if level ~= 1 then return end
            for _, mode in ipairs(GuildBoard:GetGroupModes()) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = mode.label
                info.checked = (GuildBoard.db.profile.groupMode == mode.key)
                info.func = function()
                    GuildBoard.db.profile.groupMode = mode.key
                    modeBtn:SetText(mode.label)
                    GuildBoard:RefreshList()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
        ToggleDropDownMenu(1, nil, modeMenuFrame, self, 0, 0)
    end)
    modeBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Group Mode")
        GameTooltip:AddLine("Click to select grouping", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    modeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.modeBtn = modeBtn

    -- Refresh button
    local refreshBtn = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
    refreshBtn:SetPoint("TOPRIGHT", -6, -4)
    refreshBtn:SetSize(60, 22)
    refreshBtn:SetText("Refresh")
    refreshBtn:SetScript("OnClick", function()
        GuildBoard:RequestRoster()
    end)
    refreshBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Refresh guild roster")
        GameTooltip:Show()
    end)
    refreshBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    ---- Row 2: Show Offline + Hide Alts + Min Level ----

    -- Show Offline checkbox
    local offlineCB = CreateCheckbox(toolbar, "Show Offline")
    offlineCB:SetPoint("TOPLEFT", 8, -30)
    offlineCB.onChange = function(val)
        GuildBoard.db.profile.showOffline = val
        GuildBoard:RefreshList()
    end
    f.offlineCB = offlineCB

    -- Hide Alts checkbox
    local altsCB = CreateCheckbox(toolbar, "Hide Alts")
    altsCB:SetPoint("LEFT", offlineCB, "RIGHT", 16, 0)
    altsCB.onChange = function(val)
        GuildBoard.db.profile.hideAlts = val
        GuildBoard:RefreshList()
    end
    f.altsCB = altsCB

    -- Min Level label + input
    local lvlLabel = toolbar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    lvlLabel:SetPoint("LEFT", altsCB, "RIGHT", 24, 0)
    lvlLabel:SetText("Min Level:")

    local lvlInput = CreateFrame("EditBox", nil, toolbar, "BackdropTemplate")
    lvlInput:SetPoint("LEFT", lvlLabel, "RIGHT", 4, 0)
    lvlInput:SetSize(36, 18)
    lvlInput:SetBackdrop(BACKDROP_INNER)
    lvlInput:SetBackdropColor(0.08, 0.08, 0.10, 1)
    lvlInput:SetBackdropBorderColor(unpack(C.innerBorder))
    lvlInput:SetFontObject(GameFontHighlightSmall)
    lvlInput:SetAutoFocus(false)
    lvlInput:SetNumeric(true)
    lvlInput:SetMaxLetters(3)
    lvlInput:SetTextInsets(4, 4, 0, 0)
    lvlInput:SetText("1")
    lvlInput:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        local val = tonumber(self:GetText())
        if val then
            GuildBoard.db.profile.minLevel = max(1, min(80, val))
            GuildBoard:RefreshList()
        end
    end)
    lvlInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    lvlInput:SetScript("OnEscapePressed", function(self)
        self:SetText(tostring(GuildBoard.db.profile.minLevel))
        self:ClearFocus()
    end)
    f.lvlInput = lvlInput

    ---------------------------------------------------------------------------
    -- Column Headers
    ---------------------------------------------------------------------------
    local colHeader = CreateFrame("Frame", nil, f)
    colHeader:SetPoint("TOPLEFT", toolbar, "BOTTOMLEFT", 4, -2)
    colHeader:SetPoint("TOPRIGHT", toolbar, "BOTTOMRIGHT", -4, -2)
    colHeader:SetHeight(COLHEADER_HEIGHT)

    local colBg = colHeader:CreateTexture(nil, "BACKGROUND")
    colBg:SetAllPoints()
    colBg:SetColorTexture(0.08, 0.08, 0.10, 0.8)

    local function AddColLabel(text, x, width, justify)
        local label = colHeader:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        label:SetPoint("LEFT", x, 0)
        if width then label:SetWidth(width) end
        label:SetJustifyH(justify or "LEFT")
        label:SetText(text)
        label:SetTextColor(0.60, 0.60, 0.60)
        return label
    end

    AddColLabel("Name", COL.NAME, 155, "LEFT")
    AddColLabel("Lvl", COL.LEVEL, 30, "RIGHT")
    AddColLabel("Rank", COL.RANK, 80, "LEFT")
    AddColLabel("Zone", COL.ZONE, 95, "LEFT")
    AddColLabel("Note", COL.NOTE, nil, "LEFT")

    ---------------------------------------------------------------------------
    -- Scroll Area
    ---------------------------------------------------------------------------
    local scrollBg = CreateFrame("Frame", nil, f, "BackdropTemplate")
    scrollBg:SetPoint("TOPLEFT", colHeader, "BOTTOMLEFT", 0, -2)
    scrollBg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, STATUSBAR_HEIGHT + 6)
    scrollBg:SetBackdrop(BACKDROP_INNER)
    scrollBg:SetBackdropColor(unpack(C.innerBg))
    scrollBg:SetBackdropBorderColor(unpack(C.innerBorder))

    local scrollFrame = CreateFrame("ScrollFrame", nil, scrollBg)
    scrollFrame:SetPoint("TOPLEFT", 2, -2)
    scrollFrame:SetPoint("BOTTOMRIGHT", -SCROLLBAR_WIDTH - 2, 2)
    scrollFrame:EnableMouseWheel(true)

    local scrollChild = CreateFrame("Frame")
    scrollChild:SetWidth(scrollFrame:GetWidth() or (WINDOW_WIDTH - 30))
    scrollFrame:SetScrollChild(scrollChild)

    -- Scroll bar
    local scrollBar = CreateFrame("Slider", nil, scrollBg, "BackdropTemplate")
    scrollBar:SetPoint("TOPRIGHT", -3, -2)
    scrollBar:SetPoint("BOTTOMRIGHT", -3, 2)
    scrollBar:SetWidth(SCROLLBAR_WIDTH - 4)
    scrollBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    scrollBar:SetBackdropColor(0.1, 0.1, 0.12, 0.5)
    scrollBar:SetOrientation("VERTICAL")
    scrollBar:SetMinMaxValues(0, 1)
    scrollBar:SetValue(0)
    scrollBar:SetValueStep(ROW_HEIGHT)

    local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(0.3, 0.3, 0.35, 0.8)
    thumb:SetSize(SCROLLBAR_WIDTH - 6, 40)
    scrollBar:SetThumbTexture(thumb)

    scrollBar:SetScript("OnValueChanged", function(_, value)
        scrollFrame:SetVerticalScroll(value)
    end)

    scrollFrame:SetScript("OnMouseWheel", function(_, delta)
        local cur = scrollBar:GetValue()
        local minV, maxV = scrollBar:GetMinMaxValues()
        local step = ROW_HEIGHT * 3
        local newVal = max(minV, min(maxV, cur - delta * step))
        scrollBar:SetValue(newVal)
    end)

    f.scrollFrame = scrollFrame
    f.scrollChild = scrollChild
    f.scrollBar = scrollBar
    f.scrollBg = scrollBg

    ---------------------------------------------------------------------------
    -- Status Bar
    ---------------------------------------------------------------------------
    local statusBar = CreateFrame("Frame", nil, f)
    statusBar:SetPoint("BOTTOMLEFT", 4, 4)
    statusBar:SetPoint("BOTTOMRIGHT", -4, 4)
    statusBar:SetHeight(STATUSBAR_HEIGHT)

    f.statusText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.statusText:SetPoint("LEFT", 6, 0)

    f.raidReadyText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.raidReadyText:SetPoint("RIGHT", -6, 0)

    ---------------------------------------------------------------------------
    -- OnShow
    ---------------------------------------------------------------------------
    f:SetScript("OnShow", function()
        scrollChild:SetWidth(scrollFrame:GetWidth())
        offlineCB:SetChecked(GuildBoard.db.profile.showOffline)
        altsCB:SetChecked(GuildBoard.db.profile.hideAlts)
        lvlInput:SetText(tostring(GuildBoard.db.profile.minLevel))
        modeBtn:SetText(GuildBoard:GetCurrentModeLabel())
        GuildBoard:RequestRoster()
    end)

    mainFrame = f
    f:Hide()
    return f
end

-------------------------------------------------------------------------------
-- Context Menu
-------------------------------------------------------------------------------
local contextMenuFrame

local function ShowContextMenu(anchor, member)
    if not contextMenuFrame then
        contextMenuFrame = CreateFrame("Frame", "GuildBoardContextMenu", UIParent, "UIDropDownMenuTemplate")
    end

    local function InitMenu(_, level)
        if not level then return end

        if level == 1 then
            -- Header
            local info = UIDropDownMenu_CreateInfo()
            info.text = member.name
            info.isTitle = true
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)

            if member.isOnline then
                -- Whisper
                info = UIDropDownMenu_CreateInfo()
                info.text = "Whisper"
                info.notCheckable = true
                info.func = function()
                    ChatFrame_OpenChat("/w " .. member.name .. " ")
                end
                UIDropDownMenu_AddButton(info, level)

                -- Invite
                info = UIDropDownMenu_CreateInfo()
                info.text = "Invite to Group"
                info.notCheckable = true
                info.func = function()
                    InviteUnit(member.name)
                end
                UIDropDownMenu_AddButton(info, level)
            end

            -- Cancel
            info = UIDropDownMenu_CreateInfo()
            info.text = "Cancel"
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)
        end
    end

    contextMenuFrame.initialize = InitMenu
    ToggleDropDownMenu(1, nil, contextMenuFrame, anchor, 0, 0)
end

-------------------------------------------------------------------------------
-- Build Member Tooltip
-------------------------------------------------------------------------------
local function ShowMemberTooltip(row, member)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")

    -- Name with class color
    local cc = RAID_CLASS_COLORS[member.classFileName]
    if cc then
        GameTooltip:AddLine(format("|cFF%02x%02x%02x%s|r",
            cc.r * 255, cc.g * 255, cc.b * 255, member.name))
    else
        GameTooltip:AddLine(member.name)
    end

    -- Class & Level
    GameTooltip:AddDoubleLine(
        format("Level %d %s", member.level, member.classDisplayName),
        member.rankName,
        1, 1, 1, 0.7, 0.7, 0.7)

    -- Status
    local statusColor = GetStatusColor(member)
    GameTooltip:AddLine(GetStatusText(member), statusColor[1], statusColor[2], statusColor[3])

    -- Zone
    if member.zone then
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("Zone", member.zone, 0.5, 0.5, 0.5, 1, 0.82, 0)
    end

    -- Notes
    if member.note then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Note: " .. member.note, 0.7, 0.7, 0.7, true)
    end
    if member.officerNote then
        GameTooltip:AddLine("Officer: " .. member.officerNote, 0.6, 0.5, 0.3, true)
    end

    -- Alt indicator
    if GuildBoard:IsAlt(member) then
        local mainName = GuildBoard:GetAltMainName(member)
        GameTooltip:AddLine(" ")
        if mainName then
            GameTooltip:AddLine("Alt of " .. mainName, 0.5, 0.8, 1)
        else
            GameTooltip:AddLine("Alt character", 0.5, 0.8, 1)
        end
    end

    -- Raid ready
    if member.isMaxLevel then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Raid Ready", 0.3, 0.85, 0.3)
    end

    -- Actions
    GameTooltip:AddLine(" ")
    if member.isOnline then
        GameTooltip:AddLine("Click to whisper  |  Right-click for more", 0.5, 0.5, 0.5)
    else
        GameTooltip:AddLine("Right-click for options", 0.5, 0.5, 0.5)
    end

    GameTooltip:Show()
end

-------------------------------------------------------------------------------
-- Refresh List
-------------------------------------------------------------------------------
function GuildBoard:RefreshList()
    if not mainFrame or not mainFrame:IsShown() then return end

    ReleaseAllRows()

    -- Update title
    if self.guildName then
        mainFrame.titleText:SetText(format("|cFF00D1FFGuildBoard|r  |cFF888888-|r  %s", self.guildName))
    else
        mainFrame.titleText:SetText("|cFF00D1FFGuildBoard|r")
    end

    if not IsInGuild() then
        mainFrame.statusText:SetText("Not in a guild")
        mainFrame.raidReadyText:SetText("")
        mainFrame.scrollChild:SetHeight(1)
        mainFrame.scrollBar:SetMinMaxValues(0, 0)
        mainFrame.scrollBar:Hide()
        return
    end

    local searchText = mainFrame.searchBox:GetText()
    local filtered = self:GetFilteredMembers(searchText)
    local groups = self:GetGroupedMembers(filtered)

    local scrollChild = mainFrame.scrollChild
    local yOffset = 0
    local displayedCount = 0

    for _, group in ipairs(groups) do
        -- Group header
        local groupRow = AcquireGroupRow(scrollChild)
        groupRow:SetPoint("TOPLEFT", 0, -yOffset)
        groupRow:SetPoint("RIGHT", 0, 0)

        local collapsed = self:IsGroupCollapsed(group.key)
        groupRow.arrow:SetText(collapsed and "+" or "-")
        groupRow.arrow:SetTextColor(group.color[1], group.color[2], group.color[3])
        groupRow.label:SetText(group.name)
        groupRow.label:SetTextColor(group.color[1], group.color[2], group.color[3])
        groupRow.count:SetText("(" .. #group.members .. ")")

        -- Online count for this group
        local groupOnline = 0
        for _, m in ipairs(group.members) do
            if m.isOnline then groupOnline = groupOnline + 1 end
        end
        if groupOnline > 0 then
            groupRow.onlineCount:SetText(format("|cFF4DD64D%d online|r", groupOnline))
        else
            groupRow.onlineCount:SetText("")
        end

        groupRow:SetScript("OnClick", function()
            GuildBoard:ToggleGroup(group.key)
        end)
        yOffset = yOffset + GROUP_HEIGHT

        -- Member rows
        if not collapsed then
            for _, member in ipairs(group.members) do
                local row = AcquireRow(scrollChild)
                row:SetPoint("TOPLEFT", 0, -yOffset)
                row:SetPoint("RIGHT", 0, 0)

                -- Class color bar
                local cc = RAID_CLASS_COLORS[member.classFileName]
                if cc then
                    row.classBar:SetColorTexture(cc.r, cc.g, cc.b, 1)
                else
                    row.classBar:SetColorTexture(0.5, 0.5, 0.5, 1)
                end

                -- Class icon
                local tcoords = CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[member.classFileName]
                if tcoords then
                    row.classIcon:SetTexCoord(tcoords[1], tcoords[2], tcoords[3], tcoords[4])
                    row.classIcon:Show()
                else
                    row.classIcon:Hide()
                end

                -- Name (class colored)
                local nameStr = member.name
                if GuildBoard:IsAlt(member) then
                    nameStr = nameStr .. " |cFF6699CC[A]|r"
                end
                if cc then
                    row.nameText:SetText(format("|cFF%02x%02x%02x%s|r",
                        cc.r * 255, cc.g * 255, cc.b * 255, nameStr))
                else
                    row.nameText:SetText(nameStr)
                end

                -- Level (gold if max level)
                row.levelText:SetText(tostring(member.level))
                if member.isMaxLevel then
                    row.levelText:SetTextColor(1, 0.82, 0)
                else
                    row.levelText:SetTextColor(0.7, 0.7, 0.7)
                end

                -- Rank
                row.rankText:SetText(member.rankName)

                -- Zone
                if member.isOnline and member.zone then
                    row.zoneText:SetText(member.zone)
                    row.zoneText:SetTextColor(0.6, 0.6, 0.6)
                elseif not member.isOnline then
                    row.zoneText:SetText("")
                else
                    row.zoneText:SetText("")
                end

                -- Note
                row.noteText:SetText(member.note or "")

                -- Status dot
                local statusColor = GetStatusColor(member)
                row.statusDot:SetColorTexture(statusColor[1], statusColor[2], statusColor[3], 1)

                -- Dim offline rows
                if not member.isOnline then
                    row:SetAlpha(0.5)
                else
                    row:SetAlpha(1)
                end

                -- Click to whisper (online only)
                row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                row:SetScript("OnClick", function(_, button)
                    if button == "LeftButton" and member.isOnline then
                        ChatFrame_OpenChat("/w " .. member.name .. " ")
                    elseif button == "RightButton" then
                        ShowContextMenu(row, member)
                    end
                end)

                -- Tooltip
                row:SetScript("OnEnter", function(self)
                    ShowMemberTooltip(self, member)
                end)
                row:SetScript("OnLeave", function() GameTooltip:Hide() end)

                yOffset = yOffset + ROW_HEIGHT
                displayedCount = displayedCount + 1
            end
        else
            displayedCount = displayedCount + #group.members
        end
    end

    -- Update scroll range
    scrollChild:SetHeight(max(1, yOffset))
    local scrollMax = max(0, yOffset - mainFrame.scrollBg:GetHeight() + 4)
    mainFrame.scrollBar:SetMinMaxValues(0, scrollMax)
    mainFrame.scrollBar:SetShown(scrollMax > 0)

    -- Status text
    local statusParts = {}
    tinsert(statusParts, format("%d member%s", displayedCount, displayedCount ~= 1 and "s" or ""))
    tinsert(statusParts, format("|cFF4DD64D%d online|r", self.onlineCount))
    mainFrame.statusText:SetText(table.concat(statusParts, "  |cFF555555·|r  "))

    -- Raid ready count
    local raidReady = self:GetRaidReadyCount()
    mainFrame.raidReadyText:SetText(format("Raid Ready: |cFFFFD100%d|r", raidReady))
end

-------------------------------------------------------------------------------
-- Toggle / Wire Up
-------------------------------------------------------------------------------
function GuildBoard:ToggleWindow()
    local f = CreateMainFrame()
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
    end
end
