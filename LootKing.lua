--[[

LootKing
Author: Ivan Leben

--]]


local LK = LootKing;

--Output
--===================================================

function LK.Print( msg )
  print( "|cffffff00" .. LK.PRINT_PREFIX .. " |cffffffff"..msg );
end

function LK.Error (msg)
  print( "|cffffff00" .. LK.PRINT_PREFIX .. " |cffff2222"..msg );
end

--Slash handler
--===================================================


function LK.SlashHandler( msg )

	if (msg == "") then

		--Empty command
		LK.UpdateGui();
		LK.ShowGui();
		
	else
	
		--Parametric commands
		local cmd, param = strsplit( " ", msg );
		if (cmd == "reset") then
		
			LK.ResetSave();
			LK.Print( "Settings reset." );
		end
	end
end


SLASH_LootKing1 = "/lootking";
SLASH_LootKing2 = "/lk";
SlashCmdList["LootKing"] = LK.SlashHandler;


--Player list
--===================================================

function LK.PlayerList_New( name )

	local f = PrimeGui.List_New( name );
	
	f.UpdateItem = LK.PlayerList_UpdateItem;
	
	return f;
end

function LK.PlayerList_UpdateItem( frame, item, value, selected  )

	PrimeGui.List_UpdateItem( frame, item, value, selected );
	
	if (value.color) then
	
		local c = value.color;
		item.label:SetTextColor( c.r, c.g, c.b, c.a );
	end
	
end

--Gui
--============================================================================

function LK.ShowGui()
	
	LK.gui:Show();
	LK.AutoSync();
	
end

function LK.HideGui()

	LK.gui:Hide();
end

function LK.GetActiveList()

	--Check if a valid list is active
	local save = LK.GetSave();
	if (save.activeList == nil) then
		return nil;
	end
	
	--Return currently active list	
	return save.lists[ save.activeList ];
end

function LK.SetActiveList( name )

	--Check if valid name
	local save = LK.GetSave();
	if (save.lists[ name ] == nil) then
		return;
	end
	
	--Switch to given list
	save.activeList = name;
	LK.UpdateGui();
end

function LK.FillList( guiList, playerList )

	--Constants
	local white = {r=1, g=1, b=1, a=1};
	local gray = {r=0.5, g=0.5, b=0.5, a=1};
	
	--Get raid info
	local inRaid = UnitInRaid("player");
	local raidMembers = PrimeGroup.GetMembers();
	
	--Clear existing items
	guiList:RemoveAllItems();
	
	--Iterate player items
	for i=1,table.getn(playerList) do
	
		--White if not in raid
		local col = white;
		if (inRaid) then
		
			--Gray if item not in raid
			col = gray;
			
			--Find item among raid members
			for r=1,table.getn(raidMembers) do
				if (raidMembers[r] == playerList[i]) then
				
					--Class color if item in raid
					col = PrimeGroup.GetClassColor( playerList[i] );
					break;
				end
			end
		end
		
		--Insert player item with set color
		guiList:AddItem( { text = playerList[i], color = col } );
		
	end
end


