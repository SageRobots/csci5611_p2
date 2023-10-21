int n = 128;   // number of cells
float dx = 1000.0 / (float)n; // length of each cell
float dy = dx;
float dt = 0.1;
  
float[][] h = new float[n][n]; // height
float[][] h_temp = new float[n+2][n+2]; // height
float[][] hu = new float[n][n]; // Momentum
float[][] hv = new float[n][n]; // Momentum in y direction
float scale = 20.0;

int num_substeps = 30;
boolean paused = true;

float[][] kernel = new float[3][3];
float k1 = 1.0;
float k2 = 300.0;
float k_sum = 4*k1 + k2;

PShape boat;

void setup() {
    size(1000, 600, P3D);
    camera(500, -100, 300, 500, 300, -650, 0, 1, 0);

    kernel[0][0] = 0.0/k_sum;
    kernel[0][1] = k1/k_sum;
    kernel[0][2] = 0.0/k_sum;
    kernel[1][0] = k1/k_sum;
    kernel[1][1] = k2/k_sum;
    kernel[1][2] = k1/k_sum;
    kernel[2][0] = 0.0/k_sum;
    kernel[2][1] = k1/k_sum;
    kernel[2][2] = 0.0/k_sum;
    // circle wave
    int wave_r = 20;
    int wave_x = 50;
    int wave_y = n-50;
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            // check if inside circle
            float dist = sqrt((i-wave_x)*(i-wave_x) + (j-wave_y)*(j-wave_y));
            if (dist < wave_r) {
                h[i][j] = 11.0 + (wave_r - dist) / 2.0;
            } else {
                h[i][j] = 11.0;
            }
        }
    }

    frameRate(30.0);

    boat = loadShape("duck.obj");
    boat.scale(40);
    boat.setFill(color(255, 255, 0));
}

void draw() {
    // pause at each loop
    if (!paused) {
        for (int i = 0; i < num_substeps; i++) update(dt);
        // paused = true;
        // background sky blue
        background(0, 128, 255);
        // lights();
        ambientLight(128, 128, 128);
        directionalLight(128, 128, 128, 1, 1, 0);
        lightSpecular(255, 255, 255);
        spotLight(255, 255, 255, 375, 100, -1000, 1, 1, 1, PI/2, 2);
        noStroke();

        // white box for back of tub
        fill(255, 255, 255);
        pushMatrix();
        translate(width/2, height*2-100, -width);
        box(width, height*3, 50);
        popMatrix();
        // white box for left side of tub
        pushMatrix();
        translate(0, height*2-100, -width/2 - 25);
        box(50, height*3, width);
        popMatrix();
        // white box for right side of tub 
        pushMatrix();
        translate(width, height*2-100, -width/2 - 25);
        box(50, height*3, width);
        popMatrix();

        // orange fill
        fill(255, 128, 0);
        float box_height;
        // loop to create 3 buoys
        for (int i = 0; i < 3; i++) {
            int cx = (i+1)*n/4;
            // set box height to height of water at center
            // compute average height in square under box
            box_height = 0;
            for (int k = cx-5; k < cx+5; k++) {
                for (int l = n/2-5; l < n/2+5; l++) {
                    box_height += h[k][l];
                }
            }
            box_height /= 100.0;
            box_height = height - box_height * scale + 50;
            // translate to center
            pushMatrix();
            translate((i+1)*width/4, box_height, -width/2);
            // set rotation to angle of water at center
            float dhdx = (h[cx+5][n/2] - h[cx-5][n/2]) / (10*dx);
            dhdx *= scale;
            // compute angle
            float angle = atan2(1, dhdx) - PI/2.0;
            rotateX(PI/2);
            rotateY(angle);
            // repeat for y direction
            float dhdy = (h[cx][n/2+5] - h[cx][n/2-5]) / (10*dy);
            dhdy *= scale;
            float angle_y = atan2(1, dhdy) - PI/2.0;
            rotateX(angle_y);
            // box(75,75,75);
            
            shape(boat);

            popMatrix();
        }
        // Draw Water
        stroke(0, 0, 255);
        strokeWeight(10);
        noStroke();
        for (int i = 0; i < n-1; i++) {
            for (int j = 0; j < n-1; j++) {
                // x spans from 0 to width
                float x1 = i * width / (float)(n - 1);
                float x2 = (i + 1) * width / (float)(n - 1);
                int offset = 0;
                float y1 = height - h[i][j]*scale + offset;
                float y2 = height - h[i+1][j]*scale + offset;
                float x3 = x2;
                float x4 = x1;
                float y3 = height - h[i+1][j+1]*scale + offset;
                float y4 = height - h[i][j+1]*scale + offset;
                // z related to j
                float z1 = j * width / (float)(n - 1);
                float z2 = (j + 1) * width / (float)(n - 1);
                z1 = -z1;
                z2 = -z2;
                // draw 3d shape
                fill(0, 0, 255, 230);
                specular(255, 255, 255);
                shininess(1.0);
                beginShape(QUADS);
                // front
                // vertex(x1, y1, z1);
                // vertex(x2, y2, z1);
                // vertex(x3, y3, z1);
                // vertex(x4, y4, z1);
                // top
                vertex(x1, y1, z1);
                vertex(x2, y2, z1);
                vertex(x2, y3, z2);
                vertex(x1, y4, z2);
                endShape();
            }
        }


    }
}  
  
