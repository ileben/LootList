--[[

LootList
Author: Ivan Leben

--]]

LootList = {}

LootList.VERSION = "0.1";

LootList.PREFIX = "LootList";
LootList.PRINT_PREFIX = "<LootList>";
LootList.SYNC_PREFIX = "LootListSync";

LootList.DEFAULT_SAVE =
{
	version = LootList.VERSION,
	
	lists =
	{
	},
	
	activeList = nil,
};

local LL = LootList;

--Output
--===================================================

function LL.Print( msg )
  print( "|cffffff00" .. LL.PRINT_PREFIX .. " |cffffffff"..msg );
end

function LL.Error (msg)
  print( "|cffffff00" .. LL.PRINT_PREFIX .. " |cffff2222"..msg );
end

--Save management
--===================================================

function LL.ResetSave()

	LootListSave = CopyTable( LL.DEFAULT_SAVE );
end

function LL.GetSave()

	return LootListSave;
end

--Slash handler
--===================================================


function LL.SlashHandler( msg )

	if (msg == "") then

		--Empty command
		LL.UpdateGui();
		LL.ShowGui();
		LL.AutoSync();
		
	else
	
		--Parametric commands
		local cmd, param = strsplit( " ", msg );
		if (cmd == "reset") then
		
			LL.ResetSave();
			LL.Print( "Settings reset." );
		end
	end
end


SLASH_LootList1 = "/lootlist";
SLASH_LootList2 = "/ll";
SlashCmdList["LootList"] = LL.SlashHandler;


--Player list
--===================================================

function LL.PlayerList_New( name )

	local f = PrimeGui.List_New( name );
	
	f.UpdateItem = LL.PlayerList_UpdateItem;
	
	return f;
end

function LL.PlayerList_UpdateItem( frame, item, value, selected  )

	PrimeGui.List_UpdateItem( frame, item, value, selected );
	
	if (value.color) then
	
		local c = value.color;
		item.label:SetTextColor( c.r, c.g, c.b, c.a );
	end
	
end

--Gui
--============================================================================

function LL.ShowGui()
	
	LL.gui:Show();
end

function LL.HideGui()

	LL.gui:Hide();
end

function LL.GetActiveList()

	--Check if a valid list is active
	local save = LL.GetSave();
	if (save.activeList == nil) then
		return nil;
	end
	
	--Return currently active list	
	return save.lists[ save.activeList ];
end

function LL.SetActiveList( name )

	--Check if valid name
	local save = LL.GetSave();
	if (save.lists[ name ] == nil) then
		return;
	end
	
	--Switch to given list
	save.activeList = name;
	LL.UpdateGui();
end

function LL.FillList( guiList, playerList )

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


function LL.CreateGui()

	--Window
	local w = PrimeGui.Window_New("LootList", "LootList", true, true);
	w:Init();
	w:SetParent( UIParent );
	w:SetWidth( 300 );
	w:SetHeight( 400 );
	
	--Label
    local txt = w:CreateFontString( LL.PREFIX.."Gui.Text", "OVERLAY", "GameFontNormal" );
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
	local drop = PrimeGui.Drop_New( LL.PREFIX.."Gui.Dropdown" );
	drop:Init();
	drop:SetParent( w.container );
	drop:SetPoint( "TOPLEFT", 0, -5 );
	drop:SetPoint( "TOPRIGHT", 0, -5 );
	drop:SetLabelText( "" );
	drop.OnValueChanged = LL.Gui_Drop_OnValueChanged;
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
	local list = LL.PlayerList_New( "LootList".."List" );
	list:Init();
	list:SetParent( bg );
	list:SetAllPoints( bg );
	list.window = w;
	w.list = list;
	
	return w;
	
end

function LL.UpdateGui()

	--Get save table
	local save = LL.GetSave();
	
	--Check if we got a valid list
	if (save.activeList == nil) then
	
		--Notify user of missing list
		LL.gui.text:SetText( "Join a group to receive loot list" );
		
		--Add dummy list item
		LL.gui.drop:RemoveAllItems();
		LL.gui.drop:AddItem( "<Loot list unavailable>" );
		LL.gui.drop:SelectIndex(0);
		
	else
	
		--Set message to match sync target
		LL.gui.text:SetText( "List received from "..LootList.syncTarget );
		
		--Fill dropdown with list names
		LL.gui.drop:RemoveAllItems();
		
		for name,list in pairs(save.lists) do
			LL.gui.drop:AddItem( name, name );
		end
		
		--Select active list in the dropdown
		LL.gui.drop:SelectValue( save.activeList );
		
		--Get active list
		local list = LL.GetActiveList();
		if (list ~= nil) then
		
			--Update list
			LL.FillList( LL.gui.list, list );
		end
		
	end
