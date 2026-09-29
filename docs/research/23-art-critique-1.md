# Art critique 1 (29 September 2026, fresh eyes on the first look pass)

A senior-art-director pass over seven renders of the prototype (beach hero at dusk, beach morning with props, carryable items, home at dusk, night street, street at noon with dialogue, the rig pose sheet), judged against "would this hold on a Steam page next to Inside, Gris and Planet of Lana". The renders predate the street facade generator, the furnished home, the stepped stairs and the kiosk, so several items below were already done by the end of the same session; they are kept here as the record. Items marked DONE were applied on 29 September.

## Verdict

Two of the seven would survive a first glance: the beach at dusk and the home at dusk; their skies and palettes are at the bar. Everything falls apart below the horizon line: a flat, edge-perfect rectangle of dark ground takes a third of every frame, the figures are a tenth of the frame height, the lights do not light anything, and the buildings are boxes. The look the doc describes (layered haze with Inside's accent rule, printed not rendered) is present in the sky shader and the grain and absent from the world. The rig moves well but every character is the same body. The distance to the bar is about a dozen concrete systems.

## Hero: beach at dusk

Works: the sky (indigo to rose to gold, haze band, band-free, stars fading in), the kite as the one saturated object, the string's sag, the grain as paper, the far city catching the sky colour.

1. The bottom third is a flat rectangle. Fix: a ground shader on the sand (noise-roughened top edge, vertical value gradient lighter at the waterline, a wet band 40 to 60 px that mixes the horizon colour and the sun path, a foam line sharing the sea's TIME, hash speckle 3 to 4 percent, a footprint trail behind the player), then a foreground occluder plane at scroll 1.3 to 1.5 (a net on poles, rope, a beached bow, grass tufts).
2. Layla is a tenth of the frame. Fix: camera zoom about 1.6 for ground play, keep the kite pull-out; hero framed on thirds; a one-pixel warm rim on the sun side of the figure. (Camera zoom raised to 1.3: DONE.)
3. The city is placeless and across the water; from Gaza's beach the sea is open to the west, the city curves away along the shore to one side; the coast also repeats every 6000 px. Fix: buildings to one side only, tallest at the edge and stepping into haze, a breakwater arm with a light, masts of moored hasakas, no repeat seam.
4. The sea is a flat field with white pixels. Fix: mix the horizon colour down into the sea by depth, tint glints with the sun colour, stretch them horizontally, weight density toward sun_x, two or three swell ribbons with noised edges instead of ruled rows. (Horizon mix, tinted stretched glints: DONE.)
5. The kite is a flat diamond. Fix: two-tone bowed sail lit toward the sun, a tail of plastic-bag strips, HDR colour with glow, string fading toward the hand. (Two-tone sail and fading string: DONE.)
6. No midground between sand and horizon. Fix: one plane at scroll 0.6 with the corniche rail, palms whose fronds sample Wind, a tented shade frame.
7. The HUD legend sits in every shot. Fix: a --no-hud flag for shots (DONE) and a body font with tracking for the hint.

## Beach, morning, with props

Works: the morning palette; the boat's raised prow and mast (right for a hasaka).

1. The boat floats on the ruler line. Fix: rotate 6 to 8 degrees stern-down, let the sand overlap the lower hull, tyres or a prop under the stern, a net over the gunwale, a coil of rope, one rope stay, a faded painted band along the gunwale (Gaza's skiffs are painted).
2. Crates and wall are rectangles with one hairline. Fix: a prop generator: fish crates as a stack of shallow open baskets each offset and rotated a little, ribbed; the wall as breeze block with a grid of joint lines, a missing block, a rebar spike; 1 px noise on every outer edge. (Wall courses, posts, rubble and crate slats: partly DONE.)
3. Nothing touches the ground. Fix: an ambient-occlusion ellipse under every prop and figure, props sunk 2 to 4 px. (Figures: DONE.)
4. The sand is the night colour in the morning. Fix: a per-phase "ground" colour in palette.json applied by look.gd to a "ground" group (morning cream about 0.55 value, noon warm grey 0.5, dusk 0.2, night 0.08); figures and props stay dark. (DONE.)
5. Sun and sea disagree: no column of light under the sun. Same fix as the hero sea.
6. The minaret reads as a lighthouse. Fix: taller thinner shaft, a wider balcony ring at three quarters, a short neck, a cone or dome, a crescent line, a square-shaft Omari variant.

## Carryable items

Works: legible at a glance (pita stack, jerrycan, drum), a catch of light along each top, the jerrycan yellow as a cultural signal.

1. Saturated mid-tone fills. Fix: base fill at 20 to 25 percent value in the hue, a darker band on the off-sun side, the rim at high value in the hue, a worn-plastic mottle.
2. Rims are 1 px hairlines; they vanish on Steam Deck. Fix: 2 to 2.5 px minimum.
3. No contact shadow, no sink.
4. The jerrycan is almost half a child's height; about 36 px is right, let the carry lean sell the weight.

## Home at dusk

Works: the best frame; a dark cut-away house, warm windows and a candle, Teta with her cane on the parapet against the rose sky, the tower behind, the city stepping back in three values. Do not restage it.

1. The interior is lighter than the exterior, an X-ray not a section. Fix: darker back wall, a PointLight2D per lit window, candle light with shadows and LightOccluder2D on floors and flights. (Interior rebuilt as furnished plaster rooms with a ceiling bulb light: DONE; shadows and occluders: not yet.)
2. Windows are stickers. Fix: a window recipe shared by home, street and night street: iron grille, pane gradient, HDR pane with glow, a spill light. (Frames and bars: DONE; spill lights: not yet.)
3. The candle lights the floor evenly. Fix: a three-stop radial (1.0 at centre, 0.25 at 0.35, 0 at 1.0), energy 1.8 to 2.2, position flicker, shadows on, occluders from the torso polygons. (Falloff and energy: DONE.)
4. The roof is bare. Fix: polyethylene tanks with domed tops, a solar panel, a dish, rebar with hooks, a laundry line that samples Wind. (Static versions: DONE.)
5. Stairs are slabs and walls are strokes. Fix: treads as a zigzag (DONE), a real doorway with a spill polygon, wall thickness 28 to 32 px with a lighter cut face.
6. The sea strip at roof height makes the house stand on a dock. Fix: drop the sea band 60 to 80 px and put a far low plane between (corniche, palms, a rail), or keep the sea only where CardView looks.
7. Baba and Layla differ only in height. See the rig.

## Night street

Works: the moon and halo, the star field, three planes of skyline, the mood of a blackout, lit windows as the status display.

1. No flame in the frame and the oven does not glow (its PointLight2D has no texture). Fix: a radial texture on the oven light, energy 2.0, shadows on, smoke motes; candle energy 2.5 to 3.0; lift facade albedo from 0.06 to about 0.2 and let the ambient make the dark. (Oven light texture: DONE.)
2. Lit windows do not light their walls. Same window recipe.
3. Too few dark windows. Fix: generate the default dark grid from each house's dimensions and place the named act windows among them; the JSON keeps only the lit set and the acts.
4. Facades are chamfered boxes. Fix: parapet lip, roof clutter, an open unfinished top floor on one house in three, noised outlines. (Use the Facades generator here.)
5. The plank reads as a floating bar. Fix: a dark pit interior with a gradient, the plank as a 14 px slab with end grain and bearing shadows.
6. The street is empty. Fix: two or three static neighbours with a small cool phone-torch light, one in a doorway, one on a step.
7. The ground is flat near-black. Fix: a faint cool moon gradient across the road, kerb and gutter as two value steps.

## Street at noon with dialogue

Works: the typography (Amiri right-to-left, readable, the speaker in a warm accent, the English quiet), the best atmospheric perspective of the set.

1. There is no street. Fix: a near-plane facade generator (two to four storeys, shop shutters, doors, balconies, awnings, a breeze-block yard wall with a cactus hedge, one bougainvillea accent, laundry on the wind, chalk marks, posters); replace the bakery portal with a building that has a doorway. (Facades generator with shutters, awnings, balconies, laundry, tanks, solar panels, rebar, a bakery with a lit oven mouth and a sign: DONE; cactus, bougainvillea, posters: not yet.)
2. The value structure is inverted for noon. Fix: per-phase ground colour (DONE), short contact shadows scaling with sun height, a slightly cool noon ambient and a warm morning one instead of white for both.
3. The dialogue box covers the player. Fix: narrower box, Arabic 38 and English 26 (DONE at 36 and 23), anchor away from the player, no orphan words (non-breaking spaces in "أبو أحمد" and "Abu Ahmad's"), a thin tatreez stitch line along the top edge.
4. Skyline boxes are most visible at noon: roof-edge noise, tanks, rebar, dishes, unfinished frames, per-building value jitter, the minaret profile.
5. The HUD legend sits over the sun.

## Character rig pose sheet

Works: the walk plants, the run has stride and lean, the crawl is a crawl, the sit has knees, Teta's stoop and cane and thobe read from across the room, the eye lights make faces, proportions are in range. Keep the motion fundamentals.

1. Everyone is the same body. Fix: per-character exports for shoulder width (Baba 0.14 H), torso taper, belly (Abu Ahmad), a head accessory (Baba's cap, Abu Ahmad's apron line, Mama's hijab drape), a second hand node for props.
2. Layla's headscarf is black and reads as a hood; it should be the one honest accent, like Inside's red shirt. Fix: a scarf colour export, cream at about 0.75 value, tail included. (DONE.)
3. Near and far limbs merge. Fix: depth_lift 0.22 (DONE) and a background-coloured halo under the near limbs.
4. No hands. Fix: a small paddle polygon at the forearm angle. (DONE.)
5. The kite pose is a hail. Fix: arm out at 45 to 60 degrees, elbow slightly bent, head tilted up, the other hand at the spool by the waist, weight on the back foot. (DONE.)
6. The jump is a walk with a raised knee. Fix: tuck both knees, arms back, torso forward. (DONE.)
7. Feet hover 4 px above the baseline. Fix: plant at 0. (DONE.)
8. A child's head is proportionally larger: 0.082 H for build 0. (DONE.)
9. The mirrored label on the sheet. (DONE.)

## Cross-cutting

Perfect rectangles everywhere; uniform hairline rims; a flat ground plane a third of the frame; figures, props and houses all the same near-black; no cast shadows or ground contact; lights that tint but do not light; the same skyline vocabulary in every scene; white ambient by day; the print grade lacks the ink bleed and edge wobble the doc promises (a 1 to 1.5 px low-frequency UV wobble in grade.gdshader would soften the vector feel more than anything else; blue noise instead of white hash would let the sky gradients go further).

## Ten highest-leverage changes, ranked

1. Kill the flat ground in every scene: noised top edge, per-phase lit value, wet band and foam on the beach, contact shadows under everything.
2. Make lights light: steep falloff textures, higher energy, shadows with occluders, facade albedo lifted; fix the untextured oven light.
3. Bring the camera in: figures at a sixth of the frame, kite pull-out kept.
4. Rebuild the skyline vocabulary: roof-edge noise, cylindrical tanks, rebar, solar panels, dishes, unfinished frames, a real minaret, value jitter, no repeat seam, a one-sided coast.
5. A near-plane facade generator for the street by day and night.
6. Windows as light sources, with a dense default grid of dark windows.
7. Characters, not one rig.
8. The sea reflects the sky.
9. Props with weight and place; darker fills with coloured rims and mottle; every edge noised.
10. The kite as the icon; the dialogue box narrowed with orphans fixed and a stitch line.

## Three things not to change

1. The sky shader and the dusk and morning palettes.
2. The print grade's grain and vignette (add wobble and blue noise; do not reduce it).
3. The staging of the home at dusk and the rig's motion fundamentals.
