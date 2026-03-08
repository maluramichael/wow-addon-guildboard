local addonName, addon = ...
local GuildBoard = LibStub("AceAddon-3.0"):NewAddon(addon, addonName,
    "AceEvent-3.0", "AceConsole-3.0")
_G["GuildBoard"] = GuildBoard

GuildBoard.version = (C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)(addonName, "Version") or "1.0.0"

-------------------------------------------------------------------------------
-- Compat
-------------------------------------------------------------------------------
local RequestRoster = (C_GuildInfo and C_GuildInfo.GuildRoster) or GuildRoster
local MAX_LEVEL = GetMaxPlayerLevel and GetMaxPlayerLevel() or 70

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------
local GROUP_MODES = {
    { key = "class",  label = "By Class" },
    { key = "role",   label = "By Role" },
    { key = "rank",   label = "By Rank" },
    { key = "level",  label = "By Level" },
    { key = "online", label = "By Status" },
}

local ROLE_MAP = {
    WARRIOR     = "Tank",
    PALADIN     = "Healer",
    HUNTER      = "DPS",
    ROGUE       = "DPS",
    PRIEST      = "Healer",
    DEATHKNIGHT = "Tank",
    SHAMAN      = "Healer",
    MAGE        = "DPS",
    WARLOCK     = "DPS",
    MONK        = "Healer",
    DRUID       = "Healer",
    DEMONHUNTER = "DPS",
    EVOKER      = "DPS",
}

local CLASS_ORDER = {
    "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST",
    "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "MONK",
    "DRUID", "DEMONHUNTER", "EVOKER",
}

local ROLE_ORDER = { "Tank", "Healer", "DPS" }

local ROLE_COLORS = {
    Tank   = { 0.20, 0.40, 0.80 },
    Healer = { 0.20, 0.80, 0.35 },
    DPS    = { 0.80, 0.25, 0.25 },
}

-------------------------------------------------------------------------------
-- Defaults
-------------------------------------------------------------------------------
local defaults = {
    profile = {
        minimap = { hide = false },
        groupMode = "class",
        showOffline = false,
        hideAlts = false,
        minLevel = 1,
        raidLevel = MAX_LEVEL,
        altPatterns = { "^alt" },
        windowWidth = 580,
        windowHeight = 520,
        collapsed = {},
    },
}

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------
GuildBoard.members = {}
GuildBoard.guildName = nil
GuildBoard.onlineCount = 0
GuildBoard.totalCount = 0

-------------------------------------------------------------------------------
-- Roster Scanning
-------------------------------------------------------------------------------
function GuildBoard:ScanRoster()
    if not IsInGuild() then
        wipe(self.members)
        self.guildName = nil
        self.onlineCount = 0
        self.totalCount = 0
        self:SendMessage("GUILDBOARD_ROSTER_UPDATED")
        return
    end

    self.guildName = GetGuildInfo("player")
    local numTotal = GetNumGuildMembers()
    local members = {}
    local onlineCount = 0

    for i = 1, numTotal do
        local fullName, rankName, rankIndex, level, classDisplayName,
              zone, note, officerNote, isOnline, status, classFileName = GetGuildRosterInfo(i)

        if fullName then
            local shortName = Ambiguate(fullName, "guild")
            local cf = classFileName or "WARRIOR"
            local member = {
                index = i,
                fullName = fullName,
                name = shortName,
                rankName = rankName or "",
                rankIndex = rankIndex or 0,
                level = level or 1,
                classFileName = cf,
                classDisplayName = classDisplayName or cf,
                zone = (zone and zone ~= "") and zone or nil,
                note = (note and note ~= "") and note or nil,
                officerNote = (officerNote and officerNote ~= "") and officerNote or nil,
                isOnline = isOnline or false,
                status = status or 0,
                role = ROLE_MAP[cf] or "DPS",
                isMaxLevel = (level or 0) >= self.db.profile.raidLevel,
            }
            tinsert(members, member)
            if isOnline then
                onlineCount = onlineCount + 1
            end
        end
    end

    self.members = members
    self.onlineCount = onlineCount
    self.totalCount = #members
    self:SendMessage("GUILDBOARD_ROSTER_UPDATED")
