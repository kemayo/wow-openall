local deletedelay, t = 0.5, 0
local button, waitForMail, doNothing, openAll, openMail, lastopened, stopOpening, onEvent
local _G = getfenv(0)
local baseInboxFrame_OnClick
function doNothing() end
function openAll()
	button:SetScript("OnClick", nil)
	if GetInboxNumItems() == 0 then return end
	baseInboxFrame_OnClick = InboxFrame_OnClick
	InboxFrame_OnClick = doNothing
	for i = 1, 7 do _G["MailItem" .. i .. "ButtonIcon"]:SetDesaturated(1) end
	button:RegisterEvent("UI_ERROR_MESSAGE")
	openMail(GetInboxNumItems())
end
function stopOpening()
	button:SetScript("OnUpdate", nil)
	button:SetScript("OnClick", openAll)
	if baseInboxFrame_OnClick then
		InboxFrame_OnClick = baseInboxFrame_OnClick
	end
	for i = 1, 7 do _G["MailItem" .. i .. "ButtonIcon"]:SetDesaturated(nil) end
	button:UnregisterEvent("UI_ERROR_MESSAGE")
end
function openMail(index)
	if not InboxFrame:IsVisible() or index == 0 then return stopOpening() end
	local _, _, _, _, money, COD, _, hasItem = GetInboxHeaderInfo(index)
	if money > 0 then TakeInboxMoney(index)
	elseif hasItem and COD <= 0 then TakeInboxItem(index) end
	local items = GetInboxNumItems()
	if items > 1 and index < items + 1 then
		lastopened = index
		t = 0
		button:SetScript("OnUpdate", waitForMail)
	else
		stopOpening()
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
			openMail(lastopened - 1)
		end
	end
end
function onEvent(frame, event, arg1, arg2, arg3, arg4)
	if event == "UI_ERROR_MESSAGE" then
		if arg1 == ERR_INV_FULL then
			stopOpening()
		end
	end
end
button = CreateFrame("Button", "OpenAllButton", InboxFrame, "UIPanelButtonTemplate")
button:SetWidth(120)
button:SetHeight(25)
button:SetPoint("CENTER", InboxFrame, "TOP", -15, -410)
button:SetText("Open All")
button:SetScript("OnClick", openAll)
button:SetScript("OnEvent", onEvent)