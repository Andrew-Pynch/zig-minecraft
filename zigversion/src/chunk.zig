const std = @import("std");
const rl = @import("raylib");
const Block = @import("block.zig").Block;
const Face = @import("block.zig").Face;

pub const CHUNK_SIZE = 16;
pub const CHUNK_VOLUME = CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE;

pub const Chunk = struct {
    blocks: []u16,
    position: rl.Vector3,
    mesh: ?rl.Mesh,
    material: ?rl.Material,
    needs_rebuild: bool,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, position: rl.Vector3) !Chunk {
        return Chunk{
            .blocks = try allocator.alloc(u16, CHUNK_VOLUME),
            .position = position,
            .mesh = null,
            .material = null,
            .needs_rebuild = true,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Chunk) void {
        self.allocator.free(self.blocks);
        if (self.mesh) |mesh| {
            rl.unloadMesh(mesh);
        }
        if (self.material) |material| {
            rl.unloadMaterial(material);
        }
    }

    pub fn getBlock(self: *Chunk, x: i32, y: i32, z: i32) u16 {
        if (x < 0 or x >= CHUNK_SIZE or y < 0 or y >= CHUNK_SIZE or z < 0 or z >= CHUNK_SIZE) {
            return 0; // Air
        }
        return self.blocks[@intCast(x + z * CHUNK_SIZE + y * CHUNK_SIZE * CHUNK_SIZE)];
    }

    pub fn setBlock(self: *Chunk, x: i32, y: i32, z: i32, block_id: u16) void {
        if (x < 0 or x >= CHUNK_SIZE or y < 0 or y >= CHUNK_SIZE or z < 0 or z >= CHUNK_SIZE) return;
        self.blocks[@intCast(x + z * CHUNK_SIZE + y * CHUNK_SIZE * CHUNK_SIZE)] = block_id;
        self.needs_rebuild = true;
    }

    pub fn generateMesh(self: *Chunk) void {
        // Unload existing mesh
        if (self.mesh) |old_mesh| {
            rl.unloadMesh(old_mesh);
            self.mesh = null;
        }

        var positions = std.ArrayList(rl.Vector3).initCapacity(self.allocator, CHUNK_VOLUME * 6 * 6) catch return;
        defer positions.deinit();
        var normals = std.ArrayList(rl.Vector3).initCapacity(self.allocator, CHUNK_VOLUME * 6 * 6) catch return;
        defer normals.deinit();
        var texcoords = std.ArrayList(rl.Vector2).initCapacity(self.allocator, CHUNK_VOLUME * 6 * 6) catch return;
        defer texcoords.deinit();

        for (0..CHUNK_SIZE) |xu| {
            const x = @as(i32, @intCast(xu));
            for (0..CHUNK_SIZE) |yu| {
                const y = @as(i32, @intCast(yu));
                for (0..CHUNK_SIZE) |zu| {
                    const z = @as(i32, @intCast(zu));
                    const block_id = self.getBlock(x, y, z);
                    if (block_id == 0) continue;

                    const base_x = self.position.x + @as(f32, @floatFromInt(x));
                    const base_y = self.position.y + @as(f32, @floatFromInt(y));
                    const base_z = self.position.z + @as(f32, @floatFromInt(z));

                    // Check adjacent blocks to determine visible faces
                    if (self.getBlock(x, y + 1, z) == 0) {
                        addFace(&positions, &normals, &texcoords, base_x, base_y, base_z, .top);
                    }
                    if (self.getBlock(x, y - 1, z) == 0) {
                        addFace(&positions, &normals, &texcoords, base_x, base_y, base_z, .bottom);
                    }
                    if (self.getBlock(x, y, z + 1) == 0) {
                        addFace(&positions, &normals, &texcoords, base_x, base_y, base_z, .front);
                    }
                    if (self.getBlock(x, y, z - 1) == 0) {
                        addFace(&positions, &normals, &texcoords, base_x, base_y, base_z, .back);
                    }
                    if (self.getBlock(x + 1, y, z) == 0) {
                        addFace(&positions, &normals, &texcoords, base_x, base_y, base_z, .right);
                    }
                    if (self.getBlock(x - 1, y, z) == 0) {
                        addFace(&positions, &normals, &texcoords, base_x, base_y, base_z, .left);
                    }
                }
            }
        }

        const num_vertices = positions.items.len;
        if (num_vertices == 0) {
            self.mesh = null;
            return;
        }

        // Convert vertices to flat arrays
        var vertices = self.allocator.alloc(f32, num_vertices * 3) catch return;
        defer self.allocator.free(vertices);
        var normals_arr = self.allocator.alloc(f32, num_vertices * 3) catch return;
        defer self.allocator.free(normals_arr);
        var uvs = self.allocator.alloc(f32, num_vertices * 2) catch return;
        defer self.allocator.free(uvs);

        for (0..num_vertices) |i| {
            const pos = positions.items[i];
            vertices[i * 3] = pos.x;
            vertices[i * 3 + 1] = pos.y;
            vertices[i * 3 + 2] = pos.z;

            const norm = normals.items[i];
            normals_arr[i * 3] = norm.x;
            normals_arr[i * 3 + 1] = norm.y;
            normals_arr[i * 3 + 2] = norm.z;

            const uv = texcoords.items[i];
            uvs[i * 2] = uv.x;
            uvs[i * 2 + 1] = uv.y;
        }

        var mesh = rl.Mesh{
            .vertexCount = @intCast(num_vertices),
            .triangleCount = @intCast(num_vertices / 3),
            .vertices = vertices.ptr,
            .texcoords = uvs.ptr,
            .normals = normals_arr.ptr,
            .colors = null,
            .indices = null,
            .animVertices = null,
            .animNormals = null,
            .boneIds = null,
            .boneWeights = null,
            .vaoId = 0,
            .vboId = null,
            .texcoords2 = null,
            .tangents = null,
            .boneCount = 0,
            .boneMatrices = null,
        };

        rl.uploadMesh(&mesh, false);
        self.mesh = mesh;
        self.material = rl.loadMaterialDefault() catch null;
        self.needs_rebuild = false;
    }
};

