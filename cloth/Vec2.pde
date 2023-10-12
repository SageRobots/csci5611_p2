public class Vec2 {
    public float x, y;

    public Vec2(float x, float y) {
        this.x = x;
        this.y = y;
    }

    public void add(Vec2 delta) {
        x += delta.x;
        y += delta.y;
    }

    public Vec2 add_new(Vec2 delta) {
        return new Vec2(x + delta.x, y + delta.y);
    }

    public void subtract(Vec2 delta){
        x -= delta.x;
        y -= delta.y;
    }

    public Vec2 subtract_new(Vec2 delta){
        return new Vec2(x - delta.x, y - delta.y);
    }
    
    public float length(){
      return sqrt(x*x+y*y);
    }

    public void mul(float rhs){
        x *= rhs;
        y *= rhs;
    }

    public Vec2 mul_new(float rhs){
        return new Vec2(x*rhs, y*rhs);
    }

    public Vec2 normalize(){
        float magnitude = sqrt(x*x + y*y);
        x /= magnitude;
        y /= magnitude;
        return new Vec2(x, y);
    }
    
    public float distanceTo(Vec2 rhs){
      float dx = rhs.x - x;
      float dy = rhs.y - y;
      return sqrt(dx*dx + dy*dy);
    }
    public float lengthSqr(){
      return x*x+y*y;
    }
}

float dot(Vec2 a, Vec2 b){
  return a.x*b.x + a.y*b.y;
}

Vec2 projAB(Vec2 a, Vec2 b){
  return b.mul_new(a.x*b.x + a.y*b.y);
}


Vec2 rotate_point(Vec2 origin, Vec2 point, float angle) {
    Vec2 p = point.subtract_new(origin);
    float x = p.x * cos(angle) - p.y * sin(angle);
    float y = p.x * sin(angle) + p.y * cos(angle);
    return new Vec2(x, y).add_new(origin);
}
