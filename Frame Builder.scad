// Acrylic Panel Frame Builder
// Parametric 1-, 2-, or 4-sided multi-panel acrylic frame.
// 1-sided: single rail; free ends use end_style_1 / end_style_2 (no joints).
// 2-sided (L) / 4-sided: 45° mitered joining ends with tongue/groove interlocks.
// Units: millimeters

/* [Frame Style] */
// 1 = single rail; 2 = L-shaped stand; 4 = closed picture frame
num_sides = 2; // [1, 2, 4]
// Chamfer the long outer top edges of the profile
bevel_outer = true;
// assembled = visual check; printable = parts laid flat for export
layout = "printable"; // ["assembled", "printable"]
// Ghost acrylic panels in assembled view
show_panels = true;
// Free-end styles (ignored for 4-sided — all ends join):
//   mitered = 45° cut; open = square, slots through; closed = square with end wall
// 1-sided: style 1 and 2 for either rail end. 2-sided: Each style applies to one non-joint end
end_style_1 = "mitered"; // ["mitered", "open", "closed"]
end_style_2 = "mitered"; // ["mitered", "open", "closed"]

/* [Panels] */
num_panels = 5;
// Acrylic edge along the bottom / horizontal rails (7" default)
panel_length = 177.8;
// Acrylic edge along the side / vertical rails (5" default)
panel_width = 127;
// Acrylic stock thickness
panel_thickness = 2;

/* [Slots & Frame Body] */
// How far the acrylic sits into each groove
slot_depth = 6;
// Extra clearance added to slot opening width
slot_tolerance = 0.2;
// Solid wall between neighboring panel slots
gap_between_panels = 3;
// Solid material under the slot floor
frame_under_slot = 2;
// Material outside the first and last slot
outer_wall = 3;
// Long-edge outer chamfer size when bevel_outer is true
bevel_size = 2;

/* [Corner Joint] */
// Clearance on interior tongues / grooves (per side, and on top)
joint_tolerance = 0;
// Fraction of the 45° face used by tongues/slots, measured from the base
interlock_face_fraction = 0.75;
// Tongue/groove thickness inside the wall (stack direction); 0 = auto
tab_thickness = 0;

/* [Print Layout] */
print_spacing = 5;

/* [Hidden] */
eps = 0.05;

// ---------------------------------------------------------------------------
// Derived
// ---------------------------------------------------------------------------
slot_opening = panel_thickness + slot_tolerance;
frame_height = slot_depth + frame_under_slot;
frame_width  = 2 * outer_wall
             + num_panels * slot_opening
             + max(0, num_panels - 1) * gap_between_panels;
wall_count   = num_panels + 1;
interior_wall_count = max(0, wall_count - 2);

// Thin tongue inside the wall — leaves wall material on both sides
tab_t_raw = tab_thickness > 0 ? tab_thickness : min(1.2, gap_between_panels / 2);
// Tongue/slot height along the miter (from the base); top of face left clear for tolerance.
// Cap so interlock_h + joint_tolerance never exceeds frame height.
interlock_h_max = frame_under_slot + slot_depth - joint_tolerance;
interlock_h = min(frame_height * interlock_face_fraction, interlock_h_max);

// Outer pad = material under the slot floor, so acrylic sits inset from
// the outside of the frame (not flush with the outer corner).
// 1-sided: no joining pads; closed free ends add outer_wall caps.
// 2-sided: pad only at the joining corner; free ends stay flush with the panel.
// 4-sided: pad on both ends of each rail.
outer_pad       = frame_under_slot;
rail_pad_count  = num_sides == 1 ? 0 : (num_sides == 2 ? 1 : 2);

end1_mitered = (end_style_1 == "mitered");
end1_closed  = (end_style_1 == "closed");
end2_mitered = (end_style_2 == "mitered");
end2_closed  = (end_style_2 == "closed");

