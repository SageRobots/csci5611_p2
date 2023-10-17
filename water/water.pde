int n = 64;   // number of cells
float dx = 1000.0 / (float)n; // length of each cell
float dt = 0.05;
  
float[] h = new float[n]; // height
float[] hu = new float[n]; // Momentum
float scale = 20.0;

int num_substeps = 20;
boolean paused = true;
  
void setup() {
    size(1000, 600, P3D);
    // Initalize Simulation
    for (int i = 0; i < n; i++) {
        h[i] = 1;
    }
    // big wave in the middle
    h[n/2-1] = 3;
    h[n/2] = 3;
    h[n/2+1] = 3;

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
            // x spans from 0 to width
            float x1 = i * width / (float)(n - 1);
            float x2 = (i + 1) * width / (float)(n - 1);
            float y1 = height - (h[i]-1)*scale - 100;
            float y2 = height - (h[i+1]-1)*scale - 100;
            float x3 = x2;
            float x4 = x1;
            float y3 = height;
            float y4 = height;
            float z1 = 0;
            float z2 = -50 * scale;
            // print y1s
            // println(y1);
            // line(x1, y1, x2, y2);
            // quad(x1, y1, x2, y2, x3, y3, x4, y4);
            // draw 3d shape
            beginShape(QUADS);
            // front
            vertex(x1, y1, z1);
            vertex(x2, y2, z1);
            vertex(x3, y3, z1);
            vertex(x4, y4, z1);
            // top
            vertex(x1, y1, z1);
            vertex(x2, y2, z1);
            vertex(x2, y2, z2);
            vertex(x1, y1, z2);
            endShape();
        }
    }
}  
  
void update(float dt) {
    float g = 10.0;  // gravity
    float damp = 0.9;
    
    float[] dhdt = new float[n]; // Height derivative
    float[] dhudt = new float[n];  // Momentum derivative
    
    float[] h_mid = new float[n];  // Height (midpoint)
    float[] hu_mid = new float[n]; // Momentum (midpoint)
    
    float[] dhdt_mid = new float[n]; // Height derivative (midpoint)
    float[] dhudt_mid = new float[n];  // Momentum derivative (midpoint)
  
    // Compute midpoint heights and momentums
    for (int i = 0; i < n-1; i++) {
        h_mid[i] = (h[i] + h[i+1]) / 2.0;
        hu_mid[i] = (hu[i] + hu[i+1]) / 2.0;
    }
  
    // Compute derivates at midpoints
    for (int i = 0; i < n-1; i++) {
        // Compute dh/dt (mid)
        float dhudx_mid = (hu[i+1] - hu[i])/dx;
        dhdt_mid[i] = -dhudx_mid;
        
        // Compute dhu/dt (mid)   
        float dhu2dx_mid = (hu[i+1]*hu[i+1]/h[i+1] - hu[i]*hu[i]/h[i])/dx;
        float dgh2dx_mid = (g*h[i+1]*h[i+1] - h[i]*h[i])/dx;
        dhudt_mid[i] = -(dhu2dx_mid + 0.5*dgh2dx_mid);
        // print dhudt_mid[i]
        // println("dhudt_mid[i]: " + dhudt_mid[i]);
    }
  
    // Update midpoints for 1/2 a timestep based on midpoint derivatives
    for (int i = 0; i < n-1; i++) {
        h_mid[i] += dhdt_mid[i]*dt / 2.0;
        hu_mid[i] += dhudt_mid[i]*dt / 2.0;
        // print hu_mid[i]
        // println("hu_mid[i]: " + hu_mid[i]);
    }
  
    // Compute height and momentum updates (non-midpoint)
    for (int i = 1; i < n-1; i++) {
        // Compute dh/dt
        float dhudx = (hu_mid[i] - hu_mid[i-1])/dx;
        dhdt[i] = -dhudx;
        // print dhdt[i]
        // println("dhdt[i]: " + dhdt[i]);
        
        // Compute dhu/dt
        float dhu2dx = (hu_mid[i]*hu_mid[i]/h_mid[i] - hu_mid[i-1]*hu_mid[i-1]/h_mid[i-1])/dx;
        float dgh2dx = g*(h_mid[i]*h_mid[i] - h_mid[i-1]*h_mid[i-1])/dx;
        dhudt[i] = -(dhu2dx + 0.5*dgh2dx);
    }
  
    // Update values (non-midpoint) based on full timestep
    for (int i = 1; i < n-1; i++) {
        h[i] += dhdt[i]*dt;
        // print h[i]
        // println("h[i]: " + h[i]);
        hu[i] += dhudt[i]*dt;
    }
  
    // Reflecting boundary conditions
    h[0] = h[1];
    h[n-1] = h[n-2];
    hu[0] = -hu[1];
    hu[n-1] = -hu[n-2];
}

// detect spacebar key
void keyPressed() {
    if (key == ' ') {
        paused = false;
    }
}
