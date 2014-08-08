-----------------------------------------------------------------------------------------------
-- Client Lua Script for BetterMoneyInput
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"
 
-----------------------------------------------------------------------------------------------
-- BetterMoneyInput Module Definition
-----------------------------------------------------------------------------------------------
BetterMoneyInput = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon(
																	"BetterMoneyInput", 
																	false,
																	{},
																	"Gemini:Hook-1.0"
																	)
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999

local function GetRealPos(window)
	local startx,starty=window:GetPos()
	
	if(window:GetParent()~=nil) then
		 local curwindow = window:GetParent()
		 --while curwindow:GetParent()~=nil do
		repeat
			local x,y = curwindow:GetPos()
			startx=startx+x
			starty=starty+y
			
			curwindow = curwindow:GetParent()
		until curwindow==nil
		
		
	end
	return  startx,starty
end


local function print_r (t, indent, done)
  done = done or {}
  indent = indent or ''
  local nextIndent -- Storage for next indentation value
  for key, value in pairs (t) do
    if type (value) == "table" and not done [value] then
      nextIndent = nextIndent or
          (indent .. string.rep(' ',string.len(tostring (key))+2))
          -- Shortcut conditional allocation
      done [value] = true
      Print (indent .. "[" .. tostring (key) .. "] => Table {");
      Print  (nextIndent .. "{");
      print_r (value, nextIndent .. string.rep(' ',2), done)
      Print  (nextIndent .. "}");
    else
      Print  (indent .. "[" .. tostring (key) .. "] => " .. tostring (value).."")
    end
  end
end
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function BetterMoneyInput:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function BetterMoneyInput:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- BetterMoneyInput OnLoad
-----------------------------------------------------------------------------------------------
function BetterMoneyInput:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("BetterMoneyInput.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- BetterMoneyInput OnDocLoaded
-----------------------------------------------------------------------------------------------
function BetterMoneyInput:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "BetterMoneyInputForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
		self.objects = {}
	    self.wndMain:Show(false, true)
		--Apollo.RegisterSlashCommand("bm", "OnYeeHatOn", self)
		
		self:PostHook(Apollo.GetAddon("MarketplaceCommodity"),"OnListInputPriceMouseDown","CommodityOnListInputPriceMouseDown")
		self:PostHook(Apollo.GetAddon("MarketplaceCommodity"),"OnDestroy","HideGoldInput")
		self.objects["commodity"] = Apollo.GetAddon("MarketplaceCommodity")
		
		--self.objects["mail"] = Apollo.GetAddon("Mail")
		
		self.moneychild = {}
		self.moneychild["commodity"] = "ListInputPrice"
		if(Apollo.GetAddon("MarketplaceAuction")~=nil) then
			Apollo.GetAddon("MarketplaceAuction").OnGoldSellBidInputMouseDown = function (wndHandler, wndControl) self:OnGoldInputMouseDown(wndHandler,wndControl,"auction") end
			Apollo.GetAddon("MarketplaceAuction").OnGoldSellBuyOutInputMouseDown = function (wndHandler, wndControl) self:OnGoldInputMouseDown(wndHandler,wndControl,"auction") end
			Apollo.GetAddon("MarketplaceAuction").OnGoldBuyBidInputMouseDown = function (wndHandler, wndControl) self:OnGoldInputMouseDown(wndHandler,wndControl,"auction") end
			self:PostHook(Apollo.GetAddon("MarketplaceAuction"),"OnToggleAuctionWindow")
		--self:PostHook(Apollo.GetAddon("MarketplaceAuction"),"OnCreateBuyoutInputBoxChanged","OnToggleAuctionWindow")
			self:PostHook(Apollo.GetAddon("MarketplaceAuction"),"OnDestroy","HideGoldInput")
			self.objects["auction"] = Apollo.GetAddon("MarketplaceAuction")
			self.moneychild["auction"] = {parentFrame='MarketplaceAuctionForm'}
		elseif (Apollo.GetAddon("EZAuction")~=nil) then
			Apollo.GetAddon("EZAuction").OnGoldSellBidInputMouseDown = function (wndHandler, wndControl) self:OnGoldInputMouseDown(wndHandler,wndControl,"auction") end
			Apollo.GetAddon("EZAuction").OnGoldSellBuyOutInputMouseDown = function (wndHandler, wndControl) self:OnGoldInputMouseDown(wndHandler,wndControl,"auction") end
			Apollo.GetAddon("EZAuction").OnGoldBuyBidInputMouseDown = function (wndHandler, wndControl) self:OnGoldInputMouseDown(wndHandler,wndControl,"auction") end
			self:PostHook(Apollo.GetAddon("EZAuction"),"OnToggleAuctionWindow")
		--self:PostHook(Apollo.GetAddon("MarketplaceAuction"),"OnCreateBuyoutInputBoxChanged","OnToggleAuctionWindow")
			self:PostHook(Apollo.GetAddon("EZAuction"),"OnDestroy","HideGoldInput")
			self.objects["auction"] = Apollo.GetAddon("EZAuction")
			self.moneychild["auction"] = {parentFrame='EZAuctionForm'}
		end
		
		if(Apollo.GetAddon("Trading")~=nil) then
		    self.objects["trade"] = Apollo.GetAddon("Trading")
			Apollo.GetAddon("Trading").OnGoldInputMouseDown = function (wndHandler, wndControl) self:OnGoldInputMouseDown(wndHandler,wndControl,"trade") end
			self:PostHook(Apollo.GetAddon("Trading"),"OnCancelBtn","HideGoldInput")
			self:PostHook(Apollo.GetAddon("Trading"),"OnP2PTradeResult","HideGoldInput")
			self:PostHook(Apollo.GetAddon("Trading"),"OnP2PTradeWithTarget","TradeWindowOpen")
		end
		--AddEventHandler("MouseButtonDown", "close", self)
		--Apollo.FindWindow("MarketPlaceAuctionForm")
		
		
		
		--self.moneychild["CreateBidInputBox"] = "CreateBidInputBox"
		--self.moneychild["CreateBuyoutInputBox"] = "CreateBuyoutInputBox"
		--self.moneychild["BottomBidPrice"] = "BottomBidPrice"
		--self.moneychild["auction"] = "BottomBidPrice"
		
		--self.currentTarget=0
		
		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)


		-- Do additional Addon initialization here
	end
