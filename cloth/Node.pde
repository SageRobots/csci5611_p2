// node class

class Node {
  Vec3 pos;
  Vec3 vel;
  Vec3 last_pos;
  ArrayList<Spring> connectedSprings;
  boolean isTorn;

  Node(Vec3 pos) {
    this.pos = pos;
    this.vel = new Vec3(0, 0, 0);
    this.last_pos = pos;
    this.connectedSprings = new ArrayList<Spring>();
    this.isTorn = false;
  }

}
