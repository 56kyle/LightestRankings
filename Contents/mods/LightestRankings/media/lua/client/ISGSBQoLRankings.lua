require "ISUI/ISImage"
require "ISUI/ISPanelJoypad"
require "ISUI/ISLabel"

GSBQoL = GSBQoL or {}
GSBQoL.Rankings = GSBQoL.Rankings or {}
GSBQoL.Rankings.Commands = GSBQoL.Rankings.Commands or {}

GSBQoL.Rankings.ResponseSuccess = nil;

GSBQoL.Rankings.data = GSBQoL.Rankings.data or {};

GSBQoL.Rankings.MenuConfigs = {}
GSBQoL.Rankings.MenuConfigs.Button = {}
GSBQoL.Rankings.MenuConfigs.Button.WIDTH = 30;
GSBQoL.Rankings.MenuConfigs.Button.HEIGHT = 30;

GSBQoL.Rankings.MenuConfigs.Buttons = {}
GSBQoL.Rankings.MenuConfigs.Buttons.orderIconAscendant = getTexture("media/textures/orderIconAscendant.png");
GSBQoL.Rankings.MenuConfigs.Buttons.orderIconDescendant = getTexture("media/textures/orderIconDescendant.png");

GSBQoL.Rankings.Buttons = {}

GSBQoL.Rankings.textureOff = getTexture("media/textures/Ranking_off.png");
GSBQoL.Rankings.textureOn = getTexture("media/textures/Ranking_on.png");

GSBQoL.Rankings.Admin = GSBQoL.Rankings.Admin or {}
GSBQoL.Rankings.Admin.ListAllPlayers = nil;
GSBQoL.Rankings.Admin.HiddenPlayers = nil;

ISGSBQoLRanking = ISPanel:derive("ISGSBQoLRanking");

function ISGSBQoLRanking:new(x, y, width, height)
    local o = {}
    x = getCore():getScreenWidth() - width - 30;
    y = getCore():getScreenHeight() - 660;
    o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 };
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 };
    o.width = width;
    o.height = height;
    o.moveWithMouse = true;
    o.menuHeight = 30;

    ISGSBQoLRanking.instance = o;
    return o;
end

function ISGSBQoLRanking:createChildren()

    self.scoreboardKills = self:createScoreboard("kills");
    self.scoreboardOverallKills = self:createScoreboard("overall_kills");
    self.scoreboardDeaths = self:createScoreboard("deaths");
    self.scoreboardLifetime = self:createScoreboard("lifetime");
    self.scoreboardLifetime.valueFormatter = ISRankingScoreboardItemListBox.formatLifetime;
    self.scoreboardFactionKills = self:createScoreboard("faction_kills");
    self.scoreboardFactionKills.createTooltip = ISRankingScoreboardItemListBox.factionTooltip;

    self:addChild(self.scoreboardKills);
    self:addChild(self.scoreboardOverallKills);
    self:addChild(self.scoreboardDeaths);
    self:addChild(self.scoreboardLifetime);
    self:addChild(self.scoreboardFactionKills);

    self.menuButtons = ISGSBQoLRankingMenu:new(0, 0, self:getWidth(), self.menuHeight);
    self:addChild(self.menuButtons);
    self.menuButtons:createButton(self.scoreboardKills);
    self.menuButtons:createButton(self.scoreboardOverallKills);
    self.menuButtons:createButton(self.scoreboardDeaths);
    self.menuButtons:createButton(self.scoreboardLifetime);
    self.menuButtons:createButton(self.scoreboardFactionKills);
    self.menuButtons:pack();
end

function ISGSBQoLRanking:pack()
    self:setWidth(self.menuButtons:getWidth());
    self:setX(getCore():getScreenWidth() - self:getWidth() - 30);

    self.scoreboardKills:setWidth(self:getWidth());
    self.scoreboardOverallKills:setWidth(self:getWidth());
    self.scoreboardDeaths:setWidth(self:getWidth());
    self.scoreboardLifetime:setWidth(self:getWidth());
    self.scoreboardFactionKills:setWidth(self:getWidth());
end

function ISGSBQoLRanking:createScoreboard(name)
    local yAdjust = 3
    local scoreboard = ISRankingScoreboardItemListBox:new(0, self.menuHeight + yAdjust, self:getWidth(), self:getHeight() - self.menuHeight - (yAdjust * 2));
    scoreboard:initialise();
    scoreboard:instantiate();
    scoreboard:setVisible(false);
    scoreboard.name = name;
    return scoreboard;
end

