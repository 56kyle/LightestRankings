GSBQoL = GSBQoL or {}
GSBQoL.Rankings = GSBQoL.Rankings or {}
GSBQoL.Rankings.Admin = GSBQoL.Rankings.Admin or {}

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.NewSmall)
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.NewMedium)

ISGSBQoLRankingAdminWindow = ISPanel:derive("ISGSBQoLRankingAdminWindow");

local CONFIG_WIDTH = 430; -- 2 LISTS (200) + 2 PADDING (10) + GAP (10)
local CONFIG_HEIGHT = 400;

function ISGSBQoLRankingAdminWindow:OnOpenPanel()
    if ISGSBQoLRankingAdminWindow.instance then
        ISGSBQoLRankingAdminWindow.instance:setVisible(true)
        ISGSBQoLRankingAdminWindow.instance:addToUIManager()
        ISGSBQoLRankingAdminWindow.instance:setKeyboardFocus()
        return
    end

    local modal = ISGSBQoLRankingAdminWindow:new(0, 0, CONFIG_WIDTH, CONFIG_HEIGHT)
    modal:initialise();
    modal:addToUIManager();
    modal.instance:setKeyboardFocus();
end


function ISGSBQoLRankingAdminWindow:new(x, y, width, height)
    local o = {}
    x = getCore():getScreenWidth() / 2 - (width / 2);
    y = getCore():getScreenHeight() / 2 - (height / 2);
    o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 };
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 };
    o.width = width;
    o.height = height;
    o.moveWithMouse = true;
    ISGSBQoLRankingAdminWindow.instance = o;
    ISDebugMenu.RegisterClass(self);
    return o;
end

function ISGSBQoLRankingAdminWindow:initialise()
    local PADDING = 10;
    local BTN_WIDTH = 100;
    local BTN_HEIGHT = math.max(25, FONT_HGT_SMALL + 3 * 2)
    ISPanel.initialise(self);

    self.ok = ISButton:new(PADDING, self:getHeight() - BTN_HEIGHT - PADDING, BTN_WIDTH, BTN_HEIGHT, string.upper(getText("UI_GSBQoLRankings_close")), self, ISGSBQoLRankingAdminWindow.onClick);
    self.ok.internal = "CLOSE";
    self.ok:initialise();
    self.ok:instantiate();
    self:addChild(self.ok);

    self.save = ISButton:new(self.ok:getX() + BTN_WIDTH + 5, self:getHeight() - BTN_HEIGHT - PADDING, BTN_WIDTH, BTN_HEIGHT, string.upper(getText("UI_GSBQoLRankings_save")), self, ISGSBQoLRankingAdminWindow.onClick);
    self.save.internal = "SAVE";
    self.save:initialise();
    self.save:instantiate();
    self:addChild(self.save);

    self.refresh = ISButton:new(self:getWidth() - PADDING - BTN_WIDTH, self:getHeight() - BTN_HEIGHT - PADDING, BTN_WIDTH, BTN_HEIGHT, string.upper(getText("UI_GSBQoLRankings_load")), self, ISGSBQoLRankingAdminWindow.onClick);
    self.refresh.internal = "REFRESH";
    self.refresh:initialise();
    self.refresh:instantiate();
    self:addChild(self.refresh);
end

function ISGSBQoLRankingAdminWindow:prerender()
    local z = 20;
    self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
    local title = getText("UI_GSBQoL_Rankings_admin_title");
    self:drawText(title, self.width / 2 - (getTextManager():MeasureStringX(UIFont.NewMedium, title) / 2), z, 1, 1, 1, 1, UIFont.NewMedium);

    local updated = getText("UI_GSBQoLRankings_noData");
    if GSBQoL.Rankings.Admin.data ~= nil then
        updated = os.date("%y-%b-%d, %H:%M:%S", GSBQoL.Rankings.Admin.data["updated"])
    end
    self:drawText(updated, self.width / 2 - (getTextManager():MeasureStringX(UIFont.NewSmall, updated) / 2), z + FONT_HGT_MEDIUM, 1, 1, 1, 1, UIFont.NewSmall);
end

