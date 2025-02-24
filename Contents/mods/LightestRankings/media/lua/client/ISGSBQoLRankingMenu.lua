ISGSBQoLRankingMenu = ISPanel:derive("ISGSBQoLRankingMenu");

function ISGSBQoLRankingMenu:new(x, y, width, height)
    local o = {}
    o = ISPanel:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 };
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.1 };
    o.activeBackgroundColor = { r = 1, g = 1, b = 1, a = 0.3 };
    o.width = width;
    o.height = height;
    o.marginTop = 0;
    o.marginLeft = 0;
    o.marginBottom = 0;
    o.marginRight = 0;
    o.buttons = {}
    o.buttonSize = 30;

    ISGSBQoLRankingMenu.instance = o;
    return o;
end

ISGSBQoLRankingMenuButton = ISButton:derive("ISGSBQoLRankingMenuButton");
function ISGSBQoLRankingMenuButton:new(x, y, width, height, type, clicktarget, onclick, onmousedown, allowMouseUpProcessing)
    local o = {}
    o = ISButton:new(x, y, width, height, "", clicktarget, onclick, onmousedown, allowMouseUpProcessing);
    setmetatable(o, self)
    self.__index = self

    o.borderColor = { r = 1, g = 1, b = 1, a = 0.1 };
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.1 };
    o.activeBackgroundColor = { r = 1, g = 1, b = 1, a = 0.3 };
    o.active = false
    o.internal = string.upper(type);
    o:setImage(self:getMenuIcon(type));
    --o.tooltip = self:getTooltip(type);

    return o;
end

function ISGSBQoLRankingMenuButton:prerender()
    ISButton.prerender(self);

    if self.active then
        self:drawRect(0, 0, self.width, self.height, self.activeBackgroundColor.a, self.activeBackgroundColor.r, self.activeBackgroundColor.g, self.activeBackgroundColor.b);
    else
        self:drawRect(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b);
    end
    self:drawRectBorder(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b);
end

function ISGSBQoLRankingMenuButton:getMenuIcon(icon)
    return getTexture("media/textures/" .. icon .. ".png");
end

function ISGSBQoLRankingMenuButton:getTooltip(icon)
    if icon == "kills" then
        return getText("UI_GSBQoL_Rankings_SubMenu_Kills");
    elseif icon == "deaths" then
        return getText("UI_GSBQoL_Rankings_SubMenu_Deaths");
    elseif icon == "overall_kills" then
        return getText("UI_GSBQoL_Rankings_SubMenu_OverallKills");
    elseif icon == "lifetime" then
        return getText("UI_GSBQoL_Rankings_SubMenu_Lifetime");
    elseif icon == "faction_kills" then
        return getText("UI_GSBQoL_Rankings_SubMenu_Factions");
    end
end

function ISGSBQoLRankingMenu:createButton(scoreboard)
    local button = ISGSBQoLRankingMenuButton:new(#self.buttons * self.buttonSize, 0, self.buttonSize, self.buttonSize, scoreboard.name, self);
    button:initialise();
    button.scoreboard = scoreboard;
    button:setOnClick(ISGSBQoLRankingMenu.onClick);
    self:addChild(button);

    table.insert(self.buttons, button);
    if #self.buttons == 1 then
        button.active = true;
        scoreboard:setVisible(true);
    end
    return button;
end

function ISGSBQoLRankingMenu:pack()
    self:setWidth(#self.buttons * self.buttonSize);
end

function ISGSBQoLRankingMenu:onClick(button)
    for i, _button in ipairs(self.buttons) do
        if _button ~= button then
            _button.scoreboard:setVisible(false);
            _button.active = false;
        end
    end
    button.active = true;
    button.scoreboard:setVisible(true);
end
