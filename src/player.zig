const std = @import("std");
const rl = @import("raylib");

pub const Player = struct {
    position: rl.Vector3,
    // player camera settings
    cameraPitch: f32 = 0.0,
    cameraYaw: f32 = -90.0,
    camera: rl.Camera3D,

    mouseSensitivity: f32 = 0.1,
    moveSpeed: f32 = 5.0,

    pub fn init(position: rl.Vector3) Player {
        return Player{
            .position = position,
            .camera = rl.Camera3D{
                .position = position,
                .target = .{ .x = 50.0, .y = 0.0, .z = 50.0 },
                .up = .{ .x = 0.0, .y = 10.0, .z = 0.0 },
                .fovy = 45.0,
                .projection = .perspective,
            },
        };
    }

    pub fn update(self: *Player, dt: f32) void {
        self.updateCamera(dt);
    }

    pub fn updateCamera(self: *Player, dt: f32) void {
        const mouseOffsetX = @as(f32, @floatCast(rl.getMouseDelta().x)) * self.mouseSensitivity;
        const mouseOffsetY = @as(f32, @floatCast(rl.getMouseDelta().y)) * self.mouseSensitivity;

        self.cameraYaw += mouseOffsetX;
        self.cameraPitch -= mouseOffsetY;

        if (self.cameraPitch > 89.0) self.cameraPitch = 89.0;
        if (self.cameraPitch < -89.0) self.cameraPitch = -89.0;

        const direction = rl.Vector3{
            .x = @cos(std.math.degreesToRadians(self.cameraYaw)) * @cos(std.math.degreesToRadians(self.cameraPitch)),
            .y = @sin(std.math.degreesToRadians(self.cameraPitch)),
            .z = @sin(std.math.degreesToRadians(self.cameraYaw)) * @cos(std.math.degreesToRadians(self.cameraPitch)),
        };

        const right = rl.Vector3{
            .x = @cos(std.math.degreesToRadians(self.cameraYaw - 90.0)),
            .y = 0,
            .z = @sin(std.math.degreesToRadians(self.cameraYaw - 90.0)),
        };

        // Handle all movement
        if (rl.isKeyDown(.w)) {
            self.camera.position.x += direction.x * self.moveSpeed * dt;
            self.camera.position.y += direction.y * self.moveSpeed * dt;
            self.camera.position.z += direction.z * self.moveSpeed * dt;
        }
        if (rl.isKeyDown(.s)) {
            self.camera.position.x -= direction.x * self.moveSpeed * dt;
            self.camera.position.y -= direction.y * self.moveSpeed * dt;
            self.camera.position.z -= direction.z * self.moveSpeed * dt;
        }
        if (rl.isKeyDown(.d)) {
            self.camera.position.x -= right.x * self.moveSpeed * dt;
            self.camera.position.z -= right.z * self.moveSpeed * dt;
        }
        if (rl.isKeyDown(.a)) {
            self.camera.position.x += right.x * self.moveSpeed * dt;
            self.camera.position.z += right.z * self.moveSpeed * dt;
        }
        if (rl.isKeyDown(.e)) self.camera.position.y += self.moveSpeed * dt;
        if (rl.isKeyDown(.q)) self.camera.position.y -= self.moveSpeed * dt;

        // Update camera target after all position changes
        self.camera.target = rl.Vector3{
            .x = self.camera.position.x + direction.x,
            .y = self.camera.position.y + direction.y,
            .z = self.camera.position.z + direction.z,
        };
    }
};
