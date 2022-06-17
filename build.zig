const std = @import("std");
const Builder = @import("std").build.Builder;

const examples = &[_][]const u8{"simplest"};

pub fn build(b: *Builder) !void {
    const mode = b.standardReleaseOptions();
    inline for (examples) |example| {
        const lib = b.addSharedLibrary(example, "examples/" ++ example ++ "/" ++ example ++ ".zig", .{ .unversioned = {} });

        lib.addPackagePath("zig-clap", "src/clap.zig");
        lib.setBuildMode(mode);
        lib.setOutputDir("zig-out/" ++ example);

        var step = b.step(example, "Build example \"" ++ example ++ "\"");
        step.dependOn(&lib.step);
    }
}
