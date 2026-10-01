# Feel, readability and transitions

Status: **PROPOSED for the lock** (section H of `docs/production/lock.md`). The systems (carry, kite, light, the street's memory, switching) are locked in the design document. This file is how they must feel and how a player finds their way, written because the first playtest found the gameplay "dry", the walk and jump "weird", the cuts "sudden", and a staircase nobody could reach.

## The verbs (locked; no new verbs after the lock)

Move, jump (ledges are grabbed and climbed automatically), crawl, interact (talk, sit, look, use), grab and release, kite (launch, steer, pay out, pull, reel, hook), switch character, notebook. Eight inputs, keyboard and controller, fully remappable (the design document). Every puzzle in ten days is built from these and the puzzle kit (plank, cart, rubble pile, jerrycan, beam, hook).

**Carry rules (locked, with one addition).** Light: body free. Heavy one-hand: run at 0.6, no jump. Two-handed: under 0.5, no jump, no crawl, cannot open doors. Each item has a class per character: a full 20-litre jerrycan is two-handed for Layla and Sami, heavy one-hand for adults, and Karim carries heavy one-hand at full speed (the design document). Layla cannot lift an adult; Teta carries only the bag.

## Feel targets

The feel is Silksong's lesson: the character answers the hand at once, and the animation, not the number, sells weight. Current values are in `game/scripts/player.gd` and `camera_rig.gd`; the slice tunes them with the founder in play.

| Property | Today | Target |
| --- | --- | --- |
| Input to motion | Immediate | Movement starts the same frame; the animation's anticipation never delays control |
| Tuning | F3 overlay (1 Oct) lists every value live; all are `@export` on `player.gd` and `camera_rig.gd` | The founder tunes in play and pastes the numbers back |
| Run speed | 320 px/s | Tune on the laptop; Layla faster than every adult |
| Acceleration and stopping | 4000 px/s² ground, 5400 stopping, 1400 air; skid 0.12 s at half accel when reversing above 0.8 of run speed (1 Oct) | Met: 0.08 s to full speed, 0.06 s to stop; tune by feel |
| Jump | -640 with variable height: releasing while rising multiplies vertical speed by 0.45 (1 Oct) | Rise is 0.65 s at gravity 980; a snappier quarter-second rise needs higher gravity and a shorter jump, decided by the founder in play |
| Coyote time | 0.1 s (1 Oct) | Met |
| Jump buffer | 0.1 s (1 Oct) | Met; a buffered jump released before landing is not cut |
| Landing | Impact-scaled squash (0.30 at 900 px/s; ×1.3 heavy, ×1.5 two-handed) and a knees-give pose on the rig; `landed` signal (1 Oct) | Dust on sand still to do; the sprite rig will carry a drawn landing frame |
| Ledge climb | None | Automatic grab of ledges at chest height and below, with a climb animation |
| Crawl | Hold down | Enters and leaves by animation; never stuck under a low ceiling |
| Camera | Smoothed look-ahead 140 over 0.4 s, returns to centre when idle; 120 px edge clamp; zoom 1.3; kite pull-out (1 Oct) | Met for leading and clamping; sit-spot hold to confirm in the slice |
| Kite | Physics on a string in the wind field | Readable tension (string sag and sound), gusts shown by dust at Layla's feet before they arrive, cannot be lost on Day 1 and Day 10 |

A debug overlay exposes gravity, jump, speeds, carry factors, kite drag and wind so the founder can tune in play and paste the numbers back (the design document).

## Readability: the player always knows where to go

Playtest 1 lost the founder twice: nothing on the beach said where Sami was, and the stairs could not be reached. Rules for every scene:

1. **The world points, not the HUD.** No objective text after the first minute. Direction comes from a character calling out, a kite drifting ahead, light spilling from a door, birds, a path of footprints, a neighbour pointing, sound from off screen. The only on-screen prompts are small input icons at the moment they apply.
2. **Three-second rule.** A player who stops anywhere can tell within three seconds which way is forward and what is interactive.
3. **Affordances look like what they are.** Stairs look like stairs and every flight's foot is reachable on foot; climbable ledges share one visual edge treatment; crawl gaps are dark mouths at knee height; interactive objects catch a thin warm rim of light.
4. **Screen right is where the day is going** (`docs/story/world.md`).
5. **No dead ends, no soft locks.** Every route a player must take is walked by a bot with real physics (teleports only to set up a test). A reset input and a checkpoint seconds back are always there.
6. **Teach before you test.** Every timed moment is rehearsed earlier in the same day with nothing at stake (the design document's intensity rules).

## Scene design: why the first playable felt dry

Each scene in the first playable was one mechanic with a hint line. Every scene in the slice must have:

- **A want** (Layla wants something the player can see: the tail, Sami's kite, the roof).
- **An obstacle** built from the verbs.
- **A turn** (something changes: the string snaps, the power comes on, Teta asks).
- **A payoff** the player feels (the count reaches thirty, the washing back on the line, Teta's smile).
- **People.** Somebody reacts to what the player did, in a line or a gesture.
- **Something optional to find.** A look-at, a neighbour's line, an act of care for the notebook.

**Joy is played, not watched** (the design document): the count, the kite run, football, the jerrycan race, the dabke.

**Look-ats.** Like Life is Strange, objects Layla can look at give one short handwritten thought. They are optional, never required, and every home, shop and roof has a few.

**Barks never stop movement.** Lines spoken as Layla passes play while she keeps moving; only a sit spot or a conversation the player starts holds her.

**Conversation.** No dialogue trees. At most one or two moments a day where the player chooses how Layla answers (two options, never timed, recorded in the notebook, echoed once later). Lines advance on input or wait; timing never gates reading (the design document).

## Transitions: why the cuts felt sudden

The first playable joined separate scenes with fades to black. From now on:

1. **A day is one continuous walk** through connected spaces. The camera never cuts in the middle of a walk.
2. **Time moves on the adhan.** A phase change begins with the adhan; the light changes while it plays, and play continues under it. The adhan is never cut or faded mid-phrase to change a scene (the scholar confirms how it may be used; lock E-05). The camera move varies (up to the sky, out to the sea, along a roofline, holding on a face) so it never becomes wallpaper. No black.
3. **Sound leads.** The next scene's sound starts a moment before its picture; the last scene's sound tails a moment after.
4. **Endings breathe.** A beat holds for one or two seconds after it resolves before anything new starts.
5. **Black is for the day's edges only**: the day's start (after the chapter card), and the end of Day 7.
6. **Cinematics never take control** for more than three seconds (the title card); letterbox bars signal them (the design document).

## UI text

Arabic above, English below, from the keyed CSV. Box narrow and low, never covering Layla; no orphaned words (non-breaking spaces in names such as "أبو أحمد" and "Abu Ahmad's"); a thin tatreez stitch line along the top of the box. Speaker names in the warm accent colour. Subtitle size and background options (the design document's accessibility list).
