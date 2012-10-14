#include <sourcemod>

#define PLUGIN_NAME			"DM SpawnProtect"
#define PLUGIN_AUTHOR		"Root"
#define PLUGIN_DESCRIPTION	"Prevent SpawnKilling in Deathmatch"
#define PLUGIN_VERSION		"1.0"
#define PLUGIN_CONTACT		"http://www.dodsplugins.com/"

#define DOD_MAXPLAYERS		33
#define ALLIES				2
#define AXIS				3

public Plugin:myinfo =
{
	name			= PLUGIN_NAME,
	author			= PLUGIN_AUTHOR,
	description		= PLUGIN_DESCRIPTION,
	version			= PLUGIN_VERSION,
	url				= PLUGIN_CONTACT
}

new Handle:DeathmatchMode = INVALID_HANDLE,
	Handle:SpawnProtectTime = INVALID_HANDLE,
	Handle:SpawnProtectTimer[DOD_MAXPLAYERS] = INVALID_HANDLE,
	bool:IsProtected[DOD_MAXPLAYERS] = false


public OnPluginStart()
{
	SpawnProtectTime = CreateConVar("dm_spawnprotect_time", "1.0", "<#> = time in seconds to prevent players from taking damage after spawning", FCVAR_PLUGIN, true, 0.0)

	DeathmatchMode = FindConVar("mp_friendlyfire")

	HookEventEx("player_spawn", OnPlayerSpawn, EventHookMode_Post)

	AutoExecConfig(true, "dm.spawnprotect")
}

public OnClientPostAdminCheck(client)
{
	IsProtected[client] = false
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
		if(GetConVarInt(DeathmatchMode) == 0)
		{
			KillSpawnProtTimer(client)

			IsProtected[client] = true

			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1)
			SetEntityRenderColor(client, 0, 0, 0, 255)

			SpawnProtectTimer[client] = CreateTimer(GetConVarFloat(SpawnProtectTime), SpawnProtectOff, client, TIMER_FLAG_NO_MAPCHANGE)
		}
		else
		{
			KillSpawnProtTimer(client)

			IsProtected[client] = true

			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1)

			new team = GetClientTeam(client)

			if(team == ALLIES)
			{
				SetEntityRenderColor(client, 0, 255, 0, 255)
				SpawnProtectTimer[client] = CreateTimer(GetConVarFloat(SpawnProtectTime), SpawnProtectOff, client, TIMER_FLAG_NO_MAPCHANGE)
			}

			else
			{
				SetEntityRenderColor(client, 255, 0, 0, 255)
				SpawnProtectTimer[client] = CreateTimer(GetConVarFloat(SpawnProtectTime), SpawnProtectOff, client, TIMER_FLAG_NO_MAPCHANGE)
			}
		}
	}
	return Plugin_Continue
}

public Action:SpawnProtectOff(Handle:timer, any:client)
{
	SpawnProtectTimer[client] = INVALID_HANDLE

	if(IsPlayerValid(client))
	{
		IsProtected[client] = false

		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1)
		SetEntityRenderColor(client)

		return Plugin_Handled
	}
	return Plugin_Handled
}

KillSpawnProtTimer(client)
{
	IsProtected[client] = false

	if(SpawnProtectTimer[client] != INVALID_HANDLE)
		CloseHandle(SpawnProtectTimer[client])
	SpawnProtectTimer[client] = INVALID_HANDLE
}

bool:IsPlayerValid(client)
{
	return (client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > 1) ? true : false
}