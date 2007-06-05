local deletedelay, t = 0.5, 0
local button, waitForMail, doNothing, openAll, openMail, lastopened
function doNothing() end
function openAll()
	button:SetScript("OnClick", donothing)
	if GetInboxNumItems() == 0 then return end
	openMail(1)
end
function openMail(index)
	if not InboxFrame:IsVisible() then return end
	local _, _, _, _, money, COD, _, hasItem = GetInboxHeaderInfo(index)
	if money > 0 then TakeInboxMoney(index)
	elseif hasItem and COD <= 0 then TakeInboxItem(index) end
	local items = GetInboxNumItems()
	if index < items and items > 1 then
		lastopened = index
		t = 0
		button:SetScript("OnUpdate", waitForMail)
	else
		button:SetScript("OnClick", openAll)
	end
end
function waitForMail()
	t = t + arg1
	if t > deletedelay then
		button:SetScript("OnUpdate", nil)
		local _, _, _, _, money, _, _, hasItem = GetInboxHeaderInfo(lastopened)
		if money > 0 or hasItem then --deleted or bumped
			openMail(lastopened)
		else
			openMail(lastopened + 1)
		end
	end
end

button = CreateFrame("Button", "OpenAllButton", InboxFrame, "UIPanelButtonTemplate")
button:SetWidth(120)
button:SetHeight(25)
button:SetPoint("CENTER", InboxFrame, "TOP", -15, -410)
button:SetText("Open All")
button:SetScript("OnClick", openAll)
