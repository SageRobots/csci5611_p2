public class Vec3 {
    public float x, y, z;

    public Vec3(float x, float y, float z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    public void add(Vec3 delta) {
        x += delta.x;
        y += delta.y;
        z += delta.z;
    }

    public Vec3 add_new(Vec3 delta) {
        return new Vec3(x + delta.x, y + delta.y, z + delta.z);
    }

    public void subtract(Vec3 delta){
        x -= delta.x;
        y -= delta.y;
        z -= delta.z;
    }

    public Vec3 subtract_new(Vec3 delta){
        return new Vec3(x - delta.x, y - delta.y, z - delta.z);
    }
    
    public float length(){
      return sqrt(x*x + y*y + z*z);
    }

    public void mul(float rhs){
        x *= rhs;
        y *= rhs;
        z *= rhs;
    }

    public Vec3 mul_new(float rhs){
        return new Vec3(x*rhs, y*rhs, z*rhs);
    }

    public Vec3 normalize(){
        float magnitude = sqrt(x*x + y*y + z*z);
        float a1 = x/magnitude;
        float a2 = y/magnitude;
        float a3 = z/magnitude;
        return new Vec3(a1, a2, a3);
    }
    
    public float distanceTo(Vec3 rhs){
      float dx = rhs.x - x;
      float dy = rhs.y - y;
      float dz = rhs.z - z;
      return sqrt(dx*dx + dy*dy + dz*dz);
    }

    public float lengthSqr(){
      return x*x + y*y + z*z;
    }

    public Vec3 cross(Vec3 rhs){
      return new Vec3(y*rhs.z - z*rhs.y, z*rhs.x - x*rhs.z, x*rhs.y - y*rhs.x);
    }

    public float dot(Vec3 rhs){
      return x*rhs.x + y*rhs.y + z*rhs.z;
    }
}

float dot(Vec3 a, Vec3 b){
  return a.x*b.x + a.y*b.y + a.z*b.z;
}

Vec3 projAB(Vec3 a, Vec3 b){
  return b.mul_new(a.x*b.x + a.y*b.y + a.z*b.z);
}
