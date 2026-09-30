# Day 1: The kites. Script for the vertical slice

Status: **PROPOSED for the story lock.** This is the scene-by-scene script of the design document's Day 1, the day the vertical slice builds at shipping quality and the Steam Next Fest demo will be. It replaces the first playable's "Day 1 sampler" (which borrowed Day 3 and Day 4 content), whose scenes stay in the code for those days.

**Language.** The English lines are guidance for the Palestinian writer, who writes the Arabic that ships (Arabic on screen, English below). Keep the meaning, rhythm and jokes; change anything that a Gazan would not say. Words left in Arabic in the English subtitles are in italics.

**Keys.** Every line has a key for `game/data/lines.csv`: `d1.<scene>.<speaker>.<nn>`.

**Target length.** 15 to 20 minutes. No tutorial screens: every verb is taught by the scene that needs it. No objective text after the first minute; direction comes from characters, the kite, light and sound (`docs/design/feel-and-readability.md`).

**Continuity.** One continuous day. The only fade is the opening fade-in; after that, time moves on the adhan (dhuhr, asr, maghrib, isha), each a short sound-led transition with the camera held on sky or sea, never a cut to black mid-walk.

---

## Scene 0: Before anyone is awake (the roof, fajr)

**Staging.** Black. Sound first: the sea, wind, a plastic kite rattling. Far off, the fajr adhan in one human voice. Fade up on the sea at dawn, pink and grey. One kite hangs over the water. The player is already holding its string: the first input of the game is the kite. The camera follows the string down over the roofs to Layla, barefoot on the family roof, winding string around two fingers. Pigeons on the water tanks.

**Play.** Steer and pay out in the gusts for as long as the player likes; the kite cannot fall here. The only prompt is the kite control icon.

| Key | Speaker | Line |
| --- | --- | --- |
| d1.s0.mama.01 | MAMA (off, up the stairwell) | Layla! Are you on that roof again? The bread! |
| d1.s0.layla.01 | LAYLA (to the kite) | Ten more seconds. |
| d1.s0.mama.02 | MAMA (off) | I can count, you know! |

**Exit.** She reels in, the kite drops into her arms, and she goes down the stairs (the player walks down; the stairs must read as stairs at a glance). The chapter card stitches in over the stairwell: **Day 1. The kites.**

## Scene 1: The house wakes (home, fajr)

**Staging.** The cut-away house. Baba at the door, just in from a night's fishing with a small basket; Mishmish the cat winding round his legs. Teta on the prayer mat finishing fajr, in silhouette. Mama at the gas ring; bread and dagga on the low table. Karim asleep on a mattress with a phone on his chest. Layla's hair is uncovered at home.