fn addFace(
    positions: *std.ArrayList(rl.Vector3),
    normals: *std.ArrayList(rl.Vector3),
    texcoords: *std.ArrayList(rl.Vector2),
    base_x: f32,
    base_y: f32,
    base_z: f32,
    face: Face,
) void {
    const s: f32 = 1.0;
    const normal: rl.Vector3 = switch (face) {
        .front => .{ .x = 0, .y = 0, .z = 1 },
        .back => .{ .x = 0, .y = 0, .z = -1 },
        .right => .{ .x = 1, .y = 0, .z = 0 },
        .left => .{ .x = -1, .y = 0, .z = 0 },
        .top => .{ .x = 0, .y = 1, .z = 0 },
        .bottom => .{ .x = 0, .y = -1, .z = 0 },
    };

    var vertices: [6]rl.Vector3 = undefined;
    switch (face) {
        .front => {
            vertices[0] = .{ .x = base_x, .y = base_y, .z = base_z + s };
            vertices[1] = .{ .x = base_x + s, .y = base_y, .z = base_z + s };
            vertices[2] = .{ .x = base_x + s, .y = base_y + s, .z = base_z + s };
            vertices[3] = .{ .x = base_x, .y = base_y, .z = base_z + s };
            vertices[4] = .{ .x = base_x + s, .y = base_y + s, .z = base_z + s };
            vertices[5] = .{ .x = base_x, .y = base_y + s, .z = base_z + s };
        },
        .back => {
            vertices[0] = .{ .x = base_x + s, .y = base_y, .z = base_z };
            vertices[1] = .{ .x = base_x, .y = base_y, .z = base_z };
            vertices[2] = .{ .x = base_x, .y = base_y + s, .z = base_z };
            vertices[3] = .{ .x = base_x + s, .y = base_y, .z = base_z };
            vertices[4] = .{ .x = base_x, .y = base_y + s, .z = base_z };
            vertices[5] = .{ .x = base_x + s, .y = base_y + s, .z = base_z };
        },
        .right => {
            vertices[0] = .{ .x = base_x + s, .y = base_y, .z = base_z + s };
            vertices[1] = .{ .x = base_x + s, .y = base_y, .z = base_z };
            vertices[2] = .{ .x = base_x + s, .y = base_y + s, .z = base_z };
            vertices[3] = .{ .x = base_x + s, .y = base_y, .z = base_z + s };
            vertices[4] = .{ .x = base_x + s, .y = base_y + s, .z = base_z };
            vertices[5] = .{ .x = base_x + s, .y = base_y + s, .z = base_z + s };
        },
        .left => {
            vertices[0] = .{ .x = base_x, .y = base_y, .z = base_z };
            vertices[1] = .{ .x = base_x, .y = base_y, .z = base_z + s };
            vertices[2] = .{ .x = base_x, .y = base_y + s, .z = base_z + s };
            vertices[3] = .{ .x = base_x, .y = base_y, .z = base_z };
            vertices[4] = .{ .x = base_x, .y = base_y + s, .z = base_z + s };
            vertices[5] = .{ .x = base_x, .y = base_y + s, .z = base_z };
        },
        .top => {
            vertices[0] = .{ .x = base_x, .y = base_y + s, .z = base_z + s };
            vertices[1] = .{ .x = base_x + s, .y = base_y + s, .z = base_z + s };
            vertices[2] = .{ .x = base_x + s, .y = base_y + s, .z = base_z };
            vertices[3] = .{ .x = base_x, .y = base_y + s, .z = base_z + s };
            vertices[4] = .{ .x = base_x + s, .y = base_y + s, .z = base_z };
            vertices[5] = .{ .x = base_x, .y = base_y + s, .z = base_z };
        },
        .bottom => {
            vertices[0] = .{ .x = base_x, .y = base_y, .z = base_z };
            vertices[1] = .{ .x = base_x + s, .y = base_y, .z = base_z };
            vertices[2] = .{ .x = base_x + s, .y = base_y, .z = base_z + s };
            vertices[3] = .{ .x = base_x, .y = base_y, .z = base_z };
            vertices[4] = .{ .x = base_x + s, .y = base_y, .z = base_z + s };
            vertices[5] = .{ .x = base_x, .y = base_y, .z = base_z + s };
        },
    }

    const uvs = [6]rl.Vector2{
        .{ .x = 0, .y = 0 },
        .{ .x = 1, .y = 0 },
        .{ .x = 1, .y = 1 },
        .{ .x = 0, .y = 0 },
        .{ .x = 1, .y = 1 },
        .{ .x = 0, .y = 1 },
    };

    positions.appendSlice(&vertices) catch return;
    for (0..6) |_| {
        normals.append(normal) catch return;
    }
    texcoords.appendSlice(&uvs) catch return;
}
