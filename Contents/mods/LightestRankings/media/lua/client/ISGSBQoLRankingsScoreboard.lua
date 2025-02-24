-- ************************************************************
-- ************** ISCoelhoTradeSystemItemListBox **************
-- ************************************************************

local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.NewSmall)

ISRankingScoreboardItemListBox = ISScrollingListBox:derive("ISRankingScoreboardItemListBox");

function ISRankingScoreboardItemListBox:new (x, y, width, height)
    local o = {};
    o = ISScrollingListBox:new(x, y, width, height);
    setmetatable(o, self);
    self.__index = self;

    o:setFont(UIFont.NewSmall, 3);
    o:clear();
    o.drawBorder = true;
    o.drawBorder = false;
    o.doDrawItem = self.doDrawItemPlayer;
    o.itemheight = FONT_HGT_SMALL;
    o.valueFormatter = nil;
    o.namePosition = 13;
    o.scrollWidth = 0;

    o.firstColors = {
        { r = 0.98, g = 0.77, b = 0.03 },
        { r = 0.90, g = 0.90, b = 0.90 },
        { r = 0.66, g = 0.39, b = 0.18 },
    }
    o.descending = true;

    return o;
end

function ISRankingScoreboardItemListBox:clear()
    self.items = {}
    self.selected = -1;
    self.itemheightoverride = {}
    self.count = 0;
end

function ISRankingScoreboardItemListBox:onMouseDown(x, y)
end

function ISRankingScoreboardItemListBox:doDrawItemPlayer(y, listItem, alt)
    local a = 0.95;
    local yAdjust = math.floor((self.itemheight - FONT_HGT_SMALL) / 2);
    local PADDING = 7;
    local color = { r = 1, g = 1, b = 1 }
    local item = listItem.item;

    if item.indexToList <= 3 then
        color = self.firstColors[item.indexToList];
    end
    if self.count >= 10 then
        self.namePosition = 6
    end

    local textValue = tostring(item.value);
    if self.valueFormatter ~= nil then
        textValue = self:valueFormatter(item.value);
    end
    if self.count > 20 then
        self.scrollWidth = self:getWidth() - self.vscroll:getX() - 3;
    end
    local xValue = self:getWidth() - PADDING - self.scrollWidth - getTextManager():MeasureStringX(self.font, textValue);
    self:drawText(textValue, xValue, y + yAdjust, color.r, color.g, color.b, a, self.font);

    if item.nameAdjusted ~= nil then
        self:drawText(item.nameAdjusted, PADDING + self.namePosition + 5, y + yAdjust, color.r, color.g, color.b, a, self.font);
    else
        local nameWidthMax = xValue - (PADDING + self.namePosition + 5) - 5;
        if nameWidthMax < 30 then
            nameWidthMax = 30;
            if self.createTooltip == nil then
                self.createTooltip = ISRankingScoreboardItemListBox.nameTooltip;
            end
        end
        local nameAdjusted = item.name;
        if getTextManager():MeasureStringX(self.font, nameAdjusted) > nameWidthMax then
            while getTextManager():MeasureStringX(self.font, nameAdjusted .. "...") > nameWidthMax do
                nameAdjusted = string.sub(nameAdjusted, 1, string.len(nameAdjusted) - 1)
            end
            nameAdjusted = nameAdjusted .. "...";

        end
        item.nameAdjusted = nameAdjusted;
        self:drawText(item.nameAdjusted, PADDING + self.namePosition + 5, y + yAdjust, color.r, color.g, color.b, a, self.font);
    end

    local positionText = tostring(item.indexToList);
    if item.index ~= item.indexToList then
        a = 0.4;
    end
    self:drawText(positionText, PADDING + self.namePosition - getTextManager():MeasureStringX(self.font, positionText), y + yAdjust, color.r, color.g, color.b, a, self.font);

    local extra = 0;
    if item.indexToList == 3 and self.count > 3 then
        extra = 8;
        local next = nil;
        if item.index + 1 <= self.count then
            next = self.items[item.index + 1].item;
        end
        if next ~= nil then
            if next.indexToList == item.indexToList then
                extra = 0;
            end
        end
    end

    return y + self.itemheight + extra;
end

function ISRankingScoreboardItemListBox:addItem(name, item)
    local i = {}
    i.text = name;
    i.item = item;
    i.tooltip = nil;
    if self.createTooltip then
        i.tooltip = self:createTooltip(item);
    end
    i.itemindex = self.count + 1;
    i.height = self.itemheight
    table.insert(self.items, i);
    self.count = self.count + 1;
    self:setScrollHeight(self:getScrollHeight() + i.height);
    return i;
end

function ISRankingScoreboardItemListBox:nameTooltip(listItem)
    if listItem then
        return (tostring(listItem.indexToList) .. ". " .. listItem.name);
    end
    return "";
end

function ISRankingScoreboardItemListBox:factionTooltip(listItem)
    local faction = listItem.rawData;
    local color = faction.color or { r = 1, b = 1, g = 1 };
    local textColor = "<RGB:" .. tostring(color.r) .. "," .. tostring(color.g) .. "," .. tostring(color.b) .. ">"
    local text = textColor .. " " .. faction.name .. " <LINE>";
    if faction.tag then
        text = text .. textColor .. "[" .. faction.tag .. "] <LINE>";
    end

    text = text .. " <LINE>";

    if faction.killsDetailed then
        text = text .. " <RGB:1,1,1>" .. getText("UI_GSBQoLRankings_players") .. " <LINE>";

        local ordered = {}
        for k, kills in pairs(faction.killsDetailed) do
            table.insert(ordered, { name = k, value = kills });
        end
        table.sort(ordered, function(a, b)
            if a.value == b.value then
                return a.name < b.name;
            else
                return a.value > b.value;
            end
        end)
        for i, item in ipairs(ordered) do
            text = text .. " <RGB:1,1,1>" .. item.name .. " - " .. tostring(item.value) .. " <LINE>";
        end
    end
    return text;
end

function ISRankingScoreboardItemListBox:formatLifetime(hours)
    if not hours or type(hours) ~= "number" or hours < 0 then
        return "N/A" -- Handles nil, non-numeric, or invalid values safely
    end

    local function append(text, value, suffix)
        if value > 0 then
            return (text ~= "" and text .. " " or "") .. tostring(value) .. suffix
        end
        return text
    end

    local totalMinutes = math.floor(hours * 60)
    if totalMinutes < 60 then
        return tostring(totalMinutes) .. "min" -- Return only minutes if under 1 hour
    end

    local totalHours = math.floor(hours)
    local days = math.floor(totalHours / 24)
    local months = math.floor(days / 30)
    local years = math.floor(months / 12)

    local remainingDays = days % 30
    local remainingMonths = months % 12
    local remainingHours = totalHours % 24
    local remainingMinutes = totalMinutes % 60

    local formattedTime = ""
    formattedTime = append(formattedTime, years, "y")
    formattedTime = append(formattedTime, remainingMonths, "m")
    formattedTime = append(formattedTime, remainingDays, "d")
    formattedTime = append(formattedTime, remainingHours, "h")
    formattedTime = append(formattedTime, remainingMinutes, "min")

    return formattedTime
end
