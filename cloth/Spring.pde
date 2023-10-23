// spring class
class Spring {
    Node node1;
    Node node2;
    float rest_length;
    float stiffness;
    private Vec3 force;

    Spring(Node node1, Node node2, float rest_length, float stiffness) {
        this.node1 = node1;
        this.node2 = node2;
        this.rest_length = rest_length;
        this.stiffness = stiffness;
        this.force = new Vec3(0, 0, 0);
    }

    void calculateForce() {
        Vec3 dir = node1.pos.subtract_new(node2.pos);
        float currentLength = dir.length();
        float displacement = currentLength - rest_length;
        force = dir.normalize().mul_new(stiffness * displacement);
    }

    Vec3 getForce() {
        return force;
    }
}