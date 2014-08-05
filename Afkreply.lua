-----------------------------------------------------------------------------------------------
-- Client Lua Script for Afkreply
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"

-----------------------------------------------------------------------------------------------
-- Afkreply Module Definition
-----------------------------------------------------------------------------------------------
local Afkreply = {} 
local defaults = {} 
defaults.tSendAwayToChannel = {}
defaults.tSendBackToChannel = {}
defaults.Message = {}
defaults.Message.AutoReplyMessage = "AfkReply: I am away from keyboard but your name has been saved and i will /w you back soon."
defaults.Message.BackMessage = "AfkReply: I am no longer afk"
defaults.Message.AwayMessage = "AfkReply: I will be afk for a while"
defaults.SendAutoReply = true
defaults.SendBackMessage = false
defaults.SendAwayMessage = false
-- which channels to send to
-- away
defaults.tSendAwayToChannel.Say = false
defaults.tSendAwayToChannel.Party = false
defaults.tSendAwayToChannel.Instance= false
defaults.tSendAwayToChannel.Guild = false
defaults.tSendAwayToChannel.Officer = false
defaults.tSendAwayToChannel.Zone = false
-- back
defaults.tSendBackToChannel.Say = false
defaults.tSendBackToChannel.Party = false
defaults.tSendBackToChannel.Instance= false
defaults.tSendBackToChannel.Guild = false
defaults.tSendBackToChannel.Officer = false
defaults.tSendBackToChannel.Zone = false
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
local bPlayerAway = false
local lastSent = nil


function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function Afkreply:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    -- initialize variables here

    return o
end