// Closed free ends add an outer_wall-thick cap beyond the panel
end1_cap = end1_closed ? outer_wall : 0;
end2_cap = end2_closed ? outer_wall : 0;
// 1-sided uses both caps on the single rail; 2-sided applies one per free end
bottom_rail_len = panel_length + rail_pad_count * outer_pad
                + (num_sides == 1 ? end1_cap + end2_cap
                 : num_sides == 2 ? end1_cap : 0);
side_rail_len   = panel_width  + rail_pad_count * outer_pad
                + (num_sides == 2 ? end2_cap : 0);
// Panel X inset: closed start-cap on 1-sided; miter pad otherwise
panel_x_inset   = num_sides == 1 ? end1_cap : outer_pad;

// Tongue/groove gender along the stack.
// Even # of interior walls (odd panel count): reversing the stack (flip when
// assembling from the print bed) swaps phase 0 ↔ phase 1. Mating parts must
// use the SAME phase so a flipped piece becomes complementary.
// Odd # of interior walls (even panel count): reverse preserves phase, so
// mating parts use opposite phases.
flip_mates = (interior_wall_count % 2 == 0);
function mate_phase(phase) = flip_mates ? phase : (1 - phase);

// ---------------------------------------------------------------------------
function wall_y(i) =
    (i == 0) ? 0
             : outer_wall + i * slot_opening + (i - 1) * gap_between_panels;

function wall_thickness(i) =
    (i == 0 || i == wall_count - 1) ? outer_wall : gap_between_panels;

function slot_y(i) =
    outer_wall + i * (slot_opening + gap_between_panels);

function interior_wall_id(k) = k + 1;

// Tongue thickness clamped so it fits inside a given wall
function tongue_t(i) =
    min(tab_t_raw, max(0.6, wall_thickness(i) - 1.0));

// Centered Y origin of the tongue/groove inside wall i
function tongue_y(i) =
    wall_y(i) + (wall_thickness(i) - tongue_t(i)) / 2;

// ---------------------------------------------------------------------------
// 2D profile: X = stack, Y = height (slots open +Y)
// ---------------------------------------------------------------------------
module frame_profile(bevel = false) {
    difference() {
        square([frame_width, frame_height]);

        for (i = [0 : num_panels - 1])
            translate([slot_y(i), frame_under_slot])
                square([slot_opening, slot_depth + eps]);

        if (bevel && bevel_size > 0) {
            polygon([
                [-eps, frame_height - bevel_size],
                [-eps, frame_height + eps],
                [bevel_size, frame_height + eps]
            ]);
            polygon([
                [frame_width + eps, frame_height - bevel_size],
                [frame_width - bevel_size, frame_height + eps],
                [frame_width + eps, frame_height + eps]
            ]);
        }
    }
}

// Rail along +X: X=length, Y=stack, Z=base→slots
module slotted_bar(length, bevel = false) {
    rotate([90, 0, 90])
        linear_extrude(height = length, convexity = 10)
            frame_profile(bevel);
}

// ---------------------------------------------------------------------------
// Clean 45° outside miter — whole profile, including all walls & base.
// Removes x < z at the start (base / outer corner is the long point).
// ---------------------------------------------------------------------------
module miter_waste_start() {
    translate([0, frame_width + eps, 0])
        rotate([90, 0, 0])
            linear_extrude(height = frame_width + 2 * eps, convexity = 4)
                polygon([
                    [-eps,               -eps],
                    [-eps,               frame_height + eps],
                    [frame_height + eps, frame_height + eps]
                ]);
}

module miter_waste_end(length) {
    translate([length, 0, 0])
        mirror([1, 0, 0])
            miter_waste_start();
}

