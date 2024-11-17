const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const linkage = b.option(std.builtin.LinkMode, "linkage", "Specify static or dynamic linkage") orelse .dynamic;
    const upstream = b.dependency("rmw_cyclonedds", .{});
    var lib = std.Build.Step.Compile.create(b, .{
        .root_module = .{
            .target = target,
            .optimize = optimize,
            .pic = if (linkage == .dynamic) true else null,
        },
        .name = "rmw_cyclonedds_cpp",
        .kind = .lib,
        .linkage = linkage,
    });

    lib.linkLibCpp();

    lib.addIncludePath(b.dependency("ros2_tracing", .{}).namedWriteFiles("tracetools").getDirectory());

    const rcutils_dep = b.dependency("rcutils", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
    });
    lib.linkLibrary(rcutils_dep.artifact("rcutils"));

    const cyclonedds_dep = b.dependency("cyclonedds", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
    });
    lib.linkLibrary(cyclonedds_dep.artifact("cyclonedds"));

    const rcpputils_dep = b.dependency("rcpputils", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
    });
    lib.linkLibrary(rcpputils_dep.artifact("rcpputils"));

    const rmw_dep = b.dependency("rmw", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
    });
    lib.linkLibrary(rmw_dep.artifact("rmw"));

    const rmw_dds_common_dep = b.dependency("rmw_dds_common", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
    });
    lib.linkLibrary(rmw_dds_common_dep.artifact("rmw_dds_common"));
    lib.linkLibrary(rmw_dds_common_dep.artifact("rmw_dds_common__rosidl_typesupport_cpp"));
    lib.addIncludePath(rmw_dds_common_dep.namedWriteFiles("rmw_dds_common__rosidl_generator_cpp").getDirectory());

    const rosidl_dep = b.dependency("rosidl", .{
        .target = target,
        .optimize = optimize,
        .linkage = linkage,
    });
    lib.linkLibrary(rosidl_dep.artifact("rosidl_runtime_c"));
    lib.linkLibrary(rosidl_dep.artifact("rosidl_typesupport_introspection_c"));
    lib.linkLibrary(rosidl_dep.artifact("rosidl_typesupport_introspection_cpp"));
    lib.linkLibrary(rosidl_dep.artifact("rosidl_dynamic_typesupport"));
    lib.addIncludePath(rosidl_dep.namedWriteFiles("rosidl_typesupport_interface").getDirectory());
    lib.addIncludePath(rosidl_dep.namedWriteFiles("rosidl_runtime_cpp").getDirectory());

    lib.addIncludePath(upstream.path("rmw_cyclonedds/rmw_cyclonedds_cpp/src"));
    lib.addCSourceFiles(.{
        .root = upstream.path("rmw_cyclonedds_cpp/"),
        .files = &.{
            "src/rmw_get_network_flow_endpoints.cpp",
            "src/rmw_node.cpp",
            "src/serdata.cpp",
            "src/serdes.cpp",
            "src/u16string.cpp",
            "src/exception.cpp",
            "src/demangle.cpp",
            "src/deserialization_exception.cpp",
            "src/Serialization.cpp",
            "src/TypeSupport2.cpp",
            "src/TypeSupport.cpp",
        },
        .flags = &.{
            "-Wno-deprecated-declarations",
            "--std=c++17",
            // "-P",
            "-fvisibility=hidden",
            "-fvisibility-inlines-hidden",
            "-fno-sanitize=alignment", // TODO needed because the desserialization does a pointer cast on a byte array to extract larger integers, which is technically missaligned pointer access and should be implemented differently
        }, // TODO remove -P and sanatize trap
    });

    // left in to document, this call isn't right but there's something similar
    // lib.root.sanatize_c = true;

    b.installArtifact(lib);
}
