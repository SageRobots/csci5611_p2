
// array of nodes
int NODE_WIDTH = 64;
int NODE_HEIGHT = 64;
int rip_height = 0;
int rip_width = 0;
boolean rip = false;
Node[][] nodes = new Node[NODE_WIDTH][NODE_HEIGHT];

// sphere
Sphere sphere1 = new Sphere(new Vec3(7, 3, 2), 1.0);

// Link length
float link_length = 4.0 / (NODE_WIDTH - 1);

// Gravity
Vec3 gravity = new Vec3(0, 5.0, 0);

float scale = 100.0;
float dt = 0.07;
Vec3 base_pos = new Vec3(500 / scale, 1, 0);

int num_substeps = 10;
int num_relaxation_steps = 20;
float clip_factor = 1.02;

PrintWriter output;

boolean scene3d = true;
boolean leftrightMove = false;
boolean frontbackMove = false;

// Air density (ρ), cross-sectional area (a), and drag coefficient (cd)
float airDensity = 1.225;  
// float crossSectionalArea = 1.0;  
float dragCoefficient = 20.0;  
Vec3 windVelocity = new Vec3(0.0, 0.0, 0.0); 
boolean airDrag = true;
boolean paused = true;
Camera camera;

void setup() {
    size(1000, 563, P3D);
    // width = 1000;
    camera = new Camera();

    // initial pos of nodes horizontal coming out in z
    for (int i = 0; i < NODE_WIDTH; i++) {
        for (int j = 0; j < NODE_HEIGHT; j++) {
            nodes[i][j] = new Node(new Vec3(j * link_length + width / 2 / scale , 1, i * link_length));
        }
    }

    frameRate(30);
}


void draw() {
    if (paused) return;
    // update nodes for num_substeps
    for (int i = 0; i < num_substeps; i++) update(dt / num_substeps);

    camera.Update(1.0/frameRate);

    // if rip, increase rip width by 1
    if (rip && rip_width < NODE_WIDTH) {
        rip_width++;
    }

    background(255);
    noStroke();
    // lights();
    ambientLight(128, 128, 128);
    directionalLight(128, 128, 128, -1/sqrt(3), 1/sqrt(3), -1/sqrt(3));
    spotLight(128, 128, 128, 700, 0, 200, 0, 1, 0, PI/2.0, 1);
    spotLight(128, 128, 128, 400, 0, 0, 1, 1, 1, PI/2.0, 1);

    // draw a sphere to collide with
    fill(100, 0, 200);
    pushMatrix();
    translate(sphere1.pos.x * scale, sphere1.pos.y * scale, sphere1.pos.z * scale);
    specular(255, 255, 255);
    shininess(5.0);
    sphere(sphere1.radius * scale);
    popMatrix();

    // draw triangles for groups of 3 nodes
    for (int i = 0; i < NODE_WIDTH - 1; i++) {
        for (int j = 0; j < NODE_HEIGHT - 1; j++) {
            if (j == rip_height && i < rip_width && rip) continue;
            Vec3[] triangle = new Vec3[3];
            triangle[0] = nodes[i][j].pos;
            triangle[1] = nodes[i][j+1].pos;
            triangle[2] = nodes[i+1][j].pos;

            fill(0, 200, 200, 200);
            beginShape(TRIANGLES);
            vertex(triangle[0].x * scale, triangle[0].y * scale, triangle[0].z * scale);
            vertex(triangle[1].x * scale, triangle[1].y * scale, triangle[1].z * scale);
            vertex(triangle[2].x * scale, triangle[2].y * scale, triangle[2].z * scale);
            endShape();

            Vec3[] triangle2 = new Vec3[3];
            triangle2[0] = nodes[i+1][j].pos;
            triangle2[1] = nodes[i][j+1].pos;
            triangle2[2] = nodes[i+1][j+1].pos;

            fill(0, 200, 200, 200);
            beginShape(TRIANGLES);
            vertex(triangle2[0].x * scale, triangle2[0].y * scale, triangle2[0].z * scale);
            vertex(triangle2[1].x * scale, triangle2[1].y * scale, triangle2[1].z * scale);
            vertex(triangle2[2].x * scale, triangle2[2].y * scale, triangle2[2].z * scale);
            endShape();
            
        }
    }

    // display the instruction text
    // fill(0);
    // textSize(12);
    // text("Press 'a' or 'd' to activate sphere left-right movement", 650, 20);
    // text("Press 'w' or 's' to toggle sphere front-back movement", 650, 40);
    // text("Press 'z' or 'x' to move the camera", 650, 60);
    // text("Press 'space' to toggle air drag", 650, 80);

    // fill(255, 0, 0);
    // text(str(leftrightMove), 950, 20);
    // text(str(airDrag), 950, 80);
    // text(str(frontbackMove), 950, 40);
    // text("Press '1' to toggle gravity", 10, 180);
    // text("Press '2' to toggle wind", 10, 200);

}