**Play.** Walk through; optional look-ats (Layla's one-line thoughts, shown as small handwriting): the key on its nail, the wedding list on the fridge, Karim, the cat. Take bread. Take the white scarf from the hook by the door and put it on as she leaves (a small animation, not a button).

| Key | Speaker | Line |
| --- | --- | --- |
| d1.s1.mama.01 | MAMA | *Sabah el-kheir.* Eat something before you fly away. |
| d1.s1.layla.01 | LAYLA | I'll eat on the beach! |
| d1.s1.baba.01 | BABA | Did it fly? |
| d1.s1.layla.02 | LAYLA | Like a bird, Baba. |
| d1.s1.baba.02 | BABA (pushing bread at her) | Birds come home for breakfast. |
| d1.s1.teta.01 | TETA (folding the mat) | Leave her, Rania. The wind doesn't wait for breakfast. |
| d1.s1.teta.02 | TETA | *Bismillah.* And win, or don't come home. |
| d1.s1.layla.03 | LAYLA | *Wallahi* I'll win. |
| d1.s1.look.key | LAYLA (thought) | Teta's key. Older than Teta. |
| d1.s1.look.list | LAYLA (thought) | Nour's wedding. Nine days. Mama has written "flour" four times. |
| d1.s1.look.karim | KARIM (asleep) | Five more minutes, *ya zghireh*. |
| d1.s1.look.cat | LAYLA (thought) | Mishmish loves Baba. Mishmish loves fish more. |

## Scene 2: Everyone knows (the street, morning)

**Staging.** The street waking: shutters rolling up, warm air from the bakery door, Abu Fadi angling his six panels, Um Samir sweeping the clinic step with Samir at her hem, the twins waiting with two kites, Hajja Amina's laundry on her roof line (it matters in Scene 6). **Screen right is where the day goes**, so on this walk the beach is at the right end; the steps lead down to the sand. On the kite run back inland (Scene 6) the camera shows the other side of the street, so inland is screen right again.

**Play.** Walk and run. Each neighbour speaks as she passes without stopping her (barks, not conversations). The twins fall in behind her: children follow her.

| Key | Speaker | Line |
| --- | --- | --- |
| d1.s2.abu_ahmad.01 | ABU AHMAD (at the bakery door) | Win it for the street, *ya binti*! |
| d1.s2.abu_fadi.01 | ABU FADI | Is your kite charged? Ha! Go, go. |
| d1.s2.um_samir.01 | UM SAMIR | Walk! The sea isn't going anywhere. |
| d1.s2.twin.01 | HASSAN | Sami made two kites! |
| d1.s2.twin.02 | HUSSEIN | Two! And the tail is this long! |
| d1.s2.layla.01 | LAYLA | Tails don't win. Height wins. |
| d1.s2.hajja.01 | HAJJA AMINA (from her window) | Is that Nawal's girl? Tell your Teta I'm coming for coffee! |
| d1.s2.layla.02 | LAYLA | She knows, Hajja! She's already hiding the good cups! |

## Scene 3: The festival (the beach, late morning)

**Staging.** The widest, brightest frame of the game so far. Families under umbrellas, a vendor's cart of toys and snacks, a camel, a lifeguard on his tower, a beached painted boat, a kiosk. Volunteers in caps with whistles and a megaphone; a banner (Arabic by the writer). Hundreds of children with kites made from plastic bags, sticks and string.

**Play.** Find Sami. Layla's kite needs a real tail. The twins point under the beached boat: a blue plastic bag caught there. Crawl under the boat (teaches crawl), pull it out, tie the tail (hold to tie; strips of plastic appear).

| Key | Speaker | Line |
| --- | --- | --- |
| d1.s3.volunteer.01 | VOLUNTEER (megaphone) | Kites ready! When the whistle blows, every kite goes up, and we count to thirty. Up at thirty, it counts! |
| d1.s3.sami.01 | SAMI (spinning his reel) | You're late, *ya bint 'ammi*. I made two. One to win, one to lend you when yours falls. |
| d1.s3.layla.01 | LAYLA | Mine doesn't fall. |
| d1.s3.sami.02 | SAMI | It has no tail. |
| d1.s3.layla.02 | LAYLA | It has a small tail. |
| d1.s3.sami.03 | SAMI | That's not a tail, that's a wish. |
| d1.s3.twin.01 | HUSSEIN | Plastic! Under the boat! |
| d1.s3.twin.02 | HASSAN | There are crabs under the boat. |
| d1.s3.layla.03 | LAYLA (crawling in) | Crabs are scared of me. |
| d1.s3.layla.04 | LAYLA (tail tied) | Now it's a tail. |
| d1.s3.sami.04 | SAMI | Now it's a wish with a tail. |

## Scene 4: Thirty (the beach, noon approaching)

**Staging.** The whistle. The whole beach launches. The dust at Layla's feet shows the gust to launch on. Hundreds of voices count, led by the megaphone, in Arabic, subtitled: *wahid, itnein, talateh...* The camera slowly pulls back while the player flies, until the sky over the sea is full of kites (a cinematic that never takes control). At thirty: a roar, whistles, zaghareet from the women under the umbrellas.

**Play.** Thirty seconds of kite control: pay out on gusts, pull in lulls, steer clear of other strings (a tangle costs height, never the kite). Sami's kite beside hers. If hers comes down she relaunches; the count does not wait and nothing is failed. Whichever kite is higher at thirty wins.

| Key | Speaker | Line |
| --- | --- | --- |
| d1.s4.volunteer.01 | VOLUNTEER | Kites up! |
| d1.s4.crowd.count | CROWD | (one to thirty, in voices) |
| d1.s4.twin.win_layla | HASSAN | Layla's! Layla's is highest! |
| d1.s4.twin.win_sami | HUSSEIN | Sami! Sami's is in the clouds! |
| d1.s4.sami.lose | SAMI (if Layla won) | The wind likes you today. Tomorrow it's mine. |
| d1.s4.layla.win | LAYLA (if Layla won) | Tomorrow the wind is still mine. |
| d1.s4.layla.lose | LAYLA (if Sami won) | Your tail cheated. |
| d1.s4.sami.win | SAMI (if Sami won) | Tails don't cheat. Tails hold on. |

**Mark.** `d1_contest_winner` = layla or sami.

## Scene 5: The promise (the beach, a sit spot)

**Staging.** The two of them on the sand, kites resting, the sea. The crowd thins behind them. The friend's voice, low, if recorded.

**Play.** Sit (the first sit spot; the sit input is taught here). Tie the knot: hold to tie. Close shot of two hands and one knot; the hands never touch.

| Key | Speaker | Line |
| --- | --- | --- |
| d1.s5.sami.01 | SAMI | Nour says there's no wedding without a kite. |
| d1.s5.layla.01 | LAYLA | Nour said that? |
| d1.s5.sami.02 | SAMI | I said it. She agreed. Nine days. |
| d1.s5.sami.03 | SAMI | So. Whoever won today flies at the wedding. |
| d1.s5.layla.02 | LAYLA | And whoever lost? |
| d1.s5.sami.04 | SAMI | Builds the kite. The best one this street ever saw. |
| d1.s5.layla.03 | LAYLA | Promise? |
| d1.s5.sami.05 | SAMI (holding out a cut piece of his string) | Tie it to yours. |
| d1.s5.sami.06 | SAMI (knot tied) | Now it's a promise. My Baba's knot. Nobody unties it. |
| d1.s5.layla.04 | LAYLA (putting it in her notebook) | I'm keeping it. So you don't cheat. |

## Scene 6: The kite run (beach to street to roofs, noon)

**Staging.** Sami launches again to show off a loop. His old string snaps. The onshore wind carries his kite up off the beach and inland over the city. Layla runs. The kite drifts ahead, dipping and rising: the kite itself is the signpost. The route: the steps up from the sand, the corniche, the street, a cart, under low washing, an outside staircase, across adjoining roofs with small safe gaps, water tanks, a satellite dish. The twins chase behind. Neighbours react as she passes. The kite snags on Hajja Amina's roof line and brings down a sheet.

**Play.** Kite running: run, jump, climb, crawl, fast and forgiving (a fall costs a second, the kite waits in the wind). At Hajja Amina's roof: free the kite. Optional: pick up the sheet and hang it back (the act is remembered).

| Key | Speaker | Line |
| --- | --- | --- |
| d1.s6.sami.01 | SAMI | No, no, no! My kite! |
| d1.s6.layla.01 | LAYLA | I've got it! |
| d1.s6.abu_ahmad.01 | ABU AHMAD | Slow down! My bread! |
| d1.s6.abu_fadi.01 | ABU FADI | It went left! No, your other left! |
| d1.s6.um_samir.01 | UM SAMIR | Walk, Layla! Walk! |
| d1.s6.hajja.01 | HAJJA AMINA | Who is dancing on my roof? |
| d1.s6.layla.02 | LAYLA | Only me, Hajja! I'm sorry, the kite... |
| d1.s6.hajja.02 | HAJJA AMINA | The kite, the kite. In my day we chased chickens. |
| d1.s6.hajja.03 | HAJJA AMINA (if she hangs the sheet back) | *Allah yirda 'aleiki.* Tell Nawal her granddaughter has manners, at least. |
| d1.s6.sami.02 | SAMI (arriving, out of breath) | Is it...? |
| d1.s6.layla.03 | LAYLA | Only torn. I'll fix it tonight. |
| d1.s6.sami.03 | SAMI | You'll fix my kite? |
| d1.s6.layla.04 | LAYLA | Practice. For the wedding. |

**Mark.** `d1_amina_laundry` = true if the sheet went back. **Transition.** The dhuhr adhan from the minaret; the camera rises to the sky and settles on the house at asr.

## Scene 7: The power comes on (home, asr)

**Staging.** Layla at the low table with Sami's torn kite. Teta's knafeh ghazawiya (semolina, nuts, cinnamon) on a tray. Mama with the lists. Then the grid's half day arrives on schedule: the fridge shudders, the ceiling fan turns, windows light up across the street, and a cheer goes up from every house. Karim wakes at last and plugs three phones into one socket. A knock: Abu Ahmad with a bag of bread for the wedding lists, and the women reach for their scarves (a household joke the readers confirm or cut).

**Play.** Patch the kite: tape, and thread from Teta's sewing tin. Karim's knafeh theft is interruptible.

| Key | Speaker | Line |
| --- | --- | --- |
| d1.s7.mama.01 | MAMA | Nine days. No sugar, no flour, and a girl fixing kites. |
| d1.s7.layla.01 | LAYLA | A wedding needs a kite. |
| d1.s7.mama.02 | MAMA | A wedding needs flour. |
| d1.s7.kids.01 | CHILDREN (outside) | It came! The electricity came! |
| d1.s7.karim.01 | KARIM (waking) | Why is everyone shouting? Oh. Power. |
| d1.s7.teta.01 | TETA (spoon on Karim's hand) | That knafeh has counted every piece. |
| d1.s7.teta.02 | TETA (Layla reaching into the tin) | Not that thread. That's for Nour's dress. |
| d1.s7.layla.02 | LAYLA | Just a little. |
| d1.s7.teta.03 | TETA | Everything in this house is "just a little". |
| d1.s7.teta.04 | TETA | Come up when the sun goes down. I want to ask you something. |

**Transition.** The asr light yellows; the maghrib adhan begins as Layla climbs the stairs.

## Scene 8: The question (the roof, maghrib)

**Staging.** The sun going down into the sea behind the roof. Pigeons on the water tanks. Baba mending his net. Teta on her cushion by the parapet with the key on its cord in her hands. The friend's voice rises softly (the sit-spot pad); everything else quiet.

**Play.** Sit beside Teta. Nothing else is asked.

| Key | Speaker | Line |
| --- | --- | --- |
| d1.s8.teta.01 | TETA | So? Did your kite win? |
| d1.s8.layla.win | LAYLA (if she won) | Highest on the whole beach. |
| d1.s8.layla.lose | LAYLA (if Sami won) | Sami's tail cheated. |
| d1.s8.teta.02 | TETA | Tails don't cheat. |
| d1.s8.teta.03 | TETA | Tell me something, *ya Layla*. Up there, who is braver: the kite, or the hand that holds the string? |
| d1.s8.layla.01 | LAYLA | The kite! It's the one up in the wind. The hand just stands there. |
| d1.s8.teta.04 | TETA (a long look at the sea) | Hmm. Just stands there. |
| d1.s8.layla.02 | LAYLA | Why do you always hold that key? |
| d1.s8.teta.05 | TETA | My mother held it. Now I hold it. One day you'll hold it and complain it's heavy. |
| d1.s8.layla.03 | LAYLA | It's tiny. |
| d1.s8.teta.06 | TETA | Heavy things are often tiny. |
| d1.s8.layla.04 | LAYLA | Why are you smiling? |
| d1.s8.teta.07 | TETA | Can't a grandmother smile? It's charity. Didn't they teach you that? |

**Card.** Jami' at-Tirmidhi 1956: "Your smiling in the face of your brother is charity." Held on the sea at dusk; gameplay stopped; every bus silent; the Arabic, the English and the reference; skip only at the end.

| Key | Speaker | Line |
| --- | --- | --- |
| d1.s8.baba.01 | BABA (after the card, from his net) | Nine days of your mother's lists. *Allah* help us. |

## Scene 9: A light nobody mentions (the roof, isha)

**Staging.** The isha adhan. Night. The city's windows lit, then the grid cuts out section by section across the city, as it does every night; somebody down the street calls for candles and nobody minds. On the black sea, far out, one light that does not move. Baba looks at it a second too long, then back at his net. Nobody says anything.

**Play.** The player can look (the camera drifts toward the light if they stand still at the parapet). Then the notebook.

| Key | Speaker | Line |
| --- | --- | --- |
| d1.s9.teta.01 | TETA | *Yalla*, inside. Your mother has lists. |

**The notebook page.** Layla's hand writes as the player watches: *bismillah* at the top, set clean. Then, from the marks:

| Key | Line |
| --- | --- |
| d1.note.count | The count got to 30. (Everyone's kite. The WHOLE beach.) |
| d1.note.won | Mine was highest. Sami says the wind cheated. |
| d1.note.lost | Sami's was highest. His tail cheated. |
| d1.note.run | Ran his kite down through the whole street and over three roofs. |
| d1.note.amina | Put Hajja Amina's sheet back. She says I have manners, at least. |
| d1.note.promise | 9 days. Whoever won flies. Whoever lost builds. (Knot is here.) |
| d1.note.teta | Teta asked me something. |

The tatreez end card finishes stitching. **End of Day 1.** In the demo: the end screen and the store link.

---

## Build notes for the slice

**Spaces.** The home and its roof (fajr, asr, maghrib, isha), the street in its morning and noon dressing with Hajja Amina's roof and the adjoining roofs, the beach in its festival dressing. The three spaces are one continuous walk: home, street, beach, then back up through the street and roofs.

**Verbs taught, in order.** Kite (Scene 0), walk and stairs (0), look (1), run and barks (2), crawl (3), tie (3, 5), launch on a gust (4), sit (5), kite running with jump and climb (6), repair (7), sit and listen (8). No heavy carry, no switching, no darkness on Day 1.

**People on screen.** Layla, Sami, Teta, Mama, Baba, Karim, Abu Ahmad, Abu Fadi, Um Samir and Samir, Hajja Amina, the twins, a volunteer, the crowd, Mishmish. Every one needs a performed idle, walk and at least one gesture (`docs/art/direction.md`).

**Sound.** No drone at all. The sea, the wind, the crowd, whistles, the count in voices, the adhan four times, the fridge and the fan, pigeons, the friend's voice under the roof sit (`docs/audio/direction.md`).

**Gate for this script.** A stranger plays it without help, finishes in under 25 minutes, and when asked what stuck names the count, the kite run, the promise or Teta's question.
