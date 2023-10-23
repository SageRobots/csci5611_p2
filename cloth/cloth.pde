// node class
class Node {
  Vec3 pos;
  Vec3 vel;
  Vec3 last_pos;

  Node(Vec3 pos) {
    this.pos = pos;
    this.vel = new Vec3(0, 0, 0);
    this.last_pos = pos;
  }
}

// sphere class
class Sphere {
  Vec3 pos;
  Vec3 vel = new Vec3(0, 0, 0);
  float radius;

  Sphere(Vec3 pos, float radius) {
    this.pos = pos;
    this.radius = radius;
  }
}

// array of nodes
int NODE_WIDTH = 64;
int NODE_HEIGHT = 64;
Node[][] nodes = new Node[NODE_WIDTH][NODE_HEIGHT];

// sphere
Sphere sphere1 = new Sphere(new Vec3(7.0, 3, 2), 1);

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

Camera camera;

void setup() {
    size(1000, 600, P3D);
    camera = new Camera();

    // initial pos of nodes horizontal coming out in z
    for (int i = 0; i < NODE_WIDTH; i++) {
        for (int j = 0; j < NODE_HEIGHT; j++) {
            nodes[i][j] = new Node(new Vec3(j * link_length + width / 2 / scale , 1, i * link_length));
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

    // draw triangles for groups of 3 nodes
    for (int i = 0; i < NODE_WIDTH - 1; i++) {
        for (int j = 0; j < NODE_HEIGHT - 1; j++) {
            // draw triangle
            fill(0, 150, 150, 200);
            shininess(0.1);
            beginShape(TRIANGLES);
            vertex(nodes[i][j].pos.x * scale, nodes[i][j].pos.y * scale, nodes[i][j].pos.z * scale);
            vertex(nodes[i][j+1].pos.x * scale, nodes[i][j+1].pos.y * scale, nodes[i][j+1].pos.z * scale);
            vertex(nodes[i+1][j].pos.x * scale, nodes[i+1][j].pos.y * scale, nodes[i+1][j].pos.z * scale);
            endShape();
            beginShape(TRIANGLES);
            vertex(nodes[i+1][j].pos.x * scale, nodes[i+1][j].pos.y * scale, nodes[i+1][j].pos.z * scale);
            vertex(nodes[i][j+1].pos.x * scale, nodes[i][j+1].pos.y * scale, nodes[i][j+1].pos.z * scale);
            vertex(nodes[i+1][j+1].pos.x * scale, nodes[i+1][j+1].pos.y * scale, nodes[i+1][j+1].pos.z * scale);
            endShape();
        }
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

void keyPressed() {
    camera.HandleKeyPressed();
    // if z move the sphere left
    if (key == 'z') {
        sphere1.vel.x = -1.5;
    } else if (key == 'x') {
        sphere1.vel.x = 1.5;
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