// ---------------------------------------------------------------------------
// Triangular tongue / groove in the XZ plane (thin in Y).
//
// Male tongue = right triangle in the miter WASTE region (x <= z):
//   (0,0) — (0,fh) — (fh,fh). Hypotenuse lies on the 45° face; the tongue
//   merges with the base at the outer corner. Height == frame_height.
//
// Female groove = thin parallelogram pocket ALONG the 45° face, cut into
//   the solid (x >= z) by `deepen`. Opens on the miter face for the full
//   face length (base → tip) so the mate's triangular tongue can insert.
//   Previous vertical-rectangle cuts at the tip were wrong (invisible /
//   "blemishes" in print mode, oversized slots when assembled).
// ---------------------------------------------------------------------------
module tongue_triangle_2d() {
    // Waste-side triangle on the lower portion of the miter face only.
    // Hypotenuse lies on the 45° face from the base up to interlock_h.
    h = interlock_h;
    polygon([
        [0, 0],
        [0, h],
        [h, h]
    ]);
}

module groove_triangle_2d() {
    // Solid-side triangle matching the tongue, with joint_tolerance on the
    // sides and top. Bottom stays at z = 0 (no cut into the build-plate
    // base). Top tolerance uses the unused upper quarter of the miter face
    // so it does not run past the top of the rail.
    t = joint_tolerance;
    h = interlock_h;
    top = min(h + t, frame_height);
    polygon([
        [0,     0],
        [h + t, 0],
        [h + t, top]
    ]);
}

module thin_prism_xy(y, thickness) {
    // Extrude a 2D XZ profile (drawn in XY) into a thin prism along Y
    translate([0, y + thickness, 0])
        rotate([90, 0, 0])
            linear_extrude(height = thickness, convexity = 4)
                children();
}

module interior_tongues(at_start = true, length = 0, phase = 0) {
    if (interior_wall_count > 0)
        for (k = [0 : interior_wall_count - 1])
            if (k % 2 == phase) {
                i = interior_wall_id(k);
                y = tongue_y(i);
                t = tongue_t(i);
                if (at_start)
                    thin_prism_xy(y, t)
                        tongue_triangle_2d();
                else
                    translate([length, 0, 0])
                        mirror([1, 0, 0])
                            thin_prism_xy(y, t)
                                tongue_triangle_2d();
            }
}

module interior_grooves(at_start = true, length = 0, phase = 0) {
    if (interior_wall_count > 0)
        for (k = [0 : interior_wall_count - 1])
            if (k % 2 != phase) {
                i = interior_wall_id(k);
                // Lateral clearance: same joint_tolerance used on the top
                t = tongue_t(i) + 2 * joint_tolerance;
                y = wall_y(i) + (wall_thickness(i) - t) / 2;
                if (at_start)
                    thin_prism_xy(y, t)
                        groove_triangle_2d();
                else
                    translate([length, 0, 0])
                        mirror([1, 0, 0])
                            thin_prism_xy(y, t)
                                groove_triangle_2d();
            }
}

// Cap that closes panel slots at a square end (thickness = outer_wall).
// `x` is the start of the cap along the rail. Uses the same outer-edge
// bevel as the rail profile when requested.
module end_cap_at(x, bevel = false) {
    translate([x, 0, 0])
        rotate([90, 0, 90])
            linear_extrude(height = outer_wall, convexity = 4)
                difference() {
                    square([frame_width, frame_height]);
                    if (bevel && bevel_size > 0) {
                        polygon([
                            [-eps, frame_height - bevel_size],
                            [-eps, frame_height + eps],
                            [bevel_size, frame_height + eps]
                        ]);
                        polygon([
                            [frame_width + eps, frame_height - bevel_size],
                            [frame_width - bevel_size, frame_height + eps],
                            [frame_width + eps, frame_height + eps]
                        ]);
                    }
                }
}

