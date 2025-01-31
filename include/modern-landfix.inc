#if defined _modlandfix_included
	#endinput
#endif
#define _modlandfix_included

public SharedPlugin __pl_modlandfix =
{
    name = "modern-landfix",
    file = "modern-landfix.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

native bool Landfix_GetLandfixEnabled(int client);

#if !defined REQUIRE_PLUGIN
public void __pl_modlandfix_SetNTVOptional()
{
	MarkNativeAsOptional("Landfix_GetLandfixEnabled");
}
#endif
