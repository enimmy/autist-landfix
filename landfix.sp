#pragma newdecls required
#pragma semicolon 1

#include <sdktools>
#include <sdkhooks>

#undef REQUIRE_PLUGIN
#include <shavit/core>
#include <shavit/hud>

public Plugin myinfo = 
{
	name = "LandFix",
	author = "Haze",
	description = "",
	version = "1.3",
	url = ""
}

bool gB_Enabled[MAXPLAYERS+1] = {false, ...};
bool gB_Shavit = false;
int gI_LastGroundEntity[MAXPLAYERS + 1];

public void OnPluginStart()
{
	RegConsoleCmd("sm_landfix", Command_LandFix, "Landfix");
	RegConsoleCmd("sm_64fix", Command_LandFix, "Landfix");
	
	for(int i = 1; i <= MaxClients; i++)
	{
		gB_Enabled[i] = false;	
	}
	gB_Shavit = LibraryExists("shavit");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Landfix_GetLandfixEnabled", Native_GetLandfixEnabled);
	RegPluginLibrary("modern-landfix");
	return APLRes_Success;
}

int Native_GetLandfixEnabled(Handle handler, int numParams)
{
	return gB_Enabled[GetNativeCell(1)];
}

public void OnLibraryAdded(const char[] name)
{
	gB_Shavit = LibraryExists("shavit");
}

public void OnLibRaryRemoved(const char[] name)
{
	gB_Shavit = LibraryExists("shavit");
}

public void OnClientPutInServer(int client)
{
	gB_Enabled[client] = false;
}

public Action Command_LandFix(int client, int args)
{
	if(client == 0) return Plugin_Handled;

	gB_Enabled[client] = !gB_Enabled[client];

	if(gB_Shavit)
	{
		Shavit_PrintToChat(client, "LandFix: %s", gB_Enabled[client] ? "Enabled" : "Disabled");
	}
	else
	{
		PrintToChat(client, "LandFix: %s", gB_Enabled[client] ? "Enabled" : "Disabled");
	}
	return Plugin_Handled;
}

//Thanks MARU for the idea/http://steamcommunity.com/profiles/76561197970936804
float GetGroundUnits(int client)
{
	if (!IsPlayerAlive(client)) return 0.0;
	if (GetEntityMoveType(client) != MOVETYPE_WALK) return 0.0;
	if (GetEntProp(client, Prop_Data, "m_nWaterLevel") > 1) return 0.0;

	float origin[3], originBelow[3], landingMins[3], landingMaxs[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", origin);
	GetEntPropVector(client, Prop_Data, "m_vecMins", landingMins);
	GetEntPropVector(client, Prop_Data, "m_vecMaxs", landingMaxs);
	
	originBelow[0] = origin[0];
	originBelow[1] = origin[1];
	originBelow[2] = origin[2] - 2.0;

	TR_TraceHullFilter(origin, originBelow, landingMins, landingMaxs, MASK_PLAYERSOLID, PlayerFilter, client);

	if(!TR_DidHit())
	{
		return 0.0;
	}

	TR_GetEndPosition(originBelow, null);

	float defaultHeight = originBelow[2] - RoundToFloor(originBelow[2]);
	if(defaultHeight > 0.03125) 
	{
		defaultHeight = 0.03125;
	}

	return (origin[2] - originBelow[2] + defaultHeight);
}

public Action Shavit_PreOnKeyHintHUD(int client, int target, char[] keyhint, int keyhintlength, int track, int style, bool &forceUpdate)
{
	Format(keyhint, keyhintlength, "Landfix: %s\n\n", gB_Enabled[client] ? "On":"Off");
	forceUpdate = true;
	return Plugin_Changed;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(IsFakeClient(client))
	{
		return Plugin_Continue;
	}

	int iGroundEnt = GetEntPropEnt(client, Prop_Data, "m_hGroundEntity");

	if(gB_Enabled[client]) 
	{
		if(iGroundEnt != gI_LastGroundEntity[client] && iGroundEnt != -1)
		{
			if(HasEntProp(iGroundEnt, Prop_Data, "m_currentSound")) //retrowave mega fix
			{
				return Plugin_Continue;
			}

			bool bHasVelocityProp = HasEntProp(iGroundEnt, Prop_Data, "m_vecVelocity");

			if(bHasVelocityProp)
			{
				float fVelocity[3];
				GetEntPropVector(iGroundEnt, Prop_Data, "m_vecVelocity", fVelocity);

				// ground is moving
				if(fVelocity[2] != 0.0)
				{
					return Plugin_Continue;
				}
			}

			//float difference = (gCV_Units.FloatValue - GetGroundUnits(client)), origin[3];
			float difference = (1.50 - GetGroundUnits(client)), origin[3];
			GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", origin);
			origin[2] += difference;
			SetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", origin);
		}
	}

	gI_LastGroundEntity[client] = iGroundEnt;

	return Plugin_Continue;
}

public bool PlayerFilter(int entity, int mask)
{
	return !(1 <= entity <= MaxClients);
}