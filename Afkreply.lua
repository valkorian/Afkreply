-----------------------------------------------------------------------------------------------
-- Client Lua Script for Afkreply
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------
 
require "Window"

-----------------------------------------------------------------------------------------------
-- Afkreply Module Definition
-----------------------------------------------------------------------------------------------
local Afkreply = {} 
 
-----------------------------------------------------------------------------------------------
-- Constants
-----------------------------------------------------------------------------------------------
-- e.g. local kiExampleVariableMax = 999
 local bPlayerAway = false
local lastSent = nil
local message = nil
local sendMessage = true

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
		Apollo.RegisterEventHandler("ChatMessage", "OnChatMessage", self)
		
		
		if self.tSavedData == nil then
		message = "AfkReply: I am away from keyboard but your name has been saved and i will /w you back soon."
		self.wndMain:FindChild("AutoReplyButton"):SetCheck(true)
		else
		message = self.tSavedData.Message
		self.wndMain:FindChild("AutoReplyButton"):SetCheck(self.tSavedData.SendReply)
		end
		
		
		self.WhisperMsg = {}
		self.MsgWindow = Apollo.LoadForm(self.xmlDoc, "MsgList" ,nil,self)
		self.MsgWindow:Show(false,true)
		-- Do additional Addon initialization here
	end
end


-----------------------------------------------------------------------------------------------
-- Afkreply Functions
-----------------------------------------------------------------------------------------------



-- Define general functions here

-- on SlashCommand "/afkreply"
function Afkreply:OnAfkreplyOn()
	self.wndMain:Invoke() -- show the window
	
end

function Afkreply:OnChatMessage(channelCurrent, tMessage)
	if channelCurrent:GetName() == "System" and tMessage.arMessageSegments[1].strText == "You are now 'away from keyboard.'" then
		bPlayerAway = true
	end
	if channelCurrent:GetName() == "System" and tMessage.arMessageSegments[1].strText == "You are no longer 'away from keyboard.'" then
		bPlayerAway = false
	end
	
	-- clear code suggested by Therzok
	if not bPlayerAway or 
		channelCurrent:GetName() ~= "Whisper" or
		tMessage.strSender == GameLib.GetPlayerUnit():GetName() or
		lastSent == tMessage.strSender
	then
		return
	else
		self:StoreNewWhisper(tMessage.strSender,tMessage.arMessageSegments[1].strText)
		lastSent = tMessage.strSender
		if sendMessage then
			ChatSystemLib.Command("/w "..tMessage.strSender.." "..message.."")
		end
	end
	
	

end

function Afkreply:UpdateDisplay()
	self.wndMain:FindChild("MessageBox"):SetText(message)
end

function Afkreply:ChangeReply(tMessage)
	message = tMessage
	self:UpdateDisplay()
	ChatSystemLib.PostOnChannel(ChatSystemLib.ChatChannel_Command, "Auto reply message updated" )
end
-----------------------------------------------------------------------------------------------
-- AfkreplyForm Functions
-----------------------------------------------------------------------------------------------
-- when the OK button is clicked



function Afkreply:OnWindowShow( wndHandler, wndControl )
	self:UpdateDisplay()
end

function Afkreply:OnClear( wndHandler, wndControl, eMouseButton )
 for k,v in pairs (self.WhisperMsg) do
	v:Destroy()
	self.WhisperMsg[k] = nil
	end
	self.MsgWindow:Close()
end

function Afkreply:OnMessageChange( wndHandler, wndControl, eMouseButton )
	self:ChangeReply(self.wndMain:FindChild("MessageBox"):GetText())
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
	self.wndMain:FindChild("MissedWhisperList"):ArrangeChildrenVert()
end






function Afkreply:OnButtonCheck( wndHandler, wndControl, eMouseButton )
	sendMessage = true
end

function Afkreply:ObButtonUncheck( wndHandler, wndControl, eMouseButton )
	sendMessage = false
end



function Afkreply:OnSave(eLevel)
    if eLevel ~= GameLib.CodeEnumAddonSaveLevel.Character then return nil end
	
local tsave = {}
tsave.Message = message  
tsave.SendReply = sendMessage 
    return tsave
end

function Afkreply:OnRestore(eLevel, tData)
    self.tSavedData = tData
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

-----------------------------------------------------------------------------------------------
-- Afkreply Instance
-----------------------------------------------------------------------------------------------
local AfkreplyInst = Afkreply:new()
AfkreplyInst:Init()
