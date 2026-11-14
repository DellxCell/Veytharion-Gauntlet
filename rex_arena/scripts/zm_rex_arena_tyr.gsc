// Rex Arena 0.7.3: Rex's animation tree for the Tyr drop, in its own script.
// 0.7.7: shipped as .gsc source; the tree, the clip and the key in plain text.
// Kronos links every mod script on every map, and zm_rex_arena naming Rex's
// tree crashed other maps while loading (cod25-cod.exe+ac04117). This script
// includes a Rex map script (script_6c1f17f235760ccc, Rex's Boss Rush, which
// binds the same tree), so Kronos links it on Rex only; on other maps it logs
// "include ... missing" and skips it. In the arena match it registers the tree
// and Tyr's two clips under the mod's own key, as zm_rex_arena did since 0.2.0;
// zm_rex_arena reads them from the level.
#using script_6c1f17f235760ccc;

#using_animtree( "zm_sat_scarab_scriptables" );

autoexec ra_tyr_tree()
{
    if ( getdvar( @"hash_dddf7dca1a52e591", "null" ) != "zone_boss_arena_ff" )
        return;
    if ( getdvar( "mapname" ) != "zm_sat_scarab" && getdvar( "ui_mapname" ) != "zm_sat_scarab" )
        return;
    level.var_dc93f7e52123aeea[ "ra_tyr_player" ] = #animtree;
    level.var_c64390d83bf618a6[ "ra_tyr_player" ][ "player_sucked_in" ][ 0 ] = %sat_mp_strafe_fast_jump_air_8;
    level.var_fcd9208987c2f338[ "ra_tyr_player" ][ "player_sucked_in" ][ 0 ] = %"hash_353febbc4b7c56cc";
}