function LK.CreateGui()

	--Window
	local w = PrimeGui.Window_New("LootKing", "LootKing", true, true);
	w:Init();
	w:SetParent( UIParent );
	w:SetWidth( 300 );
	w:SetHeight( 400 );
	
	--Label
    local txt = w:CreateFontString( LK.PREFIX.."Gui.Text", "OVERLAY", "GameFontNormal" );
    txt:SetTextColor( 1, 1, 0, 1 );
    txt:SetPoint( "TOPLEFT", w.container, "TOPLEFT", 0, 0 );
    txt:SetPoint( "TOPRIGHT", w.container, "TOPRIGHT", 0, 0 );
	txt:SetJustifyH( "CENTER" );
	txt:SetJustifyV( "TOP" );
    txt:SetHeight( 40 );
    txt:SetWordWrap( true );
    txt:SetText( "Message" );
	w.text = txt;
	
	--Dropdown
	local drop = PrimeGui.Drop_New( LK.PREFIX.."Gui.Dropdown" );
	drop:Init();
	drop:SetParent( w.container );
	drop:SetPoint( "TOPLEFT", 0, -5 );
	drop:SetPoint( "TOPRIGHT", 0, -5 );
	drop:SetLabelText( "" );
	drop.OnValueChanged = LK.Gui_Drop_OnValueChanged;
	drop.window = w;
	w.drop = drop;
	
	--List background
	local bg = CreateFrame( "Frame", nil, w.container );
	bg:SetPoint( "TOPRIGHT", drop, "BOTTOMRIGHT", 0,-5 );
	bg:SetPoint( "BOTTOMLEFT", 0,0 );
	
	bg:SetBackdrop(
	  {bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	   edgeFile = "Interface/DialogFrame/UI-Tooltip-Border",
	   tile = true, tileSize = 32, edgeSize = 32,
	   insets = { left = 0, right = 0, top = 0, bottom = 0 }});
	 
	bg:SetBackdropColor(0,0,0,0.8);
	
	--List box
	local list = LK.PlayerList_New( "LootKing".."List" );
	list:Init();
	list:SetParent( bg );
	list:SetAllPoints( bg );
	list.window = w;
	w.list = list;
	
	return w;
	
end

function LK.UpdateGui()

	--Get save table
	local save = LK.GetSave();
	
	--Check if we got a valid list
	if (save.activeList == nil) then
	
		--Notify user of missing list
		LK.gui.text:SetText( "Join a group to receive loot list" );
		
		--Add dummy list item
		LK.gui.drop:RemoveAllItems();
		LK.gui.drop:AddItem( "<Loot list unavailable>" );
		LK.gui.drop:SelectIndex(0);
		
	else
	
		--Set message to match sync target
		LK.gui.text:SetText( "List received from "..save.syncTarget );
		
		--Fill dropdown with list names
		LK.gui.drop:RemoveAllItems();
		
		for name,list in pairs(save.lists) do
			LK.gui.drop:AddItem( name, name );
		end
		
		--Select active list in the dropdown
		LK.gui.drop:SelectValue( save.activeList );
		
		--Get active list
		local list = LK.GetActiveList();
		if (list ~= nil) then
		
			--Update list
			LK.FillList( LK.gui.list, list );
		end
		
	end
end

function LK.Gui_Drop_OnValueChanged( drop )

	--Switch to selected list
	LK.SetActiveList( drop:GetSelectedText() );
end


--Syncing
--===================================================

function LK.GetActiveSyncList()

	--Check if a valid sync list is active
	if (LK.syncActiveList == nil) then
		return nil;
	end
	
	--Return currently active sync list	
	return LK.syncLists[ LK.syncActiveList ];
end

function LK.AutoSync()

	--Try syncing with loot master
	local master = PrimeGroup.GetLootMaster();
	
	if (master ~= nil) then
		LK.Sync( master );
		return;
	end
	
	--Try syncing with group leader
	local leader = PrimeGroup.GetLeader();
	
	if (leader ~= nil ) then
		LK.Sync( leader );
		return;
	end
end

function LK.Sync( target )
	
	--Notify user
	LK.Print( "Sending sync request to "..target.."...");
	
	--Init sync info
	LK.syncOn = true;
	LK.syncTarget = target;
	LK.syncId = LK.syncId + 1;
	
	--Init sync list
	PrimeUtil.ClearTableKeys( LK.syncLists );
	
	--Send sync request with our sync id
	SendAddonMessage( LK.SYNC_PREFIX, "SyncRequest_"..LK.syncTarget..LK.syncId,
		"WHISPER", target );
end

function LK.OnEvent_CHAT_MSG_ADDON( prefix, msg, channel, sender )

	if (prefix ~= LK.SYNC_PREFIX) then
		return;
	end
	
	local cmd, arg1, arg2 = strsplit( "_", msg );
	
	if (cmd == "SyncList" and LK.syncOn) then
	
		--Check if sync id matches
		if (arg1 == LK.syncTarget..LK.syncId) then
		
			--Create new list and make active
			LK.syncLists[ arg2 ] = {};
			LK.syncActiveList = arg2;
			
		end
	
	elseif (cmd == "Sync" and LK.syncOn) then
		
		--Check if sync id matches
		if (arg1 == LK.syncTarget..LK.syncId) then
		
			--Check that active list exists
			local syncList = LK.GetActiveSyncList();
			if (syncList ~= nil) then
				
				--Add list item
				table.insert( syncList, arg2 );
			end
		end
	
	
	elseif (cmd == "SyncEnd" and LK.syncOn) then
	
		--Check if sync id matches
		if (arg1 == LK.syncTarget..LK.syncId) then
			
			--Sync finished
			LK.syncOn = false;
			LK.ApplySync();
		end
	end
