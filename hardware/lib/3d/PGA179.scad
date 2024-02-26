PIN_D = 0.02;
PIN_H = 0.125;


pin_locations = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
    [0, 1, 2,                                          15, 16, 17],
    [0, 1, 2,                                          15, 16, 17],
    [0, 1, 2,                                          15, 16, 17],
    [0, 1, 2,                                          15, 16, 17],
    [0, 1, 2,                                          15, 16, 17],
    [0, 1, 2,                                          15, 16, 17],
    [0, 1, 2,                                          15, 16, 17],
    [0, 1, 2,                                          15, 16, 17],
    [0, 1, 2,                                          15, 16, 17],
    [0, 1, 2,                                          15, 16, 17],
    [0, 1, 2,                                          15, 16, 17],
    [0, 1, 2,                                          15, 16, 17],
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
    [   1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]
];

color("#eeeeee") {
    for(row = [0:len(pin_locations) - 1]) {
        for(column = [0:len(pin_locations[row]) - 1]) {
            translate([row * 0.1, pin_locations[row][column] * 0.1, 0])
                pin(PIN_D, PIN_H);
        }
    }
}

color("#333333")
difference() {

    // Socket interface
    translate([-0.05, -0.05, .15])
    union() {
        
        // Base rectangle shape with hole
        difference() {
            cube([1.8, 1.8, 0.1]);
            translate([.457, .457, -.01])
                cube([.885, .885, 0.12]);
        }
        
        // Angled cube
        translate([1.33, .38, 0])
            rotate([0, 0, 45])
                cube([0.3, 0.1, 0.1]);
    }


    // Holes for pins
    translate([0,0, .14])
        for(row = [0:len(pin_locations) - 1]) {
            for(column = [0:len(pin_locations[row]) - 1]) {
                translate([row * 0.1, pin_locations[row][column] * 0.1, 0])
                    pin_hole(PIN_D+0.002, PIN_H);
            }
        }
        
    translate([1.7, -.21, .14])
        rotate([0, 0, 45])
            cube([0.3, 0.1, 0.12]);
}

for(row = [0:len(pin_locations) - 1]) {
    for(column = [0:len(pin_locations[row]) - 1]) {
        translate([row * 0.1, pin_locations[row][column] * 0.1, .25])
            pin_socket(PIN_D, 0.01);
    }
}


module pin_socket(d, h) {
    $fn = 20;
    
    color("gold") {
    
        translate([0, 0, -h]) {
            union() {
                translate([0, 0, h/2])
                    difference() {
                        
                        cylinder(h = h, d = 0.055, center = true);
                        cylinder(h = h * 1.1, d = 0.021, d2 = 0.05, center = true);
                    }
            
                
                translate([0, 0, -.01])
                    difference() {
                        cylinder(h = 0.02, d = 0.023, center = true);
                        cylinder(h = 0.021, d = 0.021, center = true);
                    }
            }
        }
    }
}


module pin(d, h) {
    $fn = 20;
    translate([0, 0, h/2])
        cylinder(h = h, d = d, center = true);
    translate([0, 0, h])
        cylinder(h = h * .4, d = d * 2.5, center = true);
}
module pin_hole(d, h) {
    $fn = 20;
    translate([0, 0, h/2])
        cylinder(h = h * 0.62, d = d, center = true);
    translate([0, 0, h])
        cylinder(h = h * .4, d = d * 2.5, center = true);
}