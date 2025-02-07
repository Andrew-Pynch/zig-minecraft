const rl = @import("raylib");
const block = @import("block.zig");

pub fn main() anyerror!void {
    const screenWidth = 800;
    const screenHeight = 450;
    rl.initWindow(screenWidth, screenHeight, "zig-minecraft");
    defer rl.closeWindow();
    rl.setTargetFPS(60);
    rl.disableCursor();

    const camera = rl.Camera3D{
        .position = .{ .x = 10.0, .y = 10.0, .z = 10.0 },
        .target = .{ .x = 0.0, .y = 0.0, .z = 0.0 },
        .up = .{ .x = 0.0, .y = 1.0, .z = 0.0 },
        .fovy = 45.0,
        .projection = .perspective,
    };

    const testBlock = block.Block.init(.{ .x = 0, .y = 0, .z = 0 }, 2.0);

    while (!rl.windowShouldClose()) {
        // updateCamera(&camera);

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

// fn updateCamera(camera: *rl.Camera3D) void {
//     const moveSpeed = 0.2;
//
//     // Forward/Backward
//     if (rl.isKeyDown(.w)) {
//         camera.position.z -= moveSpeed;
//         camera.target.z -= moveSpeed;
//     }
//     if (rl.isKeyDown(.s)) {
//         camera.position.z += moveSpeed;
//         camera.target.z += moveSpeed;
//     }
//
//     // Left/Right
//     if (rl.isKeyDown(.a)) {
//         camera.position.x -= moveSpeed;
//         camera.target.x -= moveSpeed;
//     }
//     if (rl.isKeyDown(.d)) {
//         camera.position.x += moveSpeed;
//         camera.target.x += moveSpeed;
//     }
//
//     // Up/Down
//     if (rl.isKeyDown(.e)) {
//         camera.position.y += moveSpeed;
//         camera.target.y += moveSpeed;
//     }
//     if (rl.isKeyDown(.q)) {
//         camera.position.y -= moveSpeed;
//         camera.target.y -= moveSpeed;
//     }
// }