function GSBQoL.Rankings.showWindow(player)
    if GSBQoL.Rankings.window then
        GSBQoL.Rankings.window:setVisible(true);
        GSBQoL.Rankings.toolbarButton:setImage(GSBQoL.Rankings.textureOn);
        return
    end

    local scoreboard = ISGSBQoLRanking:new(0, 0, 100, 325);
    scoreboard:initialise();
    scoreboard:instantiate();
    scoreboard:pack();
    GSBQoL.Rankings.scoreboard = scoreboard;

    local window = scoreboard:wrapInCollapsableWindow(getText("UI_GSBQoL_Rankings_title"), true);
    window.close = GSBQoL.Rankings.hideWindow;
    window.closeButton.onmousedown = GSBQoL.Rankings.hideWindow;
    window:setResizable(false);
    window:addToUIManager();

    if isAdmin() or string.lower(player:getAccessLevel()) == "admin" then
        local th = window:titleBarHeight() - 5;
        local gearButton = ISButton:new(window:getWidth() - 30, 1 + (window:titleBarHeight() - th) / 2, th, th, "", window, ISGSBQoLRankingAdminWindow.OnOpenPanel);
        gearButton:initialise();
        gearButton.anchorRight = true;
        gearButton.anchorLeft = false;
        gearButton.borderColor.a = 0.0;
        gearButton.backgroundColor.a = 0;
        gearButton.backgroundColorMouseOver.a = 0;
        gearButton:setImage(getTexture("media/ui/Panel_Icon_Gear.png"));
        gearButton:setUIName(ISChat.gearButtonName);
        window:addChild(gearButton);
        gearButton:setVisible(true);
    end

    GSBQoL.Rankings.window = window;

    GSBQoL.Rankings.toolbarButton:setImage(GSBQoL.Rankings.textureOn);
    GSBQoL.Rankings.scoreboard:updateDataScoreboards();
end

function GSBQoL.Rankings.hideWindow(self)
    ISCollapsableWindow.close(self);
    GSBQoL.Rankings.toolbarButton:setImage(GSBQoL.Rankings.textureOff);
end

function GSBQoL.Rankings.showWindowToolbar()
    if GSBQoL.Rankings.window and GSBQoL.Rankings.window:getIsVisible() then
        GSBQoL.Rankings.window:close();
    else
        GSBQoL.Rankings.showWindow(getPlayer());
    end
end

function GSBQoL.Rankings.OnGameStart()
    GSBQoL.Rankings:showWindowToolbar();
    GSBQoL.Rankings.scoreboard:updateDataScoreboards();
	GSBQoL.Rankings.showWindowToolbar()
end

function GSBQoL.Rankings.addToolbarButton()
    GSBQoL.Rankings.toolbarButton = ISButton:new(0, ISEquippedItem.instance.movableBtn:getY() + ISEquippedItem.instance.movableBtn:getHeight() + 340, 50, 50, "", nil, GSBQoL.Rankings.showWindowToolbar);
    GSBQoL.Rankings.toolbarButton:setImage(GSBQoL.Rankings.textureOff);
    GSBQoL.Rankings.toolbarButton:setDisplayBackground(false);
    GSBQoL.Rankings.toolbarButton.borderColor = { r = 1, g = 1, b = 1, a = 0.1 };

    ISEquippedItem.instance:addChild(GSBQoL.Rankings.toolbarButton);
    ISEquippedItem.instance:setHeight(math.max(ISEquippedItem.instance:getHeight(), GSBQoL.Rankings.toolbarButton:getY() + 400));
end

function ISGSBQoLRanking.updateDataScoreboards()
    GSBQoL.Rankings.scoreboard:updateDataBase();
    GSBQoL.Rankings.scoreboard:updateDataBaseFactions();
end

function ISGSBQoLRanking:updateDataScoreboard(scoreboard, data)
    scoreboard:clear();
    for i, item in ipairs(data) do
        scoreboard:addItem(item.name, item);
    end
end

function ISGSBQoLRanking:sortList(list)
    table.sort(list, function(a, b)
        if a.value == b.value then
            return a.name < b.name;
        else
            return a.value > b.value;
        end
    end)

    local tieCount = 0;
    for i, o in ipairs(list) do
        if i > 1 then
            if o.value == list[i - 1].value then
                tieCount = tieCount + 1;
            else
                tieCount = 0;
            end
        end
        o["indexToList"] = i - tieCount;
        o["index"] = i;
    end
end

--GSQ EDIT
function ISGSBQoLRanking:captList(list, size, isFaction)
    local player = getPlayer()
    if not player then return end

    if size > 0 then
        local captList = {}
        local isPlayer = false
        local userName = getPlayer():getUsername()
        if isFaction then
            local faction = Faction.getPlayerFaction(player);
            if faction then
                userName = faction:getName()
            end
        end
        local playerData = nil
        for _, v in ipairs(list) do
            local pos = v["indexToList"]
            if pos <= size then
                table.insert(captList, v)
                if v.name == userName then
                    isPlayer = true
                end
            end
            if v.name == userName then
                playerData = v
            end
        end
        if not isPlayer and playerData ~= nil then
            table.insert(captList, playerData)
        end
        return captList
    end
    return list
end
-- /////

