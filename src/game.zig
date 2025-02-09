// game.zig
const std = @import("std");
const sg = @import("sokol").gfx;
const sapp = @import("sokol").app;
const sglue = @import("sokol").glue;
const slog = @import("sokol").log;
const math = @import("math.zig");
const shader = @import("renderer/shader.zig");
const pipeline = @import("renderer/pipeline.zig");
const mesh = @import("renderer/mesh.zig");

pub const Game = struct {
    allocator: std.mem.Allocator,
    render_pipeline: pipeline.RenderPipeline,
    rectangle_mesh: mesh.Mesh,
    rotation: f32,

    pub fn init(allocator: std.mem.Allocator) !Game {
        // Initialize sokol
        sg.setup(.{
            .environment = sglue.environment(),
            .logger = .{ .func = slog.func },
        });

        // Create basic rectangle vertices
        // In game.zig, update vertices:
        const vertices = &[_]mesh.Vertex{
            // Position                    UV           Normal/Color
            .{ .position = .{ -0.5, -0.5, 0 }, .uv = .{ 0, 0 }, .normal = .{ 1, 0, 0 } }, // Red
            .{ .position = .{ 0.5, -0.5, 0 }, .uv = .{ 1, 0 }, .normal = .{ 0, 1, 0 } }, // Green
            .{ .position = .{ 0.5, 0.5, 0 }, .uv = .{ 1, 1 }, .normal = .{ 0, 0, 1 } }, // Blue
            .{ .position = .{ -0.5, 0.5, 0 }, .uv = .{ 0, 1 }, .normal = .{ 1, 1, 0 } }, // Yellow
        };

        const indices = &[_]u16{
            0, 1, 2, // First triangle
            0, 2, 3, // Second triangle
        };

        var game = Game{
            .allocator = allocator,
            .render_pipeline = try pipeline.RenderPipeline.init(allocator, shader.ColorShader.createShaderDesc(sg.queryBackend())),
            .rectangle_mesh = try mesh.Mesh.init(allocator, vertices, indices),
            .rotation = 0.0,
        };

        // Bind the mesh to our pipeline
        game.rectangle_mesh.bind(&game.render_pipeline.bind);

        return game;
    }

    pub fn deinit(self: *Game) void {
        self.rectangle_mesh.deinit();
        self.render_pipeline.deinit();
        sg.shutdown();
    }

    pub fn frame(self: *Game) void {
        // Update game state
        const dt: f32 = @floatCast(sapp.frameDuration() * 60.0);
        self.rotation += 1.0 * dt;

        // Update MVP matrix
        const view = math.Mat4.lookat(.{ .x = 0.0, .y = 0.0, .z = 2.0 }, .{ .x = 0.0, .y = 0.0, .z = 0.0 }, .{ .x = 0.0, .y = 1.0, .z = 0.0 });
        const proj = math.Mat4.persp(60.0, sapp.widthf() / sapp.heightf(), 0.01, 10.0);
        const model = math.Mat4.rotate(self.rotation, .{ .x = 0.0, .y = 1.0, .z = 0.0 });
        self.render_pipeline.uniforms.mvp = math.Mat4.mul(math.Mat4.mul(proj, view), model);

        // Render frame
        sg.beginPass(.{
            .action = .{
                // Initialize all 4 color attachments (even if unused)
                .colors = .{
                    .{ .load_action = .CLEAR, .clear_value = .{ .r = 0.1, .g = 0.1, .b = 0.1, .a = 1.0 } },
                    .{ .load_action = .DONTCARE }, // Attachment 1
                    .{ .load_action = .DONTCARE }, // Attachment 2
                    .{ .load_action = .DONTCARE }, // Attachment 3
                },
            },
            .swapchain = sglue.swapchain(),
        });

        self.render_pipeline.apply();
        self.render_pipeline.updateUniforms();
        self.render_pipeline.draw(0, 6); // 6 indices for 2 triangles

        sg.endPass();
        sg.commit();
    }
};

// Global game state
var g_game: ?Game = null;

// Sokol callbacks
fn init() callconv(.C) void {
    g_game = Game.init(std.heap.c_allocator) catch unreachable;
}

fn frame() callconv(.C) void {
    if (g_game) |*game| {
        game.frame();
    }
}

fn cleanup() callconv(.C) void {
    if (g_game) |*game| {
        game.deinit();
    }
}

pub fn main() !void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .width = 800,
        .height = 600,
        .window_title = "Minecraft Clone",
        .logger = .{ .func = slog.func },
    });
}
