// renderer/pipeline.zig
const std = @import("std");
const sg = @import("sokol").gfx;
const math = @import("../math.zig");
const mesh = @import("mesh.zig");

pub const RenderPipeline = struct {
    pip: sg.Pipeline,
    shader: sg.Shader,
    bind: sg.Bindings,
    uniforms: Uniforms,

    pub const Uniforms = struct { mvp: math.Mat4 };

    pub fn init(allocator: std.mem.Allocator, shader_desc: sg.ShaderDesc) !RenderPipeline {
        _ = allocator;
        var pipeline = RenderPipeline{
            .pip = .{},
            .shader = sg.makeShader(shader_desc),
            .bind = .{},
            .uniforms = .{
                .mvp = math.Mat4.identity(),
            },
        };

        // init the pipeline with configurable state
        pipeline.pip = sg.makePipeline(.{
            .shader = pipeline.shader,
            .layout = .{
                // use array initialization instead of slice pointer
                .attrs = blk: {
                    var attrs: [16]sg.VertexAttrState = undefined;
                    attrs[0] = .{ .format = .FLOAT3, .offset = @offsetOf(mesh.Vertex, "position") };
                    attrs[1] = .{ .format = .FLOAT2, .offset = @offsetOf(mesh.Vertex, "uv") };
                    attrs[2] = .{ .format = .FLOAT3, .offset = @offsetOf(mesh.Vertex, "normal") };
                    // Set remaining attributes to default/invalid
                    for (3..16) |i| attrs[i] = .{ .format = .INVALID };
                    break :blk attrs;
                },
                // configure buffer layout
                .buffers = blk: {
                    var buffers: [8]sg.VertexBufferLayoutState = undefined;
                    for (0..8) |i| buffers[i] = .{ .stride = @sizeOf(mesh.Vertex) };
                    break :blk buffers;
                },
            },
            .index_type = .UINT16,
            .depth = .{
                .compare = .LESS_EQUAL,
                .write_enabled = true,
            },
            .cull_mode = .BACK,
        });

        return pipeline;
    }

    pub fn apply(self: *RenderPipeline) void {
        sg.applyPipeline(self.pip);
        sg.applyBindings(self.bind);
    }

    pub fn deinit(self: *RenderPipeline) void {
        sg.destroyPipeline(self.pip);
        sg.destroyShader(self.shader);
    }

    pub fn updateUniforms(self: *RenderPipeline) void {
        // update shader uniforms
        sg.applyUniforms(0, sg.asRange(&self.uniforms));
    }

    pub fn draw(self: *RenderPipeline, start: u32, count: u32) void {
        _ = self;
        sg.draw(start, count, 1);
    }
};