end

function GuildBoard:RequestRoster()
    if IsInGuild() and RequestRoster then
        RequestRoster()
    end
end

-------------------------------------------------------------------------------
-- Filtering
-------------------------------------------------------------------------------
function GuildBoard:GetFilteredMembers(search)
    search = search and strlower(strtrim(search)) or ""
    local showOffline = self.db.profile.showOffline
    local hideAlts = self.db.profile.hideAlts
    local minLevel = self.db.profile.minLevel or 1
    local result = {}

    for _, m in ipairs(self.members) do
        local visible = true

        -- Online filter
        if not showOffline and not m.isOnline then
            visible = false
        end

        -- Level filter
        if visible and m.level < minLevel then
            visible = false
        end

        -- Alt filter
        if visible and hideAlts and self:IsAlt(m) then
            visible = false
        end

        -- Search filter
        if visible and search ~= "" then
            local haystack = strlower(m.name)
            if m.note then haystack = haystack .. " " .. strlower(m.note) end
            if m.classDisplayName then haystack = haystack .. " " .. strlower(m.classDisplayName) end
            if m.zone then haystack = haystack .. " " .. strlower(m.zone) end
            if m.rankName then haystack = haystack .. " " .. strlower(m.rankName) end
            if not haystack:find(search, 1, true) then
                visible = false
            end
        end

        if visible then
            tinsert(result, m)
        end
    end

    return result
end

-------------------------------------------------------------------------------
-- Sorting
-------------------------------------------------------------------------------
local function SortMembers(a, b)
    if a.isOnline ~= b.isOnline then return a.isOnline end
    if a.level ~= b.level then return a.level > b.level end
    return a.name < b.name
end

-------------------------------------------------------------------------------
-- Grouping
-------------------------------------------------------------------------------
function GuildBoard:GetGroupModes()
    return GROUP_MODES
end

function GuildBoard:GetCurrentModeLabel()
    for _, mode in ipairs(GROUP_MODES) do
        if mode.key == self.db.profile.groupMode then
            return mode.label
        end
    end
    return "By Class"
end

function GuildBoard:CycleGroupMode(direction)
    local current = self.db.profile.groupMode
    local idx = 1
    for i, mode in ipairs(GROUP_MODES) do
        if mode.key == current then idx = i break end
    end
    idx = idx + (direction or 1)
    if idx > #GROUP_MODES then idx = 1 end
    if idx < 1 then idx = #GROUP_MODES end
    self.db.profile.groupMode = GROUP_MODES[idx].key
    self:SendMessage("GUILDBOARD_ROSTER_UPDATED")
end

function GuildBoard:GetGroupedMembers(members)
    local mode = self.db.profile.groupMode
    if mode == "class" then return self:GroupByClass(members)
    elseif mode == "role" then return self:GroupByRole(members)
    elseif mode == "rank" then return self:GroupByRank(members)
    elseif mode == "level" then return self:GroupByLevel(members)
    elseif mode == "online" then return self:GroupByOnline(members)
    end
    return self:GroupByClass(members)
end

function GuildBoard:GroupByClass(members)
    local buckets = {}
    for _, m in ipairs(members) do
        local key = m.classFileName
        if not buckets[key] then buckets[key] = {} end
        tinsert(buckets[key], m)
    end

    local groups = {}
    for _, className in ipairs(CLASS_ORDER) do
        if buckets[className] and #buckets[className] > 0 then
            sort(buckets[className], SortMembers)
            local cc = RAID_CLASS_COLORS[className]
            local displayName = buckets[className][1].classDisplayName
            tinsert(groups, {
                key = className,
                name = displayName,
                color = cc and { cc.r, cc.g, cc.b } or { 1, 1, 1 },
                members = buckets[className],
            })
        end
    end
    return groups
end

