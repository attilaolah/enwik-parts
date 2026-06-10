const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const requested_optimize = b.standardOptimizeOption(.{});
    const optimize: std.builtin.OptimizeMode = switch (requested_optimize) {
        .Debug => .Debug,
        .ReleaseFast, .ReleaseSafe, .ReleaseSmall => .ReleaseSmall,
    };

    const urls_src_external = b.option([]const u8, "urls_src", "Path to the URLs input file") orelse
        b.graph.environ_map.get("ENWIK9_URLS") orelse
        @panic("Missing URLs source. Pass -Durls_src=/path/to/urls.txt or set ENWIK9_URLS.");
    const urls_src_embedded = "generated/urls.txt";

    const mkdir_step = b.addSystemCommand(&.{ "mkdir", "-p", "src/generated" });
    const remove_step = b.addSystemCommand(&.{ "rm", "-f", "src/generated/urls.txt" });
    remove_step.step.dependOn(&mkdir_step.step);
    const copy_step = b.addSystemCommand(&.{ "cp", urls_src_external, "src/generated/urls.txt" });
    copy_step.step.dependOn(&remove_step.step);

    const options = b.addOptions();
    options.addOption([]const u8, "urls_src", urls_src_embedded);

    const exe = b.addExecutable(.{
        .name = "urls",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/urls.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.root_module.addOptions("config", options);
    exe.step.dependOn(&copy_step.step);

    b.installArtifact(exe);
}
