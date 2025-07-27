const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const clap = b.addModule("clap", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/clap.zig"),
    });

    const check = b.step("check", "check for compile errors");

    const examples = addCheckedSharedLibrary(check, .{
        .name = "zig-clap-examples",
        .linkage = .dynamic,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .root_source_file = b.path("examples/root.zig"),
            .imports = &.{
                .{ .name = "clap", .module = clap },
            },
            .link_libc = true,
        }),
    });
    b.getInstallStep().dependOn(&b.addInstallArtifact(examples, .{
        .dest_dir = .{ .override = .bin },
        .dest_sub_path = "zig-clap-examples.clap",
    }).step);
}

fn addCheckedSharedLibrary(
    check: *std.Build.Step,
    options: std.Build.LibraryOptions,
) *std.Build.Step.Compile {
    const b = check.owner;
    check.dependOn(&b.addLibrary(options).step);
    return b.addLibrary(options);
}
