// renderer/mesh.zig
const std = @import("std");
const sg = @import("sokol").gfx;

pub const Vertex = struct { position: [3]f32, uv: [2]f32, normal: [3]f32 };

pub const Mesh = struct {
    vertices: []Vertex,
    indices: []u16,
    vbuf: sg.Buffer,
    ibuf: sg.Buffer,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, vertices: []const Vertex, indices: []const u16) !Mesh {
        var mesh = Mesh{ .vertices = try allocator.dupe(Vertex, vertices), .indices = try allocator.dupe(u16, indices), .vbuf = .{}, .ibuf = .{}, .allocator = allocator };

        // create vertex buffer
        mesh.vbuf = sg.makeBuffer(.{
            .data = sg.asRange(mesh.vertices),
        });

        mesh.ibuf = sg.makeBuffer(.{ .type = .INDEXBUFFER, .data = sg.asRange(mesh.indices) });

        return mesh;
    }

    pub fn deinit(self: *Mesh) void {
        sg.destroyBuffer(self.vbuf);
        sg.destroyBuffer(self.ibuf);
        self.allocator.free(self.vertices);
        self.allocator.free(self.indices);
    }

    pub fn bind(self: *Mesh, bindings: *sg.Bindings) void {
        bindings.vertex_buffers[0] = self.vbuf;
        bindings.index_buffer = self.ibuf;
    }
};