function ISGSBQoLRanking:updateDataBaseFactions(arguments)
    local factionData = GSBQoL.Rankings.data["factions"];
    local factionList = GSBQoL.Rankings.data["factionsList"] or {}

    if arguments ~= nil then
        factionData = arguments;
        factionList = {}

        for k, faction in pairs(arguments) do
            table.insert(factionList, { name = faction.name, value = faction.kills, rawData = faction });
        end
    end
	
	local size = SandboxVars.GSBQoLRanking.ListCap or 0 -- GSQ EDIT

    self:sortList(factionList);
	factionList = self:captList(factionList, size, true) -- GSQ EDIT
    self:updateDataScoreboard(self.scoreboardFactionKills, factionList);

    GSBQoL.Rankings.data["factions"] = factionData;
    GSBQoL.Rankings.data["factionsList"] = factionList;

end

function ISGSBQoLRanking:updateDataBase(arguments)
    local kills = GSBQoL.Rankings.data["kills"] or {}
    local overallKills = GSBQoL.Rankings.data["overallKills"] or {}
    local deaths = GSBQoL.Rankings.data["deaths"] or {}
    local lifetime = GSBQoL.Rankings.data["lifetime"] or {}

    if arguments ~= nil then
        kills = {}
        overallKills = {}
        deaths = {}
        lifetime = {}

        for k, player in pairs(arguments) do
            if player.kills > 0 then
                table.insert(kills, { name = k, value = player.kills });
                table.insert(overallKills, { name = k, value = (player.overallKills or 0) + player.kills });
            elseif player.overallKills > 0 then
                table.insert(overallKills, { name = k, value = player.overallKills });
            end
            if player.deaths > 0 then
                table.insert(deaths, { name = k, value = player.deaths });
            end
            if player.lifetime > 0 then
                table.insert(lifetime, { name = k, value = player.lifetime });
            end
        end
    end

    local size = SandboxVars.GSBQoLRanking.ListCap or 0

    self:sortList(kills);
    self:sortList(overallKills);
    self:sortList(deaths);
    self:sortList(lifetime);
    kills = self:captList(kills, size, false) --GSQ EDIT
    overallKills = self:captList(overallKills, size, false) --GSQ EDIT
    deaths = self:captList(deaths, size, false) --GSQ EDIT
    lifetime = self:captList(lifetime, size, false) --GSQ EDIT

    self:updateDataScoreboard(self.scoreboardKills, kills);
    self:updateDataScoreboard(self.scoreboardDeaths, deaths);
    self:updateDataScoreboard(self.scoreboardOverallKills, overallKills);
    self:updateDataScoreboard(self.scoreboardLifetime, lifetime);

    GSBQoL.Rankings.data["kills"] = kills;
    GSBQoL.Rankings.data["deaths"] = deaths;
    GSBQoL.Rankings.data["overallKills"] = overallKills;
    GSBQoL.Rankings.data["lifetime"] = lifetime;
end

function GSBQoL.Rankings.Commands.DataFromServer(arguments)
    GSBQoL.Rankings.scoreboard:updateDataBase(arguments);
end
function GSBQoL.Rankings.Commands.DataFactionFromServer(arguments)
    GSBQoL.Rankings.scoreboard:updateDataBaseFactions(arguments or {});
end

function GSBQoL.Rankings.Commands.DataToAdmin(arguments)
    ModData.remove(GSBQoL.Rankings.Shared.MODDATA .. "Admin");
    ModData.add(GSBQoL.Rankings.Shared.MODDATA .. "Admin", arguments);
    GSBQoL.Rankings.Admin.data = arguments;
    GSBQoL.Rankings.Admin.data["updated"] = getTimestamp();

    if ISGSBQoLRankingAdminWindow.instance ~= nil then
        ISGSBQoLRankingAdminWindow.instance:populateData();
    end
end

function GSBQoL.Rankings.RankingDataClient(module, command, arguments)
    if module == GSBQoL.Rankings.Shared.MODULE_NAME then
        GSBQoL.Rankings.Commands[command](arguments);
    end
end

function GSBQoL.Rankings.EveryTenMinutesUpdateBaseCounts()
    local player = getPlayer();
    if player:isAlive() then
        local object = { player:getUsername(), player:getZombieKills(), player:getHoursSurvived() };
        sendClientCommand(player, GSBQoL.Rankings.Shared.MODULE_NAME, "BaseInfo", object);
    end
end

function GSBQoL.Rankings.OnPlayerDeath()
    GSBQoL.Rankings.hideWindow(GSBQoL.Rankings.window);
    local player = getPlayer();
    local object = { player:getUsername(), player:getZombieKills(), player:getHoursSurvived() };
    sendClientCommand(player, GSBQoL.Rankings.Shared.MODULE_NAME, "DeathKillsCount", object);
end

Events.OnGameStart.Add(GSBQoL.Rankings.EveryTenMinutesUpdateBaseCounts);
Events.EveryTenMinutes.Add(GSBQoL.Rankings.EveryTenMinutesUpdateBaseCounts);

Events.OnCreatePlayer.Add(GSBQoL.Rankings.addToolbarButton);
Events.OnPlayerDeath.Add(GSBQoL.Rankings.OnPlayerDeath);

Events.OnServerCommand.Add(GSBQoL.Rankings.RankingDataClient);
Events.OnGameStart.Add(GSBQoL.Rankings.OnGameStart);