// ---------------------------------------------------------------------------
// One rail
//   miter_*       : apply clean 45° end cut
//   interlock_*   : add interior tongue/groove (joining ends only)
//   closed_start  : square start with outer_wall-thick slot cap
//   closed_end    : square end with outer_wall-thick slot cap
// ---------------------------------------------------------------------------
module frame_rail(
    length,
    miter_start = false,
    miter_end = false,
    interlock_start = false,
    interlock_end = false,
    phase_start = 0,
    phase_end = 0,
    bevel = false,
    closed_start = false,
    closed_end = false
) {
    union() {
        difference() {
            slotted_bar(length, bevel);

            if (miter_start)
                miter_waste_start();
            if (miter_end)
                miter_waste_end(length);

            // Grooves cut after miter so they go through the angled face
            // and all the way down through the base.
            if (miter_start && interlock_start)
                interior_grooves(true, length, phase_start);
            if (miter_end && interlock_end)
                interior_grooves(false, length, phase_end);
        }

        // Tongues unioned after miter so they stay un-chamfered, full-height,
        // and merged with the base.
        if (miter_start && interlock_start)
            interior_tongues(true, length, phase_start);
        if (miter_end && interlock_end)
            interior_tongues(false, length, phase_end);

        // Closed square ends: solid walls capping the slots
        if (closed_start)
            end_cap_at(0, bevel);
        if (closed_end)
            end_cap_at(length - outer_wall, bevel);
    }
}

module orient_rail_vertical() {
    multmatrix([
        [0, 0, 1, 0],
        [0, 1, 0, 0],
        [1, 0, 0, 0],
        [0, 0, 0, 1]
    ]) children();
}

// Reverse the panel-stack axis (as when flipping a printed part to stand it up).
module flip_stack() {
    translate([0, frame_width, 0])
        mirror([0, 1, 0])
            children();
}

module acrylic_panels() {
    // Inset so edges sit on the slot floors / against end caps
    color([0.55, 0.8, 1.0, 0.35])
        for (i = [0 : num_panels - 1])
            translate([
                panel_x_inset,
                slot_y(i) + slot_tolerance / 2,
                outer_pad
            ])
                cube([panel_length, panel_thickness, panel_width]);
}

// ---------------------------------------------------------------------------
// 1-sided: single rail; free ends per end_style_1 (start) / end_style_2 (end)
// ---------------------------------------------------------------------------
module assembled_1() {
    color("SteelBlue")
        frame_rail(
            bottom_rail_len,
            miter_start = end1_mitered,
            miter_end = end2_mitered,
            bevel = bevel_outer,
            closed_start = end1_closed,
            closed_end = end2_closed
        );

    if (show_panels)
        acrylic_panels();
}

// ---------------------------------------------------------------------------
// 2-sided: joining end = miter + interlock; free ends per end_style_1 / _2
// ---------------------------------------------------------------------------
module assembled_2() {
    side_phase = mate_phase(0);

    color("SteelBlue")
        frame_rail(
            bottom_rail_len,
            miter_start = true,
            miter_end = end1_mitered,
            interlock_start = true,
            interlock_end = false,
            phase_start = 0,
            bevel = bevel_outer,
            closed_end = end1_closed
        );

    color("CadetBlue")
        orient_rail_vertical()
            // When flip_mates, mirror stack to match flipping the printed side rail
            if (flip_mates)
                flip_stack()
                    frame_rail(
                        side_rail_len,
                        miter_start = true,
                        miter_end = end2_mitered,
                        interlock_start = true,
                        interlock_end = false,
                        phase_start = side_phase,
                        bevel = bevel_outer,
                        closed_end = end2_closed
                    );
            else
                frame_rail(
                    side_rail_len,
                    miter_start = true,
                    miter_end = end2_mitered,
                    interlock_start = true,
                    interlock_end = false,
                    phase_start = side_phase,
                    bevel = bevel_outer,
                    closed_end = end2_closed
                );

    if (show_panels)
        acrylic_panels();
}

module assembled_4() {
    // Length rails: mirrored ends (0 at start/left, 1 at end/right) so a
    // length can be flipped end-for-end and still match the width pair.
    // Width rails: same order on both ends — pairing combo:
    //   left  = phase 1 (mates length's phase-0 ends)
    //   right = phase 0 (mates length's phase-1 ends)
    Lh = bottom_rail_len;
    Lv = side_rail_len;

