const std = @import("std");
const rl = @import("raylib");
const block = @import("block.zig");

pub fn main() anyerror!void {
    const screenWidth = 800;
    const screenHeight = 450;
    rl.initWindow(screenWidth, screenHeight, "zig-minecraft");
    defer rl.closeWindow();
    rl.setTargetFPS(60);
    rl.disableCursor();

    var cameraPitch: f32 = 0.0;
    var cameraYaw: f32 = -90.0;
    var camera = rl.Camera3D{
        .position = .{ .x = 10.0, .y = 10.0, .z = 10.0 },
        .target = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
        .up = .{ .x = 0.0, .y = 1.0, .z = 0.0 },
        .fovy = 45.0,
        .projection = .perspective,
    };

    const testBlock = block.Block.init(.{ .x = 0, .y = 0, .z = 0 }, 2.0);

    while (!rl.windowShouldClose()) {
        updateCamera(&camera, &cameraPitch, &cameraYaw);

        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(rl.Color.black);

        rl.beginMode3D(camera);
        rl.drawGrid(10, 1.0);
        testBlock.render();
        rl.endMode3D();

        rl.drawFPS(10, 10);
    }
}

fn updateCamera(camera: *rl.Camera3D, pitch: *f32, yaw: *f32) void {
    const moveSpeed = 0.2;
    const mouseSensitivity = 0.1;

    // Mouse movement
    const mouseOffsetX = @as(f32, @floatCast(rl.getMouseDelta().x)) * mouseSensitivity;
    const mouseOffsetY = @as(f32, @floatCast(rl.getMouseDelta().y)) * mouseSensitivity;

    // Update camera angles
    yaw.* += mouseOffsetX;
    pitch.* -= mouseOffsetY;

    // Clamp pitch to avoid flipping
    if (pitch.* > 89.0) pitch.* = 89.0;
    if (pitch.* < -89.0) pitch.* = -89.0;

    // Calculate new camera direction
    const direction = rl.Vector3{
        .x = @cos(std.math.degreesToRadians(yaw.*)) * @cos(std.math.degreesToRadians(pitch.*)),
        .y = @sin(std.math.degreesToRadians(pitch.*)),
        .z = @sin(std.math.degreesToRadians(yaw.*)) * @cos(std.math.degreesToRadians(pitch.*)),
    };

    // Calculate right vector for strafing
    const right = rl.Vector3{
        .x = @cos(std.math.degreesToRadians(yaw.* - 90.0)),
        .y = 0,
        .z = @sin(std.math.degreesToRadians(yaw.* - 90.0)),
    };

    // Handle all movement
    if (rl.isKeyDown(.w)) {
        camera.position.x += direction.x * moveSpeed;
        camera.position.y += direction.y * moveSpeed;
        camera.position.z += direction.z * moveSpeed;
    }
    if (rl.isKeyDown(.s)) {
        camera.position.x -= direction.x * moveSpeed;
        camera.position.y -= direction.y * moveSpeed;
        camera.position.z -= direction.z * moveSpeed;
    }
    if (rl.isKeyDown(.d)) {
        camera.position.x -= right.x * moveSpeed;
        camera.position.z -= right.z * moveSpeed;
    }
    if (rl.isKeyDown(.a)) {
        camera.position.x += right.x * moveSpeed;
        camera.position.z += right.z * moveSpeed;
    }
    if (rl.isKeyDown(.e)) camera.position.y += moveSpeed;
    if (rl.isKeyDown(.q)) camera.position.y -= moveSpeed;

    // Update camera target after all position changes
    camera.target = rl.Vector3{
        .x = camera.position.x + direction.x,
        .y = camera.position.y + direction.y,
        .z = camera.position.z + direction.z,
    };
}
