
local portals
local matView = CreateMaterial(
	"UnlitGeneric",
	"GMODScreenspace",
	{
		["$basetexturetransform"] = "center .5 .5 scale -1 -1 rotate 0 translate 0 0",
		["$texturealpha"] = "0",
		["$vertexalpha"] = "1",
	}
)
local matDummy = Material( "debug/white" )


-- Render the portal views
local drawing = false

hook.Add( "RenderScene", "WorldPortalRenderHook", function( plyOrigin, plyAngles)

	if ( not portals ) then return end
	if ( drawing ) then return end

	local oldWepColor = LocalPlayer():GetWeaponColor()
	LocalPlayer():SetWeaponColor( Vector(0, 0, 0) ) --no more phys gun glaw or beam
	
	for _, portal in ipairs( portals ) do
		-- Render view from portal
		local oldRT = render.GetRenderTarget()
		render.SetRenderTarget( portal.texture )
			render.Clear( 0, 0, 0, 255 )
			render.ClearDepth()
			render.ClearStencil()

			render.EnableClipping(true)
			--render.PopCustomClipPlane()
			render.PushCustomClipPlane(portals[portal.exit].forward, portals[portal.exit].forward:Dot(portals[portal.exit].pos) )
			
			local rotation = portals[portal.exit].forward:Angle() - portal.forward:Angle()
			rotation = rotation + Angle( 0, 180, 0)
			local offset = LocalPlayer():EyePos() - portal.pos
			--offset = calculateNewOffset( portal, offset )
			offset:Rotate( rotation )
			local camPos = portals[portal.exit].pos + offset

			local camAngles = plyAngles + rotation 
			
			drawing = true
				render.RenderView( {
					x = 0,
					y = 0,
					w = ScrW(),
					h = ScrH(),
					origin = camPos,
					angles = camAngles,
					drawpostprocess = true,
					drawhud = false,
					drawmonitors = false,
					drawviewmodel = false,
				} )
			drawing = false

		render.PopCustomClipPlane()
		render.EnableClipping(false)
		render.SetRenderTarget( oldRT )
	end

	LocalPlayer():SetWeaponColor( oldWepColor )
end )
hook.Add( "PreDrawOpaqueRenderables", "WorldPortalRenderHook", function()

	render.UpdateScreenEffectTexture()
	
	if ( not portals ) then return end
	if ( drawing ) then return end
	
	for _, portal in ipairs( portals ) do

		-- Draw view over portal
		render.ClearStencil()
		render.SetStencilEnable( true )

		render.SetStencilWriteMask( 1 )
    	render.SetStencilTestMask( 1 )

		render.SetStencilFailOperation( STENCILOPERATION_KEEP )
		render.SetStencilZFailOperation( STENCILOPERATION_KEEP )
		render.SetStencilPassOperation( STENCILOPERATION_REPLACE )
		render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_ALWAYS )
		render.SetStencilReferenceValue( 1 )
		
		render.SetMaterial( matDummy )
		render.SetColorModulation( 1, 1, 1 )

		render.DrawQuadEasy( portal.pos, portal.forward, portal.width, portal.height, Color( 255, 255, 255, 255) )
		
		render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )
		render.SetStencilPassOperation( STENCILOPERATION_REPLACE )
		render.SetStencilReferenceValue( 1 )
		
		matView:SetTexture( "$basetexture", portal.texture )
		render.SetMaterial( matView )
		render.DrawScreenQuad()
		
		render.SetStencilEnable( false )
	end
end )

-- Receive portal info
net.Receive("WorldPortalUpdate", function()
	portals = {}
	
	for i = 1, net.ReadInt( 16 ) do
		portals[i] = {}
		portals[i].pos = net.ReadVector()
		portals[i].width = net.ReadInt( 16 )
		portals[i].height = net.ReadInt( 16 )
		portals[i].forward = net.ReadVector()
		portals[i].exit = net.ReadInt( 16 )
		portals[i].texture = GetRenderTarget("portal" .. i,
			ScrW(),
			ScrH(),
			false
		)
	end

end )

-- Set it to draw the player while rendering portals
-- Calling Start3D to fix this is incredibly hacky

hook.Add( "PostDrawEffects", "WorldPortalPotentialFix", function()
	cam.Start3D( EyePos(), EyeAngles() )
	cam.End3D()
end)

hook.Add( "ShouldDrawLocalPlayer", "WorldPortalRenderHook", function()
	return drawing
end)
