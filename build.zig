const std = @import("std");

pub fn build(b: *std.Build) !void {
    b.release_mode = .small;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const envmap = try std.process.getEnvMap(allocator);

    const home_path = envmap.get("HOME").?;

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSmall,
    });

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("platform/root.zig"),
        .target = target,
        .optimize = optimize,
        .sanitize_c = false,
        .strip = true,
        .code_model = .small,
    });

    lib_mod.addIncludePath(.{
        .cwd_relative = b.pathJoin(&.{
            home_path,
            ".moon/include",
        }),
    });

    lib_mod.addCSourceFile(.{
        .file = .{ .cwd_relative = b.pathJoin(&.{ home_path, ".moon/lib/runtime.c" }) },
        .flags = &.{
            "-Wall",
            "-fwrapv",
            "-O3",
        },
    });

    const lib = b.addLibrary(.{
        .name = "request",
        .root_module = lib_mod,
        .linkage = .dynamic,
    });

    const exe = b.addExecutable(.{
        .name = "ntm",
        .target = target,
        .optimize = optimize,
        .strip = true,
        .code_model = .small,
    });

    exe.addIncludePath(.{
        .cwd_relative = b.pathJoin(&.{
            home_path,
            ".moon/include",
        }),
    });

    exe.addCSourceFile(.{
        .file = b.path("ntm/target/native/release/build/main/main.c"),
        .flags = &.{
            "-Wall",
            "-fwrapv",
            "-O3",
        },
    });

    exe.addObjectFile(b.path("ntm/target/native/release/build/.mooncakes/moonbitlang/x/sys/internal/ffi/libffi.a"));

    exe.linkLibrary(lib);

    b.installArtifact(exe);
}
