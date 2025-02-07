const std = @import("std");
const rl = @import("raylib");
const block = @import("block.zig");
const Player = @import("player.zig").Player;
const World = @import("world.zig").World;

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 450;
const FPS = 244;
const FPS_COORDINATES = 10;
const WORLD_SIZE = 16;

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    rl.initWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Zig Minecraft");
    defer rl.closeWindow();
    rl.setTargetFPS(FPS);

    // CURSOR STAYS IN WINDOW
    rl.disableCursor();

    var player = Player.init(.{ .x = 3.0, .y = 3.0, .z = 3.0 });
    var world = try World.init(allocator);
    defer world.deinit();

    try world.generateFlat(WORLD_SIZE, WORLD_SIZE);

    while (!rl.windowShouldClose()) {
        const dt = rl.getFrameTime();
        player.update(dt);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        rl.beginMode3D(player.camera);

        world.render(false);

        rl.endMode3D();

        rl.drawFPS(FPS_COORDINATES, FPS_COORDINATES);
    }
}
