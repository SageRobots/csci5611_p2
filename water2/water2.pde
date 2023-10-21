int n = 64;   // number of cells
float dx = 1000.0 / (float)n; // length of each cell
float dy = dx;
float dt = 0.05;
  
float[][] h = new float[n][n]; // height
float[][] hu = new float[n][n]; // Momentum
float[][] hv = new float[n][n]; // Momentum in y direction
float scale = 20.0;

int num_substeps = 30;
boolean paused = true;
  
void setup() {
    size(1000, 600, P3D);
    // camera(500, 300, 500, 500, 500, 0, 0, 1, 0);
    // Initalize Simulation
    // for (int i = 0; i < n; i++) {
    //     for (int j = 0; j < n; j++) {
    //         h[i][j] = 11.0;
    //     }
    // }

    // vertical wave
    // for (int i = n/2-1; i < n/2+2; i++) {
    //     for (int j = 0; j < n; j++) {
    //         h[i][j] = 3.0;
    //     }
    // }

    // horizontal wave
    // for (int i = n/2-1; i < n/2+2; i++) {
    //     for (int j = 0; j < n; j++) {
    //         h[j][i] = 3.0;
    //     }
    // }

    // circle wave
    int wave_r = 10;
    int wave_x = 25;
    int wave_y = n-25;
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            // check if inside circle
            float dist = sqrt((i-wave_x)*(i-wave_x) + (j-wave_y)*(j-wave_y));
            if (dist < wave_r) {
                h[i][j] = 11.0 + wave_r - dist;
            } else {
                h[i][j] = 11.0;
            }
        }
    }

    // for (int i = n/2-wave; i <= n/2+wave; i++) {
    //     for (int j = n/2-wave; j <= n/2+wave; j++) {
    //         h[j][i] = 13.0;
    //     }
    // }

    frameRate(1.0 / dt);
}

void draw() {
    // pause at each loop
    if (!paused) {
        for (int i = 0; i < num_substeps; i++) update(dt);
        // paused = true;
        background(255);
        // lights();
        ambientLight(128, 128, 128);
        directionalLight(128, 128, 128, 1, 1, 0);
        // Simulate
        // Draw Water
        stroke(0, 0, 255);
        strokeWeight(10);
        noStroke();
        fill(0, 0, 255);
        for (int i = 0; i < n-1; i++) {
            for (int j = 0; j < n-1; j++) {
                // x spans from 0 to width
                float x1 = i * width / (float)(n - 1);
                float x2 = (i + 1) * width / (float)(n - 1);
                float y1 = height - (h[i][j]-1)*scale + 200;
                float y2 = height - (h[i+1][j]-1)*scale + 200;
                float x3 = x2;
                float x4 = x1;
                float y3 = height - (h[i+1][j+1]-1)*scale + 200;
                float y4 = height - (h[i][j+1]-1)*scale + 200;
                // z related to j
                float z1 = j * width / (float)(n - 1);
                float z2 = (j + 1) * width / (float)(n - 1);
                z1 = -z1;
                z2 = -z2;
                // print zs
                // println(z1, z2);
                // print y1s
                // println(y1);
                // line(x1, y1, x2, y2);
                // quad(x1, y1, x2, y2, x3, y3, x4, y4);
                // draw 3d shape
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
    float damp = 0.8;
    
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
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            // h[i][j] = constrain(h[i][j], 8, 13);
            // hu[i][j] = constrain(hu[i][j], -10, 10);
            // hv[i][j] = constrain(hv[i][j], -10, 10);
        }
    }
}

// detect spacebar key
void keyPressed() {
    if (key == ' ') {
        paused = false;
    }
}