void update(float dt) {
    // update sphere
    sphere1.pos = sphere1.pos.add_new(sphere1.vel.mul_new(dt));

    // update node positions
    for (int i = 0; i < NODE_WIDTH; i++) {
        for (int j = 1; j < NODE_HEIGHT; j++) {
            // save last position
            nodes[i][j].last_pos = nodes[i][j].pos;
            // update velocity with gravity
            nodes[i][j].vel = nodes[i][j].vel.add_new(gravity.mul_new(dt));
        }
    }

    // store drag force for each node
    Vec3[][] drag_force = new Vec3[NODE_WIDTH][NODE_HEIGHT];
    // initialize drag force to zero
    for (int i = 0; i < NODE_WIDTH; i++) {
        for (int j = 0; j < NODE_HEIGHT; j++) {
            drag_force[i][j] = new Vec3(0, 0, 0);
        }
    }
    // compute drag force for each triangle
    Vec3 relative_vel = new Vec3(0, 0, 0);
    float cross_section_area = 0;
    Vec3 drag_force_triangle = new Vec3(0, 0, 0);
    Vec3 drag_force_triangle2 = new Vec3(0, 0, 0);
    if (airDrag) {
    for (int i = 0; i < NODE_WIDTH - 1; i++) {
        for (int j = 0; j < NODE_HEIGHT - 1; j++) {
            if (j == rip_height && i < rip_width && rip) continue;
            Vec3[] triangle = new Vec3[3];
            triangle[0] = nodes[i][j].pos;
            triangle[1] = nodes[i][j+1].pos;
            triangle[2] = nodes[i+1][j].pos;
            // vector from 0 to 1
            Vec3 v1 = triangle[1].subtract_new(triangle[0]);
            // vector from 0 to 2
            Vec3 v2 = triangle[2].subtract_new(triangle[0]);
            // compute average velocity of nodes
            Vec3 avg_vel = nodes[i][j].vel.add_new(nodes[i][j+1].vel).add_new(nodes[i+1][j].vel).mul_new(1.0 / 3.0);
            // compute relative velocity to wind
            relative_vel = avg_vel.subtract_new(windVelocity);
            // relative_vel = avg_vel;
            // compute relative velocity unit vector
            Vec3 relative_vel_unit = relative_vel.normalize();
            // compute cross section area: v1 cross v2 dot relative_vel_unit
            cross_section_area = v1.cross(v2).dot(relative_vel_unit) / 2.0;
            // compute drag force
            drag_force_triangle = relative_vel_unit.mul_new(0.5 * airDensity * relative_vel.length() * relative_vel.length() * dragCoefficient * cross_section_area);
            Vec3 drag_force_node = drag_force_triangle.mul_new(1.0 / 3.0);
            // add the drag force to each node
            drag_force[i][j] = drag_force[i][j].add_new(drag_force_node);
            drag_force[i][j+1] = drag_force[i][j+1].add_new(drag_force_node);
            drag_force[i+1][j] = drag_force[i+1][j].add_new(drag_force_node);

            Vec3[] triangle2 = new Vec3[3];
            triangle2[0] = nodes[i+1][j].pos;
            triangle2[1] = nodes[i][j+1].pos;
            triangle2[2] = nodes[i+1][j+1].pos;
            // vector from 0 to 1
            Vec3 v3 = triangle2[1].subtract_new(triangle2[0]);
            // vector from 0 to 2
            Vec3 v4 = triangle2[2].subtract_new(triangle2[0]);
            // compute average velocity of nodes
            Vec3 avg_vel2 = nodes[i+1][j].vel.add_new(nodes[i][j+1].vel).add_new(nodes[i+1][j+1].vel).mul_new(1.0 / 3.0);
            // compute relative velocity to wind
            Vec3 relative_vel2 = avg_vel2.subtract_new(windVelocity);
            // Vec3 relative_vel2 = avg_vel2;
            // compute relative velocity unit vector
            Vec3 relative_vel_unit2 = relative_vel2.normalize();
            // compute cross section area: v1 cross v2 dot relative_vel_unit
            float cross_section_area2 = v3.cross(v4).dot(relative_vel_unit2) / 2.0;
            // compute drag force
            drag_force_triangle2 = relative_vel_unit2.mul_new(0.5 * airDensity * relative_vel2.length() * relative_vel2.length() * dragCoefficient * cross_section_area2);
            Vec3 drag_force_node2 = drag_force_triangle2.mul_new(1.0 / 3.0);
            // add the drag force to each node
            drag_force[i+1][j] = drag_force[i+1][j].add_new(drag_force_node2);
            drag_force[i][j+1] = drag_force[i][j+1].add_new(drag_force_node2);
            drag_force[i+1][j+1] = drag_force[i+1][j+1].add_new(drag_force_node2);
        }
    }
    }
    // print relative velocity
    // println("relative vel: ", relative_vel.length());
    // print cross section area
    // println("cross section area: ", cross_section_area);
    // print drag force triangle 1 then 2
    // println("drag force triangle 1: ", drag_force_triangle.x, drag_force_triangle.y, drag_force_triangle.z);
    // println("drag force triangle 2: ", drag_force_triangle2.x, drag_force_triangle2.y, drag_force_triangle2.z);


    for (int i = 0; i < NODE_WIDTH; i++) {
        for (int j = 1; j < NODE_HEIGHT; j++) {
            // update velocity with drag force
            nodes[i][j].vel = nodes[i][j].vel.add_new(drag_force[i][j].mul_new(dt));
            
            // if (airDrag) {
            //     // Calculate relative velocity of the node
            //     Vec3 nodeVelocity = nodes[i][j].vel;
            //     Vec3 relativeVelocity = nodeVelocity.subtract_new(windVelocity);
            //     float relativeVelocityMag = relativeVelocity.length();

            //     // Calculate drag force using Lord Rayleigh's drag equation
            //     Vec3 dragForce = relativeVelocity.mul_new(-0.5 * airDensity * relativeVelocityMag * relativeVelocityMag * dragCoefficient * crossSectionalArea);

            //     // Apply the drag force to the node
            //     nodes[i][j].vel = nodes[i][j].vel.add_new(dragForce.mul_new(dt));
            // }
            
            // update position with velocity
            nodes[i][j].pos = nodes[i][j].pos.add_new(nodes[i][j].vel.mul_new(dt));
            
        }
    }
    // print drag force
    // println("drag: ", drag_force[10][10].x, drag_force[10][10].y, drag_force[10][10].z);


    // relaxation
    for (int i = 0; i < num_relaxation_steps; i++) relax();

    // check for collision with sphere
    for (int i = 0; i < NODE_WIDTH; i++) {
        for (int j = 0; j < NODE_HEIGHT; j++) {
            // see if node is inside sphere
            Vec3 delta = nodes[i][j].pos.subtract_new(sphere1.pos);
            float delta_len = delta.length();
            if (delta_len < sphere1.radius * clip_factor) {
                // move node to surface of sphere
                nodes[i][j].pos = sphere1.pos.add_new(delta.normalize().mul_new(sphere1.radius * clip_factor));
            }
        }
    }

    // update node velocities
    for (int i = 0; i < NODE_WIDTH; i++) {
        for (int j = 0; j < NODE_HEIGHT; j++) {
            nodes[i][j].vel = nodes[i][j].pos.subtract_new(nodes[i][j].last_pos).mul_new(1.0 / dt);
        }
    }

    // set base row to zero velocity
    for (int i = 0; i < NODE_HEIGHT; i++) {
        nodes[i][0].vel = new Vec3(0, 0, 0);
    }

    // update the sphere position along with mouse
    // Vec3 mouse_pos = new Vec3(5, 3, 2);
    // if (leftrightMove) { // move sphere left and right
    //     mouse_pos.z = (width - 500 - mouseX) / scale;
    //     mouse_pos.x = 5;
    // }
    // if (frontbackMove) { // move sphere front and back
    //     mouse_pos.x = mouseX / scale * 0.8;
    //     mouse_pos.z = 2;
    // }

    // sphere1.pos = mouse_pos;

    // checkForRipping();
}