function ISGSBQoLRankingAdminWindow:createChildren()
    local LIST_WIDTH = 200;
    local LIST_HEIGHT = 200;
    local PADDING = 10;
    local GROUP_GAP = 20;

    local BTN_WIDTH = 100;
    local BTN_HEIGHT = math.max(25, FONT_HGT_SMALL + 3 * 2)

    local Y_TITLES = 80;

    local allPlayersTitle = ISLabel:new(10, Y_TITLES, 10, getText("UI_GSBQoLRankings_players"), 1, 1, 1, 1, UIFont.NewSmall, true);
    allPlayersTitle:initialise();
    self:addChild(allPlayersTitle);

    local hiddenPlayersTitle = ISLabel:new(10 + LIST_WIDTH + 10, Y_TITLES, 10, getText("UI_GSBQoLRankings_hiddenPlayers"), 1, 1, 1, 1, UIFont.NewSmall, true);
    hiddenPlayersTitle:initialise();
    self:addChild(hiddenPlayersTitle);

    local yLists = Y_TITLES + FONT_HGT_SMALL + 3;

    self.allPlayersList = ISGSBQoLRankingAdminPlayersList:new(PADDING, yLists, LIST_WIDTH, LIST_HEIGHT);
    self.allPlayersList:initialise();
    self.allPlayersList:setOnMouseDoubleClick(self, self.onAllPlayersMouseDoubleClick);
    self:addChild(self.allPlayersList);

    self.hiddenPlayersList = ISGSBQoLRankingAdminPlayersList:new(self.allPlayersList:getRight() + 10, yLists, LIST_WIDTH, LIST_HEIGHT);
    self.hiddenPlayersList:initialise();
    self.hiddenPlayersList:setOnMouseDoubleClick(self, self.onHiddenPlayersMouseDoubleClick);
    self:addChild(self.hiddenPlayersList);

    local y = self.allPlayersList:getBottom() + GROUP_GAP;
    local labelResetFactionSeason = ISLabel:new(PADDING, y, BTN_HEIGHT, getText("UI_GSBQoLRankings_factionSeason"), 1, 1, 1, 1, UIFont.NewSmall, true);
    labelResetFactionSeason:initialise();
    self:addChild(labelResetFactionSeason);

    local x = labelResetFactionSeason:getRight() + 10;
    self.resetFactionSeason = ISButton:new(x, y, BTN_WIDTH, BTN_HEIGHT, string.upper(getText("UI_GSBQoLRankings_reset")), self, ISGSBQoLRankingAdminWindow.onClick);
    self.resetFactionSeason.internal = "FACTION_SEASON_RESET";
    self.resetFactionSeason:initialise();
    self.resetFactionSeason:instantiate();
    self:addChild(self.resetFactionSeason);

    x = self.resetFactionSeason:getRight() + 10;
    self.newFactionSeason = ISButton:new(x, y, BTN_WIDTH, BTN_HEIGHT, string.upper(getText("UI_GSBQoLRankings_newSeason")), self, ISGSBQoLRankingAdminWindow.onClick);
    self.newFactionSeason.internal = "FACTION_SEASON_NEW";
    self.newFactionSeason:initialise();
    self.newFactionSeason:instantiate();
    self:addChild(self.newFactionSeason);

    self:populateData();
end

ISGSBQoLRankingAdminPlayersList = ISScrollingListBox:derive("ISGSBQoLRankingAdminPlayersList");

function ISGSBQoLRankingAdminPlayersList:new(x, y, width, height)
    local o = {};
    o = ISScrollingListBox:new(x, y, width, height);
    setmetatable(o, self);
    self.__index = self;

    o.anchorRight = true;
    o.anchorBottom = true;
    o:setFont(UIFont.NewSmall, 3);
    o:clear();
    o.selected = -1;
    o.drawBorder = true;

    return o;
end

function ISGSBQoLRankingAdminPlayersList.sortByName(a, b)
    local la = string.lower(a.text);
    local lb = string.lower(b.text);
    return not string.sort(la, lb);
end

function ISGSBQoLRankingAdminPlayersList:sort()
    table.sort(self.items, ISGSBQoLRankingAdminPlayersList.sortByName);
    for i, item in ipairs(self.items) do
        item.itemindex = i;
    end
end

function ISGSBQoLRankingAdminWindow:populateData()
    if GSBQoL.Rankings.Admin.data then
        local allData = GSBQoL.Rankings.Admin.data;
        local ignoredPlayers = {};

        self.hiddenPlayersList:clear();
        self.allPlayersList:clear();

        local dataIgnored = allData["ignoredPlayersList"] or {};
        for k, v in pairs(dataIgnored) do
            ignoredPlayers[k] = k;
            self.hiddenPlayersList:addItem(k, { name = k });
        end
        self.hiddenPlayersList:sort();

        for k, v in pairs(allData["players"]) do
            if ignoredPlayers[k] == nil then
                self.allPlayersList:addItem(k, { name = k });
            end
        end
        self.allPlayersList:sort();
        self.refresh:setTitle(string.upper(getText("UI_GSBQoLRankings_refresh")));
    end