function GuildBoard:GroupByRole(members)
    local buckets = { Tank = {}, Healer = {}, DPS = {} }
    for _, m in ipairs(members) do
        local role = m.role
        if not buckets[role] then buckets[role] = {} end
        tinsert(buckets[role], m)
    end

    local groups = {}
    for _, role in ipairs(ROLE_ORDER) do
        if buckets[role] and #buckets[role] > 0 then
            sort(buckets[role], SortMembers)
            tinsert(groups, {
                key = role,
                name = role .. "s",
                color = ROLE_COLORS[role],
                members = buckets[role],
            })
        end
    end
    return groups
end

function GuildBoard:GroupByRank(members)
    local buckets = {}
    local rankOrder = {}

    for _, m in ipairs(members) do
        local key = m.rankIndex
        if not buckets[key] then
            buckets[key] = { rankName = m.rankName, members = {} }
            tinsert(rankOrder, key)
        end
        tinsert(buckets[key].members, m)
    end

    sort(rankOrder)
    local groups = {}
    for _, rankIdx in ipairs(rankOrder) do
        local bucket = buckets[rankIdx]
        sort(bucket.members, SortMembers)
        tinsert(groups, {
            key = "rank_" .. rankIdx,
            name = bucket.rankName,
            color = { 1, 0.82, 0 },
            members = bucket.members,
        })
    end
    return groups
end

function GuildBoard:GroupByLevel(members)
    local buckets = {}
    local order = {}

    for _, m in ipairs(members) do
        local key
        if m.level >= MAX_LEVEL then
            key = MAX_LEVEL
        else
            key = floor(m.level / 10) * 10
        end
        if not buckets[key] then
            buckets[key] = {}
            tinsert(order, key)
        end
        tinsert(buckets[key], m)
    end

    sort(order, function(a, b) return a > b end)
    local groups = {}
    for _, key in ipairs(order) do
        sort(buckets[key], SortMembers)
        local label
        if key >= MAX_LEVEL then
            label = format("Level %d", MAX_LEVEL)
        elseif key == 0 then
            label = "Level 1-9"
        else
            label = format("Level %d-%d", key, key + 9)
        end
        tinsert(groups, {
            key = "level_" .. key,
            name = label,
            color = key >= MAX_LEVEL and { 1, 0.82, 0 } or { 0.70, 0.70, 0.70 },
            members = buckets[key],
        })
    end
    return groups
end

function GuildBoard:GroupByOnline(members)
    local online = {}
    local offline = {}
    for _, m in ipairs(members) do
        if m.isOnline then tinsert(online, m)
        else tinsert(offline, m) end
    end

    sort(online, SortMembers)
    sort(offline, SortMembers)

    local groups = {}
    if #online > 0 then
        tinsert(groups, {
            key = "online",
            name = "Online",
            color = { 0.30, 0.85, 0.30 },
            members = online,
        })
    end
    if #offline > 0 then
        tinsert(groups, {
            key = "offline",
            name = "Offline",
            color = { 0.50, 0.50, 0.50 },
            members = offline,
        })
    end
    return groups
end

-------------------------------------------------------------------------------
-- Alt Detection
-------------------------------------------------------------------------------
function GuildBoard:IsAlt(member)
    local patterns = self.db and self.db.profile.altPatterns or { "^alt" }
    local note = strlower(member.note or "")
    local officerNote = strlower(member.officerNote or "")

    for _, pattern in ipairs(patterns) do
        local p = strlower(pattern)
        if p ~= "" then
            local ok1, match1 = pcall(string.find, note, p)
            if ok1 and match1 then return true end
            local ok2, match2 = pcall(string.find, officerNote, p)
            if ok2 and match2 then return true end
        end
    end
    return false
end

function GuildBoard:GetAltMainName(member)
    local text = strlower(member.note or member.officerNote or "")
    -- "ALT Charname" or "ALT Charname's"
    local main = text:match("^alt%s+(%w+)")
    if main then return main end
    -- "alt of Charname"
    main = text:match("alt of (%w+)")
    if main then return main end
    -- "Charname's alt"
    main = text:match("(%w+)'s alt")
    return main
end

-------------------------------------------------------------------------------
-- Collapse
-------------------------------------------------------------------------------
function GuildBoard:IsGroupCollapsed(key)
    return self.db.profile.collapsed[key]
end

