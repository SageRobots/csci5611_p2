
// Node struct
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
// array of 25 nodes
int NODE_WIDTH = 5;
int NODE_HEIGHT = 5;
Node[][] nodes = new Node[NODE_WIDTH][NODE_HEIGHT];

// Link length
float link_length = 0.2;

// Gravity
Vec2 gravity = new Vec2(0, 10);

float scale = 100.0;
float dt = 0.07;
Vec3 base_pos = new Vec3(500 / scale, 1, 0);

int num_substeps = 100;
int num_relaxation_steps = 100;
float length_error;
float energy;
float run_time = 30;
long start_time, current_time;
PrintWriter output;

void setup() {
    size(1000, 600, P3D);
    // camera(500.0, 300.0, 400.0, 500.0, 300.0, 0.0, 
    //     0.0, 1.0, 0.0);
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
    // for (int i = 0; i < num_substeps; i++) update(dt / num_substeps);
    
    background(255);

    // draw triangles for groups of 3 nodes
    for (int i = 0; i < NODE_WIDTH - 1; i++) {
        for (int j = 0; j < NODE_HEIGHT - 1; j++) {
            // draw triangle
            fill(0, 255, 0);
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

    // draw links
    // for (int i = 0; i < nodes.length - 1; i++) {
    //     line(nodes[i].pos.x * scale, nodes[i].pos.y * scale, nodes[i + 1].pos.x * scale, nodes[i + 1].pos.y * scale);
    // }

    // // draw nodes
    // for (int i = 0; i < nodes.length; i++) {
    //     fill(0, 255, 0);
    //     ellipse(nodes[i].pos.x * scale, nodes[i].pos.y * scale, 0.15 * scale, 0.15 * scale);
    // }
}

// void update(float dt) {
//     // update node positions
//     for (int i = 1; i < nodes.length; i++) {
//         // save last position
//         nodes[i].last_pos = nodes[i].pos;
//         // update position
//         nodes[i].vel = nodes[i].vel.add_new(gravity.mul_new(dt));
//         nodes[i].pos = nodes[i].pos.add_new(nodes[i].vel.mul_new(dt));
//     }

//     // relaxation
//     for (int i = 0; i < num_relaxation_steps; i++) relax();

//     // update node velocities
//     for (int i = 1; i < nodes.length; i++) {
//         nodes[i].vel = nodes[i].pos.subtract_new(nodes[i].last_pos).mul_new(1.0 / dt);
//     }
// }

// void relax() {
//     // update nodes using position based dynamics, leave node 0 fixed
//     for (int i = 1; i < nodes.length; i++) {
//         // constrain to link length
//         Vec2 delta = nodes[i].pos.subtract_new(nodes[i-1].pos);
//         // print delta
//         // println(delta.x + " " + delta.y);
//         float delta_len = delta.length();
//         float correction = delta_len - link_length;
//         // print correction
//         // println(correction);
//         Vec2 delta_normalized = delta.normalize();
//         nodes[i].pos = nodes[i].pos.subtract_new(delta_normalized.mul_new(correction / 2.0));
//         nodes[i-1].pos = nodes[i-1].pos.add_new(delta_normalized.mul_new(correction / 2.0));
//         // move base back to original position
//         nodes[0].pos = base_pos;
//     }
// }