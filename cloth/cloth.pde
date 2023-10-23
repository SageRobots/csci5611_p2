
// array of nodes
int NODE_WIDTH = 64;
int NODE_HEIGHT = 64;
Node[][] nodes = new Node[NODE_WIDTH][NODE_HEIGHT];

// sphere
Sphere sphere1 = new Sphere(new Vec3(7.0, 3, 2), 0.5);

// Link length
float link_length = 4.0 / (NODE_WIDTH - 1);

// Gravity
Vec3 gravity = new Vec3(0, 10, 0);

float scale = 100.0;
float dt = 0.05;
Vec3 base_pos = new Vec3(500 / scale, 1, 0);

int num_substeps = 10;
int num_relaxation_steps = 10;
float clip_factor = 1.02;
float length_error;
float energy;
long start_time, current_time;

PrintWriter output;

boolean scene3d = true;
boolean leftrightMove = false;
boolean frontbackMove = false;

// Air density (ρ), cross-sectional area (a), and drag coefficient (cd)
float airDensity = 1.225;  
float crossSectionalArea = 1.0;  
float dragCoefficient = 0.5;  
Vec3 windVelocity = new Vec3(1.5, 0.0, 0.0); 
boolean airDrag = false;

ArrayList<Spring> springs = new ArrayList<Spring>();
ArrayList<Spring> springsToRemove = new ArrayList<Spring>();
ArrayList<Node> tornNodes = new ArrayList<Node>();

Camera camera;

void setup() {
    size(1000, 600, P3D);
    camera = new Camera();

    // initial pos of nodes horizontal coming out in z
    for (int i = 0; i < NODE_WIDTH; i++) {
        for (int j = 0; j < NODE_HEIGHT; j++) {
            nodes[i][j] = new Node(new Vec3(j * link_length + width / 2 / scale , 1, i * link_length));

            // Connect nodes horizontally (create springs)
            if (i > 0) {
                Spring horizontalSpring = new Spring(nodes[i][j], nodes[i - 1][j], link_length, 100);
                springs.add(horizontalSpring);
            }

            // Connect nodes vertically (create springs)
            if (j > 0) {
                Spring verticalSpring = new Spring(nodes[i][j], nodes[i][j - 1], link_length, 100);
                springs.add(verticalSpring);
            }
        }
    }

    frameRate(1.0 / dt);
}


