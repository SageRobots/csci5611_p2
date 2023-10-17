int n = 32;   // number of cells
float dx = 1000.0 / (float)n; // length of each cell
float dt = 0.05;
  
float[][] h = new float[n][n]; // height
float[][] hu = new float[n][n]; // Momentum
float[][] hv = new float[n][n]; // Momentum in y direction
float scale = 20.0;

int num_substeps = 20;
boolean paused = true;
  
void setup() {
    size(1000, 600, P3D);
    // camera(500, 300, 500, 500, 500, 0, 0, 1, 0);
    // Initalize Simulation
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            h[i][j] = 1.0;
        }
    }
    // big wave in the middle
    for (int i = n/2-5; i < n/2+5; i++) {
        for (int j = n/2-5; j < n/2+5; j++) {
            h[n/2][n/2] = 3.0;
        }
    }

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
                float y1 = height - (h[i][j]-1)*scale - 10;
                float y2 = height - (h[i+1][j]-1)*scale - 10;
                float x3 = x2;
                float x4 = x1;
                float y3 = height - (h[i+1][j+1]-1)*scale - 10;
                float y4 = height - (h[i][j+1]-1)*scale - 10;
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
    float g = 10.0;  // gravity
    float damp = 0.9;
    
    float[][] dhdt = new float[n][n]; // Height derivative
    float[][] dhudt = new float[n][n];  // Momentum derivative in x direction
    float[][] dhvdt = new float[n][n];  // Momentum derivative in y direction
    
    float[][] h_mid = new float[n][n];  // Height (midpoint)
    float[][] hu_mid = new float[n][n]; // Momentum (midpoint)
    float[][] hv_mid = new float[n][n]; // Momentum (midpoint) in y direction
    
    float[][] dhdt_mid = new float[n][n]; // Height derivative (midpoint)
    float[][] dhudt_mid = new float[n][n];  // Momentum derivative (midpoint)
    float[][] dhvdt_mid = new float[n][n];  // Momentum derivative (midpoint) in y direction
  
    // Compute midpoint heights and momentums
    for (int i = 0; i < n-1; i++) {
        for (int j = 0; j < n-1; j++) {
            h_mid[i][j] = (h[i][j] + h[i+1][j] + h[i][j+1]) / 3.0;
            // x direction
            hu_mid[i][j] = (hu[i][j] + hu[i+1][j]) / 2.0;
            // y direction
            hv_mid[i][j] = (hv[i][j] + hv[i][j+1]) / 2.0;
        }
    }
  
    // Compute derivates at midpoints
    for (int i = 0; i < n-1; i++) {
        for (int j = 0; j < n-1; j++) {
            // Compute dh/dt (mid)
            float dhudx_mid = (hu[i+1][j] - hu[i][j])/dx;
            float dhvdx_mid = (hv[i][j+1] - hv[i][j])/dx;
            dhdt_mid[i][j] = -dhudx_mid - dhvdx_mid;
            
            // Compute dhu/dt (mid)   
            float dhu2dx_mid = (hu[i+1][j]*hu[i+1][j]/h[i+1][j] - hu[i][j]*hu[i][j]/h[i][j])/dx;
            float dgh2dx_mid = g*(h[i+1][j]*h[i+1][j] - h[i][j]*h[i][j])/dx;
            float dhuvdy_mid = (hu[i+1][j]*hv[i][j+1]/h[i+1][j] - hu[i][j]*hv[i][j]/h[i][j])/dx;
            dhudt_mid[i][j] = -(dhu2dx_mid + 0.5*dgh2dx_mid) - dhuvdy_mid;

            // compute dhv/dt (mid)
            float dhv2dy_mid = (hv[i][j+1]*hv[i][j+1]/h[i][j+1] - hv[i][j]*hv[i][j]/h[i][j])/dx;
            float dgh2dy_mid = g*(h[i][j+1]*h[i][j+1] - h[i][j]*h[i][j])/dx;
            float dhuvdx_mid = (hu[i+1][j]*hv[i][j+1]/h[i+1][j] - hu[i][j]*hv[i][j]/h[i][j])/dx;
            dhvdt_mid[i][j] = -(dhv2dy_mid + 0.5*dgh2dy_mid) - dhuvdx_mid;
        }
    }
  
    // Update midpoints for 1/2 a timestep based on midpoint derivatives
    for (int i = 0; i < n-1; i++) {
        for (int j = 0; j < n-1; j++) {
            h_mid[i][j] += dhdt_mid[i][j]*dt / 2.0;
            hu_mid[i][j] += dhudt_mid[i][j]*dt / 2.0;
            hv_mid[i][j] += dhvdt_mid[i][j]*dt / 2.0;
        }
    }
  
    // Compute height and momentum updates (non-midpoint)
    for (int i = 1; i < n-1; i++) {
        for (int j = 1; j < n-1; j++) {
            // Compute dh/dt
            float dhudx = (hu_mid[i][j] - hu_mid[i-1][j])/dx;
            float dhvdy = (hv_mid[i][j] - hv_mid[i][j-1])/dx;
            dhdt[i][j] = -dhudx - dhvdy;
            
            // Compute dhu/dt
            float dhu2dx = (hu_mid[i][j]*hu_mid[i][j]/h_mid[i][j] - hu_mid[i-1][j]*hu_mid[i-1][j]/h_mid[i-1][j])/dx;
            float dgh2dx = g*(h_mid[i][j]*h_mid[i][j] - h_mid[i-1][j]*h_mid[i-1][j])/dx;
            float dhuvdy = (hu_mid[i][j]*hv_mid[i][j]/h_mid[i][j] - hu_mid[i-1][j]*hv_mid[i][j-1]/h_mid[i][j-1])/dx;
            dhudt[i][j] = -(dhu2dx + 0.5*dgh2dx) - dhuvdy;

            // compute dhv/dt
            float dhv2dy = (hv_mid[i][j]*hv_mid[i][j]/h_mid[i][j] - hv_mid[i][j-1]*hv_mid[i][j-1]/h_mid[i][j-1])/dx;
            float dgh2dy = g*(h_mid[i][j]*h_mid[i][j] - h_mid[i][j-1]*h_mid[i][j-1])/dx;
            float dhuvdx = (hu_mid[i][j]*hv_mid[i][j]/h_mid[i][j] - hu_mid[i-1][j]*hv_mid[i][j-1]/h_mid[i-1][j])/dx;
            dhvdt[i][j] = -(dhv2dy + 0.5*dgh2dy) - dhuvdx;
        }
    }
  
    // Update values (non-midpoint) based on full timestep
    for (int i = 1; i < n-1; i++) {
        for (int j = 1; j < n-1; j++) {
            h[i][j] += dhdt[i][j]*dt;
            hu[i][j] += dhudt[i][j]*dt;
            hv[i][j] += dhvdt[i][j]*dt;
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

}

// detect spacebar key
void keyPressed() {
    if (key == ' ') {
        paused = false;
    }
}
