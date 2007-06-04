local button
local function doNothing() end
local function openAll()
	button:SetScript("OnClick", donothing)
	for i = 1, GetInboxNumItems(), 1 do
		if not InboxFrame:IsVisible() then break end
		local _, _, _, _, money, COD, _, hasItem, _, wasReturned, _, canReply = GetInboxHeaderInfo(i)
		if money > 0 then TakeInboxMoney(index)
		elseif hasItem and COD <= 0 then TakeInboxItem(index) end
	end
	button:SetScript("OnClick", openAll)
end

button = CreateFrame("Button", "OpenAllButton", InboxFrame, "UIPanelButtonTemplate")
button:SetWidth(120)
button:SetHeight(25)
button:SetPoint("CENTER", InboxFrame, "TOP", -15, -410)
button:SetText("Open All")
button.owner = self
button:SetScript("OnClick", openAll)