void update(float dt) {
    float g = 1.0;  // gravity
    float damp = 1.0;
    
    float[][] dhdt = new float[n][n]; // Height derivative
    float[][] dhudt = new float[n][n];  // Momentum derivative in x direction
    float[][] dhvdt = new float[n][n];  // Momentum derivative in y direction
    
    float[][] h_midx = new float[n][n];  // Height (midpoint)
    float[][] h_midy = new float[n][n]; 
    float[][] hu_mid = new float[n][n]; // Momentum (midpoint)
    float[][] hv_mid = new float[n][n]; // Momentum (midpoint) in y direction
    
    float[][] dhdt_midx = new float[n][n]; // Height derivative (midpoint)
    float[][] dhdt_midy = new float[n][n];
    float[][] dhudt_mid = new float[n][n];  // Momentum derivative (midpoint)
    float[][] dhvdt_mid = new float[n][n];  // Momentum derivative (midpoint) in y direction

    // zero out certain terms for testing
    float x = 1;
    float y = 1;
    float diag = 1;
  
    // Compute midpoint heights and momentums
    for (int i = 0; i < n-1; i++) {
        for (int j = 0; j < n-1; j++) {
            // h_mid[i][j] = (h[i][j] + h[i+1][j] + h[i][j+1] + h[i+1][j+1]) / 4.0;
            // if (y == 0) {
                h_midx[i][j] = (h[i][j] + h[i+1][j]) / 2.0;
            // } else if (x == 0) {
                h_midy[i][j] = (h[i][j] + h[i][j+1]) / 2.0;
            // } else {
                // h_mid[i][j] = (2*h[i][j] + h[i+1][j] + h[i][j+1]) / 4.0;
            // }
            // x direction
            hu_mid[i][j] = (hu[i][j] + hu[i+1][j]) / 2.0;
            hu_mid[i][j] *= x;
            // y direction
            hv_mid[i][j] = (hv[i][j] + hv[i][j+1]) / 2.0;
            hv_mid[i][j] *= y;
        }
    }
  
    // Compute derivates at midpoints
    for (int i = 0; i < n-1; i++) {
        for (int j = 0; j < n-1; j++) {
            // Compute dh/dt (mid)
            float dhudx_mid = (hu[i+1][j] - hu[i][j])/dx;
            dhudx_mid *= x;
            float dhvdy_mid = (hv[i][j+1] - hv[i][j])/dy;
            dhvdy_mid *= y;
            dhdt_midx[i][j] = -dhudx_mid;
            dhdt_midy[i][j] = -dhvdy_mid;
            
            // Compute dhu/dt (mid)   
            float dhu2dx_mid = (hu[i+1][j] * hu[i+1][j] / h[i+1][j] - hu[i][j] * hu[i][j] / h[i][j]) / dx;
            float dgh2dx_mid = g * (h[i+1][j] * h[i+1][j] - h[i][j] * h[i][j]) / dx;
            float dhuvdy_mid = (hu[i][j+1] * hv[i][j+1] / h[i][j+1] - hu[i][j] * hv[i][j] / h[i][j]) / dy;
            dhuvdy_mid *= x*y*diag;
            dhudt_mid[i][j] = -(dhu2dx_mid + 0.5*dgh2dx_mid) - dhuvdy_mid;

            // compute dhv/dt (mid)
            float dhv2dy_mid = (hv[i][j+1] * hv[i][j+1] / h[i][j+1] - hv[i][j] * hv[i][j] / h[i][j]) / dy;
            float dgh2dy_mid = g * (h[i][j+1] * h[i][j+1] - h[i][j] * h[i][j]) / dy;
            float dhuvdx_mid = (hu[i+1][j] * hv[i+1][j] / h[i+1][j] - hu[i][j] * hv[i][j] / h[i][j]) / dx;
            dhuvdx_mid *= x*y*diag;
            dhvdt_mid[i][j] = -(dhv2dy_mid + 0.5*dgh2dy_mid) - dhuvdx_mid;
        }
    }
  
    // Update midpoints for 1/2 a timestep based on midpoint derivatives
    for (int i = 0; i < n-1; i++) {
        for (int j = 0; j < n-1; j++) {
            h_midx[i][j] += dhdt_midx[i][j]*dt / 2.0;
            h_midy[i][j] += dhdt_midy[i][j]*dt / 2.0;
            hu_mid[i][j] += dhudt_mid[i][j]*dt / 2.0;
            hv_mid[i][j] += dhvdt_mid[i][j]*dt / 2.0;
        }
    }
  
    // Compute height and momentum updates (non-midpoint)
    for (int i = 1; i < n-1; i++) {
        for (int j = 1; j < n-1; j++) {
            // Compute dh/dt
            float dhudx = (hu_mid[i][j] - hu_mid[i-1][j]) / dx;
            dhudx *= x;
            float dhvdy = (hv_mid[i][j] - hv_mid[i][j-1]) / dy;
            dhvdy *= y;
            dhdt[i][j] = -dhudx - dhvdy;
            
            // Compute dhu/dt
            float dhu2dx = (hu_mid[i][j] * hu_mid[i][j] / h_midx[i][j] - hu_mid[i-1][j] * hu_mid[i-1][j] / h_midx[i-1][j]) / dx;
            float dgh2dx = g * (h_midx[i][j] * h_midx[i][j] - h_midx[i-1][j] * h_midx[i-1][j]) / dx;
            float dhuvdy = (hu_mid[i][j] * hv_mid[i][j] / h_midy[i][j] - hu_mid[i][j-1] * hv_mid[i][j-1] / h_midy[i][j-1]) / dy;
            dhuvdy *= x*y*diag;
            dhudt[i][j] = -(dhu2dx + 0.5*dgh2dx) - dhuvdy;

            // compute dhv/dt
            float dhv2dy = (hv_mid[i][j] * hv_mid[i][j] / h_midy[i][j] - hv_mid[i][j-1] * hv_mid[i][j-1] / h_midy[i][j-1]) / dy;
            float dgh2dy = g * (h_midy[i][j] * h_midy[i][j] - h_midy[i][j-1] * h_midy[i][j-1]) / dy;
            float dhuvdx = (hu_mid[i][j] * hv_mid[i][j] / h_midx[i][j] - hu_mid[i-1][j] * hv_mid[i-1][j] / h_midx[i-1][j]) / dx;
            dhuvdx *= x*y*diag;
            dhvdt[i][j] = -(dhv2dy + 0.5*dgh2dy) - dhuvdx;
        }
    }
  
    // Update values (non-midpoint) based on full timestep
    for (int i = 1; i < n-1; i++) {
        for (int j = 1; j < n-1; j++) {
            h[i][j] += damp * dhdt[i][j]*dt;
            hu[i][j] += damp * dhudt[i][j]*dt;
            hv[i][j] += damp * dhvdt[i][j]*dt;
        }
    }
  
    // Reflecting boundary conditions
    for (int i = 0; i < n; i++) {
        h[i][0] = h[i][1];
        h[i][n-1] = h[i][n-2];
        hv[i][0] = -hv[i][1];
        hv[i][n-1] = -hv[i][n-2];
    }
    for (int j = 0; j < n; j++) {
        h[0][j] = h[1][j];
        h[n-1][j] = h[n-2][j];
        hu[0][j] = -hu[1][j];
        hu[n-1][j] = -hu[n-2][j];
    }

    // clamp height and momentum
    // for (int i = 0; i < n; i++) {
    //     for (int j = 0; j < n; j++) {
    //         // h[i][j] = constrain(h[i][j], 8, 13);
    //         // float plim = 8;
    //         // hu[i][j] = constrain(hu[i][j], -plim, plim);
    //         // hv[i][j] = constrain(hv[i][j], -plim, plim);
    //     }
    // }

    // smooth height with convolution
    // float[][] h_new = new float[n][n];
    // pad h
    float pad = 11.0;
    for (int i = 0; i < n; i++) {
        h_temp[i+1][0] = pad;
        h_temp[i+1][n+1] = pad;
        for (int j = 0; j < n; j++) {
            h_temp[i+1][j+1] = h[i][j];
        }
    }
    for (int j = 0; j < n; j++) {
        h_temp[0][j+1] = pad;
        h_temp[n+1][j+1] = pad;
    }

    // convolve
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            float sum = 0;
            for (int k = 0; k < 3; k++) {
                for (int l = 0; l < 3; l++) {
                    sum += kernel[k][l] * h_temp[i+k][j+l];
                }
            }
            h[i][j] = sum;
        }
    }

}

// detect spacebar key
void keyPressed() {
    if (key == ' ') {
        paused = false;
    }
}
