
ENT.Type = "point"


-- Find paired entity
-- not the most efficient implementation, but good enough for now
function ENT:Think()
	-- Determine exit portal
	if ( !self.exit ) then
		for _, ent in ipairs( ents.FindByClass( "linked_portal_door" ) ) do
			if ( ent ~= self and ent.pair == self.pair ) then
				self.exit = ent
			end
		end
	end
end

-- Collect properties
function ENT:KeyValue( key, value )
	if ( key == "pair" ) then
		self.pair = tonumber( value )

	elseif ( key == "width" ) then
		self.width = tonumber( value )

	elseif ( key == "height" ) then
		self.height = tonumber( value )

	elseif ( key == "angles" ) then
		local args = value:Split( " " )

		for k, arg in pairs( args ) do
			args[k] = tonumber(arg)
		end

		self.forward = Angle( unpack(args) ):Forward()
		print( value, forward )
	end
end