end

function LL.Gui_Drop_OnValueChanged( drop )

	--Switch to selected list
	LL.SetActiveList( drop:GetSelectedText() );
end


--Syncing
--===================================================

function LL.GetActiveSyncList()

	--Check if a valid sync list is active
	if (LL.syncActiveList == nil) then
		return nil;
	end
	
	--Return currently active sync list	
	return LL.syncLists[ LL.syncActiveList ];
end

function LL.AutoSync()

	--Try syncing with loot master
	local master = PrimeGroup.GetLootMaster();
	
	if (master ~= nil) then
		LL.Sync( master );
		return;
	end
	
	--Try syncing with group leader
	local leader = PrimeGroup.GetLeader();
	
	if (leader ~= nil ) then
		LL.Sync( leader );
		return;
	end
end

function LL.Sync( target )
	
	--Notify user
	LL.Print( "Sending sync request to "..target.."...");
	
	--Init sync info
	LL.syncOn = true;
	LL.syncTarget = target;
	LL.syncId = LL.syncId + 1;
	
	--Init sync list
	PrimeUtil.ClearTableKeys( LL.syncLists );
	
	--Send sync request with our sync id
	SendAddonMessage( LL.SYNC_PREFIX, "SyncRequest_"..LL.syncTarget..LL.syncId,
		"WHISPER", target );
end

function LL.OnEvent_CHAT_MSG_ADDON( prefix, msg, channel, sender )

	if (prefix ~= LL.SYNC_PREFIX) then
		return;
	end
	
	--LL.Print( "Addon prefix: "..tostring(prefix).." Message: "..tostring(msg) );
	
	local cmd, arg1, arg2 = strsplit( "_", msg );
	
	if (cmd == "SyncList" and LL.syncOn) then
	
		--Check if sync id matches
		if (arg1 == LL.syncTarget..LL.syncId) then
		
			--Create new list and make active
			LL.syncLists[ arg2 ] = {};
			LL.syncActiveList = arg2;
			
		end
	
	elseif (cmd == "Sync" and LL.syncOn) then
		
		--Check if sync id matches
		if (arg1 == LL.syncTarget..LL.syncId) then
		
			--Check that active list exists
			local syncList = LL.GetActiveSyncList();
			if (syncList ~= nil) then
				
				--Add list item
				table.insert( syncList, arg2 );
			end
		end
	
	
	elseif (cmd == "SyncEnd" and LL.syncOn) then
	
		--Check if sync id matches
		if (arg1 == LL.syncTarget..LL.syncId) then
			
			--Sync finished
			LL.syncOn = false;
			LL.ApplySync();
		end
	end
end


function LL.ApplySync()

	--Get save table
	local save = LL.GetSave();
	
	--Clear existing lists
	PrimeUtil.ClearTableKeys( save.lists );
	save.activeList = nil;
	
	--Iterate sync lists
	for name,syncList in pairs(LL.syncLists) do
		
		--Insert/overwrite active list
		save.lists[ name ] = CopyTable(syncList);
		
		--Set first list active
		if (save.activeList == nil) then
			save.activeList = name;
		end
	end
	
	LL.UpdateGui();
end


--Entry point
--===================================================

function LL.OnEvent( frame, event, ... )
  
  local funcName = "OnEvent_" .. event;
  local func = LL[ funcName ];
  if (func) then func(...) end
  
end

function LL.Init()
	
	--Init variables
	LL.syncOn = false;
	LL.syncTarget = "Target";
	LL.syncId = 0;
	LL.syncLists = {};
	LL.syncActiveList = nil;
	
	--Start with default save if missing
	if (LL.GetSave() == nil) then
		LL.ResetSave();
	end
	
	--Create new gui if missing
	if (LL.gui == nil) then
		LL.gui = LL.CreateGui();
		LL.gui:SetPoint( "CENTER", 0,0 );
		LL.gui:Hide();
	end
	
	--Register addon event
	LL.gui:SetScript( "OnEvent", LL.OnEvent );
	LL.gui:RegisterEvent( "CHAT_MSG_ADDON" );
	
	--First update
	LL.UpdateGui();
	
end

LL.Init();