void draw() {
    // update nodes for num_substeps
    for (int i = 0; i < num_substeps; i++) update(dt / num_substeps);

    camera.Update(1.0/frameRate);

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

    ArrayList<Vec3[]> detachedTriangles = new ArrayList<Vec3[]>();

    // draw triangles for groups of 3 nodes
    for (int i = 0; i < NODE_WIDTH - 1; i++) {
        for (int j = 0; j < NODE_HEIGHT - 1; j++) {
            Vec3[] triangle = new Vec3[3];
            triangle[0] = nodes[i][j].pos;
            triangle[1] = nodes[i][j+1].pos;
            triangle[2] = nodes[i+1][j].pos;

            // Check if any of the nodes in the triangle is torn
            boolean triangleHasTornNode = false;
            if (nodes[i][j].isTorn || nodes[i][j+1].isTorn || nodes[i+1][j].isTorn) {
                triangleHasTornNode = true;
            }

            if (!triangleHasTornNode) {
                fill(0, 200, 200, 150);
                beginShape(TRIANGLES);
                vertex(triangle[0].x * scale, triangle[0].y * scale, triangle[0].z * scale);
                vertex(triangle[1].x * scale, triangle[1].y * scale, triangle[1].z * scale);
                vertex(triangle[2].x * scale, triangle[2].y * scale, triangle[2].z * scale);
                endShape();
            } else {
                // If the triangle has torn nodes, add it to the detachedTriangles list
                detachedTriangles.add(triangle);
            }

            Vec3[] triangle2 = new Vec3[3];
            triangle2[0] = nodes[i+1][j].pos;
            triangle2[1] = nodes[i][j+1].pos;
            triangle2[2] = nodes[i+1][j+1].pos;

            // Check if any of the nodes in the second triangle is torn
            boolean triangle2HasTornNode = false;
            if (nodes[i+1][j].isTorn || nodes[i][j+1].isTorn || nodes[i+1][j+1].isTorn) {
                triangle2HasTornNode = true;
            }

            if (!triangle2HasTornNode) {
                fill(0, 200, 200, 150);
                beginShape(TRIANGLES);
                vertex(triangle2[0].x * scale, triangle2[0].y * scale, triangle2[0].z * scale);
                vertex(triangle2[1].x * scale, triangle2[1].y * scale, triangle2[1].z * scale);
                vertex(triangle2[2].x * scale, triangle2[2].y * scale, triangle2[2].z * scale);
                endShape();
            } else {
                // If the second triangle has torn nodes, add it to the detachedTriangles list
                detachedTriangles.add(triangle2);
            }
            
        }
    }

    // // Update the positions of detached triangles
    // for (Vec3[] triangle : detachedTriangles) {
    //     for (int k = 0; k < 3; k++) {
    //         // Simulate falling freely by applying gravity
    //         triangle[k].add(gravity);  // Adjust the vector according to the desired fall speed
    //     }
    // }

    // // Render the detached triangles
    // fill(0, 200, 200, 150);
    // for (Vec3[] triangle : detachedTriangles) {
    //     beginShape(TRIANGLES);
    //     for (int k = 0; k < 3; k++) {
    //         vertex(triangle[k].x * scale, triangle[k].y * scale, triangle[k].z * scale);
    //     }
    //     endShape();
    // }

    // Clear the detachedTriangles list for the next frame
    // detachedTriangles.clear();
    // Render the removed springs
    stroke(255, 0, 0);  // Red color for removed springs
    strokeWeight(2);

    for (Spring spring : springsToRemove) {
        line(spring.node1.pos.x * scale, spring.node1.pos.y * scale, spring.node1.pos.z * scale,
             spring.node2.pos.x * scale, spring.node2.pos.y * scale, spring.node2.pos.z * scale);
    }

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
            
            if (airDrag) {
                // Calculate relative velocity of the node
                Vec3 nodeVelocity = nodes[i][j].vel;
                Vec3 relativeVelocity = nodeVelocity.subtract_new(windVelocity);
                float relativeVelocityMag = relativeVelocity.length();

                // Calculate drag force using Lord Rayleigh's drag equation
                Vec3 dragForce = relativeVelocity.mul_new(-0.5 * airDensity * relativeVelocityMag * relativeVelocityMag * dragCoefficient * crossSectionalArea);

                // Apply the drag force to the node
                nodes[i][j].vel = nodes[i][j].vel.add_new(dragForce.mul_new(dt));
            }
            
            // update position with velocity
            nodes[i][j].pos = nodes[i][j].pos.add_new(nodes[i][j].vel.mul_new(dt));
            
        }
    }

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
    Vec3 mouse_pos = new Vec3(5, 3, 2);
    if (leftrightMove) { // move sphere left and right
        mouse_pos.z = (width - 500 - mouseX) / scale;
        mouse_pos.x = 5;
    }
    if (frontbackMove) { // move sphere front and back
        mouse_pos.x = mouseX / scale * 0.8;
        mouse_pos.z = 2;
    }

    sphere1.pos = mouse_pos;

    checkForRipping();
}

void relax() {
    // update nodes using position based dynamics
    for (int i = 0; i < NODE_WIDTH; i++) {
        for (int j = 1; j < NODE_HEIGHT; j++) {
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

void checkForRipping() {
    
    for (Spring spring : springs) {
        spring.calculateForce();

        // println(spring.getForce().length());
        // check if spring is too long
        float forceThreshold = 7;
        if (spring.getForce().length() > forceThreshold) {
            println("ripped");

            // Add the spring to the list of springs to remove 
            springsToRemove.add(spring);
        
            // Mark the nodes as torn
            spring.node1.isTorn = true;
            spring.node2.isTorn = true;

        }
    }

    for (Spring spring : springsToRemove) {
        springs.remove(spring);
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
    if (key == 'a' || key == 'd') {
        leftrightMove = !leftrightMove;
        frontbackMove = false;
    }
    if (key == 'w' || key == 's') {
        frontbackMove = !frontbackMove;
        leftrightMove = false;
    }
    // press space to toggle air drag
    if (key == ' ') {
        println("Airdrag: " + airDrag);
        airDrag = !airDrag;
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
