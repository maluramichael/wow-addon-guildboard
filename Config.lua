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
                    raidLevel = {
                        name = "Raid Ready Level",
                        desc = "Minimum level to be considered raid ready",
                        type = "range",
                        order = 3,
                        min = 1,
                        max = 80,
                        step = 1,
                        get = function() return gb.db.profile.raidLevel end,
                        set = function(_, val)
                            gb.db.profile.raidLevel = val
                            gb:SendMessage("GUILDBOARD_ROSTER_UPDATED")
                        end,
                    },
                },
            },
            minimap = {
                name = "Minimap",
                type = "group",
                inline = true,
                order = 2,
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
                order = 3,
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
