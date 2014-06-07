

-- Send portal render code
AddCSLuaFile( "autorun/client/init.lua" )

-- Precache network string
util.AddNetworkString( "WorldPortalUpdate" )

-- Send info about portals to clients
local function WorldPortalUpdate( ply )

	ply:DrawViewModel(false)
	local portals = ents.FindByClass( "linked_portal_door" )
	
	net.Start( "WorldPortalUpdate" )
		net.WriteInt( #portals, 16 )
		
		for _, portal in ipairs( portals ) do			
			net.WriteVector( portal:GetPos() )
			net.WriteInt( portal.width, 16 )
			net.WriteInt( portal.height, 16 )
			net.WriteVector( portal.forward )
			net.WriteInt( table.KeyFromValue( portals, portal.exit ), 16 )
		end
	net.Send( ply )
end
hook.Add( "PlayerInitialSpawn", "WorldPortalUpdateTransmission", WorldPortalUpdate )

-- Set up visibility through portals
hook.Add( "SetupPlayerVisibility", "WorldPortalVisibility", function( ply, ent )
	for _, portal in ipairs( ents.FindByClass( "linked_portal_door" ) ) do
		AddOriginToPVS( portal:GetPos() )
	end
end )
