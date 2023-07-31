const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dvui_dep = b.dependency("dvui", .{ .target = target, .optimize = optimize });

    const examples = [_][]const u8{
        "standalone-sdl",
        "ontop-sdl",
    };

    inline for (examples) |ex| {
        const exe = b.addExecutable(.{
            .name = ex,
            .root_source_file = .{ .path = ex ++ ".zig" },
            .target = target,
            .optimize = optimize,
        });

        exe.addModule("dvui", dvui_dep.module("dvui"));
        exe.addModule("SDLBackend", dvui_dep.module("SDLBackend"));

        // TODO: remove this part about freetype (pulling it from the dvui_dep
        // sub-builder) once https://github.com/ziglang/zig/pull/14731 lands
        const freetype_dep = dvui_dep.builder.dependency("freetype", .{
            .target = target,
            .optimize = optimize,
        });
        exe.linkLibrary(freetype_dep.artifact("freetype"));

        exe.linkSystemLibrary("SDL2");
        exe.linkLibC();

        const compile_step = b.step(ex, "Compile " ++ ex);
        compile_step.dependOn(&b.addInstallArtifact(exe, .{}).step);
        b.getInstallStep().dependOn(compile_step);

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(compile_step);

        const run_step = b.step("run-" ++ ex, "Run " ++ ex);
        run_step.dependOn(&run_cmd.step);
    }
}
