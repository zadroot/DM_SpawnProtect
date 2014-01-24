#define DOD_MAXPLAYERS 33
#define Team_Allies    2

new Handle:SpawnProtectTime = INVALID_HANDLE,
    Handle:SpawnProtectTimer[DOD_MAXPLAYERS + 1] = INVALID_HANDLE,
    bool:Protected[DOD_MAXPLAYERS + 1] = false,
	bool:IsFreeForAll

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

	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post)

	AutoExecConfig(true, "dm.spawnprotect")
}

public OnAllPluginsLoaded()
{
	static Handle:dm_mode = INVALID_HANDLE;

	if ((dm_mode = FindConVar("dm_mode")))
	{
		IsFreeForAll = true
	}

	if (dm_mode != INVALID_HANDLE)
		CloseHandle(dm_mode);
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
	new clientID = GetEventInt(event, "userid");
	new client   = GetClientOfUserId(clientID);

	if (IsPlayerValid(client) && GetConVarInt(SpawnProtectTime))
	{
		KillSpawnProtTimer(client)

		Protected[client] = true

		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1)

		SpawnProtectTimer[client] = CreateTimer(GetConVarFloat(SpawnProtectTime), SpawnProtectOff, clientID, TIMER_FLAG_NO_MAPCHANGE)

		if (!IsFreeForAll)
		{
			if (GetClientTeam(client) == Team_Allies)
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
	if ((client = GetClientOfUserId(client)))
	{
		SpawnProtectTimer[client] = INVALID_HANDLE

		if (IsPlayerValid(client))
		{
			Protected[client] = false

			SetEntProp(client, Prop_Data, "m_takedamage", 2, 1)
			SetEntityRenderColor(client)
		}
	}
}

KillSpawnProtTimer(client)
{
	Protected[client] = false

	if(SpawnProtectTimer[client] != INVALID_HANDLE)
	{
		CloseHandle(SpawnProtectTimer[client])
	}

	SpawnProtectTimer[client] = INVALID_HANDLE
}

bool:IsPlayerValid(client) return (1 <= client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) >= Team_Allies) ? true : false