const std = @import("std");
const rl = @import("raylib");
const Block = @import("block.zig").Block;

pub const World = struct {
    blocks: std.ArrayList(Block),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !World {
        return World{
            .blocks = std.ArrayList(Block).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *World) void {
        self.blocks.deinit();
    }

    pub fn addBLock(self: *World, position: rl.Vector3) !void {
        const block = Block.init(position, 1.0);
        try self.blocks.append(block);
    }

    pub fn render(self: World) void {
        for (self.blocks.items) |block| {
            block.render(true);
        }
    }

    pub fn generateFlat(self: *World, width: i32, depth: i32) !void {
        var x: i32 = 0;
        while (x < width) : (x += 1) {
            var z: i32 = 0;
            while (z < depth) : (z += 1) {
                try self.addBLock(.{ .x = @as(f32, @floatFromInt(x)), .y = 0, .z = @as(f32, @floatFromInt(z)) });
            }
        }
    }
};