void relax() {
    // update nodes using position based dynamics
    for (int i = 0; i < NODE_WIDTH; i++) {
        for (int j = 1; j < NODE_HEIGHT; j++) {
            if (j == rip_height + 1 && i < rip_width && rip) continue;
            Vec3 delta = nodes[i][j].pos.subtract_new(nodes[i][j - 1].pos);
            float delta_len = delta.length();
            float correction = delta_len - link_length;
            Vec3 delta_normalized = delta.normalize();
            nodes[i][j].pos = nodes[i][j].pos.subtract_new(delta_normalized.mul_new(correction / 2.0));
            nodes[i][j-1].pos = nodes[i][j-1].pos.add_new(delta_normalized.mul_new(correction / 2.0));
        }
    }
    // update nodes using position based dynamics across
    for (int i = 1; i < NODE_WIDTH; i++) {
        for (int j = 0; j < NODE_HEIGHT; j++) {
            Vec3 delta = nodes[i][j].pos.subtract_new(nodes[i - 1][j].pos);
            float delta_len = delta.length();
            float correction = delta_len - link_length;
            Vec3 delta_normalized = delta.normalize();
            nodes[i][j].pos = nodes[i][j].pos.subtract_new(delta_normalized.mul_new(correction / 2.0));
            nodes[i-1][j].pos = nodes[i-1][j].pos.add_new(delta_normalized.mul_new(correction / 2.0));
        }
    }
    // move base row back to original position
    for (int i = 0; i < NODE_HEIGHT; i++) {
        nodes[i][0].pos.y = 1;
        nodes[i][0].pos.x = 5;
        nodes[i][0].pos.z = i * link_length;
    }
}

void keyPressed() {
    camera.HandleKeyPressed();
    // if z move the sphere left
    if (key == 'z') {
        sphere1.vel.x = -1.5;
    } else if (key == 'x') {
        sphere1.vel.x = 1.5;
    }
    if (key == 'p') paused = false;
    // if (key == 'f' || key == 'g') {
    //     leftrightMove = !leftrightMove;
    //     frontbackMove = false;
    // }
    // if (key == 'y' || key == 't') {
    //     frontbackMove = !frontbackMove;
    //     leftrightMove = false;
    // }
    // if r, rip cloth
    if (key == 'r') {
        rip = true;
        // random rip height
        rip_height = (NODE_HEIGHT * 2) / 3;
        rip_width = 0;
    }
    // press space to toggle air drag
    if (key == ' ') {
        // increase wind velocity
        windVelocity.x += 5.0;
    }
}

void keyReleased() {
    camera.HandleKeyReleased();
    if (key == 'z') {
        sphere1.vel.x = 0;
    } else if (key == 'x') {
        sphere1.vel.x = 0;
    }
}
