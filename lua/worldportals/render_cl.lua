
--Setup variables
worldportals.matView = CreateMaterial(
	"UnlitGeneric",
	"GMODScreenspace",
	{
		["$basetexturetransform"] = "center .5 .5 scale -1 -1 rotate 0 translate 0 0",
		["$texturealpha"] = "0",
		["$vertexalpha"] = "1",
	}
)
worldportals.matDummy = Material( "debug/white" )


--POTENTIAL IMPROVEMENT
--add portals when they're created
--remove portals when they're destroyed
--this would be slightly better than just finding all of them every frame
--hook.Add( "OnEntityCreated", "WorldPortalRenderHook", function( ent )

local portals
worldportals.drawing = true --default portals to not draw

--Start drawing the portals
--This prevents the game from crashing when loaded for the first time
hook.Add( "PostRender", "WorldPortals_StartRender", function()
	worldportals.drawing = false
	hook.Remove( "PostRender", "WorldPortals_StartRender" )
end )

local function ShouldRender( portal, exitPortal, plyOrigin )

	local distance = plyOrigin:Distance( portal:GetPos() )
	local disappearDist = portal:GetDisappearDist()

	if not (disappearDist <= 0) and distance > disappearDist then return false end

	if not IsValid( exitPortal ) then return false end

	if not portal:GetShouldDrawNextFrame() then return false end

	--don't render if the player is behind the portal
	local vec = plyOrigin - portal:GetPos()
	if ( portal:GetForward():Dot( vec ) < 0 ) then return false end

	portal:SetShouldDrawNextFrame( false )

	return true
end



-- Render views from the portals
hook.Add( "RenderScene", "WorldPortals_Render", function( plyOrigin, plyAngles )

	portals = ents.FindByClass( "linked_portal_door" )

	if ( not portals ) then return end
	if ( worldportals.drawing ) then return end

	--Disable phys gun glow and beam
	local oldWepColor = LocalPlayer():GetWeaponColor()
	LocalPlayer():SetWeaponColor( Vector(0, 0, 0) )
	
	for _, portal in pairs( portals ) do

		local exitPortal = portal:GetExit()

		if not ShouldRender( portal, exitPortal, plyOrigin ) then continue end

		local oldRT = render.GetRenderTarget()
		render.SetRenderTarget( portal:GetTexture() )
			render.Clear( 0, 0, 0, 255 )
			render.ClearDepth()
			render.ClearStencil()

			render.EnableClipping(true)
			render.PushCustomClipPlane( exitPortal:GetForward(), exitPortal:GetForward():Dot(exitPortal:GetPos() - (exitPortal:GetForward() *0.5) ) )

			local localOrigin = portal:WorldToLocal( plyOrigin )
			local localAngles = portal:WorldToLocalAngles( plyAngles )

			localOrigin:Rotate( Angle(0, 180, 0) )
			localAngles:RotateAroundAxis( Vector(0, 0, 1), 180)

			local camOrigin = exitPortal:LocalToWorld( localOrigin )
			local camAngles = exitPortal:LocalToWorldAngles( localAngles )

			worldportals.drawing = true
				render.RenderView( {
					x = 0,
					y = 0,
					w = ScrW(),
					h = ScrH(),
					origin = camOrigin,
					angles = camAngles,
					drawpostprocess = true,
					drawhud = false,
					drawmonitors = false,
					drawviewmodel = false,
				} )
			worldportals.drawing = false

			render.PopCustomClipPlane()
			render.EnableClipping(false)
		render.SetRenderTarget( oldRT )
	end

	LocalPlayer():SetWeaponColor( oldWepColor )
end )

-- Set it to draw the player while rendering portals
-- Calling Start3D to fix this is incredibly hacky
hook.Add( "PostDrawEffects", "WorldPortals_PlayerDrawFix", function()
	cam.Start3D( EyePos(), EyeAngles() )
	cam.End3D()
end)

hook.Add( "ShouldDrawLocalPlayer", "WorldPortals_PlayerDraw", function()
	if worldportals.drawing then
		return true
	end
end)
