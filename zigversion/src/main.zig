const std = @import("std");
const rl = @import("raylib");
const block = @import("block.zig");
const Player = @import("player.zig").Player;
const World = @import("world.zig").World;
const CHUNK_SIZE = @import("chunk.zig").CHUNK_SIZE;

const SCREEN_WIDTH = 800;
const SCREEN_HEIGHT = 450;
const FPS = 244;
const FPS_COORDINATES = 10;
const WORLD_SIZE = 16;
const RENDER_DISTANCE = 4;

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

    while (!rl.windowShouldClose()) {
        const dt = rl.getFrameTime();
        const player_chunk_x = @as(i32, @intFromFloat(player.position.x / CHUNK_SIZE));
        const player_chunk_z = @as(i32, @intFromFloat(player.position.z / CHUNK_SIZE));

        // Load chunks around player
        var cx = player_chunk_x - RENDER_DISTANCE;
        while (cx <= player_chunk_x + RENDER_DISTANCE) : (cx += 1) {
            var cz = player_chunk_z - RENDER_DISTANCE;
            while (cz <= player_chunk_z + RENDER_DISTANCE) : (cz += 1) {
                const coord = World.ChunkCoord{ .x = cx, .z = cz };
                _ = try world.getChunk(coord);
            }
        }

        // Unload distant chunks
        var iter = world.chunks.iterator();
        while (iter.next()) |entry| {
            const coord = entry.key_ptr.*;
            const distance_x = @abs(coord.x - player_chunk_x);
            const distance_z = @abs(coord.z - player_chunk_z);

            if (distance_x > RENDER_DISTANCE or distance_z > RENDER_DISTANCE) {
                _ = world.chunks.remove(coord);
            }
        }

        player.update(dt);
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.black);
        rl.beginMode3D(player.camera);
        world.render();
        rl.endMode3D();
        rl.drawFPS(FPS_COORDINATES, FPS_COORDINATES);
    }
}