end




function BetterMoneyInput:OnGoldInputMouseDown(wndHandler, wndControl,which)
	
	self.childwindow = wndControl:GetName()
	self.currentObject = which
	
	local x,y=GetRealPos(wndControl)
	
	self.wndMain:SetAnchorOffsets(x-10,y,x+self.wndMain:GetWidth()-10,y+self.wndMain:GetHeight())
	
	local wndListInputPrice = wndControl:GetAmount() 
	--Print(wndListInputPrice)
	self.currentTarget = wndControl
	
	self:SetGoldInput(wndListInputPrice)
	
	
end

function BetterMoneyInput:TradeWindowOpen()
	
	Apollo.FindWindowByName("SecureTrade"):FindChild("YourCash"):AddEventHandler("MouseButtonDown", "OnGoldInputMouseDown")
end

function BetterMoneyInput:OnToggleAuctionWindow()
	
	Apollo.FindWindowByName(self.moneychild["auction"].parentFrame):FindChild("CreateBuyoutInputBox"):AddEventHandler("MouseButtonDown", "OnGoldSellBuyOutInputMouseDown")
	Apollo.FindWindowByName(self.moneychild["auction"].parentFrame):FindChild("CreateBidInputBox"):AddEventHandler("MouseButtonDown", "OnGoldSellBidInputMouseDown")
	Apollo.FindWindowByName(self.moneychild["auction"].parentFrame):FindChild("BottomBidPrice"):AddEventHandler("MouseButtonDown", "OnGoldBuyBidInputMouseDown")
	Apollo.FindWindowByName(self.moneychild["auction"].parentFrame):FindChild("BottomBidPrice"):SetStyle("IgnoreMouse",false)
end

--function BetterMoneyInput:AuctionMouseDown()
--	Print("down")
--end

-----------------------------------------------------------------------------------------------
-- BetterMoneyInput Functions
-----------------------------------------------------------------------------------------------
-- Define general functions here
function BetterMoneyInput:HideGoldInput()
--Print("destroy")
	self.wndMain:Show()
end

--function BetterMoneyInput:MailBoxShowGoldInput()
--	self.wndMain:Show(true)
--end



