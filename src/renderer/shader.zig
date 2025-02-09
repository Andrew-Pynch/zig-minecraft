const std = @import("std");
const sg = @import("sokol").gfx;
const math = @import("../math.zig");

// Common uniform layout for most 3D shaders
pub const BasicUniforms = extern struct {
    mvp: math.Mat4 align(16),
};

// The vertex attribute slots used in the shaders
pub const VertexAttributes = struct {
    pub const position = 0;
    pub const uv = 1;
    pub const normal = 2;
};

// Basic 3D shader for textured meshes
pub const BasicShader = struct {
    const vs_source =
        \\#version 330
        \\uniform mat4 mvp;
        \\layout(location=0) in vec3 position;
        \\layout(location=1) in vec2 texcoord;
        \\layout(location=2) in vec3 normal;
        \\out vec2 uv;
        \\out vec3 world_normal;
        \\void main() {
        \\    gl_Position = mvp * vec4(position, 1);
        \\    uv = texcoord;
        \\    world_normal = (mvp * vec4(normal, 0.0)).xyz;
        \\}
    ;

    const fs_source =
        \\#version 330
        \\uniform sampler2D tex;
        \\in vec2 uv;
        \\in vec3 world_normal;
        \\out vec4 frag_color;
        \\void main() {
        \\    vec3 light_dir = normalize(vec3(1.0, 1.0, -1.0));
        \\    vec3 normal = normalize(world_normal);
        \\    float diffuse = max(dot(normal, light_dir), 0.0);
        \\    vec4 tex_color = texture(tex, uv);
        \\    frag_color = vec4(tex_color.rgb * (diffuse * 0.8 + 0.2), tex_color.a);
        \\}
    ;

    // basic shader
    pub fn createShaderDesc(backend: sg.Backend) sg.ShaderDesc {
        var desc: sg.ShaderDesc = .{};
        // set semantic names for attributes
        desc.attrs[VertexAttributes.position].hlsl_sem_name = "POSITION";
        desc.attrs[VertexAttributes.position].hlsl_sem_index = 0;

        desc.attrs[VertexAttributes.uv].hlsl_sem_name = "TEXCOORD";
        desc.attrs[VertexAttributes.uv].hlsl_sem_index = 0;

        desc.attrs[VertexAttributes.normal].hlsl_sem_name = "NORMAL";
        desc.attrs[VertexAttributes.normal].hlsl_sem_index = 0;

        switch (backend) {
            .GLCORE => {
                desc.vertex_func.source = vs_source;
                desc.fragment_func.source = fs_source;
            },
            else => @panic("Unsupported backend"),
        }

        desc.uniform_blocks[0] = .{
            .stage = .VERTEX,
            .size = @sizeOf(BasicUniforms),
            .glsl_uniforms = blk: {
                var uniforms: [16]sg.GlslShaderUniform = undefined;
                // Set first uniform slot to MAT4 (matches BasicUniforms.mvp)
                uniforms[0] = .{ .type = .MAT4, .glsl_name = "basic_shader" };
                // Initialize remaining slots to default
                for (1..16) |i| uniforms[i] = .{};
                break :blk uniforms;
            },
        };
        return desc;
    }
};

// Unlit color shader for debug visualization
pub const ColorShader = struct {
    const vs_source =
        \\#version 330
        \\uniform mat4 mvp;
        \\layout(location=0) in vec3 position;
        \\layout(location=1) in vec2 texcoord;  // Unused but must match format
        \\layout(location=2) in vec3 normal;    // We'll use this as color
        \\out vec3 frag_color;
        \\void main() {
        \\    gl_Position = mvp * vec4(position, 1);
        \\    frag_color = normal;  // Use normal as color
        \\}
    ;

    const fs_source =
        \\#version 330
        \\in vec3 frag_color;
        \\out vec4 out_color;
        \\void main() {
        \\    out_color = vec4(frag_color, 1.0);
        \\}
    ;

    // color shader
    pub fn createShaderDesc(backend: sg.Backend) sg.ShaderDesc {
        var desc: sg.ShaderDesc = .{};
        desc.attrs[VertexAttributes.position].hlsl_sem_name = "POSITION";
        desc.attrs[VertexAttributes.position].hlsl_sem_index = 0;

        switch (backend) {
            .GLCORE => {
                desc.vertex_func.source = vs_source;
                desc.fragment_func.source = fs_source;
            },
            else => {
                @panic("Unsupported backend");
            },
        }

        desc.uniform_blocks[0] = .{
            .stage = .VERTEX,
            .size = @sizeOf(BasicUniforms),
            .glsl_uniforms = blk: {
                var uniforms: [16]sg.GlslShaderUniform = undefined;
                // Set first uniform slot to MAT4 (matches BasicUniforms.mvp)
                uniforms[0] = .{ .type = .MAT4, .glsl_name = "color_shader" };
                // Initialize remaining slots to default
                for (1..16) |i| uniforms[i] = .{};
                break :blk uniforms;
            },
        };

        return desc;
    }
};

// Helper to create a shader based on the current backend
pub fn createShader(comptime ShaderType: type) sg.Shader {
    const desc = ShaderType.createShaderDesc(sg.queryBackend());
    return sg.makeShader(desc);
}
