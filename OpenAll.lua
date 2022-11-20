local myname, ns = ...
local myfullname = GetAddOnMetadata(myname, "Title")

local DELETE_DELAY = 0.15
local mail_checker, copper_to_pretty_money
local baseInboxFrame_OnClick
local doNothing = function() end

-- Need to move OpenAllMail a little
-- <Anchor point="CENTER" relativePoint="BOTTOM" x="-21" y="114"/>
OpenAllMail:SetPoint("CENTER", InboxFrame, "BOTTOM", -54, 114)
OpenAllMail:SetWidth(80)

local button = CreateFrame("Button", "OpenAllCashButton", InboxFrame, "UIPanelButtonTemplate")
button:SetText(MONEY)
button:SetSize(60, 25)
button:SetPoint("LEFT", OpenAllMail, "RIGHT", 5, 0)

button:SetScript("OnEvent", function(self, event, ...)
	self[event](self, event, ...)
end)

function button:UI_ERROR_MESSAGE(event, msg_type, error_msg)
	if error_msg == ERR_INV_FULL then
		return self:StopOpening("Stopped, inventory is full.")
	end
	if error_msg == ERR_ITEM_MAX_COUNT then
		self:ProcessMail(lastopened - 1)
	end
end

button:SetScript("OnClick", function(self)
	if GetInboxNumItems() == 0 then
		return
	end
	self:Disable()
	self:RegisterEvent("UI_ERROR_MESSAGE")

	OpenAllMail:Disable()
	baseInboxFrame_OnClick = InboxFrame_OnClick
	InboxFrame_OnClick = doNothing

	self.currentIndex = GetInboxNumItems()
	self:ProcessMail(GetInboxNumItems())
end)

button:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	-- GameTooltip:AddLine(string.format("%d messages", GetInboxNumItems()), 1, 1, 1)
	GameTooltip:AddLine(copper_to_pretty_money(self:TotalCash()), 1, 1, 1)
	GameTooltip:Show()
end)

button:SetScript("OnLeave", function() GameTooltip:Hide() end)

button:SetScript("OnHide", function(self)
	if self.currentIndex then
		self:StopOpening("Need a mailbox.")
	end
end)


function button:ProcessMail(index)
	if not InboxFrame:IsVisible() then
		return
	end
	if index == 0 then
		return self:StopOpening("All done.")
	end
	self.currentIndex = index
	local _, _, _, _, money, COD, _, numItems, _, _, _, _, fromGM = GetInboxHeaderInfo(index)
	-- If there's money and it's not from a GM, take it
	if money > 0 and not (fromGM or (COD and COD > 0)) then
		TakeInboxMoney(index)
		if self.total_cash then
			self.total_cash = self.total_cash - money
		end
		self:SetScript("OnUpdate", self.WaitForMail)
	else
		return self:ProcessMail(index - 1)
	end
end

function button:StopOpening(msg, ...)
	self:SetScript("OnUpdate", nil)
	self:Enable(false)

	OpenAllMail:Enable()
	if baseInboxFrame_OnClick then
		InboxFrame_OnClick = baseInboxFrame_OnClick
	end
	self:UnregisterEvent("UI_ERROR_MESSAGE")
	self.total_cash = nil
	self.currentIndex = nil
	if msg then
		DEFAULT_CHAT_FRAME:AddMessage(myfullname .. ": " .. msg, ...)
	end

	mail_checker:Show()
end

button.elapsed = 0
function button:WaitForMail(sinceLast)
	self.elapsed = self.elapsed + sinceLast
	if self.elapsed > DELETE_DELAY then
		if not InboxFrame:IsVisible() then
			return self:StopOpening()
		end
		self.elapsed = 0
		if C_Mail.IsCommandPending() then
			-- Wait for more
			return
		end
		self:SetScript("OnUpdate", nil)

		local _, _, _, _, money = GetInboxHeaderInfo(self.currentIndex)
		if money > 0 then
			--The lastopened index inbox item still contains stuff we want
			self:ProcessMail(self.currentIndex)
		else
			self:ProcessMail(self.currentIndex - 1)
		end
	end
end

function button:TotalCash()
	local index
	if not self.total_cash then
		self.total_cash = 0
		for index=0, GetInboxNumItems() do
			self.total_cash = self.total_cash + select(5, GetInboxHeaderInfo(index))
		end
	end
	return self.total_cash
end

function copper_to_pretty_money(c)
	if c > 10000 then
		return ("%d|cffffd700g|r%d|cffc7c7cfs|r%d|cffeda55fc|r"):format(c/10000, (c/100)%100, c%100)
	elseif c > 100 then
		return ("%d|cffc7c7cfs|r%d|cffeda55fc|r"):format((c/100)%100, c%100)
	else
		return ("%d|cffeda55fc|r"):format(c%100)
	end
end

if _G.MiniMapMailFrame then
	mail_checker = CreateFrame("Frame")
	mail_checker:Hide()
	mail_checker:SetScript("OnShow", function(this)
		this:RegisterEvent("MAIL_INBOX_UPDATE")
		CheckInbox()
	end)
	mail_checker:SetScript("OnHide", function(this)
		if select(2, GetInboxNumItems()) > 0 then
			MiniMapMailFrame:Show()
		else
			MiniMapMailFrame:Hide()
		end
	end)
	mail_checker:SetScript("OnEvent", function(this, event, ...)
		if event == "MAIL_INBOX_UPDATE" then
			this:Hide()
			this:UnregisterEvent("MAIL_INBOX_UPDATE")
		end
	end)
end