end

function ISGSBQoLRankingAdminWindow:onAllPlayersMouseDoubleClick(item)
    self.allPlayersList:removeItem(item["name"]);
    self.allPlayersList.selected = -1;
    self.hiddenPlayersList:addItem(item["name"], item);
    self.hiddenPlayersList:sort();
end

function ISGSBQoLRankingAdminWindow:onHiddenPlayersMouseDoubleClick(item)
    self.hiddenPlayersList:removeItem(item["name"]);
    self.hiddenPlayersList.selected = -1;
    self.allPlayersList:addItem(item["name"], item);
    self.allPlayersList:sort();
end

function ISGSBQoLRankingAdminWindow:doDrawItem(y, item, alt)
    local a = 0.9;

    if self.selected == item.index then
        self:drawRect(0, (y), self:getWidth(), self.itemheight - 1, 0.3, 0.7, 0.35, 0.15);
    end

    self:drawText(item.text, 10, y + 2, 1, 1, 1, a, self.font);

    return y + self.itemheight;
end

function ISGSBQoLRankingAdminWindow:onClick(button)
    if button.internal == "CLOSE" then
        self:close();
    elseif button.internal == "SAVE" then
        local ignorePlayersList = nil
        if #self.hiddenPlayersList.items > 0 then
            ignorePlayersList = {}
        end

        for i, listItem in ipairs(self.hiddenPlayersList.items) do
            local player = listItem.item;
            ignorePlayersList[player.name] = player;
        end

        sendClientCommand(getPlayer(), GSBQoL.Rankings.Shared.MODULE_NAME, "IgnorePlayers", ignorePlayersList);
    elseif button.internal == "REFRESH" then
        sendClientCommand(getPlayer(), GSBQoL.Rankings.Shared.MODULE_NAME, "BroadcastAdmin", nil);
    elseif luautils.stringStarts(button.internal, "FACTION_SEASON") then
        self.modalConfirmReset = ISGSBQoLRankingAdminConfirmModal:new(1, 1, self:getWidth() - 2, self:getHeight() - 2);

        if button.internal == "FACTION_SEASON_RESET" then
            self.modalConfirmReset:setAction("FactionSeasonReset")
        elseif button.internal == "FACTION_SEASON_NEW" then
            self.modalConfirmReset:setAction("FactionSeasonNew")
        end
        self.modalConfirmReset:initialise();
        self.modalConfirmReset:instantiate();

        self:addChild(self.modalConfirmReset);
    end
end

function ISGSBQoLRankingAdminWindow:setKeyboardFocus()
    Core.UnfocusActiveTextEntryBox()
end

ISGSBQoLRankingAdminConfirmModal = ISPanel:derive("ISGSBQoLRankingAdminConfirmModal");

function ISGSBQoLRankingAdminConfirmModal:new(x, y, width, height, title)
    local o = {}
    o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self

    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 0 };
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.8 };
    o.width = width;
    o.height = height;
    o.title = title;
    o.action = nil;

    return o;
end

function ISGSBQoLRankingAdminConfirmModal:createChildren()
    local width = 250;
    local x = (self.width - width) / 2
    local height = 80;
    local y = (self.height - height) / 2

    local title = "";
    if self.action == "FactionSeasonReset" then
        title = getText("UI_GSBQoLRankings_confirmModal_resetFaction");
    elseif self.action == "FactionSeasonNew" then
        title = getText("UI_GSBQoLRankings_confirmModal_newFaction");
    end

    if title ~= "" then
        title = getText("UI_GSBQoLRankings_confirmModal_base") .. title .. " <LINE> <LINE>";
    end

    local modal = ISModalRichText:new(x, y, width, height, title, true, self, ISGSBQoLRankingAdminConfirmModal.buttonClick, player);
    modal:initialise();
    self:addChild(modal);
    modal:bringToTop();
    modal.ui = self;
    modal.moveWithMouse = false;
end

function ISGSBQoLRankingAdminConfirmModal:setAction(action)
    self.action = action;
end

function ISGSBQoLRankingAdminConfirmModal:buttonClick(button)
    self:setVisible(false);
    if button.internal == "YES" then
        self:performFactionSeasonAction(self.action);
    end
end

function ISGSBQoLRankingAdminConfirmModal:performFactionSeasonAction(action)
    print("ISGSBQoLRankingAdminWindow:performFactionSeasonAction: ", action);
    if action ~= nil then
        sendClientCommand(getPlayer(), GSBQoL.Rankings.Shared.MODULE_NAME, action, {});
        self:removeFromUIManager();
    end
end
