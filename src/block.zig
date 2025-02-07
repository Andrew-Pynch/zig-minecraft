const rl = @import("raylib");

pub const Block = struct {
    position: rl.Vector3,
    size: f32,

    pub fn init(position: rl.Vector3, size: f32) Block {
        return Block{
            .position = position,
            .size = size,
        };
    }

    pub fn render(self: Block) void {
        rl.drawCube(self.position, self.size, self.size, self.size, rl.Color.red);
        rl.drawCubeWires(self.position, self.size, self.size, self.size, rl.Color.black);
    }
};