end


function LK.ApplySync()
	
	LK.Print( "List received from "..LK.syncTarget );
	
	--Get save table
	local save = LK.GetSave();
	
	--Clear existing lists
	PrimeUtil.ClearTableKeys( save.lists );
	
	--Iterate sync lists
	local firstList = nil;
	
	for name,syncList in pairs(LK.syncLists) do
		
		--Insert synced list
		save.lists[ name ] = CopyTable(syncList);
		
		--Remember first synced list
		if (firstList == nil) then
			firstList = name;
		end
	end
	
	--Select first synced list if previously selected list doesn't exist anymore
	if (save.activeList == nil or save.lists[ save.activeList ] == nil) then
		save.activeList = firstList;
	end
	
	--Store sync target
	save.syncTarget = LK.syncTarget;
	
	LK.UpdateGui();
end


--Minimap button
--===================================================

function LK.CreateMinimapButton()

	local button = PrimeGui.MinimapButton_New( LK.PREFIX.."MinimapButton" );
	button:SetIcon( "Interface\\AddOns\\LootKing\\icon.tga" );
	button:SetPosition( LK.GetSave().minimapButtonPos );
	
	button.OnPositionChanged	= LK.MinimapButton_OnPositionChanged;
	button.OnTooltipShow		= LK.MinimapButton_OnTooltipShow;
	button.OnClick				= LK.MinimapButton_OnClick;
	
	return button;
end

function LK.MinimapButton_OnPositionChanged( button )

	LK.GetSave().minimapButtonPos = button:GetPosition();
end

function LK.MinimapButton_OnTooltipShow( button )

	GameTooltip:ClearLines();
	GameTooltip:AddLine("LootKing", 1, 1, 0);
	GameTooltip:AddLine("|cffffff00Click |cffffffffto show the loot list window");
end

function LK.MinimapButton_OnClick( button, mouseButton )

	if (mouseButton == "LeftButton") then
		
		if (LK.gui:IsShown())
		then LK.HideGui();
		else LK.ShowGui();
		end
		
	end
end


--Entry point
--===================================================

function LK.OnEvent( frame, event, ... )
  
  local funcName = "OnEvent_" .. event;
  local func = LK[ funcName ];
  if (func) then func(...) end
  
end

function LK.OnEvent_PLAYER_LOGIN()
	
	--Init variables
	LK.syncOn = false;
	LK.syncTarget = nil;
	LK.syncId = 0;
	LK.syncLists = {};
	LK.syncActiveList = nil;
	
	--Start with default save if missing
	if (LK.GetSave() == nil) then
		LK.ResetSave();
	end
	
	--Upgrade save from old version
	LK.Upgrade();
	
	--Create new minimap button if missing
	if (LK.button == nil) then
		LK.button = LK.CreateMinimapButton();
	end
	
	--Create new gui if missing
	if (LK.gui == nil) then
		LK.gui = LK.CreateGui();
		LK.gui:SetPoint( "CENTER", 0,0 );
		LK.gui:Hide();
	end
	
	--Register communication events
	LK.frame:RegisterEvent( "CHAT_MSG_ADDON" );
	
	--First update
	LK.UpdateGui();
	
end

function LK.Init()

	--Register event for initialization (save isn't loaded until PLAYER_LOGIN!!!)
	LK.frame = CreateFrame( "Frame", LK.PREFIX.."EventFrame" );
	LK.frame:SetScript( "OnEvent", LK.OnEvent );
	LK.frame:RegisterEvent( "PLAYER_LOGIN" );
	
end

LK.Init();
