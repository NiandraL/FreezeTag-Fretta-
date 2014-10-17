
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_postprocess.lua" )
AddCSLuaFile( "cl_hud.lua" )

include( "shared.lua" )
include( "tables.lua" )
include( "ply_extension.lua" )

function GM:OnRoundStart()
	
	UTIL_UnFreezeAllPlayers()
	
end

function GM:CanStartRound()
	if #team.GetPlayers( TEAM_RED ) + #team.GetPlayers( TEAM_BLUE ) >= 2 then return true end
	return false
end

function GM:OnRoundResult( t )
	
	team.AddScore( t, 1 )
	
	for k,v in pairs( player.GetAll() ) do 
	
		v:Thaw()
		
		if v:Team() == t then
			v:SendLua("surface.PlaySound( \"" .. GAMEMODE.WinSound .. "\" )")
			
		else
			v:SendLua("surface.PlaySound( \"" .. GAMEMODE.LoseSound .. "\" )")
		end
		
	end
	
end

function GM:RoundTimerEnd()

	if ( !GAMEMODE:InRound() ) then return end
	
	if GAMEMODE:GetFrozenPlayers( TEAM_RED ) < GAMEMODE:GetFrozenPlayers( TEAM_BLUE ) then
		GAMEMODE:RoundEndWithResult( TEAM_RED, "RED WINS!" )
	elseif GAMEMODE:GetFrozenPlayers( TEAM_RED ) > GAMEMODE:GetFrozenPlayers( TEAM_BLUE ) then
		GAMEMODE:RoundEndWithResult( TEAM_BLUE, "BLUE WINS!" )
	else
		GAMEMODE:RoundEndWithResult( -1, "NOBODY WINS!" )
	end

end

function GM:CheckRoundEnd()

	if ( team.NumPlayers( TEAM_RED ) + team.NumPlayers( TEAM_BLUE ) ) < 2 then return end

	if GAMEMODE:GetFrozenPlayers( TEAM_RED ) == team.NumPlayers( TEAM_RED ) and team.NumPlayers( TEAM_RED ) > 0 then
		GAMEMODE:RoundEndWithResult( TEAM_RED, "BLUE WINS!" )
	elseif GAMEMODE:GetFrozenPlayers( TEAM_BLUE ) == team.NumPlayers( TEAM_BLUE ) and team.NumPlayers( TEAM_BLUE ) > 0 then
		GAMEMODE:RoundEndWithResult( TEAM_BLUE, "RED WINS!" )
	end

end

function GM:EntityTakeDamage( ent, dmginfo )

	local attacker = dmginfo:GetAttacker()
	local inflictor = dmginfo:GetAttacker()

	if not ent:IsPlayer() then return end
	if not ent:Alive() then return end
	
	if dmginfo:IsFallDamage() or ent == attacker or not attacker:IsPlayer() or not GAMEMODE:InRound() then
	
		dmginfo:SetDamage( 0 ) 
		return
		
	end
	
	if ent:IsFrozen() then
	
		ent:EmitSound( table.Random( GAMEMODE.GlassHit ) )
		
		if attacker:Team() == ent:Team() then
		
			ent:SetHealth( math.Clamp( ent:Health() + dmginfo:GetDamage() * 0.3, 1, ent:GetMaxHealth() ) ) 
			dmginfo:SetDamage( 0 )
			
			if ent:Health() == ent:GetMaxHealth() then
			
				ent:Thaw( true )
				ent:ChatPrint("You were unfrozen by "..attacker:Nick().."!")
				
				
				umsg.Start( "PlayerKilledByPlayer" ) 
		 		umsg.Entity( ent ) 
		 		umsg.String( "thaw" ) 
		 		umsg.Entity( attacker ) 
		 		umsg.End() 
				
			end
			
		else
			dmginfo:SetDamage( 0 )
		end
		
		return
		
	end
	
	if ent:Health() - dmginfo:GetDamage() < 1 then
	
		if IsValid( attacker ) and attacker:IsPlayer() then
		
			if attacker:Team() != ent:Team() then
			
				ent:SetHealth( 1 )
				ent:AddDeaths( 1 )
				ent:Flashlight( false )
				ent:IceFreeze()
				ent:ChatPrint("You were frozen in place by "..attacker:Nick().."!")
				
				dmginfo:SetDamage( 0 )
				
				
				if ( ( inflictor and inflictor == attacker ) or inflictor:IsPlayer() ) then
					inflictor = attacker:GetActiveWeapon()
				end
				
				umsg.Start( "PlayerKilledByPlayer" ) 
				umsg.Entity( ent ) 
				umsg.String( inflictor:GetClass() ) 
				umsg.Entity( attacker ) 
				umsg.End() 
				
			end
		end
	end
end

function GM:GetFrozenPlayers( t )

	local num = 0
	
	for k,v in pairs( team.GetPlayers( t ) ) do
	
		if v:IsFrozen() or not v:Alive() then
			num = num + 1
		end
		
	end
	
	return num
	
end

function GM:PlayerJoinTeam(ply, teamid) 
	if (!GAMEMODE:InRound()) and ply:Team() == TEAM_UNASSIGNED and (teamid == TEAM_RED or TEAM_BLUE) then 
		ply:SetTeam(teamid)
	end
	
	if ply:Team() != TEAM_SPECTATOR and teamid == TEAM_SPECTATOR then
		ply:SetTeam(TEAM_SPECTATOR)
		ply:KillSilent()
		ply:ChatPrint(""..ply:Nick()..", you've joined Spectators.")
	end	
	
	if (ply:Team() == TEAM_UNASSIGNED or TEAM_SPECTATOR) and ( GAMEMODE:InRound() ) and GetGlobalFloat("RoundStartTime",CurTime()) - 30 < CurTime() 
		and (teamid == TEAM_RED or TEAM_BLUE) then
		ply:SetTeam(teamid)
		timer.Simple(1, function()
			ply:Spawn()
			print("Late player successfully spawned.")
		end)
	end	
	if (ply:Team() == TEAM_UNASSIGNED or TEAM_SPECTATOR) and ( GAMEMODE:InRound() ) and GetGlobalFloat("RoundStartTime",CurTime()) + 30 < CurTime()
		and (teamid == TEAM_RED or TEAM_BLUE) then
		timer.Simple(1, function()
		ply:KillSilent()
		ply:SetTeam(teamid)
		ply:ChatPrint("You'll spawn automatically when next round starts, "..ply:Nick()..".")
		print("Late player has not been spawned.")
		end)
	end
end