    // Bottom: start at left (phase 0), end at right (phase 1)
    color("SteelBlue")
        frame_rail(Lh, true, true, true, true, 0, 1, bevel_outer);

    // Right: phase 0 both ends — mates length phase-1 ends
    color("CadetBlue")
        translate([Lh, 0, 0])
            mirror([1, 0, 0])
                orient_rail_vertical()
                    frame_rail(Lv, true, true, true, true, 0, 0, bevel_outer);

    // Top: keep start at world-left (phase 0) and end at world-right (phase 1),
    // slots facing inward (-Z)
    color("SteelBlue")
        translate([0, 0, Lv])
            mirror([1, 0, 0])
                rotate([0, 180, 0])
                    frame_rail(Lh, true, true, true, true, 0, 1, bevel_outer);

    // Left: phase 1 both ends — mates length phase-0 ends
    color("CadetBlue")
        translate([0, 0, Lv])
            mirror([0, 0, 1])
                orient_rail_vertical()
                    frame_rail(Lv, true, true, true, true, 1, 1, bevel_outer);

    if (show_panels)
        acrylic_panels();
}

module printable_parts() {
    if (num_sides == 1) {
        frame_rail(
            bottom_rail_len,
            miter_start = end1_mitered,
            miter_end = end2_mitered,
            bevel = bevel_outer,
            closed_start = end1_closed,
            closed_end = end2_closed
        );
    } else if (num_sides == 2) {
        // Side phase: same as bottom when flip_mates (odd panel count),
        // opposite otherwise — flip one part when standing it up.
        side_phase = mate_phase(0);
        frame_rail(
            bottom_rail_len,
            miter_start = true,
            miter_end = end1_mitered,
            interlock_start = true,
            interlock_end = false,
            phase_start = 0,
            bevel = bevel_outer,
            closed_end = end1_closed
        );
        translate([0, frame_width + print_spacing, 0])
            frame_rail(
                side_rail_len,
                miter_start = true,
                miter_end = end2_mitered,
                interlock_start = true,
                interlock_end = false,
                phase_start = side_phase,
                bevel = bevel_outer,
                closed_end = end2_closed
            );
    } else {
        // 2× length: mirrored ends (0 / 1) — flippable either direction
        // 1× width phase 1/1 (pairs with length phase-0 ends)
        // 1× width phase 0/0 (pairs with length phase-1 ends)
        frame_rail(bottom_rail_len, true, true, true, true, 0, 1, bevel_outer);
        translate([0, 1 * (frame_width + print_spacing), 0])
            frame_rail(bottom_rail_len, true, true, true, true, 0, 1, bevel_outer);
        translate([0, 2 * (frame_width + print_spacing), 0])
            frame_rail(side_rail_len, true, true, true, true, 1, 1, bevel_outer);
        translate([0, 3 * (frame_width + print_spacing), 0])
            frame_rail(side_rail_len, true, true, true, true, 0, 0, bevel_outer);
    }
}

// ---------------------------------------------------------------------------
echo(str("num_sides = ", num_sides));
echo(str("slot_opening = ", slot_opening));
echo(str("frame_width (stack) = ", frame_width));
echo(str("frame_height = ", frame_height));
echo(str("bottom/horizontal rail length = ", bottom_rail_len));
echo(str("side/vertical rail length = ", side_rail_len));
echo(str("tab_t (nominal) = ", tab_t_raw));
echo(str("interlock_h = ", interlock_h));
echo(str("interior_walls = ", interior_wall_count));
echo(str("flip_mates (same print phase) = ", flip_mates));
echo(str("end_style_1 = ", end_style_1));
echo(str("end_style_2 = ", end_style_2));

if (layout == "printable")
    printable_parts();
else if (num_sides == 1)
    assembled_1();
else if (num_sides == 2)
    assembled_2();
else
    assembled_4();
