# Acrylic Panel Frame Builder

Parametric OpenSCAD model for a 1-, 2-, or 4-sided multi-panel acrylic frame. Rails hold acrylic panels in parallel slots; 2- and 4-sided frames use 45° mitered corners with tongue-and-groove interlocks.

All dimensions are in **millimeters**.

## Getting started

You can customize and export STLs in either desktop OpenSCAD or the browser-based OpenSCAD Assistive Forge. Both expose the same Customizer parameters from `Frame Builder.scad`.

### Option A — Desktop OpenSCAD

1. Download OpenSCAD for Windows, macOS, or Linux from the official site:
  [https://openscad.org/downloads](https://openscad.org/downloads)
2. Install and open OpenSCAD.
3. Open `Frame Builder.scad` (**File → Open**).
4. Show the Customizer if it is hidden: **Window → Customizer**.
5. Change parameters in the Customizer panel. Preview updates as you adjust values (press **F5** / **Design → Preview** if needed).
6. When ready to export:
  - Set **layout** to `printable`.
  - Press **F6** / **Design → Render**.
  - Export with **File → Export → Export as STL…**

Tip: use **layout = assembled** and **show_panels = true** to check fit visually before switching to printable for export.

### Option B — OpenSCAD Assistive Forge (browser)

No install required. Runs in your browser:

1. Open [https://openscad-assistive-forge.pages.dev](https://openscad-assistive-forge.pages.dev)
2. On the main page, choose **Upload an OpenSCAD (.scad) file**.
3. Select `Frame Builder.scad` from this folder.
4. Use the on-screen parameter controls (same groups as the desktop Customizer).
5. Preview the model, then **Generate** / **Download** an STL when ready.

You can optionally save the project in the browser for later. Nothing is uploaded to a server for rendering — processing stays on your device.

---



## Customizer options

Parameters are grouped the same way they appear in OpenSCAD’s Customizer.

### Frame Style


| Parameter       | Default     | What it does                                                                                                                       |
| --------------- | ----------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| **num_sides**   | `2`         | Frame shape: `1` = single rail, `2` = L-shaped stand (bottom + side), `4` = closed picture-frame (four rails).                     |
| **bevel_outer** | `true`      | Chamfers the long outer top edges of each rail profile.                                                                            |
| **layout**      | `printable` | `assembled` shows the frame put together (for visual check). `printable` lays parts flat and spaced for 3D-print export.           |
| **show_panels** | `true`      | In assembled view, draws translucent acrylic panels in the slots so you can verify size and seating. Ignored for printable layout. |
| **end_style_1** | `mitered`   | Style of the first free end (see below). Ignored on 4-sided frames — every end joins.                                              |
| **end_style_2** | `mitered`   | Style of the second free end. Same options as above.                                                                               |


**End styles** (`end_style_1` / `end_style_2`):

- **mitered** — 45° cut at that free end.
- **open** — square end; panel slots run through (acrylic can slide out).
- **closed** — square end with a solid end wall that caps the slots.

Which end is which:

- **1-sided:** style 1 = start of the rail, style 2 = end of the rail.
- **2-sided:** style 1 = free end of the bottom/length rail, style 2 = free end of the side/width rail.
- **4-sided:** both ignored; all corners are mitered joining ends.



### Panels


| Parameter           | Default      | What it does                                                                       |
| ------------------- | ------------ | ---------------------------------------------------------------------------------- |
| **num_panels**      | `5`          | How many acrylic panels (and thus how many parallel slots) the frame holds.        |
| **panel_length**    | `177.8` (7″) | Acrylic edge length along the bottom / horizontal rails.                           |
| **panel_width**     | `127` (5″)   | Acrylic edge length along the side / vertical rails.                               |
| **panel_thickness** | `2`          | Acrylic stock thickness. Slot opening width is this value plus **slot_tolerance**. |




### Slots & Frame Body


| Parameter              | Default | What it does                                                                                                                               |
| ---------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| **slot_depth**         | `6`     | How far each panel sits into its groove (slot height above the floor).                                                                     |
| **slot_tolerance**     | `0.3`   | Extra clearance added to the slot opening so panels slide in without binding.                                                              |
| **gap_between_panels** | `3`     | Thickness of the solid wall between neighboring panel slots.                                                                               |
| **frame_under_slot**   | `3`     | Solid material under the slot floor (rail “base” thickness). Also sets how far the acrylic is inset from the outer corner on joining ends. |
| **outer_wall**         | `3`     | Material outside the first and last slot. Also used as the thickness of closed end caps.                                                   |
| **bevel_size**         | `2`     | Size of the long-edge outer chamfer when **bevel_outer** is on.                                                                            |




### Corner Joint

These apply to mitered joining corners on 2- and 4-sided frames (tongue/groove interlocks in the interior walls).


| Parameter                   | Default | What it does                                                                                                                                                       |
| --------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **joint_tolerance**         | `0.15`  | Clearance on interior tongues/grooves (per side, and on top) so mating miters assemble without forcing.                                                            |
| **interlock_face_fraction** | `0.75`  | Fraction of the 45° miter face used by the tongues/slots, measured up from the base. Leaves the upper part of the face clear for fit.                              |
| **tab_thickness**           | `0`     | Tongue/groove thickness inside each wall (stack direction). `0` = auto (roughly `min(1.2, gap_between_panels / 2)`). Set manually if you need a specific tab size. |




### Print Layout


| Parameter         | Default | What it does                                                                               |
| ----------------- | ------- | ------------------------------------------------------------------------------------------ |
| **print_spacing** | `12`    | Gap between rails when **layout** is `printable`, so parts don’t touch on the build plate. |


---



## Typical workflow

1. Set **panel_length**, **panel_width**, **panel_thickness**, and **num_panels** to match your acrylic.
2. Choose **num_sides** and free-end styles if using a 1- or 2-sided frame.
3. Switch **layout** to `assembled`, enable **show_panels**, and preview to check seating and corners.
4. Switch **layout** to `printable`, render, and export STL for slicing.



## Printable parts

Depending on **num_sides**, printable layout exports:

- **1-sided** — one rail
- **2-sided** — bottom/length rail + side/width rail
- **4-sided** — two length rails + two width rails (phased so corners mate when assembled)

