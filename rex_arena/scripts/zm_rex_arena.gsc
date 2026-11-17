// Rex Arena 1.2.1: Rex Infernus (zm_sat_scarab) arena match, written for Rex.
// Ashes Arena 0.4.43 is the reference; nothing here is shared with it at run
// time (own ra_ names, own "rex_arena" store, own notifies).
// Start: the mod Lua (lua/zm_rex_arena_post.lua) starts Rex round-based with
// the POI dvar 0xdddf7dca1a52e591 set to zone_boss_arena_ff. No Rex script
// reads that dvar; it only selects this script. Every change is gated by
// ra_selected().
// Arena: Rex's copy of the Ashes of the Damned boss arena, zone
// zone_boss_arena_ff (Rex = Ashes - (17096, 27072, -2248)).
// 0.1.3 (seen working in game): the zone is enabled and each spawned player is
// moved onto one of the arena's four authored player points.
// 0.2.0: after that move the player drops in as on Ashes Arena: Totenreich's
// exit from Tyr (fade to white, a three second ride down from 3000 units on a
// mover with the first-person rig, fade to black, landing shake and shockwave,
// fade in), ending under the arena cap. Rex's map zone networks Tyr's rig
// clip and Rex's own animation tree defines it, so Totenreich's rig is used
// on that tree and Ashes Arena's engine-freefall arms are left out. A
// watchdog lands the player if the drop stalls.
// 0.2.1: 0.2.0 showed Tyr's hands and the player's gun together. The gun is
// now lowered for the ride with Totenreich's own first state override.
// 0.2.2: on a bad launch (Kronos' weapon-filter hook failed at game start)
// the drop stops the client on the white screen. The script cannot see that
// hook, so it reads kronos/rex_arena/launch.json, written outside the game
// from Kronos' log, and can leave out the gun lowering, the first-person
// rig, the state overrides or the whole drop (ra_read_launch).
// 0.3.0: the reference mod's specials, elites and HVTs (same pools, rounds and
// waves), and two Rex bosses: Z-Rex from round 50 and the Guardian from round
// 75, once each. The launch file can move those two rounds for a test.
// 0.3.1: the Guardian gets the game's boss health bar (Z-Rex shows its own).
// 0.3.2: both bosses are made in the middle of the arena.
// 0.3.3: from round 100 Z-Rex and the Guardian come together. This mod's
// bosses take no damage from each other.
// 0.3.4: the Guardian's slam kills a zombie-type enemy in its inner radius
// outright (no damage event), which killed Z-Rex. A boss killed that way
// while the other is alive is made again with the health it had. While both
// are alive the mod Lua draws a second health bar from the dvar
// rex_arena_bar2.
// 0.3.5: the direct kill is recognised by the health the boss had (its
// fields are gone once it is dead). While both bosses are alive only the
// boss the game's bar follows may write to that bar.
// 0.3.6: the second bar is a second copy of the game's boss bar widget,
// given each boss's bar list entry (name and icon) the way the game's bar
// script finds it.
// 0.3.7: after a boss dies for good its bar is taken down (or switched to
// the other boss) with the game's own bar functions.
// 0.3.8: try to hide a slam-killed Z-Rex before making it again.
// 0.3.9: no corpse (no death animation) for a Z-Rex that will be made again,
//        and the new one faces the way the old one did.
// 0.4.0: Z-Rex is sent toward the nearest player while it is far away.
// 0.4.1: Ashes Arena's no super sprinters, half-price ammo, Mystery Box,
//        Rampage Inducer and T.E.D.D.; the Wunderfizz from round 1 without power.
// 0.4.2: after a round skip the latest owed boss event is made (round 100:
//        both bosses); events the skip passed over are dropped.
// 0.4.3: the Guardian is no longer held at its spawn point (Rex's own
//        boss fight sets the same field on its Guardian).
// 0.4.4: a killing blow on Z-Rex is held at 1 health so Z-Rex's own death
//        sequence (its death animation) runs on the next hit.
// 0.4.5: while the Guardian lives, a Z-Rex death that did not come from 1
//        health (the slam's kill) is undone at any health, not only above 5%.
// 0.4.6: the hold also runs after DellxCell's damage multiplier, and a death
//        counts as a slam only with the Guardian within 800 units.
// 0.4.7: tried a type value of this mod's own on Z-Rex near the hammer; the
//        game ignored the write, so 0.4.8 has no label code.
// 0.4.8: a Z-Rex death is undone only for a slam seen landing inside its kill
//        circle (or the slam's own mark); hits during its death sequence are
//        cancelled.
// 0.4.9: records of every Z-Rex death and of hits at 1 health; nocorpse is
//        cleared on a new Z-Rex and whenever it is held at 1 health.
// 0.5.0: nocorpse is never written as 0 (0.4.9 showed that loses Z-Rex's
//        death animation); this mod's own setting is removed with undefined.
// 0.5.1: exfil and GobbleGum machine from Ashes Arena, at the user's
//        World Builder marks (positions only).
// 0.5.2: the GobbleGum machine is 40 units west of its mark (it clipped
//        into the wall on its east side).
// 0.5.3: records of where the Rampage Inducer's parts are, at setup and
//        each time it turns on (a second lantern was reported).
// 0.5.4: the GobbleGum machine is 40 units forward of its mark (toward
//        the arena), not 40 units west as in 0.5.2.
// 0.5.5: 25 units forward of its mark (0.5.4's 40 was a little too far).
// 0.5.6: collision for the Mystery Box and the exfil booth, tiled from
//        copies of a measured map brush (Rex has no box or booth clip).
// 0.5.7: the box copies are sunk into the floor so their top is level
//        with the box top (0.5.6 left them 140 high around the box).
// 0.5.8: Mystery Box collision removed at the user's request (the
//        exfil booth collision stays).
// 0.5.9: Mystery Box collision from a hidden solid copy of the box's own
//        model at the box (its real shape), with probe records.
// 0.5.10: that copy removed (it gave no collision; a crash near the box
//        was reported). The box has no collision again, as in 0.5.8.
// 0.5.11: Mystery Box collision: a solid column on the box platform's
//        base (120 x 48, from the box model) from the floor up, tiled
//        from copies of one of Rex's own clip brushes.
// 0.5.12: each candidate brush is built then checked with traces along
//        the front face; one that leaves a step or a gap is removed.
// 0.5.13: records only: a trace map around the box before and after the
//        column, and where players stand around it.
// 0.5.14: the box runs along world Y (the user's logged corners), so the
//        column is rebuilt on that base and checked at the front and ends.
// 0.5.15: copies laid in 6 rows, each 8 further back, so a brush solid
//        only in its front part still fills the platform's depth.
// 0.5.16: face check tolerance 5 (0.5.15's best fit was 3.4 inside).
// 0.5.17: Caltheris (sat_spawner_zombie_neptune_zm, boss 2) with Z-Rex as
//        boss event 3 at round 255; its bar by Rex's own call.
// 0.5.18: Caltheris's bar keeps its own phase value (no whole-health
//        rewrite or callback); Z-Rex killed by Caltheris is made again.
// 0.5.19: Caltheris's hits stop under each third (Rex's quest rule) so
//        its phases change; released after 30 s without a change.
// 0.5.20: Caltheris's own phase change is blocked (it never finished in the
//        arena); the mod raises its phase at each third and reloads
//        Rex's per-phase settings.
// 0.5.21: no stop at each third; hits on Caltheris cut by the game after
//        this mod's damage callback are set back to that damage.
// 0.5.22: 5 s phase shield with its bar filling; hits cut in a later
//        phase get the weapon's phase-1 damage back.
// 0.5.23: Caltheris has one whole-health bar (as Rex's Boss Rush); its
//        phase changes are 5 s of immunity at each third.
// 0.5.24: the bar shows the game's immune state during those 5 s.
// 0.5.25: round 500: Z-Rex, the Guardian and Caltheris together, three bars
//        in a row; the bosses are kept from killing each other.
// 0.5.26: remade bosses keep their bar values; a slain Caltheris that is made
//        again leaves no body; remakes limited per boss (not within 2 s).
// 0.5.27: one-shot hold for the Guardian and Caltheris; round-500 warning,
//        Max Ammo per boss, fight summary; Caltheris's phase on its bar.
// 0.5.28: phase label removed; player hits per boss recorded.
// 0.5.29: round-500 warning removed.
// 0.5.30: the on-screen note has a background panel (mod Lua).
// 0.5.31: round 999: the trio and a fourth boss (0.5.33: the Weyward).
// 0.5.32: where the Weyward is and what hits it; put back when far away.
// 0.5.33: boss 3 is the Weyward, Rex's scorpion boss (was the Dread Skull).
// 0.5.34: the Weyward's Shadow Souls (its shield) in the records; no trial rooms.
// 0.5.35: the Weyward's Shadow Souls are put in the arena.
// 0.5.36: the Weyward's shadow storm crystals are put in the arena.
// 0.5.37: the Weyward's bar above the game's bar, and immune on it.
// 0.5.38: while the Weyward lives the game's bar is down: the Weyward's copy
// in its place, Caltheris's under it.
// 0.5.39: Caltheris's copy under the Weyward's is smaller (slot 4); between
// phases the Weyward stands in the middle of the arena.
// 0.5.40: the Weyward fakes its death twice.
// 0.5.41: six round-select pedestals near the landing spot.
// 0.5.42: the pedestals move to a DellxCell saved position (gone in 0.5.43).
// 0.5.43: the pedestals on the six places the user logged (east section).
// 0.5.44: the round-255 and round-999 pedestals swap places.
// 0.5.45: Rex's Easter egg toys on the pedestals.
// 0.5.46: bigger toys.
// 0.5.47: the round-50 Z-Rex toy twice as big, turned 45 degrees.
// 0.5.48: the round-50 Z-Rex and round-75 Guardian toys three times as big;
// the Z-Rex turned 90 degrees.
// 0.5.49: the toy scale shows (set before the model); sizes from what the
// user saw; the Z-Rex and the Guardian centred by their feet.
// 0.5.50: the round-50 Z-Rex toy as tall as the round-75 Guardian toy.
// 0.5.51: the toys rise and float, as out of Rex's super Easter egg box.
// 0.5.52: the toys rise less and glow purple, as Rex's toy scriptables do.
// 0.5.53: the glow from Rex's own toy scriptables (a script effect did not show).
// 0.5.54: each player gets a copy of each Rex toy, as Rex makes them.
// 0.5.55: a big toy's copy at the toy's size, on the toy, so its glow follows it.
// 0.5.56: the big toys back (a scriptable cannot be scaled), with a purple shroud.
// 0.5.57: no shroud; Rex's toy glow at points over each big toy's body.
// 0.5.58: the arena streams in 5 s before the move into it (was 2).
// 0.5.59: three more glows along the round-50 Z-Rex's tail.
// 0.5.60: seven more on the round-50 Z-Rex's thighs and back.
// 0.5.61: seven more on its shoulders, head top, chest and arms.
// 0.5.62: the Guardians' glow just inside their outline (none between the legs).
// 0.5.63: round 100's toys bigger: the Guardian 2.6, the Z-Rex 3.2 (as tall).
// 0.5.64: round 100's pair 2 to the Guardian's side, centred.
// 0.5.65: round 255's Caltheris as tall as round 100's toys (3.3), outline glow.
// 0.5.66: round 500: the Z-Rex, Caltheris, the Guardian, as big as rounds 100 and 255.
// 0.5.67: round 500's toys about 25 tall (80%), 3 apart.
// 0.5.68: round 999 in two rows (Z-Rex, Guardian; Caltheris, Warden), about 20 tall.
// 0.5.69: pedestal collision (the model's own, else hidden collision blocks).
// 0.5.70: pedestal collision from a fitting map brush (else a PHD Flopper test).
// 0.5.71: no PHD test; brushes up to the base's 26 wide fit (Rex's 25 cubes).
// 0.5.72: an armor wall buy on the arena wall the user logged.
// 0.5.73: its chalk 1 in front of the wall (the offset's sign was wrong).
// 0.5.74: the armor wall buy is the legendary (gold chalk) one.
// 0.5.75: it sells Golden Armor, the Cursed Tier I reward.
// 0.5.76: by Cursed Tier I in the arena (Rex's armor wall buys are one-wall-buy).
// 0.5.77: its outline is gold, as in the game's own Golden Armor mode.
// 0.5.78: gold only from armor Level III; before it, the game's own outline.
// 0.5.79: the outline is set when the Level III state changes (0.5.78 never set it).
// 0.5.80: no T.E.D.D. task in boss rounds (rx_tedd_boss_watch).
// 0.5.81: Caltheris at round 100, Z-Rex and the Guardian at 255; pedestals swapped.
// 0.5.82: beating the round-50 Z-Rex gives every player Golden Armor (ra_zrex_gold_reward).
// 0.5.83: the armor wall buy no longer sells Golden Armor; only Z-Rex gives it.
// 0.5.84: the Golden Armor popup's splash is found in its own table; boss_zrex_splash.
// 0.5.85: the table by its asset hash; else the popup's index from the game's splash list.
// 0.5.86: beating the round-75 Guardian makes Ultra weapon rarity available (ra_guardian_ultra_reward).
// 0.5.87: and the Arsenal's rarity row gets the Ultra upgrade (ra_arsenal_ultra_add, mod Lua).
// 0.5.88: beating the round-100 Caltheris makes Pack-a-Punch IV available (ra_caltheris_pap_reward).
// 0.5.89: the round-100 fight is Caltheris alone (no Z-Rex).
// 0.5.90: two of Rex's Void Claw pedestals in the arena, made by Rex's pedestal system (ra_void_claw).
// 0.5.91: three Void Claw pedestals, on the places the user logged.
// 0.5.92: the Void Claw pedestals block players (copies of Rex's clip cube, ra_void_claw_col).
// 0.5.93: three boss-pedestal fights completed upgrade the Void Claw pedestals (ra_void_claw_reward).
// 0.5.94: the upgrade shows the game's reward popup VOID TALON / NOW AVAILABLE with the user's picture (ra_void_talon_splash).
// 0.5.95: the boss-pedestal progress and the round-select text use the same popup, text only (ra_popup).
// 0.5.96: a boss-pedestal fight is complete 2 s after its bosses (popup right after the reward popup); the round-select popup stays while at the pedestal (leave).
// 0.5.97: the minimap and the objective tracker (SURVIVE) are hidden in the arena match (ra_hide_minimap and the mod Lua's minimap block).
// 0.5.98: the name players see is Veytharion's Gauntlet (menu, loading screen, mod list); the ids stay rex_arena.
// 0.5.99: after the Warden's death the white and black screens are taken down, as Rex's quest does (ra_warden_fade_watch).
// 0.6.0: after those screens, the BOSSES DEFEATED summary, then BO7's Continue Playing? vote (ra_warden_end).
// 0.6.1: the round-select pedestals are off for the whole of a boss fight (ra_boss_fight_on).
// 0.6.2: the BOSSES DEFEATED summary shows on the Warden's black screen; the screen comes down as the Continue Playing? vote opens.
// 0.6.3: 0.6.2 again, installed over 0.6.1 (crash test: three 0.6.2 starts crashed, one 0.6.1 start worked).
// 0.6.4: no exfil during a boss fight; the game's exfil-available flag is off for it, as Rex's Warden fight does (ra_exfil_boss_watch).
// 0.6.5: the squad row shows in Survival > Play in a Squad (the mod Lua re-makes it when the launcher changes its squad rows).
// 0.6.6: Boss Rush's prepare timer before each boss: 30 s for Z-Rex, the Guardian and Caltheris, 60 s for the multi-boss events (ra_prepare_timer_start).
// 0.6.7: no zombies during the prepare timer: spawning paused and the zombies cleared, the game's own way (ra_prepare_timer_clear).
// 0.6.8: killing the boss skips the round, the game's way (ra_boss_round_skip).
// 0.6.9: only the Z-Rex, Guardian and Caltheris fights give Void Talon progress (ra_void_claw_reward).
// 0.7.0: unlimited Void Claw uses during the round-999 boss pedestal fight, the Warden fight's own flag (ra_void_claw_fight).
// 0.7.1: unlimited Void Claw uses for the rest of the match once the Void Talon is unlocked (ra_void_claw_upgrade).
// 0.7.2: the arena pedestals keep their prompt past 3 grabs while uses are unlimited (ra_void_claw_hint).
// 0.7.3: Rex's animation tree moved to zm_rex_arena_tyr (linked on Rex only); other maps no longer crash loading.
// 0.7.4: every pedestal's toys rise and glow from the start, not when a player comes near (ra_round_select_rise_all).
// 0.7.5: menu only (squad row named like the solo row; Survival on the about-to-begin card).
// 0.7.6: the encrypted string constants were read as the game reads them.
// 0.7.7: shipped as .gsc source (Kronos wiki); every encrypted constant is written as its plain text.
// 0.7.8: a boss dead for good drops Boss Rush's four power-ups (ra_boss_drops).
// 0.7.9: the lobby card shows the map 9 picture (Lua only; this script changes only its version).
// 0.7.10: the loading screen names the mode Survival (Lua only; this script changes only its version).
// 1.0: first public release (Kronos Workshop). Rex's own zombies only: the extra specials /
// elites / HVT spawner plans nothing and the HVT 2.5x health rule is gone.
// 1.0.1: probe only: records Rex's Mystery Box lists and the Ray Gun, Ray Gun Mark II and
// Necrofluid Gauntlet lists in the arena (ra_box_probe); the box itself is unchanged.
// 1.1: wonder weapons in the arena box: Rex's wonder swap off, so its wonder tier rolls Ray Gun,
// Ray Gun Mark II and Rex's wonder weapon; the Necrofluid Gauntlet on 1 in 4 of those (ra_box_wonder).
// 1.1.1: records only: what each arena box spin gives (Ray Gun, Ray Gun Mark II, Rex's own wonder
// weapon, Necrofluid Gauntlet, another wonder weapon or a normal one) as box_seen (ra_box_seen_*).
// 1.1.2: test switches: launch_off_<part> = 1 in the launch file skips that part of the arena for
// one match (ra_launch_off), to find what stops the game's effects. Without it nothing changes.
// 1.1.3: the big toys' purple glow only while a player is near their pedestal (ra_toy_glow_near):
// 166 glows on from the start left the game no room for its own effects.
// 1.1.4: audit fixes: a player who leaves keeps no toy glows; each Weyward crystal's own move note;
// the Warden reward place without a player; an unused function and four unused fields removed.
// 1.1.5: Wonderbar in the arena box: the Warden Blight on about 1 spin in 2 (was about 1 in 4), with the
// box's own reroll; the wonder roll hook asks first (ra_box_wonder_pick), Wonderbar spins in box_seen.
// 1.1.6: Wonderbar gives no second Warden Blight to a player already holding one (the box rerolls it).
// 1.1.7: 5,000 salvage to every player for each boss beaten (ra_boss_salvage, the game's currency call).
// 1.1.8: beaten bosses' bodies are hidden when a round-select pedestal is used (ra_boss_corpse_*).
// 1.1.9: Caltheris takes half of a weapon's phase-1 damage in phase 2 and a quarter in phase 3 (was all of it).
// 1.2.0: beaten bosses' bodies are deleted at a pedestal pick (hide() left them; ra_boss_corpse_delete).
// 1.2.1: audit: the boss body code out (1.2.0 runtime: the body entity has no model; the delete left the
// body in view); Caltheris's later-phase share for a weapon first used after phase 1; the box_walk and
// box_probe records out; box_wonder_swap's round before the first round.
// Locals are kept in fields; the compiler's local assignments are unsafe.
#using scripts\common\callbacks;
#using scripts\common\utility;
#using script_692b19b8e5f8f9e8;
#using script_7b92812967b04687;
#using script_c1369b1abe9a0d1;
#using script_4c770a9a4ad7659c;
#using script_68b97d9e79132ec0;
#using script_663ff1906e9fe70;
#using script_3b64eb40368c1450;
#using script_6853191397ec0259;
#using script_4f9ce8d249a99f4a;
#using script_4fca32f463c5e4fa;
#using script_35ea2ad71d73089b;
#using script_2bf5529af94c9a0;
#using script_7b1e082b2533e255;
#using script_4e3b2b1d9542e66b;
#using script_1edc39044588162b;
#using script_1eaed13c599e2b34;
#using script_3ca070ee1ba8337c;
#using script_7129baf8ee832ed2;
#using script_6c2f6a14fa53759e;
#using script_66cb9fe5d1bbff6;
#using script_27623f7ac600060c;
#using script_162f01e3286930e2;
#using script_4ccf8f7e270f2426;
#using script_292c039f763f4b94;
#using script_789c50e394f0bf40;
#using script_44cd18225e55c2ac;
#using script_4478f81b31480314;
#using script_427ce33ec0c820cf;
#using script_7df061afe12b8318;
#using script_315d0ecfeb067b1c;
#using script_52a6d55588cb0819;
#using script_657e27b4628aaf50;
#using script_1e43bd77ad5dde8c;
#using script_77dca3b46e01eb1e;
// 1.1.5: Wonderbar's box hook (namespace_72c943209a0510e6), asked by ra_box_wonder_pick
#using script_1227bdf0f2eaf735;
// 1.1.7: the game's currency (namespace_189fe7075a0930a5), for ra_boss_salvage
#using script_3a9d7a7cfee99885;

autoexec ra_register()
{
    if ( !ra_selected() )
        return;

    ra_read_launch();
    nengine_store_set( "rex_arena", "version", "1.2.1" );
    nengine_store_set( "rex_arena", "host", "zm_sat_scarab" );
    nengine_store_set( "rex_arena", "poi", "zone_boss_arena_ff" );
    nengine_store_set( "rex_arena", "status", "registered" );
    nengine_store_set( "rex_arena", "mapname", getdvar( "mapname", "unknown" ) );
    nengine_store_set( "rex_arena", "ui_mapname", getdvar( "ui_mapname", "unknown" ) );
    nengine_store_set( "rex_arena", "spawn_points", 0 );
    nengine_store_set( "rex_arena", "zone_enabled", 0 );
    nengine_store_set( "rex_arena", "spawn_calls", 0 );
    nengine_store_set( "rex_arena", "players_moved", 0 );
    nengine_store_set( "rex_arena", "prepare_frames", -1 );
    nengine_store_set( "rex_arena", "wunderfizz", "not_started" );
    nengine_store_set( "rex_arena", "box", "not_started" );
    nengine_store_set( "rex_arena", "rampage", "not_started" );
    nengine_store_set( "rex_arena", "tedd", "waiting" );
    nengine_store_set( "rex_arena", "tedd_boss", "none" );
    nengine_store_set( "rex_arena", "tedd_boss_offs", 0 );
    nengine_store_set( "rex_arena", "tedd_boss_task", "none" );
    nengine_store_set( "rex_arena", "exfil", "not_started" );
    nengine_store_set( "rex_arena", "gobblegum", "not_started" );
    nengine_store_set( "rex_arena", "ammo_cost", "waiting" );
    nengine_store_set( "rex_arena", "no_super_sprint", "waiting" );
    nengine_store_set( "rex_arena", "drop", "not_started" );
    if ( ra_launch_off( "arena" ) )
    {
        nengine_store_set( "rex_arena", "status", "arena_off_by_launch_file" );
        ra_mark( "arena_off" );
        return;
    }
    level.ra_spawn_calls = 0;
    level.ra_players_moved = 0;
    level.ra_ready = 0;
    ra_mark( "registered" );
    level callback::add( #"player_spawned", &ra_spawned );
    // player damage event: cancels fall damage during the drop only
    level callback::add( #"hash_652eb614ba902b3d", &ra_on_damaged );
    if ( !ra_launch_off( "prepare" ) )
        level thread ra_prepare();
    if ( !ra_launch_off( "wunder" ) )
        level thread rx_wunder_early();
    if ( !ra_launch_off( "sprint" ) )
        level thread rx_no_super_sprint();
    if ( !ra_launch_off( "ammo_cost" ) )
        level thread rx_half_ammo_cost();
    if ( !ra_launch_off( "machines" ) )
        level thread rx_user_machines();
    if ( !ra_launch_off( "gobblegum" ) )
        level thread rx_gobblegum_manager();
    if ( !ra_launch_off( "exfil" ) )
        level thread rx_exfil_manager();
    if ( !ra_launch_off( "minimap" ) )
        level thread ra_hide_minimap();
    if ( !ra_launch_off( "warden_fade" ) )
        level thread ra_warden_fade_watch();
    if ( !ra_launch_off( "exfil_boss" ) )
        level thread ra_exfil_boss_watch();
}

function ra_selected()
{
    return getdvar( @"hash_dddf7dca1a52e591", "null" ) == "zone_boss_arena_ff" &&
        ( getdvar( "mapname" ) == "zm_sat_scarab" || getdvar( "ui_mapname" ) == "zm_sat_scarab" );
}

// The launch file: store "rex_arena", name "launch" (kronos/rex_arena/launch.json).
// It is read before anything is written to the store. Each switch counts only
// when it is the number 1; without the file every switch is off.
function ra_read_launch()
{
    level.ra_no_gun_lower = 0;
    level.ra_no_rig = 0;
    level.ra_no_states = 0;
    level.ra_no_drop = 0;
    level.ra_zrex_round = 50;
    level.ra_guardian_round = 75;
    // 0.5.81: swapped (user: "make caltheris round 100 and z rex and the
    // guardian round 255")
    level.ra_both_round = 255;
    level.ra_caltheris_round = 100;
    level.ra_trio_round = 500;
    level.ra_quad_round = 999;
    level.ra_launch_file = "no_file";
    if ( nengine_store_load( "rex_arena", "launch" ) )
    {
        level.ra_launch_file = "read";
        level.ra_flag = nengine_store_get( "rex_arena", "launch_no_gun_lower" );
        if ( isdefined( level.ra_flag ) && level.ra_flag == 1 )
            level.ra_no_gun_lower = 1;
        level.ra_flag = nengine_store_get( "rex_arena", "launch_no_rig" );
        if ( isdefined( level.ra_flag ) && level.ra_flag == 1 )
            level.ra_no_rig = 1;
        level.ra_flag = nengine_store_get( "rex_arena", "launch_no_states" );
        if ( isdefined( level.ra_flag ) && level.ra_flag == 1 )
            level.ra_no_states = 1;
        level.ra_flag = nengine_store_get( "rex_arena", "launch_no_drop" );
        if ( isdefined( level.ra_flag ) && level.ra_flag == 1 )
            level.ra_no_drop = 1;
        // test only: other rounds for the two bosses
        level.ra_flag = nengine_store_get( "rex_arena", "launch_zrex_round" );
        if ( isdefined( level.ra_flag ) && level.ra_flag >= 1 )
            level.ra_zrex_round = level.ra_flag;
        level.ra_flag = nengine_store_get( "rex_arena", "launch_guardian_round" );
        if ( isdefined( level.ra_flag ) && level.ra_flag >= 1 )
            level.ra_guardian_round = level.ra_flag;
        level.ra_flag = nengine_store_get( "rex_arena", "launch_both_round" );
        if ( isdefined( level.ra_flag ) && level.ra_flag >= 1 )
            level.ra_both_round = level.ra_flag;
        level.ra_flag = nengine_store_get( "rex_arena", "launch_caltheris_round" );
        if ( isdefined( level.ra_flag ) && level.ra_flag >= 1 )
            level.ra_caltheris_round = level.ra_flag;
        level.ra_flag = nengine_store_get( "rex_arena", "launch_trio_round" );
        if ( isdefined( level.ra_flag ) && level.ra_flag >= 1 )
            level.ra_trio_round = level.ra_flag;
        level.ra_flag = nengine_store_get( "rex_arena", "launch_quad_round" );
        if ( isdefined( level.ra_flag ) && level.ra_flag >= 1 )
            level.ra_quad_round = level.ra_flag;
    }
    nengine_store_set( "rex_arena", "launch_file", level.ra_launch_file );
    nengine_store_set( "rex_arena", "use_no_gun_lower", level.ra_no_gun_lower );
    nengine_store_set( "rex_arena", "use_no_rig", level.ra_no_rig );
    nengine_store_set( "rex_arena", "use_no_states", level.ra_no_states );
    nengine_store_set( "rex_arena", "use_no_drop", level.ra_no_drop );
    ra_launch_off_read();
    nengine_store_set( "rex_arena", "use_off", level.ra_off_text == "" ? "none" : level.ra_off_text );
}

// Server time (ms) of a set-up step, as t_<step>. Drop steps use ra_tyr_mark.
function ra_mark( step )
{
    nengine_store_set( "rex_arena", "step", step );
    nengine_store_set( "rex_arena", "t_" + step, function_83bf4b34fbbe124b() );
    nengine_store_save( "rex_arena", "runtime" );
}

// Wait for the struct table and the zone manager, then take the arena's four
// player points and enable its zone (both are Rex's own authored data).
function ra_prepare()
{
    level endon( #"game_ended" );
    level.ra_attempt = 0;
    while ( level.ra_attempt < 1200 )
    {
        if ( isdefined( level.var_7619345e0810ba9b ) && isdefined( level.var_63a203e154ffeca0 ) )
        {
            level.ra_points = namespace_60b3bdcc70f79fc6::function_4129ebc30c6186ec(
                "pf294294144351bd04_auto486321445777227930", "targetname" );
            if ( isdefined( level.ra_points ) && level.ra_points.size >= 4 &&
                 isdefined( namespace_63a203e154ffeca0::get_zone_struct( "zone_boss_arena_ff" ) ) )
            {
                namespace_63a203e154ffeca0::set_zone_enabled( "zone_boss_arena_ff", 1 );
                level.ra_ready = 1;
                nengine_store_set( "rex_arena", "spawn_points", level.ra_points.size );
                nengine_store_set( "rex_arena", "spawn_point_0", level.ra_points[ 0 ].origin );
                nengine_store_set( "rex_arena", "prepare_frames", level.ra_attempt );
                nengine_store_set( "rex_arena", "zone_enabled", 1 );
                nengine_store_set( "rex_arena", "status", "arena_prepared" );
                ra_mark( "arena_prepared" );
                return;
            }
        }
        level.ra_attempt++;
        waitframe();
    }
    nengine_store_set( "rex_arena", "status", "arena_markers_or_zone_missing" );
    ra_mark( "prepare_failed" );
}

function ra_spawned( params )
{
    if ( !ra_selected() )
        return;
    level.ra_spawn_calls++;
    nengine_store_set( "rex_arena", "spawn_calls", level.ra_spawn_calls );
    nengine_store_set( "rex_arena", "last_spawn_slot", self getentitynumber() );
    if ( isdefined( self.origin ) )
        nengine_store_set( "rex_arena", "spawn_origin", self.origin );
    nengine_store_set( "rex_arena", "status", "player_spawned" );
    ra_mark( "spawned" );
    self thread ra_drop_in();
    self thread ra_guardian_bar_later();
    if ( !isdefined( level.ra_services_started ) )
    {
        level.ra_services_started = 1;
        if ( !ra_launch_off( "specials" ) )
            level thread ra_specials_manager();
    }
}

// 0.1.3's move: stream the arena first, then place the player on one of its
// four points. Returns 0 if the arena was never prepared.
// 0.5.58: 5 s of streaming before the move (was 2) and 3 s after it (was 2), as
// Rex's own long teleports wait (script_5607e84827a261c7: 5 s); the start
// crashes +85f49b came within 2 s of the 2 s move.
function ra_move_to_arena()
{
    self.ra_wait = 0;
    while ( !level.ra_ready && self.ra_wait < 1200 )
    {
        self.ra_wait++;
        waitframe();
    }
    if ( !level.ra_ready )
    {
        nengine_store_set( "rex_arena", "status", "move_skipped_arena_not_ready" );
        ra_mark( "move_skipped" );
        return 0;
    }
    self.ra_slot = self getentitynumber() % 4;
    self.ra_point = level.ra_points[ self.ra_slot ];
    nengine_store_set( "rex_arena", "target_origin", self.ra_point.origin );
    nengine_store_set( "rex_arena", "status", "stream_requested" );
    ra_mark( "stream_requested" );
    self setadditionalstreamposuntilcleared( self.ra_point.origin, 3 );
    wait 5;
    self dontinterpolate();
    self setorigin( self.ra_point.origin );
    self setplayerangles( self.ra_point.angles );
    nengine_store_set( "rex_arena", "immediate_origin", self.origin );
    ra_mark( "moved" );
    wait 3;
    self clearadditionalstreampos();
    level.ra_players_moved++;
    nengine_store_set( "rex_arena", "players_moved", level.ra_players_moved );
    nengine_store_set( "rex_arena", "last_player_origin", self.origin );
    nengine_store_set( "rex_arena", "status", "player_in_arena" );
    ra_mark( "stream_cleared" );
    return 1;
}

// The drop-in: Totenreich's own exit from Tyr (zm_sat_locust
// script_373c7d5ffe473753, namespace_e34b8c1692e43f7d), as Ashes Arena 0.4.43
// runs it. Under a white screen the player is moved into the arena, the
// native game-start signal is awaited and the player must be standing in the
// arena. Then: the end of the Tyr stay (fade to white, prepare, wait 1), a
// jump to 3000 units above the landing point, a three second ride down on a
// mover with the first-person rig, fade to black, the landing shake and
// shockwave, and a fade back in. The player never free-falls. The landing
// point is the arena floor under the cap: Ashes (46525, -375, -45) moved to
// Rex. If any step before the ride fails the player simply stays in the arena.
function ra_drop_in()
{
    self endon( #"death" );
    self endon( #"disconnect" );
    level endon( #"game_ended" );
    // A respawn can interrupt the previous landing's safety timer.
    self ra_tyr_clear_black( "restart" );
    namespace_214d79f87f4bf971::function_9a5ee51116044765( #"hash_46ccd37542b93aee" );
    self notify( #"ra_drop_restart" );
    self endon( #"ra_drop_restart" );
    self endon( #"ra_tyr_abort" );
    self.ra_dropping = 0;
    nengine_store_set( "rex_arena", "land_monitor", "waiting_for_landing" );
    nengine_store_set( "rex_arena", "drop", "moving_to_arena" );
    nengine_store_set( "rex_arena", "drop_start_signal", "waiting" );
    nengine_store_set( "rex_arena", "drop_start_ticks", 0 );
    nengine_store_save( "rex_arena", "runtime" );
    if ( !level.ra_no_drop )
        self ra_entry_veil_start();
    if ( !self ra_move_to_arena() )
    {
        self ra_entry_veil_clear( "arena_not_ready" );
        nengine_store_set( "rex_arena", "drop", "arena_not_ready" );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    if ( level.ra_no_drop )
    {
        nengine_store_set( "rex_arena", "drop", "skipped_by_launch_file" );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    nengine_store_set( "rex_arena", "drop", "waiting_for_game_start" );
    nengine_store_save( "rex_arena", "runtime" );
    self ra_drop_wait_native_start();
    if ( !self ra_drop_wait_settled() )
    {
        self ra_entry_veil_clear( "settle_timeout" );
        nengine_store_set( "rex_arena", "drop", "spawn_not_settled" );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    if ( !isdefined( level.ra_drop_n ) )
        level.ra_drop_n = 0;
    // up to four players side by side under the cap
    self.ra_drop_slot = level.ra_drop_n % 4;
    level.ra_drop_n++;
    self.ra_tyr_dest = ( 29429, -27447, 2203 ) + ( self.ra_drop_slot % 2 * 96 - 48, self.ra_drop_slot >= 2 ? 48 : -48, 0 );
    // Totenreich's landing structs give the height (3000) and the facing.
    self.ra_tyr_height = 3000;
    self.ra_tyr_angles = ( 0, self getplayerangles()[ 1 ], 0 );
    self.ra_tyr_original_weapon = undefined;
    self.ra_tyr_rig_released = 0;
    self.ra_dropping = 1;
    nengine_store_set( "rex_arena", "drop", "tyr_exit_started" );
    nengine_store_set( "rex_arena", "drop_step", "starting" );
    nengine_store_set( "rex_arena", "drop_weapon", "not_started" );
    nengine_store_set( "rex_arena", "drop_weapon_restore", "not_started" );
    nengine_store_set( "rex_arena", "drop_weapon_saved", "not_checked" );
    nengine_store_set( "rex_arena", "drop_weapon_selection", "not_checked" );
    nengine_store_set( "rex_arena", "drop_mid_viewmodel_anim", "not_recorded" );
    nengine_store_set( "rex_arena", "drop_recover", "not_needed" );
    nengine_store_set( "rex_arena", "drop_placed_actual", "not_recorded" );
    nengine_store_set( "rex_arena", "drop_mid_player", "not_recorded" );
    nengine_store_set( "rex_arena", "drop_mid_mover", "not_recorded" );
    nengine_store_set( "rex_arena", "drop_mid_rig_present", "not_recorded" );
    nengine_store_set( "rex_arena", "drop_end_player", "not_recorded" );
    nengine_store_set( "rex_arena", "drop_end_mover", "not_recorded" );
    nengine_store_set( "rex_arena", "drop_fallback", "not_needed" );
    nengine_store_set( "rex_arena", "drop_fallback_origin", "not_recorded" );
    nengine_store_set( "rex_arena", "drop_white_fade", "not_checked" );
    nengine_store_set( "rex_arena", "drop_white_alpha", "not_recorded" );
    nengine_store_set( "rex_arena", "drop_black_fade", "not_started" );
    nengine_store_set( "rex_arena", "drop_black_alpha_before", "not_recorded" );
    nengine_store_set( "rex_arena", "drop_anim_worker", "not_started" );
    nengine_store_set( "rex_arena", "drop_mid_anim_threads", "not_recorded" );
    nengine_store_set( "rex_arena", "drop_mid_rig_shown", "not_recorded" );
    nengine_store_set( "rex_arena", "drop_rig_worker", "not_started" );
    nengine_store_set( "rex_arena", "drop_rig_handoff_before", "not_recorded" );
    nengine_store_set( "rex_arena", "drop_rig_handoff_after_native", "not_recorded" );
    nengine_store_set( "rex_arena", "drop_rig_handoff_after_unlink", "not_recorded" );
    nengine_store_set( "rex_arena", "drop_rig_release", "not_started" );
    nengine_store_set( "rex_arena", "drop_anim_tree_registered", isdefined( level.var_dc93f7e52123aeea[ "ra_tyr_player" ] ) ? 1 : 0 );
    nengine_store_set( "rex_arena", "drop_anim_view_registered", isdefined( level.var_fcd9208987c2f338[ "ra_tyr_player" ][ "player_sucked_in" ][ 0 ] ) ? 1 : 0 );
    nengine_store_set( "rex_arena", "drop_anim_rig_registered", isdefined( level.var_c64390d83bf618a6[ "ra_tyr_player" ][ "player_sucked_in" ][ 0 ] ) ? 1 : 0 );
    nengine_store_set( "rex_arena", "drop_fx", isdefined( level.var_d1e5f36ab9f106 ) && isdefined( level.var_d1e5f36ab9f106[ "begin_eject_down" ] ) ? 1 : 0 );
    nengine_store_set( "rex_arena", "drop_origin", self.ra_tyr_dest + ( 0, 0, self.ra_tyr_height ) );
    nengine_store_save( "rex_arena", "runtime" );
    self thread ra_tyr_watchdog();
    // The drop watchdog now owns fade recovery. Leave the white HUD element in
    // place for the native transition rather than clearing it.
    self ra_entry_veil_handoff();
    // function_282a6b6d6476db81, Tyr branch: function_db4902451e1e6733, then
    // function_6b4a863987e3a49 and function_5e6fbf9ef5db2557.
    self ra_tyr_stay_end();
    nengine_store_set( "rex_arena", "drop", "tyr_exit_falling" );
    nengine_store_save( "rex_arena", "runtime" );
    self ra_tyr_place( self.ra_tyr_dest + ( 0, 0, self.ra_tyr_height ), function_f20800b12e131138( self.ra_tyr_dest - self.origin ) );
    nengine_store_set( "rex_arena", "drop_placed_actual", self.origin );
    self ra_tyr_mark( "placed_above" );
    self ra_tyr_exit( self.ra_tyr_dest, self.ra_tyr_height, self.ra_tyr_angles );
    self.ra_dropping = 0;
    level.ra_land_t = function_83bf4b34fbbe124b();
    nengine_store_set( "rex_arena", "land_health", self.health );
    nengine_store_set( "rex_arena", "land_eye_height", self function_5255d85caf38b6eb()[ 2 ] - self.origin[ 2 ] );
    nengine_store_set( "rex_arena", "land_spawn_call", level.ra_spawn_calls );
    self thread ra_death_record();
    nengine_store_set( "rex_arena", "drop", "sequence_complete" );
    nengine_store_set( "rex_arena", "drop_landing", self.origin );
    nengine_store_save( "rex_arena", "runtime" );
    self thread ra_land_monitor();
}

// A white screen covers the move into the arena and the wait for the native
// start. Timeout and death clear this HUD element directly.
function ra_entry_veil_start()
{
    self.ra_entry_veil_active = 1;
    self thread ra_entry_veil_timeout();
    self thread ra_entry_veil_death();
    namespace_6b3344dd849818f8::function_a171f7756afa97bb( 0, "white" );
    nengine_store_set( "rex_arena", "drop_entry_veil", "active" );
    nengine_store_save( "rex_arena", "runtime" );
}

function ra_entry_veil_timeout()
{
    self endon( #"disconnect" );
    self endon( #"ra_drop_restart" );
    self endon( #"ra_entry_veil_cancel" );
    wait 25;
    if ( isdefined( self.ra_entry_veil_active ) && self.ra_entry_veil_active )
        self ra_entry_veil_clear( "safety_timeout" );
}

function ra_entry_veil_death()
{
    self endon( #"disconnect" );
    self endon( #"ra_drop_restart" );
    self endon( #"ra_entry_veil_cancel" );
    self waittill( #"death" );
    if ( isdefined( self.ra_entry_veil_active ) && self.ra_entry_veil_active )
        self ra_entry_veil_clear( "death" );
}

function ra_entry_veil_clear( reason )
{
    if ( isdefined( self.ra_entry_veil_active ) && self.ra_entry_veil_active )
    {
        self.ra_entry_veil_active = 0;
        if ( isdefined( self.var_fd24d570aa69fd56 ) &&
             isdefined( self.var_fd24d570aa69fd56[ "white" ] ) )
        {
            self.ra_entry_white = self.var_fd24d570aa69fd56[ "white" ];
            self.ra_entry_white fadeovertime( 0.1 );
            self.ra_entry_white.alpha = 0;
        }
        nengine_store_set( "rex_arena", "drop_entry_veil", reason );
        nengine_store_save( "rex_arena", "runtime" );
    }
    self notify( #"ra_entry_veil_cancel" );
}

function ra_entry_veil_handoff()
{
    if ( isdefined( self.ra_entry_veil_active ) && self.ra_entry_veil_active )
    {
        self.ra_entry_veil_active = 0;
        nengine_store_set( "rex_arena", "drop_entry_veil", "handed_to_drop" );
        nengine_store_save( "rex_arena", "runtime" );
    }
    self notify( #"ra_entry_veil_cancel" );
}

// The native Zombies round start sets this flag after a player has spawned and
// after its own start gate. It is a game-side signal, not proof that the
// client's loading screen has gone. If it has not come after 20 s the drop
// goes ahead (Ashes Arena waited 90 s and then skipped the drop).
function ra_drop_wait_native_start()
{
    self.ra_start_wait = 0;
    while ( !level namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( "begin_round_logic" ) && self.ra_start_wait < 200 )
    {
        wait 0.1;
        self.ra_start_wait++;
    }
    nengine_store_set( "rex_arena", "drop_start_ticks", self.ra_start_wait );
    if ( !level namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( "begin_round_logic" ) )
    {
        nengine_store_set( "rex_arena", "drop_start_signal", "timed_out_continuing" );
        nengine_store_save( "rex_arena", "runtime" );
        return 1;
    }
    nengine_store_set( "rex_arena", "drop_start_signal", "ready" );
    nengine_store_save( "rex_arena", "runtime" );
    // The move into the arena has already taken four seconds. Wait two more
    // only if the signal came later than that.
    if ( self.ra_start_wait > 0 )
        wait 2;
    return 1;
}

// True once the player has been inside the arena, not moving sideways, for
// half a second (Ashes Arena's bounds moved to Rex).
function ra_drop_wait_settled()
{
    self.ra_settle = 0;
    self.ra_settle_wait = 0;
    self.ra_prev = self.origin;
    while ( self.ra_settle < 10 && self.ra_settle_wait < 600 )
    {
        wait 0.05;
        self.ra_settle_wait++;
        self.ra_step = self.origin - self.ra_prev;
        self.ra_prev = self.origin;
        if ( self.origin[ 0 ] > 27304 && self.origin[ 0 ] < 31904 &&
             self.origin[ 1 ] > -30272 && self.origin[ 1 ] < -24872 &&
             self.origin[ 2 ] < 2648 &&
             self.ra_step[ 0 ] * self.ra_step[ 0 ] + self.ra_step[ 1 ] * self.ra_step[ 1 ] < 400 )
            self.ra_settle++;
        else
            self.ra_settle = 0;
    }
    return self.ra_settle >= 10;
}

// Records the first eight damage events and cancels fall damage while the
// player is dropping: the ride releases them 32 units above the floor.
function ra_on_damaged( params )
{
    // Record only: what damaged the player, how much and when.
    if ( isdefined( self ) && isdefined( params ) )
    {
        if ( !isdefined( level.ra_dmg_n ) )
            level.ra_dmg_n = 0;
        level.ra_dmg_n++;
        nengine_store_set( "rex_arena", "dmg_count", level.ra_dmg_n );
        if ( level.ra_dmg_n <= 8 )
        {
            nengine_store_set( "rex_arena", "dmg_" + level.ra_dmg_n + "_means", isdefined( params.var_f5a880abf0b199dc ) ? params.var_f5a880abf0b199dc : "undefined" );
            nengine_store_set( "rex_arena", "dmg_" + level.ra_dmg_n + "_amount", isdefined( params.var_a87b62c261a8d114 ) ? params.var_a87b62c261a8d114 : "undefined" );
            nengine_store_set( "rex_arena", "dmg_" + level.ra_dmg_n + "_dropping", isdefined( self.ra_dropping ) ? self.ra_dropping : "undefined" );
            nengine_store_set( "rex_arena", "dmg_" + level.ra_dmg_n + "_ms_after_landing", isdefined( level.ra_land_t ) ? function_83bf4b34fbbe124b() - level.ra_land_t : "before_landing" );
            nengine_store_set( "rex_arena", "dmg_" + level.ra_dmg_n + "_health_before", self.health );
            nengine_store_save( "rex_arena", "runtime" );
        }
    }
    if ( !isdefined( self ) || !isdefined( self.ra_dropping ) || self.ra_dropping != 1 )
        return;
    if ( !isdefined( params ) || !isdefined( params.var_f5a880abf0b199dc ) )
        return;
    if ( params.var_f5a880abf0b199dc == "MOD_FALLING" )
        params.var_a87b62c261a8d114 = 0;
}


// Tyr's two effects. 0.7.3: Rex's animation tree and its two clips are
// registered under "ra_tyr_player" by zm_rex_arena_tyr, which Kronos links on
// Rex only; naming the tree here crashed every other map while loading.
autoexec ra_tyr_preload()
{
    if ( !ra_selected() )
        return;
    nengine_store_set( "rex_arena", "fx_preload_tyr", ra_launch_off( "fx_preload" ) ? "skipped" : "loaded" );
    if ( ra_launch_off( "fx_preload" ) )
        return;
    namespace_60b3bdcc70f79fc6::function_2825fe58920e70c4( "begin_eject_up", "vfx_sat_levels_zm_locust_tube_teleport_in_screen" );
    namespace_60b3bdcc70f79fc6::function_2825fe58920e70c4( "begin_eject_down", "vfx_sat_levels_zm_locust_tube_teleport_out_screen" );
}

// function_db4902451e1e6733 after the Tyr stay: fade to white over 0.5 s,
// prepare (function_49271b9f192f91af( 1 )), wait 1.
function ra_tyr_stay_end()
{
    self endon( #"hash_20666ddcfb99d876" );
    namespace_6b3344dd849818f8::function_a171f7756afa97bb( 0.5, "white" );
    self ra_tyr_mark( "faded_white" );
    self ra_tyr_prepare();
    self ra_tyr_mark( "prepared" );
    wait 1;
}

// function_49271b9f192f91af. The player's weapon is kept; the native
// empty-hands switch is not used.
function ra_tyr_prepare()
{
    self endon( #"hash_20666ddcfb99d876" );
    // Keep the original weapon selected. The experimental empty-hands swap
    // could leave the player without a gun or stuck after the landing.
    self.ra_tyr_original_weapon = self getcurrentweapon();
    if ( !isweapon( self.ra_tyr_original_weapon ) || !self hasweapon( self.ra_tyr_original_weapon ) )
        self.ra_tyr_original_weapon = undefined;
    nengine_store_set( "rex_arena", "drop_weapon_saved", isdefined( self.ra_tyr_original_weapon ) ? "available" : "unavailable" );
    // This native function only returns the name; it does not give or switch
    // the weapon. Retain the name for investigation of the missing hands.
    nengine_store_set( "rex_arena", "drop_tyr_hands_weapon", namespace_6dcadaff87c6f389::function_17bee3f2e45888ee() );
    self ra_tyr_mark( "leave_states" );
    self ra_tyr_leave_states();
    self ra_tyr_mark( "hold" );
    if ( !level.ra_no_states )
        self thread ra_tyr_hold();
    self ra_tyr_mark( "end_slide" );
    self ra_tyr_end_slide();
    self ra_tyr_mark( "stop_actions" );
    self ra_tyr_stop_actions();
    self ra_tyr_mark( "weapon_preserved" );
    nengine_store_set( "rex_arena", "drop_weapon", "original_preserved" );
    nengine_store_save( "rex_arena", "runtime" );
    self ra_tyr_mark( "set_states" );
    self ra_tyr_set_states();
    nengine_store_set( "rex_arena", "drop_weapon_gate_after", namespace_214d79f87f4bf971::function_e5c588558239ba2a( "weapon" ) ? 1 : 0 );
    nengine_store_save( "rex_arena", "runtime" );
}

// function_6ed8e1f2e1ad9b47
function ra_tyr_leave_states()
{
    if ( self function_6e6a47d4e0ca4576() )
    {
        self function_9299511877ac7219();
        waitframe();
    }
    if ( self function_9db2be0340618948() )
    {
        self function_7f34c7d08e1fa766();
        waitframe();
    }
    if ( self function_adfcc0cba9237acf() )
    {
        namespace_214d79f87f4bf971::function_b2fc2925c70ceb16( #"hash_46ccd37542b93aee", "ladder", 0 );
        waitframe();
    }
    if ( self function_b120fdd6ffcf8f36() )
    {
        self function_ec3f14e333085dbf();
        waitframe();
    }
}

// function_56db6f6859124c85
function ra_tyr_end_slide()
{
    if ( !namespace_74b2d1dbce2fe39a::function_9b18c35fba5c3d31() )
        return;
    namespace_e68fe57307286f8a::function_c99db6d48678cf82();
}

// function_9a39ca3ca367363c
function ra_tyr_stop_actions()
{
    self function_6f6a2d52e0827735();
    self function_ae82c1262eae3c69();
    self function_bfaaf9b43819d218();
    self function_85b88200235683a1();
    namespace_fdf8d5ba42f3069b::function_a4992d4db94905d3();
    self notify( #"hash_7899a098eb572922" );
    if ( self function_8994c58a19529431() )
        self function_449cea91173bedd9();
}

// function_a486f2148a06ab16, all seven overrides.
function ra_tyr_set_states()
{
    if ( level.ra_no_states )
        return;
    // The first override lowers the gun, so only the rig's hands show. It is
    // lifted with the rest of this state group by the landing cleanup, the
    // watchdog and a restart.
    if ( !level.ra_no_gun_lower )
        namespace_214d79f87f4bf971::function_b2fc2925c70ceb16( #"hash_46ccd37542b93aee", "weapon", 0 );
    namespace_214d79f87f4bf971::function_b2fc2925c70ceb16( #"hash_46ccd37542b93aee", "freezecontrols", 1 );
    namespace_214d79f87f4bf971::function_b2fc2925c70ceb16( #"hash_46ccd37542b93aee", "ignore_playable_area_check", 1 );
    namespace_214d79f87f4bf971::function_b2fc2925c70ceb16( #"hash_46ccd37542b93aee", "ignoreme", 1 );
    namespace_214d79f87f4bf971::function_b2fc2925c70ceb16( #"hash_46ccd37542b93aee", "show_hud", 0 );
    namespace_214d79f87f4bf971::function_b2fc2925c70ceb16( #"hash_46ccd37542b93aee", "crouch", 0 );
    namespace_214d79f87f4bf971::function_b2fc2925c70ceb16( #"hash_46ccd37542b93aee", "prone", 0 );
}

// function_785193c243415d9f
function ra_tyr_hold()
{
    namespace_a9d0968f08f885b0::function_99d180c3f0ca93b8( self, "disabled", 0, 1 );
    if ( self function_edc98fa7c1061e87() )
    {
        self notify( #"hash_4615bc0f573377ee" );
        self.var_80b47a6852268227 = 1;
        waitframe();
    }
    self.var_4014e1a4c4df8dd9 = 1;
}

// function_c52f914088fc2a7f (via function_6b4a863987e3a49)
function ra_tyr_place( origin, angles )
{
    self function_2eb2bd79484faf45( ( 0, 0, 0 ) );
    self function_325a34972c399274();
    self function_a544338816001600( origin );
    self function_29137e613a12a41f( angles );
    self function_f11bddebbb9d709a( "stand", 1, 1, 1 );
}

// function_5e6fbf9ef5db2557( dest, height, angles, 0 )
function ra_tyr_exit( dest, height, angles )
{
    self endon( #"hash_20666ddcfb99d876" );
    // Build the mover at the intended starting point even if another spawn
    // system has moved the player back to the floor after placement.
    self.ra_tyr_start = dest + ( 0, 0, height );
    self.ra_tyr_yaw = function_f20800b12e131138( dest - self.ra_tyr_start ) + angles;
    self.ra_tyr_mover = namespace_60b3bdcc70f79fc6::function_f25f36ab408fc9c5( self.ra_tyr_start, self.ra_tyr_yaw );
    self ra_tyr_mark( "mover" );
    // 0.7.3: without zm_rex_arena_tyr's tree the drop keeps the mover link
    if ( !level.ra_no_rig && !isdefined( level.var_dc93f7e52123aeea[ "ra_tyr_player" ] ) )
    {
        level.ra_no_rig = 1;
        nengine_store_set( "rex_arena", "drop_tree", "not registered (zm_rex_arena_tyr not linked), no rig" );
    }
    if ( level.ra_no_rig )
    {
        // No first-person rig: the player rides the mover itself with their gun
        // in hand, by the same link the mid-ride fallback makes.
        self.ra_tyr_scene = spawnstruct();
        self function_a544338816001600( self.ra_tyr_mover.origin );
        self playerlinkto( self.ra_tyr_mover );
        nengine_store_set( "rex_arena", "drop_fallback", "no_rig_linked_to_mover" );
        self ra_tyr_mark( "mover_link" );
    }
    else
    {
        self ra_tyr_rig( self.ra_tyr_mover.origin, self.ra_tyr_mover.angles );
        self ra_tyr_mark( "rig" );
    }
    if ( isdefined( level.var_d1e5f36ab9f106 ) && isdefined( level.var_d1e5f36ab9f106[ "begin_eject_down" ] ) )
        function_3adbfd465808121c( namespace_60b3bdcc70f79fc6::function_f75ad975062ad954( "begin_eject_down" ), self, "j_head", self );
    self ra_tyr_ride( self.ra_tyr_scene, height * -1, angles, 3, 0.35 );
    if ( isdefined( level.var_d1e5f36ab9f106 ) && isdefined( level.var_d1e5f36ab9f106[ "begin_eject_down" ] ) )
        function_d93af2c64c4e6136( namespace_60b3bdcc70f79fc6::function_f75ad975062ad954( "begin_eject_down" ), self, "j_head", self );
}

// function_9b26b9212e8a24b: the first-person rig, linked to the mover.
function ra_tyr_rig( origin, angles )
{
    self.ra_tyr_scene = namespace_16b0eb576933808c::function_a5935b3469b17bc3( self, "ra_tyr_player", 1, 0 );
    self.ra_tyr_scene.angles = angles;
    self.ra_tyr_scene.var_76b413f28e3a2ed6 = function_8cb79298089e518d( "script_arms", origin, 0, 0, self );
    self.ra_tyr_scene.var_76b413f28e3a2ed6.angles = angles;
    self.ra_tyr_scene.var_76b413f28e3a2ed6.var_19bdb7d2e4226508 = self.ra_tyr_scene.var_19bdb7d2e4226508;
    self.ra_tyr_scene.var_76b413f28e3a2ed6.var_70fc3599c8a6f8b1 = self;
    self.ra_tyr_scene.var_76b413f28e3a2ed6 function_246ba832aa2f57d8( level.var_dc93f7e52123aeea[ "ra_tyr_player" ] );
    self function_f2d025c338c06fa7( self.ra_tyr_scene.var_76b413f28e3a2ed6, "tag_player" );
    self.ra_tyr_scene.var_76b413f28e3a2ed6 function_ca78af7616aa45ab( self.ra_tyr_mover );
    self.ra_tyr_scene.var_76b413f28e3a2ed6 function_f4b8e94000e3853e();
    self thread ra_tyr_rig_disconnect( self.ra_tyr_scene );
    self thread ra_tyr_rig_view( self.ra_tyr_scene );
}

// function_835dff1a0b6f91e8: the fall animation for the length of the ride.
function ra_tyr_rig_anim( scene )
{
    self endon( #"hash_20666ddcfb99d876" );
    self endon( #"ra_tyr_rig_cancel" );
    nengine_store_set( "rex_arena", "drop_rig_worker", "waiting_for_mover" );
    self.ra_tyr_mover thread ra_tyr_play_anim( scene );
    self.ra_tyr_mover waittill( #"movedone" );
    nengine_store_set( "rex_arena", "drop_rig_worker", "mover_done" );
    nengine_store_save( "rex_arena", "runtime" );
    self.ra_tyr_mover namespace_16b0eb576933808c::function_29cb91742cc7b79();
    nengine_store_set( "rex_arena", "drop_rig_handoff_before", self islinked() ? 1 : 0 );
    self function_bfaaf9b43819d218();
    nengine_store_set( "rex_arena", "drop_rig_handoff_after_native", self islinked() ? 1 : 0 );
    // Detach before deleting the animated parent, and allow a short update
    // while the landing is black. This is a client handoff experiment.
    if ( self islinked() )
        self unlink();
    nengine_store_set( "rex_arena", "drop_rig_handoff_after_unlink", self islinked() ? 1 : 0 );
    nengine_store_set( "rex_arena", "drop_rig_worker", "detached_waiting" );
    nengine_store_save( "rex_arena", "runtime" );
    wait 0.1;
    namespace_214d79f87f4bf971::function_9a5ee51116044765( "anim_scene" );
    if ( isdefined( scene.var_76b413f28e3a2ed6 ) )
        scene.var_76b413f28e3a2ed6 function_9f2ac922a6ca86b9();
    nengine_store_set( "rex_arena", "drop_rig_worker", "completed" );
    nengine_store_save( "rex_arena", "runtime" );
}

// The native animation worker runs on the mover; records whether it returns.
function ra_tyr_play_anim( scene )
{
    self.ra_tyr_anim_t0 = function_83bf4b34fbbe124b();
    nengine_store_set( "rex_arena", "drop_anim_worker", "entered" );
    nengine_store_save( "rex_arena", "runtime" );
    self namespace_16b0eb576933808c::function_3fa1ea3035fbaa67( [ scene ], "player_sucked_in", 0, 0, undefined );
    nengine_store_set( "rex_arena", "drop_anim_worker", "returned" );
    nengine_store_set( "rex_arena", "drop_anim_worker_ms", function_83bf4b34fbbe124b() - self.ra_tyr_anim_t0 );
    nengine_store_save( "rex_arena", "runtime" );
}

// function_630203ad8b2c6680: the rig is shown only to this player, and not in
// third person.
function ra_tyr_rig_view( scene )
{
    self notify( #"hash_d45edc6078d1fa21" );
    self endon( #"hash_d45edc6078d1fa21" );
    self endon( #"hash_20666ddcfb99d876" );
    self endon( #"ra_tyr_rig_cancel" );
    scene.var_76b413f28e3a2ed6 endon( #"death" );
    self.ra_tyr_rig_shown = 0;
    for ( ;; )
    {
        if ( scene.var_76b413f28e3a2ed6 function_47dd3263f5ea2597() )
        {
            self.ra_tyr_viewers = scene.var_76b413f28e3a2ed6 function_eb0e3c561102033c();
            if ( !function_98aacac99283c282( self.ra_tyr_viewers, self ) )
            {
                scene.var_76b413f28e3a2ed6 function_f4b8e94000e3853e();
                waitframe();
                continue;
            }
        }
        if ( self function_edc98fa7c1061e87() && self.ra_tyr_rig_shown )
        {
            scene.var_76b413f28e3a2ed6 function_f4b8e94000e3853e();
            self.ra_tyr_rig_shown = 0;
        }
        else if ( !self function_edc98fa7c1061e87() && !self.ra_tyr_rig_shown )
        {
            self.ra_tyr_rig_shown = 1;
            scene.var_76b413f28e3a2ed6 function_5ba794915107aaf1( self );
        }
        waitframe();
    }
}

// function_aa24807231579b1e
function ra_tyr_rig_disconnect( scene )
{
    scene.var_76b413f28e3a2ed6 endon( #"death" );
    self waittill( #"hash_20666ddcfb99d876" );
    if ( isdefined( scene.var_76b413f28e3a2ed6 ) )
        scene.var_76b413f28e3a2ed6 function_9f2ac922a6ca86b9();
}

// function_b2435c8b71589176( rig, -height, angles, 0, 3, 0.35 ): the ride down
// and the landing.
function ra_tyr_ride( scene, dz, angles, ride_time, fade_time )
{
    self endon( #"hash_20666ddcfb99d876" );
    if ( !level.ra_no_states )
        self function_d79646d3876ac6c7( 1 );
    if ( !level.ra_no_rig )
        self thread ra_tyr_rig_anim( scene );
    self.ra_tyr_mover function_7dfb0fa9bb67b50f( dz + 32, ride_time, ride_time );
    self ra_tyr_mark( "riding" );
    wait 0.15;
    level.ra_tyr_event = spawnstruct();
    level.ra_tyr_event.var_5b53f19c893758d7 = self;
    level namespace_42ffbe510c7bd5b1::function_42ffbe510c7bd5b1( #"hash_3e4093a7794b1a98", level.ra_tyr_event );
    self function_bacf2f49accd76d( %"hash_393afb55a2f3b889" );
    self function_bacf2f49accd76d( %"hash_6ba91055bf13c4c8" );
    namespace_214d79f87f4bf971::function_9a5ee51116044765( #"hash_5474fbb93aebbb65" );
    namespace_74b2d1dbce2fe39a::function_cc5dcf33f4f4301( 0 );
    self function_d88e8eab88c50c13( 0 );
    namespace_5b53f19c893758d7::function_918b8cfdd42771ea();
    self thread namespace_6b3344dd849818f8::function_359470233876be22( fade_time, "white" );
    self ra_tyr_mark( "fading_in" );
    // At one second into the descent, capture the actual positions. A normal
    // absolute player-to-rig link keeps the player near the mover. If the
    // player is still at the arena floor, reattach to the mover itself.
    wait 0.85;
    nengine_store_set( "rex_arena", "drop_mid_player", self.origin );
    nengine_store_set( "rex_arena", "drop_mid_mover", self.ra_tyr_mover.origin );
    nengine_store_set( "rex_arena", "drop_mid_rig_present", isdefined( scene.var_76b413f28e3a2ed6 ) ? 1 : 0 );
    nengine_store_set( "rex_arena", "drop_mid_rig_shown", isdefined( self.ra_tyr_rig_shown ) ? self.ra_tyr_rig_shown : -1 );
    nengine_store_set( "rex_arena", "drop_mid_viewmodel_anim", self isviewmodelanimplaying() ? 1 : 0 );
    if ( isdefined( scene.var_76b413f28e3a2ed6 ) && isdefined( scene.var_76b413f28e3a2ed6.var_e4f5c9b3359562dc ) )
        nengine_store_set( "rex_arena", "drop_mid_anim_threads", scene.var_76b413f28e3a2ed6.var_e4f5c9b3359562dc );
    else
        nengine_store_set( "rex_arena", "drop_mid_anim_threads", 0 );
    if ( self.origin[ 2 ] < self.ra_tyr_dest[ 2 ] + 512 &&
         self.ra_tyr_mover.origin[ 2 ] > self.ra_tyr_dest[ 2 ] + 1200 )
    {
        self unlink();
        self function_a544338816001600( self.ra_tyr_mover.origin );
        self playerlinkto( self.ra_tyr_mover );
        nengine_store_set( "rex_arena", "drop_fallback", "linked_to_mover" );
        nengine_store_set( "rex_arena", "drop_fallback_origin", self.origin );
    }
    // The native fade-in helper can be suppressed by a level flag. If this
    // drop's white HUD element is still opaque after its fade time, clear it.
    if ( isdefined( self.var_fd24d570aa69fd56 ) &&
         isdefined( self.var_fd24d570aa69fd56[ "white" ] ) )
    {
        self.ra_tyr_white = self.var_fd24d570aa69fd56[ "white" ];
        nengine_store_set( "rex_arena", "drop_white_alpha", self.ra_tyr_white.alpha );
        if ( self.ra_tyr_white.alpha > 0 )
        {
            self.ra_tyr_white fadeovertime( 0.1 );
            self.ra_tyr_white.alpha = 0;
            nengine_store_set( "rex_arena", "drop_white_fade", "cleared" );
        }
        else
            nengine_store_set( "rex_arena", "drop_white_fade", "already_clear" );
    }
    else
        nengine_store_set( "rex_arena", "drop_white_fade", "element_missing" );
    nengine_store_save( "rex_arena", "runtime" );
    wait ride_time - 0.15 - 0.2 - 0.85;
    nengine_store_set( "rex_arena", "drop_end_player", self.origin );
    nengine_store_set( "rex_arena", "drop_end_mover", self.ra_tyr_mover.origin );
    nengine_store_save( "rex_arena", "runtime" );
    self ra_tyr_mark( "ride_end" );
    self function_d79646d3876ac6c7( 0 );
    self ra_tyr_mark( "ride_state_off" );
    self.ra_tyr_black_owned = 1;
    self thread ra_tyr_black_safety();
    self thread namespace_6b3344dd849818f8::function_a171f7756afa97bb( 0, "black" );
    self ra_tyr_mark( "black_on" );
    wait 0.35;
    self ra_tyr_mark( "landing" );
    self function_29137e613a12a41f( angles );
    self ra_tyr_mark( "land_angles" );
    namespace_b6c4df78b601d10d::function_bd574f13d88432bf( %"hash_736f7e678dbdccde", #"hash_7f6308be8ab37fc0", 2.5 );
    self ra_tyr_mark( "land_shake" );
    self thread ra_tyr_land_shockwave();
    self thread ra_tyr_land_push();
    self ra_tyr_mark( "land_shockwave" );
    self function_bacf2f49accd76d( %"hash_254035c5eb2fb816" );
    self function_bacf2f49accd76d( %"hash_6509dcc65829f6bb" );
    self ra_tyr_mark( "land_sounds" );
    wait 1;
    self ra_tyr_mark( "landed" );
    self ra_tyr_release_rig( "landing" );
    self ra_tyr_mark( "rig_released" );
    self ra_tyr_cleanup();
    self ra_tyr_mark( "cleaned_up" );
    namespace_6b3344dd849818f8::function_359470233876be22( 0.5, "black" );
    self ra_tyr_mark( "black_faded" );
    self ra_tyr_clear_black( "normal" );
    self ra_tyr_mark( "black_cleared" );
    namespace_214d79f87f4bf971::function_9a5ee51116044765( #"hash_46ccd37542b93aee" );
    self ra_tyr_mark( "controls_released" );
    self notify( #"hash_27f6236b0086be3c" );
}

// Release only this drop's rig, stopping its scene first.
function ra_tyr_release_rig( reason )
{
    if ( isdefined( self.ra_tyr_rig_released ) && self.ra_tyr_rig_released )
        return;
    nengine_store_set( "rex_arena", "drop_rig_linked_before", self islinked() ? 1 : 0 );
    self notify( #"ra_tyr_rig_cancel" );
    if ( isdefined( self.ra_tyr_mover ) && !level.ra_no_rig )
        self.ra_tyr_mover namespace_16b0eb576933808c::function_29cb91742cc7b79();
    self ra_tyr_mark( "rig_anim_stopped" );
    self function_bfaaf9b43819d218();
    self unlink();
    self ra_tyr_mark( "rig_unlinked" );
    nengine_store_set( "rex_arena", "drop_rig_linked_after", self islinked() ? 1 : 0 );
    if ( isdefined( self.ra_tyr_scene ) && isdefined( self.ra_tyr_scene.var_76b413f28e3a2ed6 ) )
        self.ra_tyr_scene.var_76b413f28e3a2ed6 function_9f2ac922a6ca86b9();
    if ( isdefined( self.ra_tyr_mover ) )
        self.ra_tyr_mover function_9f2ac922a6ca86b9();
    self.ra_tyr_rig_released = 1;
    nengine_store_set( "rex_arena", "drop_rig_release", reason );
    nengine_store_save( "rex_arena", "runtime" );
}

// Owns only this landing's black HUD element; still runs if the normal
// sequence exits before its fade-in.
function ra_tyr_black_safety()
{
    self endon( #"disconnect" );
    self endon( #"ra_drop_restart" );
    level endon( #"game_ended" );
    wait 5;
    if ( isdefined( self.ra_tyr_black_owned ) && self.ra_tyr_black_owned )
        self ra_tyr_clear_black( "safety_timeout" );
}

function ra_tyr_clear_black( reason )
{
    if ( !isdefined( self.ra_tyr_black_owned ) || !self.ra_tyr_black_owned )
        return;
    self.ra_tyr_black_owned = 0;
    if ( isdefined( self.var_fd24d570aa69fd56 ) &&
         isdefined( self.var_fd24d570aa69fd56[ "black" ] ) )
    {
        self.ra_tyr_black = self.var_fd24d570aa69fd56[ "black" ];
        nengine_store_set( "rex_arena", "drop_black_alpha_before", self.ra_tyr_black.alpha );
        self.ra_tyr_black.alpha = 0;
        nengine_store_set( "rex_arena", "drop_black_fade", reason );
    }
    else
        nengine_store_set( "rex_arena", "drop_black_fade", "element_missing" );
    nengine_store_save( "rex_arena", "runtime" );
}

// function_aac21b520ad82c51: the landing scriptable state and the shockwave
// that knocks back nearby zombies.
function ra_tyr_land_shockwave()
{
    self function_7555d0f6ef1562a9( #"hash_d2c92d3f34916888", #"hash_83a330394146afee" );
    namespace_74b2d1dbce2fe39a::function_835556fe63cd2edd( self.origin, 256, 0, 1, 1, 1, 0, 0 );
}

// function_7a9d3f3b4a49e7b8: other players on the landing spot are pushed aside.
function ra_tyr_land_push()
{
    self.ra_tyr_near = function_35d45993c544928d( self.origin, 64 );
    if ( self.ra_tyr_near.size == 0 )
        return;
    if ( self.ra_tyr_near.size == 1 && self.ra_tyr_near[ 0 ] == self )
        return;
    self.ra_tyr_near = function_95e538e1f602b947( self.ra_tyr_near, self );
    self.ra_tyr_near_i = 0;
    while ( self.ra_tyr_near_i < self.ra_tyr_near.size )
    {
        self.ra_tyr_near[ self.ra_tyr_near_i ] namespace_60b3bdcc70f79fc6::function_4c63aa990da0185( ( 0, function_b67def3fb7ba8435( 360 ), 0 ), 1200 );
        self.ra_tyr_near_i++;
    }
}

// Record only: when the player dies after a landing.
function ra_death_record()
{
    self endon( #"disconnect" );
    self endon( #"ra_drop_restart" );
    level endon( #"game_ended" );
    self waittill( #"death" );
    nengine_store_set( "rex_arena", "death_ms_after_landing", function_83bf4b34fbbe124b() - level.ra_land_t );
    nengine_store_set( "rex_arena", "death_origin", self.origin );
    nengine_store_set( "rex_arena", "death_damage_events", isdefined( level.ra_dmg_n ) ? level.ra_dmg_n : 0 );
    nengine_store_save( "rex_arena", "runtime" );
}

// After landing, sample for about a minute. Server state only; it cannot tell
// what the client drew.
function ra_land_monitor()
{
    self endon( #"disconnect" );
    self endon( #"death" );
    self endon( #"ra_drop_restart" );
    level endon( #"game_ended" );
    self.ra_lm_step = 0;
    while ( self.ra_lm_step < 14 )
    {
        wait ( self.ra_lm_step < 3 ? self.ra_lm_step + 1 : 5 );
        self.ra_lm_step++;
        nengine_store_set( "rex_arena", "land_monitor", self.ra_lm_step );
        nengine_store_set( "rex_arena", "land_monitor_origin", self.origin );
        nengine_store_set( "rex_arena", "land_monitor_eye", self function_5255d85caf38b6eb() );
        nengine_store_set( "rex_arena", "land_monitor_angles", self function_3996cf2c8d4762a3() );
        nengine_store_set( "rex_arena", "land_monitor_linked", self islinked() ? 1 : 0 );
        nengine_store_set( "rex_arena", "lm_" + self.ra_lm_step + "_eye_height", self function_5255d85caf38b6eb()[ 2 ] - self.origin[ 2 ] );
        nengine_store_set( "rex_arena", "lm_" + self.ra_lm_step + "_health", self.health );
        nengine_store_set( "rex_arena", "lm_" + self.ra_lm_step + "_origin", self.origin );
        nengine_store_set( "rex_arena", "lm_" + self.ra_lm_step + "_ms", function_83bf4b34fbbe124b() - level.ra_land_t );
        if ( isdefined( self.var_fd24d570aa69fd56 ) && isdefined( self.var_fd24d570aa69fd56[ "black" ] ) )
            nengine_store_set( "rex_arena", "land_monitor_black", self.var_fd24d570aa69fd56[ "black" ].alpha );
        else
            nengine_store_set( "rex_arena", "land_monitor_black", "none" );
        nengine_store_save( "rex_arena", "runtime" );
    }
}

// Kronos logs no GSC errors, so the last drop step saved shows where a drop
// stopped. t_<step> is the server time (ms) the step was reached: on a bad
// launch the client can freeze after landing, and the crash report's last
// snapshot time then identifies the step.
function ra_tyr_mark( step )
{
    nengine_store_set( "rex_arena", "drop_step", step );
    nengine_store_set( "rex_arena", "t_" + step, function_83bf4b34fbbe124b() );
    nengine_store_save( "rex_arena", "runtime" );
}

// If the drop has not finished after 15 seconds (it takes about 10), stop it,
// clear both screen fades, detach the player, put them on the landing spot and
// run the cleanup. The fades are cleared first.
function ra_tyr_watchdog()
{
    self endon( #"disconnect" );
    self endon( #"ra_drop_restart" );
    level endon( #"game_ended" );
    self.ra_tyr_watch = 0;
    while ( self.ra_dropping == 1 && self.ra_tyr_watch < 150 )
    {
        wait 0.1;
        self.ra_tyr_watch++;
    }
    if ( self.ra_dropping != 1 )
        return;
    self notify( #"ra_tyr_abort" );
    nengine_store_set( "rex_arena", "drop", "recovering" );
    nengine_store_save( "rex_arena", "runtime" );
    self ra_tyr_clear_black( "watchdog" );
    namespace_6b3344dd849818f8::function_359470233876be22( 0, "white" );
    namespace_6b3344dd849818f8::function_359470233876be22( 0, "black" );
    // The native helper may be suppressed by a level flag; clear our HUD
    // elements directly as a backstop before doing any other recovery work.
    if ( isdefined( self.var_fd24d570aa69fd56 ) )
    {
        if ( isdefined( self.var_fd24d570aa69fd56[ "white" ] ) )
        {
            self.ra_entry_white = self.var_fd24d570aa69fd56[ "white" ];
            self.ra_entry_white.alpha = 0;
        }
        if ( isdefined( self.var_fd24d570aa69fd56[ "black" ] ) )
        {
            self.ra_entry_black = self.var_fd24d570aa69fd56[ "black" ];
            self.ra_entry_black.alpha = 0;
        }
    }
    nengine_store_set( "rex_arena", "drop_recover", "fades_cleared" );
    nengine_store_save( "rex_arena", "runtime" );
    self ra_tyr_release_rig( "watchdog" );
    self function_d79646d3876ac6c7( 0 );
    self function_2eb2bd79484faf45( ( 0, 0, 0 ) );
    self function_a544338816001600( self.ra_tyr_dest );
    self function_29137e613a12a41f( self.ra_tyr_angles );
    nengine_store_set( "rex_arena", "drop_recover", "placed" );
    nengine_store_save( "rex_arena", "runtime" );
    self.ra_dropping = 0;
    self ra_tyr_cleanup();
    level.ra_land_t = function_83bf4b34fbbe124b();
    nengine_store_set( "rex_arena", "drop", "recovered" );
    nengine_store_set( "rex_arena", "drop_recover", "cleaned_up" );
    nengine_store_set( "rex_arena", "drop_landing", self.origin );
    nengine_store_save( "rex_arena", "runtime" );
}

// function_9641a074298de689 with function_db6385f2e2e3db29: undo the
// preparation, leaving the original weapon selected. Both state groups are
// cleared so the watchdog path restores the controls too.
function ra_tyr_cleanup()
{
    namespace_214d79f87f4bf971::function_9a5ee51116044765( #"hash_46ccd37542b93aee" );
    namespace_214d79f87f4bf971::function_9a5ee51116044765( #"hash_5474fbb93aebbb65" );
    self.var_4014e1a4c4df8dd9 = undefined;
    namespace_a9d0968f08f885b0::function_c14762bb6e0b4edb( self );
    if ( isdefined( self.var_80b47a6852268227 ) && self.var_80b47a6852268227 )
    {
        self notify( #"hash_4615bc0f573377ee" );
        self.var_80b47a6852268227 = undefined;
    }
    // No temporary weapon was given or selected. Record the existing gun's
    // state without making the fade or control release wait on a switch.
    nengine_store_set( "rex_arena", "drop_weapon_restore", "swap_not_attempted" );
    // Switch only when the original gun is not already the current one.
    if ( isdefined( self.ra_tyr_original_weapon ) && isweapon( self.ra_tyr_original_weapon ) &&
         self hasweapon( self.ra_tyr_original_weapon ) && self getcurrentweapon() == self.ra_tyr_original_weapon )
        nengine_store_set( "rex_arena", "drop_weapon_selection", "already_current" );
    else if ( isdefined( self.ra_tyr_original_weapon ) && isweapon( self.ra_tyr_original_weapon ) &&
         self hasweapon( self.ra_tyr_original_weapon ) )
        nengine_store_set( "rex_arena", "drop_weapon_selection", self namespace_6dcadaff87c6f389::function_e1db8ce4b9327997( self.ra_tyr_original_weapon ) ? "original_selected" : "not_confirmed" );
    else
        nengine_store_set( "rex_arena", "drop_weapon_selection", "saved_weapon_unavailable" );
    nengine_store_save( "rex_arena", "runtime" );
}

// Specials, elites and HVTs, as on the reference mod. Enemies are made with
// the game's own functions: the zone spawner picks an ordinary zombie spawn
// spot of the arena (namespace_b0c5a0220f5772db::function_6776c0f9111aaf8f,
// "zombie_base") and the ZM agent spawner creates the type there
// (namespace_c92d17df4cbfb50f::function_1fd1c42a28e8b763). A type this map has
// not loaded returns nothing; it is recorded as not_loaded and skipped for the
// rest of the match. Every available type in a pool is used once before any
// repeats.
//   0 specials: from round 8, 1 + (round-8)/3 per round (max 8).
//   1 elites: from round 14, 1 + (round-14)/6 (max 4), at most 3 alive.
//   2 HVTs: from round 20, 1 + (round-20)/8 (max 3), at most 2 alive.
//   3 bosses (Rex only): Z-Rex and the Guardian, see ra_boss_spawn.
// All are must-kill: they count toward the round, so it stays open until they
// are dead. Elites and HVTs come in three waves: start (6 s after the round
// number changes, one every 1.5 s), middle (half of the round's zombies left)
// and end (an eighth left, at least 3). Specials keep a 10-20 s pace from 15 s.
function ra_sp_roster()
{
    level.ra_sp_pool = [];
    level.ra_sp_pool[ 0 ] = [ "sat_spawner_zombie_ghoul_zm",
        "sat_spawner_zombie_mimic_zm",
        "sat_spawner_zombie_mimic_emp_zm",
        "sat_spawner_zombie_mangler_zm",
        "sat_spawner_zombie_parasite_zm",
        "sat_spawner_zombie_vermin_zm",
        "sat_spawner_zombie_disciple_zm",
        "sat_spawner_zombie_hellhound_zm",
        "sat_spawner_zombie_base_abom_crawler_zm",
        "sat_spawner_zombie_orion_zm",
        "sat_spawner_zombie_viper_mini_zm",
        "sat_spawner_zombie_karkinos_zm",
        "sat_spawner_zombie_methone_zm",
        "sat_spawner_zombie_methone_fire_zm",
        "sat_spawner_zombie_shade_zm",
        "sat_spawner_zombie_loom_minion_zm",
        "sat_spawner_zombie_disciple_skoll_zm",
        "sat_spawner_zombie_base_luna_zm",
        "sat_spawner_zombie_base_armored_agni_zm" ];
    level.ra_sp_pool[ 1 ] = [ "sat_spawner_zombie_abom_zm",
        "sat_spawner_zombie_amalgam_zm",
        "sat_spawner_zombie_callisto_zm",
        "sat_spawner_zombie_viper_zm" ];
    level.ra_sp_pool[ 2 ] = [ "sat_spawner_zombie_abom_hvt_zm",
        "sat_spawner_zombie_amalgam_zm_hvt",
        "sat_spawner_zombie_mangler_hvt_zm",
        "sat_spawner_zombie_ghoul_hvt_zm",
        "sat_spawner_zombie_mimic_hvt_zm",
        "sat_spawner_zombie_mimic_hvt_emp_zm",
        "sat_spawner_zombie_callisto_hvt_zm",
        "sat_spawner_zombie_orion_hvt_zm",
        "sat_spawner_zombie_viper_hvt_zm",
        "sat_spawner_zombie_viper_mini_hvt_zm",
        "sat_spawner_zombie_karkinos_hvt",
        "sat_spawner_zombie_methone_zm_hvt",
        "sat_spawner_zombie_disciple_skoll_hvt_zm",
        "sat_spawner_zombie_base_luna_hvt" ];
    level.ra_sp_cap = [];
    level.ra_sp_cap[ 0 ] = 8;
    level.ra_sp_cap[ 1 ] = 3;
    level.ra_sp_cap[ 2 ] = 2;
    level.ra_sp_q = [];
    level.ra_sp_q[ 0 ] = [];
    level.ra_sp_q[ 1 ] = [];
    level.ra_sp_q[ 2 ] = [];
    level.ra_sp_due = [];
    level.ra_sp_due[ 0 ] = 0;
    level.ra_sp_due[ 1 ] = 0;
    level.ra_sp_due[ 2 ] = 0;
    level.ra_sp_ph = [];
    level.ra_sp_ph[ 1 ] = [];
    level.ra_sp_ph[ 2 ] = [];
    level.ra_sp_open = [];
    ra_sp_clear_round();
    level.ra_sp_live_t = [];
    level.ra_sp_bad = [];
    level.ra_sp_made = [];
    level.ra_sp_total = 0;
    level.ra_sp_not_loaded = 0;
    level.ra_sp_stuck = 0;
    level.ra_sp_nudges = 0;
    // HVTs of specials and their special (see ra_sp_watch).
    level.ra_hvt_base = [];
    level.ra_hvt_ratio = [];
    level.ra_hvt_base[ "sat_spawner_zombie_ghoul_hvt_zm" ] = "sat_spawner_zombie_ghoul_zm";
    level.ra_hvt_ratio[ "sat_spawner_zombie_ghoul_hvt_zm" ] = 5.26;
    level.ra_hvt_base[ "sat_spawner_zombie_mimic_hvt_zm" ] = "sat_spawner_zombie_mimic_zm";
    level.ra_hvt_ratio[ "sat_spawner_zombie_mimic_hvt_zm" ] = 5.03;
    level.ra_hvt_base[ "sat_spawner_zombie_mimic_hvt_emp_zm" ] = "sat_spawner_zombie_mimic_emp_zm";
    level.ra_hvt_ratio[ "sat_spawner_zombie_mimic_hvt_emp_zm" ] = 5.03;
    level.ra_hvt_base[ "sat_spawner_zombie_karkinos_hvt" ] = "sat_spawner_zombie_karkinos_zm";
    level.ra_hvt_ratio[ "sat_spawner_zombie_karkinos_hvt" ] = 3.96;
    level.ra_hvt_base[ "sat_spawner_zombie_orion_hvt_zm" ] = "sat_spawner_zombie_orion_zm";
    level.ra_hvt_ratio[ "sat_spawner_zombie_orion_hvt_zm" ] = 5.0;
    level.ra_hvt_base[ "sat_spawner_zombie_viper_mini_hvt_zm" ] = "sat_spawner_zombie_viper_mini_zm";
    level.ra_hvt_ratio[ "sat_spawner_zombie_viper_mini_hvt_zm" ] = 5.0;
    level.ra_hvt_base[ "sat_spawner_zombie_methone_zm_hvt" ] = "sat_spawner_zombie_methone_zm";
    level.ra_hvt_ratio[ "sat_spawner_zombie_methone_zm_hvt" ] = 5.0;
    level.ra_hvt_base[ "sat_spawner_zombie_disciple_skoll_hvt_zm" ] = "sat_spawner_zombie_disciple_skoll_zm";
    level.ra_hvt_ratio[ "sat_spawner_zombie_disciple_skoll_hvt_zm" ] = 5.0;
    level.ra_hvt_base[ "sat_spawner_zombie_base_luna_hvt" ] = "sat_spawner_zombie_base_luna_zm";
    level.ra_hvt_ratio[ "sat_spawner_zombie_base_luna_hvt" ] = 5.0;
    level.ra_hvt_base[ "sat_spawner_zombie_mangler_hvt_zm" ] = "sat_spawner_zombie_mangler_zm";
    level.ra_hvt_ratio[ "sat_spawner_zombie_mangler_hvt_zm" ] = 5.0;
    level.ra_sp_seen_hp = [];
    level.ra_sp_seen_round = [];
    // Boss events, once each, from the first round at or after their round:
    // 0 Z-Rex, 1 the Guardian, 2 both together, 3 (0.5.17) Z-Rex and Caltheris,
    // 4 (0.5.25) all three, 5 (0.5.31) all three and the Weyward.
    // Bosses (ra_boss_spawner): 0 Z-Rex, 1 the Guardian, 2 Caltheris,
    // 3 (0.5.33) the Weyward, Rex's main boss (0.5.31-0.5.32: the Dread Skull).
    level.ra_boss_spawner = [];
    level.ra_boss_spawner[ 0 ] = "sat_spawner_zombie_phobos_zm";
    level.ra_boss_spawner[ 1 ] = "t10_spawner_zombie_triton";
    level.ra_boss_spawner[ 2 ] = "sat_spawner_zombie_neptune_zm";
    level.ra_boss_spawner[ 3 ] = "sat_spawner_zombie_weyward_zm";
    level.ra_boss_type = [];
    level.ra_boss_round = [];
    level.ra_boss_done = [];
    level.ra_boss_type[ 0 ] = "sat_spawner_zombie_phobos_zm";
    level.ra_boss_round[ 0 ] = level.ra_zrex_round;
    level.ra_boss_done[ 0 ] = 0;
    level.ra_boss_type[ 1 ] = "t10_spawner_zombie_triton";
    level.ra_boss_round[ 1 ] = level.ra_guardian_round;
    level.ra_boss_done[ 1 ] = 0;
    level.ra_boss_type[ 2 ] = "sat_spawner_zombie_phobos_zm and t10_spawner_zombie_triton";
    level.ra_boss_round[ 2 ] = level.ra_both_round;
    level.ra_boss_done[ 2 ] = 0;
    level.ra_boss_type[ 3 ] = "sat_spawner_zombie_phobos_zm and sat_spawner_zombie_neptune_zm";
    level.ra_boss_round[ 3 ] = level.ra_caltheris_round;
    level.ra_boss_done[ 3 ] = 0;
    level.ra_boss_type[ 4 ] = "sat_spawner_zombie_phobos_zm, t10_spawner_zombie_triton and sat_spawner_zombie_neptune_zm";
    level.ra_boss_round[ 4 ] = level.ra_trio_round;
    level.ra_boss_done[ 4 ] = 0;
    level.ra_boss_type[ 5 ] = "sat_spawner_zombie_phobos_zm, t10_spawner_zombie_triton, sat_spawner_zombie_neptune_zm and sat_spawner_zombie_weyward_zm";
    level.ra_boss_round[ 5 ] = level.ra_quad_round;
    level.ra_boss_done[ 5 ] = 0;
    level.ra_both_zrex = 0;
    // 0.5.82: the round-50 Z-Rex is alive and owes the Golden Armor reward
    level.ra_zr_gold = 0;
    // 0.5.86: the round-75 Guardian is alive and owes the Ultra rarity reward
    level.ra_gd_ultra = 0;
    // 0.5.88: the round-100 Caltheris is alive and owes the Pack-a-Punch IV reward
    level.ra_cl_pap = 0;
    level.ra_tr_z = 0;
    level.ra_tr_g = 0;
    level.ra_bar_h = 0;
    level.ra_qd_started = 0;
    level.ra_qd_trio = 0;
    level.ra_qd_w = 0;
    level.ra_w_mark = 0;
    level.ra_b4_last = "";
    level.ra_b4_ui = "";
    // 0.5.38: Caltheris's copy (rex_arena_bar5) and the game's bar taken down
    level.ra_b5_text = "";
    level.ra_b5_last = "";
    level.ra_b5_ui = "";
    level.ra_q_down = 0;
    level.ra_q_n = 0;
    level.ra_wey_fake = 0;
    level.ra_wbf_last = 0;
    level.ra_wbf_n = 0;
    level.ra_wst_k = 0;
    level.ra_wpc_n = 0;
    level.ra_wpc_t = undefined;
    level.ra_cal_mark = 0;
    level.ra_boss_blocked = 0;
    level.ra_boss_revived = 0;
    level.ra_made_t = [];
    level.ra_gh_n = 0;
    level.ra_gh_big = 0;
    level.ra_t_n = 0;
    level.ra_bar_ev = 0;
    level.ra_held = [];
    level.ra_tr_end = [];
    level.ra_hud_ui = "";
    setdvar( @"rex_arena_note", "" );
    setdvar( @"rex_arena_main", "" );
    setdvar( @"rex_arena_hud_ui", "" );
    // 0.5.87: the Arsenal's Ultra slot (mod Lua) is off until the Guardian's reward
    setdvar( @"rex_arena_ultra", "" );
    setdvar( @"rex_arena_ultra_ui", "" );
    // 0.5.94: the Void Talon popup (mod Lua) is not shown until the upgrade
    setdvar( @"rex_arena_splash", "" );
    // 0.5.95: the round-select popups (mod Lua)
    setdvar( @"rex_arena_hint", "" );
    setdvar( @"rex_arena_splash_ok", "" );
    setdvar( @"rex_arena_splash_ui", "" );
    level.ra_zd_cancel = 0;
    level.ra_zo_hits = 0;
    level.ra_zi_n = 0;
    level.ra_znc_n = 0;
    level.ra_sw_last = [];
    level.ra_sw_total = 0;
    level.ra_sw_near = 0;
    level.ra_sw_inside = 0;
    level.ra_sw_kill_t = undefined;
    level.ra_zrex_hide_done = 0;
    level.ra_g_ai = [];
    level.ra_g_hp = [];
    level.ra_g_max = [];
    level.ra_g_org = [];
    level.ra_g_ang = [];
    level.ra_zrex_nc = 0;
    level.ra_g_on = [];
    level.ra_g_on[ 0 ] = 0;
    level.ra_g_on[ 1 ] = 0;
    level.ra_g_on[ 2 ] = 0;
    level.ra_g_on[ 3 ] = 0;
    level.ra_g_pass = 0;
    level.ra_b2_last = "";
    level.ra_b2_other_hp = -1;
    setdvar( @"rex_arena_bar2", "" );
    setdvar( @"rex_arena_bar2_ui", "" );
    level.ra_b2_ui = "";
    level.ra_b3_last = "";
    level.ra_b3_ui = "";
    level.ra_b_hp_last = "";
    level.ra_t_lay_last = "";
    setdvar( @"rex_arena_bar3", "" );
    setdvar( @"rex_arena_bar3_ui", "" );
    setdvar( @"rex_arena_bar4", "" );
    setdvar( @"rex_arena_bar5", "" );
    setdvar( @"rex_arena_bar4_ui", "" );
    level.ra_boss_due = -1;
    level.ra_boss_made = 0;
    nengine_store_set( "rex_arena", "boss_zrex_round", level.ra_zrex_round );
    nengine_store_set( "rex_arena", "boss_guardian_round", level.ra_guardian_round );
    nengine_store_set( "rex_arena", "boss_zrex", "waiting" );
    nengine_store_set( "rex_arena", "boss_guardian", "waiting" );
    nengine_store_set( "rex_arena", "boss_both_round", level.ra_both_round );
    nengine_store_set( "rex_arena", "boss_both", "waiting" );
    nengine_store_set( "rex_arena", "boss_caltheris_round", level.ra_caltheris_round );
    nengine_store_set( "rex_arena", "boss_caltheris_zrex", "waiting" );
    nengine_store_set( "rex_arena", "boss_caltheris", "waiting" );
    nengine_store_set( "rex_arena", "boss_trio_round", level.ra_trio_round );
    nengine_store_set( "rex_arena", "boss_trio", "waiting" );
    nengine_store_set( "rex_arena", "boss_quad_round", level.ra_quad_round );
    nengine_store_set( "rex_arena", "boss_quad", "waiting" );
    nengine_store_set( "rex_arena", "boss_weyward", "waiting" );
    nengine_store_set( "rex_arena", "boss_weyward_spawner", "none" );
    nengine_store_set( "rex_arena", "boss_weyward_bar_id", "none" );
    nengine_store_set( "rex_arena", "boss_weyward_death", "none" );
    nengine_store_set( "rex_arena", "boss_weyward_deathinfo", "none" );
    nengine_store_set( "rex_arena", "boss_weyward_hide", "none" );
    nengine_store_set( "rex_arena", "boss_weyward_lethal_held", "none" );
    nengine_store_set( "rex_arena", "boss_weyward_where", "none" );
    nengine_store_set( "rex_arena", "boss_weyward_hits", "none" );
    nengine_store_set( "rex_arena", "boss_weyward_dmg_event", "none" );
    level.ra_wh_n = 0;
    level.ra_wl_n = 0;
    level.ra_ww_n = 0;
    level.ra_wb_n = 0;
    // 0.5.34: Shadow Souls (ra_weyward_souls)
    nengine_store_set( "rex_arena", "boss_weyward_souls", "none" );
    nengine_store_set( "rex_arena", "boss_weyward_soul_event", "none" );
    level.ra_ws_n = 0;
    level.ra_ws_e = 0;
    level.ra_ws_t = undefined;
    level.ra_ws_last = "";
    level.ra_ws_alive = 0;
    level.ra_ws_placed = 0;
    level.ra_ws_sh = 0;
    level.ra_ws_cut = 0;
    // 0.5.34: no trial rooms (ra_weyward_no_trial)
    nengine_store_set( "rex_arena", "boss_weyward_trial", "none" );
    level.ra_wtr_n = 0;
    level.ra_wfar_n = 0;
    level.ra_wfar_on = 0;
    // 0.5.35: Shadow Souls put in the arena (ra_weyward_soul_home)
    nengine_store_set( "rex_arena", "boss_weyward_soul_moved", "none" );
    level.ra_wsh_k = 0;
    level.ra_wsh_n = 0;
    // 0.5.36: shadow storm crystals put in the arena (ra_weyward_crystal_home)
    // 0.5.37: the Weyward's bar copy above the game's bar, immune on it
    nengine_store_set( "rex_arena", "boss_weyward_bar_immune", "none" );
    level.ra_wbi_last = 0;
    level.ra_wbi_n = 0;
    level.ra_wey_im = 0;
    level.ra_b4_slot = 0;
    nengine_store_set( "rex_arena", "boss_weyward_crystal_moved", "none" );
    level.ra_wc_k = 0;
    level.ra_wc_n = 0;
    level.ra_ws_cr = 0;
    level.ra_ws_storm = 0;
    level.ra_crystal_spots = [];
    // 0.5.38: a ring 1600 units from the arena centre (boss_arena_ff_center),
    // every 45 degrees; heights from the nearest known floor (the move traces
    // down for the floor)
    level.ra_crystal_spots[ 0 ] = ( 31024.0, -27424.0, 2213.1 );
    level.ra_crystal_spots[ 1 ] = ( 30555.4, -26292.6, 2039.4 );
    level.ra_crystal_spots[ 2 ] = ( 29424.0, -25824.0, 2013.3 );
    level.ra_crystal_spots[ 3 ] = ( 28292.6, -26292.6, 2062.8 );
    level.ra_crystal_spots[ 4 ] = ( 27824.0, -27424.0, 2108.0 );
    level.ra_crystal_spots[ 5 ] = ( 28292.6, -28555.4, 2085.1 );
    level.ra_crystal_spots[ 6 ] = ( 29424.0, -29024.0, 2124.6 );
    level.ra_crystal_spots[ 7 ] = ( 30555.4, -28555.4, 2067.0 );
    level.ra_soul_spots = [];
    level.ra_soul_spots[ 0 ] = ( 31578.2, -27569.0, 2352.0 );
    level.ra_soul_spots[ 1 ] = ( 28984.0, -27424.0, 2310.0 );
    level.ra_soul_spots[ 2 ] = ( 31033.2, -28305.2, 2193.6 );
    level.ra_soul_spots[ 3 ] = ( 30967.4, -26962.5, 2170.8 );
    level.ra_soul_spots[ 4 ] = ( 29755.9, -27961.3, 2259.8 );
    level.ra_soul_spots[ 5 ] = ( 30398.6, -26930.5, 2165.2 );
    level.ra_soul_spots[ 6 ] = ( 29494.8, -27409.7, 2302.4 );
    level.ra_soul_spots[ 7 ] = ( 29989.3, -27004.6, 2230.1 );
    level.ra_soul_spots[ 8 ] = ( 29121.7, -27036.7, 2309.7 );
    nengine_store_set( "rex_arena", "boss_quad_summary", "none" );
    nengine_store_set( "rex_arena", "boss_bar4", "hidden" );
    nengine_store_set( "rex_arena", "boss_bar4_ui", "none" );
    nengine_store_set( "rex_arena", "boss_bar5", "hidden" );
    nengine_store_set( "rex_arena", "boss_bar5_ui", "none" );
    nengine_store_set( "rex_arena", "boss_bar_quad_down", "none" );
    nengine_store_set( "rex_arena", "boss_weyward_bar_fake", "none" );
    nengine_store_set( "rex_arena", "boss_weyward_storm_moved", "none" );
    nengine_store_set( "rex_arena", "boss_weyward_phase_centre", "none" );
    nengine_store_set( "rex_arena", "boss_weyward_fakeout", "none" );
    nengine_store_set( "rex_arena", "round_select", "none" );
    nengine_store_set( "rex_arena", "round_select_used", "none" );
    nengine_store_set( "rex_arena", "round_select_toys", "none" );
    nengine_store_set( "rex_arena", "round_select_rise", "none" );
    nengine_store_set( "rex_arena", "round_select_copies", "none" );
    nengine_store_set( "rex_arena", "round_select_glows", "none" );
    nengine_store_set( "rex_arena", "round_select_col", "none" );
    nengine_store_set( "rex_arena", "round_select_brushes", "none" );
    nengine_store_set( "rex_arena", "armor_wallbuy", "none" );
    nengine_store_set( "rex_arena", "golden_armor", "none" );
    nengine_store_set( "rex_arena", "golden_armor_players", "none" );
    nengine_store_set( "rex_arena", "golden_armor_outline", "none" );
    nengine_store_set( "rex_arena", "boss_zrex_reward", "none" );
    nengine_store_set( "rex_arena", "boss_zrex_splash", "none" );
    nengine_store_set( "rex_arena", "boss_guardian_reward", "none" );
    nengine_store_set( "rex_arena", "boss_guardian_splash", "none" );
    level.ra_note_until = 0;
    level.ra_rs_t = 0;
    level.ra_rs_note_until = 0;
    level.ra_rs_hint_t = 0;
    // 0.5.95: the pedestal and boss state the round-select popup last showed
    level.ra_rs_hint_k = -1;
    level.ra_rs_hint_free = -1;
    level.ra_rs_n = 0;
    nengine_store_set( "rex_arena", "boss_bar3", "hidden" );
    nengine_store_set( "rex_arena", "boss_bar3_ui", "none" );
    nengine_store_set( "rex_arena", "boss_bar_trio", "none" );
    nengine_store_set( "rex_arena", "boss_guardian_hits", "none" );
    nengine_store_set( "rex_arena", "boss_guardian_big_hit", "none" );
    nengine_store_set( "rex_arena", "boss_caltheris_hide", "none" );
    nengine_store_set( "rex_arena", "boss_guardian_lethal_held", "none" );
    nengine_store_set( "rex_arena", "boss_caltheris_lethal_held", "none" );
    nengine_store_set( "rex_arena", "boss_note", "none" );
    nengine_store_set( "rex_arena", "boss_reward", "none" );
    nengine_store_set( "rex_arena", "boss_drops", "none" );
    nengine_store_set( "rex_arena", "boss_trio_summary", "none" );
    nengine_store_set( "rex_arena", "boss_player_hits", "none" );
    level.ra_hf_last = [];
    level.ra_hf_n = [];
    level.ra_hf_s = [];
    level.ra_hf_k = 0;
    while ( level.ra_hf_k < 4 )
    {
        level.ra_hf_n[ level.ra_hf_k ] = 0;
        level.ra_hf_s[ level.ra_hf_k ] = 0;
        level.ra_hf_k++;
    }
    nengine_store_set( "rex_arena", "boss_hud_ui", "none" );
    nengine_store_set( "rex_arena", "boss_caltheris_bar", "none" );
    nengine_store_set( "rex_arena", "boss_caltheris_roam", "none" );
    nengine_store_set( "rex_arena", "boss_caltheris_death", "none" );
    nengine_store_set( "rex_arena", "boss_caltheris_phase", "none" );
    nengine_store_set( "rex_arena", "boss_caltheris_deathinfo", "none" );
    nengine_store_set( "rex_arena", "boss_caltheris_phase_set", "none" );
    nengine_store_set( "rex_arena", "boss_caltheris_hit", "none" );
    nengine_store_set( "rex_arena", "boss_caltheris_raised", "none" );
    nengine_store_set( "rex_arena", "boss_caltheris_shield", "none" );
    nengine_store_set( "rex_arena", "boss_caltheris_restored", "none" );
    level.ra_cr_n = 0;
    level.ra_ch_n = 0;
    level.ra_ch_up = 0;
    nengine_store_set( "rex_arena", "boss_caltheris_transition", "none" );
    nengine_store_set( "rex_arena", "boss_damage_blocked", 0 );
    nengine_store_set( "rex_arena", "boss_revived", 0 );
    nengine_store_set( "rex_arena", "boss_zrex_hide", "none" );
    nengine_store_set( "rex_arena", "boss_zrex_corpse", "none" );
    nengine_store_set( "rex_arena", "boss_zrex_chase", "none" );
    nengine_store_set( "rex_arena", "boss_skipped", "none" );
    nengine_store_set( "rex_arena", "boss_guardian_roam", "none" );
    nengine_store_set( "rex_arena", "boss_slam_near", "none" );
    nengine_store_set( "rex_arena", "boss_slam_count", "none" );
    nengine_store_set( "rex_arena", "boss_zrex_dying_hits", "none" );
    nengine_store_set( "rex_arena", "boss_zrex_final_hit", "none" );
    nengine_store_set( "rex_arena", "boss_zrex_spawn_nocorpse", "none" );
    nengine_store_set( "rex_arena", "boss_zrex_one_hp_hits", "none" );
    nengine_store_set( "rex_arena", "boss_zrex_deathinfo", "none" );
    nengine_store_set( "rex_arena", "boss_zrex_nocorpse_clear", "none" );
    nengine_store_set( "rex_arena", "boss_zrex_lethal_held", "none" );
    nengine_store_set( "rex_arena", "boss_zrex_lethal_held_late", "none" );
    nengine_store_set( "rex_arena", "boss_zrex_dying", "none" );
    nengine_store_set( "rex_arena", "boss_zrex_immune", "none" );
    nengine_store_set( "rex_arena", "boss_zrex_immune_cut", "none" );
    level.ra_zi_n = 0;
    level.ra_zi_cut = 0;
    level.ra_zi_t = undefined;
    nengine_store_set( "rex_arena", "boss_zrex_death", "none" );
    nengine_store_set( "rex_arena", "boss_guardian_death", "none" );
    nengine_store_set( "rex_arena", "boss_bar2", "hidden" );
    nengine_store_set( "rex_arena", "boss_bar_feed", "game" );
    nengine_store_set( "rex_arena", "boss_bar2_ui", "none" );
    nengine_store_set( "rex_arena", "boss_bar_down", "none" );
}

function ra_sp_clear_round()
{
    level.ra_sp_i = 0;
    while ( level.ra_sp_i < 3 )
    {
        level.ra_sp_ph[ 1 ][ level.ra_sp_i ] = 0;
        level.ra_sp_ph[ 2 ][ level.ra_sp_i ] = 0;
        level.ra_sp_open[ level.ra_sp_i ] = 0;
        level.ra_sp_i++;
    }
}

function ra_sp_next( tier )
{
    if ( level.ra_sp_q[ tier ].size == 0 )
    {
        level.ra_sp_src = level.ra_sp_pool[ tier ];
        level.ra_sp_i = 0;
        while ( level.ra_sp_i < level.ra_sp_src.size )
        {
            level.ra_sp_t = level.ra_sp_src[ level.ra_sp_i ];
            if ( !isdefined( level.ra_sp_bad[ level.ra_sp_t ] ) )
            {
                level.ra_sp_j = randomint( level.ra_sp_q[ tier ].size + 1 );
                level.ra_sp_q[ tier ][ level.ra_sp_q[ tier ].size ] = level.ra_sp_q[ tier ][ level.ra_sp_j ];
                level.ra_sp_q[ tier ][ level.ra_sp_j ] = level.ra_sp_t;
            }
            level.ra_sp_i++;
        }
    }
    if ( level.ra_sp_q[ tier ].size == 0 )
        return undefined;
    level.ra_sp_t = level.ra_sp_q[ tier ][ level.ra_sp_q[ tier ].size - 1 ];
    level.ra_sp_q[ tier ][ level.ra_sp_q[ tier ].size - 1 ] = undefined;
    return level.ra_sp_t;
}

function ra_sp_count_alive()
{
    level.ra_sp_live = 0;
    level.ra_sp_live_t[ 0 ] = 0;
    level.ra_sp_live_t[ 1 ] = 0;
    level.ra_sp_live_t[ 2 ] = 0;
    level.ra_sp_live_t[ 3 ] = 0;
    level.ra_sp_ais = getaiarray( namespace_a1db93989e602280::function_bd2c15d9f0354e97() );
    level.ra_sp_k = 0;
    while ( level.ra_sp_k < level.ra_sp_ais.size )
    {
        if ( isdefined( level.ra_sp_ais[ level.ra_sp_k ] ) && isalive( level.ra_sp_ais[ level.ra_sp_k ] ) && isdefined( level.ra_sp_ais[ level.ra_sp_k ].ra_sp_tier ) )
        {
            level.ra_sp_live++;
            level.ra_sp_live_t[ level.ra_sp_ais[ level.ra_sp_k ].ra_sp_tier ]++;
        }
        level.ra_sp_k++;
    }
    level.ra_sp_ais = undefined;
}

// Returns true when one enemy was made. level.ra_sp_fail says why not.
function ra_sp_spawn( tier )
{
    level.ra_sp_fail = undefined;
    level.ra_sp_try = 0;
    while ( level.ra_sp_try < 40 )
    {
        level.ra_sp_try++;
        level.ra_sp_type = ra_sp_next( tier );
        if ( !isdefined( level.ra_sp_type ) )
        {
            level.ra_sp_fail = "no_loaded_types";
            return false;
        }
        level.ra_sp_loc = namespace_b0c5a0220f5772db::function_6776c0f9111aaf8f( "zombie_base", undefined, 1 );
        if ( !isdefined( level.ra_sp_loc ) || !isdefined( level.ra_sp_loc.origin ) )
        {
            // The type was not tried; put it back for the next attempt.
            level.ra_sp_q[ tier ][ level.ra_sp_q[ tier ].size ] = level.ra_sp_type;
            level.ra_sp_fail = "no_spawn_location";
            return false;
        }
        level.ra_sp_yaw = 0;
        if ( isdefined( level.players ) && level.players.size > 0 && isdefined( level.players[ 0 ] ) )
        {
            level.ra_sp_ang = vectortoangles( level.players[ 0 ].origin - level.ra_sp_loc.origin );
            level.ra_sp_yaw = level.ra_sp_ang[ 1 ];
        }
        level.ra_sp_ai = namespace_c92d17df4cbfb50f::function_1fd1c42a28e8b763( level.ra_sp_type, level.ra_sp_loc.origin, ( 0, level.ra_sp_yaw, 0 ) );
        if ( isdefined( level.ra_sp_ai ) )
        {
            // Counts toward the round (must kill); the game's own
            // round-timeout cleanup would re-queue it as a normal zombie, so
            // it keeps opting out and ra_sp_watch handles stuck ones.
            level.ra_sp_ai.ignore_enemy_count = 0;
            level.ra_sp_ai.b_ignore_round_timeout_cleanup = 1;
            level.ra_sp_ai.ra_sp_tier = tier;
            level.ra_sp_ai.ra_sp_type = level.ra_sp_type;
            level.ra_sp_ai.ra_sp_seen = function_83bf4b34fbbe124b();
            if ( !isdefined( level.ra_sp_made[ level.ra_sp_type ] ) )
                level.ra_sp_made[ level.ra_sp_type ] = 0;
            level.ra_sp_made[ level.ra_sp_type ]++;
            level.ra_sp_total++;
            nengine_store_set( "rex_arena", "sp_" + level.ra_sp_type, level.ra_sp_made[ level.ra_sp_type ] );
            nengine_store_set( "rex_arena", "specials_total", level.ra_sp_total );
            nengine_store_set( "rex_arena", "specials_last", level.ra_sp_type );
            nengine_store_set( "rex_arena", "specials_last_pool", tier );
            nengine_store_set( "rex_arena", "specials_last_position", level.ra_sp_loc.origin );
            level.ra_sp_ai = undefined;
            return true;
        }
        level.ra_sp_bad[ level.ra_sp_type ] = 1;
        level.ra_sp_not_loaded++;
        nengine_store_set( "rex_arena", "sp_" + level.ra_sp_type, "not_loaded" );
        nengine_store_set( "rex_arena", "specials_not_loaded", level.ra_sp_not_loaded );
        wait 0.2;
    }
    level.ra_sp_fail = "too_many_attempts";
    return false;
}

// Number owed this round by pool: first round, rounds per step, most.
// Native zombies of this round still to kill: not yet spawned, waiting in the
// respawn queue, or alive and counted by the game. Ours are left out. Returns
// undefined when the round logic's fields are missing.
function ra_sp_native_left()
{
    level.ra_sp_sample = undefined;
    level.ra_sp_rl = level.var_a009ab14ee0d3223;
    if ( !isdefined( level.ra_sp_rl ) || !isdefined( level.ra_sp_rl.var_5c8829ccd69f3862 ) || !isdefined( level.ra_sp_rl.var_939db9ccafac43a7 ) )
    {
        level.ra_sp_rl = undefined;
        return undefined;
    }
    level.ra_sp_total_r = level.ra_sp_rl.var_5c8829ccd69f3862;
    level.ra_sp_left = level.ra_sp_total_r - level.ra_sp_rl.var_939db9ccafac43a7.size;
    if ( level.ra_sp_left < 0 )
        level.ra_sp_left = 0;
    level.ra_sp_queue = 0;
    if ( isdefined( level.var_f4f8c9a351eaab32 ) && isdefined( level.var_f4f8c9a351eaab32.var_e722b24f3444e929 ) )
        level.ra_sp_queue = level.var_f4f8c9a351eaab32.var_e722b24f3444e929.size;
    level.ra_sp_left += level.ra_sp_queue;
    level.ra_sp_cnt = namespace_ea0d69869863f098::function_45bd2c072cb4631a();
    level.ra_sp_counted = level.ra_sp_cnt.size;
    level.ra_sp_k = 0;
    while ( level.ra_sp_k < level.ra_sp_cnt.size )
    {
        if ( isdefined( level.ra_sp_cnt[ level.ra_sp_k ] ) && !isdefined( level.ra_sp_cnt[ level.ra_sp_k ].ra_sp_tier ) )
        {
            level.ra_sp_left++;
            if ( !isdefined( level.ra_sp_sample ) )
                level.ra_sp_sample = level.ra_sp_cnt[ level.ra_sp_k ];
        }
        level.ra_sp_k++;
    }
    level.ra_sp_cnt = undefined;
    level.ra_sp_rl = undefined;
    return level.ra_sp_left;
}

// Once a second: record each new one's health, and kill one that has not been
// hurt and has had no player within 1200 units for 90 s (a boss: 300 s), so a
// stuck one cannot hold the round open for ever. 1.0: no HVT 2.5x rule.
function ra_sp_watch()
{
    level.ra_sp_ais = getaiarray( namespace_a1db93989e602280::function_bd2c15d9f0354e97() );
    level.ra_sp_k = 0;
    while ( level.ra_sp_k < level.ra_sp_ais.size )
    {
        level.ra_sp_x = level.ra_sp_ais[ level.ra_sp_k ];
        if ( isdefined( level.ra_sp_x ) && isalive( level.ra_sp_x ) && isdefined( level.ra_sp_x.ra_sp_tier ) )
        {
            if ( !isdefined( level.ra_sp_x.ra_sp_hp ) )
            {
                nengine_store_set( "rex_arena", "hp_" + level.ra_sp_x.ra_sp_type, "round " + level.ra_sp_round + ": " + level.ra_sp_x.health + " (max " + level.ra_sp_x.maxhealth + ")" );
                if ( level.ra_sp_x.ra_sp_tier == 0 && isdefined( level.ra_sp_x.maxhealth ) )
                {
                    level.ra_sp_seen_hp[ level.ra_sp_x.ra_sp_type ] = level.ra_sp_x.maxhealth;
                    level.ra_sp_seen_round[ level.ra_sp_x.ra_sp_type ] = level.ra_sp_round;
                }
                level.ra_sp_x.ra_sp_hp = level.ra_sp_x.health;
                level.ra_sp_dirty = 1;
            }
            if ( level.ra_sp_x.health < level.ra_sp_x.ra_sp_hp )
                level.ra_sp_x.ra_sp_seen = level.ra_sp_now;
            level.ra_sp_x.ra_sp_hp = level.ra_sp_x.health;
            if ( isdefined( level.players ) )
            {
                level.ra_sp_p = 0;
                while ( level.ra_sp_p < level.players.size )
                {
                    if ( isdefined( level.players[ level.ra_sp_p ] ) && isalive( level.players[ level.ra_sp_p ] ) && distancesquared( level.players[ level.ra_sp_p ].origin, level.ra_sp_x.origin ) < 1440000 )
                        level.ra_sp_x.ra_sp_seen = level.ra_sp_now;
                    level.ra_sp_p++;
                }
            }
            if ( level.ra_sp_now - level.ra_sp_x.ra_sp_seen > ( level.ra_sp_x.ra_sp_tier == 3 ? 300000 : 90000 ) )
            {
                level.ra_sp_stuck++;
                nengine_store_set( "rex_arena", "sp_stuck_removed", level.ra_sp_stuck );
                nengine_store_set( "rex_arena", "sp_stuck_last", level.ra_sp_x.ra_sp_type + " at " + level.ra_sp_x.origin );
                level.ra_sp_dirty = 1;
                level.ra_sp_x kill();
            }
        }
        level.ra_sp_k++;
    }
    level.ra_sp_x = undefined;
    level.ra_sp_ais = undefined;
}

function ra_sp_new_round()
{
    level.ra_sp_round = level.var_6781718da4f78d1c.roundnumber;
    if ( istrue( level.ra_pt_on ) )
        ra_prepare_timer_stop( "round " + level.ra_sp_round + " began first" );
    ra_sp_clear_round();
    // 1.0: no extra specials, elites or HVTs (user: "we should revert the
    // zombie type rules"); a round's zombies are Rex's own. The loop still
    // tracks the round, starts the boss events and nudges a stalled round end.
    level.ra_sp_due[ 0 ] = 0;
    level.ra_sp_due[ 1 ] = 0;
    level.ra_sp_due[ 2 ] = 0;
    // Deal HVTs, then elites, to start, end, middle, start, end, middle, ...
    level.ra_sp_deal = [];
    level.ra_sp_deal[ 0 ] = 0;
    level.ra_sp_deal[ 1 ] = 2;
    level.ra_sp_deal[ 2 ] = 1;
    level.ra_sp_d = 0;
    level.ra_sp_i = 0;
    while ( level.ra_sp_i < level.ra_sp_due[ 2 ] )
    {
        level.ra_sp_ph[ 2 ][ level.ra_sp_deal[ level.ra_sp_d % 3 ] ]++;
        level.ra_sp_d++;
        level.ra_sp_i++;
    }
    level.ra_sp_i = 0;
    while ( level.ra_sp_i < level.ra_sp_due[ 1 ] )
    {
        level.ra_sp_ph[ 1 ][ level.ra_sp_deal[ level.ra_sp_d % 3 ] ]++;
        level.ra_sp_d++;
        level.ra_sp_i++;
    }
    level.ra_sp_start_t = level.ra_sp_now + 6000;
    level.ra_sp_next_t = level.ra_sp_now + 15000;
    level.ra_sp_burst_t = level.ra_sp_start_t;
    level.ra_sp_stall_t = undefined;
    level.ra_sp_hp_round = undefined;
    // The boss event owed this round: the latest one reached. An earlier
    // owed event that a round skip passed over is dropped (skipping to round
    // 100 makes both bosses, not the round-75 Guardian first).
    // 0.5.81: the latest by round, not by place in the list (Caltheris,
    // event 3, is now at 100, before Z-Rex and the Guardian, event 2, at 255).
    level.ra_boss_due = -1;
    level.ra_boss_i = 0;
    while ( level.ra_boss_i <= 5 )
    {
        if ( !level.ra_boss_done[ level.ra_boss_i ] && level.ra_sp_round >= level.ra_boss_round[ level.ra_boss_i ] )
        {
            if ( level.ra_boss_due < 0 )
                level.ra_boss_due = level.ra_boss_i;
            else if ( level.ra_boss_round[ level.ra_boss_i ] > level.ra_boss_round[ level.ra_boss_due ] )
            {
                level.ra_boss_done[ level.ra_boss_due ] = 1;
                nengine_store_set( "rex_arena", "boss_skipped", level.ra_boss_type[ level.ra_boss_due ] + " (round " + level.ra_boss_round[ level.ra_boss_due ] + ") passed over in round " + level.ra_sp_round );
                level.ra_boss_due = level.ra_boss_i;
            }
            else
            {
                level.ra_boss_done[ level.ra_boss_i ] = 1;
                nengine_store_set( "rex_arena", "boss_skipped", level.ra_boss_type[ level.ra_boss_i ] + " (round " + level.ra_boss_round[ level.ra_boss_i ] + ") passed over in round " + level.ra_sp_round );
            }
        }
        level.ra_boss_i++;
    }
    // 0.5.80: a round that owes a boss event is a boss round (no T.E.D.D.).
    if ( level.ra_boss_due >= 0 )
        level.ra_td_boss_round = level.ra_sp_round;
    level.ra_boss_tries = 0;
    level.ra_boss_t = level.ra_sp_start_t;
    nengine_store_set( "rex_arena", "boss_round_plan", level.ra_boss_due >= 0 ? level.ra_boss_type[ level.ra_boss_due ] : "none" );
    nengine_store_set( "rex_arena", "specials_round", level.ra_sp_round );
    nengine_store_set( "rex_arena", "specials_round_plan", "" + level.ra_sp_due[ 0 ] + " specials; elites " + level.ra_sp_ph[ 1 ][ 0 ] + "/" + level.ra_sp_ph[ 1 ][ 1 ] + "/" + level.ra_sp_ph[ 1 ][ 2 ] + ", hvts " + level.ra_sp_ph[ 2 ][ 0 ] + "/" + level.ra_sp_ph[ 2 ][ 1 ] + "/" + level.ra_sp_ph[ 2 ][ 2 ] + " (start/middle/end)" );
    nengine_store_set( "rex_arena", "specials_phase", "waiting" );
    level.ra_sp_dirty = 1;
}

function ra_sp_open_phase( phase, name )
{
    if ( level.ra_sp_open[ phase ] )
        return;
    level.ra_sp_open[ phase ] = 1;
    if ( level.ra_sp_burst_t > level.ra_sp_now )
        level.ra_sp_burst_t = level.ra_sp_now;
    nengine_store_set( "rex_arena", "specials_phase", name );
    if ( isdefined( level.ra_sp_left_now ) )
        nengine_store_set( "rex_arena", "specials_phase_" + name + "_left", level.ra_sp_left_now );
    level.ra_sp_dirty = 1;
}

// The earliest open wave that still owes this pool one, or -1.
function ra_sp_owed_phase( tier )
{
    level.ra_sp_pp = 0;
    while ( level.ra_sp_pp < 3 )
    {
        if ( level.ra_sp_open[ level.ra_sp_pp ] && level.ra_sp_ph[ tier ][ level.ra_sp_pp ] > 0 )
            return level.ra_sp_pp;
        level.ra_sp_pp++;
    }
    return -1;
}

function ra_specials_manager()
{
    level endon( #"game_ended" );
    if ( !ra_selected() )
        return;
    ra_sp_roster();
    nengine_store_set( "rex_arena", "specials", "waiting_for_start" );
    nengine_store_set( "rex_arena", "specials_types", level.ra_sp_pool[ 0 ].size + level.ra_sp_pool[ 1 ].size + level.ra_sp_pool[ 2 ].size );
    nengine_store_save( "rex_arena", "runtime" );
    while ( !level namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( "begin_round_logic" ) )
        wait 0.5;
    level.ra_sp_round = 0;
    level.ra_sp_next_t = 0;
    level.ra_sp_burst_t = 0;
    level.ra_sp_start_t = 0;
    level.ra_sp_watch_t = 0;
    level.ra_sp_dirty = 0;
    nengine_store_set( "rex_arena", "specials", "watching_rounds" );
    nengine_store_save( "rex_arena", "runtime" );
    while ( true )
    {
        wait 0.25;
        if ( level.ra_sp_dirty )
        {
            level.ra_sp_dirty = 0;
            nengine_store_save( "rex_arena", "runtime" );
        }
        if ( !isdefined( level.var_6781718da4f78d1c ) || !isdefined( level.var_6781718da4f78d1c.roundnumber ) )
            continue;
        level.ra_sp_now = function_83bf4b34fbbe124b();
        if ( level.var_6781718da4f78d1c.roundnumber != level.ra_sp_round )
            ra_sp_new_round();
        if ( level.ra_sp_now >= level.ra_sp_watch_t )
        {
            level.ra_sp_watch_t = level.ra_sp_now + 1000;
            ra_sp_watch();
        }
        ra_sp_count_alive();
        level.ra_sp_left_now = ra_sp_native_left();

        // Waves.
        if ( level.ra_sp_now >= level.ra_sp_start_t )
        {
            ra_sp_open_phase( 0, "start" );
            if ( !isdefined( level.ra_sp_left_now ) )
            {
                if ( !isdefined( level.ra_sp_fallback ) )
                {
                    level.ra_sp_fallback = 1;
                    nengine_store_set( "rex_arena", "specials_phase_problem", "no_round_counts_all_waves_at_start" );
                }
                ra_sp_open_phase( 1, "middle" );
                ra_sp_open_phase( 2, "end" );
            }
            else if ( isdefined( level.var_a009ab14ee0d3223.var_18808f3521d4cfb3 ) && level.var_a009ab14ee0d3223.var_18808f3521d4cfb3 == 1 )
            {
                level.ra_sp_endn = int( level.ra_sp_total_r / 8 );
                if ( level.ra_sp_endn < 3 )
                    level.ra_sp_endn = 3;
                if ( level.ra_sp_left_now * 2 <= level.ra_sp_total_r )
                {
                    ra_sp_open_phase( 1, "middle" );
                    if ( !isdefined( level.ra_sp_hp_round ) && isdefined( level.ra_sp_sample ) )
                    {
                        level.ra_sp_hp_round = 1;
                        nengine_store_set( "rex_arena", "hp_zombie", "round " + level.ra_sp_round + ": " + level.ra_sp_sample.health + " (max " + level.ra_sp_sample.maxhealth + ")" );
                        nengine_store_set( "rex_arena", "round_zombies_" + level.ra_sp_round, level.ra_sp_total_r );
                    }
                }
                if ( level.ra_sp_left_now <= level.ra_sp_endn )
                {
                    ra_sp_open_phase( 1, "middle" );
                    ra_sp_open_phase( 2, "end" );
                    if ( level.ra_sp_due[ 0 ] > 0 && level.ra_sp_next_t > level.ra_sp_now )
                        level.ra_sp_next_t = level.ra_sp_now;
                }
            }
        }

        // The round has nothing left but stays open: run the game's own
        // round-end check once more.
        level.ra_sp_stalled = 0;
        if ( isdefined( level.ra_sp_left_now ) && level.ra_sp_left_now == 0 && level.ra_sp_live == 0 && level.ra_sp_counted == 0 && level.ra_sp_queue == 0 )
        {
            if ( isdefined( level.var_a009ab14ee0d3223.var_18808f3521d4cfb3 ) && level.var_a009ab14ee0d3223.var_18808f3521d4cfb3 == 1 && isdefined( level.var_a009ab14ee0d3223.var_59c4f3931d764b9c ) && level.var_a009ab14ee0d3223.var_59c4f3931d764b9c )
                level.ra_sp_stalled = 1;
        }
        if ( !level.ra_sp_stalled )
            level.ra_sp_stall_t = undefined;
        else if ( !isdefined( level.ra_sp_stall_t ) )
            level.ra_sp_stall_t = level.ra_sp_now + 3000;
        else if ( level.ra_sp_now >= level.ra_sp_stall_t )
        {
            level.ra_sp_stall_t = level.ra_sp_now + 3000;
            level.ra_sp_nudges++;
            nengine_store_set( "rex_arena", "round_end_nudges", level.ra_sp_nudges );
            nengine_store_set( "rex_arena", "round_end_nudge_round", level.ra_sp_round );
            level.ra_sp_dirty = 1;
            level namespace_ea0d69869863f098::function_1451667b00ffb21d( undefined );
        }

        // The round's boss, with the start wave. Five tries, five seconds apart;
        // a boss that could not be made is owed again next round.
        if ( level.ra_boss_due >= 0 && level.ra_sp_now >= level.ra_sp_start_t && level.ra_sp_now >= level.ra_boss_t )
        {
            // 0.6.6: Boss Rush's prepare timer first, once per round and event
            if ( !isdefined( level.ra_pt_round ) || level.ra_pt_round != level.ra_sp_round || level.ra_pt_event != level.ra_boss_due )
            {
                ra_prepare_timer_start( level.ra_boss_due );
                level.ra_sp_dirty = 1;
                continue;
            }
            if ( istrue( level.ra_pt_on ) )
                ra_prepare_timer_stop( "over" );
            if ( ra_boss_event( level.ra_boss_due ) )
            {
                level.ra_boss_done[ level.ra_boss_due ] = 1;
                // 0.5.93: watch for the fight to be complete
                level thread ra_void_claw_fight( level.ra_boss_due );
                level.ra_boss_due = -1;
            }
            else
            {
                level.ra_boss_tries++;
                level.ra_boss_t = level.ra_sp_now + 5000;
                if ( level.ra_boss_tries >= 5 )
                    level.ra_boss_due = -1;
            }
            level.ra_sp_dirty = 1;
            continue;
        }

        // 0.6.7: no specials during the prepare timer
        if ( istrue( level.ra_pt_on ) )
            continue;
        if ( level.ra_sp_live >= 8 )
            continue;

        // Elites and HVTs of the open waves, HVTs first, one every 1.5 s.
        if ( level.ra_sp_now >= level.ra_sp_burst_t )
        {
            level.ra_sp_tier = -1;
            level.ra_sp_t2 = 2;
            while ( level.ra_sp_t2 >= 1 && level.ra_sp_tier < 0 )
            {
                if ( level.ra_sp_live_t[ level.ra_sp_t2 ] < level.ra_sp_cap[ level.ra_sp_t2 ] && ra_sp_owed_phase( level.ra_sp_t2 ) >= 0 )
                    level.ra_sp_tier = level.ra_sp_t2;
                level.ra_sp_t2--;
            }
            if ( level.ra_sp_tier >= 0 )
            {
                level.ra_sp_wave = ra_sp_owed_phase( level.ra_sp_tier );
                if ( ra_sp_spawn( level.ra_sp_tier ) )
                {
                    level.ra_sp_ph[ level.ra_sp_tier ][ level.ra_sp_wave ]--;
                    level.ra_sp_due[ level.ra_sp_tier ]--;
                    nengine_store_set( "rex_arena", "specials", "spawning" );
                    level.ra_sp_burst_t = level.ra_sp_now + 1500;
                }
                else
                {
                    nengine_store_set( "rex_arena", "specials_last_problem", level.ra_sp_fail );
                    if ( level.ra_sp_fail == "no_loaded_types" )
                    {
                        level.ra_sp_ph[ level.ra_sp_tier ][ 0 ] = 0;
                        level.ra_sp_ph[ level.ra_sp_tier ][ 1 ] = 0;
                        level.ra_sp_ph[ level.ra_sp_tier ][ 2 ] = 0;
                        level.ra_sp_due[ level.ra_sp_tier ] = 0;
                    }
                    level.ra_sp_burst_t = level.ra_sp_now + 3000;
                }
                level.ra_sp_dirty = 1;
                continue;
            }
        }

        // Specials: 10-20 s apart, every 1.5 s once the end wave is open.
        if ( level.ra_sp_due[ 0 ] > 0 && level.ra_sp_now >= level.ra_sp_next_t && level.ra_sp_live_t[ 0 ] < level.ra_sp_cap[ 0 ] )
        {
            if ( ra_sp_spawn( 0 ) )
            {
                level.ra_sp_due[ 0 ]--;
                nengine_store_set( "rex_arena", "specials", "spawning" );
                if ( level.ra_sp_open[ 2 ] )
                    level.ra_sp_next_t = level.ra_sp_now + 1500;
                else
                    level.ra_sp_next_t = level.ra_sp_now + 10000 + randomint( 10001 );
            }
            else
            {
                nengine_store_set( "rex_arena", "specials_last_problem", level.ra_sp_fail );
                if ( level.ra_sp_fail == "no_loaded_types" )
                    level.ra_sp_due[ 0 ] = 0;
                level.ra_sp_next_t = level.ra_sp_now + 3000;
            }
            level.ra_sp_dirty = 1;
        }
    }
}

// Z-Rex (0) or the Guardian (1), made as Rex's boss script
// (script_6c1f17f235760ccc) makes them: the ZM agent spawner with the type's
// own name. They are made in the middle of the arena, at Rex's own marker
// boss_arena_ff_center (the octagon). Z-Rex also gets that script's centre
// and radius for its fight (the two fields
// namespace_2823e49aa0908abb::function_9f1707d1a108b8e4 sets, 900 squared),
// which lie towards the west wall.
// The other per-boss fields and callbacks of that script are not set. Both are
// must-kill and keep the game's health.
// 0.5.17: 2 is Caltheris (Rex makes it the same way, type
// sat_spawner_zombie_neptune_zm); it keeps the game's health too.
function ra_boss_spawn( index, origin )
{
    level.ra_boss_name = index == 0 ? "boss_zrex" : ( index == 1 ? "boss_guardian" : ( index == 2 ? "boss_caltheris" : "boss_weyward" ) );
    level.ra_boss_origin = origin;
    level.ra_boss_yaw = 0;
    if ( isdefined( level.players ) && level.players.size > 0 && isdefined( level.players[ 0 ] ) )
    {
        level.ra_boss_ang = vectortoangles( level.players[ 0 ].origin - level.ra_boss_origin );
        level.ra_boss_yaw = level.ra_boss_ang[ 1 ];
    }
    if ( isdefined( level.ra_boss_spawn_yaw ) )
    {
        level.ra_boss_yaw = level.ra_boss_spawn_yaw;
        level.ra_boss_spawn_yaw = undefined;
    }
    nengine_store_set( "rex_arena", level.ra_boss_name, "spawning in round " + level.ra_sp_round );
    nengine_store_save( "rex_arena", "runtime" );
    level.ra_boss_ai = namespace_c92d17df4cbfb50f::function_1fd1c42a28e8b763( level.ra_boss_spawner[ index ], level.ra_boss_origin, ( 0, level.ra_boss_yaw, 0 ) );
    // 0.5.33: the Weyward: Rex's fight makes it with a 14-character name, by
    // length "zombie_weyward"; tried when the spawner name makes nothing.
    if ( !isdefined( level.ra_boss_ai ) && index == 3 && level.ra_boss_spawner[ 3 ] != "zombie_weyward" )
    {
        level.ra_boss_ai = namespace_c92d17df4cbfb50f::function_1fd1c42a28e8b763( "zombie_weyward", level.ra_boss_origin, ( 0, level.ra_boss_yaw, 0 ) );
        nengine_store_set( "rex_arena", "boss_weyward_spawner", level.ra_boss_spawner[ 3 ] + " made nothing; zombie_weyward " + ( isdefined( level.ra_boss_ai ) ? "made it" : "made nothing" ) );
        if ( isdefined( level.ra_boss_ai ) )
            level.ra_boss_spawner[ 3 ] = "zombie_weyward";
    }
    if ( !isdefined( level.ra_boss_ai ) )
    {
        nengine_store_set( "rex_arena", level.ra_boss_name, "not_made in round " + level.ra_sp_round );
        return false;
    }
    level.ra_boss_ai.ignore_enemy_count = 0;
    level.ra_boss_ai.b_ignore_round_timeout_cleanup = 1;
    level.ra_boss_ai.ra_sp_tier = 3;
    level.ra_boss_ai.ra_boss_index = index;
    level.ra_boss_ai.ra_sp_type = level.ra_boss_spawner[ index ];
    level.ra_boss_ai.ra_sp_seen = function_83bf4b34fbbe124b();
    // 0.5.26: a remade boss gets its kept health before any bar is shown (the
    // game's bar call writes the health it has then).
    if ( isdefined( level.ra_spawn_hp ) )
    {
        if ( level.ra_boss_ai.health > level.ra_spawn_hp )
            level.ra_boss_ai.health = level.ra_spawn_hp;
        level.ra_spawn_hp = undefined;
    }
    level.ra_made_t[ index ] = function_83bf4b34fbbe124b();
    level.ra_held[ index ] = 0;
    level.ra_bar_ev++;
    if ( index == 0 )
    {
        level.ra_boss_ai.var_c0c42bbd970e30ee = ( 27840, -27411, 2162 );
        level.ra_boss_ai.var_a6a2972d94e39973 = 810000;
        level.ra_boss_ai.var_c773552bfe348b9a = 1;
        level.ra_zrex_ai = level.ra_boss_ai;
    }
    // no damage from this mod's other bosses (ra_boss_damage)
    level.ra_boss_ai namespace_56fb43fc0b6ee43e::function_dfae6a5bd222c586( &ra_boss_damage );
    if ( !isdefined( level.ra_bar_keeper ) )
    {
        level.ra_bar_keeper = 1;
        level thread ra_boss_bar_keeper();
        level thread ra_boss_guard();
    }
    level.ra_g_ai[ index ] = level.ra_boss_ai;
    level.ra_g_hp[ index ] = level.ra_boss_ai.health;
    level.ra_g_max[ index ] = level.ra_boss_ai.maxhealth;
    level.ra_g_org[ index ] = level.ra_boss_ai.origin;
    level.ra_g_ang[ index ] = level.ra_boss_ai.angles;
    if ( index == 0 )
        level.ra_zrex_nc = 0;
    level.ra_g_on[ index ] = 1;
    if ( index == 0 )
    {
        level.ra_zrex_hide_done = 0;
        level.ra_zl_t = undefined;
        nengine_store_set( "rex_arena", "boss_zrex_spawn_nocorpse", "round " + level.ra_sp_round + ": nocorpse at spawn " + ( isdefined( level.ra_boss_ai.nocorpse ) ? level.ra_boss_ai.nocorpse : "unset" ) + " (left alone)" );
        if ( !isdefined( level.ra_late_hold ) )
        {
            level.ra_late_hold = 1;
            level callback::add( "on_zombie_ai_damaged", &ra_zrex_hold_late );
        }
        // The same entity-level death event Rex uses for Z-Rex.
        level.ra_boss_ai namespace_42ffbe510c7bd5b1::function_3e93ae4f7823fe81( "on_zombie_ai_killed", &ra_zrex_slam_hide );
        level.ra_boss_ai thread ra_zrex_chase();
    }
    if ( index == 1 )
    {
        level.ra_guardian_ai = level.ra_boss_ai;
        // 0.5.26: from the round-500 event on the Guardian is a side bar.
        if ( !level.ra_bar_h )
            level thread ra_guardian_bar_all();
        // The Guardian's AI walks it back to its spawn point when it is more
        // than 200 units away unless this is set; Rex's fight sets it to 1.
        level.ra_boss_ai.var_e30ba852102cf5a0 = 1;
        // 0.5.25: Caltheris's rock throw kill skips it (as Z-Rex since 0.5.21).
        level.ra_boss_ai.var_c773552bfe348b9a = 1;
        // 0.5.27: one-shot hold (ra_guardian_hold_late)
        if ( !isdefined( level.ra_g_late ) )
        {
            level.ra_g_late = 1;
            level callback::add( "on_zombie_ai_damaged", &ra_guardian_hold_late );
        }
        level.ra_boss_ai thread ra_guardian_roam_watch();
    }
    if ( index == 2 )
    {
        level.ra_caltheris_ai = level.ra_boss_ai;
        // 0.5.26: a remade Caltheris gets its phase before its bar is shown.
        if ( istrue( level.ra_cal_reviving ) && isdefined( level.ra_cg_keep_ph ) && isdefined( level.ra_boss_ai.var_c1a14ef3b76e22c5 ) && level.ra_boss_ai.var_c1a14ef3b76e22c5 != level.ra_cg_keep_ph )
        {
            level.ra_boss_ai.var_c1a14ef3b76e22c5 = level.ra_cg_keep_ph;
            level.ra_boss_ai ra_caltheris_phase_settings();
        }
        level.ra_cal_phase = level.ra_boss_ai.var_c1a14ef3b76e22c5;
        level.ra_boss_ai.var_8f1c21afe4877bb5 = 1;
        level.ra_boss_ai.var_474e63113b850e5d = 1;
        // 0.5.25: its own rock throw kill skips it; a shield left by a
        // Caltheris that died during it is ended and the immune bar cleared;
        // one made again keeps the per-weapon damage.
        level.ra_boss_ai.var_c773552bfe348b9a = 1;
        if ( isdefined( level.ra_cal_sh ) )
        {
            level.ra_cs_i = 0;
            while ( isdefined( level.players ) && level.ra_cs_i < level.players.size )
            {
                if ( isdefined( level.players[ level.ra_cs_i ] ) )
                    level.players[ level.ra_cs_i ] thread namespace_83b3fe93c7a4b9b4::function_e5a4de300c61a650( 0 );
                level.ra_cs_i++;
            }
        }
        level.ra_cal_sh = undefined;
        level.ra_cal_mark = 0;
        if ( !istrue( level.ra_cal_reviving ) )
        {
            level.ra_cal_wd = [];
            // 1.2.1
            level.ra_cal_any = undefined;
        }
        if ( !isdefined( level.ra_cal_late ) )
        {
            level.ra_cal_late = 1;
            level callback::add( "on_zombie_ai_damaged", &ra_caltheris_phase_late );
        }
        level.ra_boss_ai namespace_42ffbe510c7bd5b1::function_3e93ae4f7823fe81( "on_zombie_ai_killed", &ra_caltheris_death_info );
        level thread ra_caltheris_bar_all();
        level.ra_boss_ai thread ra_caltheris_roam_watch();
    }
    // 0.5.31: the Weyward (Rex's boss-fight Weyward). Caltheris's rock throw
    // kill skips it, it gets the one-shot hold (ra_weyward_hold_late), and the
    // death event Rex registers for its bosses (ra_weyward_death_info).
    if ( index == 3 )
    {
        level.ra_weyward_ai = level.ra_boss_ai;
        level.ra_w_mark = 0;
        // 0.5.33: its bar list entry, from its own bar name field (what Rex's
        // fight passes to the game's bar), found as ra_boss_bar_ids finds them.
        level.ra_wey_bar_id = undefined;
        if ( isdefined( level.ra_boss_ai.var_6f21c22a420f0038 ) )
            level.ra_wey_bar_id = function_43b5ed5a14a56573( #"hash_9c9913488ca22949", function_99ee3cf75e2291a6( %"hash_325c203c696a2b10", level.ra_boss_ai.var_6f21c22a420f0038 ) );
        if ( !isdefined( level.ra_wey_bar_id ) )
            level.ra_wey_bar_id = -1;
        nengine_store_set( "rex_arena", "boss_weyward_bar_id", "round " + level.ra_sp_round + ": bar name field " + ( isdefined( level.ra_boss_ai.var_6f21c22a420f0038 ) ? "set" : "unset" ) + ", bar list id " + level.ra_wey_bar_id );
        level.ra_boss_ai.var_c773552bfe348b9a = 1;
        if ( !isdefined( level.ra_w_late ) )
        {
            level.ra_w_late = 1;
            level callback::add( "on_zombie_ai_damaged", &ra_weyward_hold_late );
        }
        level.ra_boss_ai namespace_42ffbe510c7bd5b1::function_3e93ae4f7823fe81( "on_zombie_ai_killed", &ra_weyward_death_info );
    }
    level.ra_boss_made++;
    nengine_store_set( "rex_arena", level.ra_boss_name, "made in round " + level.ra_sp_round + " at " + level.ra_boss_ai.origin + ", health " + level.ra_boss_ai.health + " of " + level.ra_boss_ai.maxhealth );
    nengine_store_set( "rex_arena", "bosses_made", level.ra_boss_made );
    level.ra_boss_ai = undefined;
    return true;
}

// The Guardian's boss health bar. Rex's boss script shows it by calling the
// game's bar function on every player right after it makes the Guardian
// (namespace_83b3fe93c7a4b9b4::function_b0e23ac80da814d8, script_7129baf8ee832ed2),
// with this name. The function follows the boss's health and takes the bar
// down when it dies. Z-Rex's own script makes the same call for itself. These
// run on their own threads, so a fault here cannot stop the specials manager.
function ra_guardian_bar_all()
{
    level endon( #"game_ended" );
    nengine_store_set( "rex_arena", "boss_guardian_bar", "starting" );
    if ( !isdefined( level.players ) )
        return;
    level.ra_bar_i = 0;
    while ( level.ra_bar_i < level.players.size )
    {
        if ( isdefined( level.players[ level.ra_bar_i ] ) )
            level.players[ level.ra_bar_i ] ra_guardian_bar();
        level.ra_bar_i++;
    }
    nengine_store_save( "rex_arena", "runtime" );
}

function ra_guardian_bar()
{
    if ( !ra_boss_alive( level.ra_guardian_ai, 1 ) )
        return;
    if ( !isdefined( level.ra_bar_calls ) )
        level.ra_bar_calls = 0;
    nengine_store_set( "rex_arena", "boss_guardian_bar", "calling" );
    self namespace_83b3fe93c7a4b9b4::function_b0e23ac80da814d8( "zombie_triton_healthbar", level.ra_guardian_ai );
    level.ra_bar_calls++;
    level.ra_bar_ev++;
    nengine_store_set( "rex_arena", "boss_guardian_bar", "shown to " + level.ra_bar_calls );
}

// 0.5.17: Caltheris's bar, by the call Rex's boss script makes right after it
// makes Caltheris (function_752b99c3bd86b36c), with Caltheris's bar name. Own
// thread.
function ra_caltheris_bar_all()
{
    level endon( #"game_ended" );
    nengine_store_set( "rex_arena", "boss_caltheris_bar", "starting" );
    if ( !isdefined( level.players ) )
        return;
    level.ra_cbar_i = 0;
    while ( level.ra_cbar_i < level.players.size )
    {
        if ( isdefined( level.players[ level.ra_cbar_i ] ) )
            level.players[ level.ra_cbar_i ] ra_caltheris_bar();
        level.ra_cbar_i++;
    }
    nengine_store_save( "rex_arena", "runtime" );
}

function ra_caltheris_bar()
{
    if ( !ra_boss_alive( level.ra_caltheris_ai, 2 ) )
        return;
    if ( !isdefined( level.ra_cbar_calls ) )
        level.ra_cbar_calls = 0;
    self namespace_83b3fe93c7a4b9b4::function_b0e23ac80da814d8( "zombie_neptune_healthbar_3", level.ra_caltheris_ai );
    level.ra_cbar_calls++;
    level.ra_bar_ev++;
    nengine_store_set( "rex_arena", "boss_caltheris_bar", "shown to " + level.ra_cbar_calls );
}

// A player who (re)spawns while the Guardian is alive gets the bar again.
function ra_guardian_bar_later()
{
    self endon( #"disconnect" );
    self endon( #"death" );
    level endon( #"game_ended" );
    wait 3;
    self ra_guardian_bar();
}

// One boss event. 0: Z-Rex, 1: the Guardian, both in the middle of the arena
// (Rex's marker boss_arena_ff_center). 2: both together, 220 units either side
// of it, Z-Rex first. Returns true when the event is complete; a Z-Rex already
// made for event 2 is not made again on a later try.
// 0.6.6: Boss Rush's prepare timer (user: "regular boss rush has this
// prepare timer for each boss ... for z rex, the guardian and caltheris it
// should be 30 seconds, for the multi boss pedestals should be 1 minute").
// Rex's Boss Rush (script_6c1f17f235760ccc function_b55900a1d64fdc0e) shows
// the banner with these three level UI values before each boss and sets the
// first to 0 when the boss comes. The boss is made when it reaches 0:00.
function ra_prepare_timer_start( e )
{
    level.ra_pt_round = level.ra_sp_round;
    level.ra_pt_event = e;
    level.ra_pt_ms = 30000;
    if ( e == 2 || e == 4 || e == 5 )
        level.ra_pt_ms = 60000;
    level.ra_boss_t = level.ra_sp_now + level.ra_pt_ms;
    function_fa049e8e9b591c85( "ui_zm_echo_portal_timer_vis", 1 );
    function_fa049e8e9b591c85( "ui_zm_echo_portal_time", function_83bf4b34fbbe124b() + level.ra_pt_ms );
    function_fa049e8e9b591c85( "ui_zm_echo_portal_timer_string_index", function_805dab7f4398f073( &"hash_3991bf1327b7a158" ) );
    level.ra_pt_on = 1;
    level.ra_pt_n = isdefined( level.ra_pt_n ) ? level.ra_pt_n + 1 : 1;
    // 0.6.7: no zombies during the timer
    namespace_ea0d69869863f098::function_b1aacaee86092345( 1, "rex_arena_prepare" );
    level.ra_pt_paused = 1;
    level thread ra_prepare_timer_clear( level.ra_pt_n );
    level.ra_pt_text = "timer " + level.ra_pt_n + ": " + level.ra_boss_type[ e ] + " in round " + level.ra_sp_round + ", " + int( level.ra_pt_ms / 1000 ) + " s";
    nengine_store_set( "rex_arena", "prepare_timer", level.ra_pt_text + " (shown)" );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.6.7: the zombies are cleared when the timer is shown and again each second
// while it is up (one already on its way in), as the round manager's own round
// clear does (script_4e3b2b1d9542e66b function_823fb6c9844ab576: spawning
// paused, then namespace_a1db93989e602280::function_d65026d5f7ec85db).
function ra_prepare_timer_clear( n )
{
    level endon( #"game_ended" );
    level.ra_pt_sweeps = 0;
    level.ra_pt_seen = 0;
    while ( istrue( level.ra_pt_on ) && level.ra_pt_n == n )
    {
        level.ra_pt_alive = namespace_ea0d69869863f098::function_45bd2c072cb4631a();
        if ( level.ra_pt_alive.size > 0 )
        {
            level.ra_pt_sweeps++;
            level.ra_pt_seen += level.ra_pt_alive.size;
            namespace_a1db93989e602280::function_d65026d5f7ec85db();
            nengine_store_set( "rex_arena", "prepare_timer_clear", "timer " + n + ": " + level.ra_pt_sweeps + " clears, " + level.ra_pt_seen + " zombies seen, " + namespace_ea0d69869863f098::function_45bd2c072cb4631a().size + " left after the last" );
            level.ra_sp_dirty = 1;
        }
        wait 1;
    }
}

function ra_prepare_timer_stop( why )
{
    if ( istrue( level.ra_pt_paused ) )
    {
        namespace_ea0d69869863f098::function_b1aacaee86092345( 0, "rex_arena_prepare" );
        level.ra_pt_paused = 0;
    }
    function_fa049e8e9b591c85( "ui_zm_echo_portal_timer_vis", 0 );
    level.ra_pt_on = 0;
    nengine_store_set( "rex_arena", "prepare_timer", level.ra_pt_text + "; taken down: " + why );
    nengine_store_save( "rex_arena", "runtime" );
}

function ra_boss_event( event )
{
    // 0.5.82: the round-50 Z-Rex owes the Golden Armor reward
    if ( event == 0 )
    {
        if ( !ra_boss_spawn( 0, ( 29424, -27424, 2216 ) ) )
            return false;
        level.ra_zr_gold = 1;
        return true;
    }
    // 0.5.86: the round-75 Guardian owes the Ultra rarity reward
    if ( event == 1 )
    {
        if ( !ra_boss_spawn( 1, ( 29424, -27424, 2216 ) ) )
            return false;
        level.ra_gd_ultra = 1;
        return true;
    }
    if ( event == 3 )
        return ra_boss_event_cz();
    if ( event == 4 )
        return ra_boss_event_trio();
    if ( event == 5 )
        return ra_boss_event_quad();
    nengine_store_set( "rex_arena", "boss_both", "spawning in round " + level.ra_sp_round );
    if ( !level.ra_both_zrex )
    {
        if ( !ra_boss_spawn( 0, ( 29204, -27424, 2216 ) ) )
            return false;
        level.ra_both_zrex = 1;
        wait 1.5;
    }
    if ( !ra_boss_spawn( 1, ( 29644, -27424, 2216 ) ) )
        return false;
    nengine_store_set( "rex_arena", "boss_both", "made in round " + level.ra_sp_round );
    return true;
}

// 0.5.17: event 3, Z-Rex and Caltheris. 0.5.89: Caltheris alone (user, at
// round 100: "when i did caltheris, it has z rex aswell"), at the arena
// centre as events 0 and 1 make Z-Rex and the Guardian alone.
function ra_boss_event_cz()
{
    nengine_store_set( "rex_arena", "boss_caltheris_zrex", "spawning in round " + level.ra_sp_round );
    if ( !ra_boss_spawn( 2, ( 29424, -27424, 2216 ) ) )
        return false;
    // 0.5.88: the round-100 Caltheris owes the Pack-a-Punch IV reward
    level.ra_cl_pap = 1;
    nengine_store_set( "rex_arena", "boss_caltheris_zrex", "made in round " + level.ra_sp_round + " (Caltheris alone)" );
    return true;
}

// 0.5.25: event 4, Z-Rex, the Guardian and Caltheris at the three arena
// points events 0 to 3 use (Z-Rex 220 units one side of the centre, the
// Guardian at it, Caltheris 220 units the other side), 1.5 s apart. A boss
// already made for it, or one of these bosses still alive, is not made again
// on a later try. The bars go into a row (ra_boss_bar_trio).
function ra_boss_event_trio()
{
    level.ra_bar_h = 1;
    if ( !isdefined( level.ra_tr_t0 ) )
        level.ra_tr_t0 = function_83bf4b34fbbe124b();
    nengine_store_set( "rex_arena", "boss_trio", "spawning in round " + level.ra_sp_round );
    if ( !level.ra_tr_z && ra_boss_alive( level.ra_zrex_ai, 0 ) )
        level.ra_tr_z = 1;
    if ( !level.ra_tr_z )
    {
        if ( !ra_boss_spawn( 0, ( 29204, -27424, 2216 ) ) )
            return false;
        level.ra_tr_z = 1;
        wait 1.5;
    }
    if ( !level.ra_tr_g && ra_boss_alive( level.ra_guardian_ai, 1 ) )
        level.ra_tr_g = 1;
    if ( !level.ra_tr_g )
    {
        if ( !ra_boss_spawn( 1, ( 29424, -27424, 2216 ) ) )
            return false;
        level.ra_tr_g = 1;
        wait 1.5;
    }
    if ( !ra_boss_alive( level.ra_caltheris_ai, 2 ) )
    {
        if ( !ra_boss_spawn( 2, ( 29644, -27424, 2216 ) ) )
            return false;
    }
    nengine_store_set( "rex_arena", "boss_trio", "made in round " + level.ra_sp_round + "; alive: Z-Rex " + ( ra_boss_alive( level.ra_zrex_ai, 0 ) ? 1 : 0 ) + ", Guardian " + ( ra_boss_alive( level.ra_guardian_ai, 1 ) ? 1 : 0 ) + ", Caltheris " + ( ra_boss_alive( level.ra_caltheris_ai, 2 ) ? 1 : 0 ) );
    nengine_store_save( "rex_arena", "runtime" );
    return true;
}

// 0.5.31: event 5, round 999: the three bosses as event 4 makes them, then
// the Weyward (boss 3) 220 units west of Z-Rex's point, 1.5 s later. On its
// first try the trio's made flags and the fight times start again. A part
// already made is not made again on a later try.
function ra_boss_event_quad()
{
    if ( !level.ra_qd_started )
    {
        level.ra_qd_started = 1;
        level.ra_tr_z = 0;
        level.ra_tr_g = 0;
        level.ra_tr_end = [];
        level.ra_tr_t0 = function_83bf4b34fbbe124b();
    }
    nengine_store_set( "rex_arena", "boss_quad", "spawning in round " + level.ra_sp_round );
    if ( !level.ra_qd_trio )
    {
        if ( !ra_boss_event_trio() )
            return false;
        level.ra_qd_trio = 1;
        wait 1.5;
    }
    if ( !ra_boss_alive( level.ra_weyward_ai, 3 ) )
    {
        if ( !ra_boss_spawn( 3, ( 28984, -27424, 2216 ) ) )
            return false;
    }
    level.ra_qd_w = 1;
    nengine_store_set( "rex_arena", "boss_quad", "made in round " + level.ra_sp_round + "; alive: Z-Rex " + ( ra_boss_alive( level.ra_zrex_ai, 0 ) ? 1 : 0 ) + ", Guardian " + ( ra_boss_alive( level.ra_guardian_ai, 1 ) ? 1 : 0 ) + ", Caltheris " + ( ra_boss_alive( level.ra_caltheris_ai, 2 ) ? 1 : 0 ) + ", Weyward " + ( ra_boss_alive( level.ra_weyward_ai, 3 ) ? 1 : 0 ) );
    nengine_store_save( "rex_arena", "runtime" );
    return true;
}

// The damage callback of each boss. The game calls it for every hit on that
// boss with the hit's record (var_917e21c98d80255e is the attacker,
// var_a87b62c261a8d114 the damage) and uses a returned value of 0 or more as
// the damage. A hit by another of this mod's bosses does nothing; every other
// hit is left as it is (-1).
function ra_boss_damage( params )
{
    if ( isdefined( params ) && isdefined( params.var_917e21c98d80255e ) && isdefined( params.var_917e21c98d80255e.ra_sp_tier ) && params.var_917e21c98d80255e.ra_sp_tier == 3 && params.var_917e21c98d80255e != self )
    {
        level.ra_boss_blocked++;
        if ( level.ra_boss_blocked == 1 || level.ra_boss_blocked % 50 == 0 )
        {
            nengine_store_set( "rex_arena", "boss_damage_blocked", level.ra_boss_blocked );
            if ( level.ra_boss_blocked == 1 )
                nengine_store_save( "rex_arena", "runtime" );
        }
        return 0;
    }
    // 0.5.28: player hits per boss (ra_boss_hit_frame).
    if ( isdefined( self.ra_boss_index ) && isdefined( params ) && isdefined( params.var_917e21c98d80255e ) )
        self ra_boss_hit_frame( params );
    // 0.5.21: Caltheris: note the hit's damage for ra_caltheris_phase_late.
    // 0.5.22: no damage during the phase shield; per weapon, the last phase-1
    // damage; in a later phase a hit under a tenth of it gets it back.
    if ( isdefined( self.ra_boss_index ) && self.ra_boss_index == 2 && isdefined( params ) && isdefined( params.var_a87b62c261a8d114 ) )
    {
        if ( isdefined( level.ra_cal_sh ) )
        {
            self.ra_cal_in = 0;
            return 0;
        }
        self.ra_cal_in = params.var_a87b62c261a8d114;
        level.ra_cw_key = undefined;
        if ( isdefined( params.var_e663e01e515b27 ) && isdefined( params.var_e663e01e515b27.var_85d9eda284f364cd ) )
            level.ra_cw_key = params.var_e663e01e515b27.var_85d9eda284f364cd;
        if ( isdefined( level.ra_cw_key ) && isdefined( level.ra_cal_wd ) && isdefined( self.var_c1a14ef3b76e22c5 ) )
        {
            // 1.2.1: a weapon first used after phase 1 (no phase-1 hit of its own) takes the last phase-1 hit
            // of any weapon, so it gets the later-phase share below too (was about 2 % of its damage)
            if ( self.var_c1a14ef3b76e22c5 > 1 && !isdefined( level.ra_cal_wd[ level.ra_cw_key ] ) && isdefined( level.ra_cal_any ) )
                level.ra_cal_wd[ level.ra_cw_key ] = level.ra_cal_any;
            if ( self.var_c1a14ef3b76e22c5 <= 1 )
            {
                if ( params.var_a87b62c261a8d114 > 0 )
                {
                    level.ra_cal_wd[ level.ra_cw_key ] = params.var_a87b62c261a8d114;
                    // 1.2.1: and of any weapon, for weapons first used after phase 1
                    level.ra_cal_any = params.var_a87b62c261a8d114;
                }
            }
            // 1.1.9: phase 2 gets half of the weapon's phase-1 damage, phase 3 a quarter (user: "caltheris last 2
            // phases she is taking a lot of dmg", chose "Phase 2 half, phase 3 quarter"); 0.5.22 gave a hit under a
            // tenth all of it back. A hit the game left above that share stays as it is.
            else if ( isdefined( level.ra_cal_wd[ level.ra_cw_key ] ) && params.var_a87b62c261a8d114 < level.ra_cal_wd[ level.ra_cw_key ] * ( self.var_c1a14ef3b76e22c5 == 2 ? 0.5 : 0.25 ) )
            {
                self.ra_cal_in = level.ra_cal_wd[ level.ra_cw_key ] * ( self.var_c1a14ef3b76e22c5 == 2 ? 0.5 : 0.25 );
                level.ra_cr_n++;
                if ( level.ra_cr_n == 1 || level.ra_cr_n % 25 == 0 )
                {
                    nengine_store_set( "rex_arena", "boss_caltheris_restored", "round " + level.ra_sp_round + ": " + level.ra_cr_n + " hits brought back; last " + params.var_a87b62c261a8d114 + " to " + self.ra_cal_in + " (" + ( self.var_c1a14ef3b76e22c5 == 2 ? "half" : "a quarter" ) + " of its phase-1 " + level.ra_cal_wd[ level.ra_cw_key ] + ") in phase " + self.var_c1a14ef3b76e22c5 );
                    nengine_store_save( "rex_arena", "runtime" );
                }
                return self.ra_cal_in;
            }
        }
    }
    // 0.5.26: who hits the Guardian, and its biggest hit.
    if ( isdefined( self.ra_boss_index ) && self.ra_boss_index == 1 && isdefined( params ) && isdefined( params.var_a87b62c261a8d114 ) )
        self ra_guardian_hit_note( params );
    // 0.5.32: who hits the Weyward, from where.
    if ( isdefined( self.ra_boss_index ) && self.ra_boss_index == 3 && isdefined( params ) && isdefined( params.var_a87b62c261a8d114 ) )
        self ra_weyward_hit_note( params );
    // 0.4.4: Z-Rex's own damage callback (script_178546be025df90c), which runs
    // before this one, starts its death sequence only for a lethal hit that
    // lands while its health is at or below the hit's fraction of its max
    // health; a bigger killing blow skips it and Z-Rex dies without its death
    // animation (0.4.3: last health seen 13954 of 2400000, never held at 1).
    // A hit that would still kill this mod's Z-Rex is held at 1 health, so the
    // next hit goes through Z-Rex's own death sequence.
    if ( isdefined( self.ra_boss_index ) && self.ra_boss_index == 0 && isdefined( params ) && isdefined( params.var_a87b62c261a8d114 ) && self.health > 1 && params.var_a87b62c261a8d114 >= self.health )
    {
        if ( !isdefined( level.ra_zd_held ) )
            level.ra_zd_held = 0;
        level.ra_zd_held++;
        if ( level.ra_zrex_nc )
        {
            self thread ra_zrex_nocorpse_clear();
            level.ra_zrex_nc = 0;
            nengine_store_set( "rex_arena", "boss_zrex_corpse", "normal corpse (held at 1)" );
        }
        nengine_store_set( "rex_arena", "boss_zrex_lethal_held", "round " + level.ra_sp_round + ": hit of " + params.var_a87b62c261a8d114 + " at health " + self.health + " held at 1 (" + level.ra_zd_held + ")" );
        nengine_store_save( "rex_arena", "runtime" );
        return self.health - 1;
    }
    return -1;
}

// 0.5.28: a hit on one of this mod's bosses whose attacker is a player is
// counted for that boss, and also when it comes in the same server frame as a
// player hit on another of its bosses (one shot reaching two: splash or
// penetration). Recorded as boss_player_hits every 25 hits.
function ra_boss_hit_frame( params )
{
    level.ra_hf_p = 0;
    level.ra_hf_k = 0;
    while ( isdefined( level.players ) && level.ra_hf_k < level.players.size )
    {
        if ( isdefined( level.players[ level.ra_hf_k ] ) && level.players[ level.ra_hf_k ] == params.var_917e21c98d80255e )
            level.ra_hf_p = 1;
        level.ra_hf_k++;
    }
    if ( !level.ra_hf_p || self.ra_boss_index < 0 || self.ra_boss_index > 3 )
        return;
    level.ra_hf_t = function_83bf4b34fbbe124b();
    level.ra_hf_i = self.ra_boss_index;
    level.ra_hf_n[ level.ra_hf_i ]++;
    level.ra_hf_k = 0;
    level.ra_hf_same = 0;
    while ( level.ra_hf_k < 4 )
    {
        if ( level.ra_hf_k != level.ra_hf_i && isdefined( level.ra_hf_last[ level.ra_hf_k ] ) && level.ra_hf_last[ level.ra_hf_k ] == level.ra_hf_t )
            level.ra_hf_same = 1;
        level.ra_hf_k++;
    }
    if ( level.ra_hf_same )
        level.ra_hf_s[ level.ra_hf_i ]++;
    level.ra_hf_last[ level.ra_hf_i ] = level.ra_hf_t;
    if ( level.ra_hf_n[ level.ra_hf_i ] % 25 == 1 )
    {
        nengine_store_set( "rex_arena", "boss_player_hits", "round " + level.ra_sp_round + ": player hits (in the same frame as a hit on another boss): Z-Rex " + level.ra_hf_n[ 0 ] + " (" + level.ra_hf_s[ 0 ] + "), Guardian " + level.ra_hf_n[ 1 ] + " (" + level.ra_hf_s[ 1 ] + "), Caltheris " + level.ra_hf_n[ 2 ] + " (" + level.ra_hf_s[ 2 ] + "), Weyward " + level.ra_hf_n[ 3 ] + " (" + level.ra_hf_s[ 3 ] + ")" );
        nengine_store_save( "rex_arena", "runtime" );
    }
}

// 0.5.27: on the game's zombie-damaged event, after DellxCell's multiplier (as
// ra_zrex_hold_late): a hit that would kill this mod's Guardian above 1 health
// leaves it at 1. A held Guardian is not made again (a player's kill).
function ra_guardian_hold_late( params )
{
    if ( !isdefined( self ) || !isdefined( self.ra_boss_index ) || self.ra_boss_index != 1 || !isalive( self ) )
        return;
    if ( !isdefined( params ) || !isdefined( params.var_a87b62c261a8d114 ) || self.health <= 1 || params.var_a87b62c261a8d114 < self.health )
        return;
    level.ra_held[ 1 ] = 1;
    nengine_store_set( "rex_arena", "boss_guardian_lethal_held", "round " + level.ra_sp_round + ": hit of " + params.var_a87b62c261a8d114 + " at health " + self.health + " held at 1" );
    nengine_store_save( "rex_arena", "runtime" );
    params.var_a87b62c261a8d114 = self.health - 1;
}

// 0.5.26: a hit on the Guardian in its damage callback: by a player, one of
// this mod's bosses, something else, or nothing. Counted; the biggest kept.
function ra_guardian_hit_note( params )
{
    level.ra_gh_n++;
    level.ra_gh_who = "none";
    if ( isdefined( params.var_917e21c98d80255e ) )
    {
        level.ra_gh_who = "other";
        if ( isdefined( params.var_917e21c98d80255e.ra_boss_index ) )
            level.ra_gh_who = "boss " + params.var_917e21c98d80255e.ra_boss_index;
        level.ra_gh_i = 0;
        while ( isdefined( level.players ) && level.ra_gh_i < level.players.size )
        {
            if ( isdefined( level.players[ level.ra_gh_i ] ) && level.players[ level.ra_gh_i ] == params.var_917e21c98d80255e )
                level.ra_gh_who = "player";
            level.ra_gh_i++;
        }
    }
    if ( params.var_a87b62c261a8d114 > level.ra_gh_big )
    {
        level.ra_gh_big = params.var_a87b62c261a8d114;
        nengine_store_set( "rex_arena", "boss_guardian_big_hit", "round " + level.ra_sp_round + ": " + level.ra_gh_big + " by " + level.ra_gh_who + " at health " + self.health );
        nengine_store_save( "rex_arena", "runtime" );
    }
    if ( level.ra_gh_n == 1 || level.ra_gh_n % 50 == 0 )
        nengine_store_set( "rex_arena", "boss_guardian_hits", "round " + level.ra_sp_round + ": " + level.ra_gh_n + " hits; last " + params.var_a87b62c261a8d114 + " by " + level.ra_gh_who + " at health " + self.health );
}

// A player follows one boss's health bar at a time. Once a second, a living
// player whose followed boss is gone gets the bar of a boss that is still
// alive: 0.5.25: Caltheris first, then the Guardian. Runs on its own thread.
function ra_boss_bar_keeper()
{
    level endon( #"game_ended" );
    while ( true )
    {
        wait 1;
        level.ra_keep_g = ra_boss_alive( level.ra_guardian_ai, 1 );
        level.ra_keep_z = ra_boss_alive( level.ra_zrex_ai, 0 );
        level.ra_keep_c = ra_boss_alive( level.ra_caltheris_ai, 2 );
        if ( !level.ra_keep_g && !level.ra_keep_z && !level.ra_keep_c )
            continue;
        // 0.5.38: not while the Weyward lives (its fight has the game's bar down)
        if ( level.ra_bar_h && ra_boss_alive( level.ra_weyward_ai, 3 ) )
            continue;
        if ( !isdefined( level.players ) )
            continue;
        level.ra_keep_i = 0;
        while ( level.ra_keep_i < level.players.size )
        {
            level.ra_keep_p = level.players[ level.ra_keep_i ];
            if ( isdefined( level.ra_keep_p ) && isalive( level.ra_keep_p ) && ( !isdefined( level.ra_keep_p.var_7fa280bb4c563541 ) || !isalive( level.ra_keep_p.var_7fa280bb4c563541 ) ) )
            {
                if ( level.ra_keep_c )
                    level.ra_keep_p ra_caltheris_bar();
                else if ( level.ra_keep_g )
                    level.ra_keep_p ra_guardian_bar();
                else
                    level.ra_keep_p ra_zrex_bar();
            }
            level.ra_keep_i++;
        }
        level.ra_keep_p = undefined;
    }
}

// Z-Rex's bar, by the call its own aitype script makes for itself.
function ra_zrex_bar()
{
    if ( !ra_boss_alive( level.ra_zrex_ai, 0 ) )
        return;
    if ( !isdefined( level.ra_zbar_calls ) )
        level.ra_zbar_calls = 0;
    self namespace_83b3fe93c7a4b9b4::function_b0e23ac80da814d8( "zombie_phobos_healthbar", level.ra_zrex_ai );
    level.ra_zbar_calls++;
    level.ra_bar_ev++;
    nengine_store_set( "rex_arena", "boss_zrex_bar", "shown to " + level.ra_zbar_calls );
}

// Watches both bosses (own thread, every 0.05 s) and feeds the second bar.
function ra_boss_guard()
{
    level endon( #"game_ended" );
    while ( true )
    {
        wait 0.05;
        ra_slam_watch();
        ra_boss_guard_one( 0 );
        ra_boss_guard_one( 1 );
        ra_caltheris_guard();
        ra_weyward_guard();
        level.ra_g_pass++;
        if ( level.ra_g_pass % 3 == 0 )
            ra_boss_bar2();
    }
}

// A boss reference counts only while it is this mod's living boss: once a
// boss has died the game can hand its entity to a new enemy (0.3.6: in round
// 105 the Guardian's bar followed an Amalgam's health), so a living entity
// without the boss's mark (ra_boss_index, set in ra_boss_spawn) is not it.
function ra_boss_alive( ai, index )
{
    return isdefined( ai ) && isalive( ai ) && isdefined( ai.ra_boss_index ) && ai.ra_boss_index == index;
}

// 0.5.26: a boss may be made again unless it died within 2 s of being made
// (a remake at a place where it dies at once is not repeated). Replaces the
// 25 remakes for the whole match.
function ra_boss_can_remake( index )
{
    return !isdefined( level.ra_made_t[ index ] ) || function_83bf4b34fbbe124b() - level.ra_made_t[ index ] >= 2000;
}

// One boss. While it lives its health and place are remembered. When it is
// gone its death is written to the store. The Guardian's slam kills a
// zombie-type enemy in its inner radius with the kill builtin
// (script_670486d63d6d8151), which no damage callback sees, and the dead
// enemy's fields are gone by the next look (0.3.4 read the slam's flag as 0).
// A player's kill ends near zero health (Z-Rex's own callback holds it at 1
// for its death sequence). So a boss that dies with more than 5% of its
// health while the other boss is alive is made again at the same place with
// the health it had.
function ra_boss_guard_one( index )
{
    if ( !level.ra_g_on[ index ] )
        return;
    if ( ra_boss_alive( level.ra_g_ai[ index ], index ) )
    {
        level.ra_g_hp[ index ] = level.ra_g_ai[ index ].health;
        level.ra_g_max[ index ] = level.ra_g_ai[ index ].maxhealth;
        level.ra_g_org[ index ] = level.ra_g_ai[ index ].origin;
        level.ra_g_ang[ index ] = level.ra_g_ai[ index ].angles;
        if ( index == 0 )
        {
            ra_zrex_corpse_rule();
            ra_zrex_low_watch();
            ra_zrex_immune_watch();
        }
        return;
    }
    level.ra_g_on[ index ] = 0;
    level.ra_g_flag = 0;
    if ( isdefined( level.ra_g_ai[ index ] ) && isdefined( level.ra_g_ai[ index ].var_a472e925a028ede0 ) && level.ra_g_ai[ index ].var_a472e925a028ede0 )
        level.ra_g_flag = 1;
    level.ra_g_gone = level.ra_g_ai[ index ];
    level.ra_g_ai[ index ] = undefined;
    if ( index == 0 )
        level.ra_zrex_ai = undefined;
    else
        level.ra_guardian_ai = undefined;
    level.ra_g_other = 0;
    if ( index == 0 && ra_zrex_partner_alive() )
        level.ra_g_other = 1;
    if ( index == 1 && level.ra_g_on[ 0 ] && ra_boss_alive( level.ra_g_ai[ 0 ], 0 ) )
        level.ra_g_other = 1;
    // 0.5.25: or Caltheris
    if ( index == 1 && level.ra_g_on[ 2 ] && ra_boss_alive( level.ra_g_ai[ 2 ], 2 ) )
        level.ra_g_other = 1;
    level.ra_g_key = index == 0 ? "boss_zrex_death" : "boss_guardian_death";
    level.ra_g_text = "round " + level.ra_sp_round + ": health " + level.ra_g_hp[ index ] + " of " + level.ra_g_max[ index ] + ", direct kill flag " + level.ra_g_flag + ", other boss alive " + level.ra_g_other;
    if ( isdefined( level.ra_made_t[ index ] ) )
        level.ra_g_text = level.ra_g_text + ", " + ( function_83bf4b34fbbe124b() - level.ra_made_t[ index ] ) + " ms after it was made";
    if ( isdefined( level.ra_g_org[ index ] ) )
        level.ra_g_text = level.ra_g_text + ", at " + level.ra_g_org[ index ];
    if ( index == 0 && isdefined( level.ra_g_org[ 0 ] ) && isdefined( level.ra_g_org[ 1 ] ) )
        level.ra_g_text = level.ra_g_text + ", Guardian " + int( distance( level.ra_g_org[ 0 ], level.ra_g_org[ 1 ] ) ) + " units away";
    if ( index == 0 && isdefined( level.ra_g_org[ 0 ] ) && isdefined( level.ra_g_org[ 2 ] ) && level.ra_g_on[ 2 ] )
        level.ra_g_text = level.ra_g_text + ", Caltheris " + int( distance( level.ra_g_org[ 0 ], level.ra_g_org[ 2 ] ) ) + " units away";
    if ( index == 0 )
        level.ra_g_text = level.ra_g_text + ", slam " + ( ra_zrex_slam_logged() ? "seen inside its kill circle" : "not seen" ) + ", slam mark " + level.ra_zrex_hide_done;
    // Z-Rex (0.4.8): a death not from 1 health (a player's kill is held at 1
    // first) while a slam was seen landing inside its kill circle, or with the
    // slam's own mark on it (the death callback). The Guardian: above 5%.
    if ( level.ra_g_other && ( index == 0 ? level.ra_g_hp[ 0 ] > 1 && ( ra_zrex_slam_logged() || level.ra_zrex_hide_done ) : level.ra_g_hp[ index ] > level.ra_g_max[ index ] * 0.05 ) && ra_boss_can_remake( index ) && !istrue( level.ra_held[ index ] ) )
    {
        // If the early death callback missed it, hide only the still-identifiable
        // dead Z-Rex. Never operate on a living or recycled enemy entity.
        if ( index == 0 && !level.ra_zrex_hide_done )
        {
            if ( isdefined( level.ra_g_gone ) && !isalive( level.ra_g_gone ) && isdefined( level.ra_g_gone.ra_boss_index ) && level.ra_g_gone.ra_boss_index == 0 )
            {
                level.ra_g_gone hide();
                level.ra_zrex_hide_done = 1;
                nengine_store_set( "rex_arena", "boss_zrex_hide", "guard: hidden" );
            }
            else
                nengine_store_set( "rex_arena", "boss_zrex_hide", "guard: old entity unavailable" );
        }
        level.ra_g_keep_hp = level.ra_g_hp[ index ];
        level.ra_spawn_hp = level.ra_g_keep_hp;
        if ( isdefined( level.ra_g_ang[ index ] ) )
            level.ra_boss_spawn_yaw = level.ra_g_ang[ index ][ 1 ];
        if ( ra_boss_spawn( index, level.ra_g_org[ index ] ) )
        {
            if ( level.ra_g_ai[ index ].health > level.ra_g_keep_hp )
                level.ra_g_ai[ index ].health = level.ra_g_keep_hp;
            level.ra_g_hp[ index ] = level.ra_g_ai[ index ].health;
            level.ra_boss_revived++;
            nengine_store_set( "rex_arena", "boss_revived", level.ra_boss_revived );
            level.ra_g_text = level.ra_g_text + "; made again with " + level.ra_g_ai[ index ].health;
        }
        else
        {
            level.ra_boss_spawn_yaw = undefined;
            level.ra_g_text = level.ra_g_text + "; could not be made again";
        }
        level.ra_spawn_hp = undefined;
        if ( index == 0 )
            level.ra_sw_kill_t = undefined;
    }
    else if ( index == 0 && level.ra_g_hp[ 0 ] > 1 && level.ra_zrex_nc )
        level.ra_g_text = level.ra_g_text + "; not a slam, left dead (no-corpse rule was on)";
    if ( !isdefined( level.ra_g_ai[ index ] ) && istrue( level.ra_held[ index ] ) )
        level.ra_g_text = level.ra_g_text + "; held at 1 before (a player's kill), left dead";
    if ( !isdefined( level.ra_g_ai[ index ] ) && level.ra_g_other && !ra_boss_can_remake( index ) )
        level.ra_g_text = level.ra_g_text + "; died within 2 s of being made, left dead";
    nengine_store_set( "rex_arena", level.ra_g_key, level.ra_g_text );
    if ( !isdefined( level.ra_g_deaths ) )
        level.ra_g_deaths = 0;
    level.ra_g_deaths++;
    if ( level.ra_g_deaths <= 40 )
        nengine_store_set( "rex_arena", level.ra_g_key + "_" + level.ra_g_deaths, level.ra_g_text );
    nengine_store_save( "rex_arena", "runtime" );
    // 0.5.82: the round-50 Z-Rex is dead for good
    if ( index == 0 && !isdefined( level.ra_g_ai[ 0 ] ) && level.ra_zr_gold )
        ra_zrex_gold_reward();
    // 0.5.86: the round-75 Guardian is dead for good
    if ( index == 1 && !isdefined( level.ra_g_ai[ 1 ] ) && level.ra_gd_ultra )
        ra_guardian_ultra_reward();
    if ( !isdefined( level.ra_g_ai[ index ] ) )
        ra_boss_final( index );
    if ( !isdefined( level.ra_g_ai[ index ] ) )
        level thread ra_boss_bar_down( level.ra_g_gone );
    level.ra_g_gone = undefined;
}

// 0.5.82: the round-50 Z-Rex is beaten (user: "if u beat him u get golden
// armor", with the popup "GOLDEN ARMOR / REWARD"). Each player gets what
// Rogue Run's Golden Armor reward gives (script_2bdf8eafdb703418
// function_484557ce9be06e04): the game's Golden Armor upgrade, then armor
// Level III, full, with the HUD (Rex's armor level function,
// script_315d0ecfeb067b1c), and the game's reward popup (the splash Rogue Run
// shows for it, script_52a6d55588cb0819).
function ra_zrex_gold_reward()
{
    level.ra_zr_gold = 0;
    level.ra_zg_text = "round " + level.ra_sp_round + ":";
    // 0.5.84: the popup did not show (user: "i got the golden armor but i
    // didnt get the pop up"). The splash is looked up in the mode's tables,
    // then in its own table (global splash table 0992aea7c6cb791c); a miss the
    // game remembers is cleared each time.
    // 0.5.85: by its asset hash (0.5.84's # hash: "reward table bundle not
    // found")
    level.ra_zg_tab = %"hash_992aea7c6cb791c";
    level.ra_zg_diag = "gate: level " + istrue( level.var_58cdd295b0c5dafa );
    if ( isdefined( level.var_7ebad24685cd9f8c ) )
        level.ra_zg_diag = level.ra_zg_diag + ", mode " + istrue( level.var_7ebad24685cd9f8c.var_9134e628a1ec8919 ) + "; mode table " + isdefined( level.var_7ebad24685cd9f8c.var_364cd614772ab2f9 ) + ", mode extra table " + isdefined( level.var_7ebad24685cd9f8c.var_e662dd7f27d462eb );
    else
        level.ra_zg_diag = level.ra_zg_diag + ", no mode splash settings";
    level.ra_zg_diag = level.ra_zg_diag + "; reward table bundle " + ( isdefined( function_6071eb16b74b2e99( level.ra_zg_tab ) ) ? "loads" : "not found" );
    level.ra_zg_idx = namespace_d4d574390268fbf3::function_b38e6009339f46f7( #"hash_3f1230d0a52e8c3e" );
    level.ra_zg_diag = level.ra_zg_diag + "; mode tables lookup " + ( isdefined( level.ra_zg_idx ) ? level.ra_zg_idx : "missed" );
    if ( !isdefined( level.ra_zg_idx ) )
    {
        if ( isdefined( level.var_7b2fd27ec6c3a883 ) )
            level.var_7b2fd27ec6c3a883[ #"hash_3f1230d0a52e8c3e" ] = undefined;
        level.ra_zg_idx = namespace_d4d574390268fbf3::function_b38e6009339f46f7( #"hash_3f1230d0a52e8c3e", level.ra_zg_tab );
        level.ra_zg_diag = level.ra_zg_diag + "; reward table lookup " + ( isdefined( level.ra_zg_idx ) ? level.ra_zg_idx : "missed" );
        if ( !isdefined( level.ra_zg_idx ) && isdefined( level.var_7b2fd27ec6c3a883 ) )
            level.var_7b2fd27ec6c3a883[ #"hash_3f1230d0a52e8c3e" ] = undefined;
    }
    // 0.5.85: still missed: the reward's splash asset (093bf66ab9c4f5f0) in
    // the game's networked splash list, as the game does on a hit, kept in
    // its splash cache for the popup call
    if ( !isdefined( level.ra_zg_idx ) )
    {
        level.ra_zg_net = function_43b5ed5a14a56573( #"hash_a372798eadba5c90", %"hash_93bf66ab9c4f5f0" );
        level.ra_zg_diag = level.ra_zg_diag + "; splash list index " + ( isdefined( level.ra_zg_net ) ? level.ra_zg_net : "undefined" );
        if ( isdefined( level.ra_zg_net ) && level.ra_zg_net >= 0 )
        {
            if ( !isdefined( level.var_3e518141bcfabbdd ) )
                level.var_3e518141bcfabbdd = [];
            level.var_3e518141bcfabbdd[ #"hash_3f1230d0a52e8c3e" ] = level.ra_zg_net;
            level.ra_zg_idx = level.ra_zg_net;
            level.ra_zg_diag = level.ra_zg_diag + " (kept for the popup)";
        }
    }
    level.ra_zg_slot = [];
    level.ra_zg_i = 0;
    while ( isdefined( level.players ) && level.ra_zg_i < level.players.size )
    {
        if ( isdefined( level.players[ level.ra_zg_i ] ) )
        {
            level.ra_zg_had = istrue( level.players[ level.ra_zg_i ].var_a1faa64d8c07872e );
            if ( !level.ra_zg_had )
                level.players[ level.ra_zg_i ] namespace_60b3bdcc70f79fc6::function_81557bcd4ddf6a05( #"hash_ce6dbbcbb4e41fbf", #"hash_27c1e4caeb1b7199" );
            level.players[ level.ra_zg_i ] namespace_74c85f0ddf2d285f::function_fdbe2cad6d8bb7e7( 3 );
            // 0.5.84: with the reward table and no gate (7th parameter, as
            // the game's function_ccbbac80e736b9f9)
            level.ra_zg_slot[ level.ra_zg_i ] = ( isdefined( level.players[ level.ra_zg_i ].var_8371af86d4691b34 ) ? level.players[ level.ra_zg_i ].var_8371af86d4691b34 : "none" ) + "/" + ( isdefined( level.players[ level.ra_zg_i ].var_d2f2ea7ceba93421 ) ? level.players[ level.ra_zg_i ].var_d2f2ea7ceba93421 : "none" );
            level.players[ level.ra_zg_i ] thread namespace_d4d574390268fbf3::function_1db44600d5ce31d4( #"hash_3f1230d0a52e8c3e", undefined, undefined, undefined, undefined, level.ra_zg_tab, 1 );
            level.ra_zg_lv = "none";
            if ( isdefined( level.players[ level.ra_zg_i ].var_da4a8128a869b164 ) )
                level.ra_zg_lv = level.players[ level.ra_zg_i ].var_da4a8128a869b164;
            level.ra_zg_text = level.ra_zg_text + " player " + level.ra_zg_i + ( level.ra_zg_had ? " had Golden Armor" : " given Golden Armor" ) + ", now armor level " + level.ra_zg_lv + ( istrue( level.players[ level.ra_zg_i ].var_a1faa64d8c07872e ) ? ", golden" : ", not golden" ) + ";";
        }
        level.ra_zg_i++;
    }
    nengine_store_set( "rex_arena", "boss_zrex_reward", level.ra_zg_text );
    nengine_store_set( "rex_arena", "boss_zrex_splash", level.ra_zg_diag );
    nengine_store_save( "rex_arena", "runtime" );
    level thread ra_zrex_splash_check();
}

// 0.5.86: the round-75 Guardian is beaten (user: "now the guardian's reward
// will be ultra rarity", with BO7's ULTRA WEAPON RARITY / NOW AVAILABLE
// popup). What BO7's Cursed Tier II does for it (script_657e27b4628aaf50):
// the rarity cap goes to 5 (Ultra), the loot rarity roll that can give Ultra
// is registered, and its switch is set. The Cursed tier itself is left alone.
// Then every player gets the game's Tier II popup.
function ra_guardian_ultra_reward()
{
    level.ra_gd_ultra = 0;
    level.ra_gu_text = "round " + level.ra_sp_round + ": rarity cap was " + ( isdefined( level.var_48e2b36291b57f44 ) ? level.var_48e2b36291b57f44 : "undefined" );
    if ( !isdefined( level.var_48e2b36291b57f44 ) || level.var_48e2b36291b57f44 < 5 )
        level.var_48e2b36291b57f44 = 5;
    level.ra_gu_text = level.ra_gu_text + ", now " + level.var_48e2b36291b57f44;
    if ( namespace_60b3bdcc70f79fc6::function_6af4632c5734e07e( #"hash_fa1ec14daf3b21ad", #"hash_459bf078b969217d" ) )
        level.ra_gu_text = level.ra_gu_text + "; Ultra loot roll already set";
    else
    {
        namespace_60b3bdcc70f79fc6::function_de57f49b8df192cc( #"hash_fa1ec14daf3b21ad", #"hash_459bf078b969217d", &namespace_c4ffb30e278ebec8::function_f09353885602ac5e );
        level.ra_gu_text = level.ra_gu_text + "; Ultra loot roll " + ( namespace_60b3bdcc70f79fc6::function_6af4632c5734e07e( #"hash_fa1ec14daf3b21ad", #"hash_459bf078b969217d" ) ? "set" : "not set" );
    }
    function_874cb5a131709245( "ui_show_weapon_upgrade_tier_5", 1 );
    level.ra_gu_text = level.ra_gu_text + "; switch on";
    nengine_store_set( "rex_arena", "boss_guardian_reward", level.ra_gu_text );
    // 0.5.87: the Arsenal's rarity row gets the Ultra upgrade
    ra_arsenal_ultra_add();
    ra_reward_splash_ready( #"hash_bfb53fe0bfcb8ec2", %"hash_992aea7c6cb791c", %"hash_177493ec59855c74" );
    level.ra_gu_slot = [];
    level.ra_gu_i = 0;
    while ( isdefined( level.players ) && level.ra_gu_i < level.players.size )
    {
        if ( isdefined( level.players[ level.ra_gu_i ] ) )
        {
            level.ra_gu_slot[ level.ra_gu_i ] = ( isdefined( level.players[ level.ra_gu_i ].var_8371af86d4691b34 ) ? level.players[ level.ra_gu_i ].var_8371af86d4691b34 : "none" );
            level.players[ level.ra_gu_i ] thread namespace_d4d574390268fbf3::function_1db44600d5ce31d4( #"hash_bfb53fe0bfcb8ec2", undefined, undefined, undefined, undefined, %"hash_992aea7c6cb791c", 1 );
        }
        level.ra_gu_i++;
    }
    nengine_store_set( "rex_arena", "boss_guardian_splash", level.ra_rs_diag );
    nengine_store_save( "rex_arena", "runtime" );
    level thread ra_guardian_splash_check();
}

// 0.5.87: the Ultra upgrade in the Arsenal's rarity row (user: "when u get it
// unlocked i want it to be added to the arsenal machine aswell"). Rex's rarity
// group has four upgrade items; BO7's Cursed list adds the Ultra one
// (scriptbundle 76b58e1ee1e4569d). It is added to the Arsenal's menu as the
// game adds items (script_4269c5cb8b71e86e function_7b1d4491df5154b1): in the
// menu's item list at the next index, and in the rarity group (the group of
// the Legendary item) at the next position. A purchase sends that index
// (script_46fecad419c065b2 function_3466b144d2348320). The mod Lua shows the
// entry from rex_arena_ultra ("index|position|Legendary's index").
function ra_arsenal_ultra_add()
{
    level.ra_au_text = "round " + level.ra_sp_round;
    level.ra_au_b = function_6071eb16b74b2e99( %"hash_76b58e1ee1e4569d" );
    if ( !isdefined( level.ra_au_b ) )
    {
        nengine_store_set( "rex_arena", "arsenal_ultra", level.ra_au_text + ": Ultra upgrade bundle not found" );
        return;
    }
    level.ra_au_text = level.ra_au_text + ": Ultra bundle level " + ( isdefined( level.ra_au_b.var_b131e47fdc5c0ad6 ) ? level.ra_au_b.var_b131e47fdc5c0ad6 : "undefined" ) + ", cost " + ( isdefined( level.ra_au_b.var_2729c5e6f598b48f ) ? level.ra_au_b.var_2729c5e6f598b48f : "undefined" );
    if ( !isdefined( level.ra_au_b.var_b131e47fdc5c0ad6 ) || level.ra_au_b.var_b131e47fdc5c0ad6 != 5 )
    {
        nengine_store_set( "rex_arena", "arsenal_ultra", level.ra_au_text + "; not added (not level 5)" );
        return;
    }
    if ( !isdefined( level.var_a8a90c8a6ff537ea ) || !isdefined( level.var_a8a90c8a6ff537ea[ #"hash_1ab0119734c3d7c1" ] ) || !isdefined( level.var_a8a90c8a6ff537ea[ #"hash_1ab0119734c3d7c1" ].var_3d80f21b259dad6 ) )
    {
        nengine_store_set( "rex_arena", "arsenal_ultra", level.ra_au_text + "; no Arsenal menu" );
        return;
    }
    level.ra_au_m = level.var_a8a90c8a6ff537ea[ #"hash_1ab0119734c3d7c1" ];
    level.ra_au_leg = undefined;
    level.ra_au_has = 0;
    level.ra_au_k = 1;
    while ( level.ra_au_k <= level.ra_au_m.var_3d80f21b259dad6.size )
    {
        level.ra_au_it = level.ra_au_m.var_3d80f21b259dad6[ level.ra_au_k ];
        if ( isdefined( level.ra_au_it ) && isdefined( level.ra_au_it.var_4276cbe535bb0eae ) )
        {
            level.ra_au_ib = function_6071eb16b74b2e99( level.ra_au_it.var_4276cbe535bb0eae );
            if ( isdefined( level.ra_au_ib ) && isdefined( level.ra_au_ib.var_b131e47fdc5c0ad6 ) )
            {
                if ( level.ra_au_ib.var_b131e47fdc5c0ad6 == 4 )
                    level.ra_au_leg = level.ra_au_it;
                if ( level.ra_au_ib.var_b131e47fdc5c0ad6 == 5 )
                    level.ra_au_has = 1;
            }
        }
        level.ra_au_k++;
    }
    level.ra_au_text = level.ra_au_text + "; menu items " + level.ra_au_m.var_3d80f21b259dad6.size;
    if ( level.ra_au_has )
    {
        nengine_store_set( "rex_arena", "arsenal_ultra", level.ra_au_text + "; Ultra already in the menu" );
        return;
    }
    if ( !isdefined( level.ra_au_leg ) || !isdefined( level.ra_au_m.var_256445803195385a ) || !isdefined( level.ra_au_m.var_256445803195385a[ level.ra_au_leg.var_b487b5b7ae379493 ] ) )
    {
        nengine_store_set( "rex_arena", "arsenal_ultra", level.ra_au_text + "; no Legendary item or rarity group" );
        return;
    }
    level.ra_au_grp = level.ra_au_m.var_256445803195385a[ level.ra_au_leg.var_b487b5b7ae379493 ];
    level.ra_au_text = level.ra_au_text + "; rarity group " + level.ra_au_leg.var_b487b5b7ae379493 + ( isdefined( level.ra_au_grp.var_b13646f5585d25f3 ) && level.ra_au_grp.var_b13646f5585d25f3 == #"hash_2a699cbbf39ea43b" ? " (WEAPON RARITY)" : " (other name)" ) + ", Legendary index " + level.ra_au_leg.var_c4b8734f93ae56ff;
    level.ra_au_gi = level.ra_au_m.var_3d80f21b259dad6.size + 1;
    while ( isdefined( level.ra_au_m.var_3d80f21b259dad6[ level.ra_au_gi ] ) )
        level.ra_au_gi++;
    level.ra_au_pos = level.ra_au_grp.var_3d80f21b259dad6.size + 1;
    while ( isdefined( level.ra_au_grp.var_3d80f21b259dad6[ level.ra_au_pos ] ) )
        level.ra_au_pos++;
    level.ra_au_new = spawnstruct();
    level.ra_au_new.var_4276cbe535bb0eae = %"hash_76b58e1ee1e4569d";
    level.ra_au_new.var_b487b5b7ae379493 = level.ra_au_leg.var_b487b5b7ae379493;
    level.ra_au_new.var_f5fec69ffd2456b2 = level.ra_au_pos;
    level.ra_au_new.var_c4b8734f93ae56ff = level.ra_au_gi;
    level.ra_au_new.var_c535f3efb28bf746 = level.ra_au_leg.var_c535f3efb28bf746;
    level.ra_au_m.var_3d80f21b259dad6[ level.ra_au_gi ] = level.ra_au_new;
    level.ra_au_grp.var_3d80f21b259dad6[ level.ra_au_pos ] = level.ra_au_new;
    setdvar( @"rex_arena_ultra", level.ra_au_gi + "|" + level.ra_au_pos + "|" + level.ra_au_leg.var_c4b8734f93ae56ff );
    level.ra_au_text = level.ra_au_text + "; Ultra added at index " + level.ra_au_gi + ", position " + level.ra_au_pos + "; menu lookup " + ( isdefined( level.var_a8a90c8a6ff537ea[ #"hash_1ab0119734c3d7c1" ].var_3d80f21b259dad6[ level.ra_au_gi ] ) ? "finds it" : "misses it" );
    nengine_store_set( "rex_arena", "arsenal_ultra", level.ra_au_text );
    level thread ra_arsenal_ultra_watch();
    level thread ra_arsenal_ultra_end();
}

// 0.5.87: what the mod Lua's Ultra block reports in rex_arena_ultra_ui, kept in
// the store (each change, checked every second).
function ra_arsenal_ultra_watch()
{
    level endon( #"game_ended" );
    level.ra_au_ui = "";
    while ( true )
    {
        wait 1;
        level.ra_au_now = getdvar( @"rex_arena_ultra_ui", "" );
        if ( level.ra_au_now != level.ra_au_ui )
        {
            level.ra_au_ui = level.ra_au_now;
            nengine_store_set( "rex_arena", "arsenal_ultra_ui", level.ra_au_ui );
            nengine_store_save( "rex_arena", "runtime" );
        }
    }
}

// 0.5.97: the minimap (top left) and the objective tracker under it (SURVIVE /
// Holdout in Her House) are hidden in the arena match (user: "now we need to
// remove the minimap in the left and the survive window"). The mod Lua's
// minimap block hides them while rex_arena_minimap is "1". It is set again
// every second: the Lua clears it in the frontend, and the HUD is built after
// this starts. What the Lua reports (rex_arena_minimap_ui) goes to the store.
function ra_hide_minimap()
{
    level.ra_mm_ui = "";
    setdvar( @"rex_arena_minimap_ui", "" );
    nengine_store_set( "rex_arena", "minimap", "asked" );
    while ( true )
    {
        if ( getdvar( @"rex_arena_minimap", "" ) != "1" )
            setdvar( @"rex_arena_minimap", "1" );
        level.ra_mm_now = getdvar( @"rex_arena_minimap_ui", "" );
        if ( level.ra_mm_now != level.ra_mm_ui )
        {
            level.ra_mm_ui = level.ra_mm_now;
            nengine_store_set( "rex_arena", "minimap", level.ra_mm_ui );
            nengine_store_save( "rex_arena", "runtime" );
        }
        wait 1;
    }
}

// 0.5.99: the Warden's (the Weyward's) last death leaves the screen black
// (user: "when killing the warden, the screen flashes white and then it stays
// black"). Rex's death sequence (script_54dddff365034d92
// function_4e8b3cdd86f68b5c) puts each player's white overlay up, then the
// black one, then sets this level flag; only Rex's main quest
// (script_208c0afde0bb6ec function_aa17fa7583dcf3bd) waits for the flag and
// fades them out again (white over 0.05 s, black over 0.3 s), and the arena
// does not run that quest step. This does the same fades when the flag is set,
// then clears the flag so a later Warden death is handled too. Nothing else
// of the quest's ending runs.
function ra_warden_fade_watch()
{
    level endon( #"game_ended" );
    level.ra_wf_n = 0;
    level.ra_wf_last = -100000;
    level.ra_bf_held = 0;
    nengine_store_set( "rex_arena", "warden_fade", "waiting" );
    nengine_store_set( "rex_arena", "warden_end", "waiting" );
    while ( true )
    {
        wait 0.25;
        if ( !level namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( "weyward_real_death_sequence_end" ) )
            continue;
        level.ra_wf_n++;
        // 0.6.2: the black screen stays up for the summary; the ending takes
        // it down as the vote opens. Once per Warden death (its death sets the
        // flag twice, about 20 s apart); a later flag only gets the fades.
        if ( function_83bf4b34fbbe124b() - level.ra_wf_last > 45000 )
        {
            level.ra_wf_last = function_83bf4b34fbbe124b();
            ra_warden_end();
            level.ra_wf_last = function_83bf4b34fbbe124b();
        }
        else
            ra_warden_fades();
        level namespace_60b3bdcc70f79fc6::function_bb43e9471feff54e( "weyward_real_death_sequence_end" );
    }
}

// 0.6.2: Rex's white and black screens taken down on every player, as its
// quest step does (white over 0.05 s, black over 0.3 s); 0.5.99-0.6.1 did this
// in ra_warden_fade_watch the moment the flag was set.
function ra_warden_fades()
{
    level.ra_wf_up = 0;
    level.ra_wf_i = 0;
    while ( level.ra_wf_i < level.players.size )
    {
        if ( isdefined( level.players[ level.ra_wf_i ] ) )
        {
            if ( isdefined( level.players[ level.ra_wf_i ].var_fd24d570aa69fd56 ) && isdefined( level.players[ level.ra_wf_i ].var_fd24d570aa69fd56[ "black" ] ) && isdefined( level.players[ level.ra_wf_i ].var_fd24d570aa69fd56[ "black" ].var_957f4b704a6a7e42 ) && level.players[ level.ra_wf_i ].var_fd24d570aa69fd56[ "black" ].var_957f4b704a6a7e42 == 1 )
                level.ra_wf_up++;
            level.players[ level.ra_wf_i ] thread namespace_6b3344dd849818f8::function_359470233876be22( 0.05, "white" );
            level.players[ level.ra_wf_i ] thread namespace_6b3344dd849818f8::function_359470233876be22( 0.3, "black" );
        }
        level.ra_wf_i++;
    }
    nengine_store_set( "rex_arena", "warden_fade", "Warden death " + level.ra_wf_n + ": white and black screens faded out for " + level.players.size + " player(s), black was up for " + level.ra_wf_up );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.6.0: after the Warden's death screens (user: "i want the time screen to
// be after the blacksscreen after the warden dies and i want this screen after
// it aswell"): the BOSSES DEFEATED summary (a round-999 fight), then BO7's own
// Continue Playing? vote, the one Rex's quest ending opens
// (namespace_74b2d1dbce2fe39a::function_3477750f338de598 with the same text, no
// fade). No place is passed, so the vote moves nobody; everyone choosing EXIT
// ends the match the game's way. If someone continues, the game's continue
// reward (ra_warden_reward).
// 0.6.2 (user: "the boss summary should come up during the blackscreen and the
// continue playing should come after the blackscreen"): the summary is shown
// while Rex's black screen is still up; the screens come down (ra_warden_fades)
// in the same frame the vote opens. If round-999 bosses are still alive 3 s
// after the flag, the screens come down first so they can be fought and the
// summary waits up to 30 s more, as in 0.6.0.
function ra_warden_end()
{
    // 0.6.1: the round-select pedestals are off while it runs
    level.ra_we_on = 1;
    level.ra_we_i = 0;
    while ( level.ra_qd_w && !level.ra_bf_held && level.ra_we_i < 12 )
    {
        wait 0.25;
        level.ra_we_i++;
    }
    level.ra_we_faded = 0;
    if ( level.ra_qd_w && !level.ra_bf_held )
    {
        ra_warden_fades();
        level.ra_we_faded = 1;
        while ( level.ra_qd_w && !level.ra_bf_held && level.ra_we_i < 132 )
        {
            wait 0.25;
            level.ra_we_i++;
        }
    }
    level.ra_we_text = level.ra_bf_held ? ( level.ra_we_faded ? "summary shown after the black screen (bosses were still alive)" : "summary shown on the black screen" ) : ( level.ra_qd_w ? "no summary (round-999 bosses still alive after 30 s)" : "no summary (not a round-999 fight)" );
    if ( level.ra_bf_held )
    {
        level.ra_bf_held = 0;
        ra_note( "BOSSES DEFEATED", level.ra_bf_text, 10 );
        wait 10;
    }
    // 0.6.2: the black screen comes down as the vote opens
    if ( !level.ra_we_faded )
        ra_warden_fades();
    // 1.1.4: the arena centre when neither the Weyward's place nor player 0 is known
    level.ra_we_at = ( 29424, -27424, 2216 );
    if ( isdefined( level.ra_g_org[ 3 ] ) )
        level.ra_we_at = level.ra_g_org[ 3 ];
    else if ( isdefined( level.players ) && level.players.size > 0 && isdefined( level.players[ 0 ] ) )
        level.ra_we_at = level.players[ 0 ].origin;
    nengine_store_set( "rex_arena", "warden_end", level.ra_we_text + "; vote open" );
    level.ra_we_res = namespace_74b2d1dbce2fe39a::function_3477750f338de598( undefined, &"hash_76ff85bb2057ad7b", 0, 0 );
    nengine_store_set( "rex_arena", "warden_end", level.ra_we_text + "; vote done: " + ( istrue( level.ra_we_res ) ? "everyone left, the match ends" : "someone continues, reward at " + level.ra_we_at ) );
    nengine_store_save( "rex_arena", "runtime" );
    if ( !istrue( level.ra_we_res ) )
        level thread ra_warden_reward();
    level.ra_we_on = 0;
}

// 0.6.0: the game's continue reward, 4 s after the vote, as Rex's
// function_78f9d6116fa25d95 does, at the Warden's last place.
function ra_warden_reward()
{
    level endon( #"game_ended" );
    wait 4;
    namespace_74b2d1dbce2fe39a::function_2e003fa13e881f92( level.ra_we_at );
    nengine_store_set( "rex_arena", "warden_reward", "continue reward at " + level.ra_we_at );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.6.0: a held round-999 summary no Warden ending took is shown 40 s later.
function ra_bf_release()
{
    level endon( #"game_ended" );
    wait 40;
    if ( !level.ra_bf_held )
        return;
    level.ra_bf_held = 0;
    ra_note( "BOSSES DEFEATED", level.ra_bf_text, 10 );
}


// 0.5.87: the Ultra slot does not outlive the arena match.
function ra_arsenal_ultra_end()
{
    level waittill( #"game_ended" );
    setdvar( @"rex_arena_ultra", "" );
}

// 0.5.88: the round-100 Caltheris is beaten (user: "for the last change i
// want it to make pap 4 available", with BO7's PACK-A-PUNCH IV / NOW AVAILABLE
// popup; asked when: "Caltheris reward"). What BO7's Cursed Tier III does for
// it (script_657e27b4628aaf50): the Pack-a-Punch level cap goes to 4. Rex's
// Pack-a-Punch menu already has the level-4 item; the machine offers the
// weapon's level + 1 only below the cap (script_4f24ca7a470a5fa8). The Cursed
// tier itself is left alone. Then every player gets the game's Tier III popup.
function ra_caltheris_pap_reward()
{
    level.ra_cl_pap = 0;
    level.ra_cp_text = "round " + level.ra_sp_round + ": Pack-a-Punch level cap was " + ( isdefined( level.var_eda995bb839c4aa ) ? level.var_eda995bb839c4aa : "undefined" );
    if ( !isdefined( level.var_eda995bb839c4aa ) || level.var_eda995bb839c4aa < 4 )
        level.var_eda995bb839c4aa = 4;
    level.ra_cp_text = level.ra_cp_text + ", now " + level.var_eda995bb839c4aa;
    if ( isdefined( level.var_a8a90c8a6ff537ea ) && isdefined( level.var_a8a90c8a6ff537ea[ #"hash_77ca6c195676c20e" ] ) && isdefined( level.var_a8a90c8a6ff537ea[ #"hash_77ca6c195676c20e" ].var_3d80f21b259dad6 ) )
    {
        level.ra_cp_m = level.var_a8a90c8a6ff537ea[ #"hash_77ca6c195676c20e" ];
        level.ra_cp_text = level.ra_cp_text + "; Pack-a-Punch menu items " + level.ra_cp_m.var_3d80f21b259dad6.size + ", level-4 item " + ( isdefined( level.ra_cp_m.var_3d80f21b259dad6[ 4 ] ) ? "found" : "missing" );
        if ( isdefined( level.ra_cp_m.var_3d80f21b259dad6[ 4 ] ) && isdefined( level.ra_cp_m.var_3d80f21b259dad6[ 4 ].var_4276cbe535bb0eae ) )
            level.ra_cp_text = level.ra_cp_text + ( level.ra_cp_m.var_3d80f21b259dad6[ 4 ].var_4276cbe535bb0eae == %"hash_3fc7feac20b16941" ? " (the level4 bundle)" : " (another bundle)" );
    }
    else
        level.ra_cp_text = level.ra_cp_text + "; no Pack-a-Punch menu";
    if ( isdefined( level.var_f77ef06e8d43541e ) && isdefined( level.var_f77ef06e8d43541e[ "hintstring_only" ] ) && isdefined( level.var_f77ef06e8d43541e[ "hintstring_only" ].var_38660cab607b147e ) )
        level.ra_cp_text = level.ra_cp_text + "; level table size " + level.var_f77ef06e8d43541e[ "hintstring_only" ].var_38660cab607b147e.size;
    level.ra_cp_text = level.ra_cp_text + "; map menu lookup " + ( isdefined( level.var_2616e52fe1bd99e6 ) ? "set" : "none" );
    nengine_store_set( "rex_arena", "boss_caltheris_reward", level.ra_cp_text );
    ra_reward_splash_ready( #"hash_f88b3d2ef10dd8b5", %"hash_992aea7c6cb791c", %"hash_a9209f641ec857" );
    level.ra_cp_slot = [];
    level.ra_cp_i = 0;
    while ( isdefined( level.players ) && level.ra_cp_i < level.players.size )
    {
        if ( isdefined( level.players[ level.ra_cp_i ] ) )
        {
            level.ra_cp_slot[ level.ra_cp_i ] = ( isdefined( level.players[ level.ra_cp_i ].var_8371af86d4691b34 ) ? level.players[ level.ra_cp_i ].var_8371af86d4691b34 : "none" );
            level.players[ level.ra_cp_i ] thread namespace_d4d574390268fbf3::function_1db44600d5ce31d4( #"hash_f88b3d2ef10dd8b5", undefined, undefined, undefined, undefined, %"hash_992aea7c6cb791c", 1 );
        }
        level.ra_cp_i++;
    }
    nengine_store_set( "rex_arena", "boss_caltheris_splash", level.ra_rs_diag );
    nengine_store_save( "rex_arena", "runtime" );
    level thread ra_caltheris_splash_check();
}

// 0.5.88: 1 s after the Pack-a-Punch IV popup call, each player's splash slot
// before and after (it moves on only when the server sends a splash).
function ra_caltheris_splash_check()
{
    level endon( #"game_ended" );
    wait 1;
    level.ra_cs_i = 0;
    while ( isdefined( level.players ) && level.ra_cs_i < level.players.size )
    {
        if ( isdefined( level.players[ level.ra_cs_i ] ) )
            level.ra_rs_diag = level.ra_rs_diag + "; player " + level.ra_cs_i + " splash slot before " + ( isdefined( level.ra_cp_slot[ level.ra_cs_i ] ) ? level.ra_cp_slot[ level.ra_cs_i ] : "none" ) + ", after " + ( isdefined( level.players[ level.ra_cs_i ].var_8371af86d4691b34 ) ? level.players[ level.ra_cs_i ].var_8371af86d4691b34 : "none" );
        level.ra_cs_i++;
    }
    nengine_store_set( "rex_arena", "boss_caltheris_splash", level.ra_rs_diag );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.86: a reward popup's splash is found as 0.5.85 finds the Golden Armor
// one: the mode's tables, then the reward table by its asset hash, then the
// splash asset's index in the networked splash list, kept in the game's
// splash cache. A miss the game remembers is cleared each time. Writes
// level.ra_rs_diag.
function ra_reward_splash_ready( splash, table, asset )
{
    level.ra_rs_diag = "reward table bundle " + ( isdefined( function_6071eb16b74b2e99( table ) ) ? "loads" : "not found" );
    level.ra_rs_idx = namespace_d4d574390268fbf3::function_b38e6009339f46f7( splash );
    level.ra_rs_diag = level.ra_rs_diag + "; mode tables lookup " + ( isdefined( level.ra_rs_idx ) ? level.ra_rs_idx : "missed" );
    if ( isdefined( level.ra_rs_idx ) )
        return;
    if ( isdefined( level.var_7b2fd27ec6c3a883 ) )
        level.var_7b2fd27ec6c3a883[ splash ] = undefined;
    level.ra_rs_idx = namespace_d4d574390268fbf3::function_b38e6009339f46f7( splash, table );
    level.ra_rs_diag = level.ra_rs_diag + "; reward table lookup " + ( isdefined( level.ra_rs_idx ) ? level.ra_rs_idx : "missed" );
    if ( isdefined( level.ra_rs_idx ) )
        return;
    if ( isdefined( level.var_7b2fd27ec6c3a883 ) )
        level.var_7b2fd27ec6c3a883[ splash ] = undefined;
    level.ra_rs_net = function_43b5ed5a14a56573( #"hash_a372798eadba5c90", asset );
    level.ra_rs_diag = level.ra_rs_diag + "; splash list index " + ( isdefined( level.ra_rs_net ) ? level.ra_rs_net : "undefined" );
    if ( isdefined( level.ra_rs_net ) && level.ra_rs_net >= 0 )
    {
        if ( !isdefined( level.var_3e518141bcfabbdd ) )
            level.var_3e518141bcfabbdd = [];
        level.var_3e518141bcfabbdd[ splash ] = level.ra_rs_net;
        level.ra_rs_diag = level.ra_rs_diag + " (kept for the popup)";
    }
}

// 0.5.86: 1 s after the Ultra popup call, each player's splash slot before
// and after (it moves on only when the server sends a splash).
function ra_guardian_splash_check()
{
    level endon( #"game_ended" );
    wait 1;
    level.ra_gs_i = 0;
    while ( isdefined( level.players ) && level.ra_gs_i < level.players.size )
    {
        if ( isdefined( level.players[ level.ra_gs_i ] ) )
            level.ra_rs_diag = level.ra_rs_diag + "; player " + level.ra_gs_i + " splash slot before " + ( isdefined( level.ra_gu_slot[ level.ra_gs_i ] ) ? level.ra_gu_slot[ level.ra_gs_i ] : "none" ) + ", after " + ( isdefined( level.players[ level.ra_gs_i ].var_8371af86d4691b34 ) ? level.players[ level.ra_gs_i ].var_8371af86d4691b34 : "none" );
        level.ra_gs_i++;
    }
    nengine_store_set( "rex_arena", "boss_guardian_splash", level.ra_rs_diag );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.84: 1 s after the popup call, each player's splash slot and count
// (var_8371af86d4691b34 / var_d2f2ea7ceba93421, moved on by the game only when
// the server sends a splash), before and after.
function ra_zrex_splash_check()
{
    level endon( #"game_ended" );
    wait 1;
    level.ra_zs_i = 0;
    while ( isdefined( level.players ) && level.ra_zs_i < level.players.size )
    {
        if ( isdefined( level.players[ level.ra_zs_i ] ) )
            level.ra_zg_diag = level.ra_zg_diag + "; player " + level.ra_zs_i + " splash slot/count before " + ( isdefined( level.ra_zg_slot[ level.ra_zs_i ] ) ? level.ra_zg_slot[ level.ra_zs_i ] : "none" ) + ", after " + ( isdefined( level.players[ level.ra_zs_i ].var_8371af86d4691b34 ) ? level.players[ level.ra_zs_i ].var_8371af86d4691b34 : "none" ) + "/" + ( isdefined( level.players[ level.ra_zs_i ].var_d2f2ea7ceba93421 ) ? level.players[ level.ra_zs_i ].var_d2f2ea7ceba93421 : "none" );
        level.ra_zs_i++;
    }
    nengine_store_set( "rex_arena", "boss_zrex_splash", level.ra_zg_diag );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.31: another of Z-Rex, the Guardian and Caltheris is alive.
function ra_weyward_other()
{
    return ( level.ra_g_on[ 0 ] && ra_boss_alive( level.ra_g_ai[ 0 ], 0 ) ) || ( level.ra_g_on[ 1 ] && ra_boss_alive( level.ra_g_ai[ 1 ], 1 ) ) || ( level.ra_g_on[ 2 ] && ra_boss_alive( level.ra_g_ai[ 2 ], 2 ) );
}

// 0.5.31: the Weyward is made again (as the Guardian and Caltheris): another
// boss is alive, it died with the instant-kill mark or above 5% of its
// health, not within 2 s of being made, and was never held at 1.
function ra_weyward_remake_ok()
{
    if ( !ra_weyward_other() || !ra_boss_can_remake( 3 ) || istrue( level.ra_held[ 3 ] ) )
        return false;
    return level.ra_w_mark || level.ra_g_hp[ 3 ] > level.ra_g_max[ 3 ] * 0.05;
}

// 0.5.31: the Weyward (boss 3), as ra_caltheris_guard: while it lives its
// health and place are kept; when it is gone its death is written to the
// store, it is made again where it died with its health when
// ra_weyward_remake_ok says so, and otherwise it is dead for good
// (ra_boss_final).
function ra_weyward_guard()
{
    if ( !level.ra_g_on[ 3 ] )
        return;
    if ( ra_boss_alive( level.ra_g_ai[ 3 ], 3 ) )
    {
        level.ra_g_hp[ 3 ] = level.ra_g_ai[ 3 ].health;
        level.ra_g_max[ 3 ] = level.ra_g_ai[ 3 ].maxhealth;
        level.ra_g_org[ 3 ] = level.ra_g_ai[ 3 ].origin;
        level.ra_g_ang[ 3 ] = level.ra_g_ai[ 3 ].angles;
        ra_weyward_where();
        ra_weyward_souls();
        ra_weyward_no_trial();
        ra_weyward_phase_centre();
        return;
    }
    level.ra_g_on[ 3 ] = 0;
    level.ra_wg_gone = level.ra_g_ai[ 3 ];
    level.ra_g_ai[ 3 ] = undefined;
    level.ra_weyward_ai = undefined;
    if ( isdefined( level.ra_wg_gone ) && isdefined( level.ra_wg_gone.var_a472e925a028ede0 ) && level.ra_wg_gone.var_a472e925a028ede0 )
        level.ra_w_mark = 1;
    level.ra_wg_text = "round " + level.ra_sp_round + ": health " + level.ra_g_hp[ 3 ] + " of " + level.ra_g_max[ 3 ] + ", other boss alive " + ( ra_weyward_other() ? 1 : 0 ) + ", instant-kill mark " + level.ra_w_mark;
    if ( isdefined( level.ra_made_t[ 3 ] ) )
        level.ra_wg_text = level.ra_wg_text + ", " + ( function_83bf4b34fbbe124b() - level.ra_made_t[ 3 ] ) + " ms after it was made";
    if ( isdefined( level.ra_g_org[ 3 ] ) )
        level.ra_wg_text = level.ra_wg_text + ", at " + level.ra_g_org[ 3 ];
    if ( isdefined( level.ra_g_org[ 3 ] ) && ra_weyward_remake_ok() )
    {
        level.ra_wg_keep_hp = level.ra_g_hp[ 3 ];
        level.ra_spawn_hp = level.ra_wg_keep_hp;
        if ( isdefined( level.ra_g_ang[ 3 ] ) )
            level.ra_boss_spawn_yaw = level.ra_g_ang[ 3 ][ 1 ];
        if ( ra_boss_spawn( 3, level.ra_g_org[ 3 ] ) )
        {
            if ( level.ra_g_ai[ 3 ].health > level.ra_wg_keep_hp )
                level.ra_g_ai[ 3 ].health = level.ra_wg_keep_hp;
            level.ra_g_hp[ 3 ] = level.ra_g_ai[ 3 ].health;
            level.ra_boss_revived++;
            nengine_store_set( "rex_arena", "boss_revived", level.ra_boss_revived );
            level.ra_wg_text = level.ra_wg_text + "; made again with " + level.ra_g_ai[ 3 ].health;
        }
        else
        {
            level.ra_boss_spawn_yaw = undefined;
            level.ra_wg_text = level.ra_wg_text + "; could not be made again";
        }
        level.ra_spawn_hp = undefined;
    }
    if ( !isdefined( level.ra_g_ai[ 3 ] ) && istrue( level.ra_held[ 3 ] ) )
        level.ra_wg_text = level.ra_wg_text + "; held at 1 before (a player's kill), left dead";
    if ( !isdefined( level.ra_g_ai[ 3 ] ) && ra_weyward_other() && !ra_boss_can_remake( 3 ) )
        level.ra_wg_text = level.ra_wg_text + "; died within 2 s of being made, left dead";
    nengine_store_set( "rex_arena", "boss_weyward_death", level.ra_wg_text );
    if ( !isdefined( level.ra_wg_deaths ) )
        level.ra_wg_deaths = 0;
    level.ra_wg_deaths++;
    if ( level.ra_wg_deaths <= 20 )
        nengine_store_set( "rex_arena", "boss_weyward_death_" + level.ra_wg_deaths, level.ra_wg_text );
    nengine_store_save( "rex_arena", "runtime" );
    if ( !isdefined( level.ra_g_ai[ 3 ] ) )
        ra_boss_final( 3 );
    level.ra_wg_gone = undefined;
}

// 0.5.32: every 2 s while the Weyward lives: its place, its distance from the
// arena centre (the Guardian's point), from each living boss and from the
// player, and its health. More than 3500 units from the centre, it is put back
// (ra_weyward_bring_back, at most 3 times).
function ra_weyward_where()
{
    level.ra_ww_now = function_83bf4b34fbbe124b();
    if ( isdefined( level.ra_ww_t ) && level.ra_ww_now < level.ra_ww_t )
        return;
    level.ra_ww_t = level.ra_ww_now + 2000;
    level.ra_ww_ai = level.ra_g_ai[ 3 ];
    level.ra_ww_d = int( distance( level.ra_ww_ai.origin, ( 29424, -27424, 2216 ) ) );
    level.ra_ww_text = "round " + level.ra_sp_round + ", " + int( ( level.ra_ww_now - level.ra_made_t[ 3 ] ) / 1000 ) + " s after made: at " + level.ra_ww_ai.origin + ", " + level.ra_ww_d + " from the arena centre, health " + level.ra_ww_ai.health + " of " + level.ra_ww_ai.maxhealth;
    if ( ra_boss_alive( level.ra_zrex_ai, 0 ) )
        level.ra_ww_text = level.ra_ww_text + ", Z-Rex " + int( distance( level.ra_ww_ai.origin, level.ra_zrex_ai.origin ) );
    if ( ra_boss_alive( level.ra_guardian_ai, 1 ) )
        level.ra_ww_text = level.ra_ww_text + ", Guardian " + int( distance( level.ra_ww_ai.origin, level.ra_guardian_ai.origin ) );
    if ( ra_boss_alive( level.ra_caltheris_ai, 2 ) )
        level.ra_ww_text = level.ra_ww_text + ", Caltheris " + int( distance( level.ra_ww_ai.origin, level.ra_caltheris_ai.origin ) );
    if ( isdefined( level.players ) && level.players.size > 0 && isdefined( level.players[ 0 ] ) )
        level.ra_ww_text = level.ra_ww_text + ", player " + int( distance( level.ra_ww_ai.origin, level.players[ 0 ].origin ) ) + " (player at " + level.players[ 0 ].origin + ")";
    level.ra_ww_text = level.ra_ww_text + ", souls alive " + level.ra_ws_alive + " (placed " + level.ra_ws_placed + "), shield " + level.ra_ws_sh + ", damage " + ( 100 - level.ra_ws_cut ) + "%";
    nengine_store_set( "rex_arena", "boss_weyward_where", level.ra_ww_text );
    level.ra_ww_n++;
    if ( level.ra_ww_n <= 20 )
        nengine_store_set( "rex_arena", "boss_weyward_where_" + level.ra_ww_n, level.ra_ww_text );
    // 0.5.39: not while immune (its phase change: ra_weyward_phase_centre)
    if ( level.ra_ww_d > 3500 && level.ra_wb_n < 3 && !istrue( level.ra_ww_ai.var_9b230d276449dbc8 ) )
        level thread ra_weyward_bring_back( level.ra_ww_ai, level.ra_ww_ai.origin, level.ra_ww_d );
    nengine_store_save( "rex_arena", "runtime" );
    level.ra_ww_ai = undefined;
}

// 0.5.34: the Weyward's Shadow Souls. The game's boss script (core
// script_5cda26b07ee216bf, which the Weyward's own script uses) makes them at
// each phase change (70% and 40% health) into the boss's soul list
// (var_14b016fe8b256eed), sends each to a spot (var_2a28dc6cba206399) and
// then marks it placed (var_31ee4cc6f0acd713). While a placed soul lives the
// boss's shield field (var_1516298348ea0b2b) is set and its damage is
// multiplied by 1 - min( placed x 0.4, 0.95 ) (the Weyward's settings).
// Checked on every pass of the boss guard: when the count alive, the count
// placed, the shield, the immune field (var_9b230d276449dbc8) or the phase
// (var_96eb4eec60875abc) changes, boss_weyward_soul_event (first 40 also
// numbered); every 2 s while souls live or the shield is up,
// boss_weyward_souls (first 30 also numbered). Records only.
function ra_weyward_souls()
{
    level.ra_ws_ai = level.ra_g_ai[ 3 ];
    level.ra_ws_all = 0;
    level.ra_ws_alive = 0;
    level.ra_ws_placed = 0;
    if ( isdefined( level.ra_ws_ai.var_14b016fe8b256eed ) )
        level.ra_ws_all = level.ra_ws_ai.var_14b016fe8b256eed.size;
    level.ra_ws_i = 0;
    while ( level.ra_ws_i < level.ra_ws_all )
    {
        level.ra_ws_s = level.ra_ws_ai.var_14b016fe8b256eed[ level.ra_ws_i ];
        if ( isdefined( level.ra_ws_s ) && isalive( level.ra_ws_s ) )
        {
            level.ra_ws_alive++;
            if ( istrue( level.ra_ws_s.var_31ee4cc6f0acd713 ) )
            {
                level.ra_ws_placed++;
                ra_weyward_soul_home( level.ra_ws_s );
            }
        }
        level.ra_ws_i++;
    }
    // 0.5.36: the crystal list (var_ffbac11aaec6ae15) and the storm
    // (var_caa78a711562a0f1, namespace_e1405a28eaa11849)
    level.ra_ws_cr = 0;
    level.ra_ws_i = 0;
    while ( isdefined( level.ra_ws_ai.var_ffbac11aaec6ae15 ) && level.ra_ws_i < level.ra_ws_ai.var_ffbac11aaec6ae15.size )
    {
        level.ra_ws_s = level.ra_ws_ai.var_ffbac11aaec6ae15[ level.ra_ws_i ];
        if ( isdefined( level.ra_ws_s ) && isalive( level.ra_ws_s ) )
        {
            level.ra_ws_cr++;
            ra_weyward_crystal_home( level.ra_ws_s );
        }
        level.ra_ws_i++;
    }
    level.ra_ws_storm = istrue( level.ra_ws_ai.var_caa78a711562a0f1 ) ? 1 : 0;
    ra_weyward_storm_home( level.ra_ws_ai );
    level.ra_ws_s = undefined;
    level.ra_ws_sh = istrue( level.ra_ws_ai.var_1516298348ea0b2b ) ? 1 : 0;
    level.ra_ws_im = istrue( level.ra_ws_ai.var_9b230d276449dbc8 ) ? 1 : 0;
    level.ra_ws_ph = isdefined( level.ra_ws_ai.var_96eb4eec60875abc ) ? level.ra_ws_ai.var_96eb4eec60875abc : "?";
    level.ra_ws_ai = undefined;
    level.ra_ws_cut = 0;
    if ( level.ra_ws_sh && level.ra_ws_placed > 0 )
        level.ra_ws_cut = ( level.ra_ws_placed * 40 > 95 ) ? 95 : level.ra_ws_placed * 40;
    level.ra_ws_key = level.ra_ws_alive + "|" + level.ra_ws_placed + "|" + level.ra_ws_sh + "|" + level.ra_ws_im + "|" + level.ra_ws_ph + "|" + level.ra_ws_cr + "|" + level.ra_ws_storm;
    if ( level.ra_ws_key != level.ra_ws_last )
    {
        level.ra_ws_last = level.ra_ws_key;
        level.ra_ws_e++;
        level.ra_ws_text = ra_weyward_soul_text();
        nengine_store_set( "rex_arena", "boss_weyward_soul_event", level.ra_ws_text );
        if ( level.ra_ws_e <= 40 )
            nengine_store_set( "rex_arena", "boss_weyward_soul_event_" + level.ra_ws_e, level.ra_ws_text );
        nengine_store_save( "rex_arena", "runtime" );
    }
    if ( level.ra_ws_alive == 0 && !level.ra_ws_sh && level.ra_ws_cr == 0 && !level.ra_ws_storm )
        return;
    level.ra_ws_now = function_83bf4b34fbbe124b();
    if ( isdefined( level.ra_ws_t ) && level.ra_ws_now < level.ra_ws_t )
        return;
    level.ra_ws_t = level.ra_ws_now + 2000;
    level.ra_ws_n++;
    level.ra_ws_text = ra_weyward_soul_text();
    nengine_store_set( "rex_arena", "boss_weyward_souls", level.ra_ws_text );
    if ( level.ra_ws_n <= 30 )
        nengine_store_set( "rex_arena", "boss_weyward_souls_" + level.ra_ws_n, level.ra_ws_text );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.35: Shadow Souls in the arena. The game places each soul by setting the
// origin of the mover it rides (var_5cbd68ae26bbcf9a) to a spot in the
// Weyward's own arena (function_de92f052633c1fa1) and nothing moves it after
// that. A placed soul more than 5000 units from the arena centre is put, the
// same way, on the next of nine arena spots (places the Weyward stood in the
// 0.5.33 run, far apart, 100 units up); its spot field (var_2a28dc6cba206399)
// follows. Records boss_weyward_soul_moved (first 20 also numbered).
function ra_weyward_soul_home( soul )
{
    if ( !isdefined( soul.var_5cbd68ae26bbcf9a ) )
        return;
    level.ra_wsh_d = int( distance( soul.var_5cbd68ae26bbcf9a.origin, ( 29424, -27424, 2216 ) ) );
    if ( level.ra_wsh_d <= 5000 )
        return;
    level.ra_wsh_from = soul.var_5cbd68ae26bbcf9a.origin;
    level.ra_wsh_spot = level.ra_soul_spots[ level.ra_wsh_k % level.ra_soul_spots.size ];
    level.ra_wsh_k++;
    soul.var_5cbd68ae26bbcf9a.origin = level.ra_wsh_spot;
    soul.var_2a28dc6cba206399 = level.ra_wsh_spot;
    level.ra_wsh_n++;
    level.ra_wsh_text = "round " + level.ra_sp_round + ": soul " + level.ra_wsh_n + " from " + level.ra_wsh_from + " (" + level.ra_wsh_d + " from the arena centre) to arena spot " + ( ( level.ra_wsh_k - 1 ) % level.ra_soul_spots.size + 1 ) + " " + level.ra_wsh_spot;
    nengine_store_set( "rex_arena", "boss_weyward_soul_moved", level.ra_wsh_text );
    if ( level.ra_wsh_n <= 20 )
        nengine_store_set( "rex_arena", "boss_weyward_soul_moved_" + level.ra_wsh_n, level.ra_wsh_text );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.36: shadow storm crystals in the arena. The Weyward's bomb attack
// (script_190e128009243fcb) makes them as AIs on struct groups of its own
// arena; the storm (core script_1ccff940e7de18ed) is centred on the living
// crystals. A living crystal more than 5000 units from the arena centre is
// put, once, on a free arena spot (no living crystal within 200 units), the
// way the Weyward is put back (ra_weyward_crystal_move).
function ra_weyward_crystal_home( crystal )
{
    if ( istrue( crystal.ra_crystal_moved ) )
        return;
    level.ra_wch_d = int( distance( crystal.origin, ( 29424, -27424, 2216 ) ) );
    if ( level.ra_wch_d <= 5000 )
        return;
    crystal.ra_crystal_moved = 1;
    level.ra_wch_spot = undefined;
    level.ra_wch_j = 0;
    while ( level.ra_wch_j < level.ra_crystal_spots.size && !isdefined( level.ra_wch_spot ) )
    {
        level.ra_wch_try = level.ra_crystal_spots[ ( level.ra_wc_k + level.ra_wch_j ) % level.ra_crystal_spots.size ];
        if ( !ra_weyward_crystal_near( level.ra_wch_try ) )
        {
            level.ra_wch_spot = level.ra_wch_try;
            level.ra_wc_k = level.ra_wc_k + level.ra_wch_j + 1;
        }
        level.ra_wch_j++;
    }
    if ( !isdefined( level.ra_wch_spot ) )
    {
        level.ra_wch_spot = level.ra_crystal_spots[ level.ra_wc_k % level.ra_crystal_spots.size ];
        level.ra_wc_k++;
    }
    level.ra_wc_n++;
    level thread ra_weyward_crystal_move( crystal, crystal.origin, level.ra_wch_d, level.ra_wch_spot, level.ra_wc_n );
}

// 0.5.38: the storm in the middle of the arena. The storm module makes its
// model (var_d415f9cad43b30f5, tag_origin_weyward_wipe_attack) over the
// average place of the living crystals plus a height
// (function_ba636707f671696d) and beams each crystal to it. Each new one is
// put once over the arena centre (boss_arena_ff_center) at the same height
// over the floor (its height over the crystals then, 400 when none lives).
// Records boss_weyward_storm_moved.
function ra_weyward_storm_home( boss )
{
    if ( !isdefined( boss.var_d415f9cad43b30f5 ) || istrue( boss.var_d415f9cad43b30f5.ra_storm_moved ) )
        return;
    level.ra_wst = boss.var_d415f9cad43b30f5;
    level.ra_wst.ra_storm_moved = 1;
    level.ra_wst_z = 0;
    level.ra_wst_n = 0;
    level.ra_wst_i = 0;
    while ( isdefined( boss.var_ffbac11aaec6ae15 ) && level.ra_wst_i < boss.var_ffbac11aaec6ae15.size )
    {
        level.ra_wst_c = boss.var_ffbac11aaec6ae15[ level.ra_wst_i ];
        if ( isdefined( level.ra_wst_c ) && isalive( level.ra_wst_c ) )
        {
            level.ra_wst_z = level.ra_wst_z + level.ra_wst_c.origin[ 2 ];
            level.ra_wst_n++;
        }
        level.ra_wst_i++;
    }
    level.ra_wst_c = undefined;
    level.ra_wst_h = 400;
    if ( level.ra_wst_n > 0 )
        level.ra_wst_h = level.ra_wst.origin[ 2 ] - level.ra_wst_z / level.ra_wst_n;
    level.ra_wst_from = level.ra_wst.origin;
    level.ra_wst.origin = ( 29424, -27424, 2216 + level.ra_wst_h );
    level.ra_wst_k++;
    nengine_store_set( "rex_arena", "boss_weyward_storm_moved", "round " + level.ra_sp_round + ": storm " + level.ra_wst_k + " from " + level.ra_wst_from + " (" + int( distance( level.ra_wst_from, ( 29424, -27424, 2216 ) ) ) + " from the arena centre, " + int( level.ra_wst_h ) + " over " + level.ra_wst_n + " crystals) to " + level.ra_wst.origin );
    nengine_store_save( "rex_arena", "runtime" );
    level.ra_wst = undefined;
}

// 0.5.36: a living crystal of the Weyward's within 200 units of a place.
function ra_weyward_crystal_near( spot )
{
    level.ra_wcn_ai = level.ra_g_ai[ 3 ];
    level.ra_wcn_i = 0;
    while ( isdefined( level.ra_wcn_ai ) && isdefined( level.ra_wcn_ai.var_ffbac11aaec6ae15 ) && level.ra_wcn_i < level.ra_wcn_ai.var_ffbac11aaec6ae15.size )
    {
        level.ra_wcn_c = level.ra_wcn_ai.var_ffbac11aaec6ae15[ level.ra_wcn_i ];
        level.ra_wcn_i++;
        if ( isdefined( level.ra_wcn_c ) && isalive( level.ra_wcn_c ) && distance( level.ra_wcn_c.origin, spot ) < 200 )
        {
            level.ra_wcn_ai = undefined;
            level.ra_wcn_c = undefined;
            return true;
        }
    }
    level.ra_wcn_ai = undefined;
    level.ra_wcn_c = undefined;
    return false;
}

// 0.5.36: put a crystal on its arena spot with setorigin (as
// ra_weyward_bring_back), look again 1 s later and set it once more if it is
// more than 300 units off; record where it is then. Own thread.
function ra_weyward_crystal_move( crystal, from, far, spot, n )
{
    level endon( #"game_ended" );
    // 0.5.38: on the floor at the spot: a trace down from 300 above to 400
    // under it; the spot's own height when nothing is hit or the hit is more
    // than 150 over it (a pillar or an arch)
    crystal.ra_spot = spot;
    crystal.ra_floor = "no floor hit";
    level.ra_wcm_floor = physicstrace( spot + ( 0, 0, 300 ), spot - ( 0, 0, 400 ) );
    if ( isdefined( level.ra_wcm_floor ) && level.ra_wcm_floor[ 2 ] > spot[ 2 ] - 399 && level.ra_wcm_floor[ 2 ] < spot[ 2 ] + 150 )
    {
        crystal.ra_spot = ( spot[ 0 ], spot[ 1 ], level.ra_wcm_floor[ 2 ] + 2 );
        crystal.ra_floor = "floor at " + int( level.ra_wcm_floor[ 2 ] );
    }
    crystal dontinterpolate();
    crystal setorigin( crystal.ra_spot );
    wait 1;
    // 1.1.4: the note per crystal number; crystals move at the same time
    if ( !isdefined( level.ra_wcm_ag ) )
        level.ra_wcm_ag = [];
    level.ra_wcm_ag[ n ] = "";
    if ( isdefined( crystal ) && isalive( crystal ) && distance( crystal.origin, crystal.ra_spot ) > 300 )
    {
        crystal dontinterpolate();
        crystal setorigin( crystal.ra_spot );
        level.ra_wcm_ag[ n ] = " (set again)";
        wait 1;
    }
    if ( isdefined( crystal ) && isalive( crystal ) )
        level.ra_wcm_text = "round " + level.ra_sp_round + ": crystal " + n + " from " + from + " (" + far + " from the arena centre) to " + crystal.ra_spot + " (" + crystal.ra_floor + ")" + level.ra_wcm_ag[ n ] + "; then at " + crystal.origin + ", " + int( distance( crystal.origin, crystal.ra_spot ) ) + " from the spot";
    else
        level.ra_wcm_text = "round " + level.ra_sp_round + ": crystal " + n + " from " + from + " (" + far + " from the arena centre) to " + spot + level.ra_wcm_ag[ n ] + "; then gone";
    nengine_store_set( "rex_arena", "boss_weyward_crystal_moved", level.ra_wcm_text );
    if ( n <= 20 )
        nengine_store_set( "rex_arena", "boss_weyward_crystal_moved_" + n, level.ra_wcm_text );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.34: the record text for ra_weyward_souls: phase, shield, immune, souls
// in the list / alive / placed, the damage the Weyward then takes and where it
// is; each soul's place, distance from the arena centre and from the Weyward,
// health, placed mark and spot; the player's place and nearest soul.
function ra_weyward_soul_text()
{
    level.ra_wt_ai = level.ra_g_ai[ 3 ];
    level.ra_wt_text = "round " + level.ra_sp_round + ", " + int( ( function_83bf4b34fbbe124b() - level.ra_made_t[ 3 ] ) / 1000 ) + " s after made: phase " + level.ra_ws_ph + ", shield " + level.ra_ws_sh + ", immune " + level.ra_ws_im + ", souls in list " + level.ra_ws_all + ", alive " + level.ra_ws_alive + ", placed " + level.ra_ws_placed + ", damage " + ( 100 - level.ra_ws_cut ) + "%; Weyward at " + level.ra_wt_ai.origin + ", " + int( distance( level.ra_wt_ai.origin, ( 29424, -27424, 2216 ) ) ) + " from the arena centre";
    level.ra_wt_near = -1;
    level.ra_wt_i = 0;
    while ( isdefined( level.ra_wt_ai.var_14b016fe8b256eed ) && level.ra_wt_i < level.ra_wt_ai.var_14b016fe8b256eed.size )
    {
        level.ra_wt_s = level.ra_wt_ai.var_14b016fe8b256eed[ level.ra_wt_i ];
        level.ra_wt_i++;
        if ( !isdefined( level.ra_wt_s ) || !isalive( level.ra_wt_s ) )
        {
            level.ra_wt_text = level.ra_wt_text + "; soul " + level.ra_wt_i + " dead";
            continue;
        }
        level.ra_wt_text = level.ra_wt_text + "; soul " + level.ra_wt_i + " at " + level.ra_wt_s.origin + ", " + int( distance( level.ra_wt_s.origin, ( 29424, -27424, 2216 ) ) ) + " from the centre, " + int( distance( level.ra_wt_s.origin, level.ra_wt_ai.origin ) ) + " from the Weyward, health " + level.ra_wt_s.health + ", placed " + ( istrue( level.ra_wt_s.var_31ee4cc6f0acd713 ) ? 1 : 0 );
        if ( isdefined( level.ra_wt_s.var_2a28dc6cba206399 ) )
            level.ra_wt_text = level.ra_wt_text + ", spot " + level.ra_wt_s.var_2a28dc6cba206399;
        if ( isdefined( level.players ) && level.players.size > 0 && isdefined( level.players[ 0 ] ) )
        {
            level.ra_wt_d = int( distance( level.ra_wt_s.origin, level.players[ 0 ].origin ) );
            if ( level.ra_wt_near < 0 || level.ra_wt_d < level.ra_wt_near )
                level.ra_wt_near = level.ra_wt_d;
        }
    }
    // 0.5.36: crystals and the storm
    level.ra_wt_text = level.ra_wt_text + "; crystals alive " + level.ra_ws_cr + ", storm " + level.ra_ws_storm;
    if ( isdefined( level.ra_wt_ai.var_d415f9cad43b30f5 ) )
        level.ra_wt_text = level.ra_wt_text + " at " + level.ra_wt_ai.var_d415f9cad43b30f5.origin;
    level.ra_wt_ci = 0;
    while ( isdefined( level.ra_wt_ai.var_ffbac11aaec6ae15 ) && level.ra_wt_ci < level.ra_wt_ai.var_ffbac11aaec6ae15.size )
    {
        level.ra_wt_c = level.ra_wt_ai.var_ffbac11aaec6ae15[ level.ra_wt_ci ];
        level.ra_wt_ci++;
        if ( isdefined( level.ra_wt_c ) && isalive( level.ra_wt_c ) )
            level.ra_wt_text = level.ra_wt_text + "; crystal " + level.ra_wt_ci + " at " + level.ra_wt_c.origin + ", " + int( distance( level.ra_wt_c.origin, ( 29424, -27424, 2216 ) ) ) + " from the centre, health " + level.ra_wt_c.health;
    }
    level.ra_wt_c = undefined;
    if ( isdefined( level.players ) && level.players.size > 0 && isdefined( level.players[ 0 ] ) )
        level.ra_wt_text = level.ra_wt_text + "; player at " + level.players[ 0 ].origin + ", " + int( distance( level.players[ 0 ].origin, ( 29424, -27424, 2216 ) ) ) + " from the centre, nearest soul " + ( level.ra_wt_near < 0 ? "none" : "" + level.ra_wt_near );
    level.ra_wt_ai = undefined;
    level.ra_wt_s = undefined;
    return level.ra_wt_text;
}

// 0.5.34: no trial rooms in the arena. At the Weyward's change from phase 2
// to 3 (40% health) the game's boss script (core script_5cda26b07ee216bf,
// function_257578735511440f) calls Rex's trial hook level.var_348a1070393d7e6a
// (script_29f8fb7095fe1210, function_9d592bf4751a9015), which puts each
// player into one of the Weyward's four rooms. The boss script calls it only
// when it is defined, and Rex's own final fight is its only other reader, so
// while the Weyward lives in the arena it is kept undefined
// (boss_weyward_trial). A player more than 20000 units from the arena centre
// while the Weyward lives is recorded (boss_weyward_player_far_N, first 10).
function ra_weyward_no_trial()
{
    if ( isdefined( level.var_348a1070393d7e6a ) )
    {
        level.var_348a1070393d7e6a = undefined;
        level.ra_wtr_n++;
        nengine_store_set( "rex_arena", "boss_weyward_trial", "round " + level.ra_sp_round + ": Rex's trial-room hook taken off " + level.ra_wtr_n + " time(s), last with the Weyward at health " + level.ra_g_ai[ 3 ].health + " of " + level.ra_g_ai[ 3 ].maxhealth );
        nengine_store_save( "rex_arena", "runtime" );
    }
    if ( !isdefined( level.players ) || level.players.size == 0 || !isdefined( level.players[ 0 ] ) )
        return;
    level.ra_wfar_d = int( distance( level.players[ 0 ].origin, ( 29424, -27424, 2216 ) ) );
    if ( level.ra_wfar_d <= 20000 )
    {
        level.ra_wfar_on = 0;
        return;
    }
    if ( level.ra_wfar_on )
        return;
    level.ra_wfar_on = 1;
    level.ra_wfar_n++;
    if ( level.ra_wfar_n > 10 )
        return;
    nengine_store_set( "rex_arena", "boss_weyward_player_far_" + level.ra_wfar_n, "round " + level.ra_sp_round + ", " + int( ( function_83bf4b34fbbe124b() - level.ra_made_t[ 3 ] ) / 1000 ) + " s after the Weyward was made: player at " + level.players[ 0 ].origin + ", " + level.ra_wfar_d + " from the arena centre; Weyward phase " + level.ra_ws_ph + ", health " + level.ra_g_ai[ 3 ].health + " of " + level.ra_g_ai[ 3 ].maxhealth + ", immune " + level.ra_ws_im + ", trial hook " + ( isdefined( level.var_348a1070393d7e6a ) ? "set" : "off" ) );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.39: between phases the Weyward stands in the middle of the arena. For
// its phase change (immune, var_9b230d276449dbc8) the boss script
// (script_5cda26b07ee216bf, function_beb4b6db05298dd8) moves it to a struct of
// its own arena for about 20 s and back to where it was at the end. While it
// is immune and more than 3500 units from the arena centre, it is put on the
// centre (boss_arena_ff_center) with setorigin, at most once a second.
// Records boss_weyward_phase_centre.
function ra_weyward_phase_centre()
{
    level.ra_wpc_ai = level.ra_g_ai[ 3 ];
    if ( !istrue( level.ra_wpc_ai.var_9b230d276449dbc8 ) )
        return;
    level.ra_wpc_d = int( distance( level.ra_wpc_ai.origin, ( 29424, -27424, 2216 ) ) );
    if ( level.ra_wpc_d <= 3500 )
        return;
    level.ra_wpc_now = function_83bf4b34fbbe124b();
    if ( isdefined( level.ra_wpc_t ) && level.ra_wpc_now < level.ra_wpc_t )
        return;
    level.ra_wpc_t = level.ra_wpc_now + 1000;
    level.ra_wpc_from = level.ra_wpc_ai.origin;
    level.ra_wpc_ai dontinterpolate();
    level.ra_wpc_ai setorigin( ( 29424, -27424, 2216 ) );
    level.ra_wpc_n++;
    nengine_store_set( "rex_arena", "boss_weyward_phase_centre", "round " + level.ra_sp_round + ": " + level.ra_wpc_n + " time(s); last in phase " + level.ra_wpc_ai.var_96eb4eec60875abc + " from " + level.ra_wpc_from + " (" + level.ra_wpc_d + " from the arena centre) to the arena centre, health " + level.ra_wpc_ai.health + " of " + level.ra_wpc_ai.maxhealth );
    nengine_store_save( "rex_arena", "runtime" );
    level.ra_wpc_ai = undefined;
}

// 0.5.32: put the Weyward back at its spawn point with setorigin (as the drop
// puts players), then record where it is 1 s later. Own thread, so a fault
// here cannot stop the boss guard.
function ra_weyward_bring_back( ai, from, far )
{
    level endon( #"game_ended" );
    level.ra_wb_n++;
    level.ra_wb_i = level.ra_wb_n;
    nengine_store_set( "rex_arena", "boss_weyward_moved_" + level.ra_wb_i, "round " + level.ra_sp_round + ": from " + from + " (" + far + " from the centre): moving" );
    nengine_store_save( "rex_arena", "runtime" );
    ai dontinterpolate();
    ai setorigin( ( 28984, -27424, 2216 ) );
    wait 1;
    if ( isdefined( ai ) && isalive( ai ) )
        level.ra_wb_text = "at " + ai.origin + ", " + int( distance( ai.origin, ( 29424, -27424, 2216 ) ) ) + " from the centre";
    else
        level.ra_wb_text = "gone";
    nengine_store_set( "rex_arena", "boss_weyward_moved_" + level.ra_wb_i, "round " + level.ra_sp_round + ": from " + from + " (" + far + " from the centre); 1 s later " + level.ra_wb_text );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.32: a hit on the Weyward in its damage callback: by a player, one of this
// mod's bosses, something else, or nothing; how far away the attacker was,
// where the Weyward was, and how far the Guardian was.
function ra_weyward_hit_note( params )
{
    level.ra_wh_n++;
    level.ra_wh_who = "none";
    level.ra_wh_far = "?";
    if ( isdefined( params.var_917e21c98d80255e ) )
    {
        level.ra_wh_who = "other";
        if ( isdefined( params.var_917e21c98d80255e.ra_boss_index ) )
            level.ra_wh_who = "boss " + params.var_917e21c98d80255e.ra_boss_index;
        level.ra_wh_i = 0;
        while ( isdefined( level.players ) && level.ra_wh_i < level.players.size )
        {
            if ( isdefined( level.players[ level.ra_wh_i ] ) && level.players[ level.ra_wh_i ] == params.var_917e21c98d80255e )
                level.ra_wh_who = "player";
            level.ra_wh_i++;
        }
        if ( isdefined( params.var_917e21c98d80255e.origin ) )
            level.ra_wh_far = int( distance( params.var_917e21c98d80255e.origin, self.origin ) );
    }
    level.ra_wh_g = "none";
    if ( ra_boss_alive( level.ra_guardian_ai, 1 ) )
        level.ra_wh_g = int( distance( level.ra_guardian_ai.origin, self.origin ) );
    level.ra_wh_text = "round " + level.ra_sp_round + ": " + level.ra_wh_n + " hits; last " + params.var_a87b62c261a8d114 + " by " + level.ra_wh_who + " (" + level.ra_wh_far + " units away) at health " + self.health + ", at " + self.origin + ", Guardian " + level.ra_wh_g + " units away, souls placed " + level.ra_ws_placed + ", shield " + level.ra_ws_sh + ", damage " + ( 100 - level.ra_ws_cut ) + "%";
    if ( level.ra_wh_n <= 10 || level.ra_wh_n % 10 == 0 )
    {
        nengine_store_set( "rex_arena", "boss_weyward_hits", level.ra_wh_text );
        if ( level.ra_wh_n <= 10 )
            nengine_store_set( "rex_arena", "boss_weyward_hit_" + level.ra_wh_n, level.ra_wh_text );
        nengine_store_save( "rex_arena", "runtime" );
    }
}

// 0.5.31: the Weyward's death event (the one Rex registers for its bosses):
// the instant-kill mark, read before the guard's next look. One the guard
// will make again leaves no body (as Caltheris's, 0.5.26).
function ra_weyward_death_info( params )
{
    if ( !isdefined( self.ra_boss_index ) || self.ra_boss_index != 3 )
        return;
    level.ra_w_mark = isdefined( self.var_a472e925a028ede0 ) && self.var_a472e925a028ede0 ? 1 : 0;
    if ( ra_weyward_remake_ok() )
    {
        self.nocorpse = 1;
        self hide();
        level thread ra_weyward_corpse_hide( self );
    }
    nengine_store_set( "rex_arena", "boss_weyward_deathinfo", "round " + level.ra_sp_round + ": health " + self.health + ", instant-kill mark " + level.ra_w_mark + ", other boss alive " + ( ra_weyward_other() ? 1 : 0 ) );
}

// 0.5.31: the corpse of a hidden dead Weyward, looked for every 0.1 s for 1 s
// and hidden (as ra_caltheris_corpse_hide). Own thread.
function ra_weyward_corpse_hide( ai )
{
    level endon( #"game_ended" );
    level.ra_whd_t = 0;
    while ( level.ra_whd_t < 10 )
    {
        if ( !isdefined( ai ) )
            break;
        level.ra_whd_c = ai getcorpseentity();
        if ( isdefined( level.ra_whd_c ) )
        {
            level.ra_whd_c hide();
            level.ra_whd_c = undefined;
            nengine_store_set( "rex_arena", "boss_weyward_hide", "round " + level.ra_sp_round + ": hidden at death; body found after " + level.ra_whd_t * 100 + " ms and hidden" );
            nengine_store_save( "rex_arena", "runtime" );
            return;
        }
        level.ra_whd_t++;
        wait 0.1;
    }
    nengine_store_set( "rex_arena", "boss_weyward_hide", "round " + level.ra_sp_round + ": hidden at death; no body within 1 s" + ( isdefined( ai ) ? "" : " (entity gone)" ) );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.31: one-shot hold for the Weyward (as ra_guardian_hold_late).
function ra_weyward_hold_late( params )
{
    if ( !isdefined( self ) || !isdefined( self.ra_boss_index ) || self.ra_boss_index != 3 || !isalive( self ) )
        return;
    // 0.5.32: every damage event on the Weyward, counted.
    if ( isdefined( params ) && isdefined( params.var_a87b62c261a8d114 ) )
    {
        level.ra_wl_n++;
        if ( level.ra_wl_n <= 10 || level.ra_wl_n % 10 == 0 )
        {
            nengine_store_set( "rex_arena", "boss_weyward_dmg_event", "round " + level.ra_sp_round + ": " + level.ra_wl_n + " damage events; last " + params.var_a87b62c261a8d114 + " at health " + self.health + ", at " + self.origin );
            nengine_store_save( "rex_arena", "runtime" );
        }
    }
    // 0.5.40: a second fake death. After its first one (var_f9e26f943ef4abc)
    // and its revive (var_ba89dbfc67972f95 back to 1) the Weyward's damage
    // callback (function_bd924e62aafac328) makes the next fall to 1000 health
    // its last death. Once per Weyward, the hit that leaves it at 10000 health
    // or less clears that mark (which also gives its abilities their later
    // settings, so not for long), so that fall is a second fake death and the
    // one after it the last.
    if ( !istrue( self.ra_fo_armed ) && isdefined( params ) && isdefined( params.var_a87b62c261a8d114 ) && istrue( self.var_f9e26f943ef4abc ) && istrue( self.var_ba89dbfc67972f95 ) && !istrue( self.var_426cbbee92f4e599 ) && self.health - params.var_a87b62c261a8d114 <= 10000 )
    {
        self.ra_fo_armed = 1;
        self.var_f9e26f943ef4abc = 0;
        nengine_store_set( "rex_arena", "boss_weyward_fakeout", "round " + level.ra_sp_round + ": second fake death set up by a hit of " + params.var_a87b62c261a8d114 + " at health " + self.health + " of " + self.maxhealth );
        nengine_store_save( "rex_arena", "runtime" );
    }
    if ( !isdefined( params ) || !isdefined( params.var_a87b62c261a8d114 ) || self.health <= 1 || params.var_a87b62c261a8d114 < self.health )
        return;
    level.ra_held[ 3 ] = 1;
    nengine_store_set( "rex_arena", "boss_weyward_lethal_held", "round " + level.ra_sp_round + ": hit of " + params.var_a87b62c261a8d114 + " at health " + self.health + " held at 1" );
    nengine_store_save( "rex_arena", "runtime" );
    params.var_a87b62c261a8d114 = self.health - 1;
}

// 0.5.17: Caltheris (boss 2). While it lives its health and place are kept;
// when it is gone its death is written to the store and the bars are put
// right. 0.5.25: as the Guardian, it is made again where it died with its
// health when another boss is alive and it died with the instant-kill mark
// (from its death event) or above 5% of its health (a player's kill ends near
// 0); its phase is set back and Rex's per-phase settings are reloaded.
function ra_caltheris_guard()
{
    if ( !level.ra_g_on[ 2 ] )
        return;
    if ( ra_boss_alive( level.ra_g_ai[ 2 ], 2 ) )
    {
        level.ra_g_hp[ 2 ] = level.ra_g_ai[ 2 ].health;
        level.ra_g_max[ 2 ] = level.ra_g_ai[ 2 ].maxhealth;
        level.ra_g_org[ 2 ] = level.ra_g_ai[ 2 ].origin;
        level.ra_g_ang[ 2 ] = level.ra_g_ai[ 2 ].angles;
        if ( !istrue( level.ra_g_ai[ 2 ].var_8f1c21afe4877bb5 ) )
        {
            level.ra_g_ai[ 2 ].var_8f1c21afe4877bb5 = 1;
            nengine_store_set( "rex_arena", "boss_caltheris_transition", "round " + level.ra_sp_round + ": its own phase-change field cleared in phase " + level.ra_g_ai[ 2 ].var_c1a14ef3b76e22c5 + " at health " + level.ra_g_ai[ 2 ].health + "; set again" );
            nengine_store_save( "rex_arena", "runtime" );
        }
        if ( isdefined( level.ra_g_ai[ 2 ].var_c1a14ef3b76e22c5 ) && ( !isdefined( level.ra_cal_phase ) || level.ra_cal_phase != level.ra_g_ai[ 2 ].var_c1a14ef3b76e22c5 ) )
        {
            level.ra_cal_phase = level.ra_g_ai[ 2 ].var_c1a14ef3b76e22c5;
            nengine_store_set( "rex_arena", "boss_caltheris_phase", "round " + level.ra_sp_round + ": phase " + level.ra_cal_phase + " at health " + level.ra_g_ai[ 2 ].health + " of " + level.ra_g_ai[ 2 ].maxhealth );
            nengine_store_save( "rex_arena", "runtime" );
        }
        return;
    }
    level.ra_g_on[ 2 ] = 0;
    level.ra_cg_gone = level.ra_g_ai[ 2 ];
    level.ra_g_ai[ 2 ] = undefined;
    level.ra_caltheris_ai = undefined;
    level.ra_cg_text = "round " + level.ra_sp_round + ": health " + level.ra_g_hp[ 2 ] + " of " + level.ra_g_max[ 2 ] + ", Z-Rex alive " + ( ra_boss_alive( level.ra_zrex_ai, 0 ) ? 1 : 0 );
    if ( isdefined( level.ra_g_org[ 2 ] ) && isdefined( level.ra_cr_home ) )
        level.ra_cg_text = level.ra_cg_text + ", " + int( distance( level.ra_g_org[ 2 ], level.ra_cr_home ) ) + " units from its spawn point";
    level.ra_cg_other = 0;
    if ( ( level.ra_g_on[ 0 ] && ra_boss_alive( level.ra_g_ai[ 0 ], 0 ) ) || ( level.ra_g_on[ 1 ] && ra_boss_alive( level.ra_g_ai[ 1 ], 1 ) ) )
        level.ra_cg_other = 1;
    level.ra_cg_text = level.ra_cg_text + ", other boss alive " + level.ra_cg_other + ", instant-kill mark " + level.ra_cal_mark + ", phase " + ( isdefined( level.ra_cal_phase ) ? level.ra_cal_phase : "none" ) + ", shield " + ( isdefined( level.ra_cal_sh ) ? 1 : 0 );
    if ( isdefined( level.ra_made_t[ 2 ] ) )
        level.ra_cg_text = level.ra_cg_text + ", " + ( function_83bf4b34fbbe124b() - level.ra_made_t[ 2 ] ) + " ms after it was made";
    if ( isdefined( level.ra_g_org[ 2 ] ) )
        level.ra_cg_text = level.ra_cg_text + ", at " + level.ra_g_org[ 2 ];
    if ( level.ra_cg_other && isdefined( level.ra_g_org[ 2 ] ) && ( level.ra_cal_mark || level.ra_g_hp[ 2 ] > level.ra_g_max[ 2 ] * 0.05 ) && ra_boss_can_remake( 2 ) && !istrue( level.ra_held[ 2 ] ) )
    {
        level.ra_cg_keep_hp = level.ra_g_hp[ 2 ];
        level.ra_cg_keep_ph = level.ra_cal_phase;
        level.ra_spawn_hp = level.ra_cg_keep_hp;
        if ( isdefined( level.ra_g_ang[ 2 ] ) )
            level.ra_boss_spawn_yaw = level.ra_g_ang[ 2 ][ 1 ];
        level.ra_cal_reviving = 1;
        if ( ra_boss_spawn( 2, level.ra_g_org[ 2 ] ) )
        {
            if ( level.ra_g_ai[ 2 ].health > level.ra_cg_keep_hp )
                level.ra_g_ai[ 2 ].health = level.ra_cg_keep_hp;
            level.ra_g_hp[ 2 ] = level.ra_g_ai[ 2 ].health;
            if ( isdefined( level.ra_cg_keep_ph ) && isdefined( level.ra_g_ai[ 2 ].var_c1a14ef3b76e22c5 ) && level.ra_g_ai[ 2 ].var_c1a14ef3b76e22c5 != level.ra_cg_keep_ph )
            {
                level.ra_g_ai[ 2 ].var_c1a14ef3b76e22c5 = level.ra_cg_keep_ph;
                level.ra_g_ai[ 2 ] ra_caltheris_phase_settings();
            }
            level.ra_cal_phase = level.ra_g_ai[ 2 ].var_c1a14ef3b76e22c5;
            level.ra_boss_revived++;
            nengine_store_set( "rex_arena", "boss_revived", level.ra_boss_revived );
            level.ra_cg_text = level.ra_cg_text + "; made again with " + level.ra_g_ai[ 2 ].health + " in phase " + ( isdefined( level.ra_cal_phase ) ? level.ra_cal_phase : "none" );
        }
        else
        {
            level.ra_boss_spawn_yaw = undefined;
            level.ra_cg_text = level.ra_cg_text + "; could not be made again";
        }
        level.ra_cal_reviving = undefined;
        level.ra_spawn_hp = undefined;
    }
    if ( !isdefined( level.ra_g_ai[ 2 ] ) && istrue( level.ra_held[ 2 ] ) )
        level.ra_cg_text = level.ra_cg_text + "; held at 1 before (a player's kill), left dead";
    if ( !isdefined( level.ra_g_ai[ 2 ] ) && level.ra_cg_other && !ra_boss_can_remake( 2 ) )
        level.ra_cg_text = level.ra_cg_text + "; died within 2 s of being made, left dead";
    nengine_store_set( "rex_arena", "boss_caltheris_death", level.ra_cg_text );
    if ( !isdefined( level.ra_cg_deaths ) )
        level.ra_cg_deaths = 0;
    level.ra_cg_deaths++;
    if ( level.ra_cg_deaths <= 20 )
        nengine_store_set( "rex_arena", "boss_caltheris_death_" + level.ra_cg_deaths, level.ra_cg_text );
    nengine_store_save( "rex_arena", "runtime" );
    if ( !isdefined( level.ra_g_ai[ 2 ] ) )
        ra_boss_final( 2 );
    // 0.5.88: the round-100 Caltheris is dead for good
    if ( !isdefined( level.ra_g_ai[ 2 ] ) && level.ra_cl_pap )
        ra_caltheris_pap_reward();
    if ( !isdefined( level.ra_g_ai[ 2 ] ) )
        level thread ra_boss_bar_down( level.ra_cg_gone );
    level.ra_cg_gone = undefined;
}

// 0.5.21: on the game's zombie-damaged event, after DellxCell's multiplier
// (as ra_zrex_hold_late). A hit on this mod's Caltheris that the game has cut
// below the damage this mod's damage callback saw is set back to it.
// 0.5.22: no damage during the phase shield; a hit under the next third starts
// it. Its own phase change stays blocked (spawn and boss
// guard), because in the arena it started but never finished.
function ra_caltheris_phase_late( params )
{
    if ( !isdefined( self ) || !isdefined( self.ra_boss_index ) || self.ra_boss_index != 2 || !isalive( self ) )
        return;
    if ( !isdefined( params ) || !isdefined( params.var_a87b62c261a8d114 ) )
        return;
    if ( isdefined( level.ra_cal_sh ) )
    {
        params.var_a87b62c261a8d114 = 0;
        level.ra_cal_sh_hits++;
        self.ra_cal_in = undefined;
        return;
    }
    level.ra_ch_late = params.var_a87b62c261a8d114;
    if ( isdefined( self.ra_cal_in ) && self.ra_cal_in > params.var_a87b62c261a8d114 )
    {
        params.var_a87b62c261a8d114 = self.ra_cal_in;
        level.ra_ch_up++;
        if ( level.ra_ch_up == 1 || level.ra_ch_up % 25 == 0 )
        {
            nengine_store_set( "rex_arena", "boss_caltheris_raised", "round " + level.ra_sp_round + ": " + level.ra_ch_up + " hits set back up; last " + level.ra_ch_late + " to " + self.ra_cal_in + " in phase " + self.var_c1a14ef3b76e22c5 );
            nengine_store_save( "rex_arena", "runtime" );
        }
    }
    level.ra_ch_n++;
    if ( level.ra_ch_n == 1 || level.ra_ch_n % 25 == 0 )
    {
        level.ra_ch_text = "round " + level.ra_sp_round + ", hit " + level.ra_ch_n + ": callback " + ( isdefined( self.ra_cal_in ) ? self.ra_cal_in : "none" ) + ", after game and DellxCell " + level.ra_ch_late + ", used " + params.var_a87b62c261a8d114 + ", health " + self.health + " phase " + self.var_c1a14ef3b76e22c5;
        if ( isdefined( self.ra_ch_prev_hp ) )
            level.ra_ch_text = level.ra_ch_text + "; previous hit used " + self.ra_ch_prev_dmg + ", health fell " + ( self.ra_ch_prev_hp - self.health );
        nengine_store_set( "rex_arena", "boss_caltheris_hit", level.ra_ch_text );
        nengine_store_save( "rex_arena", "runtime" );
    }
    self.ra_ch_prev_hp = self.health;
    self.ra_ch_prev_dmg = params.var_a87b62c261a8d114;
    self.ra_cal_in = undefined;
    // 0.5.27: one-shot hold: a hit that would kill it above 1 health leaves 1.
    if ( self.health > 1 && params.var_a87b62c261a8d114 >= self.health )
    {
        level.ra_held[ 2 ] = 1;
        nengine_store_set( "rex_arena", "boss_caltheris_lethal_held", "round " + level.ra_sp_round + ": hit of " + params.var_a87b62c261a8d114 + " at health " + self.health + " held at 1, phase " + self.var_c1a14ef3b76e22c5 );
        nengine_store_save( "rex_arena", "runtime" );
        params.var_a87b62c261a8d114 = self.health - 1;
    }
    if ( !isdefined( self.var_c1a14ef3b76e22c5 ) || self.var_c1a14ef3b76e22c5 >= 3 )
        return;
    // 0.5.22: a hit under the next third stops one point under it and starts
    // the 5 s phase shield (ra_caltheris_shield). 0.5.23: also with the whole
    // bar (var_474e63113b850e5d).
    level.ra_cc_line = int( self.maxhealth - self.maxhealth / 3 * self.var_c1a14ef3b76e22c5 );
    if ( self.health - params.var_a87b62c261a8d114 >= level.ra_cc_line )
        return;
    level.ra_cc_dmg = self.health - level.ra_cc_line + 1;
    if ( level.ra_cc_dmg < 0 )
        level.ra_cc_dmg = 0;
    if ( params.var_a87b62c261a8d114 > level.ra_cc_dmg )
        params.var_a87b62c261a8d114 = level.ra_cc_dmg;
    level.ra_cal_sh = 1;
    level.ra_cal_sh_hits = 0;
    self thread ra_caltheris_shield();
}

// 0.5.22: the phase shield. 0.5.23: for 5 s Caltheris takes no damage (damage
// callback and late step); its whole-health bar stays where it stopped. Then
// its phase goes up by one and Rex's per-phase settings are reloaded. Own
// thread on Caltheris.
function ra_caltheris_shield()
{
    self endon( #"death" );
    level endon( #"game_ended" );
    level.ra_cs_from = self.var_c1a14ef3b76e22c5;
    level.ra_cs_hp = self.health - level.ra_cc_dmg;
    // 0.5.24: the game's immune bar state (as script_5cda26b07ee216bf).
    level.ra_cs_shown = 0;
    level.ra_cs_i = 0;
    while ( isdefined( level.players ) && level.ra_cs_i < level.players.size )
    {
        if ( isdefined( level.players[ level.ra_cs_i ] ) && isdefined( level.players[ level.ra_cs_i ].var_7fa280bb4c563541 ) && level.players[ level.ra_cs_i ].var_7fa280bb4c563541 == self )
        {
            level.players[ level.ra_cs_i ] thread namespace_83b3fe93c7a4b9b4::function_e5a4de300c61a650( 1 );
            level.ra_cs_shown++;
        }
        level.ra_cs_i++;
    }
    wait 5;
    level.ra_cs_i = 0;
    while ( isdefined( level.players ) && level.ra_cs_i < level.players.size )
    {
        if ( isdefined( level.players[ level.ra_cs_i ] ) )
            level.players[ level.ra_cs_i ] thread namespace_83b3fe93c7a4b9b4::function_e5a4de300c61a650( 0 );
        level.ra_cs_i++;
    }
    self.var_8f1c21afe4877bb5 = 1;
    self.var_c1a14ef3b76e22c5 = self.var_c1a14ef3b76e22c5 + 1;
    self ra_caltheris_phase_settings();
    level.ra_cal_sh = undefined;
    nengine_store_set( "rex_arena", "boss_caltheris_shield", "round " + level.ra_sp_round + ": phase " + level.ra_cs_from + " to " + self.var_c1a14ef3b76e22c5 + " after 5 s immune at health " + self.health + " (stopped at " + level.ra_cs_hp + "), hits blocked " + level.ra_cal_sh_hits + ", whole bar " + istrue( self.var_474e63113b850e5d ) + ", immune bar shown to " + level.ra_cs_shown );
    nengine_store_set( "rex_arena", "boss_caltheris_phase_set", "round " + level.ra_sp_round + ": phase " + self.var_c1a14ef3b76e22c5 + " at health " + self.health + ", settings reloaded " + level.ra_cp_done );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.20: Rex's per-phase ability settings reload (function_1ec96503c85b8721,
// script_fd54ba823d404ad), which Rex's Boss Rush runs after setting phase 3.
// Its two builtin calls with Rex's own strings; Rex's script is outside the
// build's include rule.
function ra_caltheris_phase_settings()
{
    level.ra_cp_done = 0;
    if ( !isdefined( self.var_33117b8c6888723a ) )
        return;
    level.ra_cp_args = [];
    level.ra_cp_args[ "fight_phase" ] = self.var_c1a14ef3b76e22c5;
    level.ra_cp_val = self function_805ca5e408d630c0( self.var_33117b8c6888723a, "ground_slam", level.ra_cp_args, 0 );
    if ( isdefined( level.ra_cp_val ) )
    {
        self function_695b8e1b655c2796( "ground_slam", level.ra_cp_val );
        level.ra_cp_done = level.ra_cp_done + 1;
    }
    level.ra_cp_val = self function_805ca5e408d630c0( self.var_33117b8c6888723a, "ranged_attack_throw", level.ra_cp_args, 0 );
    if ( isdefined( level.ra_cp_val ) )
    {
        self function_695b8e1b655c2796( "ranged_attack_throw", level.ra_cp_val );
        level.ra_cp_done = level.ra_cp_done + 1;
    }
    level.ra_cp_val = undefined;
}

// 0.5.18: Caltheris's own death event (the one Rex registers for it): its
// health and the instant-kill mark, read before the guard's next look.
function ra_caltheris_death_info( params )
{
    if ( !isdefined( self.ra_boss_index ) || self.ra_boss_index != 2 )
        return;
    // 0.5.25: for the guard's rule
    level.ra_cal_mark = isdefined( self.var_a472e925a028ede0 ) && self.var_a472e925a028ede0 ? 1 : 0;
    // 0.5.26: one the guard will make again (as in ra_caltheris_guard) leaves
    // no body: hidden now, its corpse hidden when it appears.
    if ( ( level.ra_cal_mark || level.ra_g_hp[ 2 ] > level.ra_g_max[ 2 ] * 0.05 ) && ra_boss_can_remake( 2 ) && !istrue( level.ra_held[ 2 ] ) && ( ( level.ra_g_on[ 0 ] && ra_boss_alive( level.ra_g_ai[ 0 ], 0 ) ) || ( level.ra_g_on[ 1 ] && ra_boss_alive( level.ra_g_ai[ 1 ], 1 ) ) ) )
    {
        self.nocorpse = 1;
        self hide();
        level thread ra_caltheris_corpse_hide( self );
    }
    nengine_store_set( "rex_arena", "boss_caltheris_deathinfo", "round " + level.ra_sp_round + ": health " + self.health + ", phase " + self.var_c1a14ef3b76e22c5 + ", instant-kill mark " + ( isdefined( self.var_a472e925a028ede0 ) && self.var_a472e925a028ede0 ? 1 : 0 ) + ", Z-Rex alive " + ( ra_boss_alive( level.ra_zrex_ai, 0 ) ? 1 : 0 ) );
}

// 0.5.26: the corpse of a hidden dead Caltheris, looked for every 0.1 s for
// 1 s and hidden. Own thread.
function ra_caltheris_corpse_hide( ai )
{
    level endon( #"game_ended" );
    level.ra_chd_t = 0;
    while ( level.ra_chd_t < 10 )
    {
        if ( !isdefined( ai ) )
            break;
        level.ra_chd_c = ai getcorpseentity();
        if ( isdefined( level.ra_chd_c ) )
        {
            level.ra_chd_c hide();
            level.ra_chd_c = undefined;
            nengine_store_set( "rex_arena", "boss_caltheris_hide", "round " + level.ra_sp_round + ": hidden at death, mark " + level.ra_cal_mark + "; body found after " + level.ra_chd_t * 100 + " ms and hidden" );
            nengine_store_save( "rex_arena", "runtime" );
            return;
        }
        level.ra_chd_t++;
        wait 0.1;
    }
    nengine_store_set( "rex_arena", "boss_caltheris_hide", "round " + level.ra_sp_round + ": hidden at death, mark " + level.ra_cal_mark + "; no body within 1 s" + ( isdefined( ai ) ? "" : " (entity gone)" ) );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.18: the main bar value of the boss it follows. For Caltheris it is what
// its own bar callback shows (function_aa647407d5c4af0, its type script
// script_630a77a502f15d9e): the current third of its health, unless
// var_474e63113b850e5d is set. Others: health of max health.
function ra_b2_main_value()
{
    level.ra_b2_mh = level.ra_b2_main.health;
    level.ra_b2_mm = level.ra_b2_main.maxhealth;
    if ( isdefined( level.ra_b2_main.ra_boss_index ) && level.ra_b2_main.ra_boss_index == 2 && !istrue( level.ra_b2_main.var_474e63113b850e5d ) && isdefined( level.ra_b2_main.var_c1a14ef3b76e22c5 ) )
    {
        level.ra_b2_mm = level.ra_b2_main.maxhealth / 3;
        level.ra_b2_mh = level.ra_b2_main.health - level.ra_b2_mm * ( 3 - level.ra_b2_main.var_c1a14ef3b76e22c5 );
        if ( level.ra_b2_mh <= 0 )
            level.ra_b2_mh = 0;
    }
}

// 0.5.17: how far Caltheris goes from where it was made (Rex makes it in its
// own arena; here it is in the arena match's). Own thread.
function ra_caltheris_roam_watch()
{
    self endon( #"death" );
    level endon( #"game_ended" );
    level.ra_cr_home = self.origin;
    level.ra_cr_far = 0;
    level.ra_cr_said = 0;
    nengine_store_set( "rex_arena", "boss_caltheris_roam", "made in round " + level.ra_sp_round );
    while ( true )
    {
        wait 1;
        level.ra_cr_d = int( distance( self.origin, level.ra_cr_home ) );
        if ( level.ra_cr_d > level.ra_cr_far )
            level.ra_cr_far = level.ra_cr_d;
        if ( level.ra_cr_far >= level.ra_cr_said + 100 )
        {
            level.ra_cr_said = level.ra_cr_far;
            nengine_store_set( "rex_arena", "boss_caltheris_roam", "round " + level.ra_sp_round + ": up to " + level.ra_cr_far + " units from its spawn point (now " + level.ra_cr_d + "), health " + self.health + " of " + self.maxhealth );
        }
    }
}

// The second health bar. The game's bar follows one boss; while both are
// alive the other one is written to the dvar rex_arena_bar2 as
// "NAME|health|max|server time|bar list id", from which the mod Lua shows a
// second copy of the game's bar widget under the first. An empty value hides
// it. What the Lua used (the copy, or its own drawing) comes back in the dvar
// rex_arena_bar2_ui and is kept in the store.
// The game's bar script lets every boss type write its health to that one
// bar (function_34fa8d0cfe24d6aa, registered by function_f50a10314e72caa1 in
// both type scripts). While both are alive the boss the bar does not follow
// has that callback taken off (function_d16104a6c7125d2d) and the followed
// one has it registered; if the other boss's health still changed, the
// followed boss's value is written to the bar again. When one boss is left
// it gets its callback back.
function ra_boss_bar2()
{
    // 0.5.27: what the mod Lua's HUD block did (0.5.28: the note only).
    ra_boss_hud_record();
    // 0.5.25: from the round-500 event on, the bars are in a row.
    if ( level.ra_bar_h )
    {
        ra_boss_bar_trio();
        return;
    }
    level.ra_b2_text = "";
    // 0.5.17: Z-Rex's partner is the Guardian, else Caltheris.
    level.ra_b2_pa = undefined;
    if ( ra_boss_alive( level.ra_guardian_ai, 1 ) )
    {
        level.ra_b2_pa = level.ra_guardian_ai;
        level.ra_b2_pn = "THE GUARDIAN";
    }
    else if ( ra_boss_alive( level.ra_caltheris_ai, 2 ) )
    {
        level.ra_b2_pa = level.ra_caltheris_ai;
        level.ra_b2_pn = "CALTHERIS";
    }
    if ( ra_boss_alive( level.ra_zrex_ai, 0 ) && isdefined( level.ra_b2_pa ) )
    {
        level.ra_b2_ai = level.ra_zrex_ai;
        level.ra_b2_main = level.ra_b2_pa;
        level.ra_b2_name = "Z-REX";
        if ( !isdefined( level.ra_zrex_bar_id ) )
            ra_boss_bar_ids();
        level.ra_b2_id = level.ra_zrex_bar_id;
        if ( level.ra_b2_pn == "CALTHERIS" )
        {
            // 0.5.18: the main bar stays on Caltheris (its own phase bar).
            level.ra_b2_i = 0;
            while ( isdefined( level.players ) && level.ra_b2_i < level.players.size )
            {
                if ( isdefined( level.players[ level.ra_b2_i ] ) && isdefined( level.players[ level.ra_b2_i ].var_7fa280bb4c563541 ) && level.players[ level.ra_b2_i ].var_7fa280bb4c563541 == level.ra_zrex_ai )
                    level.players[ level.ra_b2_i ] ra_caltheris_bar();
                level.ra_b2_i++;
            }
        }
        else if ( isdefined( level.players ) && level.players.size > 0 && isdefined( level.players[ 0 ] ) && isdefined( level.players[ 0 ].var_7fa280bb4c563541 ) && level.players[ 0 ].var_7fa280bb4c563541 == level.ra_zrex_ai )
        {
            level.ra_b2_ai = level.ra_b2_pa;
            level.ra_b2_main = level.ra_zrex_ai;
            level.ra_b2_name = level.ra_b2_pn;
            level.ra_b2_id = level.ra_guardian_bar_id;
        }
        level.ra_b2_text = level.ra_b2_name + "|" + level.ra_b2_ai.health + "|" + level.ra_b2_ai.maxhealth + "|" + function_83bf4b34fbbe124b() + "|" + level.ra_b2_id;
        level.ra_b2_ai namespace_83b3fe93c7a4b9b4::function_d16104a6c7125d2d();
        // 0.5.18: Caltheris keeps only its own bar callback.
        if ( !isdefined( level.ra_b2_main.ra_boss_index ) || level.ra_b2_main.ra_boss_index != 2 )
            level.ra_b2_main namespace_83b3fe93c7a4b9b4::function_f50a10314e72caa1();
        if ( level.ra_b2_other_hp != level.ra_b2_ai.health )
        {
            level.ra_b2_other_hp = level.ra_b2_ai.health;
            ra_b2_main_value();
            level.ra_b2_i = 0;
            while ( isdefined( level.players ) && level.ra_b2_i < level.players.size )
            {
                if ( isdefined( level.players[ level.ra_b2_i ] ) )
                    level.players[ level.ra_b2_i ] thread namespace_83b3fe93c7a4b9b4::function_d4d30f8437fafce1( level.ra_b2_mh, level.ra_b2_mm );
                level.ra_b2_i++;
            }
        }
        if ( level.ra_b2_last == "" )
            nengine_store_set( "rex_arena", "boss_bar_feed", "second bar " + level.ra_b2_name + "; type ids defined: z-rex " + isdefined( level.ra_zrex_ai.var_33117b8c6888723a ) + ", " + level.ra_b2_pn + " " + isdefined( level.ra_b2_pa.var_33117b8c6888723a ) );
        level.ra_b2_ai = undefined;
        level.ra_b2_main = undefined;
    }
    level.ra_b2_pa = undefined;
    if ( level.ra_b2_text != "" || level.ra_b2_last != "" )
        setdvar( @"rex_arena_bar2", level.ra_b2_text );
    if ( level.ra_b2_text != "" )
    {
        level.ra_b2_ui_now = getdvar( @"rex_arena_bar2_ui", "" );
        if ( level.ra_b2_ui_now != level.ra_b2_ui )
        {
            level.ra_b2_ui = level.ra_b2_ui_now;
            nengine_store_set( "rex_arena", "boss_bar2_ui", level.ra_b2_ui );
            nengine_store_save( "rex_arena", "runtime" );
        }
    }
    if ( level.ra_b2_text != "" && level.ra_b2_last == "" )
        nengine_store_set( "rex_arena", "boss_bar2", "shown: " + level.ra_b2_name + " in round " + level.ra_sp_round );
    if ( level.ra_b2_text == "" && level.ra_b2_last != "" )
    {
        nengine_store_set( "rex_arena", "boss_bar2", "hidden after " + level.ra_b2_name );
        level.ra_b2_other_hp = -1;
        if ( ra_boss_alive( level.ra_zrex_ai, 0 ) )
            level.ra_zrex_ai namespace_83b3fe93c7a4b9b4::function_f50a10314e72caa1();
        if ( ra_boss_alive( level.ra_guardian_ai, 1 ) )
            level.ra_guardian_ai namespace_83b3fe93c7a4b9b4::function_f50a10314e72caa1();
    }
    level.ra_b2_last = level.ra_b2_text;
}

// 0.5.25: the bars from the round-500 event on (level.ra_bar_h). The game's
// bar (the main one) follows Caltheris, else the Guardian, else Z-Rex;
// players whose bar follows another of this mod's living bosses are moved to
// it. A living Z-Rex that is not the main boss goes to rex_arena_bar2 in slot
// -1 (left of the game's bar), a living Guardian that is not the main boss to
// rex_arena_bar3 in slot 1 (right of it), as "NAME|health|max|server
// time|bar list id|slot". As in ra_boss_bar2, the side bosses have the game's
// bar callback taken off, the main one keeps it (Caltheris) or gets it, and
// the main value is written again when a side boss's health changed. What
// the Lua used comes back in rex_arena_bar2_ui / rex_arena_bar3_ui.
function ra_boss_bar_trio()
{
    level.ra_b2_text = "";
    level.ra_b3_text = "";
    // 0.5.31: the Weyward (boss 3) under the game's bar (rex_arena_bar4, slot
    // 0); 0.5.33: name and icon from its bar list entry, the script's name
    // when it has none (-1).
    level.ra_b4_text = "";
    // 0.5.38: while the Weyward lives the game's bar is down (ra_boss_bar_quad)
    level.ra_b5_text = "";
    level.ra_t_w = ra_boss_alive( level.ra_weyward_ai, 3 );
    if ( !level.ra_t_w )
        level.ra_q_down = 0;
    if ( ra_boss_alive( level.ra_weyward_ai, 3 ) )
    {
        // 0.5.38: no bar while it fakes its death (its first fall to 1000
        // health: function_d0fd11e8ededcef0, until it comes back,
        // var_864f7da030e1538) or dies (function_de8516e4bb111561); its script
        // takes the game's bar down for both (function_57cec007b96540a4).
        // 0.5.40: down while either fake death runs (var_ba89dbfc67972f95 is 0
        // from its start to the revive)
        level.ra_wey_fake = istrue( level.ra_weyward_ai.var_426cbbee92f4e599 ) || ( istrue( level.ra_weyward_ai.var_f9e26f943ef4abc ) && !istrue( level.ra_weyward_ai.var_ba89dbfc67972f95 ) );
        if ( !level.ra_wey_fake )
            level.ra_b4_text = "THE WEYWARD|" + level.ra_weyward_ai.health + "|" + level.ra_weyward_ai.maxhealth + "|" + function_83bf4b34fbbe124b() + "|" + level.ra_wey_bar_id;
        if ( level.ra_wey_fake != level.ra_wbf_last )
        {
            level.ra_wbf_last = level.ra_wey_fake;
            level.ra_wbf_n++;
            nengine_store_set( "rex_arena", "boss_weyward_bar_fake", "round " + level.ra_sp_round + ", change " + level.ra_wbf_n + ": bar " + ( level.ra_wey_fake ? "hidden (" + ( istrue( level.ra_weyward_ai.var_426cbbee92f4e599 ) ? "last death" : "fake death" ) + ")" : "back" ) + " at health " + level.ra_weyward_ai.health + " of " + level.ra_weyward_ai.maxhealth );
            nengine_store_save( "rex_arena", "runtime" );
        }
        level.ra_wey_im = istrue( level.ra_weyward_ai.var_9b230d276449dbc8 ) ? 1 : 0;
        // 0.5.33: the game's bar callback off it, as for the other side bosses
        level.ra_weyward_ai namespace_83b3fe93c7a4b9b4::function_d16104a6c7125d2d();
    }
    level.ra_t_z = ra_boss_alive( level.ra_zrex_ai, 0 );
    level.ra_t_g = ra_boss_alive( level.ra_guardian_ai, 1 );
    level.ra_t_c = ra_boss_alive( level.ra_caltheris_ai, 2 );
    level.ra_t_main = undefined;
    level.ra_t_mn = "none";
    if ( level.ra_t_c && !level.ra_t_w )
    {
        level.ra_t_main = level.ra_caltheris_ai;
        level.ra_t_mn = "CALTHERIS";
    }
    else if ( level.ra_t_g && !level.ra_t_w )
    {
        level.ra_t_main = level.ra_guardian_ai;
        level.ra_t_mn = "THE GUARDIAN";
    }
    else if ( level.ra_t_z && !level.ra_t_w )
    {
        level.ra_t_main = level.ra_zrex_ai;
        level.ra_t_mn = "Z-REX";
    }
    // 0.5.37: the Weyward's copy above the game's bar (slot 2) while that bar
    // follows a boss, else in its place (slot 3); its seventh field is 1 while
    // the Weyward is immune (the mod Lua then plays the widget's immune clip).
    if ( level.ra_b4_text != "" )
    {
        level.ra_b4_slot = isdefined( level.ra_t_main ) ? 2 : 3;
        level.ra_b4_text = level.ra_b4_text + "|" + level.ra_b4_slot + "|" + level.ra_wey_im;
        ra_weyward_bar_immune();
    }
    if ( isdefined( level.ra_t_main ) )
    {
        if ( !isdefined( level.ra_zrex_bar_id ) )
            ra_boss_bar_ids();
        level.ra_t_hp = "";
        if ( level.ra_t_z && level.ra_t_main != level.ra_zrex_ai )
        {
            level.ra_b2_text = "Z-REX|" + level.ra_zrex_ai.health + "|" + level.ra_zrex_ai.maxhealth + "|" + function_83bf4b34fbbe124b() + "|" + level.ra_zrex_bar_id + "|-1";
            level.ra_zrex_ai namespace_83b3fe93c7a4b9b4::function_d16104a6c7125d2d();
            level.ra_t_hp = level.ra_t_hp + level.ra_zrex_ai.health;
        }
        level.ra_t_hp = level.ra_t_hp + "/";
        if ( level.ra_t_g && level.ra_t_main != level.ra_guardian_ai )
        {
            level.ra_b3_text = "THE GUARDIAN|" + level.ra_guardian_ai.health + "|" + level.ra_guardian_ai.maxhealth + "|" + function_83bf4b34fbbe124b() + "|" + level.ra_guardian_bar_id + "|1";
            level.ra_guardian_ai namespace_83b3fe93c7a4b9b4::function_d16104a6c7125d2d();
            level.ra_t_hp = level.ra_t_hp + level.ra_guardian_ai.health;
        }
        if ( level.ra_t_main.ra_boss_index != 2 )
            level.ra_t_main namespace_83b3fe93c7a4b9b4::function_f50a10314e72caa1();
        level.ra_t_i = 0;
        while ( isdefined( level.players ) && level.ra_t_i < level.players.size )
        {
            level.ra_t_p = level.players[ level.ra_t_i ];
            if ( isdefined( level.ra_t_p ) && isdefined( level.ra_t_p.var_7fa280bb4c563541 ) && level.ra_t_p.var_7fa280bb4c563541 != level.ra_t_main && ( ( level.ra_t_z && level.ra_t_p.var_7fa280bb4c563541 == level.ra_zrex_ai ) || ( level.ra_t_g && level.ra_t_p.var_7fa280bb4c563541 == level.ra_guardian_ai ) || ( ra_boss_alive( level.ra_weyward_ai, 3 ) && level.ra_t_p.var_7fa280bb4c563541 == level.ra_weyward_ai ) ) )
                level.ra_t_p ra_boss_main_bar();
            level.ra_t_i++;
        }
        level.ra_t_p = undefined;
        // 0.5.26: also when a boss was made or a player's bar was switched
        // (level.ra_bar_ev) or the main boss changed, and once a second.
        level.ra_t_n++;
        level.ra_t_key = level.ra_t_hp + "|" + level.ra_t_main.ra_boss_index + "|" + level.ra_bar_ev;
        if ( level.ra_t_key != level.ra_b_hp_last || level.ra_t_n % 7 == 0 )
        {
            level.ra_b_hp_last = level.ra_t_key;
            level.ra_b2_main = level.ra_t_main;
            ra_b2_main_value();
            level.ra_b2_main = undefined;
            level.ra_t_i = 0;
            while ( isdefined( level.players ) && level.ra_t_i < level.players.size )
            {
                if ( isdefined( level.players[ level.ra_t_i ] ) )
                    level.players[ level.ra_t_i ] thread namespace_83b3fe93c7a4b9b4::function_d4d30f8437fafce1( level.ra_b2_mh, level.ra_b2_mm );
                level.ra_t_i++;
            }
        }
    }
    else if ( level.ra_t_w )
        ra_boss_bar_quad();
    level.ra_t_main = undefined;
    level.ra_t_lay = "main " + level.ra_t_mn + ", left " + ( level.ra_b2_text != "" ? "Z-REX" : "none" ) + ", right " + ( level.ra_b3_text != "" ? "THE GUARDIAN" : "none" ) + ", THE WEYWARD " + ( level.ra_b4_text != "" ? ( level.ra_b4_slot == 2 ? "above" : "in its place" ) : "none" ) + ", CALTHERIS " + ( level.ra_b5_text != "" ? "under" : "none" ) + ", game's bar " + ( level.ra_t_w ? "down" : "up" );
    if ( level.ra_t_lay != level.ra_t_lay_last )
    {
        level.ra_t_lay_last = level.ra_t_lay;
        nengine_store_set( "rex_arena", "boss_bar_trio", "round " + level.ra_sp_round + ": " + level.ra_t_lay );
        nengine_store_save( "rex_arena", "runtime" );
    }
    if ( level.ra_b2_text != "" || level.ra_b2_last != "" )
        setdvar( @"rex_arena_bar2", level.ra_b2_text );
    if ( level.ra_b3_text != "" || level.ra_b3_last != "" )
        setdvar( @"rex_arena_bar3", level.ra_b3_text );
    if ( level.ra_b2_text != "" )
    {
        level.ra_b2_ui_now = getdvar( @"rex_arena_bar2_ui", "" );
        if ( level.ra_b2_ui_now != level.ra_b2_ui )
        {
            level.ra_b2_ui = level.ra_b2_ui_now;
            nengine_store_set( "rex_arena", "boss_bar2_ui", level.ra_b2_ui );
            nengine_store_save( "rex_arena", "runtime" );
        }
    }
    if ( level.ra_b3_text != "" )
    {
        level.ra_b3_ui_now = getdvar( @"rex_arena_bar3_ui", "" );
        if ( level.ra_b3_ui_now != level.ra_b3_ui )
        {
            level.ra_b3_ui = level.ra_b3_ui_now;
            nengine_store_set( "rex_arena", "boss_bar3_ui", level.ra_b3_ui );
            nengine_store_save( "rex_arena", "runtime" );
        }
    }
    if ( level.ra_b2_text != "" && level.ra_b2_last == "" )
        nengine_store_set( "rex_arena", "boss_bar2", "shown: Z-REX left of the game's bar in round " + level.ra_sp_round );
    if ( level.ra_b2_text == "" && level.ra_b2_last != "" )
        nengine_store_set( "rex_arena", "boss_bar2", "hidden in round " + level.ra_sp_round );
    if ( level.ra_b3_text != "" && level.ra_b3_last == "" )
        nengine_store_set( "rex_arena", "boss_bar3", "shown: THE GUARDIAN right of the game's bar in round " + level.ra_sp_round );
    if ( level.ra_b3_text == "" && level.ra_b3_last != "" )
        nengine_store_set( "rex_arena", "boss_bar3", "hidden in round " + level.ra_sp_round );
    level.ra_b2_last = level.ra_b2_text;
    level.ra_b3_last = level.ra_b3_text;
    if ( level.ra_b4_text != "" || level.ra_b4_last != "" )
        setdvar( @"rex_arena_bar4", level.ra_b4_text );
    if ( level.ra_b4_text != "" )
    {
        level.ra_b4_ui_now = getdvar( @"rex_arena_bar4_ui", "" );
        if ( level.ra_b4_ui_now != level.ra_b4_ui )
        {
            level.ra_b4_ui = level.ra_b4_ui_now;
            nengine_store_set( "rex_arena", "boss_bar4_ui", level.ra_b4_ui );
            nengine_store_save( "rex_arena", "runtime" );
        }
    }
    if ( level.ra_b4_text != "" && level.ra_b4_last == "" )
        nengine_store_set( "rex_arena", "boss_bar4", "shown: THE WEYWARD " + ( level.ra_b4_slot == 2 ? "above the game's bar" : "in the game's bar's place" ) + " in round " + level.ra_sp_round );
    if ( level.ra_b4_text == "" && level.ra_b4_last != "" )
        nengine_store_set( "rex_arena", "boss_bar4", "hidden in round " + level.ra_sp_round );
    level.ra_b4_last = level.ra_b4_text;
    // 0.5.38: Caltheris's copy under the Weyward's
    if ( level.ra_b5_text != "" || level.ra_b5_last != "" )
        setdvar( @"rex_arena_bar5", level.ra_b5_text );
    if ( level.ra_b5_text != "" )
    {
        level.ra_b5_ui_now = getdvar( @"rex_arena_bar5_ui", "" );
        if ( level.ra_b5_ui_now != level.ra_b5_ui )
        {
            level.ra_b5_ui = level.ra_b5_ui_now;
            nengine_store_set( "rex_arena", "boss_bar5_ui", level.ra_b5_ui );
            nengine_store_save( "rex_arena", "runtime" );
        }
    }
    if ( level.ra_b5_text != "" && level.ra_b5_last == "" )
        nengine_store_set( "rex_arena", "boss_bar5", "shown: CALTHERIS under THE WEYWARD in round " + level.ra_sp_round );
    if ( level.ra_b5_text == "" && level.ra_b5_last != "" )
        nengine_store_set( "rex_arena", "boss_bar5", "hidden in round " + level.ra_sp_round );
    level.ra_b5_last = level.ra_b5_text;
}

// 0.5.38: the bars while the Weyward lives (round 999). The game's bar is
// taken down for every player whose bar follows a boss or is open (the bar
// script's function_4aa93fe15c8cfb69), so Caltheris's own bar callback
// (function_aa647407d5c4af0, in Rex's map scripts, which this mod cannot
// take off) has no bar to write to. All four are copies: the Weyward in the
// game's bar's place (rex_arena_bar4, slot 3, set in ra_boss_bar_trio),
// Caltheris under it (rex_arena_bar5, slot 4, 0.5.39: smaller than the
// Weyward's; its phase bar value), Z-Rex
// left (slot -1), the Guardian right (slot 1), each with an immune field.
// The game's bar callback is taken off them. From ra_boss_bar_trio.
function ra_boss_bar_quad()
{
    if ( !isdefined( level.ra_zrex_bar_id ) )
        ra_boss_bar_ids();
    level.ra_q_now = function_83bf4b34fbbe124b();
    if ( level.ra_t_z )
    {
        level.ra_b2_text = "Z-REX|" + level.ra_zrex_ai.health + "|" + level.ra_zrex_ai.maxhealth + "|" + level.ra_q_now + "|" + level.ra_zrex_bar_id + "|-1|" + ( istrue( level.ra_zrex_ai.var_cffd4250b352cef4 ) ? 1 : 0 );
        level.ra_zrex_ai namespace_83b3fe93c7a4b9b4::function_d16104a6c7125d2d();
    }
    if ( level.ra_t_g )
    {
        level.ra_b3_text = "THE GUARDIAN|" + level.ra_guardian_ai.health + "|" + level.ra_guardian_ai.maxhealth + "|" + level.ra_q_now + "|" + level.ra_guardian_bar_id + "|1|" + ( istrue( level.ra_guardian_ai.var_9b230d276449dbc8 ) ? 1 : 0 );
        level.ra_guardian_ai namespace_83b3fe93c7a4b9b4::function_d16104a6c7125d2d();
    }
    if ( level.ra_t_c )
    {
        level.ra_b2_main = level.ra_caltheris_ai;
        ra_b2_main_value();
        level.ra_b2_main = undefined;
        level.ra_b5_text = "CALTHERIS|" + int( level.ra_b2_mh ) + "|" + int( level.ra_b2_mm ) + "|" + level.ra_q_now + "|" + level.ra_caltheris_bar_id + "|4|" + ( istrue( level.ra_cal_sh ) ? 1 : 0 );
        level.ra_caltheris_ai namespace_83b3fe93c7a4b9b4::function_d16104a6c7125d2d();
    }
    level.ra_q_i = 0;
    while ( isdefined( level.players ) && level.ra_q_i < level.players.size )
    {
        level.ra_q_p = level.players[ level.ra_q_i ];
        if ( isdefined( level.ra_q_p ) && ( isdefined( level.ra_q_p.var_7fa280bb4c563541 ) || level.ra_q_p namespace_83b3fe93c7a4b9b4::function_44d523f97fcaa324() ) )
        {
            level.ra_q_who = isdefined( level.ra_q_p.var_7fa280bb4c563541 ) ? ( isdefined( level.ra_q_p.var_7fa280bb4c563541.ra_boss_index ) ? "boss " + level.ra_q_p.var_7fa280bb4c563541.ra_boss_index : "another enemy" ) : "none";
            level.ra_q_p namespace_83b3fe93c7a4b9b4::function_4aa93fe15c8cfb69();
            level.ra_q_n++;
            nengine_store_set( "rex_arena", "boss_bar_quad_down", "round " + level.ra_sp_round + ": game's bar taken down " + level.ra_q_n + " time(s); last for player " + level.ra_q_i + ", following " + level.ra_q_who + ( level.ra_q_down ? " (it had come back)" : "" ) );
            nengine_store_save( "rex_arena", "runtime" );
        }
        level.ra_q_i++;
    }
    level.ra_q_p = undefined;
    level.ra_q_down = 1;
}

// 0.5.37: the Weyward's immunity and the game's bar. The boss script puts
// every player's game bar in its immune state for the Weyward's phase change
// (function_e5a4de300c61a650, core script_5cda26b07ee216bf), but that bar
// follows another boss here (the Weyward has its copy), so when the Weyward's
// immunity starts the game's bar is put back to vulnerable unless its own boss
// is immune (Caltheris's shield, Z-Rex's immune move, the boss script's field).
// Records boss_weyward_bar_immune. From ra_boss_bar_trio.
function ra_weyward_bar_immune()
{
    if ( level.ra_wey_im == level.ra_wbi_last )
        return;
    level.ra_wbi_last = level.ra_wey_im;
    level.ra_wbi_n++;
    level.ra_wbi_reset = "no";
    if ( level.ra_wey_im && isdefined( level.ra_t_main ) )
    {
        if ( ( level.ra_t_main == level.ra_caltheris_ai && istrue( level.ra_cal_sh ) ) || istrue( level.ra_t_main.var_cffd4250b352cef4 ) || istrue( level.ra_t_main.var_9b230d276449dbc8 ) )
            level.ra_wbi_reset = "no, its own boss is immune";
        else
        {
            level.ra_wbi_i = 0;
            while ( isdefined( level.players ) && level.ra_wbi_i < level.players.size )
            {
                if ( isdefined( level.players[ level.ra_wbi_i ] ) )
                    level.players[ level.ra_wbi_i ] thread namespace_83b3fe93c7a4b9b4::function_e5a4de300c61a650( 0 );
                level.ra_wbi_i++;
            }
            level.ra_wbi_reset = "yes";
        }
    }
    nengine_store_set( "rex_arena", "boss_weyward_bar_immune", "round " + level.ra_sp_round + ": " + level.ra_wbi_n + " changes; last immune " + level.ra_wey_im + ", Weyward bar slot " + level.ra_b4_slot + ", game's bar " + ( isdefined( level.ra_t_main ) ? level.ra_t_mn : "none" ) + " set back to vulnerable: " + level.ra_wbi_reset );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.27: what the mod Lua's HUD block reports in rex_arena_hud_ui, kept in
// the store. 0.5.28: the phase label is removed. From ra_boss_bar2.
function ra_boss_hud_record()
{
    level.ra_hud_now = getdvar( @"rex_arena_hud_ui", "" );
    if ( level.ra_hud_now != level.ra_hud_ui )
    {
        level.ra_hud_ui = level.ra_hud_now;
        nengine_store_set( "rex_arena", "boss_hud_ui", level.ra_hud_ui );
        nengine_store_save( "rex_arena", "runtime" );
    }
}

// 0.5.27: a note on screen (mod Lua, rex_arena_note): title, body, how long.
function ra_note( title, body, seconds )
{
    setdvar( @"rex_arena_note", title + "|" + body + "|" + function_83bf4b34fbbe124b() + "|" + seconds );
    // 0.5.41: the round-select hint does not cover it
    level.ra_note_until = function_83bf4b34fbbe124b() + seconds * 1000;
    nengine_store_set( "rex_arena", "boss_note", "round " + level.ra_sp_round + ": " + title + " / " + body );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.27: m:ss of a time in ms.
function ra_time_text( ms )
{
    level.ra_tt_s = int( ms / 1000 );
    level.ra_tt_sec = level.ra_tt_s % 60;
    return int( level.ra_tt_s / 60 ) + ":" + ( level.ra_tt_sec < 10 ? "0" : "" ) + level.ra_tt_sec;
}

// 0.7.8: a boss dead for good drops what Rex's Boss Rush drops after each of
// its bosses (user: "whenever u kill a boss in boss rush u get 4 drops as a
// reward can we implement that for every boss u kill"; the four are "max ammo,
// full power, free perk and max armor"). Boss Rush (script_6c1f17f235760ccc,
// function_1786f8f2f7e852f3) spawns them with
// namespace_38b819984cd6da1b::function_6726dd8e88240ef6( name, place, 58 ), 58 s
// on the ground. Here: in a square 100 out from where the boss fell, on the
// ground, 50 above it. Max Ammo is full_ammo (Boss Rush's encrypted name is the
// one 0.7.6 read as full_ammo); the other names are written by their length in
// Boss Rush (10, 9, 10 letters). A name drops only when the game's power-up
// list has it; Max Armor tries full_armor, then max_armor. Each try is stored.
function ra_boss_drops( index )
{
    if ( !isdefined( level.ra_bd_t ) )
        level.ra_bd_t = [];
    if ( isdefined( level.ra_bd_t[ index ] ) && function_83bf4b34fbbe124b() - level.ra_bd_t[ index ] < 5000 )
        return;
    level.ra_bd_t[ index ] = function_83bf4b34fbbe124b();
    level.ra_bd_name = index == 0 ? "Z-Rex" : ( index == 1 ? "the Guardian" : ( index == 2 ? "Caltheris" : "the Weyward" ) );
    if ( !isdefined( level.ra_bd_count ) )
        level.ra_bd_count = 0;
    level.ra_bd_count++;
    if ( !isdefined( level.ra_g_org[ index ] ) )
    {
        level.ra_bd_text = "round " + level.ra_sp_round + ": no place known for " + level.ra_bd_name + ", nothing dropped";
        nengine_store_set( "rex_arena", "boss_drops", level.ra_bd_text );
        if ( level.ra_bd_count <= 20 )
            nengine_store_set( "rex_arena", "boss_drops_" + level.ra_bd_count, level.ra_bd_text );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    level.ra_bd_list = namespace_38b819984cd6da1b::function_8ee77fc699f9d8c3().var_38b819984cd6da1b;
    level.ra_bd_try = [ "full_ammo", "full_power", "free_perk", "full_armor", "max_armor" ];
    level.ra_bd_off = [ ( 100, 100, 0 ), ( -100, 100, 0 ), ( 100, -100, 0 ), ( -100, -100, 0 ) ];
    level.ra_bd_text = "round " + level.ra_sp_round + ": " + level.ra_bd_name + " fell at " + level.ra_g_org[ index ] + ";";
    if ( !isdefined( level.ra_bd_list ) )
        level.ra_bd_text = level.ra_bd_text + " the game's power-up list is missing;";
    level.ra_bd_n = 0;
    level.ra_bd_armor = 0;
    for ( level.ra_bd_i = 0; level.ra_bd_i < level.ra_bd_try.size; level.ra_bd_i++ )
    {
        level.ra_bd_what = level.ra_bd_try[ level.ra_bd_i ];
        if ( level.ra_bd_i == 4 && level.ra_bd_armor )
            level.ra_bd_what = undefined;
        if ( isdefined( level.ra_bd_what ) && ( !isdefined( level.ra_bd_list ) || !isdefined( level.ra_bd_list[ level.ra_bd_what ] ) ) )
        {
            level.ra_bd_text = level.ra_bd_text + " " + level.ra_bd_what + " not registered;";
            level.ra_bd_what = undefined;
        }
        if ( isdefined( level.ra_bd_what ) && level.ra_bd_n < 4 )
        {
            if ( level.ra_bd_i >= 3 )
                level.ra_bd_armor = 1;
            level.ra_bd_at = function_df9f501a2a0cbf4( level.ra_g_org[ index ] + level.ra_bd_off[ level.ra_bd_n ] + ( 0, 0, 40 ) );
            if ( !isdefined( level.ra_bd_at ) )
                level.ra_bd_at = level.ra_g_org[ index ] + level.ra_bd_off[ level.ra_bd_n ];
            level thread namespace_38b819984cd6da1b::function_6726dd8e88240ef6( level.ra_bd_what, level.ra_bd_at + ( 0, 0, 50 ), 58 );
            level.ra_bd_text = level.ra_bd_text + " " + level.ra_bd_what + " at " + level.ra_bd_at + ";";
            level.ra_bd_n++;
        }
    }
    level.ra_bd_text = level.ra_bd_text + " " + level.ra_bd_n + " dropped";
    nengine_store_set( "rex_arena", "boss_drops", level.ra_bd_text );
    if ( level.ra_bd_count <= 20 )
        nengine_store_set( "rex_arena", "boss_drops_" + level.ra_bd_count, level.ra_bd_text );
    nengine_store_save( "rex_arena", "runtime" );
}

// 1.1.7: a boss beaten (dead for good, ra_boss_final): 5000 salvage to every player (user: "5k salvage
// reward for beating each boss"), with the game's own currency call, as its rewards give salvage
// (core script_3ca070ee1ba8337c function_c7338ab736d78439). Records boss_salvage.
function ra_boss_salvage( index )
{
    level.ra_sv_n = 0;
    for ( level.ra_sv_i = 0; isdefined( level.var_10f4ff41c4b7f0ac ) && level.ra_sv_i < level.var_10f4ff41c4b7f0ac.size; level.ra_sv_i++ )
    {
        if ( isdefined( level.var_10f4ff41c4b7f0ac[ level.ra_sv_i ] ) )
        {
            level.var_10f4ff41c4b7f0ac[ level.ra_sv_i ] namespace_189fe7075a0930a5::function_91837b02eb37486e( #"salvage", 5000 );
            level.ra_sv_n++;
        }
    }
    if ( !isdefined( level.ra_sv_total ) )
        level.ra_sv_total = 0;
    level.ra_sv_total = level.ra_sv_total + 5000;
    level.ra_sv_name = index == 0 ? "Z-Rex" : ( index == 1 ? "the Guardian" : ( index == 2 ? "Caltheris" : "the Weyward" ) );
    nengine_store_set( "rex_arena", "boss_salvage", "round " + level.ra_sp_round + ": " + level.ra_sv_name + " beaten, 5000 salvage to " + level.ra_sv_n + " players (" + level.ra_sv_total + " each from bosses so far)" );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.27: a round-500 boss is dead for good (not made again). When all three
// are dead the fight summary goes on screen and to the store.
// 0.7.8: every boss dead for good comes here; it drops Boss Rush's four
// power-ups (ra_boss_drops). The round-500 Max Ammo (0.5.27) is one of them now.
function ra_boss_final( index )
{
    ra_boss_drops( index );
    ra_boss_salvage( index );
    if ( !level.ra_bar_h || !isdefined( level.ra_tr_t0 ) || isdefined( level.ra_tr_end[ index ] ) )
        return;
    level.ra_tr_end[ index ] = function_83bf4b34fbbe124b();
    level.ra_bf_name = index == 0 ? "Z-Rex" : ( index == 1 ? "the Guardian" : ( index == 2 ? "Caltheris" : "the Weyward" ) );
    nengine_store_set( "rex_arena", "boss_reward", "round " + level.ra_sp_round + ": " + level.ra_bf_name + " dead for good, its drops in boss_drops" );
    nengine_store_save( "rex_arena", "runtime" );
    if ( !isdefined( level.ra_tr_end[ 0 ] ) || !isdefined( level.ra_tr_end[ 1 ] ) || !isdefined( level.ra_tr_end[ 2 ] ) )
        return;
    // 0.5.31: in the round-999 fight, also the Weyward once it was made.
    if ( level.ra_qd_w && !isdefined( level.ra_tr_end[ 3 ] ) )
        return;
    level.ra_bf_last = level.ra_tr_end[ 0 ];
    if ( level.ra_tr_end[ 1 ] > level.ra_bf_last )
        level.ra_bf_last = level.ra_tr_end[ 1 ];
    if ( level.ra_tr_end[ 2 ] > level.ra_bf_last )
        level.ra_bf_last = level.ra_tr_end[ 2 ];
    level.ra_bf_w = "";
    if ( level.ra_qd_w )
    {
        if ( level.ra_tr_end[ 3 ] > level.ra_bf_last )
            level.ra_bf_last = level.ra_tr_end[ 3 ];
        level.ra_bf_w = "   THE WEYWARD " + ra_time_text( level.ra_tr_end[ 3 ] - level.ra_tr_t0 );
    }
    level.ra_bf_text = "Z-REX " + ra_time_text( level.ra_tr_end[ 0 ] - level.ra_tr_t0 ) + "   THE GUARDIAN " + ra_time_text( level.ra_tr_end[ 1 ] - level.ra_tr_t0 ) + "   CALTHERIS " + ra_time_text( level.ra_tr_end[ 2 ] - level.ra_tr_t0 ) + level.ra_bf_w + "   TOTAL " + ra_time_text( level.ra_bf_last - level.ra_tr_t0 );
    nengine_store_set( "rex_arena", level.ra_qd_w ? "boss_quad_summary" : "boss_trio_summary", "round " + level.ra_sp_round + ": " + level.ra_bf_text + "; remakes " + level.ra_boss_revived );
    // 0.6.0: in a round-999 fight the summary comes after the Warden's death
    // screens (ra_warden_end); if no ending takes it, 40 s later (ra_bf_release)
    if ( level.ra_qd_w )
    {
        level.ra_bf_held = 1;
        level thread ra_bf_release();
        return;
    }
    ra_note( "BOSSES DEFEATED", level.ra_bf_text, 10 );
}

// 0.5.25: the game's bar of the main boss of ra_boss_bar_trio, for a player.
function ra_boss_main_bar()
{
    if ( level.ra_t_main.ra_boss_index == 2 )
        self ra_caltheris_bar();
    else if ( level.ra_t_main.ra_boss_index == 1 )
        self ra_guardian_bar();
    else
        self ra_zrex_bar();
}

// The boss bar list entry of each boss, found the way the game's bar script
// finds the one it shows (function_b0e23ac80da814d8, script_7129baf8ee832ed2):
// the mod Lua takes the boss's name and icon from it. -1 when there is none.
function ra_boss_bar_ids()
{
    level.ra_zrex_bar_id = function_43b5ed5a14a56573( #"hash_9c9913488ca22949", function_99ee3cf75e2291a6( %"hash_325c203c696a2b10", "zombie_phobos_healthbar" ) );
    level.ra_guardian_bar_id = function_43b5ed5a14a56573( #"hash_9c9913488ca22949", function_99ee3cf75e2291a6( %"hash_325c203c696a2b10", "zombie_triton_healthbar" ) );
    if ( !isdefined( level.ra_zrex_bar_id ) )
        level.ra_zrex_bar_id = -1;
    if ( !isdefined( level.ra_guardian_bar_id ) )
        level.ra_guardian_bar_id = -1;
    level.ra_caltheris_bar_id = function_43b5ed5a14a56573( #"hash_9c9913488ca22949", function_99ee3cf75e2291a6( %"hash_325c203c696a2b10", "zombie_neptune_healthbar_3" ) );
    if ( !isdefined( level.ra_caltheris_bar_id ) )
        level.ra_caltheris_bar_id = -1;
    nengine_store_set( "rex_arena", "boss_bar_ids", "z-rex " + level.ra_zrex_bar_id + ", guardian " + level.ra_guardian_bar_id + ", caltheris " + level.ra_caltheris_bar_id );
    nengine_store_save( "rex_arena", "runtime" );
}

// A boss died and was not made again. The game takes a boss's bar down from a
// thread on the boss itself after its death animation (Z-Rex:
// function_73d0ea342093a003, script_178546be025df90c), and this mod's bar
// keeper used to show the bar again on the dead boss's entity once a new enemy
// had it. After 3 s, each player whose bar follows no living enemy, or still
// follows the dead boss's entity, gets the other boss's bar if it is alive;
// otherwise the bar is taken down with the game's own
// function_4aa93fe15c8cfb69. Runs on its own thread.
function ra_boss_bar_down( gone )
{
    level endon( #"game_ended" );
    wait 3;
    if ( !isdefined( level.players ) )
        return;
    // 0.5.38: not while the Weyward lives (its fight has the game's bar down)
    if ( level.ra_bar_h && ra_boss_alive( level.ra_weyward_ai, 3 ) )
        return;
    level.ra_down_g = ra_boss_alive( level.ra_guardian_ai, 1 );
    level.ra_down_z = ra_boss_alive( level.ra_zrex_ai, 0 );
    level.ra_down_c = ra_boss_alive( level.ra_caltheris_ai, 2 );
    level.ra_down_n = 0;
    level.ra_down_s = 0;
    level.ra_down_i = 0;
    while ( level.ra_down_i < level.players.size )
    {
        level.ra_down_p = level.players[ level.ra_down_i ];
        if ( isdefined( level.ra_down_p ) && ( !isdefined( level.ra_down_p.var_7fa280bb4c563541 ) || !isalive( level.ra_down_p.var_7fa280bb4c563541 ) || ( isdefined( gone ) && level.ra_down_p.var_7fa280bb4c563541 == gone ) ) )
        {
            if ( level.ra_down_c )
            {
                level.ra_down_p ra_caltheris_bar();
                level.ra_down_s++;
            }
            else if ( level.ra_down_g )
            {
                level.ra_down_p ra_guardian_bar();
                level.ra_down_s++;
            }
            else if ( level.ra_down_z )
            {
                level.ra_down_p ra_zrex_bar();
                level.ra_down_s++;
            }
            else
            {
                level.ra_down_p namespace_83b3fe93c7a4b9b4::function_4aa93fe15c8cfb69();
                level.ra_down_n++;
            }
        }
        level.ra_down_i++;
    }
    level.ra_down_p = undefined;
    nengine_store_set( "rex_arena", "boss_bar_down", "round " + level.ra_sp_round + ": taken down for " + level.ra_down_n + ", switched for " + level.ra_down_s );
    nengine_store_save( "rex_arena", "runtime" );
}

// The Guardian's instant-kill sets this flag immediately before kill().
// Hide only this match's tracked Z-Rex, on the game's own death callback, if
// the existing guard would also attempt a replacement. Do not delete the AI:
// the game's other death callbacks and corpse cleanup must still run. If the
// flag/entity has already been cleared, the guard has a conservative fallback.
function ra_zrex_slam_hide( params )
{
    if ( isdefined( self.ra_boss_index ) && self.ra_boss_index == 0 )
        level thread ra_zrex_death_info( self );
    if ( !isdefined( level.ra_g_on[ 0 ] ) || !level.ra_g_on[ 0 ] ||
         !isdefined( level.ra_g_ai[ 0 ] ) || level.ra_g_ai[ 0 ] != self ||
         !isdefined( self.ra_boss_index ) || self.ra_boss_index != 0 ||
         !isdefined( self.var_a472e925a028ede0 ) || !self.var_a472e925a028ede0 ||
         level.ra_g_hp[ 0 ] <= 1 || !ra_zrex_partner_near() || !ra_boss_can_remake( 0 ) )
        return;
    self.nocorpse = 1;
    self hide();
    level.ra_zrex_hide_done = 1;
    level.ra_zrex_corpse = self getcorpseentity();
    if ( isdefined( level.ra_zrex_corpse ) )
    {
        level.ra_zrex_corpse hide();
        nengine_store_set( "rex_arena", "boss_zrex_hide", "death callback: no corpse rule " + level.ra_zrex_nc + ", corpse found and hidden" );
    }
    else
        nengine_store_set( "rex_arena", "boss_zrex_hide", "death callback: no corpse rule " + level.ra_zrex_nc + ", no corpse" );
    level.ra_zrex_corpse = undefined;
}

// Z-Rex leaves no corpse (so no death animation is seen) only while the guard
// would make it again after a death: the Guardian is alive, Z-Rex is above 1
// health (0.4.5; was 5%) and fewer than 25 revives were made. Otherwise the game's
// normal death is left alone (nocorpse is only cleared if this mod set it).
function ra_zrex_corpse_rule()
{
    if ( ra_zrex_partner_near() && level.ra_g_hp[ 0 ] > 1 && ra_boss_can_remake( 0 ) )
    {
        if ( !level.ra_zrex_nc )
        {
            level.ra_g_ai[ 0 ].nocorpse = 1;
            level.ra_zrex_nc = 1;
            nengine_store_set( "rex_arena", "boss_zrex_corpse", "no corpse while its partner boss is alive" );
        }
    }
    else if ( level.ra_zrex_nc )
    {
        level.ra_g_ai[ 0 ] thread ra_zrex_nocorpse_clear();
        level.ra_zrex_nc = 0;
        nengine_store_set( "rex_arena", "boss_zrex_corpse", "normal corpse" );
    }
}

// Z-Rex goes for the nearest living player. Once a second: farther than 800
// units it gets a goal (priority 2) at that player's spot on the navmesh, with
// the zombie goal function the game's AI code uses; it keeps it until it is
// within 500 units, then the goal is released the way Rex's own Z-Rex stuck
// fix releases it, and Z-Rex's own attacks take over. Only this mod's Z-Rex
// runs this; it ends when that Z-Rex dies (a replacement starts its own).
function ra_zrex_chase()
{
    self endon( #"death" );
    level endon( #"game_ended" );
    level.ra_zc_on = 0;
    if ( !isdefined( level.ra_zc_count ) )
        level.ra_zc_count = 0;
    wait 3;
    while ( true )
    {
        level.ra_zc_best = undefined;
        level.ra_zc_d = 0;
        level.ra_zc_i = 0;
        while ( isdefined( level.players ) && level.ra_zc_i < level.players.size )
        {
            level.ra_zc_p = level.players[ level.ra_zc_i ];
            if ( isdefined( level.ra_zc_p ) && isalive( level.ra_zc_p ) )
            {
                level.ra_zc_pd = distancesquared( self.origin, level.ra_zc_p.origin );
                if ( !isdefined( level.ra_zc_best ) || level.ra_zc_pd < level.ra_zc_d )
                {
                    level.ra_zc_best = level.ra_zc_p;
                    level.ra_zc_d = level.ra_zc_pd;
                }
            }
            level.ra_zc_i++;
        }
        level.ra_zc_p = undefined;
        if ( isdefined( level.ra_zc_best ) && ( level.ra_zc_d > 640000 || ( level.ra_zc_on && level.ra_zc_d > 250000 ) ) )
        {
            level.ra_zc_goal = self namespace_56fb43fc0b6ee43e::function_580e82d21a732187( level.ra_zc_best );
            if ( !isdefined( level.ra_zc_goal ) )
                level.ra_zc_goal = level.ra_zc_best.origin;
            self namespace_56fb43fc0b6ee43e::function_578a4940ca2d03d0( level.ra_zc_goal, 2 );
            if ( !level.ra_zc_on )
            {
                level.ra_zc_on = 1;
                level.ra_zc_count++;
                nengine_store_set( "rex_arena", "boss_zrex_chase", "chasing (" + level.ra_zc_count + " times) in round " + level.ra_sp_round + " from " + int( sqrt( level.ra_zc_d ) ) );
            }
        }
        else if ( level.ra_zc_on )
        {
            self function_7ead521500ed5ed8();
            self function_6e5a3e150c380a02( 2 );
            level.ra_zc_on = 0;
            nengine_store_set( "rex_arena", "boss_zrex_chase", "reached a player (" + level.ra_zc_count + " chases) in round " + level.ra_sp_round );
        }
        level.ra_zc_best = undefined;
        wait 1;
    }
}

autoexec rx_rampage_preload()
{
    if ( !ra_selected() )
        return;
    nengine_store_set( "rex_arena", "fx_preload_rampage", ra_launch_off( "fx_preload" ) ? "skipped" : "loaded" );
    if ( ra_launch_off( "fx_preload" ) )
        return;
    level.rx_rampage_fx = loadfxasset( "vfx_jup_ob_gameplay_zm_rampage_inducer_despawn" );
}

function rx_half( value )
{
    if ( !isdefined( value ) )
        return value;
    return int( value / 2 );
}

function rx_cost_text( value )
{
    if ( !isdefined( value ) )
        return "-";
    return "" + value;
}

function rx_ammo_cache_cost_text( costs )
{
    return rx_cost_text( costs.var_2729c5e6f598b48f ) + " normal " +
        rx_cost_text( costs.var_b73cf47f78dc7922 ) + "/" + rx_cost_text( costs.var_b73cf37f78dc76ef ) + "/" +
        rx_cost_text( costs.var_b73cf27f78dc74bc ) + "/" + rx_cost_text( costs.var_b73cf17f78dc7289 ) + " other " +
        rx_cost_text( costs.var_cecc0a1d213a5866 ) + "/" + rx_cost_text( costs.var_89de21b8a22ba0e3 ) + "/" +
        rx_cost_text( costs.var_89de22b8a22ba316 ) + "/" + rx_cost_text( costs.var_89de23b8a22ba549 ) + "/" +
        rx_cost_text( costs.var_89de24b8a22ba77c );
}

function rx_ammo_station_cost_text( costs )
{
    return rx_cost_text( costs.var_aab764b135fd9f26 ) + " tiers " +
        rx_cost_text( costs.var_b73cf47f78dc7922 ) + "/" + rx_cost_text( costs.var_b73cf37f78dc76ef ) + "/" +
        rx_cost_text( costs.var_b73cf27f78dc74bc ) + "/" + rx_cost_text( costs.var_b73cf17f78dc7289 );
}

function rx_half_ammo_cost()
{
    level endon( #"game_ended" );
    if ( !ra_selected() )
        return;
    level.rx_ac_wait = 0;
    while ( !isdefined( level.var_6c83d1b7ba6fafa5 ) && level.rx_ac_wait < 600 )
    {
        wait 0.1;
        level.rx_ac_wait++;
    }
    level.rx_ac_halved = 0;
    level.rx_ac_station_halved = 0;
    if ( !isdefined( level.var_6c83d1b7ba6fafa5 ) )
        nengine_store_set( "rex_arena", "ammo_cost", "no_cost_table" );
    nengine_store_save( "rex_arena", "runtime" );
    while ( true )
    {
        level.rx_ac_dirty = 0;
        if ( isdefined( level.var_6c83d1b7ba6fafa5 ) && !isdefined( level.var_6c83d1b7ba6fafa5.rx_halved ) )
        {
            level.rx_ac = level.var_6c83d1b7ba6fafa5;
            nengine_store_set( "rex_arena", "ammo_cost_before", rx_ammo_cache_cost_text( level.rx_ac ) );
            level.rx_ac.var_2729c5e6f598b48f = rx_half( level.rx_ac.var_2729c5e6f598b48f );
            level.rx_ac.var_b73cf47f78dc7922 = rx_half( level.rx_ac.var_b73cf47f78dc7922 );
            level.rx_ac.var_b73cf37f78dc76ef = rx_half( level.rx_ac.var_b73cf37f78dc76ef );
            level.rx_ac.var_b73cf27f78dc74bc = rx_half( level.rx_ac.var_b73cf27f78dc74bc );
            level.rx_ac.var_b73cf17f78dc7289 = rx_half( level.rx_ac.var_b73cf17f78dc7289 );
            level.rx_ac.var_cecc0a1d213a5866 = rx_half( level.rx_ac.var_cecc0a1d213a5866 );
            level.rx_ac.var_89de21b8a22ba0e3 = rx_half( level.rx_ac.var_89de21b8a22ba0e3 );
            level.rx_ac.var_89de22b8a22ba316 = rx_half( level.rx_ac.var_89de22b8a22ba316 );
            level.rx_ac.var_89de23b8a22ba549 = rx_half( level.rx_ac.var_89de23b8a22ba549 );
            level.rx_ac.var_89de24b8a22ba77c = rx_half( level.rx_ac.var_89de24b8a22ba77c );
            level.rx_ac.rx_halved = 1;
            level.rx_ac_halved++;
            nengine_store_set( "rex_arena", "ammo_cost_after", rx_ammo_cache_cost_text( level.rx_ac ) );
            nengine_store_set( "rex_arena", "ammo_cost_halved", level.rx_ac_halved );
            nengine_store_set( "rex_arena", "ammo_cost", "halved" );
            level.rx_ac_dirty = 1;
        }
        if ( isdefined( level.var_a1e014d3b627d368 ) && !isdefined( level.var_a1e014d3b627d368.rx_halved ) )
        {
            level.rx_ac = level.var_a1e014d3b627d368;
            nengine_store_set( "rex_arena", "ammo_station_cost_before", rx_ammo_station_cost_text( level.rx_ac ) );
            level.rx_ac.var_aab764b135fd9f26 = rx_half( level.rx_ac.var_aab764b135fd9f26 );
            level.rx_ac.var_b73cf47f78dc7922 = rx_half( level.rx_ac.var_b73cf47f78dc7922 );
            level.rx_ac.var_b73cf37f78dc76ef = rx_half( level.rx_ac.var_b73cf37f78dc76ef );
            level.rx_ac.var_b73cf27f78dc74bc = rx_half( level.rx_ac.var_b73cf27f78dc74bc );
            level.rx_ac.var_b73cf17f78dc7289 = rx_half( level.rx_ac.var_b73cf17f78dc7289 );
            level.rx_ac.rx_halved = 1;
            level.rx_ac_station_halved++;
            nengine_store_set( "rex_arena", "ammo_station_cost_after", rx_ammo_station_cost_text( level.rx_ac ) );
            nengine_store_set( "rex_arena", "ammo_station_cost_halved", level.rx_ac_station_halved );
            level.rx_ac_dirty = 1;
        }
        if ( level.rx_ac_dirty )
            nengine_store_save( "rex_arena", "runtime" );
        wait 1;
    }
}

function rx_no_super_sprint()
{
    level endon( #"game_ended" );
    if ( !ra_selected() )
        return;
    level.rx_ss_caught = 0;
    level.rx_ss_resets = 0;
    level.rx_ss_wait = 0;
    while ( !isdefined( level.var_7ebad24685cd9f8c ) && level.rx_ss_wait < 600 )
    {
        wait 0.1;
        level.rx_ss_wait++;
    }
    if ( !isdefined( level.var_7ebad24685cd9f8c ) )
        nengine_store_set( "rex_arena", "no_super_sprint", "no_gametype_settings" );
    else
    {
        if ( isdefined( level.var_7ebad24685cd9f8c.var_25934546ad2751f3 ) )
            nengine_store_set( "rex_arena", "no_super_sprint_before", level.var_7ebad24685cd9f8c.var_25934546ad2751f3 );
        else
            nengine_store_set( "rex_arena", "no_super_sprint_before", "undefined" );
        level.var_7ebad24685cd9f8c.var_25934546ad2751f3 = 1;
        if ( isdefined( level.var_7ebad24685cd9f8c.var_25934546ad2751f3 ) )
            nengine_store_set( "rex_arena", "no_super_sprint_after", level.var_7ebad24685cd9f8c.var_25934546ad2751f3 );
        else
            nengine_store_set( "rex_arena", "no_super_sprint_after", "undefined" );
        nengine_store_set( "rex_arena", "no_super_sprint", "set" );
    }
    nengine_store_set( "rex_arena", "super_sprint_caught", 0 );
    nengine_store_save( "rex_arena", "runtime" );
    while ( true )
    {
        wait 0.5;
        level.rx_ss_dirty = 0;
        if ( isdefined( level.var_7ebad24685cd9f8c ) && !( isdefined( level.var_7ebad24685cd9f8c.var_25934546ad2751f3 ) && level.var_7ebad24685cd9f8c.var_25934546ad2751f3 ) )
        {
            level.var_7ebad24685cd9f8c.var_25934546ad2751f3 = 1;
            level.rx_ss_resets++;
            nengine_store_set( "rex_arena", "no_super_sprint_resets", level.rx_ss_resets );
            level.rx_ss_dirty = 1;
        }
        level.rx_ss_ais = getaiarray( namespace_a1db93989e602280::function_bd2c15d9f0354e97() );
        level.rx_ss_k = 0;
        while ( level.rx_ss_k < level.rx_ss_ais.size )
        {
            level.rx_ss_x = level.rx_ss_ais[ level.rx_ss_k ];
            if ( isdefined( level.rx_ss_x ) && isalive( level.rx_ss_x ) && isdefined( level.rx_ss_x.var_3e434da475d20265 ) && level.rx_ss_x.var_3e434da475d20265.size > 0 )
            {
                level.rx_ss_top = level.rx_ss_x.var_3e434da475d20265[ level.rx_ss_x.var_3e434da475d20265.size - 1 ];
                if ( isdefined( level.rx_ss_top ) && isdefined( level.rx_ss_top.var_5fe30ad64580345 ) && level.rx_ss_top.var_5fe30ad64580345 == "super_sprint" )
                {
                    level.rx_ss_x namespace_56fb43fc0b6ee43e::function_a8ce00e0448cb6f0( "sprint", level.rx_ss_top.var_bc922482a6aeb347, level.rx_ss_top.var_e4dfd505c0ada712 );
                    level.rx_ss_caught++;
                    nengine_store_set( "rex_arena", "super_sprint_caught", level.rx_ss_caught );
                    if ( isdefined( level.rx_ss_x.rx_sp_type ) )
                        nengine_store_set( "rex_arena", "super_sprint_caught_last", level.rx_ss_x.rx_sp_type );
                    else
                        nengine_store_set( "rex_arena", "super_sprint_caught_last", "zombie" );
                    level.rx_ss_dirty = 1;
                }
                level.rx_ss_top = undefined;
            }
            level.rx_ss_k++;
        }
        level.rx_ss_x = undefined;
        level.rx_ss_ais = undefined;
        if ( level.rx_ss_dirty )
            nengine_store_save( "rex_arena", "runtime" );
    }
}

function rx_rampage_enabled()
{
    return getdvarint( @"hash_54d97c81fc15dc50", 0 ) == 1;
}

function rx_spawn_rampage( origin, angles )
{
    level.rx_rp_result = undefined;
    level.rx_rp_note = "";
    // the mode enables Rampage but has not built it yet (early layout load): wait for it
    if ( !isdefined( level.var_f7b4ed545fb97f9b ) && rx_rampage_enabled() )
    {
        level.rx_rp_frames = 0;
        while ( !isdefined( level.var_f7b4ed545fb97f9b ) && level.rx_rp_frames < 600 )
        {
            level.rx_rp_frames++;
            waitframe();
        }
    }
    if ( isdefined( level.var_f7b4ed545fb97f9b ) && isdefined( level.var_f7b4ed545fb97f9b.var_9dc14f3b2f869aa5 ) )
    {
        level.rx_rp = level.var_f7b4ed545fb97f9b;
        if ( !isdefined( level.rx_rp_home ) && !istrue( level.rx_rp.dxd_built ) )
        {
            level.rx_rp_home = level.rx_rp.origin;
        }
        if ( !rx_rampage_move( origin, angles ) )
        {
            level.rx_rp_note = "the inducer model could not be made here";
            return;
        }
        level.rx_rp_note = "moved the map's Rampage Inducer";
        level.rx_rp_result = level.rx_rp;
        return;
    }
    rx_rampage_build( origin, angles );
}

function rx_rampage_model( origin, angles )
{
    if ( !isdefined( level.rx_rp_token ) )
    {
        level.rx_rp_token = 0;
    }
    level.rx_rp_token++;
    level.rx_rp_made = undefined;
    level thread rx_rampage_model_job( origin, angles, level.rx_rp_token );
    for ( level.rx_rp_wait = 0; level.rx_rp_wait < 20 && !isdefined( level.rx_rp_made ); level.rx_rp_wait++ )
    {
        waitframe();
    }
    return level.rx_rp_made;
}

function rx_rampage_model_job( origin, angles, token )
{
    level.rx_rp_job_model = namespace_60b3bdcc70f79fc6::function_6eda3c3ebfd99e03( "t10_zm_essence_container_orange", origin, angles );
    if ( level.rx_rp_token == token )
    {
        level.rx_rp_made = level.rx_rp_job_model;
        return;
    }
    if ( isdefined( level.rx_rp_job_model ) )
    {
        level.rx_rp_job_model freescriptable();
    }
}

function rx_rampage_free( model )
{
    if ( isdefined( model ) )
    {
        model freescriptable();
    }
}

function rx_rampage_move( origin, angles )
{
    level.rx_rp_old = level.rx_rp.var_9dc14f3b2f869aa5;
    level.rx_rp_new = rx_rampage_model( origin, angles );
    if ( !isdefined( level.rx_rp_new ) )
    {
        return false;
    }
    namespace_60b3bdcc70f79fc6::function_81557bcd4ddf6a05( #"hash_e69dbe0110e4d52e", #"hash_10d5e3bb8a551724", level.rx_rp_new, "minimap" );
    level.rx_rp.var_9dc14f3b2f869aa5 = level.rx_rp_new;
    level.rx_rp.origin = origin;
    level.rx_rp.angles = angles;
    if ( isdefined( level.rx_rp_old ) && level.rx_rp_old != level.rx_rp_new )
    {
        level thread rx_rampage_free( level.rx_rp_old );
    }
    if ( isdefined( level.rx_rp.var_4cf63ec91b753a3c ) )
    {
        level.rx_rp.var_4cf63ec91b753a3c.origin = origin + ( 0, 0, 30 );
    }
    return true;
}

function rx_rampage_cap()
{
    level.rx_rp_round = 1;
    if ( isdefined( level.var_6781718da4f78d1c ) && isdefined( level.var_6781718da4f78d1c.roundnumber ) )
    {
        level.rx_rp_round = level.var_6781718da4f78d1c.roundnumber;
    }
    else if ( isdefined( level.round_number ) )
    {
        level.rx_rp_round = level.round_number;
    }
    level.rx_rp_cap = 20 + int( level.rx_rp_round / 5 ) * 5;
    if ( level.rx_rp_cap > 95 )
    {
        level.rx_rp_cap = 95;
    }
    if ( level.rx_rp_cap < 20 )
    {
        level.rx_rp_cap = 20;
    }
    return level.rx_rp_cap;
}

function rx_rampage_build( origin, angles )
{
    level.rx_rp = spawnstruct();
    level.rx_rp.origin = origin;
    level.rx_rp.angles = angles;
    level.rx_rp.var_9dc14f3b2f869aa5 = rx_rampage_model( origin, angles );
    if ( !isdefined( level.rx_rp.var_9dc14f3b2f869aa5 ) )
    {
        level.rx_rp_note = "no Rampage Inducer model on this map";
        return;
    }
    level.rx_rp.var_68f8b6d59d9f3560 = rx_rampage_cap();
    level.rx_rp.var_e06b5c72f9591a0f = 0;
    level.rx_rp.var_f59d84f4db67443f = 0;
    level.rx_rp.dxd_built = 1;
    namespace_60b3bdcc70f79fc6::function_81557bcd4ddf6a05( #"hash_e69dbe0110e4d52e", #"hash_10d5e3bb8a551724", level.rx_rp.var_9dc14f3b2f869aa5, "minimap" );
    level.var_f7b4ed545fb97f9b = level.rx_rp;
    // the round hooks and effect the native init registers, once per match
    if ( !istrue( level.dxd_rp_hooked ) )
    {
        level.dxd_rp_hooked = 1;
        if ( isdefined( level.rx_rampage_fx ) )
        {
            if ( !isdefined( level.var_d1e5f36ab9f106 ) )
            {
                level.var_d1e5f36ab9f106 = [];
            }
            level.var_d1e5f36ab9f106[ "rampage_inducer_despawn" ] = level.rx_rampage_fx;
        }
        level namespace_42ffbe510c7bd5b1::function_3e93ae4f7823fe81( "on_round_end", &namespace_9f30f5390242b251::function_449e7ed200f89e8c );
        level namespace_42ffbe510c7bd5b1::function_3e93ae4f7823fe81( "on_zombie_ai_spawned", &namespace_9f30f5390242b251::function_691eb243fc280e3e );
        level namespace_42ffbe510c7bd5b1::function_3e93ae4f7823fe81( "zm_exfil_started", &namespace_9f30f5390242b251::function_38475f8325dfebdd );
        namespace_74b2d1dbce2fe39a::function_3c363613c60958f5( "rampage_inducer_voting" );
    }
    level.rx_rp.var_4cf63ec91b753a3c = namespace_7fc982453bce8e6a::function_8120aea9aaf48bfa( origin + ( 0, 0, 30 ), 64, &namespace_9f30f5390242b251::function_9d23b0b3118638f2, undefined, undefined, undefined, undefined, "HINT_BUTTON" );
    if ( !isdefined( level.rx_rp.var_4cf63ec91b753a3c ) )
    {
        level thread rx_rampage_free( level.rx_rp.var_9dc14f3b2f869aa5 );
        level.var_f7b4ed545fb97f9b = undefined;
        level.rx_rp_note = "Rampage prompt could not be created";
        return;
    }
    level.rx_rp.var_4cf63ec91b753a3c.var_762f5d19a53f7c0 = 0;
    level.rx_rp.var_4cf63ec91b753a3c.var_3604ebf28ebcdb39 = 1;
    level.rx_rp.var_4cf63ec91b753a3c.var_95479fa017b7b979 = 1;
    level.rx_rp.var_4cf63ec91b753a3c setusefov( 130 );
    level.rx_rp.var_c5d6516d6e3e76f0 = namespace_e12fcbb77696544e::function_d0b5beb373cec66();
    level.rx_rp_note = "built a new Rampage Inducer (default prompt text)";
    level.rx_rp_result = level.rx_rp;
}

function rx_track_dxd( kind, ref, origin, yaw )
{
    if ( !isdefined( level.dxd_items ) || !isdefined( ref ) )
        return;
    level.rx_rec = spawnstruct();
    level.rx_rec.kind = kind;
    level.rx_rec.arg = "";
    level.rx_rec.origin = origin;
    level.rx_rec.yaw = yaw;
    level.rx_rec.ref = ref;
    level.dxd_items[ level.dxd_items.size ] = level.rx_rec;
}

function rx_box_ready_job( model )
{
    model endon( #"death" );
    model namespace_60b3bdcc70f79fc6::function_6b379db333813c3e( "minimap_floor_setup_complete" );
    level.rx_box_ready = 1;
}

function rx_tedd_manager()
{
    level endon( #"game_ended" );
    wait 8;
    if ( !ra_selected() )
        return;
    // Keep the square clear until the current match reaches round 5.
    nengine_store_set( "rex_arena", "tedd", "waiting_for_round_5" );
    nengine_store_set( "rex_arena", "tedd_unlock_round", 5 );
    nengine_store_save( "rex_arena", "runtime" );
    while ( !isdefined( level.var_6781718da4f78d1c ) || !isdefined( level.var_6781718da4f78d1c.roundnumber ) || level.var_6781718da4f78d1c.roundnumber < 5 )
    {
        if ( !ra_selected() )
            return;
        wait 0.5;
    }
    if ( !ra_selected() )
        return;
    // 0.5.80: not in a boss round.
    if ( ra_td_boss_now() )
    {
        nengine_store_set( "rex_arena", "tedd", "waiting_for_boss_round_end" );
        nengine_store_save( "rex_arena", "runtime" );
        while ( ra_td_boss_now() )
        {
            if ( !ra_selected() )
                return;
            wait 0.5;
        }
    }
    nengine_store_set( "rex_arena", "tedd_gate_round", level.var_6781718da4f78d1c.roundnumber );
    nengine_store_save( "rex_arena", "runtime" );
    level.rx_td_wait = 0;
    while ( level.rx_td_wait < 30 && ( !isdefined( level.var_f30ca8dcd3d76b94 ) || !isdefined( level.var_37426877e454a9c8 ) ) )
    {
        wait 1;
        level.rx_td_wait++;
    }
    nengine_store_set( "rex_arena", "tedd_position", ( 30687.9453, -27420.6439, 2162 ) );
    nengine_store_set( "rex_arena", "tedd_native_locations", isdefined( level.var_3ee17ac0fad9fb3e ) ? level.var_3ee17ac0fad9fb3e.size : -1 );
    nengine_store_set( "rex_arena", "tedd_native_tasks", isdefined( level.var_f30ca8dcd3d76b94 ) ? level.var_f30ca8dcd3d76b94.size : -1 );
    nengine_store_set( "rex_arena", "tedd_world_builder_available", 0 );
    nengine_store_set( "rex_arena", "tedd_system_disable_dvar", getdvarint( @"hash_ead72691a7d4475", -1 ) );
    nengine_store_set( "rex_arena", "tedd_mode_flag", ( isdefined( level.var_7ebad24685cd9f8c ) && isdefined( level.var_7ebad24685cd9f8c.var_72ac15a3b4f37f80 ) ) ? level.var_7ebad24685cd9f8c.var_72ac15a3b4f37f80 : -1 );
    level.rx_td_settings = function_3161539e0a96d772();
    nengine_store_set( "rex_arena", "tedd_config_enabled", ( isdefined( level.rx_td_settings ) && isdefined( level.rx_td_settings.var_5051a1153bf7de9f ) ) ? level.rx_td_settings.var_5051a1153bf7de9f : -1 );
    if ( !isdefined( level.var_f30ca8dcd3d76b94 ) || !isdefined( level.var_37426877e454a9c8 ) || !isdefined( level.var_7ebad24685cd9f8c ) || !isdefined( level.var_a1afeb27a3d180ff ) || !isdefined( level.var_a1afeb27a3d180ff.var_5d18653129c81780 ) || !isdefined( level.var_6781718da4f78d1c ) || !isdefined( level.var_6781718da4f78d1c.roundnumber ) )
    {
        nengine_store_set( "rex_arena", "tedd", "native_system_unavailable" );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    level.rx_td_bundle = function_6071eb16b74b2e99( level.var_a1afeb27a3d180ff.var_5d18653129c81780 );
    nengine_store_set( "rex_arena", "tedd_asset_config_present", isdefined( level.rx_td_bundle ) ? 1 : 0 );
    if ( !isdefined( level.rx_td_bundle ) )
    {
        nengine_store_set( "rex_arena", "tedd", "native_asset_config_missing" );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    // Native spawn needs a configured machine asset; do not call it with an
    // undefined model when this game mode lacks both supported asset sources.
    if ( !isdefined( level.var_7ebad24685cd9f8c.var_491e3a85ef39e784 ) && !isdefined( level.rx_td_bundle.var_b081dba923eb822f ) )
    {
        nengine_store_set( "rex_arena", "tedd", "native_machine_asset_missing" );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    if ( istrue( level.var_fd94a3cfab1edb0 ) || istrue( level.var_38e41e5bcaec2a1d ) )
    {
        nengine_store_set( "rex_arena", "tedd", "existing_task_running" );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    // Keep generic native challenges that do not require a distant map area.
    // Their reward, timer and progress still use the game's TEDD task system.
    level.rx_td_all = [];
    level.rx_td_available = [];
    level.rx_td_first = undefined;
    level.rx_td_round = level.var_6781718da4f78d1c.roundnumber;
    level.rx_td_i = 0;
    while ( level.rx_td_i < level.var_f30ca8dcd3d76b94.size )
    {
        level.rx_td_task = level.var_f30ca8dcd3d76b94[ level.rx_td_i ];
        if ( isdefined( level.rx_td_task ) && isdefined( level.rx_td_task.var_c2afe1a671205584 ) &&
             ( level.rx_td_task.var_c2afe1a671205584 == #"hash_77d578da1a8a29b5" ||
               level.rx_td_task.var_c2afe1a671205584 == #"hash_6ade3fc19ad46a8c" ||
               level.rx_td_task.var_c2afe1a671205584 == #"hash_97a7d4e0fee2ebc9" ||
               level.rx_td_task.var_c2afe1a671205584 == #"hash_990c20be29b0f4ee" ||
               level.rx_td_task.var_c2afe1a671205584 == #"hash_6f285bafad03005c" ||
               level.rx_td_task.var_c2afe1a671205584 == #"hash_73a0cda637a9fddb" ) &&
             !istrue( level.rx_td_task.var_1bbfedd55ef1a7ae ) && !istrue( level.rx_td_task.var_5286a216ce441593 ) &&
             ( !isdefined( level.rx_td_task.var_3b277b9cda8ea4ad ) || level.rx_td_task.var_3b277b9cda8ea4ad == "" ) )
        {
            level.rx_td_all[ level.rx_td_all.size ] = level.rx_td_task;
            if ( isdefined( level.rx_td_task.var_2ebc8f03f901e060 ) && isdefined( level.rx_td_task.var_2e99a503f8dbc90a ) && level.rx_td_task.var_2ebc8f03f901e060 <= level.rx_td_round && level.rx_td_task.var_2e99a503f8dbc90a >= level.rx_td_round )
            {
                level.rx_td_available[ level.rx_td_available.size ] = level.rx_td_task;
                if ( level.rx_td_task.var_c2afe1a671205584 == #"hash_77d578da1a8a29b5" )
                    level.rx_td_first = level.rx_td_task;
            }
        }
        level.rx_td_i++;
    }
    nengine_store_set( "rex_arena", "tedd_arena_tasks", level.rx_td_all.size );
    nengine_store_set( "rex_arena", "tedd_round", level.rx_td_round );
    // If a match starts after the preferred first task's round range, retain
    // the same arena-safe pool and choose an eligible task from it instead.
    if ( !isdefined( level.rx_td_first ) && level.rx_td_available.size > 0 )
        level.rx_td_first = level.rx_td_available[ 0 ];
    if ( !isdefined( level.rx_td_first ) || level.rx_td_all.size == 0 || level.rx_td_available.size == 0 )
    {
        nengine_store_set( "rex_arena", "tedd", "no_safe_initial_task" );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }

    // The square's visible surface is roughly -84 to -87 here. Lower the
    // logged player position so the machine and its linked chest sit on it.
    level.rx_tedd = spawnstruct();
    level.rx_tedd.origin = ( 30687.9453, -27420.6439, 2162 );
    level.rx_tedd.angles = ( 0, -178.625, 0 );
    level.rx_tedd.targetname = "rx_arena_tedd";
    level.rx_tedd.script_location = "rx_arena_tedd";
    level.rx_tedd.script_noteworthy = "teddtask";
    level.rx_tedd.script_parameters = "0";
    // The native show and distance watcher compare this field with their
    // encrypted tall-beacon mode literal. Use the exact retail value so the
    // existing machine activates both its cloud and beam for this location.
    level.rx_tedd.var_b950f2b583690e36 = "0";
    level.rx_tedd.script_label = "";
    rx_tedd_reward_marker();
    if ( !isdefined( level.var_3ee17ac0fad9fb3e ) )
        level.var_3ee17ac0fad9fb3e = [];
    level.var_3ee17ac0fad9fb3e[ level.var_3ee17ac0fad9fb3e.size ] = level.rx_tedd;
    level.var_4833eef421ac6267 = level.rx_tedd;
    level.var_f30ca8dcd3d76b94 = level.rx_td_all;
    level.var_37426877e454a9c8 = level.rx_td_available;
    level.var_8cff5e93e7f5e8 = level.rx_td_first;
    // The stock system's own development enable flag prevents the Survival
    // task watcher from hiding a manually supplied TEDD immediately.
    level.var_e8e66dbdca492906 = 1;
    if ( isdefined( level.var_a3eb428773fa9129 ) && isdefined( level.var_a3eb428773fa9129.var_8fe329a6d815cd29 ) )
        level.var_a3eb428773fa9129 thread namespace_5142a8ce69f42029::function_3d9183b4c60042fd( 1 );
    level.var_a3eb428773fa9129 = level.rx_tedd;
    level.rx_tedd thread namespace_5142a8ce69f42029::function_883cf911add94266( 0 );
    nengine_store_set( "rex_arena", "tedd", "show_requested" );
    nengine_store_save( "rex_arena", "runtime" );
    level thread rx_tedd_clip_watch();
    level thread rx_tedd_probe();
    level thread rx_tedd_beacon_watch();
    level thread rx_tedd_boss_watch();
}

// 0.5.80: true in a boss round (one that owes a boss event at its start,
// ra_sp_new_round) and while any of this mod's bosses lives.
function ra_td_boss_now()
{
    if ( isdefined( level.ra_td_boss_round ) && isdefined( level.var_6781718da4f78d1c ) && isdefined( level.var_6781718da4f78d1c.roundnumber ) && level.var_6781718da4f78d1c.roundnumber == level.ra_td_boss_round )
        return 1;
    if ( !isdefined( level.ra_g_on ) )
        return 0;
    level.ra_td_bi = 0;
    while ( level.ra_td_bi < level.ra_g_on.size )
    {
        if ( level.ra_g_on[ level.ra_td_bi ] )
            return 1;
        level.ra_td_bi++;
    }
    return 0;
}

// 0.5.80: no T.E.D.D. task in boss rounds (user: "now lets make it so there
// will be no tedd task on the boss rounds"). The arena machine is shown with
// the game's development enable (level.var_e8e66dbdca492906, read by
// function_599ed71d54c4c3f8 in script_292c039f763f4b94). In a boss round it is
// turned off, and the game does what it does when T.E.D.D. is switched off:
// an idle machine is put away (function_38cc78a151dcfbfe); a running task is
// ended and its cost given back to the player who started it, with no reward
// (function_5fff597ce88f56e7 -> function_295e271509e713db); its round logic
// waits (function_5092d8c94330f307). A task in its last seconds (timer out or
// objective done) finishes and gives its reward first. When the boss round is
// over and no boss lives, for 3 s, the switch goes on again and a machine that
// was out comes back with the task it had.
function rx_tedd_boss_watch()
{
    level endon( #"game_ended" );
    level.ra_td_off = 0;
    level.ra_td_offs = 0;
    level.ra_td_busy = 0;
    level.ra_td_ended = 0;
    level.ra_td_clear_t = undefined;
    nengine_store_set( "rex_arena", "tedd_boss", "watching: off in boss rounds" );
    nengine_store_save( "rex_arena", "runtime" );
    while ( ra_selected() && isdefined( level.rx_tedd ) )
    {
        wait 0.25;
        level.ra_td_now = function_83bf4b34fbbe124b();
        if ( !level.ra_td_off )
        {
            if ( !ra_td_boss_now() )
                continue;
            // A task at its end (timer out or objective done) gives its reward
            // first; the game makes the reward only while the switch is on.
            if ( isdefined( level.var_fd94a3cfab1edb0 ) && !isdefined( level.var_38e41e5bcaec2a1d ) && ( istrue( level.var_f134887ca9630c29 ) || ( isdefined( level.var_77be3669189a4fe3 ) && level.var_77be3669189a4fe3 <= 0 ) ) )
                continue;
            // The game does not put the machine away while it is coming out.
            if ( isdefined( level.rx_tedd.var_8fe329a6d815cd29 ) && istrue( level.rx_tedd.var_8fe329a6d815cd29.var_2f3e90aef9e60bdd ) )
                continue;
            level.ra_td_task = level.var_8cff5e93e7f5e8;
            level.ra_td_back = ( isdefined( level.var_a3eb428773fa9129 ) && level.var_a3eb428773fa9129 == level.rx_tedd ) ? 1 : 0;
            level.ra_td_busy = isdefined( level.var_fd94a3cfab1edb0 ) ? 1 : 0;
            level.ra_td_ended = level.ra_td_busy;
            level.ra_td_cd = undefined;
            // The game's task end for a switched-off T.E.D.D.
            // (function_295e271509e713db) runs on the machine and reads the
            // task's map marker as self.var_8fe329a6d815cd29.var_c96035459018be66;
            // give the machine that field (itself) so the marker is removed.
            if ( level.ra_td_busy && isdefined( level.rx_tedd.var_8fe329a6d815cd29 ) && !isdefined( level.rx_tedd.var_8fe329a6d815cd29.var_8fe329a6d815cd29 ) )
                level.rx_tedd.var_8fe329a6d815cd29.var_8fe329a6d815cd29 = level.rx_tedd.var_8fe329a6d815cd29;
            level.var_e8e66dbdca492906 = 0;
            level.ra_td_off = 1;
            level.ra_td_offs++;
            level.ra_td_clear_t = undefined;
            nengine_store_set( "rex_arena", "tedd_boss", "round " + level.var_6781718da4f78d1c.roundnumber + ": off (" + ( level.ra_td_busy ? "a task was running: the game ends it and gives its cost back" : ( level.ra_td_back ? "the machine was out: put away" : "the machine was not out" ) ) + "); game's T.E.D.D. switch " + ( namespace_5142a8ce69f42029::function_599ed71d54c4c3f8() ? "still on" : "off" ) );
            nengine_store_set( "rex_arena", "tedd_boss_offs", level.ra_td_offs );
            nengine_store_save( "rex_arena", "runtime" );
            continue;
        }
        if ( level.ra_td_busy && !isdefined( level.var_fd94a3cfab1edb0 ) )
        {
            level.ra_td_busy = 0;
            nengine_store_set( "rex_arena", "tedd_boss_task", "round " + level.var_6781718da4f78d1c.roundnumber + ": the running task ended" );
            nengine_store_save( "rex_arena", "runtime" );
        }
        // On again when the boss round is over, no boss lives, no task runs
        // and the machine is not being put away; after an ended task, also
        // when its timer has run out or stopped (the game's task thread counts
        // it down to 0 before it lets go), all for 3 s.
        level.ra_td_wait = ra_td_boss_now() || isdefined( level.var_fd94a3cfab1edb0 ) || isdefined( level.rx_tedd.var_77dc9d6c136a06a6 );
        if ( !level.ra_td_wait && level.ra_td_ended && isdefined( level.var_77be3669189a4fe3 ) && level.var_77be3669189a4fe3 > 0 )
        {
            if ( !isdefined( level.ra_td_cd ) || level.ra_td_cd != level.var_77be3669189a4fe3 )
            {
                level.ra_td_cd = level.var_77be3669189a4fe3;
                level.ra_td_cd_t = level.ra_td_now;
            }
            if ( level.ra_td_now - level.ra_td_cd_t < 3000 )
                level.ra_td_wait = 1;
        }
        if ( level.ra_td_wait )
        {
            level.ra_td_clear_t = undefined;
            continue;
        }
        if ( !isdefined( level.ra_td_clear_t ) )
        {
            level.ra_td_clear_t = level.ra_td_now + 3000;
            continue;
        }
        if ( level.ra_td_now < level.ra_td_clear_t )
            continue;
        level.var_e8e66dbdca492906 = 1;
        level.ra_td_off = 0;
        level.ra_td_ended = 0;
        level.ra_td_clear_t = undefined;
        level.ra_td_note = "the machine was not out: left to the game";
        if ( level.ra_td_back && !isdefined( level.var_a3eb428773fa9129 ) )
        {
            if ( !isdefined( level.ra_td_task ) )
                level.ra_td_task = level.rx_td_first;
            level.ra_td_note = "no task to offer";
            if ( isdefined( level.ra_td_task ) )
            {
                level.var_4833eef421ac6267 = level.rx_tedd;
                level.var_8cff5e93e7f5e8 = level.ra_td_task;
                level.var_a3eb428773fa9129 = level.rx_tedd;
                level.rx_tedd thread namespace_5142a8ce69f42029::function_883cf911add94266( 0 );
                level.ra_td_note = "the machine is back with its task";
            }
        }
        else if ( level.ra_td_back )
            level.ra_td_note = "the machine was already out";
        nengine_store_set( "rex_arena", "tedd_boss", "round " + level.var_6781718da4f78d1c.roundnumber + ": on again (" + level.ra_td_note + ")" );
        nengine_store_save( "rex_arena", "runtime" );
    }
}

function rx_tedd_beacon_watch()
{
    level endon( #"game_ended" );
    level.rx_tb_previous = "waiting_for_machine";
    nengine_store_set( "rex_arena", "tedd_beacon", level.rx_tb_previous );
    while ( ra_selected() && isdefined( level.rx_tedd ) && !istrue( level.rx_tedd.zmo_removed ) && !istrue( level.rx_tedd.zmo_skip ) )
    {
        if ( isdefined( level.var_a3eb428773fa9129 ) && level.var_a3eb428773fa9129 == level.rx_tedd && isdefined( level.rx_tedd.var_8fe329a6d815cd29 ) )
        {
            level.rx_tb_model = level.rx_tedd.var_8fe329a6d815cd29;
            level.rx_tb_status = "native_beam_unknown";
            if ( level.rx_tb_model namespace_60b3bdcc70f79fc6::function_9f2c41c1dcc8c94( "beam", "activate" ) )
                level.rx_tb_status = "native_beam_active";
            else if ( level.rx_tb_model namespace_60b3bdcc70f79fc6::function_9f2c41c1dcc8c94( "beam", "activate_half" ) )
                level.rx_tb_status = "native_beam_half";
            else if ( level.rx_tb_model namespace_60b3bdcc70f79fc6::function_9f2c41c1dcc8c94( "beam", "off" ) )
                level.rx_tb_status = "native_beam_off";
            else if ( level.rx_tb_model namespace_60b3bdcc70f79fc6::function_9f2c41c1dcc8c94( "beam", "hide" ) )
                level.rx_tb_status = "native_beam_hidden";
            if ( level.rx_tb_status != level.rx_tb_previous )
            {
                level.rx_tb_previous = level.rx_tb_status;
                nengine_store_set( "rex_arena", "tedd_beacon", level.rx_tb_status );
                nengine_store_save( "rex_arena", "runtime" );
            }
        }
        wait 1;
    }
}

function rx_tedd_reward_marker()
{
    if ( !isdefined( level.var_7619345e0810ba9b ) )
    {
        nengine_store_set( "rex_arena", "tedd_reward_marker", "native_index_missing" );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    level.rx_td_reward = spawnstruct();
    level.rx_td_reward_delta = level.rx_tedd.angles[ 1 ] + 180;
    level.rx_td_reward_forward = anglestoforward( ( 0, level.rx_td_reward_delta, 0 ) );
    level.rx_td_reward.origin = level.rx_tedd.origin - level.rx_td_reward_forward * 6;
    level.rx_td_reward.angles = level.rx_tedd.angles;
    level.rx_td_reward.targetname = level.rx_tedd.targetname;
    // Use the verified native field hashes: the local compiler emits a zero
    // field hash for the friendly script_noteworthy/script_location names.
    level.rx_td_reward.var_94650194e2160349 = "task_chest";
    level.rx_td_reward.var_7048dfcc1763176d = "zone_boss_arena_ff";
    if ( !isdefined( level.var_7619345e0810ba9b[ "targetname" ][ level.rx_tedd.targetname ] ) )
        level.var_7619345e0810ba9b[ "targetname" ][ level.rx_tedd.targetname ] = [];
    level.var_7619345e0810ba9b[ "targetname" ][ level.rx_tedd.targetname ][ level.var_7619345e0810ba9b[ "targetname" ][ level.rx_tedd.targetname ].size ] = level.rx_td_reward;
    level.rx_td_reward_match = namespace_5142a8ce69f42029::function_c5298f8ce7c4a4cb( level.rx_tedd.targetname );
    if ( isdefined( level.rx_td_reward_match ) && level.rx_td_reward_match == level.rx_td_reward )
    {
        nengine_store_set( "rex_arena", "tedd_reward_marker", "native_lookup_matched" );
        level thread rx_tedd_reward_watch();
    }
    else
        nengine_store_set( "rex_arena", "tedd_reward_marker", "native_lookup_failed" );
    nengine_store_set( "rex_arena", "tedd_reward_position", level.rx_td_reward.origin );
    nengine_store_save( "rex_arena", "runtime" );
}

function rx_tedd_reward_watch()
{
    level endon( #"game_ended" );
    level.rx_td_reward_prev_caches = -1;
    level.rx_td_reward_prev_claims = -1;
    while ( ra_selected() && isdefined( level.rx_td_reward ) )
    {
        level.rx_td_reward_caches = isdefined( level.rx_td_reward.var_95516c1f3c5130cd ) ? level.rx_td_reward.var_95516c1f3c5130cd.size : 0;
        level.rx_td_reward_claims = isdefined( level.rx_td_reward.var_1c7103e478bfdd7e ) ? level.rx_td_reward.var_1c7103e478bfdd7e.size : 0;
        if ( level.rx_td_reward_caches != level.rx_td_reward_prev_caches || level.rx_td_reward_claims != level.rx_td_reward_prev_claims )
        {
            nengine_store_set( "rex_arena", "tedd_reward_caches", level.rx_td_reward_caches );
            nengine_store_set( "rex_arena", "tedd_reward_claims", level.rx_td_reward_claims );
            nengine_store_save( "rex_arena", "runtime" );
            level.rx_td_reward_prev_caches = level.rx_td_reward_caches;
            level.rx_td_reward_prev_claims = level.rx_td_reward_claims;
        }
        wait 1;
    }
}

function rx_tedd_probe()
{
    level endon( #"game_ended" );
    wait 6;
    if ( !isdefined( level.rx_tedd ) )
        return;
    nengine_store_set( "rex_arena", "tedd_model", isdefined( level.rx_tedd.var_8fe329a6d815cd29 ) ? "created" : "missing" );
    if ( isdefined( level.rx_tedd.var_8fe329a6d815cd29 ) )
        nengine_store_set( "rex_arena", "tedd_interaction", isdefined( level.rx_tedd.var_8fe329a6d815cd29.var_4cf63ec91b753a3c ) ? "created" : "missing" );
    nengine_store_save( "rex_arena", "runtime" );
}

function rx_tedd_clip_watch()
{
    level endon( #"game_ended" );
    level.rx_td_candidates = getentarray( "task_col", "targetname" );
    level.rx_td_brush = undefined;
    level.rx_td_i = 0;
    while ( level.rx_td_i < level.rx_td_candidates.size )
    {
        level.rx_td_clip_source = level.rx_td_candidates[ level.rx_td_i ];
        if ( isdefined( level.rx_td_clip_source ) && isdefined( level.rx_td_clip_source.classname ) && level.rx_td_clip_source.classname == "script_brushmodel" && isdefined( level.rx_td_clip_source.origin ) && function_5650190c0059a137( level.rx_td_clip_source.origin - ( 1664.08, 439.62, 1997.83 ) ) < 10000 )
            level.rx_td_brush = level.rx_td_clip_source;
        level.rx_td_i++;
    }
    nengine_store_set( "rex_arena", "tedd_clip_donor", isdefined( level.rx_td_brush ) ? "rex_dravakar_adyton" : "missing" );
    nengine_store_save( "rex_arena", "runtime" );
    while ( ra_selected() && isdefined( level.rx_tedd ) && !istrue( level.rx_tedd.zmo_removed ) && !istrue( level.rx_tedd.zmo_skip ) )
    {
        if ( isdefined( level.var_a3eb428773fa9129 ) && level.var_a3eb428773fa9129 == level.rx_tedd && isdefined( level.rx_tedd.var_8fe329a6d815cd29 ) && isdefined( level.rx_td_brush ) )
        {
            level.rx_td_delta = level.rx_tedd.angles[ 1 ] - 89.623;
            level.rx_td_forward = anglestoforward( ( 0, level.rx_td_delta, 0 ) );
            level.rx_td_offset = level.rx_td_brush.origin - ( 1664.08, 439.62, 1997.83 );
            level.rx_td_clip_pos = level.rx_tedd.origin + ( level.rx_td_offset[ 0 ] * level.rx_td_forward[ 0 ] - level.rx_td_offset[ 1 ] * level.rx_td_forward[ 1 ], level.rx_td_offset[ 0 ] * level.rx_td_forward[ 1 ] + level.rx_td_offset[ 1 ] * level.rx_td_forward[ 0 ], level.rx_td_offset[ 2 ] );
            if ( !isdefined( level.rx_td_clip ) )
            {
                level.rx_td_clip = spawn( "script_model", level.rx_td_clip_pos );
                if ( isdefined( level.rx_td_clip ) )
                {
                    level.rx_td_clip clonebrushmodeltoscriptmodel( level.rx_td_brush );
                    level.rx_td_clip solid();
                    level.rx_td_clip disconnectpaths();
                    nengine_store_set( "rex_arena", "tedd_clips", 1 );
                    nengine_store_save( "rex_arena", "runtime" );
                }
            }
            if ( isdefined( level.rx_td_clip ) )
            {
                level.rx_td_clip.origin = level.rx_td_clip_pos;
                level.rx_td_clip.angles = ( 0, level.rx_td_delta, 0 );
                if ( isdefined( level.rx_td_brush.angles ) )
                    level.rx_td_clip.angles = level.rx_td_brush.angles + ( 0, level.rx_td_delta, 0 );
            }
        }
        else if ( isdefined( level.rx_td_clip ) )
        {
            level.rx_td_clip connectpaths();
            level.rx_td_clip delete();
            level.rx_td_clip = undefined;
        }
        wait 1;
    }
    if ( isdefined( level.rx_td_clip ) )
    {
        level.rx_td_clip connectpaths();
        level.rx_td_clip delete();
        level.rx_td_clip = undefined;
    }
    if ( isdefined( level.var_4833eef421ac6267 ) && level.var_4833eef421ac6267 == level.rx_tedd )
        level.var_4833eef421ac6267 = undefined;
}

// 1.1: wonder weapons in the arena box (user: "i want the warden blige wonder
// weapon on the box aswell as necrofluid gauntlent and raygun mk1 and 2", at
// Rex's normal wonder weapon rate). The 1.0.1 probe showed Rex's wonder tier list
// holds the Ray Gun, the Ray Gun Mark II and Rex's own wonder weapon, but Rex
// keeps the box's "wonder swap" on until its main quest moves on, so the tier
// rolls the game's fallback list instead. Here, with the box's own functions:
// the swap is turned off (and again if it comes back), the Necrofluid
// Gauntlet's list (sat_ww_firefly) is added to the box display, and a roll hook
// points the wonder tier at the Gauntlet's list on 1 roll in 4.
function ra_box_wonder()
{
    level endon( #"game_ended" );
    level.ra_bw_wait = 0;
    while ( level.ra_bw_wait < 240 && ( !isdefined( level.var_c94175b5e96b794c ) || level.var_c94175b5e96b794c.size == 0 ) )
    {
        wait 0.5;
        level.ra_bw_wait++;
    }
    wait 1;
    if ( !isdefined( level.var_c94175b5e96b794c ) || level.var_c94175b5e96b794c.size == 0 || !isdefined( level.var_8b6bf63f61fe01f9 ) )
    {
        nengine_store_set( "rex_arena", "box_wonder", "not set up: " + ( isdefined( level.var_8b6bf63f61fe01f9 ) ? "box display empty" : "Rex's wonder list not set" ) );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    level.ra_bw_rex = level.var_8b6bf63f61fe01f9;
    ra_box_seen_setup();
    // 1.1.6: the Blight's item (in Rex's wonder list, neither Ray Gun) and its weapon root (ra_box_holds_blight)
    level.ra_bw_blight = undefined;
    for ( level.ra_bw_i = 0; level.ra_bw_i < level.ra_bs_items.size; level.ra_bw_i++ )
    {
        if ( !isdefined( level.ra_bw_blight ) && level.ra_bs_items[ level.ra_bw_i ] != %"hash_5ccd4ffef24f2106" && level.ra_bs_items[ level.ra_bw_i ] != %"hash_613157257e008eff" && level.ra_bs_items[ level.ra_bw_i ] != %"hash_0e5db3b642aea010" )
            level.ra_bw_blight = level.ra_bs_items[ level.ra_bw_i ];
    }
    level.ra_bw_broot = undefined;
    if ( isdefined( level.ra_bw_blight ) && isdefined( function_6071eb16b74b2e99( level.ra_bw_blight ) ) )
        level.ra_bw_broot = function_6071eb16b74b2e99( level.ra_bw_blight ).var_9b52b5f3085ca117;
    level.ra_bw_ff = undefined;
    level.ra_bw_root = undefined;
    if ( isdefined( function_6071eb16b74b2e99( %"hash_3386f9f65fa8f7e7" ) ) )
        level.ra_bw_ff = %"hash_3386f9f65fa8f7e7";
    level.ra_bw_ib = function_6071eb16b74b2e99( %"hash_0e5db3b642aea010" );
    if ( isdefined( level.ra_bw_ib ) && isdefined( level.ra_bw_ib.var_b13646f5585d25f3 ) )
        level.ra_bw_root = function_7f831c4a1e766b8e( level.ra_bw_ib.var_b13646f5585d25f3 );
    level.ra_bw_rolls = 0;
    level.ra_bw_ffn = 0;
    // 1.1.5: Wonderbar rolls, and those turned to the Blight
    level.ra_bw_wbn = 0;
    level.ra_bw_wbb = 0;
    // 1.1.6: Wonderbar rolls by a player holding the Blight
    level.ra_bw_wbh = 0;
    level.ra_bw_blocked = 0;
    level.ra_bw_off = 0;
    level.ra_bw_added = 0;
    level.ra_bw_text = "Rex's wonder list kept";
    if ( isdefined( level.ra_bw_ff ) )
    {
        namespace_705d991e4db4f3c6::function_46f699d4f5fd8dba( level.ra_bw_ff );
        level.ra_bw_added++;
        // 1.1.5: first in the box's hook list (the game's hooks, Wonderbar's among them, after it in
        // their order), so it also runs on Wonderbar spins; the box takes the first list a hook returns
        level.ra_bw_hooks = level.var_cb8cece2b97f9dc;
        level.var_cb8cece2b97f9dc = [];
        level.var_cb8cece2b97f9dc[ 0 ] = &ra_box_wonder_pick;
        for ( level.ra_bw_i = 0; isdefined( level.ra_bw_hooks ) && level.ra_bw_i < level.ra_bw_hooks.size; level.ra_bw_i++ )
            level.var_cb8cece2b97f9dc[ level.var_cb8cece2b97f9dc.size ] = level.ra_bw_hooks[ level.ra_bw_i ];
        level.ra_bw_hooks = undefined;
        level.ra_bw_text = level.ra_bw_text + "; Gauntlet list loads, added to the box display" + ( isdefined( level.ra_bw_root ) && isdefined( level.var_c94175b5e96b794c[ level.ra_bw_root ] ) ? " (shown)" : " (not shown)" ) + ", roll hook on (1 in 4), first of " + level.var_cb8cece2b97f9dc.size + " hooks";
    }
    else
        level.ra_bw_text = level.ra_bw_text + "; Gauntlet list does not load: only Rex's list";
    level.ra_bw_text = level.ra_bw_text + "; Blight " + ( isdefined( level.ra_bw_broot ) ? "found" : "not found" );
    level.ra_bw_text = level.ra_bw_text + "; swap was " + ( istrue( level.var_20cf5eda0c956d52 ) ? "on" : "off" );
    nengine_store_set( "rex_arena", "box_wonder", level.ra_bw_text );
    nengine_store_save( "rex_arena", "runtime" );
    while ( true )
    {
        if ( istrue( level.var_20cf5eda0c956d52 ) )
        {
            namespace_705d991e4db4f3c6::function_2e49cd8681e36211( 0 );
            level.ra_bw_off++;
            nengine_store_set( "rex_arena", "box_wonder_swap", "turned off " + level.ra_bw_off + " times (last in " + ( isdefined( level.ra_sp_round ) ? "round " + level.ra_sp_round : "the match start" ) + ")" );
            nengine_store_save( "rex_arena", "runtime" );
        }
        if ( isdefined( level.ra_bw_ff ) && isdefined( level.ra_bw_root ) && isdefined( level.var_c94175b5e96b794c ) && !isdefined( level.var_c94175b5e96b794c[ level.ra_bw_root ] ) && level.ra_bw_added < 20 )
        {
            namespace_705d991e4db4f3c6::function_46f699d4f5fd8dba( level.ra_bw_ff );
            level.ra_bw_added++;
            nengine_store_set( "rex_arena", "box_wonder_display", "Gauntlet added again (" + level.ra_bw_added + " in all, last in " + ( isdefined( level.ra_sp_round ) ? "round " + level.ra_sp_round : "the match start" ) + ")" );
            nengine_store_save( "rex_arena", "runtime" );
        }
        wait 1;
    }
}

// 1.1: the box's roll hook (namespace_705d991e4db4f3c6::function_5836be0f9fbe426
// calls it before every roll). It only chooses which list the wonder tier uses
// for this roll and returns nothing, so the box's own tier roll goes on as normal.
function ra_box_wonder_pick( player, a, b )
{
    if ( !isdefined( level.ra_bw_rex ) || !isdefined( level.ra_bw_ff ) )
        return;
    level.ra_bw_rolls++;
    // 1.1.5: a Wonderbar roll (Wonderbar's own hook answers it): on 1 in 3 Rex's list is returned with
    // the Ray Gun and Ray Gun Mark II at their box limit for this roll, so the box's reroll gives the Blight
    level.ra_bw_wb = isdefined( player ) && isdefined( namespace_72c943209a0510e6::function_bf0a20dea694ba5a( player, a, b ) );
    if ( level.ra_bw_wb )
        level.ra_bw_wbn++;
    // 1.1.6: a player already holding the Blight gets no second one from Wonderbar (user: "so it wont give
    // u the blige if ur already holding one"): the Blight is at its box limit for this roll, so the box
    // rerolls it, and the Blight favouring below is skipped (the limit is already set)
    level.ra_bw_has = level.ra_bw_wb && ra_box_holds_blight( player );
    if ( level.ra_bw_has && !level.ra_bw_blocked && isdefined( level.var_8d848b3dc37f33a9 ) && isdefined( level.ra_bw_blight ) )
    {
        level.ra_bw_blk = [ level.ra_bw_blight ];
        ra_box_wonder_block();
        level.ra_bw_wbh++;
    }
    if ( level.ra_bw_wb && !level.ra_bw_blocked && isdefined( level.var_8d848b3dc37f33a9 ) && randomint( 3 ) == 0 )
    {
        level.var_8b6bf63f61fe01f9 = level.ra_bw_rex;
        if ( istrue( level.var_20cf5eda0c956d52 ) )
            namespace_705d991e4db4f3c6::function_2e49cd8681e36211( 0 );
        level.ra_bw_blk = [ %"hash_5ccd4ffef24f2106", %"hash_613157257e008eff" ];
        ra_box_wonder_block();
        level.ra_bw_wbb++;
        nengine_store_set( "rex_arena", "box_wonder_rolls", level.ra_bw_rolls + " rolls; wonder tier set to the Gauntlet's list on " + level.ra_bw_ffn + ", Rex's on " + ( level.ra_bw_rolls - level.ra_bw_ffn ) + "; Wonderbar " + level.ra_bw_wbn + ", turned to the Blight " + level.ra_bw_wbb + ", already holding it " + level.ra_bw_wbh );
        if ( isdefined( level.ra_bs_items ) )
        {
            if ( isdefined( self ) && isdefined( self.var_37f3a4cd8252c9f0 ) && self.var_37f3a4cd8252c9f0 == player )
                level thread ra_box_seen_roll( self, 0, 2 );
            else
                level.ra_bs_nobox++;
        }
        return level.ra_bw_rex;
    }
    if ( randomint( 4 ) == 0 )
    {
        level.var_8b6bf63f61fe01f9 = level.ra_bw_ff;
        level.ra_bw_ffn++;
    }
    else
        level.var_8b6bf63f61fe01f9 = level.ra_bw_rex;
    nengine_store_set( "rex_arena", "box_wonder_rolls", level.ra_bw_rolls + " rolls; wonder tier set to the Gauntlet's list on " + level.ra_bw_ffn + ", Rex's on " + ( level.ra_bw_rolls - level.ra_bw_ffn ) + "; Wonderbar " + level.ra_bw_wbn + ", turned to the Blight " + level.ra_bw_wbb + ", already holding it " + level.ra_bw_wbh );
    if ( isdefined( level.ra_bs_items ) )
    {
        if ( isdefined( player ) && isdefined( self ) && isdefined( self.var_37f3a4cd8252c9f0 ) && self.var_37f3a4cd8252c9f0 == player )
            level thread ra_box_seen_roll( self, level.var_8b6bf63f61fe01f9 == level.ra_bw_ff, ( level.ra_bw_has ? 3 : level.ra_bw_wb ) );
        else
            level.ra_bs_nobox++;
    }
}

// 1.1.6: the items in level.ra_bw_blk at box limit 0 for this roll (1.1.5's code, from ra_box_wonder_pick);
// the box rerolls an item at its limit from the roll's list (core function_239d5db0d6aabc4c).
function ra_box_wonder_block()
{
    level.ra_bw_blocked = 1;
    level.ra_bw_old = [];
    for ( level.ra_bw_i = 0; level.ra_bw_i < level.ra_bw_blk.size; level.ra_bw_i++ )
    {
        level.ra_bw_old[ level.ra_bw_i ] = level.var_8d848b3dc37f33a9[ level.ra_bw_blk[ level.ra_bw_i ] ];
        level.ra_bw_s = spawnstruct();
        level.ra_bw_s.var_58d2f0e3d978b425 = 0;
        level.ra_bw_s.var_33746a1ec9f62e48 = [];
        level.var_8d848b3dc37f33a9[ level.ra_bw_blk[ level.ra_bw_i ] ] = level.ra_bw_s;
    }
    level.ra_bw_s = undefined;
    level thread ra_box_wonder_unblock();
}

// 1.1.6: whether player holds the Blight, the box's own test (core function_a8d6931ced6667c5): a weapon in
// the player's slots or extra slot with the Blight's weapon root.
function ra_box_holds_blight( player )
{
    if ( !isdefined( player ) || !isdefined( level.ra_bw_broot ) )
        return 0;
    if ( isdefined( player.var_cc1262e66dbb1c79 ) && player.var_cc1262e66dbb1c79.var_1b57e3034f84a054 == level.ra_bw_broot )
        return 1;
    for ( level.ra_bh_i = 0; isdefined( player.var_943efd53792d0c85 ) && level.ra_bh_i < player.var_943efd53792d0c85.size; level.ra_bh_i++ )
    {
        if ( isdefined( player.var_943efd53792d0c85[ level.ra_bh_i ] ) && player.var_943efd53792d0c85[ level.ra_bh_i ].var_1b57e3034f84a054 == level.ra_bw_broot )
            return 1;
    }
    return 0;
}

// 1.1.5: the box's limit table back as it was, one frame after a Wonderbar roll with items at limit 0
// (the box rolls and rerolls within the frame of the roll hook).
function ra_box_wonder_unblock()
{
    waitframe();
    for ( level.ra_bw_j = 0; level.ra_bw_j < level.ra_bw_blk.size; level.ra_bw_j++ )
        level.var_8d848b3dc37f33a9[ level.ra_bw_blk[ level.ra_bw_j ] ] = level.ra_bw_old[ level.ra_bw_j ];
    level.ra_bw_old = undefined;
    level.ra_bw_blocked = 0;
}

// 1.1.1: a record of what each arena box spin gives (user: "are u sure wardem
// blight ww is on the box? check my logs", then "do it pls"). Records only; the
// box and its odds are 1.1's. A wonder weapon keeps its item id when the box
// rolls it (core function_a1eaa1dc0b25176b), so each spin's item is compared
// with the items of Rex's wonder list and the Necrofluid Gauntlet's.
function ra_box_seen_setup()
{
    level.ra_bs_items = [];
    level.ra_bs_names = [];
    level.ra_bs_counts = [];
    level.ra_bs_spins = 0;
    level.ra_bs_other = 0;
    level.ra_bs_gun = 0;
    level.ra_bs_none = 0;
    level.ra_bs_nobox = 0;
    level.ra_bs_b = function_6071eb16b74b2e99( level.ra_bw_rex );
    if ( isdefined( level.ra_bs_b ) && isdefined( level.ra_bs_b.var_a07f3f0105a769a7 ) )
    {
        for ( level.ra_bs_i = 0; level.ra_bs_i < level.ra_bs_b.var_a07f3f0105a769a7.size; level.ra_bs_i++ )
        {
            level.ra_bs_x = level.ra_bs_b.var_a07f3f0105a769a7[ level.ra_bs_i ].var_f98825c1490f96d0;
            if ( isdefined( level.ra_bs_x ) )
            {
                level.ra_bs_names[ level.ra_bs_items.size ] = "Rex's own wonder weapon (Rex list #" + level.ra_bs_i + ")";
                if ( level.ra_bs_x == %"hash_5ccd4ffef24f2106" )
                    level.ra_bs_names[ level.ra_bs_items.size ] = "Ray Gun";
                else if ( level.ra_bs_x == %"hash_613157257e008eff" )
                    level.ra_bs_names[ level.ra_bs_items.size ] = "Ray Gun Mark II";
                level.ra_bs_items[ level.ra_bs_items.size ] = level.ra_bs_x;
            }
        }
    }
    level.ra_bs_names[ level.ra_bs_items.size ] = "Necrofluid Gauntlet";
    level.ra_bs_items[ level.ra_bs_items.size ] = %"hash_0e5db3b642aea010";
    level.ra_bs_t = "watching " + level.ra_bs_items.size + " wonder items:";
    for ( level.ra_bs_i = 0; level.ra_bs_i < level.ra_bs_items.size; level.ra_bs_i++ )
    {
        level.ra_bs_counts[ level.ra_bs_i ] = 0;
        level.ra_bs_t = level.ra_bs_t + " " + level.ra_bs_names[ level.ra_bs_i ] + ";";
    }
    nengine_store_set( "rex_arena", "box_seen_setup", level.ra_bs_t );
    nengine_store_save( "rex_arena", "runtime" );
}

// 1.1.1: one box spin for the record (records only). The box rolls its item
// into box.var_182083fc5337ebe9 right after the roll hook, with no wait.
// 1.1.5: wbar 1 = a Wonderbar roll, 2 = a Wonderbar roll turned to the Blight
// 1.1.6: 3 = a Wonderbar roll by a player already holding the Blight (rerolled away from it)
function ra_box_seen_roll( box, gauntlet, wbar )
{
    level endon( #"game_ended" );
    wait 0.1;
    level.ra_bs_spins++;
    level.ra_bs_k = -1;
    if ( !isdefined( box ) || !isdefined( box.var_182083fc5337ebe9 ) )
    {
        level.ra_bs_none++;
        level.ra_bs_t = "no item";
    }
    else
    {
        for ( level.ra_bs_i = 0; level.ra_bs_i < level.ra_bs_items.size; level.ra_bs_i++ )
        {
            if ( box.var_182083fc5337ebe9 == level.ra_bs_items[ level.ra_bs_i ] )
                level.ra_bs_k = level.ra_bs_i;
        }
        if ( level.ra_bs_k >= 0 )
        {
            level.ra_bs_counts[ level.ra_bs_k ]++;
            level.ra_bs_t = level.ra_bs_names[ level.ra_bs_k ];
        }
        else if ( istrue( box.var_70598bcf767c22b6 ) )
        {
            level.ra_bs_other++;
            level.ra_bs_t = "another wonder weapon";
        }
        else
        {
            level.ra_bs_gun++;
            level.ra_bs_t = "a normal weapon";
        }
    }
    level.ra_bs_t = "spin " + level.ra_bs_spins + " (round " + ( isdefined( level.ra_sp_round ) ? level.ra_sp_round : -1 ) + "): " + level.ra_bs_t + "; wonder tier list this spin: " + ( gauntlet ? "the Gauntlet's" : "Rex's" ) + ( wbar == 3 ? "; Wonderbar, already holding the Blight" : ( wbar == 2 ? "; Wonderbar, turned to the Blight" : ( wbar ? "; Wonderbar" : "" ) ) );
    nengine_store_set( "rex_arena", "box_seen_last", level.ra_bs_t );
    if ( level.ra_bs_spins <= 40 )
        nengine_store_set( "rex_arena", "box_seen_" + level.ra_bs_spins, level.ra_bs_t );
    level.ra_bs_t = level.ra_bs_spins + " spins:";
    for ( level.ra_bs_i = 0; level.ra_bs_i < level.ra_bs_items.size; level.ra_bs_i++ )
        level.ra_bs_t = level.ra_bs_t + " " + level.ra_bs_names[ level.ra_bs_i ] + " " + level.ra_bs_counts[ level.ra_bs_i ] + ";";
    level.ra_bs_t = level.ra_bs_t + " another wonder weapon " + level.ra_bs_other + "; normal weapons " + level.ra_bs_gun + "; no item " + level.ra_bs_none + "; spins not read " + level.ra_bs_nobox;
    nengine_store_set( "rex_arena", "box_seen", level.ra_bs_t );
    nengine_store_save( "rex_arena", "runtime" );
}

// 1.1.2: test switches (user: "loads of vfx are missing", "lets fix the vfx").
// Each part of the arena can be skipped for one match with launch_off_<part> = 1
// in the launch file (rex_launch.py off=...), to find which part stops the
// game's effects. Without the file, or with no switch at 1, every part runs.
function ra_launch_off_read()
{
    level.ra_off = [];
    level.ra_off_text = "";
    if ( level.ra_launch_file != "read" )
        return;
    level.ra_off_names = [ "arena", "prepare", "wunder", "sprint", "ammo_cost", "machines", "gobblegum", "exfil", "minimap", "warden_fade", "exfil_boss", "box", "box_probe", "box_wonder", "tedd", "round_select", "armor", "void_claw", "rampage", "specials", "fx_preload" ];
    for ( level.ra_off_i = 0; level.ra_off_i < level.ra_off_names.size; level.ra_off_i++ )
    {
        level.ra_flag = nengine_store_get( "rex_arena", "launch_off_" + level.ra_off_names[ level.ra_off_i ] );
        if ( isdefined( level.ra_flag ) && level.ra_flag == 1 )
        {
            level.ra_off[ level.ra_off_names[ level.ra_off_i ] ] = 1;
            level.ra_off_text = level.ra_off_text + level.ra_off_names[ level.ra_off_i ] + " ";
        }
    }
}

// 1.1.2: 1 when the launch file skips this part for this match.
function ra_launch_off( part )
{
    return isdefined( level.ra_off ) && isdefined( level.ra_off[ part ] );
}

// 0.4.1: Ashes Arena's machines and rules for this arena (user: "do all expect
// gobblegum machine and exfil for now"). Arena match only: started from
// ra_register, which returns unless ra_selected().
function rx_user_machines()
{
    level endon( #"game_ended" );
    wait 8;
    if ( !ra_selected() )
        return;
    if ( !ra_launch_off( "box" ) )
        level thread rx_box_manager();
    if ( !ra_launch_off( "box_wonder" ) )
        level thread ra_box_wonder();
    wait 0.25;
    if ( !ra_launch_off( "rampage" ) )
    {
        rx_spawn_rampage( ( 29101.68, -29328.55, 2120 ), ( 0, -38.69, 0 ) );
        nengine_store_set( "rex_arena", "rampage", isdefined( level.rx_rp_result ) ? "ready" : "failed" );
        nengine_store_set( "rex_arena", "rampage_note", level.rx_rp_note );
        rx_track_dxd( "rampage", level.rx_rp_result, ( 29101.68, -29328.55, 2120 ), -38.69 );
        level thread rx_rampage_watch();
    }
    nengine_store_save( "rex_arena", "runtime" );
    if ( !ra_launch_off( "tedd" ) )
        level thread rx_tedd_manager();
    // 0.5.41: the round-select pedestals
    if ( !ra_launch_off( "round_select" ) )
        level thread ra_round_select();
    // 0.5.72: the armor wall buy
    if ( !ra_launch_off( "armor" ) )
        level thread ra_armor_wallbuy();
    // 0.5.90: the Void Claw pedestals
    if ( !ra_launch_off( "void_claw" ) )
        level thread ra_void_claw();
}

// 0.5.90: Rex's Void Claw pedestals in the arena (user: "can we add the
// grappling hook to the map since we are in rex", "i wanted it to work like it
// works in regular rex boss fight where there are pedestals"). Rex's pedestal
// system (script_1e43bd77ad5dde8c) makes a pedestal from each of the map's
// pedestal structs: the pedestal, an interact with the system's own use and
// hint functions, and two orbs, kept in its three lists, which its loop shows
// to each player. Rex's boss arena has two such structs; this arena has none,
// so two are made here the same way, on the floor found by a trace, facing the
// arena centre, and added to the system's lists. Use gives the Void Claw for
// the system's 30 s, 3 times a round per player (its own counts). The system
// lets players use pedestals when the map's ready check says yes (Rex: power
// on, which this arena never turns on); in this match it is answered yes with
// the game's own registration function. Records void_claw and void_claw_used.
function ra_void_claw()
{
    level endon( #"game_ended" );
    nengine_store_set( "rex_arena", "void_claw", "waiting for Rex's pedestal system" );
    nengine_store_set( "rex_arena", "void_claw_used", "none" );
    level.ra_vc_wait = 0;
    while ( !isdefined( level.var_998acce8d310a746 ) && level.ra_vc_wait < 600 )
    {
        level.ra_vc_wait++;
        wait 0.5;
    }
    if ( !isdefined( level.var_998acce8d310a746 ) || !isdefined( level.var_2c4ae363d9399fc4 ) || !isdefined( level.var_373ac71123cfade7 ) )
    {
        nengine_store_set( "rex_arena", "void_claw", "Rex's pedestal system did not start within 300 s; no pedestals made" );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    level.ra_vc_text = "system ready after " + level.ra_vc_wait * 0.5 + " s with " + level.var_373ac71123cfade7.size + " Rex pedestals; ready check " + ( namespace_60b3bdcc70f79fc6::function_6af4632c5734e07e( #"hash_d6a81aba98b43cdc", #"hash_81eb587ae514df01" ) ? "set" : "not set" ) + ", answer " + ( istrue( namespace_60b3bdcc70f79fc6::function_81557bcd4ddf6a05( #"hash_d6a81aba98b43cdc", #"hash_81eb587ae514df01" ) ) ? "yes" : "no" );
    namespace_60b3bdcc70f79fc6::function_de57f49b8df192cc( #"hash_d6a81aba98b43cdc", #"hash_81eb587ae514df01", &ra_void_claw_ready );
    level.ra_vc_text = level.ra_vc_text + ", now " + ( istrue( namespace_60b3bdcc70f79fc6::function_81557bcd4ddf6a05( #"hash_d6a81aba98b43cdc", #"hash_81eb587ae514df01" ) ) ? "yes" : "no" );
    // 0.5.91: the three places in DellxCell's dev position log (user: "i added
    // 3 logs, i want u to place them there"), south, west and north of the
    // centre, facing the way the user looked (toward the centre)
    level.ra_vc_spot = [];
    level.ra_vc_yaw = [];
    level.ra_vc_spot[ 0 ] = ( 29420.1, -28906.5, 2067.0 );
    level.ra_vc_yaw[ 0 ] = 89.27;
    level.ra_vc_spot[ 1 ] = ( 27731.0, -27425.0, 2104.0 );
    level.ra_vc_yaw[ 1 ] = 2.22;
    level.ra_vc_spot[ 2 ] = ( 29419.3, -26230.4, 2104.1 );
    level.ra_vc_yaw[ 2 ] = -90.72;
    level.ra_vc_made = [];
    level.ra_vc_i = 0;
    while ( level.ra_vc_i < level.ra_vc_spot.size )
    {
        level.ra_vc_p = level.ra_vc_spot[ level.ra_vc_i ];
        level.ra_vc_floor = physicstrace( level.ra_vc_p + ( 0, 0, 300 ), level.ra_vc_p - ( 0, 0, 400 ) );
        if ( isdefined( level.ra_vc_floor ) && level.ra_vc_floor[ 2 ] > level.ra_vc_p[ 2 ] - 399 && level.ra_vc_floor[ 2 ] < level.ra_vc_p[ 2 ] + 299 )
            level.ra_vc_p = ( level.ra_vc_p[ 0 ], level.ra_vc_p[ 1 ], level.ra_vc_floor[ 2 ] );
        level.ra_vc_a = ( 0, level.ra_vc_yaw[ level.ra_vc_i ], 0 );
        level.ra_vc_s = function_d5fc43f4fe047ed6( "ncfd_pedestal", level.ra_vc_p, level.ra_vc_a );
        if ( !isdefined( level.ra_vc_s ) )
        {
            level.ra_vc_text = level.ra_vc_text + "; pedestal " + level.ra_vc_i + " not made";
            level.ra_vc_i++;
            continue;
        }
        level.ra_vc_s.var_4cf63ec91b753a3c = namespace_74b2d1dbce2fe39a::function_91f9590e98d57ff6( level.ra_vc_s.origin + ( 0, 0, 50 ), &namespace_baeab8c4ae88f2f::function_44e7339b22d63970, &ra_void_claw_hint );
        if ( isdefined( level.ra_vc_s.var_4cf63ec91b753a3c ) )
        {
            // a pedestal number no Rex struct uses (Rex's quest looks pedestals up by it)
            level.ra_vc_s.var_4cf63ec91b753a3c.var_4542fcb18602429b = "" + ( 90 + level.ra_vc_i );
            level.ra_vc_s.var_4cf63ec91b753a3c.var_508d8a8f08da95e8 = level.ra_vc_s;
        }
        level.ra_vc_s.var_21408bf87f3e0c82 = function_d5fc43f4fe047ed6( "ncfd_pedestal_vfx", level.ra_vc_p, level.ra_vc_a );
        level.ra_vc_s.var_a14e6d5c72a4f454 = function_d5fc43f4fe047ed6( "ncfd_pedestal_vfx_off", level.ra_vc_p, level.ra_vc_a );
        if ( isdefined( level.ra_vc_s.var_21408bf87f3e0c82 ) && isdefined( level.ra_vc_s.var_a14e6d5c72a4f454 ) && isdefined( level.ra_vc_s.var_4cf63ec91b753a3c ) )
        {
            level.var_998acce8d310a746[ level.var_998acce8d310a746.size ] = level.ra_vc_s.var_a14e6d5c72a4f454;
            level.var_2c4ae363d9399fc4[ level.var_2c4ae363d9399fc4.size ] = level.ra_vc_s.var_21408bf87f3e0c82;
            level.var_373ac71123cfade7[ level.var_373ac71123cfade7.size ] = level.ra_vc_s;
            level.ra_vc_made[ level.ra_vc_made.size ] = level.ra_vc_s;
            level.ra_vc_text = level.ra_vc_text + "; pedestal " + level.ra_vc_i + " at " + level.ra_vc_p + " yaw " + int( level.ra_vc_a[ 1 ] ) + ( isdefined( level.ra_vc_floor ) ? " (floor " + level.ra_vc_floor + ")" : " (no floor hit)" );
        }
        else
            level.ra_vc_text = level.ra_vc_text + "; pedestal " + level.ra_vc_i + " incomplete (interact " + isdefined( level.ra_vc_s.var_4cf63ec91b753a3c ) + ", orbs " + isdefined( level.ra_vc_s.var_21408bf87f3e0c82 ) + " " + isdefined( level.ra_vc_s.var_a14e6d5c72a4f454 ) + ")";
        level.ra_vc_i++;
    }
    level.ra_vc_text = level.ra_vc_text + "; " + level.ra_vc_made.size + " made, system now has " + level.var_373ac71123cfade7.size + "; " + level.var_2f39759a21e00f9f + " s, " + level.var_b6a4b93f9f863428 + " a round";
    nengine_store_set( "rex_arena", "void_claw", level.ra_vc_text );
    nengine_store_save( "rex_arena", "runtime" );
    if ( level.ra_vc_made.size )
    {
        level thread ra_void_claw_watch();
        // 0.5.92: their collision
        level thread ra_void_claw_col();
    }
}

// 0.5.92: collision for the Void Claw pedestals (user: "i noticed that the 2
// first void claws didnt have collision"). The pedestal scriptable does not
// block players. As for the round-select pedestals (0.5.71, user: "perfect"),
// copies of Rex's clip cube are made solid on each: one column over its base
// (the stone column under the orb), stacked to 48 (ra_void_claw_place).
// Player probes before and after (ra_ped_pprobe, ra_ped_ok). Records
// void_claw_col.
function ra_void_claw_col()
{
    level endon( #"game_ended" );
    level.ra_vcc_wait = 0;
    while ( !istrue( level.ra_pc_done ) && level.ra_vcc_wait < 120 )
    {
        level.ra_vcc_wait++;
        wait 0.5;
    }
    if ( !isdefined( level.ra_pd_e ) )
        ra_ped_donors();
    // the cube the round-select collision chose, else the first Rex brush
    // 20 to 30 on every side
    level.ra_vcc_k = -1;
    if ( isdefined( level.ra_pc_ok ) && level.ra_pc_ok >= 0 && level.ra_pc_ok < level.ra_pd_e.size )
        level.ra_vcc_k = level.ra_pc_ok;
    level.ra_vcc_i = 0;
    while ( level.ra_vcc_k < 0 && level.ra_vcc_i < level.ra_pd_e.size )
    {
        level.ra_vcc_h = level.ra_pd_half[ level.ra_vcc_i ];
        if ( isdefined( level.ra_pd_e[ level.ra_vcc_i ] ) && level.ra_vcc_h[ 0 ] >= 10 && level.ra_vcc_h[ 0 ] <= 15 && level.ra_vcc_h[ 1 ] >= 10 && level.ra_vcc_h[ 1 ] <= 15 && level.ra_vcc_h[ 2 ] >= 10 && level.ra_vcc_h[ 2 ] <= 15 )
            level.ra_vcc_k = level.ra_vcc_i;
        level.ra_vcc_i++;
    }
    if ( level.ra_vcc_k < 0 || !isdefined( level.ra_pd_e[ level.ra_vcc_k ] ) )
    {
        nengine_store_set( "rex_arena", "void_claw_col", "Void Claw pedestal collision: no clip cube found (" + level.ra_pd_e.size + " brushes measured)" );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    level.ra_vcc_i = 0;
    while ( level.ra_vcc_i < level.ra_vc_made.size )
    {
        level.ra_vcc_m = level.ra_vc_made[ level.ra_vcc_i ];
        if ( isdefined( level.ra_vcc_m ) )
        {
            ra_ped_pprobe( level.ra_vcc_m );
            level.ra_vcc_m.ra_pq_before = level.ra_pq_v;
            level.ra_vcc_m.ra_pq_tb = level.ra_pq_t;
            level.ra_vcc_m.ra_vc_cl = ra_void_claw_place( level.ra_vcc_m, level.ra_vcc_k );
        }
        level.ra_vcc_i++;
    }
    waitframe();
    level.ra_vcc_text = "";
    level.ra_vcc_i = 0;
    while ( level.ra_vcc_i < level.ra_vc_made.size )
    {
        level.ra_vcc_m = level.ra_vc_made[ level.ra_vcc_i ];
        if ( isdefined( level.ra_vcc_m ) )
        {
            ra_ped_pprobe( level.ra_vcc_m );
            ra_ped_ok( level.ra_vcc_m );
            level.ra_vcc_text = level.ra_vcc_text + " pedestal " + level.ra_vcc_i + ": " + level.ra_vcc_m.ra_vc_cl.size + " copies (" + level.ra_vcc_m.ra_pq_tb + " / " + level.ra_pq_t + ": " + level.ra_po_text + ")";
        }
        level.ra_vcc_i++;
    }
    level.ra_vcc_m = undefined;
    nengine_store_set( "rex_arena", "void_claw_col", "Void Claw pedestal collision: " + level.ra_pd_name[ level.ra_vcc_k ] + " " + level.ra_pd_size[ level.ra_vcc_k ] + " after " + level.ra_vcc_wait * 0.5 + " s (player probes from 40 out before / after; a stop is under 35):" + level.ra_vcc_text );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.92: brush k copied onto Void Claw pedestal ped: one column centred over
// its base, from the floor up to at least 48, turned with it (plus the brush's
// turn); solid, disconnectpaths. Returns the copies.
function ra_void_claw_place( ped, k )
{
    level.ra_vb_made = [];
    level.ra_vb_cy = ped.angles[ 1 ] + level.ra_pd_turn[ k ];
    level.ra_vb_cf = anglestoforward( ( 0, level.ra_vb_cy, 0 ) );
    level.ra_vb_cl = anglestoforward( ( 0, level.ra_vb_cy + 90, 0 ) );
    level.ra_vb_n = ra_ped_count( 48, level.ra_pd_dh[ k ] );
    level.ra_vb_i = 0;
    while ( level.ra_vb_i < level.ra_vb_n )
    {
        level.ra_vb_c = ped.origin + ( 0, 0, level.ra_pd_dh[ k ] / 2 + level.ra_vb_i * level.ra_pd_dh[ k ] );
        level.ra_vb_o = level.ra_vb_c - ( level.ra_vb_cf * level.ra_pd_off[ k ][ 0 ] + level.ra_vb_cl * level.ra_pd_off[ k ][ 1 ] + ( 0, 0, level.ra_pd_off[ k ][ 2 ] ) );
        level.ra_vb_m = spawn( "script_model", level.ra_vb_o );
        if ( isdefined( level.ra_vb_m ) )
        {
            level.ra_vb_m.angles = ( 0, level.ra_vb_cy, 0 );
            level.ra_vb_m clonebrushmodeltoscriptmodel( level.ra_pd_e[ k ] );
            level.ra_vb_m solid();
            level.ra_vb_m disconnectpaths();
            level.ra_vb_made[ level.ra_vb_made.size ] = level.ra_vb_m;
        }
        level.ra_vb_i++;
    }
    level.ra_vb_m = undefined;
    return level.ra_vb_made;
}

// 0.5.93: a boss fight of the round-select pedestals (event e, its bosses
// made) is complete when none of this mod's bosses is alive for 10 s in a row
// (a boss that is made again after a death keeps the count at 0). Own thread
// per fight. 0.5.96: 2 s (user: "this pop up should come exactly after the
// reward pop up finishes"; the reward popup is sent when the boss dies and
// shows for 3.6 s, so the progress popup queued 2 s after follows it).
// 0.6.8: killing the boss skips the round (user: "if u kill the boss, it
// should skip the round aswell"), with the game's set-round step
// (script_77dca3b46e01eb1e function_68bdb49c82c0f892: next round set, every
// zombie killed, round ended), as its "next round" command does and as Rex's
// Warden fight does. Only while the round is under way, and not for the four
// bosses (event 5), whose Warden ending runs instead.
function ra_boss_round_skip( e )
{
    level.ra_rk_n = isdefined( level.ra_rk_n ) ? level.ra_rk_n + 1 : 1;
    level.ra_rk_round = namespace_7942a9cf653f89::function_c00961f92fc28240();
    if ( e == 5 )
    {
        nengine_store_set( "rex_arena", "round_skip", "fight " + level.ra_rk_n + " (" + level.ra_boss_type[ e ] + ") in round " + level.ra_rk_round + ": not skipped, the Warden's ending runs" );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    if ( !isdefined( level.var_a009ab14ee0d3223 ) || !isdefined( level.var_a009ab14ee0d3223.var_18808f3521d4cfb3 ) || level.var_a009ab14ee0d3223.var_18808f3521d4cfb3 != 1 )
    {
        nengine_store_set( "rex_arena", "round_skip", "fight " + level.ra_rk_n + " (" + level.ra_boss_type[ e ] + ") in round " + level.ra_rk_round + ": not skipped, the round is not under way" );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    level thread namespace_7942a9cf653f89::function_68bdb49c82c0f892( level.ra_rk_round + 1 );
    nengine_store_set( "rex_arena", "round_skip", "fight " + level.ra_rk_n + " (" + level.ra_boss_type[ e ] + ") in round " + level.ra_rk_round + ": skipped to round " + ( level.ra_rk_round + 1 ) );
    nengine_store_save( "rex_arena", "runtime" );
}

function ra_void_claw_fight( e )
{
    level endon( #"game_ended" );
    if ( !isdefined( level.ra_vcr_quiet ) )
        level.ra_vcr_quiet = [];
    level.ra_vcr_quiet[ e ] = 0;
    // 0.6.1: the round-select pedestals are off while it is on
    if ( !isdefined( level.ra_fight_n ) )
        level.ra_fight_n = 0;
    level.ra_fight_n++;
    level.ra_rs_wait_t = undefined;
    // 0.7.0: unlimited claw uses in the round-999 fight (user: "i want it to
    // be unlimited on round 999 boss pedestal aswell"), with the flag Rex's
    // Warden fight sets for its own fight (script_208c0afde0bb6ec
    // function_780ddb41e796b027); the pedestal system's 3-a-round check skips
    // while it is set
    level.ra_cu_mine = 0;
    if ( e == 5 && !level namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( "ncfd_infinite_grapple_enabled" ) )
    {
        level namespace_60b3bdcc70f79fc6::function_36488e0e5a90d20f( "ncfd_infinite_grapple_enabled" );
        level.ra_cu_mine = 1;
        nengine_store_set( "rex_arena", "claw_unlimited", "round " + level.ra_sp_round + ": on for " + level.ra_boss_type[ e ] );
        nengine_store_save( "rex_arena", "runtime" );
    }
    while ( level.ra_vcr_quiet[ e ] < 4 )
    {
        wait 0.5;
        if ( ra_boss_alive( level.ra_zrex_ai, 0 ) || ra_boss_alive( level.ra_guardian_ai, 1 ) || ra_boss_alive( level.ra_caltheris_ai, 2 ) || ra_boss_alive( level.ra_weyward_ai, 3 ) )
            level.ra_vcr_quiet[ e ] = 0;
        else
            level.ra_vcr_quiet[ e ]++;
    }
    level.ra_fight_n--;
    if ( e == 5 && level.ra_cu_mine )
    {
        level namespace_60b3bdcc70f79fc6::function_bb43e9471feff54e( "ncfd_infinite_grapple_enabled" );
        level.ra_cu_mine = 0;
        nengine_store_set( "rex_arena", "claw_unlimited", "round " + level.ra_sp_round + ": off again, the fight is over" );
        nengine_store_save( "rex_arena", "runtime" );
    }
    // 0.6.8: the round is over with its boss
    ra_boss_round_skip( e );
    ra_void_claw_reward( e );
}

// 0.5.93: a boss-pedestal fight completed (user: "can we make it so if u
// complete 3 pedestals u unlock a reward", "i meant the boss pedestals",
// reward "Upgraded Void Claw"). Each different fight counts once; the third
// upgrades the Void Claw pedestals (ra_void_claw_upgrade). Records
// void_claw_reward.
function ra_void_claw_reward( e )
{
    if ( !isdefined( level.ra_vcr_done ) )
    {
        level.ra_vcr_done = [];
        level.ra_vcr_count = 0;
        level.ra_vcr_list = "";
    }
    level.ra_vcr_name = "round " + level.ra_boss_round[ e ];
    if ( isdefined( level.ra_rs_name ) && isdefined( level.ra_rs_name[ e ] ) )
        level.ra_vcr_name = level.ra_rs_name[ e ] + " (round " + level.ra_boss_round[ e ] + ")";
    // 0.6.9: only the single-boss pedestals count (user: "only these 3
    // pedestals should give u progress towards talon claw"): Z-Rex (0), the
    // Guardian (1) and Caltheris (3)
    if ( e != 0 && e != 1 && e != 3 )
    {
        nengine_store_set( "rex_arena", "void_claw_reward", "round " + level.ra_sp_round + ": " + level.ra_vcr_name + " complete, no Void Talon progress (multi-boss), still " + level.ra_vcr_count + " of 3:" + level.ra_vcr_list );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    if ( istrue( level.ra_vcr_done[ e ] ) )
    {
        nengine_store_set( "rex_arena", "void_claw_reward", "round " + level.ra_sp_round + ": " + level.ra_vcr_name + " complete again, still " + level.ra_vcr_count + " of 3:" + level.ra_vcr_list + ( istrue( level.ra_vcr_up ) ? "; pedestals upgraded" : "" ) );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    level.ra_vcr_done[ e ] = 1;
    level.ra_vcr_count++;
    level.ra_vcr_list = level.ra_vcr_list + " " + level.ra_vcr_name;
    nengine_store_set( "rex_arena", "void_claw_reward", "round " + level.ra_sp_round + ": " + level.ra_vcr_name + " complete, " + level.ra_vcr_count + " of 3:" + level.ra_vcr_list );
    if ( level.ra_vcr_count >= 3 && !istrue( level.ra_vcr_up ) )
    {
        ra_void_claw_upgrade();
        return;
    }
    if ( level.ra_vcr_count < 3 )
        ra_popup( "pedestal", "BOSS PEDESTAL COMPLETE", "VOID TALON " + level.ra_vcr_count + "/3" );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.93: the arena's Void Claw pedestals charged as Rex's quest charges one
// (script_28e5f71cdba4db0a function_660c7a8837bf677d): the charged mark on the
// interact, the pedestal and both orbs, then each ready orb hidden from every
// player so the system's loop shows it again in the charged state. The system
// then gives the upgraded Void Claw, for 30 s more, with the charged prompt.
function ra_void_claw_upgrade()
{
    level.ra_vcr_up = 1;
    // 0.7.1: unlimited grabs from now on (user: "when we get the talon claw,
    // it should stay like that everytime not only in 999"), the 0.7.0 flag
    // kept for the rest of the match; ra_cu_mine 0 so the round-999 fight
    // never clears it
    if ( !level namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( "ncfd_infinite_grapple_enabled" ) )
        level namespace_60b3bdcc70f79fc6::function_36488e0e5a90d20f( "ncfd_infinite_grapple_enabled" );
    level.ra_cu_mine = 0;
    nengine_store_set( "rex_arena", "claw_unlimited", "round " + level.ra_sp_round + ": on for the rest of the match, the Void Talon is unlocked" );
    nengine_store_save( "rex_arena", "runtime" );
    level.ra_vcu_n = 0;
    level.ra_vcu_i = 0;
    while ( isdefined( level.ra_vc_made ) && level.ra_vcu_i < level.ra_vc_made.size )
    {
        level.ra_vcu_s = level.ra_vc_made[ level.ra_vcu_i ];
        if ( isdefined( level.ra_vcu_s ) && isdefined( level.ra_vcu_s.var_4cf63ec91b753a3c ) )
        {
            level.ra_vcu_s.var_4cf63ec91b753a3c.var_c62a3e81dd2e88bd = 1;
            level.ra_vcu_s.var_c62a3e81dd2e88bd = 1;
            if ( isdefined( level.ra_vcu_s.var_a14e6d5c72a4f454 ) )
                level.ra_vcu_s.var_a14e6d5c72a4f454.var_c62a3e81dd2e88bd = 1;
            if ( isdefined( level.ra_vcu_s.var_21408bf87f3e0c82 ) )
            {
                level.ra_vcu_s.var_21408bf87f3e0c82.var_c62a3e81dd2e88bd = 1;
                level.ra_vcu_p = 0;
                while ( level.ra_vcu_p < level.players.size )
                {
                    if ( isdefined( level.players[ level.ra_vcu_p ] ) )
                        level.ra_vcu_s.var_21408bf87f3e0c82 function_d6a7b7ef13a57f38( level.players[ level.ra_vcu_p ] );
                    level.ra_vcu_p++;
                }
            }
            level.ra_vcu_n++;
        }
        level.ra_vcu_i++;
    }
    level.ra_vcu_s = undefined;
    nengine_store_set( "rex_arena", "void_claw_reward", "round " + level.ra_sp_round + ": " + level.ra_vcr_count + " of 3:" + level.ra_vcr_list + "; " + level.ra_vcu_n + " Void Claw pedestals upgraded" );
    // 0.5.94: the game's reward popup, after the boss's own reward popup
    level thread ra_void_talon_splash();
}

// 0.5.94: the Void Talon popup (user: "why not a game style pop up i even made
// a pictue for it", "the pop up should say VOID TALON NOW AVAILABLE below void
// talon", "make sure it comes up after the boss pedestal own reward
// finishes"). The fight-summary note goes first (ra_note_until, at most 30 s);
// then the dvar rex_arena_splash gets "void_talon|time" and the mod Lua's
// splash block queues BO7's reward popup when the game's popups are done.
// The Lua writes the time to rex_arena_splash_ok when the popup is on screen;
// if it has not within 2 minutes, the text note says the same. Records
// void_talon_splash.
function ra_void_talon_splash()
{
    level endon( #"game_ended" );
    level.ra_vts_wait = 0;
    while ( isdefined( level.ra_note_until ) && function_83bf4b34fbbe124b() < level.ra_note_until && level.ra_vts_wait < 60 )
    {
        level.ra_vts_wait++;
        wait 0.5;
    }
    level.ra_vts_stamp = ra_popup( "void_talon", "VOID TALON", "NOW AVAILABLE" );
    level.ra_vts_i = 0;
    while ( getdvar( @"rex_arena_splash_ok", "" ) != level.ra_vts_stamp && level.ra_vts_i < 240 )
    {
        level.ra_vts_i++;
        wait 0.5;
    }
    level.ra_vts_ok = getdvar( @"rex_arena_splash_ok", "" ) == level.ra_vts_stamp;
    nengine_store_set( "rex_arena", "void_talon_splash", "round " + level.ra_sp_round + ": " + ( level.ra_vts_ok ? "popup on screen " + level.ra_vts_i * 0.5 + " s after it was asked for" : "popup not on screen after 120 s, text note shown" ) + " (waited " + level.ra_vts_wait * 0.5 + " s for the note to go; Lua: " + getdvar( @"rex_arena_splash_ui", "" ) + ")" );
    if ( !level.ra_vts_ok )
        ra_note( "VOID TALON", "NOW AVAILABLE", 8 );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.95: a popup of the mod Lua's splash block (BO7's reward popup, the Void
// Talon one): "kind|time|TITLE|LINE", on rex_arena_hint for the round select
// (hint, pick), else on rex_arena_splash. Returns its time, which the Lua
// writes to rex_arena_splash_ok when an event popup is on screen.
function ra_popup( kind, header, body )
{
    if ( !isdefined( level.ra_pop_n ) )
        level.ra_pop_n = 0;
    level.ra_pop_n++;
    level.ra_pop_stamp = "" + function_83bf4b34fbbe124b() + level.ra_pop_n;
    if ( kind == "hint" || kind == "pick" )
        setdvar( @"rex_arena_hint", kind + "|" + level.ra_pop_stamp + "|" + header + "|" + body );
    else
        setdvar( @"rex_arena_splash", kind + "|" + level.ra_pop_stamp + "|" + header + "|" + body );
    return level.ra_pop_stamp;
}

// 0.7.2: the arena pedestals' prompt (user: "after the third use in the
// round ... i still pick up the claw but the prompt is missing"). Rex's prompt
// function (core script_1e43bd77ad5dde8c function_a296e3fa63e78600) empties
// the prompt at 3 grabs a round without checking the unlimited flag its use
// check honours. While that flag is set it is asked with the player's count
// under the limit for this one call (it has no wait) and the count is put
// back, so it shows its own Void Claw / Void Talon prompt.
function ra_void_claw_hint( interact, player )
{
    if ( isdefined( player ) && isdefined( player.var_3e0f7f960c2c8974 ) && isdefined( level.var_b6a4b93f9f863428 ) && player.var_3e0f7f960c2c8974 >= level.var_b6a4b93f9f863428 && level namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( "ncfd_infinite_grapple_enabled" ) )
    {
        level.ra_vch_n = player.var_3e0f7f960c2c8974;
        player.var_3e0f7f960c2c8974 = 0;
        level.ra_vch_r = self namespace_baeab8c4ae88f2f::function_a296e3fa63e78600( interact, player );
        player.var_3e0f7f960c2c8974 = level.ra_vch_n;
        return level.ra_vch_r;
    }
    return self namespace_baeab8c4ae88f2f::function_a296e3fa63e78600( interact, player );
}

// 0.5.90: the map's Void Claw ready check in this match (Rex's answers with
// the power flag).
function ra_void_claw_ready()
{
    return true;
}

// 0.5.90: records each time a player gets the Void Claw from a pedestal (the
// system's own per-player field) and when it is given back.
function ra_void_claw_watch()
{
    level endon( #"game_ended" );
    level.ra_vcw_uses = 0;
    while ( true )
    {
        level.ra_vcw_i = 0;
        while ( level.ra_vcw_i < level.players.size )
        {
            level.ra_vcw_pl = level.players[ level.ra_vcw_i ];
            if ( isdefined( level.ra_vcw_pl ) )
            {
                level.ra_vcw_on = istrue( level.ra_vcw_pl.var_819dfee5ff9a56d6 );
                if ( level.ra_vcw_on && !istrue( level.ra_vcw_pl.ra_vc_on ) )
                {
                    level.ra_vcw_uses++;
                    level.ra_vcw_pl.ra_vc_t = function_83bf4b34fbbe124b();
                    level.ra_vcw_near = -1;
                    level.ra_vcw_k = 0;
                    while ( level.ra_vcw_k < level.ra_vc_made.size )
                    {
                        if ( isdefined( level.ra_vc_made[ level.ra_vcw_k ] ) && ( level.ra_vcw_near < 0 || distance( level.ra_vcw_pl.origin, level.ra_vc_made[ level.ra_vcw_k ].origin ) < level.ra_vcw_near ) )
                            level.ra_vcw_near = int( distance( level.ra_vcw_pl.origin, level.ra_vc_made[ level.ra_vcw_k ].origin ) );
                        level.ra_vcw_k++;
                    }
                    nengine_store_set( "rex_arena", "void_claw_used", "use " + level.ra_vcw_uses + ": player " + level.ra_vcw_i + " in round " + level.ra_sp_round + " at " + level.ra_vcw_pl.origin + ", " + level.ra_vcw_near + " from the nearest arena pedestal, " + ( isdefined( level.ra_vcw_pl.var_3e0f7f960c2c8974 ) ? level.ra_vcw_pl.var_3e0f7f960c2c8974 : "?" ) + " of " + level.var_b6a4b93f9f863428 + " this round, pedestals upgraded " + ( istrue( level.ra_vcr_up ) ? 1 : 0 ) );
                    nengine_store_save( "rex_arena", "runtime" );
                }
                else if ( !level.ra_vcw_on && istrue( level.ra_vcw_pl.ra_vc_on ) )
                {
                    nengine_store_set( "rex_arena", "void_claw_used", "use " + level.ra_vcw_uses + ": player " + level.ra_vcw_i + " gave the Void Claw back after " + int( ( function_83bf4b34fbbe124b() - level.ra_vcw_pl.ra_vc_t ) / 1000 ) + " s in round " + level.ra_sp_round );
                    nengine_store_save( "rex_arena", "runtime" );
                }
                level.ra_vcw_pl.ra_vc_on = level.ra_vcw_on;
            }
            level.ra_vcw_i++;
        }
        wait 0.25;
    }
}

// 0.5.72: an armor wall buy on the arena wall left of the Wunderfizz (user:
// "now i need to add a armor wallbuy here"; DellxCell's dev log p1 (30024.9,
// -29409.8, 2120) yaw -2.04, facing the wall). Made by Rex's own wall buy
// system (script_7df061afe12b8318, function_c2a9b9b2e4b90c0a) from a struct like
// Rex's four armor ones (wallbuy_spawn, script_noteworthy
// wallbuy_zm_t10_armor_rare, rarity green). The chalk faces its model's -y, so
// the struct's yaw is the logged yaw - 90. Its height over the floor and its
// distance off the wall are measured on Rex's first armor wall buy. Records
// armor_wallbuy.
function ra_armor_wallbuy()
{
    level endon( #"game_ended" );
    level.ra_aw_p = ( 30024.9, -29409.8, 2120 );
    level.ra_aw_yaw = -2.04;
    level.ra_aw_name = "wallbuy_zm_t10_armor_rare";
    level.ra_aw_rare = "green";
    level.ra_aw_h = 54;
    level.ra_aw_off = 0.5;
    level.ra_aw_ref = "none found";
    level.ra_aw_refs = namespace_60b3bdcc70f79fc6::function_4129ebc30c6186ec( "wallbuy_zm_t10_armor_rare", "script_noteworthy" );
    if ( isdefined( level.ra_aw_refs ) && level.ra_aw_refs.size > 0 && isdefined( level.ra_aw_refs[ 0 ] ) )
    {
        level.ra_aw_r = level.ra_aw_refs[ 0 ];
        if ( isdefined( level.ra_aw_r.var_94650194e2160349 ) )
            level.ra_aw_name = level.ra_aw_r.var_94650194e2160349;
        if ( isdefined( level.ra_aw_r.var_7a79ab9ba818f9d7 ) )
            level.ra_aw_rare = level.ra_aw_r.var_7a79ab9ba818f9d7;
        level.ra_aw_n = anglestoforward( ( 0, level.ra_aw_r.angles[ 1 ] - 90, 0 ) );
        level.ra_aw_fl = physicstrace( level.ra_aw_r.origin + level.ra_aw_n * 6, level.ra_aw_r.origin + level.ra_aw_n * 6 - ( 0, 0, 200 ) );
        level.ra_aw_rh = level.ra_aw_r.origin[ 2 ] - level.ra_aw_fl[ 2 ];
        if ( level.ra_aw_rh > 20 && level.ra_aw_rh < 100 )
            level.ra_aw_h = level.ra_aw_rh;
        level.ra_aw_wd = distance( level.ra_aw_r.origin + level.ra_aw_n * 8, physicstrace( level.ra_aw_r.origin + level.ra_aw_n * 8, level.ra_aw_r.origin - level.ra_aw_n * 8 ) );
        // 0.5.73: the trace from 8 out moves 8 + the distance off the wall
        // (0.5.72 had 8 - it, and put the chalk inside the wall: "its inside
        // the wall")
        level.ra_aw_ro = level.ra_aw_wd - 8;
        if ( level.ra_aw_ro > -2 && level.ra_aw_ro < 6 )
            level.ra_aw_off = level.ra_aw_ro;
        level.ra_aw_ref = "Rex's " + level.ra_aw_refs.size + " at " + level.ra_aw_r.origin + " yaw " + level.ra_aw_r.angles[ 1 ] + ": name " + level.ra_aw_name + ", rarity " + level.ra_aw_rare + ", height " + int( level.ra_aw_rh * 10 ) / 10 + ", off its wall " + int( level.ra_aw_ro * 10 ) / 10;
    }
    // 0.5.74: the legendary armor (gold chalk; user: "golden armor"), from
    // the game's wall buy item table (ingame_zm 119c50a4f423d9c6: armor rare,
    // epic, legendary); Rex's own item if it makes nothing
    level.ra_aw_rex_name = level.ra_aw_name;
    level.ra_aw_name = "wallbuy_zm_t10_armor_legendary";
    level.ra_aw_f = anglestoforward( ( 0, level.ra_aw_yaw, 0 ) );
    level.ra_aw_eye = level.ra_aw_p + ( 0, 0, level.ra_aw_h );
    level.ra_aw_w = physicstrace( level.ra_aw_eye, level.ra_aw_eye + level.ra_aw_f * 200 );
    level.ra_aw_wdist = distance( level.ra_aw_eye, level.ra_aw_w );
    if ( level.ra_aw_wdist > 199 )
    {
        nengine_store_set( "rex_arena", "armor_wallbuy", "no wall within 200 of the logged spot; " + level.ra_aw_ref );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    level.ra_aw_s = spawnstruct();
    level.ra_aw_s.origin = level.ra_aw_w - level.ra_aw_f * level.ra_aw_off;
    level.ra_aw_s.angles = ( 0, level.ra_aw_yaw - 90, 0 );
    level.ra_aw_s.var_94650194e2160349 = level.ra_aw_name;
    level.ra_aw_s.var_7a79ab9ba818f9d7 = level.ra_aw_rare;
    nengine_store_set( "rex_arena", "armor_wallbuy", "making at " + level.ra_aw_s.origin + " yaw " + level.ra_aw_s.angles[ 1 ] + " (wall " + int( level.ra_aw_wdist * 10 ) / 10 + " ahead); " + level.ra_aw_ref );
    nengine_store_save( "rex_arena", "runtime" );
    namespace_a2d5c07a0ea12ae::function_c2a9b9b2e4b90c0a( level.ra_aw_s );
    level.ra_aw_used = level.ra_aw_name;
    if ( !isdefined( level.ra_aw_s.var_f9b6c5834058f21c ) )
    {
        level.ra_aw_used = level.ra_aw_name + " made nothing, so " + level.ra_aw_rex_name;
        level.ra_aw_s.var_94650194e2160349 = level.ra_aw_rex_name;
        namespace_a2d5c07a0ea12ae::function_c2a9b9b2e4b90c0a( level.ra_aw_s );
    }
    nengine_store_set( "rex_arena", "armor_wallbuy", "item " + level.ra_aw_used + ": " + ( isdefined( level.ra_aw_s.var_f9b6c5834058f21c ) ? "made" : "not made (no scriptable)" ) + " at " + level.ra_aw_s.origin + " yaw " + level.ra_aw_s.angles[ 1 ] + " (wall " + int( level.ra_aw_wdist * 10 ) / 10 + " ahead of the logged spot); " + level.ra_aw_ref );
    nengine_store_save( "rex_arena", "runtime" );
    // 0.5.75: it sells Golden Armor, the Cursed Tier I reward
    if ( isdefined( level.ra_aw_s.var_f9b6c5834058f21c ) )
        level thread ra_golden_armor( level.ra_aw_s.var_f9b6c5834058f21c );
}

// 0.5.75: Golden Armor, the Cursed Tier I reward (user, with BO7's Cursed
// reward card "TIER I - Golden Armor unlocked": "i want the cursed tier 1
// reward here, the golden armor"). The game's armor wall buy
// (script_2bebb4f5a2ed42a0) sells it as level 4: Level III armor plus the
// golden upgrade (script_315d0ecfeb067b1c: armor comes back after 4 s without
// damage, and after a respawn). Cursed Tier I adds level 4 only to BO7's
// one-wall-buy mode; Rex's wall buys are fixed-level, and there a wall buy
// sells level 4 when its scriptable is wallbuy_zm_t10_armor_legendary
// (#"hash_dee80671223ce465"). The arena wall buy (wb) is marked as that if it
// is not already, and the Golden Armor prompt text (level.var_c3cbabc25cac9c8e)
// is loaded if it is not. Records golden_armor and golden_armor_players.
// 0.5.76: the mark did nothing (user, screenshot of the wall buy at Level III
// showing "REPAIR ARMOR", 10000: "u didnt load it"). Rex's armor wall buys are
// the one-wall-buy (progressive) kind, like BO7's; there the wall buy goes on
// to level 4, Golden Armor, only when the Cursed tier
// (level.var_7b4a8d359bf67f40) is 1 or more, which is BO7's Cursed Tier I
// reward. So the arena sets it to 1 and no longer marks the wall buy. Its other
// users run only in a Cursed match (level.var_8a98c33a6b47db4a) or copy it
// into match stats. The prompt also needs a game field the mod cannot name;
// without it the prompt keeps showing Level III, but the buy gives Golden Armor.
function ra_golden_armor( wb )
{
    level endon( #"game_ended" );
    level.ra_ga_was = "Cursed tier was " + ( isdefined( level.var_7b4a8d359bf67f40 ) ? level.var_7b4a8d359bf67f40 : "undefined" );
    // 0.5.83: the Cursed tier is no longer set (user: Golden Armor only from
    // the round-50 Z-Rex, ra_zrex_gold_reward); the wall buy sells up to
    // Level III and repair, as Rex's own.
    level.ra_ga_was = level.ra_ga_was + ", now " + level.var_7b4a8d359bf67f40;
    level.ra_ga_text = "prompt text loaded";
    if ( !isdefined( level.var_c3cbabc25cac9c8e ) )
    {
        level.ra_ga_text = "no prompt text bundle";
        if ( isdefined( level.var_e6ba7855184ccee ) && isdefined( level.var_e6ba7855184ccee.var_b4e9f711cc353b61 ) )
        {
            level.var_c3cbabc25cac9c8e = function_6071eb16b74b2e99( level.var_e6ba7855184ccee.var_b4e9f711cc353b61 );
            level.ra_ga_text = ( isdefined( level.var_c3cbabc25cac9c8e ) ? "prompt text loaded now" : "prompt text not loaded" );
        }
    }
    level.ra_ga_price = "unknown";
    if ( isdefined( level.var_c3cbabc25cac9c8e ) && isdefined( level.var_c3cbabc25cac9c8e.var_889528aa38fdcbf2 ) )
        level.ra_ga_price = level.var_c3cbabc25cac9c8e.var_889528aa38fdcbf2;
    nengine_store_set( "rex_arena", "golden_armor", level.ra_ga_was + ", " + level.ra_ga_text + ", Golden Armor price " + level.ra_ga_price );
    // 0.5.77: a gold outline (user: "the outline is not golden"). The game's
    // own Golden Armor mode (script_7f0ced39b52ff8a4, function_6ad7881b32deb49c)
    // sets every armor wall buy's rarity part to its top state; the wall buy
    // system uses the same state for its top rarity (script_7df061afe12b8318,
    // function_ef135a26415497af). Set again if anything changes it.
    // 0.5.78: gold only from armor Level III (user: "the outline color should
    // be on the third tier of armor not the first"). Before it, the state the
    // game gives Rex's one-wall-buy armor wall buys when made
    // (script_2bebb4f5a2ed42a0, function_c779ad1e87a6ccba), whose outline went
    // with the armor level (green, then purple). One part for the whole wall
    // buy: gold when every player has Level III or Golden Armor.
    // 0.5.79: function_67c8eb8480801905 says whether the part has a state
    // (the game checks it before setting one), not whether it is in it; 0.5.78
    // read it as the second and so never set the outline (user: "still not
    // gold"). Now it is set when the Level III state changes.
    level.ra_ga_made = ( wb function_67c8eb8480801905( "wallbuy", "universal" ) ? "has the game's state" : "has not the game's state" ) + ", " + ( wb function_67c8eb8480801905( "wallbuy", "orange" ) ? "has gold" : "has not gold" );
    level.ra_ga_gold = -1;
    level.ra_ga_changes = 0;
    nengine_store_set( "rex_arena", "golden_armor_outline", level.ra_ga_made );
    nengine_store_save( "rex_arena", "runtime" );
    level.ra_ga_last = "";
    level.ra_ga_tick = 0;
    while ( true )
    {
        wait 0.25;
        if ( !isdefined( wb ) )
            return;
        level.ra_ga_all3 = 0;
        if ( isdefined( level.players ) && level.players.size > 0 )
        {
            level.ra_ga_all3 = 1;
            level.ra_ga_i = 0;
            while ( level.ra_ga_i < level.players.size )
            {
                if ( isdefined( level.players[ level.ra_ga_i ] ) && !istrue( level.players[ level.ra_ga_i ].var_a1faa64d8c07872e ) && !( isdefined( level.players[ level.ra_ga_i ].var_da4a8128a869b164 ) && level.players[ level.ra_ga_i ].var_da4a8128a869b164 >= 3 ) )
                    level.ra_ga_all3 = 0;
                level.ra_ga_i++;
            }
        }
        if ( level.ra_ga_all3 != level.ra_ga_gold )
        {
            if ( level.ra_ga_all3 )
            {
                if ( wb function_67c8eb8480801905( "wallbuy", "orange" ) )
                    wb setscriptablepartstate( "wallbuy", "orange" );
            }
            else if ( level.ra_ga_gold == 1 && wb function_67c8eb8480801905( "wallbuy", "universal" ) )
                wb setscriptablepartstate( "wallbuy", "universal" );
            level.ra_ga_gold = level.ra_ga_all3;
            level.ra_ga_changes++;
            nengine_store_set( "rex_arena", "golden_armor_outline", level.ra_ga_made + "; now " + ( level.ra_ga_all3 ? "gold (all players Level III)" : "the game's outline (not all players Level III)" ) + ", changes " + level.ra_ga_changes );
            nengine_store_save( "rex_arena", "runtime" );
        }
        level.ra_ga_tick++;
        if ( level.ra_ga_tick < 4 )
            continue;
        level.ra_ga_tick = 0;
        level.ra_ga_now = "";
        level.ra_ga_i = 0;
        while ( isdefined( level.players ) && level.ra_ga_i < level.players.size )
        {
            if ( isdefined( level.players[ level.ra_ga_i ] ) )
            {
                level.ra_ga_lv = "none";
                if ( isdefined( level.players[ level.ra_ga_i ].var_da4a8128a869b164 ) )
                    level.ra_ga_lv = level.players[ level.ra_ga_i ].var_da4a8128a869b164;
                level.ra_ga_now = level.ra_ga_now + "player " + level.ra_ga_i + ": armor level " + level.ra_ga_lv + ( istrue( level.players[ level.ra_ga_i ].var_a1faa64d8c07872e ) ? ", golden" : "" ) + "; ";
            }
            level.ra_ga_i++;
        }
        if ( level.ra_ga_now != level.ra_ga_last )
        {
            level.ra_ga_last = level.ra_ga_now;
            nengine_store_set( "rex_arena", "golden_armor_players", level.ra_ga_now );
            nengine_store_save( "rex_arena", "runtime" );
        }
    }
}

// 0.5.41: round-select pedestals near the landing spot (user: "i want to add a
// thing in the map that when u interact with it u can choose the round to go
// to like 50 75 100 255 500 999"). Six of Rex's mask pedestals
// (sat_zm_ncfd_pedestal, which the map places for its Easter egg) on the six
// places the user logged (0.5.43: the east section, two groups of three),
// facing the way the user looked, on the floor found by a trace; one per boss
// round (the mod's own settings); south to north 50, 75, 100, 999, 500, 255
// (0.5.44). The game's
// prompts take only localized strings, so a player within 60 units of one
// sees its round in the mod's note; Use there while no boss of this mod is
// alive picks it (ra_round_select_pick). Records round_select and
// round_select_used.
function ra_round_select()
{
    level endon( #"game_ended" );
    level.ra_rs_round = [];
    level.ra_rs_round[ 0 ] = level.ra_zrex_round;
    level.ra_rs_round[ 1 ] = level.ra_guardian_round;
    level.ra_rs_round[ 2 ] = level.ra_both_round;
    level.ra_rs_round[ 3 ] = level.ra_caltheris_round;
    level.ra_rs_round[ 4 ] = level.ra_trio_round;
    level.ra_rs_round[ 5 ] = level.ra_quad_round;
    level.ra_rs_name = [];
    level.ra_rs_name[ 0 ] = "Z-Rex";
    level.ra_rs_name[ 1 ] = "The Guardian";
    level.ra_rs_name[ 2 ] = "Z-Rex and the Guardian";
    level.ra_rs_name[ 3 ] = "Caltheris";
    level.ra_rs_name[ 4 ] = "Z-Rex, the Guardian and Caltheris";
    level.ra_rs_name[ 5 ] = "Z-Rex, the Guardian, Caltheris and the Warden";
    // 0.5.45: each pedestal's toys (Rex's super Easter egg figures), in fight
    // order, and their size
    level.ra_rs_toys = [];
    level.ra_rs_toys[ 0 ] = [ "sat_zm_phobos_tiny" ];
    level.ra_rs_toys[ 1 ] = [ "sat_zm_triton_gtoy" ];
    level.ra_rs_toys[ 2 ] = [ "sat_zm_phobos_tiny", "sat_zm_triton_gtoy" ];
    level.ra_rs_toys[ 3 ] = [ "sat_zm_neptune_1_tiny" ];
    // 0.5.66: Caltheris and the Guardian swapped (user: "swap the position of
    // hte guardian and caltheris")
    level.ra_rs_toys[ 4 ] = [ "sat_zm_phobos_tiny", "sat_zm_neptune_1_tiny", "sat_zm_triton_gtoy" ];
    level.ra_rs_toys[ 5 ] = [ "sat_zm_phobos_tiny", "sat_zm_triton_gtoy", "sat_zm_neptune_1_tiny", "sat_zm_npc_obsidian_tiny" ];
    level.ra_rs_toy_scale = [];
    // 0.5.46: bigger (user: "zrex should be a lot bigger, same for the
    // guardian, same for round 100, same for caltheris, ever so slightly
    // bigger for round 500")
    // 0.5.49: the scale did not show before 0.5.49 (the user saw every toy at
    // 1); sizes from that and the user's asks: Z-Rex "10x larger", the Guardian
    // "3 times larger", 100 and Caltheris "a lot bigger", 500 "ever so slightly
    // bigger", 999 as seen
    // 0.5.50: as tall as the Guardian at 3 (user: "make rex as big as the
    // guardian"): 12.2 x 3 / 9.9
    level.ra_rs_toy_scale[ 0 ] = 3.7;
    level.ra_rs_toy_scale[ 1 ] = 3;
    // 0.5.63: bigger (user: "these 2 should be bigger"); its Z-Rex 3.2 to
    // be as tall (ra_toy_scale_at)
    level.ra_rs_toy_scale[ 2 ] = 2.6;
    // 0.5.65: as tall as round 100's toys (user: "make caltheris as big as
    // the round 100 one"): 31.7 / 9.5
    level.ra_rs_toy_scale[ 3 ] = 3.3;
    // 0.5.66: as big as rounds 100 and 255 (user: "make them bigger"): the
    // Guardian 2.6, the Z-Rex 3.2 and Caltheris 3.3 (ra_toy_scale_at)
    // 0.5.67: about 80% of that, all about 24.5 tall (user, asked: "About 25
    // tall"): the Guardian 2, the Z-Rex 2.5, Caltheris 2.6
    level.ra_rs_toy_scale[ 4 ] = 2;
    // 0.5.68: about 20 tall in two rows (user: "and bigger too", asked:
    // "About 20 tall"): the Guardian and the Warden 1.65, the Z-Rex 2,
    // Caltheris 2.1 (ra_toy_scale_at)
    level.ra_rs_toy_scale[ 5 ] = 1.65;
    // 0.5.47: a pedestal's toys turned from its facing (degrees)
    level.ra_rs_toy_turn = [];
    // 0.5.48: another 45 (user: "rotate him another 45 degree")
    level.ra_rs_toy_turn[ 0 ] = 90;
    level.ra_rs_toy_turn[ 1 ] = 0;
    level.ra_rs_toy_turn[ 2 ] = 0;
    level.ra_rs_toy_turn[ 3 ] = 0;
    level.ra_rs_toy_turn[ 4 ] = 0;
    level.ra_rs_toy_turn[ 5 ] = 0;
    level.ra_rs_toy_m = [];
    level.ra_rs_toy_text = "";
    // 0.5.51: each toy's pedestal, and whether a pedestal's toys have risen
    level.ra_rs_toy_k = [];
    level.ra_rs_up = [];
    level.ra_rs_up[ 0 ] = 0;
    level.ra_rs_up[ 1 ] = 0;
    level.ra_rs_up[ 2 ] = 0;
    level.ra_rs_up[ 3 ] = 0;
    level.ra_rs_up[ 4 ] = 0;
    level.ra_rs_up[ 5 ] = 0;
    level.ra_rs_up_text = "";
    // 0.5.53: Rex toy scriptables made
    level.ra_rs_glow_n = 0;
    level.ra_rs_glow_on = 0;
    // 0.5.54: the players' copies made (round_select_copies)
    level.ra_rs_copy_text = "";
    // 0.5.57: the big toys' glow points, and the Rex glows made on them
    level.ra_rs_gp_n = 0;
    level.ra_rs_gl_n = 0;
    // 1.1.3: and freed (ra_toy_glow_free)
    level.ra_rs_gl_off = 0;
    // 1.1.4: and freed for players who left (ra_toy_glow_near)
    level.ra_gn_left = 0;
    level.ra_rs_m = [];
    level.ra_rs_where = "";
    // 0.5.43: the places in DellxCell's dev position log (p1..p6), as the user
    // stood there, and the way the user looked
    level.ra_rs_spot = [];
    level.ra_rs_yaw = [];
    level.ra_rs_spot[ 0 ] = ( 31681.0, -27975.5, 2256.7 );
    level.ra_rs_yaw[ 0 ] = 177.3;
    level.ra_rs_spot[ 1 ] = ( 31680.9, -27825.1, 2257.5 );
    level.ra_rs_yaw[ 1 ] = 178.4;
    // 0.5.81: Z-Rex and the Guardian (now round 255) on p6, Caltheris (now
    // round 100) on p3 (user: "swap caltheris podium for z rex and the
    // guadian podium")
    level.ra_rs_spot[ 3 ] = ( 31681.0, -27667.1, 2256.0 );
    level.ra_rs_yaw[ 3 ] = -179.8;
    // 0.5.44: round 255 on p6, round 999 on p4 (user: "swap the places of 255
    // and 999")
    level.ra_rs_spot[ 2 ] = ( 31673.0, -26787.4, 2255.6 );
    level.ra_rs_yaw[ 2 ] = -178.3;
    level.ra_rs_spot[ 4 ] = ( 31673.0, -26990.6, 2252.0 );
    level.ra_rs_yaw[ 4 ] = 179.2;
    level.ra_rs_spot[ 5 ] = ( 31673.0, -27202.3, 2252.0 );
    level.ra_rs_yaw[ 5 ] = -178.2;
    level.ra_rs_i = 0;
    while ( level.ra_rs_i < 6 )
    {
        level.ra_rs_p = level.ra_rs_spot[ level.ra_rs_i ];
        level.ra_rs_floor = physicstrace( level.ra_rs_p + ( 0, 0, 300 ), level.ra_rs_p - ( 0, 0, 400 ) );
        if ( isdefined( level.ra_rs_floor ) && level.ra_rs_floor[ 2 ] > level.ra_rs_p[ 2 ] - 399 && level.ra_rs_floor[ 2 ] < level.ra_rs_p[ 2 ] + 150 )
            level.ra_rs_p = ( level.ra_rs_p[ 0 ], level.ra_rs_p[ 1 ], level.ra_rs_floor[ 2 ] );
        level.ra_rs_m[ level.ra_rs_i ] = spawn( "script_model", level.ra_rs_p );
        if ( isdefined( level.ra_rs_m[ level.ra_rs_i ] ) )
        {
            level.ra_rs_m[ level.ra_rs_i ] setmodel( "sat_zm_ncfd_pedestal" );
            level.ra_rs_m[ level.ra_rs_i ].angles = ( 0, level.ra_rs_yaw[ level.ra_rs_i ], 0 );
            ra_round_select_toys( level.ra_rs_i );
            level.ra_rs_where = level.ra_rs_where + " " + level.ra_rs_round[ level.ra_rs_i ] + " at " + level.ra_rs_p;
        }
        else
            level.ra_rs_where = level.ra_rs_where + " " + level.ra_rs_round[ level.ra_rs_i ] + " not made";
        level.ra_rs_i++;
    }
    // 0.5.69: their collision (ra_round_select_col)
    level thread ra_round_select_col();
    nengine_store_set( "rex_arena", "round_select", "pedestals (round, place):" + level.ra_rs_where );
    nengine_store_set( "rex_arena", "round_select_toys", level.ra_rs_toy_m.size + " toys:" + level.ra_rs_toy_text + "; glow points " + level.ra_rs_gp_n );
    nengine_store_save( "rex_arena", "runtime" );
    while ( true )
    {
        wait 0.1;
        ra_round_select_pass();
    }
}

// 0.5.70: collision for the pedestals (user: "now we need to add some
// collision to the pedestals"). 0.5.69's (the pedestal model made solid; hidden
// t10_zm_gameplay_collision_01 blocks) did not block ("i can walk through").
// What has blocked players in this mod is a copy of a map brush (the Mystery
// Box, the exfil): Rex's brushes are measured (ra_ped_donors) and those that fit
// a pedestal are tried, fewest copies first, on the first pedestal; one is kept
// when player-shaped probes that ran clear before now stop (ra_ped_ok), then
// copied into the others. 0.5.71: no fallback (0.5.70's PHD Flopper machine
// showed: hide does not hide a scriptable). Records round_select_brushes,
// round_select_col.
function ra_round_select_col()
{
    level endon( #"game_ended" );
    waitframe();
    level.ra_pc_first = -1;
    level.ra_pc_i = 0;
    while ( level.ra_pc_i < level.ra_rs_m.size )
    {
        level.ra_pc_m = level.ra_rs_m[ level.ra_pc_i ];
        if ( isdefined( level.ra_pc_m ) )
        {
            ra_ped_pprobe( level.ra_pc_m );
            level.ra_pc_m.ra_pq_before = level.ra_pq_v;
            level.ra_pc_m.ra_pq_tb = level.ra_pq_t;
            if ( level.ra_pc_first < 0 )
                level.ra_pc_first = level.ra_pc_i;
        }
        level.ra_pc_i++;
    }
    if ( level.ra_pc_first < 0 )
    {
        level.ra_pc_done = 1;
        return;
    }
    ra_ped_donors();
    level.ra_pc_ok = -1;
    level.ra_pc_try = "";
    level.ra_pc_t = 0;
    level.ra_pc_m = level.ra_rs_m[ level.ra_pc_first ];
    while ( level.ra_pc_t < 6 && level.ra_pc_ok < 0 )
    {
        level.ra_pc_d = ra_ped_donor_next();
        if ( level.ra_pc_d < 0 )
            break;
        level.ra_pc_m.ra_pc_cl = ra_ped_brush_place( level.ra_pc_m, level.ra_pc_d );
        waitframe();
        ra_ped_pprobe( level.ra_pc_m );
        level.ra_pc_good = ra_ped_ok( level.ra_pc_m );
        level.ra_pc_try = level.ra_pc_try + " try " + ( level.ra_pc_t + 1 ) + ": " + level.ra_pd_name[ level.ra_pc_d ] + " " + level.ra_pd_size[ level.ra_pc_d ] + " turned " + level.ra_pd_turn[ level.ra_pc_d ] + ", " + level.ra_pc_m.ra_pc_cl.size + " copies (" + level.ra_pq_t + ": " + level.ra_po_text + ")";
        if ( level.ra_pc_good )
            level.ra_pc_ok = level.ra_pc_d;
        else
            ra_ped_delete( level.ra_pc_m.ra_pc_cl );
        level.ra_pc_t++;
    }
    level.ra_pc_text = "";
    if ( level.ra_pc_ok >= 0 )
    {
        level.ra_pc_i = 0;
        while ( level.ra_pc_i < level.ra_rs_m.size )
        {
            level.ra_pc_m = level.ra_rs_m[ level.ra_pc_i ];
            if ( isdefined( level.ra_pc_m ) && level.ra_pc_i != level.ra_pc_first )
                level.ra_pc_m.ra_pc_cl = ra_ped_brush_place( level.ra_pc_m, level.ra_pc_ok );
            level.ra_pc_i++;
        }
        waitframe();
        level.ra_pc_i = 0;
        while ( level.ra_pc_i < level.ra_rs_m.size )
        {
            level.ra_pc_m = level.ra_rs_m[ level.ra_pc_i ];
            if ( isdefined( level.ra_pc_m ) )
            {
                ra_ped_pprobe( level.ra_pc_m );
                ra_ped_ok( level.ra_pc_m );
                level.ra_pc_text = level.ra_pc_text + " " + level.ra_rs_round[ level.ra_pc_i ] + ": " + level.ra_pc_m.ra_pc_cl.size + " copies (" + level.ra_pc_m.ra_pq_tb + " / " + level.ra_pq_t + ": " + level.ra_po_text + ")";
            }
            level.ra_pc_i++;
        }
        nengine_store_set( "rex_arena", "round_select_col", "pedestal collision: " + level.ra_pd_name[ level.ra_pc_ok ] + " " + level.ra_pd_size[ level.ra_pc_ok ] + " (player probes from 40 out before / after; a stop is under 35):" + level.ra_pc_text + ";" + level.ra_pc_try );
    }
    else
    {
        // 0.5.71: no PHD Flopper test (user: "i wanted the collision not the
        // machine")
        nengine_store_set( "rex_arena", "round_select_col", "pedestal collision: no brush worked;" + level.ra_pc_try );
    }
    level.ra_pc_m = undefined;
    // 0.5.92: done with the brush list (ra_void_claw_col waits for this)
    level.ra_pc_done = 1;
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.70: player-shaped probes of a pedestal: playerphysicstrace (the player's
// own collision) from 40 out, 6 up, towards its centre from its front, back
// and both sides. level.ra_pq_v holds the distances moved, level.ra_pq_t them
// as text.
function ra_ped_pprobe( m )
{
    level.ra_pq_f = anglestoforward( m.angles );
    level.ra_pq_r = anglestoforward( m.angles + ( 0, 90, 0 ) );
    level.ra_pq_c = m.origin + ( 0, 0, 6 );
    level.ra_pq_v = [];
    level.ra_pq_t = "";
    level.ra_pq_k = 0;
    while ( level.ra_pq_k < 4 )
    {
        if ( level.ra_pq_k == 0 )
            level.ra_pq_d = level.ra_pq_f;
        else if ( level.ra_pq_k == 1 )
            level.ra_pq_d = level.ra_pq_f * -1;
        else if ( level.ra_pq_k == 2 )
            level.ra_pq_d = level.ra_pq_r;
        else
            level.ra_pq_d = level.ra_pq_r * -1;
        level.ra_pq_s = level.ra_pq_c + level.ra_pq_d * 40;
        level.ra_pq_e = playerphysicstrace( level.ra_pq_s, level.ra_pq_c );
        level.ra_pq_v[ level.ra_pq_k ] = distance( level.ra_pq_s, level.ra_pq_e );
        level.ra_pq_t = level.ra_pq_t + int( level.ra_pq_v[ level.ra_pq_k ] * 10 ) / 10 + ( level.ra_pq_k < 3 ? " " : "" );
        level.ra_pq_k++;
    }
}

// 0.5.70: whether a pedestal now blocks: of its probes that ran clear before
// (>= 39), at least 2 and all but one now stop (< 35). level.ra_po_text says how
// many.
function ra_ped_ok( m )
{
    level.ra_po_clear = 0;
    level.ra_po_hit = 0;
    level.ra_po_k = 0;
    while ( level.ra_po_k < 4 )
    {
        if ( m.ra_pq_before[ level.ra_po_k ] >= 39 )
        {
            level.ra_po_clear++;
            if ( level.ra_pq_v[ level.ra_po_k ] < 35 )
                level.ra_po_hit++;
        }
        level.ra_po_k++;
    }
    level.ra_po_text = level.ra_po_hit + " of " + level.ra_po_clear + " stopped";
    if ( level.ra_po_clear >= 2 && level.ra_po_hit >= 2 && level.ra_po_hit >= level.ra_po_clear - 1 )
        return 1;
    return 0;
}

// 0.5.70: Rex's brushes measured: every script_brushmodel but the skipped
// names (ra_ped_donor_skip), unrotated; its size along the world axes
// (getpointinbounds) and its copies for a pedestal (ra_ped_copies), turned with
// it or 90 more. Records round_select_brushes.
function ra_ped_donors()
{
    level.ra_pd_e = [];
    level.ra_pd_half = [];
    level.ra_pd_off = [];
    level.ra_pd_turn = [];
    level.ra_pd_n = [];
    level.ra_pd_dd = [];
    level.ra_pd_dw = [];
    level.ra_pd_dh = [];
    level.ra_pd_area = [];
    level.ra_pd_name = [];
    level.ra_pd_size = [];
    level.ra_pd_used = [];
    level.ra_pd_fit = 0;
    level.ra_pd_fits = "";
    level.ra_pd_near = "";
    level.ra_pd_all = getentarray( "script_brushmodel", "classname" );
    level.ra_pd_i = 0;
    while ( level.ra_pd_i < level.ra_pd_all.size )
    {
        level.ra_pd_b = level.ra_pd_all[ level.ra_pd_i ];
        level.ra_pd_i++;
        if ( !isdefined( level.ra_pd_b ) || !isdefined( level.ra_pd_b.origin ) )
            continue;
        level.ra_pd_tn = "-";
        if ( isdefined( level.ra_pd_b.targetname ) )
            level.ra_pd_tn = level.ra_pd_b.targetname;
        if ( ra_ped_donor_skip( level.ra_pd_tn ) )
            continue;
        if ( isdefined( level.ra_pd_b.angles ) && ( level.ra_pd_b.angles[ 0 ] != 0 || level.ra_pd_b.angles[ 1 ] != 0 || level.ra_pd_b.angles[ 2 ] != 0 ) )
            continue;
        level.ra_pd_mid = level.ra_pd_b getpointinbounds( 0, 0, 0 );
        level.ra_pd_hv = level.ra_pd_b getpointinbounds( 1, 1, 1 ) - level.ra_pd_mid;
        level.ra_pd_hv = ( abs( level.ra_pd_hv[ 0 ] ), abs( level.ra_pd_hv[ 1 ] ), abs( level.ra_pd_hv[ 2 ] ) );
        if ( level.ra_pd_hv[ 0 ] < 1 || level.ra_pd_hv[ 1 ] < 1 || level.ra_pd_hv[ 2 ] < 1 )
            continue;
        level.ra_pd_c0 = ra_ped_copies( level.ra_pd_hv[ 0 ] * 2, level.ra_pd_hv[ 1 ] * 2, level.ra_pd_hv[ 2 ] * 2 );
        level.ra_pd_c90 = ra_ped_copies( level.ra_pd_hv[ 1 ] * 2, level.ra_pd_hv[ 0 ] * 2, level.ra_pd_hv[ 2 ] * 2 );
        level.ra_pd_k = level.ra_pd_e.size;
        level.ra_pd_e[ level.ra_pd_k ] = level.ra_pd_b;
        level.ra_pd_half[ level.ra_pd_k ] = level.ra_pd_hv;
        level.ra_pd_off[ level.ra_pd_k ] = level.ra_pd_mid - level.ra_pd_b.origin;
        level.ra_pd_name[ level.ra_pd_k ] = level.ra_pd_tn;
        level.ra_pd_size[ level.ra_pd_k ] = int( level.ra_pd_hv[ 0 ] * 2 ) + "x" + int( level.ra_pd_hv[ 1 ] * 2 ) + "x" + int( level.ra_pd_hv[ 2 ] * 2 );
        level.ra_pd_used[ level.ra_pd_k ] = 0;
        if ( level.ra_pd_c0 > 0 && ( level.ra_pd_c90 <= 0 || level.ra_pd_c0 <= level.ra_pd_c90 ) )
        {
            level.ra_pd_turn[ level.ra_pd_k ] = 0;
            level.ra_pd_n[ level.ra_pd_k ] = level.ra_pd_c0;
            level.ra_pd_dd[ level.ra_pd_k ] = level.ra_pd_hv[ 0 ] * 2;
            level.ra_pd_dw[ level.ra_pd_k ] = level.ra_pd_hv[ 1 ] * 2;
        }
        else
        {
            level.ra_pd_turn[ level.ra_pd_k ] = 90;
            level.ra_pd_n[ level.ra_pd_k ] = level.ra_pd_c90;
            level.ra_pd_dd[ level.ra_pd_k ] = level.ra_pd_hv[ 1 ] * 2;
            level.ra_pd_dw[ level.ra_pd_k ] = level.ra_pd_hv[ 0 ] * 2;
        }
        level.ra_pd_dh[ level.ra_pd_k ] = level.ra_pd_hv[ 2 ] * 2;
        level.ra_pd_area[ level.ra_pd_k ] = level.ra_pd_dd[ level.ra_pd_k ] * level.ra_pd_dw[ level.ra_pd_k ];
        if ( level.ra_pd_n[ level.ra_pd_k ] > 0 )
        {
            level.ra_pd_fit++;
            level.ra_pd_fits = level.ra_pd_fits + " " + level.ra_pd_tn + " " + level.ra_pd_size[ level.ra_pd_k ] + " x" + level.ra_pd_n[ level.ra_pd_k ];
        }
        else if ( level.ra_pd_hv[ 0 ] <= 20 || level.ra_pd_hv[ 1 ] <= 20 )
            level.ra_pd_near = level.ra_pd_near + " " + level.ra_pd_tn + " " + level.ra_pd_size[ level.ra_pd_k ];
    }
    level.ra_pd_b = undefined;
    nengine_store_set( "rex_arena", "round_select_brushes", level.ra_pd_all.size + " script_brushmodels, " + level.ra_pd_e.size + " measured, " + level.ra_pd_fit + " fit a pedestal (name, size x y z, copies):" + level.ra_pd_fits + "; not fitting, 40 or less across one way:" + level.ra_pd_near );
}

// 0.5.70: brushes not tried: titan, slick and slip clips, cinematic, vehicle,
// portal and navigation brushes, the boss arena's edge.
function ra_ped_donor_skip( tn )
{
    level.ra_ps_names = [ "titan_clip_a", "titan_clip_b", "m_pltfm_slickclip", "m_pltfm_slickclip_btm", "movplat_rh_slipclip", "boss_arena_edge_player_clip", "cals_srm_ent", "heli_pilot_mesh", "hermes_script_brushmodel", "hermes_vehicle_script_brushmodel", "nexus_ring_1_link", "nexus_ring_2_link", "nexus_ring_3_link", "portal_brush", "pq_forge_platform_ai_nav", "pq_forge_platform_ai_obstacle", "sbm_igc_outro_all_shots", "sbm_igc_weyward_intro_vig", "sbm_igc_weyward_plr_dth_vig", "sideroom_navmesh_plug", "um_vi_ra" ];
    level.ra_ps_i = 0;
    while ( level.ra_ps_i < level.ra_ps_names.size )
    {
        if ( level.ra_ps_names[ level.ra_ps_i ] == tn )
            return 1;
        level.ra_ps_i++;
    }
    return 0;
}

// 0.5.70: copies of a brush dd deep, dw wide and dh high to fill a pedestal's
// 15 x 27 x 34.4 outline (its top slab extruded down): 0 if it is more than
// 16.5 deep or 28.5 wide, or needs more than 24; one taller than 34.4 sinks.
function ra_ped_copies( dd, dw, dh )
{
    // 0.5.71: up to the base's 26 deep (Rex's cubes about 25 across)
    if ( dd > 27 || dw > 28.5 || dd < 2 || dw < 2 || dh < 2 )
        return 0;
    level.ra_pk_h = 1;
    if ( dh < 34.4 )
        level.ra_pk_h = ra_ped_count( 34.4, dh );
    level.ra_pk_n = ra_ped_count( 15, dd ) * ra_ped_count( 27, dw ) * level.ra_pk_h;
    if ( level.ra_pk_n > 24 )
        return 0;
    return level.ra_pk_n;
}

// 0.5.70: copies of length d to span size (1 if it is as long).
function ra_ped_count( size, d )
{
    if ( d >= size )
        return 1;
    level.ra_pk_c = int( size / d );
    if ( level.ra_pk_c * d < size )
        level.ra_pk_c++;
    return level.ra_pk_c;
}

// 0.5.70: the next fitting brush to try: fewest copies, then the biggest
// footprint; -1 when none is left. 0.5.71: then the smallest footprint (least
// past the pedestal).
function ra_ped_donor_next()
{
    level.ra_pn_best = -1;
    level.ra_pn_i = 0;
    while ( level.ra_pn_i < level.ra_pd_e.size )
    {
        if ( level.ra_pd_n[ level.ra_pn_i ] > 0 && !level.ra_pd_used[ level.ra_pn_i ] )
        {
            if ( level.ra_pn_best < 0 || level.ra_pd_n[ level.ra_pn_i ] < level.ra_pd_n[ level.ra_pn_best ] || ( level.ra_pd_n[ level.ra_pn_i ] == level.ra_pd_n[ level.ra_pn_best ] && level.ra_pd_area[ level.ra_pn_i ] < level.ra_pd_area[ level.ra_pn_best ] ) )
                level.ra_pn_best = level.ra_pn_i;
        }
        level.ra_pn_i++;
    }
    if ( level.ra_pn_best >= 0 )
        level.ra_pd_used[ level.ra_pn_best ] = 1;
    return level.ra_pn_best;
}

// 0.5.70: brush k copied into pedestal ped, filling its 15 (its forward) x 27
// (its width) outline from the floor to 34.4 (a taller one sunk, its top at
// 34.4), spread edge to edge; solid, disconnectpaths. Returns the copies.
function ra_ped_brush_place( ped, k )
{
    level.ra_pl_made = [];
    level.ra_pl_yaw = ped.angles[ 1 ];
    level.ra_pl_cy = level.ra_pl_yaw + level.ra_pd_turn[ k ];
    level.ra_pl_f = anglestoforward( ( 0, level.ra_pl_yaw, 0 ) );
    level.ra_pl_r = anglestoforward( ( 0, level.ra_pl_yaw + 90, 0 ) );
    level.ra_pl_cf = anglestoforward( ( 0, level.ra_pl_cy, 0 ) );
    level.ra_pl_cl = anglestoforward( ( 0, level.ra_pl_cy + 90, 0 ) );
    level.ra_pl_nd = ra_ped_count( 15, level.ra_pd_dd[ k ] );
    level.ra_pl_nw = ra_ped_count( 27, level.ra_pd_dw[ k ] );
    level.ra_pl_nh = 1;
    if ( level.ra_pd_dh[ k ] < 34.4 )
        level.ra_pl_nh = ra_ped_count( 34.4, level.ra_pd_dh[ k ] );
    level.ra_pl_id = 0;
    while ( level.ra_pl_id < level.ra_pl_nd )
    {
        level.ra_pl_iw = 0;
        while ( level.ra_pl_iw < level.ra_pl_nw )
        {
            level.ra_pl_ih = 0;
            while ( level.ra_pl_ih < level.ra_pl_nh )
            {
                level.ra_pl_ld = ra_ped_axis( 15, level.ra_pd_dd[ k ], level.ra_pl_nd, level.ra_pl_id );
                level.ra_pl_lw = ra_ped_axis( 27, level.ra_pd_dw[ k ], level.ra_pl_nw, level.ra_pl_iw );
                if ( level.ra_pd_dh[ k ] >= 34.4 )
                    level.ra_pl_lz = 34.4 - level.ra_pd_dh[ k ] / 2;
                else
                    level.ra_pl_lz = level.ra_pd_dh[ k ] / 2 + ra_ped_axis( 34.4, level.ra_pd_dh[ k ], level.ra_pl_nh, level.ra_pl_ih ) + ( 34.4 - level.ra_pd_dh[ k ] ) / 2;
                level.ra_pl_c = ped.origin + level.ra_pl_f * level.ra_pl_ld + level.ra_pl_r * level.ra_pl_lw + ( 0, 0, level.ra_pl_lz );
                level.ra_pl_o = level.ra_pl_c - ( level.ra_pl_cf * level.ra_pd_off[ k ][ 0 ] + level.ra_pl_cl * level.ra_pd_off[ k ][ 1 ] + ( 0, 0, level.ra_pd_off[ k ][ 2 ] ) );
                level.ra_pl_m = spawn( "script_model", level.ra_pl_o );
                if ( isdefined( level.ra_pl_m ) )
                {
                    level.ra_pl_m.angles = ( 0, level.ra_pl_cy, 0 );
                    level.ra_pl_m clonebrushmodeltoscriptmodel( level.ra_pd_e[ k ] );
                    level.ra_pl_m solid();
                    level.ra_pl_m disconnectpaths();
                    level.ra_pl_made[ level.ra_pl_made.size ] = level.ra_pl_m;
                }
                level.ra_pl_ih++;
            }
            level.ra_pl_iw++;
        }
        level.ra_pl_id++;
    }
    level.ra_pl_m = undefined;
    return level.ra_pl_made;
}

// 0.5.70: where copy i of n (length d) sits along size, centred on 0: spread
// edge to edge; 0 for one copy or one as long.
function ra_ped_axis( size, d, n, i )
{
    if ( n <= 1 || d >= size )
        return 0;
    return 0 - size / 2 + d / 2 + i * ( size - d ) / ( n - 1 );
}

// 0.5.70: a failed try's copies removed.
function ra_ped_delete( list )
{
    level.ra_px_i = 0;
    while ( isdefined( list ) && level.ra_px_i < list.size )
    {
        if ( isdefined( list[ level.ra_px_i ] ) )
            list[ level.ra_px_i ] delete();
        level.ra_px_i++;
    }
}

// 0.5.45: the toys of pedestal k on its top (34.4 over its origin): side by
// side across its width (its local y, 1.5 apart, centred), the first on the
// left as seen from its front, each centred on the top's depth and turned 90
// degrees from the pedestal (the toys face their -y), so they face the way
// the pedestal faces; scaled with setscale before the model is set (0.5.49,
// as Rex's own scripts do). 0.5.51: each keeps how far it rises and floats
// (ra_toy_rise).
// 0.5.68: pedestal k's toys: one row (ra_round_select_row), but round 999's in
// two (user: "should we make them stacked on top of each other by 2x2 with zrex
// and guardian then warden and caltheris toys"): the Z-Rex and the Guardian
// low, Caltheris and the Warden 24 over them (the low ones about 20 tall, 4
// between), each row's toys' centres either side of the pedestal's centre.
function ra_round_select_toys( k )
{
    if ( k == 5 )
    {
        ra_round_select_row( k, [ "sat_zm_phobos_tiny", "sat_zm_triton_gtoy" ], 0, 1.3 );
        ra_round_select_row( k, [ "sat_zm_neptune_1_tiny", "sat_zm_npc_obsidian_tiny" ], 24, -3.2 );
        return;
    }
    ra_round_select_row( k, level.ra_rs_toys[ k ], 0, ra_toy_shift( k ) );
}

// 0.5.68: one row of pedestal k's toys (list), zup over the others' height,
// moved shift along the pedestal's width (0.5.45-0.5.67 ra_round_select_toys).
function ra_round_select_row( k, list, zup, shift )
{
    level.ra_rt_ped = level.ra_rs_m[ k ];
    level.ra_rt_list = list;
    level.ra_rt_s = level.ra_rs_toy_scale[ k ];
    level.ra_rt_yaw = level.ra_rs_yaw[ k ];
    // 0.5.47: the turn (the centring forward follows it)
    level.ra_rt_turn = level.ra_rs_toy_turn[ k ];
    level.ra_rt_f = anglestoforward( ( 0, level.ra_rt_yaw + level.ra_rt_turn, 0 ) );
    level.ra_rt_r = anglestoforward( ( 0, level.ra_rt_yaw + 90, 0 ) );
    level.ra_rt_w = 0;
    level.ra_rt_i = 0;
    while ( level.ra_rt_i < level.ra_rt_list.size )
    {
        // 0.5.63: each toy's own scale
        level.ra_rt_w = level.ra_rt_w + ra_toy_width( level.ra_rt_list[ level.ra_rt_i ] ) * ra_toy_scale_at( k, level.ra_rt_list[ level.ra_rt_i ] );
        if ( level.ra_rt_i > 0 )
            level.ra_rt_w = level.ra_rt_w + ra_toy_gap( k );
        level.ra_rt_i++;
    }
    // 0.5.64: and the pedestal's shift (ra_toy_shift)
    level.ra_rt_at = -0.5 * level.ra_rt_w + shift;
    level.ra_rt_i = 0;
    while ( level.ra_rt_i < level.ra_rt_list.size )
    {
        level.ra_rt_name = level.ra_rt_list[ level.ra_rt_i ];
        // 0.5.63: this toy's own scale
        level.ra_rt_s = ra_toy_scale_at( k, level.ra_rt_name );
        level.ra_rt_wi = ra_toy_width( level.ra_rt_name ) * level.ra_rt_s;
        level.ra_rt_off = level.ra_rt_at + level.ra_rt_wi * 0.5;
        level.ra_rt_at = level.ra_rt_at + level.ra_rt_wi + ra_toy_gap( k );
        level.ra_rt_dep = ra_toy_depth( level.ra_rt_name ) * level.ra_rt_s;
        level.ra_rt_pos = level.ra_rt_ped.origin + ( level.ra_rt_r[ 0 ] * level.ra_rt_off + level.ra_rt_f[ 0 ] * level.ra_rt_dep, level.ra_rt_r[ 1 ] * level.ra_rt_off + level.ra_rt_f[ 1 ] * level.ra_rt_dep, 34.6 + zup );
        level.ra_rt_m = spawn( "script_model", level.ra_rt_pos );
        if ( isdefined( level.ra_rt_m ) )
        {
            // 0.5.49: the scale before the model, as Rex's own scripts do (set
            // after the model, then the same model again, it did not show)
            level.ra_rt_m setscale( level.ra_rt_s );
            level.ra_rt_m setmodel( level.ra_rt_name );
            level.ra_rt_m.angles = ( 0, level.ra_rt_yaw + 90 + level.ra_rt_turn, 0 );
            // 0.5.51: Rex's box raises its toys 19, the middle of three 10 more;
            // they float 1.5 at the toy's own size
            // 0.5.52: 6 (the middle of three 9) and at most 3 (user: "the
            // toys are too high")
            level.ra_rt_m.ra_up = 6;
            if ( level.ra_rt_list.size == 3 && level.ra_rt_i == 1 )
                level.ra_rt_m.ra_up = 9;
            level.ra_rt_m.ra_bob = 1.5 * level.ra_rt_s;
            if ( level.ra_rt_m.ra_bob > 3 )
                level.ra_rt_m.ra_bob = 3;
            // 0.5.56: the toy's model name, scale and shroud anchors
            level.ra_rt_m.ra_name = level.ra_rt_name;
            level.ra_rt_m.ra_s = level.ra_rt_s;
            if ( level.ra_rt_s <= 1.1 )
            {
                // 0.5.52: a tag_origin mover. 0.5.53: Rex's own toy scriptable on
                // it (a glow played by script does not show). 0.5.54: one copy
                // for each player (ra_toy_copies), as Rex makes these toys; here
                // its name and the copies. 0.5.56: only the toys at about their
                // own size (rounds 500 and 999; a scriptable cannot be scaled),
                // the mover on the toy's origin.
                level.ra_rt_m.ra_glow = spawn( "script_model", level.ra_rt_pos );
                if ( isdefined( level.ra_rt_m.ra_glow ) )
                {
                    level.ra_rt_m.ra_glow setmodel( "tag_origin" );
                    level.ra_rt_m.ra_glow.angles = level.ra_rt_m.angles;
                    level.ra_rt_m.ra_sc_name = ra_toy_scriptable( level.ra_rt_name );
                    level.ra_rt_m.ra_sc = [];
                }
            }
            else
            {
                // 0.5.57: a big toy: Rex's toy glow at points over its body
                // (ra_toy_glow_make), made once it has risen; it bobs 1.5
                // (Rex's own amount), as those glows stay where they are made
                level.ra_rt_m.ra_sc_name = ra_toy_scriptable( level.ra_rt_name );
                level.ra_rt_m.ra_gpts = ra_toy_glow_pts( level.ra_rt_name, level.ra_rt_s );
                level.ra_rt_m.ra_gsc = [];
                level.ra_rt_m.ra_bob = 1.5;
                level.ra_rs_gp_n = level.ra_rs_gp_n + level.ra_rt_m.ra_gpts.size;
            }
            level.ra_rs_toy_k[ level.ra_rs_toy_m.size ] = k;
            level.ra_rs_toy_m[ level.ra_rs_toy_m.size ] = level.ra_rt_m;
            level.ra_rs_toy_text = level.ra_rs_toy_text + " " + level.ra_rs_round[ k ] + ": " + level.ra_rt_name + " x" + level.ra_rt_s;
        }
        else
            level.ra_rs_toy_text = level.ra_rs_toy_text + " " + level.ra_rs_round[ k ] + ": " + level.ra_rt_name + " not made";
        level.ra_rt_i++;
    }
    level.ra_rt_m = undefined;
    level.ra_rt_ped = undefined;
}

// 0.5.54: a player's copies of the Rex toys. Rex makes these toy scriptables
// one per player: its shelf (script_53d8a642c173e600) and the game's own
// scriptable spawns (script_2b867a98ca762b0a) pass a fifth argument,
// [ #"hash_5f9c433bdcfb4e14", the player's entity number ]; 0.5.53 made them
// without it and none showed (the user: round 999's pedestal empty). Once per
// player, late joiners too. At its own size the copy is the toy and ours is
// hidden once a copy is made; else only its glow (base off). A copy made after
// its toy rose starts glowing. Records round_select_copies.
// 0.5.55: a scaled toy's copy is on the toy with its model and is scaled to
// the toy's size (ra_toy_copy_scale). 0.5.56: that did not scale it; only the
// toys at about their own size (rounds 500 and 999) have copies, on their
// mover with their model; at round 500 inside our slightly bigger toy.
function ra_toy_copies()
{
    self.ra_toy_copied = 1;
    level.ra_tc_n = 0;
    level.ra_tc_i = 0;
    while ( level.ra_tc_i < level.ra_rs_toy_m.size )
    {
        level.ra_tc_m = level.ra_rs_toy_m[ level.ra_tc_i ];
        level.ra_tc_i++;
        // 0.5.57: a big toy already up: this player's glows on it
        // 1.1.3: its glows only near its pedestal (ra_toy_glow_near)
        if ( isdefined( level.ra_tc_m ) && isdefined( level.ra_tc_m.ra_gpts ) )
            continue;
        if ( !isdefined( level.ra_tc_m ) || !isdefined( level.ra_tc_m.ra_glow ) || !isdefined( level.ra_tc_m.ra_sc_name ) )
            continue;
        // 0.5.56: on the mover (the toy's origin) with its model, as at round
        // 999 in 0.5.54-0.5.55; our model hidden only at its own size
        level.ra_tc_sc = spawnscriptable( level.ra_tc_m.ra_sc_name, level.ra_tc_m.ra_glow.origin, level.ra_tc_m.ra_glow.angles, undefined, [ #"hash_5f9c433bdcfb4e14", self getentitynumber() ] );
        if ( !isdefined( level.ra_tc_sc ) )
            continue;
        if ( level.ra_tc_m.ra_s == 1 )
            level.ra_tc_m hide();
        level.ra_tc_sc function_2e5e844f5f8173bc( level.ra_tc_m.ra_glow );
        if ( istrue( level.ra_tc_m.ra_risen ) )
        {
            level.ra_tc_sc setscriptablepartstate( "glow", "on" );
            level.ra_rs_glow_on++;
        }
        level.ra_tc_m.ra_sc[ level.ra_tc_m.ra_sc.size ] = level.ra_tc_sc;
        level.ra_tc_n++;
        level.ra_rs_glow_n++;
    }
    level.ra_tc_m = undefined;
    level.ra_tc_sc = undefined;
    level.ra_rs_copy_text = level.ra_rs_copy_text + " player " + self getentitynumber() + ": " + level.ra_tc_n + " of " + level.ra_rs_toy_m.size;
    nengine_store_set( "rex_arena", "round_select_copies", "Rex toy copies (player: made of toys):" + level.ra_rs_copy_text );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.57: a big toy (self) up: for player pl, a copy of Rex's toy scriptable
// at each of the toy's glow points (its frame, at its scale; the glow plays 5
// over the scriptable), model off and glow on: Rex's purple, round the toy's
// body. A glow without its model stays where it is turned on (0.5.54), so they
// are made where the toy is once it has risen. Records round_select_glows.
function ra_toy_glow_make( pl )
{
    // 1.1.3: each player's glows apart, so ra_toy_glow_free can free them
    level.ra_tg_e = pl getentitynumber();
    // 1.1.4: the highest entity number with glows (ra_toy_glow_near frees those of players who left)
    if ( !isdefined( level.ra_gn_top ) || level.ra_tg_e > level.ra_gn_top )
        level.ra_gn_top = level.ra_tg_e;
    if ( !isdefined( self.ra_gsp ) )
        self.ra_gsp = [];
    self.ra_gsp[ level.ra_tg_e ] = [];
    level.ra_tg_f = anglestoforward( self.angles );
    level.ra_tg_l = anglestoforward( self.angles + ( 0, 90, 0 ) );
    level.ra_tg_i = 0;
    while ( level.ra_tg_i < self.ra_gpts.size )
    {
        level.ra_tg_v = self.ra_gpts[ level.ra_tg_i ];
        level.ra_tg_i++;
        level.ra_tg_sc = spawnscriptable( self.ra_sc_name, self.origin + level.ra_tg_f * level.ra_tg_v[ 0 ] + level.ra_tg_l * level.ra_tg_v[ 1 ] + ( 0, 0, level.ra_tg_v[ 2 ] - 5 ), self.angles, undefined, [ #"hash_5f9c433bdcfb4e14", pl getentitynumber() ] );
        if ( !isdefined( level.ra_tg_sc ) )
            continue;
        level.ra_tg_sc setscriptablepartstate( "base", "off" );
        level.ra_tg_sc setscriptablepartstate( "glow", "on" );
        self.ra_gsp[ level.ra_tg_e ][ self.ra_gsp[ level.ra_tg_e ].size ] = level.ra_tg_sc;
        level.ra_rs_gl_n++;
    }
    level.ra_tg_sc = undefined;
    nengine_store_set( "rex_arena", "round_select_glows", "Rex glows on the big toys, near their pedestal only: " + ( level.ra_rs_gl_n - level.ra_rs_gl_off ) + " now (made " + level.ra_rs_gl_n + ", freed " + level.ra_rs_gl_off + "; " + level.ra_rs_gp_n + " points a player)" );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.57: a big toy's glow points: k-means centres of its mesh vertices (the
// exported model, game inches), in its frame (x forward, y left, z up), at its
// scale: the Z-Rex's feet, legs, back, tail and head; the Guardian's legs,
// torso, arms and head.
function ra_toy_glow_pts( name, s )
{
    // 0.5.59: three more along the tail's centre line (user: "make zrex tail
    // light more soothly by adding couple more"), about 9 apart to the tip
    // 0.5.60: seven more just inside the surface (user: "more glow on the
    // thigh and back please"): both thighs (upper and knee) and the back
    // 0.5.61: seven more where the user circled ("it should have a bit more
    // here"): the shoulders' top, the head's top, the chest and both arms
    if ( name == "sat_zm_phobos_tiny" && s == 3.7 )
        return [ ( -0.3, -2.4, 3.4 ), ( 1.2, -7.6, 15.7 ), ( -0.3, 21.8, 19.6 ), ( -0.1, -14.5, 24.8 ), ( -0.4, 3.0, 22.7 ), ( -0.1, -31.4, 28.6 ), ( -0.1, 12.5, 20.6 ), ( -0.3, 31.0, 18.8 ), ( -0.2, 38.5, 18.7 ), ( 7, -5, 15 ), ( -7, -5, 15 ), ( 6.5, -4, 9 ), ( -6.5, -4, 9 ), ( 0, -10, 30.5 ), ( 0, -3, 29 ), ( 0, 4.5, 25 ), ( 0, -15, 31 ), ( 0, -21, 31.5 ), ( 0, -27, 33 ), ( 0, -33, 31 ), ( 0, -19, 19 ), ( 4, -17, 15 ), ( -4, -17, 15 ) ];
    // 0.5.62: the Guardians just inside their front outline, both sides,
    // none between the legs (user: "the guardian looks a bit weird")
    if ( name == "sat_zm_triton_gtoy" && s == 3 )
        return [ ( 4.5, 0, 3 ), ( -4.5, 0, 3 ), ( 4.5, -0.5, 9.5 ), ( -4.5, -0.5, 9.5 ), ( 4, -1, 15 ), ( -4, -1, 15 ), ( 11.5, -6, 20 ), ( -11.5, -6, 20 ), ( 10.5, -2, 25 ), ( -10.5, -2, 25 ), ( 7.5, 0, 31 ), ( -7.5, 0, 31 ), ( 0, -1.5, 35.5 ) ];
    // 0.5.63: round 100's bigger toys: the round-50 Z-Rex's points at 3.2 / 3.7
    // and the round-75 Guardian's at 2.6 / 3
    if ( name == "sat_zm_phobos_tiny" && s == 3.2 )
        return [ ( -0.3, -2.1, 2.9 ), ( 1, -6.6, 13.6 ), ( -0.3, 18.9, 17 ), ( -0.1, -12.5, 21.4 ), ( -0.3, 2.6, 19.6 ), ( -0.1, -27.2, 24.7 ), ( -0.1, 10.8, 17.8 ), ( -0.3, 26.8, 16.3 ), ( -0.2, 33.3, 16.2 ), ( 6.1, -4.3, 13 ), ( -6.1, -4.3, 13 ), ( 5.6, -3.5, 7.8 ), ( -5.6, -3.5, 7.8 ), ( 0, -8.6, 26.4 ), ( 0, -2.6, 25.1 ), ( 0, 3.9, 21.6 ), ( 0, -13, 26.8 ), ( 0, -18.2, 27.2 ), ( 0, -23.4, 28.5 ), ( 0, -28.5, 26.8 ), ( 0, -16.4, 16.4 ), ( 3.5, -14.7, 13 ), ( -3.5, -14.7, 13 ) ];
    if ( name == "sat_zm_triton_gtoy" && s == 2.6 )
        return [ ( 3.9, 0, 2.6 ), ( -3.9, 0, 2.6 ), ( 3.9, -0.4, 8.2 ), ( -3.9, -0.4, 8.2 ), ( 3.5, -0.9, 13 ), ( -3.5, -0.9, 13 ), ( 10, -5.2, 17.3 ), ( -10, -5.2, 17.3 ), ( 9.1, -1.7, 21.7 ), ( -9.1, -1.7, 21.7 ), ( 6.5, 0, 26.9 ), ( -6.5, 0, 26.9 ), ( 0, -1.3, 30.8 ) ];
    // 0.5.68: round 999's at about 20 tall: spread subsets of the tuned ones,
    // scaled (the Z-Rex's 3.7 by 2 / 3.7, the Guardian's 3 by 1.65 / 3,
    // Caltheris's 3.3 by 2.1 / 3.3), and the Warden's own
    if ( name == "sat_zm_phobos_tiny" && s == 2 )
        return [ ( -0.2, -1.3, 1.8 ), ( 3.8, -2.7, 8.1 ), ( -3.8, -2.7, 8.1 ), ( 3.5, -2.2, 4.9 ), ( -3.5, -2.2, 4.9 ), ( 0, -5.4, 16.5 ), ( 0, 2.4, 13.5 ), ( 0, -8.1, 16.8 ), ( 0, -14.6, 17.8 ), ( -0.1, -17, 15.5 ), ( 0, -10.3, 10.3 ), ( 2.2, -9.2, 8.1 ), ( -2.2, -9.2, 8.1 ), ( -0.2, 11.8, 10.6 ), ( -0.1, 20.8, 10.1 ) ];
    if ( name == "sat_zm_triton_gtoy" && s == 1.65 )
        return [ ( 2.5, 0, 1.7 ), ( -2.5, 0, 1.7 ), ( 2.2, -0.6, 8.3 ), ( -2.2, -0.6, 8.3 ), ( 6.3, -3.3, 11 ), ( -6.3, -3.3, 11 ), ( 4.1, 0, 17.1 ), ( -4.1, 0, 17.1 ), ( 0, -0.8, 19.5 ) ];
    if ( name == "sat_zm_neptune_1_tiny" && s == 2.1 )
        return [ ( 0.2, 2.4, 5.4 ), ( 8.9, -4.5, 9.9 ), ( -8.9, -4.5, 9.9 ), ( 7, 0.3, 16.5 ), ( -7, 0.3, 16.5 ), ( 5.4, 0.3, 19.7 ), ( -5.4, 0.3, 19.7 ), ( 0, 0.6, 21.9 ) ];
    if ( name == "sat_zm_npc_obsidian_tiny" && s == 1.65 )
        return [ ( 0, 0.5, 3.5 ), ( -2.3, -2.5, 6.5 ), ( 1.6, -2, 7 ), ( 2.6, -1.2, 11 ), ( -2.3, -1.2, 11 ), ( 0, -0.5, 18.5 ) ];
    // 0.5.67: round 500's at about 25 tall: the round-50 Z-Rex's at 2.5 / 3.7,
    // round 255's Caltheris's at 2.6 / 3.3, round 75's Guardian's at 2 / 3
    if ( name == "sat_zm_phobos_tiny" && s == 2.5 )
        return [ ( -0.2, -1.6, 2.3 ), ( 0.8, -5.1, 10.6 ), ( -0.2, 14.7, 13.2 ), ( -0.1, -9.8, 16.8 ), ( -0.3, 2, 15.3 ), ( -0.1, -21.2, 19.3 ), ( -0.1, 8.4, 13.9 ), ( -0.2, 20.9, 12.7 ), ( -0.1, 26, 12.6 ), ( 4.7, -3.4, 10.1 ), ( -4.7, -3.4, 10.1 ), ( 4.4, -2.7, 6.1 ), ( -4.4, -2.7, 6.1 ), ( 0, -6.8, 20.6 ), ( 0, -2, 19.6 ), ( 0, 3, 16.9 ), ( 0, -10.1, 20.9 ), ( 0, -14.2, 21.3 ), ( 0, -18.2, 22.3 ), ( 0, -22.3, 20.9 ), ( 0, -12.8, 12.8 ), ( 2.7, -11.5, 10.1 ), ( -2.7, -11.5, 10.1 ) ];
    if ( name == "sat_zm_neptune_1_tiny" && s == 2.6 )
        return [ ( 0.2, 3, 6.7 ), ( 11, -5.5, 12.2 ), ( -11, -5.5, 12.2 ), ( 9.8, 0, 16.5 ), ( -9.8, 0, 16.5 ), ( 8.7, 0.4, 20.5 ), ( -8.7, 0.4, 20.5 ), ( 6.7, 0.4, 24.4 ), ( -6.7, 0.4, 24.4 ), ( 0, 0.8, 27.2 ) ];
    if ( name == "sat_zm_triton_gtoy" && s == 2 )
        return [ ( 3, 0, 2 ), ( -3, 0, 2 ), ( 3, -0.3, 6.3 ), ( -3, -0.3, 6.3 ), ( 2.7, -0.7, 10 ), ( -2.7, -0.7, 10 ), ( 7.7, -4, 13.3 ), ( -7.7, -4, 13.3 ), ( 7, -1.3, 16.7 ), ( -7, -1.3, 16.7 ), ( 5, 0, 20.7 ), ( -5, 0, 20.7 ), ( 0, -1, 23.7 ) ];
    // 0.5.65: Caltheris at 3.3, just inside its front outline: the stalk, the
    // claws, the arms, the body's sides, the shoulders and the head's top
    if ( name == "sat_zm_neptune_1_tiny" && s == 3.3 )
        return [ ( 0.3, 3.8, 8.5 ), ( 14, -7, 15.5 ), ( -14, -7, 15.5 ), ( 12.5, 0, 21 ), ( -12.5, 0, 21 ), ( 11, 0.5, 26 ), ( -11, 0.5, 26 ), ( 8.5, 0.5, 31 ), ( -8.5, 0.5, 31 ), ( 0, 1, 34.5 ) ];
    return [];
}

// 0.5.64: how far pedestal k's row of toys moves along its width (to the
// last toy's side): round 100's 2 (user: "they are a little bit offcenter"; the
// Guardian's arms make its slot wider than its body, so the toys' centres sat
// 2 to the Z-Rex's side), else 0.
// 0.5.66: round 500's 4, so its middle toy (Caltheris) is on the centre.
function ra_toy_shift( k )
{
    if ( k == 2 )
        return 2;
    // 0.5.67: 3 at its smaller size and wider gaps
    if ( k == 4 )
        return 3;
    return 0;
}

// 0.5.67: the space between pedestal k's toys: 3 at round 500 (its glows run
// together at 1.5), else 1.5 (0.5.45).
function ra_toy_gap( k )
{
    // 0.5.68: round 999's rows too
    if ( k == 4 || k == 5 )
        return 3;
    return 1.5;
}

// 0.5.63: a toy's scale on pedestal k: the pedestal's, but round 100's Z-Rex
// as tall as its Guardian (9.9 x 3.2 = 12.2 x 2.6), as at rounds 50 and 75.
// 0.5.66: round 500's too: its Z-Rex 3.2 and Caltheris 3.3, as at rounds 100
// and 255 (all about 31.7 tall).
function ra_toy_scale_at( k, name )
{
    if ( k == 2 && name == "sat_zm_phobos_tiny" )
        return 3.2;
    // 0.5.67: round 500 about 25 tall: the Z-Rex 2.5, Caltheris 2.6
    if ( k == 4 && name == "sat_zm_phobos_tiny" )
        return 2.5;
    if ( k == 4 && name == "sat_zm_neptune_1_tiny" )
        return 2.6;
    // 0.5.68: round 999 about 20 tall: the Z-Rex 2, Caltheris 2.1
    if ( k == 5 && name == "sat_zm_phobos_tiny" )
        return 2;
    if ( k == 5 && name == "sat_zm_neptune_1_tiny" )
        return 2.1;
    return level.ra_rs_toy_scale[ k ];
}

// 0.5.53: Rex's toy scriptable for a toy model (map refs: each one's base
// part shows that model; all in Rex's network scriptable list).
function ra_toy_scriptable( name )
{
    if ( name == "sat_zm_phobos_tiny" )
        return %"hash_784d10605e42452a";
    if ( name == "sat_zm_triton_gtoy" )
        return %"hash_260c0eeb4cffbe71";
    if ( name == "sat_zm_neptune_1_tiny" )
        return %"hash_784d0f605e424377";
    return %"hash_477b41eb17a3aa26";
}

// 0.5.45: a toy's width across (its x extent, GrayWolf export, game inches).
function ra_toy_width( name )
{
    if ( name == "sat_zm_phobos_tiny" )
        return 4.9;
    if ( name == "sat_zm_triton_gtoy" )
        return 9.1;
    if ( name == "sat_zm_neptune_1_tiny" )
        return 10;
    return 4.9;
}

// 0.5.45: how far forward a toy's origin goes so its footprint is centred on
// the pedestal top's depth (the middle of its y extent; it faces its -y).
// 0.5.49: the Z-Rex and the Guardian by the middle of their feet.
function ra_toy_depth( name )
{
    if ( name == "sat_zm_phobos_tiny" )
        return -0.95;
    if ( name == "sat_zm_triton_gtoy" )
        return -0.37;
    if ( name == "sat_zm_neptune_1_tiny" )
        return 0.1;
    return -0.55;
}

// 0.6.1: a boss fight is on: from a round-select pick until its fight starts
// (at most 3 minutes), while a boss event is owed, for the whole of a fight
// (ra_void_claw_fight: until none of its bosses is alive for 2 s), and while
// the Warden's summary waits or its ending runs.
function ra_boss_fight_on()
{
    if ( isdefined( level.ra_boss_due ) && level.ra_boss_due >= 0 )
        return true;
    if ( isdefined( level.ra_fight_n ) && level.ra_fight_n > 0 )
        return true;
    if ( istrue( level.ra_bf_held ) || istrue( level.ra_we_on ) )
        return true;
    return isdefined( level.ra_rs_wait_t ) && function_83bf4b34fbbe124b() < level.ra_rs_wait_t;
}

// 0.5.41: one pass of the round select: the players at a pedestal, a pick,
// the note.
function ra_round_select_pass()
{
    level.ra_rs_free = !ra_boss_alive( level.ra_zrex_ai, 0 ) && !ra_boss_alive( level.ra_guardian_ai, 1 ) && !ra_boss_alive( level.ra_caltheris_ai, 2 ) && !ra_boss_alive( level.ra_weyward_ai, 3 );
    // 0.6.1: and not anywhere in a boss fight (user: "i want the podiums to be
    // disabled while ur in another boss fight")
    if ( level.ra_rs_free && ra_boss_fight_on() )
        level.ra_rs_free = 0;
    level.ra_rs_now = function_83bf4b34fbbe124b();
    level.ra_rs_near = -1;
    // 1.1.3: the big toys' glows near their pedestal only
    ra_toy_glow_near();
    level.ra_rs_pi = 0;
    while ( isdefined( level.players ) && level.ra_rs_pi < level.players.size )
    {
        level.ra_rs_pl = level.players[ level.ra_rs_pi ];
        level.ra_rs_pi++;
        // 0.5.54: this player's copies of the Rex toys, once
        if ( isdefined( level.ra_rs_pl ) && !istrue( level.ra_rs_pl.ra_toy_copied ) )
            level.ra_rs_pl ra_toy_copies();
        if ( !isdefined( level.ra_rs_pl ) || !isalive( level.ra_rs_pl ) )
            continue;
        // 0.5.51: the toys of a pedestal the player comes near rise
        // 0.7.4: every pedestal's, at once (user: "make it so i dont need to
        // get close to the pedestals for the purple light to spawn on the toys")
        ra_round_select_rise_all();
        level.ra_rs_k = ra_round_select_at( level.ra_rs_pl.origin );
        if ( level.ra_rs_k < 0 )
        {
            level.ra_rs_pl.ra_rs_use = 0;
            continue;
        }
        level.ra_rs_near = level.ra_rs_k;
        level.ra_rs_use = level.ra_rs_pl usebuttonpressed();
        if ( level.ra_rs_use && !istrue( level.ra_rs_pl.ra_rs_use ) && level.ra_rs_free && level.ra_rs_now >= level.ra_rs_t )
        {
            level.ra_rs_t = level.ra_rs_now + 3000;
            level.ra_rs_from = level.ra_sp_round;
            level.ra_rs_ok = ra_round_select_pick( level.ra_rs_k );
            level.ra_rs_n++;
            // 0.6.1: its fight counts as on from the pick (at most 3 minutes)
            if ( level.ra_rs_ok )
                level.ra_rs_wait_t = level.ra_rs_now + 180000;
            // 0.5.95: the game's popup, text only
            ra_popup( "pick", "ROUND " + level.ra_rs_round[ level.ra_rs_k ], level.ra_rs_ok ? "Next round - " + level.ra_rs_name[ level.ra_rs_k ] : "Round not changed" );
            level.ra_rs_hint_k = level.ra_rs_k;
            level.ra_rs_hint_free = level.ra_rs_free;
            level.ra_rs_note_until = level.ra_rs_now + 4000;
            nengine_store_set( "rex_arena", "round_select_used", "pick " + level.ra_rs_n + " in round " + level.ra_rs_from + ": player " + ( level.ra_rs_pi - 1 ) + " picked round " + level.ra_rs_round[ level.ra_rs_k ] + " (" + level.ra_rs_name[ level.ra_rs_k ] + "); " + ( level.ra_rs_ok ? "set, round state " + level.ra_rj_state : "no round manager" ) );
            nengine_store_save( "rex_arena", "runtime" );
        }
        level.ra_rs_pl.ra_rs_use = level.ra_rs_use;
    }
    level.ra_rs_pl = undefined;
    // 0.5.95: the game's popup, text only, when a player comes to a pedestal
    // or the boss state changes there (not every second)
    if ( level.ra_rs_near < 0 )
    {
        // 0.5.96: the popup stays while a player is at the pedestal; it goes
        // when nobody is (user: "the pop up goes away while im still looking at it")
        if ( level.ra_rs_hint_k >= 0 )
            ra_popup( "leave", "", "" );
        level.ra_rs_hint_k = -1;
        return;
    }
    if ( level.ra_rs_now < level.ra_note_until || level.ra_rs_now < level.ra_rs_note_until || level.ra_rs_now < level.ra_rs_hint_t )
        return;
    if ( level.ra_rs_near == level.ra_rs_hint_k && level.ra_rs_free == level.ra_rs_hint_free )
        return;
    level.ra_rs_hint_t = level.ra_rs_now + 1000;
    level.ra_rs_hint_k = level.ra_rs_near;
    level.ra_rs_hint_free = level.ra_rs_free;
    ra_popup( "hint", "ROUND " + level.ra_rs_round[ level.ra_rs_near ], level.ra_rs_name[ level.ra_rs_near ] + ( level.ra_rs_free ? " - press Use" : " - boss fight in progress" ) );
}

// 0.7.4: every pedestal whose toys have not risen: they rise and glow
// (ra_round_select_rise), wherever the players are.
function ra_round_select_rise_all()
{
    level.ra_rsr_i = 0;
    while ( level.ra_rsr_i < level.ra_rs_m.size )
    {
        if ( !level.ra_rs_up[ level.ra_rsr_i ] && isdefined( level.ra_rs_m[ level.ra_rsr_i ] ) )
            ra_round_select_rise( level.ra_rsr_i );
        level.ra_rsr_i++;
    }
}

// 0.5.51: pedestal k's toys rise, once. Records round_select_rise.
function ra_round_select_rise( k )
{
    level.ra_rs_up[ k ] = 1;
    level.ra_rsr_n = 0;
    level.ra_rsr_j = 0;
    while ( level.ra_rsr_j < level.ra_rs_toy_m.size )
    {
        if ( level.ra_rs_toy_k[ level.ra_rsr_j ] == k && isdefined( level.ra_rs_toy_m[ level.ra_rsr_j ] ) )
        {
            level.ra_rs_toy_m[ level.ra_rsr_j ] thread ra_toy_rise();
            level.ra_rsr_n++;
        }
        level.ra_rsr_j++;
    }
    level.ra_rs_up_text = level.ra_rs_up_text + " " + level.ra_rs_round[ k ] + ": " + level.ra_rsr_n;
    // 0.5.52: and the glow
    // 0.5.53: and the scriptables whose glow is on
    // 0.5.56: and the big toys' shrouds
    nengine_store_set( "rex_arena", "round_select_rise", "risen (round: toys):" + level.ra_rs_up_text + "; glow on " + level.ra_rs_glow_on + " of " + level.ra_rs_glow_n + "; big-toy glow points " + level.ra_rs_gp_n );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.51: a toy rises and floats as Rex's super Easter egg box shows its toys
// (script_328fdabe75ddb9bb): up ra_up over 2 seconds (moveto), then 2.1
// seconds later bobbing ra_bob every 2 seconds (Rex: bobbing( up, 1.5, 2 )).
// 0.5.52: its tag_origin model rises and bobs with it.
// 0.5.53: its Rex toy scriptable (on that model) glows: part glow on, as
// Rex's shelf does with all six toys. 0.5.54: every player's copy; a copy made
// later starts with it on (ra_risen).
function ra_toy_rise()
{
    self endon( #"death" );
    level endon( #"game_ended" );
    self.ra_risen = 1;
    self.ra_ri = 0;
    while ( isdefined( self.ra_sc ) && self.ra_ri < self.ra_sc.size )
    {
        if ( isdefined( self.ra_sc[ self.ra_ri ] ) )
        {
            self.ra_sc[ self.ra_ri ] setscriptablepartstate( "glow", "on" );
            level.ra_rs_glow_on++;
        }
        self.ra_ri++;
    }
    self moveto( self.origin + ( 0, 0, self.ra_up ), 2 );
    if ( isdefined( self.ra_glow ) )
        self.ra_glow moveto( self.ra_glow.origin + ( 0, 0, self.ra_up ), 2 );
    wait 2.1;
    // 0.5.57: a big toy, up: Rex's glow on its body
    // 1.1.3: made only while a player is near its pedestal (ra_toy_glow_near)
    if ( isdefined( self.ra_gpts ) )
        self.ra_glowed = 1;
    self bobbing( ( 0, 0, 1 ), self.ra_bob, 2 );
    if ( isdefined( self.ra_glow ) )
        self.ra_glow bobbing( ( 0, 0, 1 ), self.ra_bob, 2 );
}

// 1.1.3: the big toys' purple glow only near their pedestal (user: "loads of
// vfx are missing"; chose "Glow only when near"). 0.7.4's 166 looping glows
// from the start (0.5.57's points on every big toy, for every player) left the
// game no room for its own effects; with round select off they came back.
// Each player has the glow of one pedestal at most: the nearest within 150
// units (150 up or down), kept until they are 200 away or another pedestal is
// nearer (the pedestals stand 150 to 215 apart). Its risen big toys' glows
// for that player are made (ra_toy_glow_make); every other toy's glows for that
// player, and all of them when the player is dead, are freed.
function ra_toy_glow_near()
{
    level.ra_gn_seen = [];
    level.ra_gn_pi = 0;
    while ( isdefined( level.players ) && level.ra_gn_pi < level.players.size )
    {
        level.ra_gn_pl = level.players[ level.ra_gn_pi ];
        level.ra_gn_pi++;
        if ( !isdefined( level.ra_gn_pl ) || !istrue( level.ra_gn_pl.ra_toy_copied ) )
            continue;
        level.ra_gn_e = level.ra_gn_pl getentitynumber();
        level.ra_gn_seen[ level.ra_gn_e ] = 1;
        if ( !isdefined( level.ra_gn_pl.ra_gn_k ) )
            level.ra_gn_pl.ra_gn_k = -1;
        // the nearest pedestal within 150; the one already lit stays within 200
        level.ra_gn_best = -1;
        level.ra_gn_bd = 150;
        level.ra_gn_keep = 0;
        level.ra_gn_k = 0;
        while ( isalive( level.ra_gn_pl ) && level.ra_gn_k < level.ra_rs_m.size )
        {
            if ( isdefined( level.ra_rs_m[ level.ra_gn_k ] ) )
            {
                level.ra_gn_d = distance( ( level.ra_gn_pl.origin[ 0 ], level.ra_gn_pl.origin[ 1 ], 0 ), ( level.ra_rs_m[ level.ra_gn_k ].origin[ 0 ], level.ra_rs_m[ level.ra_gn_k ].origin[ 1 ], 0 ) );
                level.ra_gn_z = level.ra_gn_pl.origin[ 2 ] - level.ra_rs_m[ level.ra_gn_k ].origin[ 2 ];
                if ( level.ra_gn_z < 150 && level.ra_gn_z > -150 && level.ra_gn_d < level.ra_gn_bd )
                {
                    level.ra_gn_best = level.ra_gn_k;
                    level.ra_gn_bd = level.ra_gn_d;
                }
                if ( level.ra_gn_k == level.ra_gn_pl.ra_gn_k && level.ra_gn_z < 200 && level.ra_gn_z > -200 && level.ra_gn_d < 200 )
                    level.ra_gn_keep = 1;
            }
            level.ra_gn_k++;
        }
        if ( level.ra_gn_best < 0 && level.ra_gn_keep )
            level.ra_gn_best = level.ra_gn_pl.ra_gn_k;
        level.ra_gn_pl.ra_gn_k = level.ra_gn_best;
        level.ra_gn_j = 0;
        while ( level.ra_gn_j < level.ra_rs_toy_m.size )
        {
            level.ra_gn_t = level.ra_rs_toy_m[ level.ra_gn_j ];
            level.ra_gn_want = level.ra_rs_toy_k[ level.ra_gn_j ] == level.ra_gn_best;
            level.ra_gn_j++;
            if ( !isdefined( level.ra_gn_t ) || !isdefined( level.ra_gn_t.ra_gpts ) || level.ra_gn_t.ra_gpts.size == 0 || !istrue( level.ra_gn_t.ra_glowed ) )
                continue;
            level.ra_gn_has = isdefined( level.ra_gn_t.ra_gsp ) && isdefined( level.ra_gn_t.ra_gsp[ level.ra_gn_e ] ) && level.ra_gn_t.ra_gsp[ level.ra_gn_e ].size > 0;
            if ( level.ra_gn_want && !level.ra_gn_has )
                level.ra_gn_t ra_toy_glow_make( level.ra_gn_pl );
            else if ( !level.ra_gn_want && level.ra_gn_has )
                level.ra_gn_t ra_toy_glow_free( level.ra_gn_e );
        }
    }
    // 1.1.4: glows kept for an entity number no player above has now (the player
    // left, or a new player in that slot has no copies yet) are freed
    level.ra_gn_j = 0;
    while ( isdefined( level.ra_gn_top ) && level.ra_gn_j < level.ra_rs_toy_m.size )
    {
        level.ra_gn_t = level.ra_rs_toy_m[ level.ra_gn_j ];
        level.ra_gn_j++;
        if ( !isdefined( level.ra_gn_t ) || !isdefined( level.ra_gn_t.ra_gsp ) )
            continue;
        level.ra_gn_e = 0;
        while ( level.ra_gn_e <= level.ra_gn_top )
        {
            if ( !isdefined( level.ra_gn_seen[ level.ra_gn_e ] ) && isdefined( level.ra_gn_t.ra_gsp[ level.ra_gn_e ] ) && level.ra_gn_t.ra_gsp[ level.ra_gn_e ].size > 0 )
            {
                level.ra_gn_left = level.ra_gn_left + level.ra_gn_t.ra_gsp[ level.ra_gn_e ].size;
                nengine_store_set( "rex_arena", "round_select_glows_left", "glows freed for players who left: " + level.ra_gn_left + " (last: entity " + level.ra_gn_e + ")" );
                level.ra_gn_t ra_toy_glow_free( level.ra_gn_e );
            }
            level.ra_gn_e++;
        }
    }
    level.ra_gn_pl = undefined;
    level.ra_gn_t = undefined;
}

// 1.1.3: player e's glows on this big toy freed (ra_toy_glow_near).
function ra_toy_glow_free( e )
{
    level.ra_tf_i = 0;
    while ( level.ra_tf_i < self.ra_gsp[ e ].size )
    {
        if ( isdefined( self.ra_gsp[ e ][ level.ra_tf_i ] ) )
        {
            self.ra_gsp[ e ][ level.ra_tf_i ] freescriptable();
            level.ra_rs_gl_off++;
        }
        level.ra_tf_i++;
    }
    self.ra_gsp[ e ] = [];
    nengine_store_set( "rex_arena", "round_select_glows", "Rex glows on the big toys, near their pedestal only: " + ( level.ra_rs_gl_n - level.ra_rs_gl_off ) + " now (made " + level.ra_rs_gl_n + ", freed " + level.ra_rs_gl_off + "; " + level.ra_rs_gp_n + " points a player)" );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.41: the pedestal within 60 units (and 120 up or down) of a place, -1
// for none.
function ra_round_select_at( pos )
{
    level.ra_rsa_i = 0;
    while ( level.ra_rsa_i < level.ra_rs_m.size )
    {
        level.ra_rsa_m = level.ra_rs_m[ level.ra_rsa_i ];
        if ( isdefined( level.ra_rsa_m ) && distance( ( pos[ 0 ], pos[ 1 ], 0 ), ( level.ra_rsa_m.origin[ 0 ], level.ra_rsa_m.origin[ 1 ], 0 ) ) < 60 && pos[ 2 ] - level.ra_rsa_m.origin[ 2 ] < 120 && pos[ 2 ] - level.ra_rsa_m.origin[ 2 ] > -120 )
        {
            level.ra_rsa_m = undefined;
            return level.ra_rsa_i;
        }
        level.ra_rsa_i++;
    }
    level.ra_rsa_m = undefined;
    return -1;
}

// 0.5.41: a pick. The boss events before it count as done (passed over), it
// and the later ones can be had again; this round's owed event is dropped;
// the round-500 and round-999 fights start again from nothing (their made
// flags, times and the bars in a row); the Weyward's put-back count starts
// again. Then the round jump.
function ra_round_select_pick( k )
{
    level.ra_rsp_i = 0;
    while ( level.ra_rsp_i <= 5 )
    {
        level.ra_boss_done[ level.ra_rsp_i ] = level.ra_rsp_i < k ? 1 : 0;
        level.ra_rsp_i++;
    }
    level.ra_boss_due = -1;
    level.ra_tr_z = 0;
    level.ra_tr_g = 0;
    level.ra_tr_end = [];
    level.ra_tr_t0 = undefined;
    level.ra_qd_started = 0;
    level.ra_qd_trio = 0;
    level.ra_qd_w = 0;
    level.ra_bar_h = 0;
    level.ra_wb_n = 0;
    return ra_round_jump( level.ra_rs_round[ k ] );
}

// 0.5.41: DellxCell's round jump (zm_mod_menu.gsc, menu_jump_round): with a
// round going (round manager state 1) the next round is set and the round is
// ended (through var_a009ab14ee0d3223 when there is one, else the round
// manager's notify); otherwise the round number is set (and the next round in
// state 2). level.ra_rj_state keeps the state seen.
function ra_round_jump( n )
{
    level.ra_rj_state = "none";
    if ( !isdefined( level.var_6781718da4f78d1c ) )
        return false;
    level.ra_rj_state = 0;
    if ( isdefined( level.var_6781718da4f78d1c.state ) )
        level.ra_rj_state = level.var_6781718da4f78d1c.state;
    if ( level.ra_rj_state == 1 && isdefined( level.var_a009ab14ee0d3223 ) )
    {
        level.var_dc917abcf5b8f749 = n;
        level.var_a009ab14ee0d3223.state = 2;
    }
    else if ( level.ra_rj_state == 1 )
    {
        level.var_dc917abcf5b8f749 = n;
        level.var_6781718da4f78d1c notify( #"hash_ebf555762278f138" );
    }
    else
    {
        level.var_6781718da4f78d1c.roundnumber = n;
        level.round_number = n;
        if ( level.ra_rj_state == 2 )
            level.var_dc917abcf5b8f749 = n;
    }
    return true;
}

// The Wunderfizz from round 1 without power. The game's Wunderfizz start-up
// (namespace_34fc1661493f2405::function_e3d3bfcc06c89350) waits until the round
// in the game-type setting var_7910192e66e7774c when var_c0e626638c3cdd4c is set
// (why Rex's appeared later); its power loop (function_29138c19b4ba9199) skips
// the power wait the first time when level.var_1d3d915cc555bf38[ its perk ] is
// set, the per-machine always-on table Rex's own map script uses for another
// machine (script_6ca41465354bcc51). Both are set as early as possible; the
// Wunderfizz at Rex's arena marker 861 is then only watched and recorded.
function rx_wunder_early()
{
    level endon( #"game_ended" );
    if ( !isdefined( level.var_1d3d915cc555bf38 ) )
        level.var_1d3d915cc555bf38 = [];
    level.var_1d3d915cc555bf38[ "specialty_choice" ] = 1;
    level.rx_wf_wait = 0;
    while ( !isdefined( level.var_7ebad24685cd9f8c ) && level.rx_wf_wait < 600 )
    {
        waitframe();
        level.rx_wf_wait++;
    }
    if ( !isdefined( level.var_7ebad24685cd9f8c ) )
        nengine_store_set( "rex_arena", "wunderfizz", "no_gametype_settings" );
    else
    {
        nengine_store_set( "rex_arena", "wunderfizz_delayed", isdefined( level.var_7ebad24685cd9f8c.var_c0e626638c3cdd4c ) ? level.var_7ebad24685cd9f8c.var_c0e626638c3cdd4c : "undefined" );
        nengine_store_set( "rex_arena", "wunderfizz_round_before", isdefined( level.var_7ebad24685cd9f8c.var_7910192e66e7774c ) ? level.var_7ebad24685cd9f8c.var_7910192e66e7774c : "undefined" );
        if ( isdefined( level.var_7ebad24685cd9f8c.var_7910192e66e7774c ) )
            level.var_7ebad24685cd9f8c.var_7910192e66e7774c = 0;
        nengine_store_set( "rex_arena", "wunderfizz", "set_early (" + level.rx_wf_wait + " frames)" );
    }
    nengine_store_save( "rex_arena", "runtime" );
    level.rx_wf_tries = 0;
    while ( level.rx_wf_tries < 1800 )
    {
        if ( !isdefined( level.var_1d3d915cc555bf38 ) )
            level.var_1d3d915cc555bf38 = [];
        level.var_1d3d915cc555bf38[ "specialty_choice" ] = 1;
        if ( isdefined( level.var_7ebad24685cd9f8c ) && isdefined( level.var_7ebad24685cd9f8c.var_7910192e66e7774c ) && level.var_7ebad24685cd9f8c.var_7910192e66e7774c != 0 )
            level.var_7ebad24685cd9f8c.var_7910192e66e7774c = 0;
        if ( isdefined( level.var_2ad433898c7f6057 ) )
        {
            level.rx_wf_i = 0;
            while ( level.rx_wf_i < level.var_2ad433898c7f6057.size )
            {
                level.rx_wf_x = level.var_2ad433898c7f6057[ level.rx_wf_i ];
                if ( isdefined( level.rx_wf_x ) && isdefined( level.rx_wf_x.origin ) && isdefined( level.rx_wf_x.var_b69810c6c14b1634 ) && distancesquared( level.rx_wf_x.origin, ( 30040, -29561.2, 2120 ) ) < 160000 )
                {
                    level.rx_wf_round = -1;
                    if ( isdefined( level.var_6781718da4f78d1c ) && isdefined( level.var_6781718da4f78d1c.roundnumber ) )
                        level.rx_wf_round = level.var_6781718da4f78d1c.roundnumber;
                    nengine_store_set( "rex_arena", "wunderfizz", "arrived in round " + level.rx_wf_round + " after " + level.rx_wf_tries + " s" );
                    nengine_store_save( "rex_arena", "runtime" );
                    level.rx_wf_x = undefined;
                    return;
                }
                level.rx_wf_i++;
            }
            level.rx_wf_x = undefined;
        }
        wait 1;
        level.rx_wf_tries++;
    }
    nengine_store_set( "rex_arena", "wunderfizz", "not_seen_in_30_min" );
    nengine_store_save( "rex_arena", "runtime" );
}

// One Mystery Box in the arena, at the spot of the user's Ashes Arena box,
// made like Ashes Arena 0.4.x: a box location struct copied from a ready native
// box location (template) and built by the box system itself
// (namespace_705d991e4db4f3c6::function_ab59e6993557d5b6). Once it is ready
// the other locations are closed and taken out of the rotation, and the box
// stays put (var_5542fc8f8eafa0c0). No World Builder field is used.
function rx_box_manager()
{
    level endon( #"game_ended" );
    level.rx_bx_wait = 0;
    while ( level.rx_bx_wait < 200 && ( !isdefined( level.var_1bbb5557537e2c0c ) || !isdefined( level.var_e0e84452fe117b5f ) || level.var_1bbb5557537e2c0c.size == 0 ) )
    {
        wait 0.1;
        level.rx_bx_wait++;
    }
    if ( !isdefined( level.var_1bbb5557537e2c0c ) || !isdefined( level.var_e0e84452fe117b5f ) || level.var_1bbb5557537e2c0c.size == 0 )
    {
        nengine_store_set( "rex_arena", "box", "native_system_not_ready" );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    level.rx_bx_src = undefined;
    level.rx_bx_wait = 0;
    while ( !isdefined( level.rx_bx_src ) && level.rx_bx_wait < 80 )
    {
        level.rx_bx_i = 0;
        while ( level.rx_bx_i < level.var_1bbb5557537e2c0c.size )
        {
            level.rx_bx_item = level.var_1bbb5557537e2c0c[ level.rx_bx_i ];
            if ( !isdefined( level.rx_bx_src ) && isdefined( level.rx_bx_item ) && isdefined( level.rx_bx_item.origin ) && isdefined( level.rx_bx_item.var_97c6497c84d770a ) && !istrue( level.rx_bx_item.rx_arena_box ) )
                level.rx_bx_src = level.rx_bx_item;
            level.rx_bx_i++;
        }
        if ( !isdefined( level.rx_bx_src ) )
        {
            wait 0.25;
            level.rx_bx_wait++;
        }
    }
    level.rx_bx_item = undefined;
    if ( !isdefined( level.rx_bx_src ) )
    {
        nengine_store_set( "rex_arena", "box", "native_template_missing" );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    level.rx_bx = spawnstruct();
    level.rx_bx.origin = ( 29712, -25443, 2080 );
    level.rx_bx.angles = ( 0, 90, 0 );
    level.rx_bx.script_start = 1;
    level.rx_bx.rx_arena_box = 1;
    level.rx_bx.var_b5608a3a940478dc = "rx_arena_box";
    if ( isdefined( level.rx_bx_src.targetname ) )
        level.rx_bx.targetname = level.rx_bx_src.targetname;
    if ( isdefined( level.rx_bx_src.script_parameters ) )
        level.rx_bx.script_parameters = level.rx_bx_src.script_parameters;
    if ( isdefined( level.rx_bx_src.script_noteworthy ) )
        level.rx_bx.script_noteworthy = level.rx_bx_src.script_noteworthy;
    if ( isdefined( level.rx_bx_src.str_magicbox_scriptable ) )
        level.rx_bx.str_magicbox_scriptable = level.rx_bx_src.str_magicbox_scriptable;
    level.rx_bx namespace_705d991e4db4f3c6::function_ab59e6993557d5b6();
    if ( !isdefined( level.rx_bx.var_97c6497c84d770a ) )
    {
        level.var_1bbb5557537e2c0c = arrayremove( level.var_1bbb5557537e2c0c, level.rx_bx );
        level.var_e0e84452fe117b5f[ "rx_arena_box" ] = undefined;
        nengine_store_set( "rex_arena", "box", "model_not_made" );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    level.rx_box_ready = 0;
    level thread rx_box_ready_job( level.rx_bx.var_97c6497c84d770a );
    level.rx_bx_wait = 0;
    while ( !level.rx_box_ready && level.rx_bx_wait < 200 && isdefined( level.rx_bx.var_97c6497c84d770a ) )
    {
        level.rx_bx_wait++;
        waitframe();
    }
    if ( !level.rx_box_ready || !isdefined( level.rx_bx.var_97c6497c84d770a ) )
    {
        level.var_1bbb5557537e2c0c = arrayremove( level.var_1bbb5557537e2c0c, level.rx_bx );
        level.var_e0e84452fe117b5f[ "rx_arena_box" ] = undefined;
        nengine_store_set( "rex_arena", "box", "model_not_ready" );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    rx_box_activate();
    level thread rx_box_guard();
    level thread rx_box_col();
}

function rx_box_activate()
{
    level.rx_bx_i = 0;
    while ( level.rx_bx_i < level.var_1bbb5557537e2c0c.size )
    {
        level.rx_bx_item = level.var_1bbb5557537e2c0c[ level.rx_bx_i ];
        if ( isdefined( level.rx_bx_item ) && level.rx_bx_item != level.rx_bx )
        {
            if ( isdefined( level.rx_bx_item.var_97c6497c84d770a ) && istrue( level.rx_bx_item.var_f14b2b4820b635e7 ) )
                level.rx_bx_item thread namespace_705d991e4db4f3c6::function_3fc5ec87d3083d53( 1, 1 );
            level.rx_bx_item.var_f14b2b4820b635e7 = 0;
        }
        level.rx_bx_i++;
    }
    level.rx_bx_item = undefined;
    level.var_1bbb5557537e2c0c = [ level.rx_bx ];
    level.var_5542fc8f8eafa0c0 = 1;
    level.rx_bx.var_f14b2b4820b635e7 = 1;
    level.rx_bx thread namespace_705d991e4db4f3c6::function_d032ba44d110e870( 1, 0 );
    nengine_store_set( "rex_arena", "box", "single_location_requested" );
    nengine_store_set( "rex_arena", "box_origin", level.rx_bx.origin );
    nengine_store_set( "rex_arena", "box_rotation_count", level.var_1bbb5557537e2c0c.size );
    nengine_store_save( "rex_arena", "runtime" );
}

function rx_box_guard()
{
    level endon( #"game_ended" );
    while ( ra_selected() )
    {
        wait 2;
        level.var_5542fc8f8eafa0c0 = 1;
        if ( !isdefined( level.var_1bbb5557537e2c0c ) || !isdefined( level.rx_bx ) || !isdefined( level.rx_bx.var_97c6497c84d770a ) )
            continue;
        if ( level.var_1bbb5557537e2c0c.size != 1 || level.var_1bbb5557537e2c0c[ 0 ] != level.rx_bx )
        {
            level.rx_bx_resets = isdefined( level.rx_bx_resets ) ? level.rx_bx_resets + 1 : 1;
            nengine_store_set( "rex_arena", "box_rotation_resets", level.rx_bx_resets );
            rx_box_activate();
        }
    }
}

// Records how far this mod's Guardian gets from where it was made (so a
// Guardian still held at its spawn point shows in the store). Once a second,
// written when the farthest distance grows by 100 units or more.
function ra_guardian_roam_watch()
{
    self endon( #"death" );
    level endon( #"game_ended" );
    level.ra_gr_home = self.origin;
    level.ra_gr_far = 0;
    level.ra_gr_said = 0;
    nengine_store_set( "rex_arena", "boss_guardian_roam", "made in round " + level.ra_sp_round + "; leash field " + self.var_e30ba852102cf5a0 );
    while ( true )
    {
        wait 1;
        level.ra_gr_d = int( distance( self.origin, level.ra_gr_home ) );
        if ( level.ra_gr_d > level.ra_gr_far )
            level.ra_gr_far = level.ra_gr_d;
        if ( level.ra_gr_far >= level.ra_gr_said + 100 )
        {
            level.ra_gr_said = level.ra_gr_far;
            nengine_store_set( "rex_arena", "boss_guardian_roam", "round " + level.ra_sp_round + ": up to " + level.ra_gr_far + " units from its spawn point (now " + level.ra_gr_d + ")" );
        }
    }
}

// 0.4.4: from the boss guard, while this mod's Z-Rex lives. When it first sits
// at 1 health (its own death sequence, or this mod's held hit), the time is
// noted and its death flag is looked at on a separate thread. A Z-Rex still at
// 1 health after 60 s is killed, so a sequence that never finishes cannot hold
// the round open.
function ra_zrex_low_watch()
{
    if ( level.ra_g_ai[ 0 ].health > 1 )
    {
        level.ra_zl_t = undefined;
        return;
    }
    if ( !isdefined( level.ra_zl_t ) )
    {
        level.ra_zl_t = function_83bf4b34fbbe124b();
        nengine_store_set( "rex_arena", "boss_zrex_dying", "round " + level.ra_sp_round + ": at 1 health" );
        nengine_store_save( "rex_arena", "runtime" );
        level.ra_g_ai[ 0 ] thread ra_zrex_flag_probe();
        return;
    }
    if ( function_83bf4b34fbbe124b() - level.ra_zl_t > 60000 )
    {
        level.ra_zl_t = undefined;
        nengine_store_set( "rex_arena", "boss_zrex_dying", "round " + level.ra_sp_round + ": still at 1 health after 60 s; killed" );
        nengine_store_save( "rex_arena", "runtime" );
        level.ra_g_ai[ 0 ] kill();
    }
}

// 0.5.24: Z-Rex's own immune move (script_31af9060592e982c,
// function_5f8dc1ca7561fecb) sets var_cffd4250b352cef4, and its damage
// callback (script_178546be025df90c, function_724896e630cbef00) then gives 0;
// its move's end or interruption sets it back. Each move is noted with how
// long it lasted; one still on after 20 s is set back to 0. From the boss guard.
function ra_zrex_immune_watch()
{
    if ( !istrue( level.ra_g_ai[ 0 ].var_cffd4250b352cef4 ) )
    {
        if ( isdefined( level.ra_zi_t ) )
        {
            level.ra_zi_n++;
            nengine_store_set( "rex_arena", "boss_zrex_immune", "round " + level.ra_sp_round + ": immune move " + level.ra_zi_n + " ended after " + ( function_83bf4b34fbbe124b() - level.ra_zi_t ) + " ms at health " + level.ra_g_ai[ 0 ].health );
            level.ra_zi_t = undefined;
        }
        return;
    }
    if ( !isdefined( level.ra_zi_t ) )
    {
        level.ra_zi_t = function_83bf4b34fbbe124b();
        return;
    }
    if ( function_83bf4b34fbbe124b() - level.ra_zi_t > 20000 )
    {
        level.ra_g_ai[ 0 ].var_cffd4250b352cef4 = 0;
        level.ra_zi_cut++;
        level.ra_zi_t = undefined;
        nengine_store_set( "rex_arena", "boss_zrex_immune_cut", "round " + level.ra_sp_round + ": immune for over 20 s at health " + level.ra_g_ai[ 0 ].health + "; set back (" + level.ra_zi_cut + ")" );
        nengine_store_save( "rex_arena", "runtime" );
    }
}

// Whether Z-Rex's own death flag (the one its damage callback sets when its
// death sequence starts) is set. Own thread: a fault here stops only this.
function ra_zrex_flag_probe()
{
    self endon( #"death" );
    nengine_store_set( "rex_arena", "boss_zrex_dying_flag", "checking" );
    wait 1;
    level.ra_zf = 0;
    if ( self namespace_60b3bdcc70f79fc6::function_11e87341ba2131ce( "marked_for_death" ) && self namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( "marked_for_death" ) )
        level.ra_zf = 1;
    nengine_store_set( "rex_arena", "boss_zrex_dying_flag", level.ra_zf ? "set (its own death sequence)" : "not set" );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.4.6: the Guardian's slam kills only in its inner radius, so a Z-Rex death
// counts as a slam only when the Guardian was within 800 units of it at the
// guard's last look (both positions are sampled every 0.05 s).
function ra_zrex_guardian_near()
{
    return isdefined( level.ra_g_org[ 0 ] ) && isdefined( level.ra_g_org[ 1 ] ) && distancesquared( level.ra_g_org[ 0 ], level.ra_g_org[ 1 ] ) < 640000;
}

// 0.5.18: Z-Rex's partner boss is alive: the Guardian or Caltheris.
function ra_zrex_partner_alive()
{
    return ( level.ra_g_on[ 1 ] && ra_boss_alive( level.ra_g_ai[ 1 ], 1 ) ) || ( level.ra_g_on[ 2 ] && ra_boss_alive( level.ra_g_ai[ 2 ], 2 ) );
}

// 0.5.18: the partner can have killed Z-Rex: the Guardian within 800 units
// (its slam), or Caltheris anywhere (its reach is not known; the instant-kill
// mark on Z-Rex decides). 0.5.25: with all three, either.
function ra_zrex_partner_near()
{
    if ( level.ra_g_on[ 2 ] && ra_boss_alive( level.ra_g_ai[ 2 ], 2 ) )
        return true;
    return level.ra_g_on[ 1 ] && ra_boss_alive( level.ra_g_ai[ 1 ], 1 ) && ra_zrex_guardian_near();
}

// 0.4.6: on the game's zombie-damaged event, added after DellxCell's (which
// multiplies the damage in place there). A hit that would still kill this
// mod's Z-Rex is set to health - 1, so the next hit goes through Z-Rex's own
// death sequence.
function ra_zrex_hold_late( params )
{
    if ( !isdefined( self ) || !isdefined( self.ra_boss_index ) || self.ra_boss_index != 0 || !isalive( self ) )
        return;
    if ( !isdefined( params ) || !isdefined( params.var_a87b62c261a8d114 ) )
        return;
    // 0.4.7: at 1 health Z-Rex's own callback has started its death sequence
    // (its flag); a later stage can still enlarge the hit (0.4.6 in game: held
    // at 1, then dead from 1 without the animation). The sequence ends with
    // the game's kill, so further hits are cancelled while the flag is set.
    if ( self.health <= 1 )
    {
        level.ra_zo_hits++;
        level.ra_zo_text = "round " + level.ra_sp_round + ": damage " + params.var_a87b62c261a8d114 + " after the game's rules, death flag " + ( self ra_zrex_dying_flag() ? "set" : "not set" );
        nengine_store_set( "rex_arena", "boss_zrex_one_hp_hits", level.ra_zo_hits + " hits at 1 health; last " + level.ra_zo_text );
        if ( level.ra_zo_hits <= 10 )
        {
            nengine_store_set( "rex_arena", "boss_zrex_one_hp_hit_" + level.ra_zo_hits, level.ra_zo_text );
            nengine_store_save( "rex_arena", "runtime" );
        }
        if ( params.var_a87b62c261a8d114 >= 1 )
        {
            if ( self ra_zrex_dying_flag() )
            {
                params.var_a87b62c261a8d114 = 0;
                level.ra_zd_cancel++;
                if ( level.ra_zd_cancel == 1 || level.ra_zd_cancel % 20 == 0 )
                {
                    nengine_store_set( "rex_arena", "boss_zrex_dying_hits", "round " + level.ra_sp_round + ": " + level.ra_zd_cancel + " hits cancelled during its death sequence" );
                    nengine_store_save( "rex_arena", "runtime" );
                }
            }
            else
            {
                nengine_store_set( "rex_arena", "boss_zrex_final_hit", "round " + level.ra_sp_round + ": hit of " + params.var_a87b62c261a8d114 + " at 1 health with its death flag not set; let through" );
                nengine_store_save( "rex_arena", "runtime" );
            }
        }
        return;
    }
    if ( params.var_a87b62c261a8d114 < self.health )
        return;
    if ( !isdefined( level.ra_zd_late ) )
        level.ra_zd_late = 0;
    level.ra_zd_late++;
    nengine_store_set( "rex_arena", "boss_zrex_lethal_held_late", "round " + level.ra_sp_round + ": hit of " + params.var_a87b62c261a8d114 + " at health " + self.health + " held at 1 (" + level.ra_zd_late + ")" );
    params.var_a87b62c261a8d114 = self.health - 1;
    if ( level.ra_zrex_nc )
    {
        self thread ra_zrex_nocorpse_clear();
        level.ra_zrex_nc = 0;
        nengine_store_set( "rex_arena", "boss_zrex_corpse", "normal corpse (held at 1)" );
    }
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.4.7: whether Z-Rex's own death flag is set (its damage callback sets it
// when its death sequence starts; the same check as ra_zrex_flag_probe).
function ra_zrex_dying_flag()
{
    return self namespace_60b3bdcc70f79fc6::function_11e87341ba2131ce( "marked_for_death" ) && self namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( "marked_for_death" );
}

// 0.4.8: a slam with a kill circle landed within reach of Z-Rex in the last
// 250 ms (ra_slam_check).
function ra_zrex_slam_logged()
{
    return isdefined( level.ra_sw_kill_t ) && function_83bf4b34fbbe124b() - level.ra_sw_kill_t <= 250;
}

// The Guardian keeps each slam's result (impact point and kill circle) in a
// struct of its own, filled before its kill pass (script_670486d63d6d8151).
// A new impact point means a slam landed in the last 0.05 s. One within 400
// units of Z-Rex's last place is recorded; one whose kill circle reaches that
// place (plus 60 units for Z-Rex's movement since) marks the time, which the
// guard uses to undo a slam kill.
function ra_slam_watch()
{
    if ( !level.ra_g_on[ 1 ] || !ra_boss_alive( level.ra_g_ai[ 1 ], 1 ) )
        return;
    ra_slam_check( 0, level.ra_g_ai[ 1 ].var_d368de47f50cccdf );
    ra_slam_check( 1, level.ra_g_ai[ 1 ].var_7eb791e627c0827a );
}

function ra_slam_check( slot, result )
{
    if ( !isdefined( result ) || !isdefined( result.var_e5049d59fedd8c2f ) )
        return;
    if ( isdefined( level.ra_sw_last[ slot ] ) && level.ra_sw_last[ slot ] == result.var_e5049d59fedd8c2f )
        return;
    level.ra_sw_last[ slot ] = result.var_e5049d59fedd8c2f;
    level.ra_sw_total++;
    if ( !level.ra_g_on[ 0 ] || !isdefined( level.ra_g_org[ 0 ] ) )
        return;
    level.ra_sw_dx = result.var_e5049d59fedd8c2f[ 0 ] - level.ra_g_org[ 0 ][ 0 ];
    level.ra_sw_dy = result.var_e5049d59fedd8c2f[ 1 ] - level.ra_g_org[ 0 ][ 1 ];
    level.ra_sw_d = int( sqrt( level.ra_sw_dx * level.ra_sw_dx + level.ra_sw_dy * level.ra_sw_dy ) );
    if ( level.ra_sw_d >= 400 )
        return;
    level.ra_sw_near++;
    level.ra_sw_kr = -1;
    if ( isdefined( result.var_3f9fe6c6d730bba8 ) )
        level.ra_sw_kr = result.var_3f9fe6c6d730bba8;
    if ( level.ra_sw_kr > 0 && level.ra_sw_d < level.ra_sw_kr + 60 )
    {
        level.ra_sw_kill_t = function_83bf4b34fbbe124b();
        if ( level.ra_sw_d < level.ra_sw_kr )
            level.ra_sw_inside++;
    }
    level.ra_sw_text = "round " + level.ra_sp_round + ": slam landed " + level.ra_sw_d + " units from Z-Rex (kill circle " + level.ra_sw_kr + "), Z-Rex " + ( ra_boss_alive( level.ra_g_ai[ 0 ], 0 ) ? "alive" : "dead" );
    nengine_store_set( "rex_arena", "boss_slam_near", level.ra_sw_text );
    if ( level.ra_sw_near <= 30 )
        nengine_store_set( "rex_arena", "boss_slam_near_" + level.ra_sw_near, level.ra_sw_text );
    nengine_store_set( "rex_arena", "boss_slam_count", "slams " + level.ra_sw_total + ", within 400 units of Z-Rex " + level.ra_sw_near + ", inside the kill circle " + level.ra_sw_inside );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.4.9: what a Z-Rex death looked like from its death event: health, its own
// death flag (its death sequence), nocorpse, the slam's mark, and whether the
// game had made a corpse then and 0.5 s later (its death animation plays on
// the corpse). Own level thread: a fault here stops only this.
function ra_zrex_death_info( ai )
{
    level.ra_zi_n++;
    level.ra_zi_id = level.ra_zi_n;
    level.ra_zi_text = "round " + level.ra_sp_round + ": health " + ai.health + ", death flag " + ( ai ra_zrex_dying_flag() ? "set" : "not set" ) + ", nocorpse " + ( isdefined( ai.nocorpse ) ? ai.nocorpse : "unset" ) + ", slam mark " + ( isdefined( ai.var_a472e925a028ede0 ) && ai.var_a472e925a028ede0 ? 1 : 0 ) + ", corpse " + ( isdefined( ai getcorpseentity() ) ? "yes" : "no" );
    nengine_store_set( "rex_arena", "boss_zrex_deathinfo", level.ra_zi_text );
    if ( level.ra_zi_id <= 10 )
        nengine_store_set( "rex_arena", "boss_zrex_deathinfo_" + level.ra_zi_id, level.ra_zi_text );
    nengine_store_save( "rex_arena", "runtime" );
    wait 0.5;
    if ( !isdefined( ai ) )
        level.ra_zi_text = level.ra_zi_text + "; 0.5 s later the entity is gone";
    else
        level.ra_zi_text = level.ra_zi_text + "; 0.5 s later corpse " + ( isdefined( ai getcorpseentity() ) ? "yes" : "no" );
    nengine_store_set( "rex_arena", "boss_zrex_deathinfo", level.ra_zi_text );
    if ( level.ra_zi_id <= 10 )
        nengine_store_set( "rex_arena", "boss_zrex_deathinfo_" + level.ra_zi_id, level.ra_zi_text );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.0: removes this mod's no-corpse setting from Z-Rex. The game's scripts
// only ever set nocorpse to 1, and a Z-Rex given 0 lost its death animation
// and body (0.4.9), so the field is removed instead. Own thread: a fault here
// stops only this ("clearing" is left in the store).
function ra_zrex_nocorpse_clear()
{
    nengine_store_set( "rex_arena", "boss_zrex_nocorpse_clear", "round " + level.ra_sp_round + ": clearing" );
    self.nocorpse = undefined;
    level.ra_znc_n++;
    nengine_store_set( "rex_arena", "boss_zrex_nocorpse_clear", "round " + level.ra_sp_round + ": removed (" + level.ra_znc_n + " times), now " + ( isdefined( self.nocorpse ) ? self.nocorpse : "unset" ) );
}

// 0.5.1: Ashes Arena's exfil and GobbleGum machine (Ashes 0.4.43 code, renamed
// aa_ -> rx_), at the spots the user marked in World Builder (save
// "exfil_and_gobble"; positions only). Both are built with the game's own
// calls: the exfil is a new native exfil location registered as the only one,
// the machine is the game's per-location GobbleGum setup on a plain struct.
// Arena match only: each manager returns unless ra_selected().
// Exfil: (29099, -25437, 2071) yaw 358, no booth collision (Rex has no donor
// brush). GobbleGum: (29415, -25308, 2071) yaw 266.
function rx_exfil_manager()
{
    level endon( #"game_ended" );
    if ( !ra_selected() )
        return;
    // Create the booth as soon as native exfil locations and destinations
    // exist. This changes placement timing, not round availability.
    level.rx_xf_wait = 0;
    level.rx_xf_source = undefined;
    while ( !isdefined( level.rx_xf_source ) && level.rx_xf_wait < 600 )
    {
        if ( isdefined( level.var_d59cf14644e9665e ) && isdefined( level.var_d59cf14644e9665e.var_c7cfc464905e7bcd ) && isdefined( level.var_d59cf14644e9665e.var_60451de0b132b4cd ) && isdefined( level.var_7619345e0810ba9b ) )
            rx_exfil_find_source();
        if ( !isdefined( level.rx_xf_source ) )
        {
            wait 0.1;
            level.rx_xf_wait++;
        }
    }
    nengine_store_set( "rex_arena", "exfil_native_wait_ticks", level.rx_xf_wait );
    if ( !isdefined( level.rx_xf_source ) )
    {
        nengine_store_set( "rex_arena", "exfil", "native_template_or_destinations_missing" );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    // Never replace locations while an exfil window or an exfil is active.
    level.rx_xf_wait = 0;
    while ( ( isdefined( level.var_d59cf14644e9665e.var_d867cc41c15a2fd1 ) || namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( "exfil_window_active" ) ) && level.rx_xf_wait < 180 )
    {
        wait 1;
        level.rx_xf_wait++;
    }
    if ( isdefined( level.var_d59cf14644e9665e.var_d867cc41c15a2fd1 ) || namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( "exfil_window_active" ) )
    {
        nengine_store_set( "rex_arena", "exfil", "window_already_active" );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }

    level.rx_xf = spawnstruct();
    level.rx_xf.origin = ( 29099, -25437, 2071 );
    level.rx_xf.angles = ( 0, 358, 0 );
    level.rx_xf.var_94650194e2160349 = level.rx_xf_source.var_94650194e2160349;
    level.rx_xf.var_e866b658199d3d44 = isdefined( level.rx_xf_source.var_e866b658199d3d44 ) ? level.rx_xf_source.var_e866b658199d3d44 : 10000;
    level.rx_xf.var_5542f497e2de8809 = isdefined( level.rx_xf_source.var_5542f497e2de8809 ) ? level.rx_xf_source.var_5542f497e2de8809 : 1250;
    level.rx_xf.var_b78ab1d96704e340 = "disable";
    rx_exfil_interact_marker();

    // The retail exfil portal requires four linked teleport destinations.
    // Keep the original, indexed destination marker for the exit sequence;
    // a World Builder position-only copy omits those links.
    level.rx_xf.var_5fc9666ddf44b5a0 = level.rx_xf_source.var_5fc9666ddf44b5a0;
    level.rx_xf_forward = anglestoforward( level.rx_xf.angles );
    level.rx_xf.var_815c0da84aabce29 = spawnstruct();
    level.rx_xf.var_815c0da84aabce29.origin = level.rx_xf.origin + level.rx_xf_forward * 300;
    level.rx_xf.var_815c0da84aabce29.angles = level.rx_xf.angles;
    level.rx_xf.var_e78d1323ef173b = spawnstruct();
    level.rx_xf.var_e78d1323ef173b.origin = level.rx_xf.origin + level.rx_xf_forward * 150;
    level.rx_xf.var_e78d1323ef173b.angles = level.rx_xf.angles;
    level.rx_xf.var_6434f4d7be44b03d = spawnscriptable( level.var_d59cf14644e9665e.var_60451de0b132b4cd, level.rx_xf.origin, level.rx_xf.angles );
    level.rx_xf.var_4cf63ec91b753a3c = spawnscriptable( "zm_sat_exfil_scriptable_interact", level.rx_xf.var_b03fab8f4be015ad.origin );
    if ( !isdefined( level.rx_xf.var_6434f4d7be44b03d ) || !isdefined( level.rx_xf.var_4cf63ec91b753a3c ) )
    {
        if ( isdefined( level.rx_xf.var_6434f4d7be44b03d ) )
            level.rx_xf.var_6434f4d7be44b03d freescriptable();
        if ( isdefined( level.rx_xf.var_4cf63ec91b753a3c ) )
            level.rx_xf.var_4cf63ec91b753a3c freescriptable();
        nengine_store_set( "rex_arena", "exfil", "local_scriptable_missing" );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    level.rx_xf.var_4cf63ec91b753a3c.var_63b713bfea7c9e7c = level.rx_xf;
    namespace_7fc982453bce8e6a::function_2558ae94964fd952( level.rx_xf.var_4cf63ec91b753a3c, &namespace_6538eb3d75c4239b::function_cc7cbc67cac45bf1, undefined, undefined, &namespace_6538eb3d75c4239b::function_ac8d0e7bd667ef23 );
    level.rx_xf.var_4cf63ec91b753a3c namespace_7fc982453bce8e6a::function_e4a4753e6eac02d7();
    level.rx_xf namespace_6538eb3d75c4239b::function_bb6c83c5d8558eb1( 0, 0, 0 );
    if ( isdefined( level.var_d59cf14644e9665e.var_d867cc41c15a2fd1 ) || namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( "exfil_window_active" ) )
    {
        level.rx_xf.var_6434f4d7be44b03d freescriptable();
        level.rx_xf.var_4cf63ec91b753a3c freescriptable();
        nengine_store_set( "rex_arena", "exfil", "window_started_during_setup" );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }

    // If an earlier window left objective handles behind, retire them using
    // the game's own cleanup while the original location list is still intact.
    level.rx_xf_old = level.var_d59cf14644e9665e.var_c7cfc464905e7bcd;
    level.rx_xf_i = 0;
    level.rx_xf_has_icon = 0;
    while ( level.rx_xf_i < level.rx_xf_old.size )
    {
        if ( isdefined( level.rx_xf_old[ level.rx_xf_i ] ) && isdefined( level.rx_xf_old[ level.rx_xf_i ].var_c6883f07ae9a466 ) )
            level.rx_xf_has_icon = 1;
        level.rx_xf_i++;
    }
    if ( level.rx_xf_has_icon )
        namespace_6538eb3d75c4239b::function_ca4b478da8448624( 0, 0 );
    level.rx_xf_i = 0;
    while ( level.rx_xf_i < level.rx_xf_old.size )
    {
        if ( isdefined( level.rx_xf_old[ level.rx_xf_i ] ) )
            level.rx_xf_old[ level.rx_xf_i ] namespace_6538eb3d75c4239b::function_bb6c83c5d8558eb1( 0, 0, 0 );
        level.rx_xf_i++;
    }
    level.var_d59cf14644e9665e.var_c7cfc464905e7bcd = [ level.rx_xf ];
    level.rx_xfe_started = 0;
    level namespace_42ffbe510c7bd5b1::function_3e93ae4f7823fe81( "zm_exfil_success", &rx_exfil_success, undefined );
    nengine_store_set( "rex_arena", "exfil_end", "watching_for_success" );
    nengine_store_set( "rex_arena", "exfil", "arena_location_registered" );
    level thread rx_exfil_clip();
    nengine_store_set( "rex_arena", "exfil_collision", "none (Rex has no donor brush)" );
    nengine_store_set( "rex_arena", "exfil_created_relative_to_landing", isdefined( level.ra_land_t ) ? function_83bf4b34fbbe124b() - level.ra_land_t : "before_landing" );
    nengine_store_set( "rex_arena", "exfil_position", level.rx_xf.origin );
    nengine_store_set( "rex_arena", "exfil_interaction_position", level.rx_xf.var_b03fab8f4be015ad.origin );
    nengine_store_set( "rex_arena", "exfil_hvt_position", level.rx_xf.var_815c0da84aabce29.origin );
    nengine_store_set( "rex_arena", "exfil_teleport_destinations", level.rx_xf_points.size );
    nengine_store_set( "rex_arena", "exfil_original_locations", level.rx_xf_old.size );
    nengine_store_set( "rex_arena", "exfil_active_locations", level.var_d59cf14644e9665e.var_c7cfc464905e7bcd.size );
    nengine_store_save( "rex_arena", "runtime" );
}

function rx_exfil_find_source()
{
    level.rx_xf_i = 0;
    while ( level.rx_xf_i < level.var_d59cf14644e9665e.var_c7cfc464905e7bcd.size )
    {
        level.rx_xf_candidate = level.var_d59cf14644e9665e.var_c7cfc464905e7bcd[ level.rx_xf_i ];
        if ( isdefined( level.rx_xf_candidate ) && isdefined( level.rx_xf_candidate.origin ) && isdefined( level.rx_xf_candidate.angles ) && isdefined( level.rx_xf_candidate.var_6434f4d7be44b03d ) && isdefined( level.rx_xf_candidate.var_b03fab8f4be015ad ) && isdefined( level.rx_xf_candidate.var_b03fab8f4be015ad.origin ) && isdefined( level.rx_xf_candidate.var_5fc9666ddf44b5a0 ) && isdefined( level.rx_xf_candidate.var_5fc9666ddf44b5a0.var_9a6c71ddc479ec9f ) )
        {
            level.rx_xf_points = namespace_60b3bdcc70f79fc6::function_4129ebc30c6186ec( level.rx_xf_candidate.var_5fc9666ddf44b5a0.var_9a6c71ddc479ec9f, "targetname" );
            if ( isdefined( level.rx_xf_points ) && level.rx_xf_points.size >= 4 )
            {
                level.rx_xf_source = level.rx_xf_candidate;
                return;
            }
        }
        level.rx_xf_i++;
    }
}

function rx_exfil_interact_marker()
{
    level.rx_xf_delta = level.rx_xf.angles[ 1 ] - level.rx_xf_source.angles[ 1 ];
    level.rx_xf_rot = anglestoforward( ( 0, level.rx_xf_delta, 0 ) );
    level.rx_xf_offset = level.rx_xf_source.var_b03fab8f4be015ad.origin - level.rx_xf_source.origin;
    level.rx_xf.var_b03fab8f4be015ad = spawnstruct();
    level.rx_xf.var_b03fab8f4be015ad.origin = level.rx_xf.origin + ( level.rx_xf_offset[ 0 ] * level.rx_xf_rot[ 0 ] - level.rx_xf_offset[ 1 ] * level.rx_xf_rot[ 1 ], level.rx_xf_offset[ 0 ] * level.rx_xf_rot[ 1 ] + level.rx_xf_offset[ 1 ] * level.rx_xf_rot[ 0 ], level.rx_xf_offset[ 2 ] );
    level.rx_xf.var_b03fab8f4be015ad.angles = ( 0, level.rx_xf_delta, 0 );
    if ( isdefined( level.rx_xf_source.var_b03fab8f4be015ad.angles ) )
        level.rx_xf.var_b03fab8f4be015ad.angles = level.rx_xf_source.var_b03fab8f4be015ad.angles + ( 0, level.rx_xf_delta, 0 );
}

// 0.6.4: no exfil during a boss fight (user: "lets make it so the exfil
// doesnt show on boss rounds"). Rex's own boss fight, the Warden's
// (script_208c0afde0bb6ec function_780ddb41e796b027), clears the game's
// exfil-available flag at its start; its ending sets it again
// (function_78f9d6116fa25d95). The game's exfil
// window (script_789c50e394f0bf40 function_21a86762c018a414) waits for that
// flag before it shows, and takes its icon down while the flag is clear. This
// clears it while ra_boss_fight_on() is true and sets it again when the fight
// is over. Only a flag this cleared is set again, and nothing is done while an
// exfil is under way.
function ra_exfil_boss_watch()
{
    level endon( #"game_ended" );
    level.ra_xb_held = 0;
    level.ra_xb_n = 0;
    nengine_store_set( "rex_arena", "exfil_boss", "waiting" );
    while ( true )
    {
        wait 0.5;
        level.ra_xb_fight = ra_boss_fight_on();
        level.ra_xb_round = isdefined( level.var_6781718da4f78d1c ) && isdefined( level.var_6781718da4f78d1c.roundnumber ) ? level.var_6781718da4f78d1c.roundnumber : -1;
        if ( level.ra_xb_fight && !level.ra_xb_held )
        {
            if ( isdefined( level.var_d59cf14644e9665e ) && isdefined( level.var_d59cf14644e9665e.var_d867cc41c15a2fd1 ) )
                continue;
            if ( !level namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( "rbz_allow_exfil" ) )
                continue;
            level namespace_60b3bdcc70f79fc6::function_bb43e9471feff54e( "rbz_allow_exfil" );
            level.ra_xb_held = 1;
            level.ra_xb_n++;
            nengine_store_set( "rex_arena", "exfil_boss", "boss fight " + level.ra_xb_n + " (round " + level.ra_xb_round + "): exfil off" );
            nengine_store_save( "rex_arena", "runtime" );
        }
        else if ( !level.ra_xb_fight && level.ra_xb_held )
        {
            level namespace_60b3bdcc70f79fc6::function_36488e0e5a90d20f( "rbz_allow_exfil" );
            level.ra_xb_held = 0;
            nengine_store_set( "rex_arena", "exfil_boss", "boss fight " + level.ra_xb_n + " over (round " + level.ra_xb_round + "): exfil on again" );
            nengine_store_save( "rex_arena", "runtime" );
        }
    }
}

function rx_exfil_success( params, ignored )
{
    if ( !ra_selected() || istrue( level.rx_xfe_started ) || !isdefined( params ) || !function_cfebf1a31085d52b( params ) || !isdefined( params.var_957e9d25e3f9e03 ) || !function_58736ce92359fa07( params.var_957e9d25e3f9e03 ) )
        return;
    level.rx_xfe_players = params.var_957e9d25e3f9e03;
    level.rx_xfe_i = 0;
    while ( level.rx_xfe_i < level.rx_xfe_players.size )
    {
        level.rx_xfe_player = level.rx_xfe_players[ level.rx_xfe_i ];
        if ( isdefined( level.rx_xfe_player ) && function_503f9a7fd00943c7( level.rx_xfe_player ) && level.rx_xfe_player function_b36623eefe0028c8() && istrue( level.rx_xfe_player.var_1a98782093ca2c08 ) && istrue( level.rx_xfe_player.var_472e2d036e427d3b ) )
        {
            level.rx_xfe_host = level.rx_xfe_player;
            level.rx_xfe_started = 1;
            nengine_store_set( "rex_arena", "exfil_end", "success_host_seen" );
            nengine_store_save( "rex_arena", "runtime" );
            level thread rx_exfil_end_watch();
            return;
        }
        level.rx_xfe_i++;
    }
}

function rx_exfil_native_ending()
{
    return istrue( level.var_9ff6e401c5578760 ) || istrue( level.var_a725b8d28bb8c67e ) || istrue( level.var_e3805050a2c5f924 ) || istrue( level.var_c5c2570873b080b2 ) || istrue( level.var_41e82ca9c2b4c55a );
}

function rx_exfil_end_context()
{
    if ( !ra_selected() || !isdefined( game[ "state" ] ) || game[ "state" ] != "playing" || !isdefined( level.var_dfeae4b8b3d59217 ) || level.var_dfeae4b8b3d59217 != "zm_sat_scarab" || !isdefined( level.var_7ebad24685cd9f8c ) || !isdefined( level.var_7ebad24685cd9f8c.var_53486d8d1bcaeac7 ) )
        return 0;
    if ( level.var_7ebad24685cd9f8c.var_53486d8d1bcaeac7 != "zm_rb_survival" && level.var_7ebad24685cd9f8c.var_53486d8d1bcaeac7 != "zm_rb_r_mod_survival" )
        return 0;
    if ( isdefined( level.var_61515efa4249e355 ) || isdefined( level.var_519fe94beba8d651 ) )
        return 0;
    level.rx_xfe_post_setting = function_8d35635fa0f5f852( "commonOption", "postGameExfil" );
    if ( !isdefined( level.rx_xfe_post_setting ) || istrue( level.rx_xfe_post_setting ) || !isdefined( level.postGameExfil ) || istrue( level.postGameExfil ) )
        return 0;
    return 1;
}

function rx_exfil_end_host_valid()
{
    if ( !isdefined( level.rx_xfe_host ) || !function_503f9a7fd00943c7( level.rx_xfe_host ) || istrue( level.rx_xfe_host.var_176b6ae22ca10468 ) || !level.rx_xfe_host function_b36623eefe0028c8() || !function_52d4872ae95d8bb7( level.rx_xfe_host ) )
        return 0;
    return level.rx_xfe_host.var_948fe687565941e7 == "playing" && istrue( level.rx_xfe_host.var_1a98782093ca2c08 ) && istrue( level.rx_xfe_host.var_472e2d036e427d3b );
}

function rx_exfil_end_solo()
{
    return isdefined( level.var_10f4ff41c4b7f0ac ) && function_58736ce92359fa07( level.var_10f4ff41c4b7f0ac ) && level.var_10f4ff41c4b7f0ac.size == 1 && level.var_10f4ff41c4b7f0ac[ 0 ] == level.rx_xfe_host;
}

function rx_exfil_end_presented()
{
    return istrue( level.rx_xfe_host.var_3417dc9429b05c62 ) && level.rx_xfe_host function_939eb64accd1e612( "post_game_state" ) == 1 && level.rx_xfe_host function_939eb64accd1e612( "ui_dmz_extract_successful" ) == 1 && level.rx_xfe_host function_939eb64accd1e612( "ui_br_squad_eliminated_active" ) == 1;
}

function rx_exfil_end_watch()
{
    level endon( #"game_ended" );
    level endon( #"hash_8ae9b61daf6f8f94" );
    level.rx_xfe_ticks = 0;
    while ( level.rx_xfe_ticks < 120 )
    {
        if ( rx_exfil_native_ending() )
        {
            nengine_store_set( "rex_arena", "exfil_end", "native_ending_already_started" );
            nengine_store_save( "rex_arena", "runtime" );
            return;
        }
        if ( !rx_exfil_end_context() || !rx_exfil_end_host_valid() )
        {
            nengine_store_set( "rex_arena", "exfil_end", "context_or_host_not_eligible" );
            nengine_store_set( "rex_arena", "exfil_end_game_state", isdefined( game[ "state" ] ) ? game[ "state" ] : "undefined" );
            nengine_store_set( "rex_arena", "exfil_end_poi", isdefined( level.var_a76045f3136660f9 ) ? level.var_a76045f3136660f9 : "undefined" );
            nengine_store_set( "rex_arena", "exfil_end_post_setting", isdefined( level.rx_xfe_post_setting ) ? level.rx_xfe_post_setting : "undefined" );
            nengine_store_set( "rex_arena", "exfil_end_post_level", isdefined( level.postGameExfil ) ? level.postGameExfil : "undefined" );
            nengine_store_save( "rex_arena", "runtime" );
            return;
        }
        if ( !rx_exfil_end_solo() )
        {
            nengine_store_set( "rex_arena", "exfil_end", "not_confirmed_solo" );
            nengine_store_save( "rex_arena", "runtime" );
            return;
        }
        if ( rx_exfil_end_presented() )
        {
            wait 1.75;
            if ( rx_exfil_native_ending() || !rx_exfil_end_context() || !rx_exfil_end_host_valid() || !rx_exfil_end_solo() || !rx_exfil_end_presented() )
            {
                nengine_store_set( "rex_arena", "exfil_end", "state_changed_during_presentation" );
                nengine_store_save( "rex_arena", "runtime" );
                return;
            }
            if ( !isdefined( game[ "end_reason" ] ) || !isdefined( game[ "end_reason" ][ "objective_completed" ] ) )
            {
                nengine_store_set( "rex_arena", "exfil_end", "native_end_reason_missing" );
                nengine_store_save( "rex_arena", "runtime" );
                return;
            }
            level.rx_xfe_winner = function_cf1241c266463447( @"hash_aea3ac32a07685ba", "allies" );
            if ( !isdefined( level.rx_xfe_winner ) || level.rx_xfe_winner == "" )
            {
                nengine_store_set( "rex_arena", "exfil_end", "native_winner_missing" );
                nengine_store_save( "rex_arena", "runtime" );
                return;
            }
            nengine_store_set( "rex_arena", "exfil_end", "requesting_native_endgame" );
            nengine_store_save( "rex_arena", "runtime" );
            // The native ending emits game_ended before finishing. Run it
            // on its own thread so this watcher's endon cannot abort it.
            level thread namespace_2c0a06b7d96890b6::function_61515efa4249e355( level.rx_xfe_winner, game[ "end_reason" ][ "objective_completed" ] );
            return;
        }
        wait 0.25;
        level.rx_xfe_ticks++;
    }
    nengine_store_set( "rex_arena", "exfil_end", "presentation_timeout" );
    nengine_store_save( "rex_arena", "runtime" );
}

function rx_gobblegum_manager()
{
    level endon( #"game_ended" );
    if ( !ra_selected() )
        return;
    level.rx_gum_wait = 0;
    while ( !isdefined( level.var_e0910c7bd4aab6fc ) && level.rx_gum_wait < 200 )
    {
        wait 0.1;
        level.rx_gum_wait++;
    }
    if ( !isdefined( level.var_e0910c7bd4aab6fc ) )
    {
        nengine_store_set( "rex_arena", "gobblegum", "native_system_not_ready" );
        nengine_store_save( "rex_arena", "runtime" );
        return;
    }
    // 0.4.19: 0.4.13 and 0.4.18 built the machine before the game's own start
    // gate and before the game's own machines existed (it was first in the
    // list), and both matches went black. Wait for the same start flag the
    // drop waits for, and for the game to have listed its own machines. The
    // drop starts at least 2 seconds after that flag, so the machine is still
    // there before the player lands. After 60 seconds it is built regardless.
    level.rx_gum_gate = 0;
    while ( level.rx_gum_gate < 600 &&
        ( !level namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( "begin_round_logic" ) ||
          ( level.var_e0910c7bd4aab6fc.size == 0 && level.rx_gum_gate < 300 ) ) )
    {
        wait 0.1;
        level.rx_gum_gate++;
    }
    nengine_store_set( "rex_arena", "gobblegum_gate_ticks", level.rx_gum_gate );
    nengine_store_set( "rex_arena", "gobblegum_gate_flag", level namespace_60b3bdcc70f79fc6::function_f0bb112fe637e41c( "begin_round_logic" ) ? 1 : 0 );

    // Never put a second machine on the marked spot (for example when the
    // arena_gum World Builder save is loaded): report it and build nothing.
    level.rx_gum_i = 0;
    while ( level.rx_gum_i < level.var_e0910c7bd4aab6fc.size )
    {
        level.rx_gum_item = level.var_e0910c7bd4aab6fc[ level.rx_gum_i ];
        if ( isdefined( level.rx_gum_item ) && isdefined( level.rx_gum_item.origin ) &&
            function_5650190c0059a137( level.rx_gum_item.origin - ( 29415, -25308, 2071 ) ) < 64 )
        {
            nengine_store_set( "rex_arena", "gobblegum", "spot_already_has_a_machine" );
            nengine_store_set( "rex_arena", "gobblegum_source", "not_built" );
            nengine_store_save( "rex_arena", "runtime" );
            return;
        }
        level.rx_gum_i++;
    }
    nengine_store_set( "rex_arena", "gobblegum_native_before", level.var_e0910c7bd4aab6fc.size );
    level.rx_gum = spawnstruct();
    // 0.5.5: 25 units forward (along yaw 266, toward the arena) of the World
    // Builder mark (29415, -25308, 2071), which put the machine half inside
    // the wall behind it. 0.5.4's 40 units was a little too far out.
    level.rx_gum.origin = ( 29413.3, -25332.9, 2071 );
    level.rx_gum.angles = ( 0, 266, 0 );
    // The game's own per-location call, made directly as the game makes it.
    level.rx_gum namespace_adb04aeb7ba103ef::function_9a3e81eb8357ad32( level.rx_gum );
    nengine_store_set( "rex_arena", "gobblegum_source", "native_location" );
    nengine_store_set( "rex_arena", "gobblegum_ms_after_landing", isdefined( level.ra_land_t ) ? function_83bf4b34fbbe124b() - level.ra_land_t : "before_landing" );
    nengine_store_set( "rex_arena", "gobblegum_native_wait_ticks", level.rx_gum_wait );
    nengine_store_set( "rex_arena", "gobblegum_native_after", level.var_e0910c7bd4aab6fc.size );
    nengine_store_set( "rex_arena", "gobblegum_clips", "none_native_model_only" );
    level.rx_gum_wait = 0;
    while ( level.rx_gum_wait < 200 &&
        ( !isdefined( level.rx_gum.var_31b963920e4331f3 ) ||
          !isdefined( level.rx_gum.var_31b963920e4331f3.var_4cf63ec91b753a3c ) ) )
    {
        waitframe();
        level.rx_gum_wait++;
    }
    nengine_store_set( "rex_arena", "gobblegum", isdefined( level.rx_gum.var_31b963920e4331f3 ) ? "model_created" : "model_missing" );
    if ( isdefined( level.rx_gum.var_31b963920e4331f3 ) )
        nengine_store_set( "rex_arena", "gobblegum_interaction", isdefined( level.rx_gum.var_31b963920e4331f3.var_4cf63ec91b753a3c ) ? "created" : "missing" );
    nengine_store_set( "rex_arena", "gobblegum_position", level.rx_gum.origin );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.3: records only. The user saw a second inducer lantern appear when the
// arena one was turned on. Records where the game's inducer was before this
// mod moved it, where its model and prompt are, and, each time it turns on
// (first 3), those positions again, whether the game's inducer and model are
// still the ones this mod set up, and each player's position.
// Own level thread: a fault here stops only this.
function rx_rampage_watch()
{
    level endon( #"game_ended" );
    if ( !ra_selected() )
        return;
    nengine_store_set( "rex_arena", "rampage_home", isdefined( level.rx_rp_home ) ? level.rx_rp_home : "none" );
    nengine_store_set( "rex_arena", "rampage_setup", rx_rampage_where() );
    nengine_store_save( "rex_arena", "runtime" );
    level.rx_rpw_n = 0;
    level.rx_rpw_was = 0;
    while ( isdefined( level.var_f7b4ed545fb97f9b ) )
    {
        level.rx_rpw_on = istrue( level.var_f7b4ed545fb97f9b.var_e06b5c72f9591a0f );
        if ( level.rx_rpw_on && !level.rx_rpw_was )
        {
            level.rx_rpw_n++;
            if ( level.rx_rpw_n <= 3 )
            {
                level.rx_rpw_text = "round " + ( isdefined( level.var_6781718da4f78d1c ) && isdefined( level.var_6781718da4f78d1c.roundnumber ) ? level.var_6781718da4f78d1c.roundnumber : -1 ) + ": " + rx_rampage_where();
                level.rx_rpw_i = 0;
                while ( isdefined( level.var_10f4ff41c4b7f0ac ) && level.rx_rpw_i < level.var_10f4ff41c4b7f0ac.size )
                {
                    if ( isdefined( level.var_10f4ff41c4b7f0ac[ level.rx_rpw_i ] ) )
                        level.rx_rpw_text = level.rx_rpw_text + "; player " + level.rx_rpw_i + " at " + level.var_10f4ff41c4b7f0ac[ level.rx_rpw_i ].origin;
                    level.rx_rpw_i++;
                }
                nengine_store_set( "rex_arena", "rampage_on_" + level.rx_rpw_n, level.rx_rpw_text );
                nengine_store_save( "rex_arena", "runtime" );
            }
        }
        level.rx_rpw_was = level.rx_rpw_on;
        wait 0.25;
    }
    nengine_store_set( "rex_arena", "rampage_watch", "the game's inducer is gone" );
    nengine_store_save( "rex_arena", "runtime" );
}

function rx_rampage_where()
{
    if ( !isdefined( level.var_f7b4ed545fb97f9b ) )
        return "no inducer";
    level.rx_rpw_where = "inducer " + ( isdefined( level.rx_rp ) && level.var_f7b4ed545fb97f9b == level.rx_rp ? "is this mod's" : "is not this mod's" );
    level.rx_rpw_where = level.rx_rpw_where + ", struct at " + ( isdefined( level.var_f7b4ed545fb97f9b.origin ) ? level.var_f7b4ed545fb97f9b.origin : "none" );
    if ( isdefined( level.var_f7b4ed545fb97f9b.var_9dc14f3b2f869aa5 ) )
        level.rx_rpw_where = level.rx_rpw_where + ", model at " + level.var_f7b4ed545fb97f9b.var_9dc14f3b2f869aa5.origin + ( isdefined( level.rx_rp_new ) && level.var_f7b4ed545fb97f9b.var_9dc14f3b2f869aa5 == level.rx_rp_new ? " (this mod's)" : " (not this mod's)" );
    else
        level.rx_rpw_where = level.rx_rpw_where + ", no model";
    if ( isdefined( level.var_f7b4ed545fb97f9b.var_4cf63ec91b753a3c ) )
        level.rx_rpw_where = level.rx_rpw_where + ", prompt at " + level.var_f7b4ed545fb97f9b.var_4cf63ec91b753a3c.origin;
    else
        level.rx_rpw_where = level.rx_rpw_where + ", no prompt";
    level.rx_rpw_where = level.rx_rpw_where + ", old model " + ( isdefined( level.rx_rp_old ) ? "still defined" : "gone" );
    return level.rx_rpw_where;
}

// 0.5.6: collision for the Mystery Box and the exfil booth. Rex has no clip
// brush for either, so each is a block filled with copies of one of the map's
// own brushes: the smallest task_col (T.E.D.D. chest collision), measured in
// game with getpointinbounds. Copies are made the game's way
// (clonebrushmodeltoscriptmodel, solid, disconnectpaths) and turned to the
// machine's yaw. Block sizes are first estimates; everything is recorded.
function rx_clip_donor()
{
    if ( isdefined( level.rx_cd_brush ) )
        return 1;
    level.rx_cd_list = getentarray( "task_col", "targetname" );
    level.rx_cd_text = "";
    level.rx_cd_best = -1;
    level.rx_cd_i = 0;
    while ( level.rx_cd_i < level.rx_cd_list.size )
    {
        level.rx_cd_e = level.rx_cd_list[ level.rx_cd_i ];
        if ( isdefined( level.rx_cd_e ) && isdefined( level.rx_cd_e.classname ) && level.rx_cd_e.classname == "script_brushmodel" && isdefined( level.rx_cd_e.origin ) )
        {
            level.rx_cd_mid = level.rx_cd_e getpointinbounds( 0, 0, 0 );
            level.rx_cd_top = level.rx_cd_e getpointinbounds( 1, 1, 1 );
            level.rx_cd_h = level.rx_cd_top - level.rx_cd_mid;
            level.rx_cd_h = ( abs( level.rx_cd_h[ 0 ] ), abs( level.rx_cd_h[ 1 ] ), abs( level.rx_cd_h[ 2 ] ) );
            level.rx_cd_text = level.rx_cd_text + int( level.rx_cd_h[ 0 ] * 2 ) + "x" + int( level.rx_cd_h[ 1 ] * 2 ) + "x" + int( level.rx_cd_h[ 2 ] * 2 ) + " ";
            level.rx_cd_v = level.rx_cd_h[ 0 ] * level.rx_cd_h[ 1 ] * level.rx_cd_h[ 2 ];
            if ( level.rx_cd_h[ 0 ] >= 4 && level.rx_cd_h[ 1 ] >= 4 && level.rx_cd_h[ 2 ] >= 4 && ( level.rx_cd_best < 0 || level.rx_cd_v < level.rx_cd_best ) )
            {
                level.rx_cd_best = level.rx_cd_v;
                level.rx_cd_brush = level.rx_cd_e;
                level.rx_cd_half = level.rx_cd_h;
                level.rx_cd_off = level.rx_cd_mid - level.rx_cd_e.origin;
            }
        }
        level.rx_cd_i++;
    }
    nengine_store_set( "rex_arena", "clip_donor_sizes", level.rx_cd_list.size + " task_col: " + level.rx_cd_text );
    if ( !isdefined( level.rx_cd_brush ) )
    {
        nengine_store_set( "rex_arena", "clip_donor", "none usable" );
        nengine_store_save( "rex_arena", "runtime" );
        return 0;
    }
    nengine_store_set( "rex_arena", "clip_donor", "task_col at " + level.rx_cd_brush.origin + ", size " + level.rx_cd_half * 2 + ", centre offset " + level.rx_cd_off );
    nengine_store_save( "rex_arena", "runtime" );
    return 1;
}

// Fills a block of full size ( fx forward, fy across, fz up ) centred on
// centre, turned to yaw, with copies of the donor. Returns the copies made.
function rx_clip_block( centre, yaw, fx, fy, fz )
{
    level.rx_cb_made = [];
    if ( !rx_clip_donor() )
        return level.rx_cb_made;
    level.rx_cb_size = ( fx, fy, fz );
    level.rx_cb_n = [];
    level.rx_cb_k = 0;
    while ( level.rx_cb_k < 3 )
    {
        level.rx_cb_d = level.rx_cd_half[ level.rx_cb_k ] * 2;
        level.rx_cb_n[ level.rx_cb_k ] = int( level.rx_cb_size[ level.rx_cb_k ] / level.rx_cb_d );
        if ( level.rx_cb_n[ level.rx_cb_k ] * level.rx_cb_d < level.rx_cb_size[ level.rx_cb_k ] )
            level.rx_cb_n[ level.rx_cb_k ]++;
        if ( level.rx_cb_n[ level.rx_cb_k ] < 1 )
            level.rx_cb_n[ level.rx_cb_k ] = 1;
        level.rx_cb_k++;
    }
    level.rx_cb_total = level.rx_cb_n[ 0 ] * level.rx_cb_n[ 1 ] * level.rx_cb_n[ 2 ];
    if ( level.rx_cb_total > 64 )
        return level.rx_cb_made;
    level.rx_cb_f = anglestoforward( ( 0, yaw, 0 ) );
    level.rx_cb_ix = 0;
    while ( level.rx_cb_ix < level.rx_cb_n[ 0 ] )
    {
        level.rx_cb_iy = 0;
        while ( level.rx_cb_iy < level.rx_cb_n[ 1 ] )
        {
            level.rx_cb_iz = 0;
            while ( level.rx_cb_iz < level.rx_cb_n[ 2 ] )
            {
                level.rx_cb_lx = rx_clip_axis( 0, level.rx_cb_ix );
                level.rx_cb_ly = rx_clip_axis( 1, level.rx_cb_iy );
                level.rx_cb_lz = rx_clip_axis( 2, level.rx_cb_iz );
                level.rx_cb_p = centre + ( level.rx_cb_lx * level.rx_cb_f[ 0 ] - level.rx_cb_ly * level.rx_cb_f[ 1 ], level.rx_cb_lx * level.rx_cb_f[ 1 ] + level.rx_cb_ly * level.rx_cb_f[ 0 ], level.rx_cb_lz );
                level.rx_cb_o = level.rx_cb_p - ( level.rx_cd_off[ 0 ] * level.rx_cb_f[ 0 ] - level.rx_cd_off[ 1 ] * level.rx_cb_f[ 1 ], level.rx_cd_off[ 0 ] * level.rx_cb_f[ 1 ] + level.rx_cd_off[ 1 ] * level.rx_cb_f[ 0 ], level.rx_cd_off[ 2 ] );
                level.rx_cb_m = spawn( "script_model", level.rx_cb_o );
                if ( isdefined( level.rx_cb_m ) )
                {
                    level.rx_cb_m.angles = ( 0, yaw, 0 );
                    level.rx_cb_m clonebrushmodeltoscriptmodel( level.rx_cd_brush );
                    level.rx_cb_m solid();
                    level.rx_cb_m disconnectpaths();
                    level.rx_cb_made[ level.rx_cb_made.size ] = level.rx_cb_m;
                }
                level.rx_cb_iz++;
            }
            level.rx_cb_iy++;
        }
        level.rx_cb_ix++;
    }
    return level.rx_cb_made;
}

// Centre of copy i along axis k: spread evenly so the copies span the block
// edge to edge (a donor larger than the block sits in its middle).
function rx_clip_axis( k, i )
{
    level.rx_ca_d = level.rx_cd_half[ k ] * 2;
    if ( level.rx_cb_n[ k ] <= 1 || level.rx_ca_d >= level.rx_cb_size[ k ] )
        return 0;
    return 0 - level.rx_cb_size[ k ] / 2 + level.rx_ca_d / 2 + i * ( level.rx_cb_size[ k ] - level.rx_ca_d ) / ( level.rx_cb_n[ k ] - 1 );
}

function rx_exfil_clip()
{
    level endon( #"game_ended" );
    if ( !ra_selected() || !isdefined( level.rx_xf ) || isdefined( level.rx_exfil_clips ) )
        return;
    level.rx_exfil_clips = rx_clip_block( level.rx_xf.origin + ( 0, 0, 48 ), level.rx_xf.angles[ 1 ], 40, 40, 96 );
    nengine_store_set( "rex_arena", "exfil_clips", level.rx_exfil_clips.size + " copies (" + level.rx_cb_n[ 0 ] + " x " + level.rx_cb_n[ 1 ] + " x " + level.rx_cb_n[ 2 ] + "), block 40 x 40 x 96 at " + level.rx_xf.origin + " yaw " + level.rx_xf.angles[ 1 ] );
    nengine_store_save( "rex_arena", "runtime" );
}

// 0.5.14: Mystery Box collision, a solid column on the platform's base from
// the floor up (as the user drew it; as Ashes Arena's map clip). The box runs
// along world Y (the model's forward at yaw 90; the user's logged corners).
// Base from the box model (sat_zm_mystery_box_fxanim): 120 along Y, 48 along
// X with the front edge on the arena side (west, -X), bottom 9 below the box
// origin (the floor). Tiled from copies of one of Rex's invisible clip
// brushes, measured here; copies overlap inside so the ends and front are
// flush; extra depth goes behind (east). Each candidate is checked with
// traces at the front and both ends (rx_box_col_probe); one that leaves a
// step, a slant or a gap is deleted. Nothing is made if none passes.
// Own level thread: a fault here stops only this.
function rx_box_col()
{
    level endon( #"game_ended" );
    if ( !ra_selected() || !isdefined( level.rx_bx ) || isdefined( level.rx_bxc ) )
        return;
    level.rx_bxc_xf = level.rx_bx.origin[ 0 ] - 23.8;
    level.rx_bxc_ys = level.rx_bx.origin[ 1 ] - 60.07;
    level.rx_bxc_z0 = level.rx_bx.origin[ 2 ] - 9;
    level.rx_bxc_names = [ "task_col", "m_pltfm_plyclip", "wb_rh_clip", "movplat_rh_clip", "vertplat_rh_clip", "perk_machine_choice_clip", "script_brushmodel_pillar_clip", "forge_arch_clip", "pq_forge_platform_clip", "qo_pillar_platform_clip", "pq_forge_end_clip", "elevator_clip", "rh_col_coffin" ];
    level.rx_bxc_cand = [];
    level.rx_bxc_seen = 0;
    level.rx_bxc_tall = 0;
    level.rx_bxc_k = 0;
    while ( level.rx_bxc_k < level.rx_bxc_names.size )
    {
        level.rx_bxc_list = getentarray( level.rx_bxc_names[ level.rx_bxc_k ], "targetname" );
        level.rx_bxc_i = 0;
        while ( level.rx_bxc_i < level.rx_bxc_list.size )
        {
            level.rx_bxc_e = level.rx_bxc_list[ level.rx_bxc_i ];
            if ( isdefined( level.rx_bxc_e ) && isdefined( level.rx_bxc_e.classname ) && level.rx_bxc_e.classname == "script_brushmodel" && isdefined( level.rx_bxc_e.origin ) && ( !isdefined( level.rx_bxc_e.angles ) || level.rx_bxc_e.angles == ( 0, 0, 0 ) ) )
            {
                level.rx_bxc_seen++;
                level.rx_bxc_mid = level.rx_bxc_e getpointinbounds( 0, 0, 0 );
                level.rx_bxc_top = level.rx_bxc_e getpointinbounds( 1, 1, 1 );
                level.rx_bxc_h = level.rx_bxc_top - level.rx_bxc_mid;
                level.rx_bxc_h = ( abs( level.rx_bxc_h[ 0 ] ), abs( level.rx_bxc_h[ 1 ] ), abs( level.rx_bxc_h[ 2 ] ) );
                if ( level.rx_bxc_h[ 0 ] >= 2 && level.rx_bxc_h[ 1 ] >= 2 && level.rx_bxc_h[ 2 ] * 2 >= 56 && level.rx_bxc_h[ 2 ] * 2 <= 400 )
                {
                    level.rx_bxc_tall++;
                    level.rx_bxc_r = 0;
                    while ( level.rx_bxc_r < 2 )
                    {
                        // a: length along the box (world Y), b: depth (world X)
                        level.rx_bxc_a = level.rx_bxc_r == 0 ? level.rx_bxc_h[ 1 ] * 2 : level.rx_bxc_h[ 0 ] * 2;
                        level.rx_bxc_b = level.rx_bxc_r == 0 ? level.rx_bxc_h[ 0 ] * 2 : level.rx_bxc_h[ 1 ] * 2;
                        level.rx_bxc_s = rx_box_col_score( level.rx_bxc_a, level.rx_bxc_b );
                        if ( level.rx_bxc_s >= 0 )
                        {
                            level.rx_bxc_c = spawnstruct();
                            level.rx_bxc_c.brush = level.rx_bxc_e;
                            level.rx_bxc_c.name = level.rx_bxc_names[ level.rx_bxc_k ];
                            level.rx_bxc_c.half = level.rx_bxc_h;
                            level.rx_bxc_c.off = level.rx_bxc_mid - level.rx_bxc_e.origin;
                            level.rx_bxc_c.rot = level.rx_bxc_r * 90;
                            level.rx_bxc_c.ta = level.rx_bxc_a;
                            level.rx_bxc_c.tb = level.rx_bxc_b;
                            level.rx_bxc_c.score = level.rx_bxc_s;
                            level.rx_bxc_cand[ level.rx_bxc_cand.size ] = level.rx_bxc_c;
                        }
                        level.rx_bxc_r++;
                    }
                }
            }
            level.rx_bxc_i++;
        }
        level.rx_bxc_k++;
    }
    level.rx_bxc_c = undefined;
    level.rx_bxc_e = undefined;
    nengine_store_set( "rex_arena", "box_col_scan", level.rx_bxc_seen + " clip brushes, " + level.rx_bxc_tall + " tall enough, " + level.rx_bxc_cand.size + " fitting candidates" );
    rx_box_col_probe();
    level.rx_bxc_base = level.rx_bxf_n;
    nengine_store_set( "rex_arena", "box_col_probe_before", level.rx_bxf_t );
    nengine_store_save( "rex_arena", "runtime" );
    level.rx_bxc_try = 0;
    while ( level.rx_bxc_try < 8 && !isdefined( level.rx_bxc ) )
    {
        level.rx_bxc_pick = undefined;
        level.rx_bxc_i = 0;
        while ( level.rx_bxc_i < level.rx_bxc_cand.size )
        {
            if ( !istrue( level.rx_bxc_cand[ level.rx_bxc_i ].tried ) && ( !isdefined( level.rx_bxc_pick ) || level.rx_bxc_cand[ level.rx_bxc_i ].score < level.rx_bxc_pick.score ) )
                level.rx_bxc_pick = level.rx_bxc_cand[ level.rx_bxc_i ];
            level.rx_bxc_i++;
        }
        if ( !isdefined( level.rx_bxc_pick ) )
            break;
        level.rx_bxc_pick.tried = 1;
        level.rx_bxc_try++;
        rx_box_col_build( level.rx_bxc_pick );
        waitframe();
        waitframe();
        level.rx_bxc_ok = rx_box_col_ok();
        nengine_store_set( "rex_arena", "box_col_try_" + level.rx_bxc_try, level.rx_bxc_pick.name + " at " + level.rx_bxc_pick.brush.origin + ", size " + level.rx_bxc_pick.half * 2 + ", turned " + level.rx_bxc_pick.rot + ", " + level.rx_bxc_made.size + " copies: " + ( level.rx_bxc_ok ? "faces flush, kept" : "faces not flush, removed" ) + " (front/south/north " + level.rx_bxf_t + ")" );
        nengine_store_save( "rex_arena", "runtime" );
        if ( level.rx_bxc_ok )
        {
            level.rx_bxc = level.rx_bxc_made;
            level.rx_bxc_i = 0;
            while ( level.rx_bxc_i < level.rx_bxc.size )
            {
                level.rx_bxc[ level.rx_bxc_i ] disconnectpaths();
                level.rx_bxc_i++;
            }
            nengine_store_set( "rex_arena", "box_col", level.rx_bxc.size + " copies of " + level.rx_bxc_pick.name + " (" + level.rx_bxc_nl + " along x " + level.rx_bxc_nd + " rows 8 apart), column y " + level.rx_bxc_ys + ".." + ( level.rx_bxc_ys + 120 ) + ", x from " + level.rx_bxc_xf + " (front) back " + ( 40 + level.rx_bxc_pick.tb ) + ", z " + level.rx_bxc_z0 + " up " + level.rx_bxc_pick.half[ 2 ] * 2 );
        }
        else
        {
            level.rx_bxc_i = 0;
            while ( level.rx_bxc_i < level.rx_bxc_made.size )
            {
                level.rx_bxc_made[ level.rx_bxc_i ] delete();
                level.rx_bxc_i++;
            }
            level.rx_bxc_made = [];
            waitframe();
        }
    }
    if ( !isdefined( level.rx_bxc ) )
        nengine_store_set( "rex_arena", "box_col", "no candidate passed (" + level.rx_bxc_try + " tried); no collision made" );
    level.rx_bxc_cand = [];
    level.rx_bxc_pick = undefined;
    nengine_store_save( "rex_arena", "runtime" );
}

// Builds candidate c's copies on the base into level.rx_bxc_made (solid,
// no path change yet). Along Y: from the south end, ends flush. Along X
// (0.5.15): 6 rows, the first with its front on the front edge, each next 8
// further back, so a brush solid only in its front part fills the depth.
function rx_box_col_build( c )
{
    level.rx_bxc_made = [];
    level.rx_bxc_nl = rx_box_col_count( c.ta, 120 );
    level.rx_bxc_nd = 6;
    if ( c.rot == 0 )
        level.rx_bxc_offw = c.off;
    else
        level.rx_bxc_offw = ( 0 - c.off[ 1 ], c.off[ 0 ], c.off[ 2 ] );
    level.rx_bxc_il = 0;
    while ( level.rx_bxc_il < level.rx_bxc_nl )
    {
        if ( level.rx_bxc_nl <= 1 )
            level.rx_bxc_cy = level.rx_bxc_ys + 60;
        else
            level.rx_bxc_cy = level.rx_bxc_ys + c.ta / 2 + level.rx_bxc_il * ( 120 - c.ta ) / ( level.rx_bxc_nl - 1 );
        level.rx_bxc_id = 0;
        while ( level.rx_bxc_id < level.rx_bxc_nd )
        {
            level.rx_bxc_cx = level.rx_bxc_xf + c.tb / 2 + level.rx_bxc_id * 8;
            level.rx_bxc_m = spawn( "script_model", ( level.rx_bxc_cx, level.rx_bxc_cy, level.rx_bxc_z0 + c.half[ 2 ] ) - level.rx_bxc_offw );
            if ( isdefined( level.rx_bxc_m ) )
            {
                level.rx_bxc_m.angles = ( 0, c.rot, 0 );
                level.rx_bxc_m clonebrushmodeltoscriptmodel( c.brush );
                level.rx_bxc_m solid();
                level.rx_bxc_made[ level.rx_bxc_made.size ] = level.rx_bxc_m;
            }
            level.rx_bxc_id++;
        }
        level.rx_bxc_il++;
    }
    level.rx_bxc_m = undefined;
}

// physicstrace from 24 units outside each face toward it (12 past it), 20 and
// 60 up. 0..5 front (west face; 10 in from each end and the middle), 6..9
// south end, 10..13 north end (8 and 40 behind the front edge).
// level.rx_bxf_n holds each hit distance (36 = no hit), level.rx_bxf_t the text.
function rx_box_col_probe()
{
    level.rx_bxf_n = [];
    level.rx_bxf_t = "";
    level.rx_bxf_k = 0;
    while ( level.rx_bxf_k < 14 )
    {
        if ( level.rx_bxf_k < 6 )
        {
            level.rx_bxf_y = level.rx_bxc_ys + 10 + ( level.rx_bxf_k % 3 ) * 50;
            level.rx_bxf_z = level.rx_bxc_z0 + ( level.rx_bxf_k < 3 ? 20 : 60 );
            level.rx_bxf_s = ( level.rx_bxc_xf - 24, level.rx_bxf_y, level.rx_bxf_z );
            level.rx_bxf_e = ( level.rx_bxc_xf + 12, level.rx_bxf_y, level.rx_bxf_z );
        }
        else
        {
            level.rx_bxf_j = ( level.rx_bxf_k - 6 ) % 4;
            level.rx_bxf_x = level.rx_bxc_xf + 8 + ( level.rx_bxf_j % 2 ) * 32;
            level.rx_bxf_z = level.rx_bxc_z0 + ( level.rx_bxf_j < 2 ? 20 : 60 );
            if ( level.rx_bxf_k < 10 )
            {
                level.rx_bxf_s = ( level.rx_bxf_x, level.rx_bxc_ys - 24, level.rx_bxf_z );
                level.rx_bxf_e = ( level.rx_bxf_x, level.rx_bxc_ys + 12, level.rx_bxf_z );
            }
            else
            {
                level.rx_bxf_s = ( level.rx_bxf_x, level.rx_bxc_ys + 144, level.rx_bxf_z );
                level.rx_bxf_e = ( level.rx_bxf_x, level.rx_bxc_ys + 108, level.rx_bxf_z );
            }
        }
        level.rx_bxf_hit = physicstrace( level.rx_bxf_s, level.rx_bxf_e );
        level.rx_bxf_n[ level.rx_bxf_k ] = distance( level.rx_bxf_s, level.rx_bxf_hit );
        level.rx_bxf_t = level.rx_bxf_t + int( level.rx_bxf_n[ level.rx_bxf_k ] * 10 ) / 10 + ( level.rx_bxf_k == 5 || level.rx_bxf_k == 9 ? " / " : level.rx_bxf_k == 13 ? "" : " " );
        level.rx_bxf_k++;
    }
}

// After building: every probe that was clear before must now stop at its
// face (24 +/- 5, 0.5.16); at least 8 probes must count.
function rx_box_col_ok()
{
    rx_box_col_probe();
    level.rx_bxo_n = 0;
    level.rx_bxo_k = 0;
    while ( level.rx_bxo_k < 14 )
    {
        if ( level.rx_bxc_base[ level.rx_bxo_k ] > 35 )
        {
            if ( abs( level.rx_bxf_n[ level.rx_bxo_k ] - 24 ) > 5 )
                return 0;
            level.rx_bxo_n++;
        }
        level.rx_bxo_k++;
    }
    return level.rx_bxo_n >= 8;
}

// How many copies of length size cover span (1 if one is already as long).
function rx_box_col_count( size, span )
{
    if ( size >= span )
        return 1;
    level.rx_bcc_n = int( span / size );
    if ( level.rx_bcc_n * size < span )
        level.rx_bcc_n++;
    return level.rx_bcc_n;
}

// Lower is better; -1 = unusable. a = length along the box (span 120),
// b = depth (span 48). 0.5.15: 6 rows 8 apart reach 40 + b behind the front
// edge. At most 8 past the ends, 60 past the back, 24 copies.
function rx_box_col_score( a, b )
{
    level.rx_bcs_ox = a > 120 ? a - 120 : 0;
    level.rx_bcs_oy = 40 + b > 48 ? 40 + b - 48 : 0;
    level.rx_bcs_n = rx_box_col_count( a, 120 ) * 6;
    if ( level.rx_bcs_n > 24 || level.rx_bcs_ox > 8 || level.rx_bcs_oy > 60 )
        return -1;
    return level.rx_bcs_ox * 4 + level.rx_bcs_oy + level.rx_bcs_n * 0.5;
}
