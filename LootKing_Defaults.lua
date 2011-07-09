--[[

LootKing
Author: Ivan Leben

--]]

--Main table
--========================================================

LootKing = {};

local LK = LootKing;

--Default values
--========================================================

LK.VERSION = "1.2";
LK.UPGRADE_LIST = { "1.1" };

LK.PREFIX = "LootKing";
LK.PRINT_PREFIX = "<LootKing>";
LK.SYNC_PREFIX = "LootKingSync";

LK.DEFAULT_SAVE =
{
	version = LK.VERSION,
	
	lists =
	{
	},
	
	activeList = nil,
	syncTarget = nil,
	minimapButtonPos = 240,
};

--Save management
--===================================================

function LK.ResetSave()

	_G["LootKingSave"] = CopyTable( LK.DEFAULT_SAVE );
end

function LK.GetSave()

	return _G["LootKingSave"];
end


--Save upgrades
--====================================================

function LK.Upgrade_1_1()

	local save = LK.GetSave();
	
	if (save.minimapButtonPos == nil) then
		save.minimapButtonPos = LK.DEFAULT_SAVE.minimapButtonPos;
	end
	
	if (save.syncTarget == nil) then
		save.syncTarget = "someone";
	end

end

function LK.Upgrade()

	local save = LK.GetSave();
	local curVersion = save.version;
	
	for i=1,table.getn( LK.UPGRADE_LIST ) do

		local nextVersion = LK.UPGRADE_LIST[i];
		if (PrimeUtil.CompareVersions( curVersion, nextVersion )) then
			
			LK.Print( "Upgrading settings from version "..curVersion.." to "..nextVersion, true );
			
			local verString = string.gsub( nextVersion, "[.]", "_" );
			local funcName = "Upgrade_"..verString;
			local func = LK[ funcName ];
			
			if (func) then func() else
				LK.Error( "Missing upgrade function!" );
			end
			
			curVersion = nextVersion;
		end
	end
	
	save.version = LK.VERSION;
end
