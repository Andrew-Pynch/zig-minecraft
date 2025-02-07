const std = @import("std");
const rl = @import("raylib");
const Block = @import("block.zig").Block;
const Chunk = @import("chunk.zig").Chunk;
const CHUNK_SIZE = @import("chunk.zig").CHUNK_SIZE;

pub const World = struct {
    chunks: std.AutoHashMap(ChunkCoord, Chunk),
    allocator: std.mem.Allocator,

    pub const ChunkCoord = struct {
        x: i32,
        z: i32,

        pub fn hash(self: ChunkCoord) u64 {
            return @as(u64, @bitCast(self.x)) << 32 | @as(u64, @bitCast(self.z));
        }

        pub fn eql(a: ChunkCoord, b: ChunkCoord) bool {
            return a.x == b.x and a.z == b.z;
        }
    };

    pub fn init(allocator: std.mem.Allocator) !World {
        return World{
            .chunks = std.AutoHashMap(ChunkCoord, Chunk).init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *World) void {
        var iter = self.chunks.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.deinit();
        }
        self.chunks.deinit();
    }

    pub fn getChunk(self: *World, coord: ChunkCoord) !*Chunk {
        const entry = try self.chunks.getOrPut(coord);
        if (!entry.found_existing) {
            const position = rl.Vector3{
                .x = @floatFromInt(coord.x * CHUNK_SIZE),
                .y = 0,
                .z = @floatFromInt(coord.z * CHUNK_SIZE),
            };
            entry.value_ptr.* = try Chunk.init(self.allocator, position);
            try self.generateChunk(entry.value_ptr);
            entry.value_ptr.generateMesh();
        }
        return entry.value_ptr;
    }

    fn generateChunk(_self: *World, chunk: *Chunk) !void {
        _ = _self; // autofix
        // Simple flat terrain generation
        for (0..CHUNK_SIZE) |xu| {
            const x = @as(i32, @intCast(xu));
            for (0..CHUNK_SIZE) |zu| {
                const z = @as(i32, @intCast(zu));
                const height = 4;
                chunk.setBlock(
                    x,
                    height,
                    z,
                    1,
                );
            }
        }
    }

    pub fn render(self: *World) void {
        var iter = self.chunks.iterator();
        while (iter.next()) |entry| {
            const chunk = entry.value_ptr;
            if (chunk.mesh) |mesh| {
                rl.drawMesh(mesh, chunk.material.?, rl.Matrix.identity());
            }
        }
    }
};
