const std = @import("std");
const rl = @import("raylib");

pub const Face = enum {
    front,
    back,
    left,
    right,
    top,
    bottom,
};

pub const Block = struct {
    position: rl.Vector3,
    size: f32,
    visible_faces: std.EnumSet(Face),
    mesh: ?rl.Mesh,
    material: ?rl.Material,

    pub fn init(position: rl.Vector3, size: f32) Block {
        var block = Block{
            .position = position,
            .size = size,
            .visible_faces = std.EnumSet(Face).initFull(),
            .mesh = null,
            .material = null,
        };
        block.generateMesh();
        return block;
    }

    pub fn render(self: Block, debug_render: bool) void {
        if (self.mesh != null and self.material != null) {
            // Always draw the regular mesh
            rl.drawMesh(self.mesh.?, self.material.?, rl.Matrix.identity());

            if (debug_render) {
                self.renderDebugData();
            }
        }
    }

    pub fn deinit(self: *Block) void {
        if (self.mesh) |*mesh| {
            rl.unloadMesh(mesh);
        }
        if (self.material) |*mat| {
            rl.unloadMaterial(mat);
        }
    }

    fn generateMesh(self: *Block) void {
        const max_vertices = 6 * 6; // 6 faces × 6 vertices per face
        var positions: [max_vertices]rl.Vector3 = undefined;
        var normals: [max_vertices]rl.Vector3 = undefined;
        var texcoords: [max_vertices]rl.Vector2 = undefined;
        var vertex_count: usize = 0;

        if (self.visible_faces.contains(.front)) {
            self.addFace(&positions, &normals, &texcoords, &vertex_count, .front);
        }
        if (self.visible_faces.contains(.back)) {
            self.addFace(&positions, &normals, &texcoords, &vertex_count, .back);
        }
        if (self.visible_faces.contains(.left)) {
            self.addFace(&positions, &normals, &texcoords, &vertex_count, .left);
        }
        if (self.visible_faces.contains(.right)) {
            self.addFace(&positions, &normals, &texcoords, &vertex_count, .right);
        }
        if (self.visible_faces.contains(.top)) {
            self.addFace(&positions, &normals, &texcoords, &vertex_count, .top);
        }
        if (self.visible_faces.contains(.bottom)) {
            self.addFace(&positions, &normals, &texcoords, &vertex_count, .bottom);
        }

        // Create float arrays for mesh data
        var vertices: [max_vertices * 3]f32 = undefined;
        var norms: [max_vertices * 3]f32 = undefined;
        var uvs: [max_vertices * 2]f32 = undefined;

        // Convert Vector3/Vector2 arrays to float arrays
        for (0..vertex_count) |i| {
            vertices[i * 3 + 0] = positions[i].x;
            vertices[i * 3 + 1] = positions[i].y;
            vertices[i * 3 + 2] = positions[i].z;

            norms[i * 3 + 0] = normals[i].x;
            norms[i * 3 + 1] = normals[i].y;
            norms[i * 3 + 2] = normals[i].z;

            uvs[i * 2 + 0] = texcoords[i].x;
            uvs[i * 2 + 1] = texcoords[i].y;
        }

        // Create the mesh
        var mesh = rl.Mesh{
            .vertexCount = @intCast(vertex_count),
            .triangleCount = @intCast(vertex_count / 3),
            .vertices = &vertices,
            .texcoords = &uvs,
            .normals = &norms,
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

        // Handle potential errors from loadMaterialDefault
        if (rl.loadMaterialDefault()) |material| {
            self.material = material;
        } else |err| {
            std.debug.print("Failed to load default material: {}\n", .{err});
            self.material = null;
        }
    }

    fn addFace(
        self: *Block,
        positions: []rl.Vector3,
        normals: []rl.Vector3,
        texcoords: []rl.Vector2,
        start: *usize,
        face: Face,
    ) void {
        const base = self.position;
        const s = self.size;
        const i = start.*;
        switch (face) {
            .front => {
                // Positions
                positions[i + 0] = .{ .x = base.x, .y = base.y, .z = base.z + s };
                positions[i + 1] = .{ .x = base.x + s, .y = base.y, .z = base.z + s };
                positions[i + 2] = .{ .x = base.x + s, .y = base.y + s, .z = base.z + s };
                positions[i + 3] = .{ .x = base.x, .y = base.y, .z = base.z + s };
                positions[i + 4] = .{ .x = base.x + s, .y = base.y + s, .z = base.z + s };
                positions[i + 5] = .{ .x = base.x, .y = base.y + s, .z = base.z + s };

                @memset(normals[i .. i + 6], .{ .x = 0, .y = 0, .z = 1 });
            },
            .back => {
                positions[i + 0] = .{ .x = base.x + s, .y = base.y, .z = base.z };
                positions[i + 1] = .{ .x = base.x, .y = base.y, .z = base.z };
                positions[i + 2] = .{ .x = base.x, .y = base.y + s, .z = base.z };
                positions[i + 3] = .{ .x = base.x + s, .y = base.y, .z = base.z };
                positions[i + 4] = .{ .x = base.x, .y = base.y + s, .z = base.z };
                positions[i + 5] = .{ .x = base.x + s, .y = base.y + s, .z = base.z };

                @memset(normals[i .. i + 6], .{ .x = 0, .y = 0, .z = -1 });
            },
            .right => {
                positions[i + 0] = .{ .x = base.x + s, .y = base.y, .z = base.z + s };
                positions[i + 1] = .{ .x = base.x + s, .y = base.y, .z = base.z };
                positions[i + 2] = .{ .x = base.x + s, .y = base.y + s, .z = base.z };
                positions[i + 3] = .{ .x = base.x + s, .y = base.y, .z = base.z + s };
                positions[i + 4] = .{ .x = base.x + s, .y = base.y + s, .z = base.z };
                positions[i + 5] = .{ .x = base.x + s, .y = base.y + s, .z = base.z + s };

                @memset(normals[i .. i + 6], .{ .x = 1, .y = 0, .z = 0 });
            },
            .left => {
                positions[i + 0] = .{ .x = base.x, .y = base.y, .z = base.z };
                positions[i + 1] = .{ .x = base.x, .y = base.y, .z = base.z + s };
                positions[i + 2] = .{ .x = base.x, .y = base.y + s, .z = base.z + s };
                positions[i + 3] = .{ .x = base.x, .y = base.y, .z = base.z };
                positions[i + 4] = .{ .x = base.x, .y = base.y + s, .z = base.z + s };
                positions[i + 5] = .{ .x = base.x, .y = base.y + s, .z = base.z };

                @memset(normals[i .. i + 6], .{ .x = -1, .y = 0, .z = 0 });
            },
            .top => {
                positions[i + 0] = .{ .x = base.x, .y = base.y + s, .z = base.z + s };
                positions[i + 1] = .{ .x = base.x + s, .y = base.y + s, .z = base.z + s };
                positions[i + 2] = .{ .x = base.x + s, .y = base.y + s, .z = base.z };
                positions[i + 3] = .{ .x = base.x, .y = base.y + s, .z = base.z + s };
                positions[i + 4] = .{ .x = base.x + s, .y = base.y + s, .z = base.z };
                positions[i + 5] = .{ .x = base.x, .y = base.y + s, .z = base.z };

                @memset(normals[i .. i + 6], .{ .x = 0, .y = 1, .z = 0 });
            },
            .bottom => {
                positions[i + 0] = .{ .x = base.x, .y = base.y, .z = base.z };
                positions[i + 1] = .{ .x = base.x + s, .y = base.y, .z = base.z };
                positions[i + 2] = .{ .x = base.x + s, .y = base.y, .z = base.z + s };
                positions[i + 3] = .{ .x = base.x, .y = base.y, .z = base.z };
                positions[i + 4] = .{ .x = base.x + s, .y = base.y, .z = base.z + s };
                positions[i + 5] = .{ .x = base.x, .y = base.y, .z = base.z + s };

                @memset(normals[i .. i + 6], .{ .x = 0, .y = -1, .z = 0 });
            },
        }

        // UV coordinates are the same for all faces
        texcoords[i + 0] = .{ .x = 0, .y = 0 };
        texcoords[i + 1] = .{ .x = 1, .y = 0 };
        texcoords[i + 2] = .{ .x = 1, .y = 1 };
        texcoords[i + 3] = .{ .x = 0, .y = 0 };
        texcoords[i + 4] = .{ .x = 1, .y = 1 };
        texcoords[i + 5] = .{ .x = 0, .y = 1 };

        start.* += 6;
    }

    pub fn renderDebugData(self: Block) void {
        const base = self.position;
        const s = self.size;

        const faces = std.enums.values(Face);
        for (faces) |face| {
            if (!self.visible_faces.contains(face)) continue;

            var vertices: [6]rl.Vector3 = undefined;
            switch (face) {
                .front => {
                    vertices[0] = .{ .x = base.x, .y = base.y, .z = base.z + s };
                    vertices[1] = .{ .x = base.x + s, .y = base.y, .z = base.z + s };
                    vertices[2] = .{ .x = base.x + s, .y = base.y + s, .z = base.z + s };
                    vertices[3] = .{ .x = base.x, .y = base.y, .z = base.z + s };
                    vertices[4] = .{ .x = base.x + s, .y = base.y + s, .z = base.z + s };
                    vertices[5] = .{ .x = base.x, .y = base.y + s, .z = base.z + s };
                },
                .back => {
                    vertices[0] = .{ .x = base.x + s, .y = base.y, .z = base.z };
                    vertices[1] = .{ .x = base.x, .y = base.y, .z = base.z };
                    vertices[2] = .{ .x = base.x, .y = base.y + s, .z = base.z };
                    vertices[3] = .{ .x = base.x + s, .y = base.y, .z = base.z };
                    vertices[4] = .{ .x = base.x, .y = base.y + s, .z = base.z };
                    vertices[5] = .{ .x = base.x + s, .y = base.y + s, .z = base.z };
                },
                .right => {
                    vertices[0] = .{ .x = base.x + s, .y = base.y, .z = base.z + s };
                    vertices[1] = .{ .x = base.x + s, .y = base.y, .z = base.z };
                    vertices[2] = .{ .x = base.x + s, .y = base.y + s, .z = base.z };
                    vertices[3] = .{ .x = base.x + s, .y = base.y, .z = base.z + s };
                    vertices[4] = .{ .x = base.x + s, .y = base.y + s, .z = base.z };
                    vertices[5] = .{ .x = base.x + s, .y = base.y + s, .z = base.z + s };
                },
                .left => {
                    vertices[0] = .{ .x = base.x, .y = base.y, .z = base.z };
                    vertices[1] = .{ .x = base.x, .y = base.y, .z = base.z + s };
                    vertices[2] = .{ .x = base.x, .y = base.y + s, .z = base.z + s };
                    vertices[3] = .{ .x = base.x, .y = base.y, .z = base.z };
                    vertices[4] = .{ .x = base.x, .y = base.y + s, .z = base.z + s };
                    vertices[5] = .{ .x = base.x, .y = base.y + s, .z = base.z };
                },
                .top => {
                    vertices[0] = .{ .x = base.x, .y = base.y + s, .z = base.z + s };
                    vertices[1] = .{ .x = base.x + s, .y = base.y + s, .z = base.z + s };
                    vertices[2] = .{ .x = base.x + s, .y = base.y + s, .z = base.z };
                    vertices[3] = .{ .x = base.x, .y = base.y + s, .z = base.z + s };
                    vertices[4] = .{ .x = base.x + s, .y = base.y + s, .z = base.z };
                    vertices[5] = .{ .x = base.x, .y = base.y + s, .z = base.z };
                },
                .bottom => {
                    vertices[0] = .{ .x = base.x, .y = base.y, .z = base.z };
                    vertices[1] = .{ .x = base.x + s, .y = base.y, .z = base.z };
                    vertices[2] = .{ .x = base.x + s, .y = base.y, .z = base.z + s };
                    vertices[3] = .{ .x = base.x, .y = base.y, .z = base.z };
                    vertices[4] = .{ .x = base.x + s, .y = base.y, .z = base.z + s };
                    vertices[5] = .{ .x = base.x, .y = base.y, .z = base.z + s };
                },
            }

            // Draw each triangle's vertices and edges
            var i: usize = 0;
            while (i < 6) : (i += 3) {
                const v0 = vertices[i];
                const v1 = vertices[i + 1];
                const v2 = vertices[i + 2];

                // Draw vertices as spheres
                rl.drawSphere(v0, 0.05, rl.Color.red);
                rl.drawSphere(v1, 0.05, rl.Color.red);
                rl.drawSphere(v2, 0.05, rl.Color.red);

                // Draw triangle edges
                rl.drawLine3D(v0, v1, rl.Color.green);
                rl.drawLine3D(v1, v2, rl.Color.green);
                rl.drawLine3D(v2, v0, rl.Color.green);
            }
        }
    }
};
