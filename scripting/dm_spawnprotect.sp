#include <sourcemod>

#define DOD_MAXPLAYERS 33
#define Team_Allies    2

new Handle:IsFreeForAllMode = INVALID_HANDLE,
    Handle:SpawnProtectTime = INVALID_HANDLE,
    Handle:SpawnProtectTimer[DOD_MAXPLAYERS + 1] = INVALID_HANDLE,
    bool:Protected[DOD_MAXPLAYERS + 1] = false

public Plugin:myinfo =
{
	name        = "DM SpawnProtect",
	author      = "Root",
	description = "Prevent spawn killing in DeathMatch",
	version     = "1.0",
	url         = "http://www.dodsplugins.com/"
}


public OnPluginStart()
{
	SpawnProtectTime = CreateConVar("dm_spawnprotect_time", "1.0", "<#> = Time (in seconds) to prevent player from taking damage after respawning", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0)

	IsFreeForAllMode = FindConVar("mp_friendlyfire")

	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post)

	AutoExecConfig(true, "dm.spawnprotect")
}

public OnClientPostAdminCheck(client)
{
	Protected[client] = false
}

public OnClientDisconnect(client)
{
	KillSpawnProtTimer(client)
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))

	if(GetConVarInt(SpawnProtectTime) && IsPlayerValid(client))
	{
		KillSpawnProtTimer(client)

		Protected[client] = true

		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1)

		SpawnProtectTimer[client] = CreateTimer(GetConVarFloat(SpawnProtectTime), SpawnProtectOff, client, TIMER_FLAG_NO_MAPCHANGE)

		if(GetConVarBool(IsFreeForAllMode) == false)
		{
			if(GetClientTeam(client) == Team_Allies)
			{
				SetEntityRenderColor(client, 0, 255, 0, 255)
			}
			else
			{
				SetEntityRenderColor(client, 255, 0, 0, 255)
			}
		}
		else SetEntityRenderColor(client, 0, 0, 0, 255)
	}
	return Plugin_Continue
}

public Action:SpawnProtectOff(Handle:timer, any:client)
{
	SpawnProtectTimer[client] = INVALID_HANDLE

	if(IsPlayerValid(client))
	{
		Protected[client] = false

		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1)
		SetEntityRenderColor(client)

		return Plugin_Handled
	}
	return Plugin_Handled
}

KillSpawnProtTimer(client)
{
	Protected[client] = false

	if(SpawnProtectTimer[client] != INVALID_HANDLE)
		CloseHandle(SpawnProtectTimer[client])
	SpawnProtectTimer[client] = INVALID_HANDLE
}

bool:IsPlayerValid(client)
{
	return (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) >= Team_Allies) ? true : false
}