function Afkreply:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- Afkreply OnLoad
-----------------------------------------------------------------------------------------------
function Afkreply:OnLoad()
    -- load our form file
	self.xmlDoc = XmlDoc.CreateFromFile("Afkreply.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	
	
end

-----------------------------------------------------------------------------------------------
-- Afkreply OnDocLoaded
-----------------------------------------------------------------------------------------------
function Afkreply:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndMain = Apollo.LoadForm(self.xmlDoc, "AfkreplyForm", nil, self)
		if self.wndMain == nil then
			Apollo.AddAddonErrorText(self, "Could not load the main window for some reason.")
			return
		end
	    self.wndMain:Show(false, true)
		-- if the xmlDoc is no longer needed, you should set it to nil
		-- self.xmlDoc = nil
		
		-- Register handlers for events, slash commands and timer, etc.
		-- e.g. Apollo.RegisterEventHandler("KeyDown", "OnKeyDown", self)
		Apollo.RegisterSlashCommand("afkreply", "OnAfkreplyOn", self)
		Apollo.RegisterSlashCommand("back", "OnBack", self)
		Apollo.RegisterSlashCommand("away", "OnAway", self)
		Apollo.RegisterSlashCommand("afksetting", "OnSetting", self)
		Apollo.RegisterSlashCommand("afkreplysetting", "OnSetting", self)
		Apollo.RegisterEventHandler("ChatMessage", "OnChatMessage", self)
		
		self.wndSetting = Apollo.LoadForm(self.xmlDoc, "Setting", nil, self)
		self.wndSetting:Show(false,true)
		self.MsgWindow = Apollo.LoadForm(self.xmlDoc, "MsgList" ,nil,self)
		self.MsgWindow:Show(false,true)
		self.wndChangeMsg = Apollo.LoadForm(self.xmlDoc, "ChangeMessageForm" , nil ,self)
		
		self.wndChangeMsg:Show(false,true)
		self.WhisperMsg = {}
		
		if self.LoadedData == nil then
			self.tSettings = deepcopy(defaults)
		else
			self.tSettings = deepcopy(self.LoadedData)
		end
		
		

		-- Do additional Addon initialization here
	end
end


-----------------------------------------------------------------------------------------------
-- Afkreply Functions
-----------------------------------------------------------------------------------------------
function Afkreply:OnBack()
	bPlayerAway = false
	if self.tSettings.SendBackMessage then
		self:PostBackMessage()
	end
	
end

function Afkreply:OnAway()
	bPlayerAway = true
	if self.tSettings.SendAwayMessage then
		self:PostAwayMessage()
	end
	
end

function Afkreply:PostAwayMessage()
	if self.tSettings.tSendAwayToChannel.Say 		then ChatSystemLib.Command("/s "..self.tSettings.Message.AwayMessage.."") end
	if self.tSettings.tSendAwayToChannel.Party  		then ChatSystemLib.Command("/p "..self.tSettings.Message.AwayMessage.."") end
	if self.tSettings.tSendAwayToChannel.Instance 	then ChatSystemLib.Command("/i "..self.tSettings.Message.AwayMessage.."") end
	if self.tSettings.tSendAwayToChannel.Guild 		then ChatSystemLib.Command("/g "..self.tSettings.Message.AwayMessage.."") end
	if self.tSettings.tSendAwayToChannel.Officer 	then ChatSystemLib.Command("/go "..self.tSettings.Message.AwayMessage.."") end
	if self.tSettings.tSendAwayToChannel.Zone 		then ChatSystemLib.Command("/z "..self.tSettings.Message.AwayMessage.."") end
	end

function Afkreply:PostBackMessage()
	if self.tSettings.tSendBackToChannel.Say 		then ChatSystemLib.Command("/s "..self.tSettings.Message.BackMessage.."") end
	if self.tSettings.tSendBackToChannel.Party  		then ChatSystemLib.Command("/p "..self.tSettings.Message.BackMessage.."") end
	if self.tSettings.tSendBackToChannel.Instance 	then ChatSystemLib.Command("/i "..self.tSettings.Message.BackMessage.."") end
	if self.tSettings.tSendBackToChannel.Guild 		then ChatSystemLib.Command("/g "..self.tSettings.Message.BackMessage.."") end
	if self.tSettings.tSendBackToChannel.Officer 	then ChatSystemLib.Command("/go "..self.tSettings.Message.BackMessage.."") end
	if self.tSettings.tSendBackToChannel.Zone 		then ChatSystemLib.Command("/z "..self.tSettings.Message.BackMessage.."") end
end
-- Define general functions here

-- on SlashCommand "/afkreply"
function Afkreply:OnAfkreplyOn()
	self.wndMain:Invoke() -- show the window
	
end

function Afkreply:OnChatMessage(channelCurrent, tMessage)
	if channelCurrent:GetName() == "System" and tMessage.arMessageSegments[1].strText == "You are now 'away from keyboard.'" then
		bPlayerAway = true
		self:OnAway()
	end
	if channelCurrent:GetName() == "System" and tMessage.arMessageSegments[1].strText == "You are no longer 'away from keyboard.'" then
		bPlayerAway = false
		self:OnBack()
	end
	
	-- cleaner code suggested by Therzok
	if not bPlayerAway or 
		channelCurrent:GetName() ~= "Whisper" or
		lastSent == tMessage.strSender
	then
		return
	else
		self:StoreNewWhisper(tMessage.strSender,tMessage.arMessageSegments[1].strText)
		lastSent = tMessage.strSender
		if self.tSettings.SendAutoReply  then
			ChatSystemLib.Command("/w "..tMessage.strSender.." "..self.tSettings.Message.AutoReplyMessage.."")
		end
	end
	
	

end


-----------------------------------------------------------------------------------------------
-- AfkreplyForm Functions
-----------------------------------------------------------------------------------------------





function Afkreply:OnClear( wndHandler, wndControl, eMouseButton )
 for k,v in pairs (self.WhisperMsg) do
	v:Destroy()
	self.WhisperMsg[k] = nil
	end
	self.MsgWindow:Close()
	self.wndMain:FindChild("NumOfWhisperText"):Show(true,true);
end


function Afkreply:OnClose( wndHandler, wndControl, eMouseButton )
	self.wndMain:Close() -- hide the window
	
end


function Afkreply:StoreNewWhisper(tName,tMessage)
	if self.WhisperMsg[tName] == nil then
		self.WhisperMsg[tName] = Apollo.LoadForm(self.xmlDoc, "MissedWhisperItem" ,self.wndMain:FindChild("MissedWhisperList"),self)
		self.WhisperMsg[tName]:FindChild("Button"):FindChild("Name"):SetText(tName)
		self.WhisperMsg[tName]:FindChild("Button"):FindChild("Message"):SetText(tMessage)
	else
		local oldmessage = self.WhisperMsg[tName]:FindChild("Message"):GetText()
		self.WhisperMsg[tName]:FindChild("Message"):SetText(" "..tMessage.."\n"..oldmessage" ")
	end
	
	self.wndMain:Invoke() -- show the window
	self.wndMain:FindChild("NumOfWhisperText"):Show(false,true);
	self.wndMain:FindChild("MissedWhisperList"):ArrangeChildrenVert()
end



function Afkreply:OnChangeMessage(ToChange)
	self.wndChangeMsg:Show(true,true)
	
end



function Afkreply:OnSave(eLevel)
    if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return nil end
	
    return self.tSettings 
end

function Afkreply:OnRestore(eLevel, tData)
    self.LoadedData = deepcopy(tData)
end

function Afkreply:OnSetting()
	self:ShowSetting()
end

function Afkreply:ShowSetting()
	self.wndSetting:Show(true,true)
end


function Afkreply:OnSettingButton( wndHandler, wndControl, eMouseButton )
	self:ShowSetting()
end

---------------------------------------------------------------------------------------------------
-- MissedWhisperItem Functions
---------------------------------------------------------------------------------------------------

function Afkreply:OnWhisperButton( wndHandler, wndControl, eMouseButton )

	self.MsgWindow:FindChild("SenderName"):SetText(wndHandler:FindChild("Name"):GetText())
	self.MsgWindow:FindChild("MessageBox"):SetText(wndHandler:FindChild("Message"):GetText())
	self.MsgWindow:Show(true,false)
			
end


---------------------------------------------------------------------------------------------------
-- MsgList Functions
---------------------------------------------------------------------------------------------------

function Afkreply:CloseMessage( wndHandler, wndControl, eMouseButton )
	self.MsgWindow:Close()
end

---------------------------------------------------------------------------------------------------
-- Setting Functions
---------------------------------------------------------------------------------------------------

function Afkreply:AutoMessageCheck( wndHandler, wndControl, eMouseButton )
	sendMessage = true
end

function Afkreply:AutoMessageUncheck( wndHandler, wndControl, eMouseButton )
	sendMessage = false
end

function Afkreply:OnSettingApply( wndHandler, wndControl, eMouseButton )
	
	-- sets the tick boxes for sending auto messages
	self.tSettings.SendAutoReply = self.wndSetting:FindChild("AutoReplyButton"):IsChecked()
	self.tSettings.SendAwayMessage = self.wndSetting:FindChild("AwayButton"):IsChecked()
	self.tSettings.SendBackMessage = self.wndSetting:FindChild("BackButton"):IsChecked()
	
	-- send away message buttons
	self.tSettings.tSendAwayToChannel.Say = self.wndSetting:FindChild("AwayMessageControl"):FindChild("AwaySayButton"):IsChecked()
	self.tSettings.tSendAwayToChannel.Party = self.wndSetting:FindChild("AwayMessageControl"):FindChild("AwayPartyButton"):IsChecked()
	self.tSettings.tSendAwayToChannel.Instance = self.wndSetting:FindChild("AwayMessageControl"):FindChild("AwayInstanceButton"):IsChecked()
	self.tSettings.tSendAwayToChannel.Guild = self.wndSetting:FindChild("AwayMessageControl"):FindChild("AwayGuildButton"):IsChecked()
	self.tSettings.tSendAwayToChannel.Officer = self.wndSetting:FindChild("AwayMessageControl"):FindChild("AwayOfficerButton"):IsChecked()
	self.tSettings.tSendAwayToChannel.Zone = self.wndSetting:FindChild("AwayMessageControl"):FindChild("AwayZoneButton"):IsChecked()
	
	-- send back message button
	self.tSettings.tSendBackToChannel.Say = self.wndSetting:FindChild("BackMessageControl"):FindChild("BackSayButton"):IsChecked()
	self.tSettings.tSendBackToChannel.Party = self.wndSetting:FindChild("BackMessageControl"):FindChild("BackPartyButton"):IsChecked()
	self.tSettings.tSendBackToChannel.Instance = self.wndSetting:FindChild("BackMessageControl"):FindChild("BackInstanceButton"):IsChecked()
	self.tSettings.tSendBackToChannel.Guild = self.wndSetting:FindChild("BackMessageControl"):FindChild("BackGuildButton"):IsChecked()
	self.tSettings.tSendBackToChannel.Officer = self.wndSetting:FindChild("BackMessageControl"):FindChild("BackOfficerButton"):IsChecked()
	self.tSettings.tSendBackToChannel.Zone = self.wndSetting:FindChild("BackMessageControl"):FindChild("BackZoneButton"):IsChecked()
	self.wndSetting:Close()
end
	
function Afkreply:OnSettingShow( wndHandler, wndControl )
self.wndSetting:ToFront()
		-- sets the tick boxes for sending auto messages
	self.wndSetting:FindChild("AutoReplyButton"):SetCheck(self.tSettings.SendAutoReply)
	self.wndSetting:FindChild("AwayButton"):SetCheck(self.tSettings.SendAwayMessage)
	self.wndSetting:FindChild("BackButton"):SetCheck(self.tSettings.SendBackMessage)
	
	-- send away message buttons
	self.wndSetting:FindChild("AwayMessageControl"):FindChild("AwaySayButton"):SetCheck(self.tSettings.tSendAwayToChannel.Say)
	self.wndSetting:FindChild("AwayMessageControl"):FindChild("AwayPartyButton"):SetCheck(self.tSettings.tSendAwayToChannel.Party)
	self.wndSetting:FindChild("AwayMessageControl"):FindChild("AwayInstanceButton"):SetCheck(self.tSettings.tSendAwayToChannel.Instance)
	self.wndSetting:FindChild("AwayMessageControl"):FindChild("AwayGuildButton"):SetCheck(self.tSettings.tSendAwayToChannel.Guild)
	self.wndSetting:FindChild("AwayMessageControl"):FindChild("AwayOfficerButton"):SetCheck(self.tSettings.tSendAwayToChannel.Officer)
	self.wndSetting:FindChild("AwayMessageControl"):FindChild("AwayZoneButton"):SetCheck(self.tSettings.tSendAwayToChannel.Zone)
	
	-- send back message button
	self.wndSetting:FindChild("BackMessageControl"):FindChild("BackSayButton"):SetCheck(self.tSettings.tSendBackToChannel.Say)
	self.wndSetting:FindChild("BackMessageControl"):FindChild("BackPartyButton"):SetCheck(self.tSettings.tSendBackToChannel.Party)
	self.wndSetting:FindChild("BackMessageControl"):FindChild("BackInstanceButton"):SetCheck(self.tSettings.tSendBackToChannel.Instance)
	self.wndSetting:FindChild("BackMessageControl"):FindChild("BackGuildButton"):SetCheck(self.tSettings.tSendBackToChannel.Guild)
	self.wndSetting:FindChild("BackMessageControl"):FindChild("BackOfficerButton"):SetCheck(self.tSettings.tSendBackToChannel.Officer)
	self.wndSetting:FindChild("BackMessageControl"):FindChild("BackZoneButton"):SetCheck(self.tSettings.tSendBackToChannel.Party)
	
end

function Afkreply:OnSettingCancel( wndHandler, wndControl, eMouseButton )
	self.wndSetting:Close()
end


function Afkreply:OnChangeReplyMessage( wndHandler, wndControl, eMouseButton )
	self:EditMessage(0)
end

function Afkreply:OnChangeBackMessage( wndHandler, wndControl, eMouseButton )
	self:EditMessage(1)
end

function Afkreply:OnChangeAwayMessage( wndHandler, wndControl, eMouseButton )
	self:EditMessage(2)
end



---------------------------------------------------------------------------------------------------
-- ChangeMessageForm Functions
---------------------------------------------------------------------------------------------------

function Afkreply:EditMessage(num)
	self.wndChangeMsg:FindChild("MessageToChange"):SetText(num)
	self.wndChangeMsg:Show(true,true)
end


function Afkreply:OnMessageChangeShow( wndHandler, wndControl )
	self.wndChangeMsg:ToFront()
	local ItemToEdit = self.wndChangeMsg:FindChild("MessageToChange"):GetText()
	local title = ""
	local message = ""
	if ItemToEdit == '0' then 
		title = "Change Auto Reply Message"
		 message = self.tSettings.Message.AutoReplyMessage
	end
	if ItemToEdit  == '1' then 
		title = "Change Back Message" 
		message = self.tSettings.Message.BackMessage
	end
	if ItemToEdit  == '2' then 
		title = "Change Away Message" 
		message = self.tSettings.Message.AwayMessage
	end
	
	self.wndChangeMsg:FindChild("MessageBox"):SetText(message)
	self.wndChangeMsg:FindChild("Title"):SetText(title)
end


function Afkreply:OnApplyMessage( wndHandler, wndControl, eMouseButton )
	local ItemToEdit = self.wndChangeMsg:FindChild("MessageToChange"):GetText()
	local message = self.wndChangeMsg:FindChild("MessageBox"):GetText()
	if ItemToEdit == '0' then 
		self.tSettings.AutoReplyMesssage = message
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Command,"Auto Reply Message Changed")
	end
	if ItemToEdit  == '1' then 
		self.tSettings.Message.BackMessage = message
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Command,"Back Message Changed")
	end
	if ItemToEdit  == '2' then 
		self.tSettings.Message.AwayMessage = message
		ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Command,"Away Message Changed")
	end

	self.wndChangeMsg:Close()
end

function Afkreply:OnMessageCancel( wndHandler, wndControl, eMouseButton )
	self.wndChangeMsg:Close()
end

function Afkreply:OnMessageChangeMove( wndHandler, wndControl, nOldLeft, nOldTop, nOldRight, nOldBottom )
	self.wndChangeMsg:ToFront()
end

-----------------------------------------------------------------------------------------------
-- Afkreply Instance
-----------------------------------------------------------------------------------------------
local AfkreplyInst = Afkreply:new()
AfkreplyInst:Init()
