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