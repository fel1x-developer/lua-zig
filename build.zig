const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const luaLib = liblua(b, target, optimize);
    const luaCmd = lua(b, target, optimize);

    b.installArtifact(luaLib);
    b.installArtifact(luaCmd);
}

fn liblua(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const lib = b.addStaticLibrary(.{
        .name = "lua",
        .target = target,
        .optimize = optimize,
    });
    lib.pie = true;
    switch (optimize) {
        .Debug, .ReleaseSafe => lib.bundle_compiler_rt = true,
        else => lib.root_module.strip = true,
    }
    lib.addIncludePath(.{ .path = "." });
    if (lib.rootModuleTarget().os.tag == .linux) {
        lib.defineCMacro("LUA_USE_LINUX", null);
        lib.defineCMacro("LUA_USE_READLINE", null);
    }
    lib.addCSourceFiles(.{
        .files = &.{
            // CORE_O
            "lapi.c",
            "lcode.c",
            "lctype.c",
            "ldebug.c",
            "ldo.c",
            "ldump.c",
            "lfunc.c",
            "lgc.c",
            "llex.c",
            "lmem.c",
            "lobject.c",
            "lopcodes.c",
            "lparser.c",
            "lstate.c",
            "lstring.c",
            "ltable.c",
            "ltm.c",
            "lundump.c",
            "lvm.c",
            "lzio.c",
            "ltests.c",
            // AUX_O
            "lauxlib.c",
            // LIB_O
            "lbaselib.c",
            "ldblib.c",
            "liolib.c",
            "lmathlib.c",
            "loslib.c",
            "ltablib.c",
            "lstrlib.c",
            "lutf8lib.c",
            "loadlib.c",
            "lcorolib.c",
            "linit.c",
        },
        .flags = cflags,
    });
    lib.linkLibC();
    return lib;
}

fn lua(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const lib = b.addExecutable(.{
        .name = "lua",
        .target = target,
        .optimize = optimize,
    });
    lib.pie = true;
    switch (optimize) {
        .Debug, .ReleaseSafe => lib.bundle_compiler_rt = true,
        else => lib.root_module.strip = true,
    }
    if (lib.rootModuleTarget().os.tag == .linux) {
        lib.defineCMacro("LUA_USE_LINUX", null);
        lib.defineCMacro("LUA_USE_LINUX", null);
    }
    lib.addCSourceFiles(.{
        .files = &.{
            "lua.c",
        },
        .flags = cflags,
    });
    lib.linkLibrary(liblua(b, target, optimize));
    lib.linkSystemLibrary("m");
    // MYLIBS
    if (lib.rootModuleTarget().os.tag == .linux) {
        lib.linkSystemLibrary("dl");
        lib.linkSystemLibrary("readline");
    }
    lib.linkLibC();
    return lib;
}

const cflags = &.{
    // CWARNSCPP
    "-Wfatal-errors",
    "-Wextra",
    "-Wshadow",
    "-Wundef",
    "-Wwrite-strings",
    "-Wredundant-decls",
    "-Wdisabled-optimization",
    "-Wdouble-promotion",
    "-Wmissing-declarations",
    // CWARNSC
    "-Wdeclaration-after-statement",
    "-Wmissing-prototypes",
    "-Wnested-externs",
    "-Wstrict-prototypes",
    "-Wc++-compat",
    "-Wold-style-definition",
    // rest of CFLAGS
    "-std=c99",
    "-Wall",
    "-O2",
    "-fno-stack-protector",
    "-fno-common",
    "-march=native",
    // LDFLAGS
    "-Wl,-E",
};

const BuildInfo = struct {
    path: []const u8,
    fn filename(self: BuildInfo) []const u8 {
        var split = std.mem.splitSequence(u8, std.fs.path.basename(self.path), ".");
        return split.first();
    }
};
