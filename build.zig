const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const clap = b.addModule("clap", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/clap.zig"),
    });

    {
        const gain = b.addLibrary(.{
            .name = "zig-gain",
            .linkage = .dynamic,
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .root_source_file = b.path("examples/gain.zig"),
                .imports = &.{
                    .{ .name = "clap", .module = clap },
                },
                .link_libc = true,
            }),
        });
        b.getInstallStep().dependOn(&b.addInstallArtifact(gain, .{
            .dest_dir = .{ .override = .bin },
            .dest_sub_path = "zig-gain.clap",
        }).step);
    }

    {
        const gain = b.addLibrary(.{
            .name = "gain",
            .linkage = .dynamic,
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .root_source_file = b.path("examples/gain.zig"),
                .imports = &.{
                    .{ .name = "clap", .module = clap },
                },
                .link_libc = true,
            }),
        });
        b.step("check", "").dependOn(&gain.step);
    }
}
