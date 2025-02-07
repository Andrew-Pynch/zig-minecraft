const std = @import("std");
const rl = @import("raylib");
const block = @import("block.zig");
const Player = @import("player.zig").Player;
const World = @import("world.zig").World;

pub fn main() anyerror!void {
    const screenWidth = 800;
    const screenHeight = 450;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    rl.initWindow(screenWidth, screenHeight, "zig-minecraft");
    defer rl.closeWindow();
    rl.setTargetFPS(244);

    // CURSOR STAYS IN WINDOW
    rl.disableCursor();

    var player = Player.init(.{ .x = 0, .y = 0, .z = 0 });
    var world = try World.init(allocator);
    defer world.deinit();

    try world.generateFlat(1, 1);

    while (!rl.windowShouldClose()) {
        const dt = rl.getFrameTime();
        player.update(dt);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        rl.beginMode3D(player.camera);

        world.render();

        rl.endMode3D();

        rl.drawFPS(10, 10);
    }
}
