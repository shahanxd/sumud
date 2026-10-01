# Decisions

Founder decisions, with the date. The design document holds the reasoning; this file is the record.

| Date | Decision | Notes |
| --- | --- | --- |
| 2026-09-29 | Art base is Limbo and Inside silhouettes ("Shadow and Thread"), with colour carried by light, sky, sea and accents | more colour than Limbo, never paint on silhouettes |
| 2026-09-29 | Engine: Godot 4.7.2, GDScript, Forward+ on desktop | |
| 2026-09-29 | Cast as designed; family name Haddad retired, placeholder Awad until readers choose | |
| 2026-09-29 | Ten days, four tentpoles (1, 3, 7, 10) and six short days, about two hours | |
| 2026-09-29 | English and Arabic at launch; Urdu and Hindi within a month | |
| 2026-09-29 | No combat. The perpetrator is "they": present, faceless, never a target | |
| 2026-09-29 | Fully halal: voices-only score, duff only at the wedding, Quran as a full stop, no AI-generated Quran, voices or music | school lens to be chosen (Hanafi proposed) |
| 2026-09-29 | Real explosion sound, once per strike day, then silence | |
| 2026-09-29 | Children's deaths may be shown, as aftermath; Sami dies on Day 7; target PEGI 16 | founder to confirm |
| 2026-09-29 | Title SUMUD for now | |
| 2026-09-29 | Player-designed kites in the ending; public web page after launch | |
| 2026-09-29 | Charity: yes; share and organisation to be set | "100%" to be clarified |
| 2026-09-29 | Content complete by 28 December 2026; launch March 2027 after Next Fest | founder to confirm |
| 2026-09-29 | Design document v0.2 finished: Scripture moments filled, critiques 11 and 12 folded in, verification corrections applied, proofread | see "What the critiques changed" in the doc |
| 2026-09-29 | Proposed, founder to confirm: Sami is Layla's cousin next door (a relation, not a cast change); Karim's choice is a scholarship or staying; Teta keeps her mother's key | readers to vet |
| 2026-09-29 | Proposed, founder to confirm: charity in the War Child wording, Medical Aid for Palestinians or PCRF, quarterly post, launch-week pledge | Decision 5 |
| 2026-09-29 | Open: Decision 13 (Dhul Hijjah, recommended no), Decision 14 (whose wedding, recommended Sami's sister) | founder |
| 2026-09-29 | Amiri and Noto Naskh Arabic fetched into the repository under the OFL for the prototype | founder to confirm |
| 2026-09-29 | Prototype look: sky and sea shaders, a screen-space print grade, a per-phase palette with a lit ground colour; the ground is bright by day, figures and props stay dark | founder to react to the renders |
| 2026-09-29 | Characters are one procedural bone rig (Figure) drawn each frame, no sprites; Layla's headscarf drawn cream as her one accent | founder to confirm the scarf colour |
| 2026-09-29 | All prototype sound is synthesised by tools/audio.py from noise and resonances; roof_breath_loop.wav is a placeholder for the friend's vocal pad; Day 1 has no drone and no rumble | |
| 2026-09-29 | Street facades, the home interior and the beach props are generated or hand-placed polygons with muted plaster tones; signs say "مخبز أبو أحمد" and "كشك الشاطئ" | readers to vet the signs |
| 2026-09-29 | Founder played the first playable on Windows: "if my dream is v2.0, this is v0.2"; characters wooden, scarf and eyes weird, walk and jump weird, story dead, gameplay dry, cuts sudden, sounds weird | `docs/playtests/2026-09-29-founder.md` |
| 2026-09-30 | Pre-production lock phase begins: every decision that cannot change later is settled before production (`docs/production/lock.md`) | founder: "document everything first" |
| 2026-09-30 | Launch date may move for quality; set at the Day 3 gate, not earlier than late 2027 | founder said yes; supersedes the 29 September plan (launch March 2027 after Next Fest) and the founder's "two to three months" |
| 2026-09-30 | The order of work: lock, then a vertical slice of Day 1 at shipping quality, then Day 3, then production (`docs/production/pipeline.md`) | proposed; lock A-06, K-01 |
| 2026-09-30 | AI-generated textures, sounds or art are not used, even as placeholders or style targets; people make the assets (recorded, filmed, drawn) | restates the design document; lock F-01 |
| 2026-09-30 | Characters to be made by performance (rotoscoped silhouettes), an artist's cut-out rig, or an improved code rig, chosen by an animation test | proposed; lock F-03 |
| 2026-09-30 | References: Silksong (hand-made motion, feel), Life is Strange (quiet moments, lived-in rooms), The Kite Runner (a child's city at kite height) | lock A-05 |
| 2026-09-30 | The repository's `docs/` is the source of truth for any agent; the Claude Doc is the founder's reading copy | lock K-06 |
| 2026-10-01 | AI generation allowed for art, textures, props, animation frames, sound effects and ambience ("ai generation allowed, go ahead make it good"); reverses the 30 September rule | lock F-01; limits proposed in F-09: no AI Quran, no AI music, nothing from real Gazans' footage or likeness, review, rights rows, Steam disclosure |
| 2026-10-01 | Commit after every batch and update HANDOFF.md in the same commit, so the project can be handed to another agent at any time | founder's instruction |
| 2026-10-01 | The playable's characters and hero props are generated images extracted through Canva previews and keyed by tools/roto.py; the bone rig stays as the fallback for anyone without frames | lock F-03 still PROPOSED for the founder to confirm by playing; method D in docs/art/direction.md |

| 2026-10-01 | The founder answered the whole lock register in chat: every PROPOSED row locked as written except the changes below ("lock all", "p1 and p2 lock") | lock.md, all rows |
| 2026-10-01 | Schedule: "we speed up": Day 1 complete on 1 October, Day 3 by 7 October, the full game by December 2026. Supersedes the 30 September "launch moves for quality" dates; the quality bar (A-04) stands, reached by iterating on finished days | lock K-01; pipeline.md stages |
| 2026-10-01 | Character method: generated silhouette frames, kept after the founder played the build ("keep") | lock F-03, I-03 |
| 2026-10-01 | No artist: the founder judges every asset, the agent produces all art by generation and code | lock F-04; pipeline roles |
| 2026-10-01 | Layla's scarf is dusty blue, her one colour accent | lock F-06; player.tscn `scarf_color` |
| 2026-10-01 | Eyes: try Limbo-style eye-lights against none on the next style frame; the founder picks there | lock F-05 stays PROPOSED |
| 2026-10-01 | Sound: ElevenLabs on the founder's account for foley, ambience and the strike; Quran never generated, each scripture moment gets an audio slot the founder fills by hand with a licensed human recording | lock G-01 |
| 2026-10-01 | The founder's friend (a song performer, named later) sings only the songs; Layla's lines are sung by a young girl with consent | lock G-02, G-04 |
| 2026-10-01 | The founder does the scholar review themselves before each day ships | lock E-05 |
| 2026-10-01 | Readers deferred ("not now, later"); still required before any public build | lock E-06 |
| 2026-10-01 | Budget as proposed, no ceiling given; Canva for images ("canva doing good") | lock K-02, F-01 |
| 2026-10-01 | Generated world sound is in the game: 22 files from ElevenLabs (`tools/eleven.py`, prompts in `game/assets/audio/generated.json`); drone, rumble, ringing and the friend's placeholder stay synthesised. Free-tier output is non-commercial, so the files are drafts until the account is paid and they are regenerated | lock G-01; rights.md |