function GuildBoard:ToggleGroup(key)
    self.db.profile.collapsed[key] = not self.db.profile.collapsed[key]
    self:SendMessage("GUILDBOARD_ROSTER_UPDATED")
end

-------------------------------------------------------------------------------
-- Stats
-------------------------------------------------------------------------------
function GuildBoard:GetRaidReadyCount()
    local count = 0
    for _, m in ipairs(self.members) do
        if m.isMaxLevel then count = count + 1 end
    end
    return count
end

function GuildBoard:GetClassCounts()
    local counts = {}
    for _, m in ipairs(self.members) do
        counts[m.classFileName] = (counts[m.classFileName] or 0) + 1
    end
    return counts
end

-------------------------------------------------------------------------------
-- LDB
-------------------------------------------------------------------------------
function GuildBoard:SetupLDB()
    local ldb = LibStub("LibDataBroker-1.1")
    local dataObj = ldb:NewDataObject("GuildBoard", {
        type = "launcher",
        icon = "Interface\\Icons\\INV_Misc_GroupNeedMore",
        OnClick = function(_, button)
            if button == "LeftButton" then
                self:ToggleWindow()
            elseif button == "RightButton" then
                self:OpenConfig()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("|cFF00D1FFGuildBoard|r")
            if not IsInGuild() then
                tooltip:AddLine("Not in a guild", 0.7, 0.7, 0.7)
            else
                tooltip:AddLine(self.guildName or "Guild", 1, 0.82, 0)
                tooltip:AddLine(" ")
                tooltip:AddDoubleLine("Members", tostring(self.totalCount), 1, 1, 1, 1, 0.82, 0)
                tooltip:AddDoubleLine("Online", tostring(self.onlineCount), 1, 1, 1, 0.3, 0.85, 0.3)
                tooltip:AddDoubleLine("Raid Ready", tostring(self:GetRaidReadyCount()), 1, 1, 1, 1, 0.82, 0)
            end
            tooltip:AddLine(" ")
            tooltip:AddLine("|cFFFFFFFFLeft-click:|r Toggle window", 0.5, 0.5, 0.5)
            tooltip:AddLine("|cFFFFFFFFRight-click:|r Options", 0.5, 0.5, 0.5)
        end,
    })

    local icon = LibStub("LibDBIcon-1.0")
    icon:Register("GuildBoard", dataObj, self.db.profile.minimap)
end

-------------------------------------------------------------------------------
-- Lifecycle
-------------------------------------------------------------------------------
function GuildBoard:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("GuildBoardDB", defaults, true)

    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, self:GetOptionsTable())
    self.optionsCategoryID = select(2,
        LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, "GuildBoard"))

    self:SetupLDB()

    self:RegisterChatCommand("gb", "SlashCommand")
    self:RegisterChatCommand("guildboard", "SlashCommand")
end

function GuildBoard:OnEnable()
    self:RegisterEvent("GUILD_ROSTER_UPDATE")
    self:RegisterMessage("GUILDBOARD_ROSTER_UPDATED", "RefreshList")

    -- Initial scan after short delay
    C_Timer.After(2, function()
        self:RequestRoster()
    end)
end

function GuildBoard:GUILD_ROSTER_UPDATE()
    self:ScanRoster()
end

-------------------------------------------------------------------------------
-- Slash Commands
-------------------------------------------------------------------------------
function GuildBoard:SlashCommand(input)
    input = strtrim(strlower(input or ""))

    if input == "" or input == "toggle" then
        self:ToggleWindow()
    elseif input == "config" or input == "options" then
        self:OpenConfig()
    elseif input == "refresh" then
        self:RequestRoster()
        self:Print("Roster refreshed.")
    else
        self:Print("GuildBoard Commands:")
        self:Print("  /gb - Toggle window")
        self:Print("  /gb config - Open options")
        self:Print("  /gb refresh - Refresh roster")
    end
end

function GuildBoard:OpenConfig()
    if Settings and Settings.OpenToCategory then
        pcall(Settings.OpenToCategory, self.optionsCategoryID or "GuildBoard")
    end
end

-- UI stubs (overridden by UI.lua)
function GuildBoard:ToggleWindow() end
function GuildBoard:RefreshList() end
