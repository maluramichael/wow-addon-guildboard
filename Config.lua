local _, addon = ...
local GuildBoard = addon

function GuildBoard:GetOptionsTable()
    local gb = self
    return {
        name = "GuildBoard",
        type = "group",
        args = {
            display = {
                name = "Display",
                type = "group",
                inline = true,
                order = 1,
                args = {
                    showOffline = {
                        name = "Show Offline Members",
                        desc = "Include offline members in the roster view",
                        type = "toggle",
                        order = 1,
                        width = "full",
                        get = function() return gb.db.profile.showOffline end,
                        set = function(_, val)
                            gb.db.profile.showOffline = val
                            gb:SendMessage("GUILDBOARD_ROSTER_UPDATED")
                        end,
                    },
                    groupMode = {
                        name = "Default Group Mode",
                        desc = "How to group guild members",
                        type = "select",
                        order = 2,
                        values = {
                            class  = "By Class",
                            role   = "By Role",
                            rank   = "By Rank",
                            level  = "By Level",
                            online = "By Status",
                        },
                        get = function() return gb.db.profile.groupMode end,
                        set = function(_, val)
                            gb.db.profile.groupMode = val
                            gb:SendMessage("GUILDBOARD_ROSTER_UPDATED")
                        end,
                    },
                    hideAlts = {
                        name = "Hide Alts by Default",
                        desc = "Hide characters detected as alts when opening the window",
                        type = "toggle",
                        order = 3,
                        width = "full",
                        get = function() return gb.db.profile.hideAlts end,
                        set = function(_, val)
                            gb.db.profile.hideAlts = val
                            gb:SendMessage("GUILDBOARD_ROSTER_UPDATED")
                        end,
                    },
                    minLevel = {
                        name = "Default Min Level Filter",
                        desc = "Only show members at or above this level",
                        type = "range",
                        order = 4,
                        min = 1,
                        max = 90,
                        step = 1,
                        get = function() return gb.db.profile.minLevel end,
                        set = function(_, val)
                            gb.db.profile.minLevel = val
                            gb:SendMessage("GUILDBOARD_ROSTER_UPDATED")
                        end,
                    },
                    raidLevel = {
                        name = "Raid Ready Level",
                        desc = "Minimum level to be considered raid ready",
                        type = "range",
                        order = 5,
                        min = 1,
                        max = 90,
                        step = 1,
                        get = function() return gb.db.profile.raidLevel end,
                        set = function(_, val)
                            gb.db.profile.raidLevel = val
                            gb:SendMessage("GUILDBOARD_ROSTER_UPDATED")
                        end,
                    },
                },
            },
            altDetection = {
                name = "Alt Detection",
                type = "group",
                inline = true,
                order = 2,
                args = {
                    desc = {
                        name = "Lua patterns to identify alts. Checked case-insensitively against both public and officer notes.\n\nExamples:\n  ^alt  =  note starts with \"ALT\"\n  ^twink  =  note starts with \"TWINK\"\n  alt of  =  note contains \"alt of\"",
                        type = "description",
                        order = 1,
                    },
                    patterns = {
                        name = "Alt Patterns (one per line)",
                        type = "input",
                        order = 2,
                        width = "full",
                        multiline = 4,
                        get = function()
                            return table.concat(gb.db.profile.altPatterns, "\n")
                        end,
                        set = function(_, val)
                            local patterns = {}
                            for line in val:gmatch("[^\r\n]+") do
                                line = strtrim(line)
                                if line ~= "" then
                                    tinsert(patterns, line)
                                end
                            end
                            gb.db.profile.altPatterns = patterns
                            gb:SendMessage("GUILDBOARD_ROSTER_UPDATED")
                        end,
                    },
                },
            },
            ilvlExtraction = {
                name = "Item Level Extraction",
                type = "group",
                inline = true,
                order = 3,
                args = {
                    desc = {
                        name = "Lua patterns to extract item level from guild notes. Must contain a (%d+) capture group.\nChecked case-insensitively. First match wins.\n\nExamples:\n  (%d+)%s*ilvl  =  \"230 ilvl\"\n  (%d+)%s*-%s*ilvl  =  \"251 - ilvl\"\n  ilvl%s*(%d+)  =  \"ilvl 230\"",
                        type = "description",
                        order = 1,
                    },
                    patterns = {
                        name = "iLvl Patterns (one per line)",
                        type = "input",
                        order = 2,
                        width = "full",
                        multiline = 4,
                        get = function()
                            return table.concat(gb.db.profile.ilvlPatterns, "\n")
                        end,
                        set = function(_, val)
                            local patterns = {}
                            for line in val:gmatch("[^\r\n]+") do
                                line = strtrim(line)
                                if line ~= "" then
                                    tinsert(patterns, line)
                                end
                            end
                            gb.db.profile.ilvlPatterns = patterns
                            gb:SendMessage("GUILDBOARD_ROSTER_UPDATED")
                        end,
                    },
                },
            },
            minimap = {
                name = "Minimap",
                type = "group",
                inline = true,
                order = 4,
                args = {
                    minimapBtn = {
                        name = "Show Minimap Button",
                        desc = "Show or hide the minimap button",
                        type = "toggle",
                        order = 1,
                        width = "full",
                        get = function() return not gb.db.profile.minimap.hide end,
                        set = function(_, val)
                            gb.db.profile.minimap.hide = not val
                            if val then
                                LibStub("LibDBIcon-1.0"):Show("GuildBoard")
                            else
                                LibStub("LibDBIcon-1.0"):Hide("GuildBoard")
                            end
                        end,
                    },
                },
            },
            commands = {
                name = "Slash Commands",
                type = "group",
                inline = true,
                order = 5,
                args = {
                    help = {
                        name = "/gb - Toggle guild board window\n/gb config - Open this options panel\n/gb refresh - Refresh guild roster",
                        type = "description",
                        order = 1,
                    },
                },
            },
        },
    }
end