function BetterMoneyInput:CommodityOnListInputPriceMouseDown(wndHandler, wndControl)
    --print_r(wndControl:GetData():GetData())
	self.childwindow = "ListInputPrice"
	self.currentObject = "commodity"
	self:GetCurrentPrice(wndControl)
	local x,y=GetRealPos(wndControl)
	
	self.wndMain:SetAnchorOffsets(x-10,y,x+self.wndMain:GetWidth()-10,y+self.wndMain:GetHeight())
end

--function BetterMoneyInput:AuctionOnListInputPriceMouseDown(wndHandler, wndControl)
	--print_r(wndControl:GetData())
	--self.currentObject = "auction"
	--self:GetCurrentPrice(wndHandler, wndControl)

		
--end

function BetterMoneyInput:GetCurrentPrice(wndControl)
	local wndListInputPrice = wndControl:GetData():FindChild(self.childwindow):GetAmount() 
	--Print(wndListInputPrice)
	self.currentTarget = wndControl
	
	self:SetGoldInput(wndListInputPrice)

end

-----------------------------------------------------------------------------------------------
-- BetterMoneyInputForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked
function BetterMoneyInput:OnYeeHatOn()
	--Apollo.FindWindowByName("MarketplaceAuctionForm"):FindChild("CreateBuyoutInputBox"):SetAmount(1000)
end

function BetterMoneyInput:CalcGoldValuesInput(amount)
	--Print(amount)
	local platin = math.floor(amount / 100 / 100 / 100)
	local gold = math.floor((amount / 100 / 100) % 100)
 	local silver = math.floor((amount / 100) % 100)
	local copper = math.floor(amount % 100)
	return platin,gold,silver,copper
    --silver = (rval / 100) % 100
    --copper = rval % 100
end

local function reformat(number,noplatin)
	if(type(number)~="number") then
		return "00"
	end
	
	if(number<10 and noplatin==true) then
		return tostring("0"..number)
	elseif(number>100 and noplatin==true) then
		return tostring(99)
	else
		return tostring(number)
	
	end

end




function BetterMoneyInput:CalcInputGoldValues()

	
	local platin = reformat(tonumber(self.wndMain:FindChild("InputPlatin"):GetText()),false)
	local gold =  reformat(tonumber(self.wndMain:FindChild("InputGold"):GetText()),true)
 	local silver = reformat(tonumber(self.wndMain:FindChild("InputSilver"):GetText()),true)
	local copper = reformat(tonumber(self.wndMain:FindChild("InputCopper"):GetText()),true)
	return platin..gold..silver..copper

end

function BetterMoneyInput:SetGoldInput(amount)
	local platin,gold,silver,copper=self:CalcGoldValuesInput(amount)
	self.wndMain:FindChild("InputPlatin"):SetText(platin)
	self.wndMain:FindChild("InputGold"):SetText(gold)
	self.wndMain:FindChild("InputSilver"):SetText(silver)
	self.wndMain:FindChild("InputCopper"):SetText(copper)
	self.wndMain:Show(true)
	self.wndMain:ToFront()
	self.wndMain:FindChild("InputPlatin"):SetFocus()

end

function BetterMoneyInput:UpdateGoldString()
	if(self.currentObject == "commodity") then
		self.currentTarget:GetData():FindChild("ListInputPrice"):SetAmount(self:CalcInputGoldValues()) 
		self.objects[self.currentObject]:HelperValidateListInputForSubmit(self.currentTarget:GetData())
	elseif(self.currentObject == "auction") then
		self.currentTarget:SetAmount(self:CalcInputGoldValues())
		
		if(self.currentTarget:GetName() == "BottomBidPrice") then
			self.objects[self.currentObject]:HelperValidateBidEditBoxInput()
		else
		
			self.objects[self.currentObject]:ValidateSellOrder()
		end
	elseif(self.currentObject == "trade") then
		local nNewAmount = tonumber(self:CalcInputGoldValues())
		local nPlayerCash = GameLib.GetPlayerCurrency():GetAmount()
		if nNewAmount > nPlayerCash then
			nNewAmount = nPlayerCash
		end
		P2PTrading.SetMoney(nNewAmount)	
		self.currentTarget:SetAmount(self:CalcInputGoldValues())
	
	
	end
end


-----------------------------------------------------------------------------------------------
-- BetterMoneyInput Instance
-----------------------------------------------------------------------------------------------
local BetterMoneyInputInst = BetterMoneyInput:new()
BetterMoneyInputInst:Init()
