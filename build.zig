const std = @import("std");
const Builder = std.Build;

const examples = &[_][]const u8{"simplest"};

pub fn build(b: *Builder) !void {
    const clap = b.addModule("zig-clap", .{
        .source_file = .{ .path = "src/clap.zig" },
    });

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    inline for (examples) |example| {
        const lib = b.addSharedLibrary(.{
            .name = example,
            .root_source_file = .{ .path = "examples/" ++ example ++ "/" ++ example ++ ".zig" },
            .target = target,
            .optimize = optimize,
        });

        lib.addModule("zig-clap", clap);

        var install = b.addInstallArtifact(lib);
        install.dest_sub_path = try std.mem.concat(b.allocator, u8, &.{
            try std.zig.binNameAlloc(b.allocator, .{
                .root_name = example,
                .target = target.toTarget(),
                .output_mode = .Lib,
                .link_mode = .Dynamic,
            }),
            ".clap",
        });

        var step = b.step(example, "Build example \"" ++ example ++ "\"");
        step.dependOn(&install.step);
    }
}
