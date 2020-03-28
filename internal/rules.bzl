load(":actions.bzl", "nodejs_link")
load(":providers.bzl", "JsLibraryInfo")

def _nodejs_binary_impl(ctx):
    srcs = ctx.files.srcs
    entry_point = ctx.file.entry_point

    if entry_point not in srcs:
        fail(
            "could not find '{entry_point}'"
                .format(entry_point = entry_point.basename) +
            "as specified by 'entry_point' attribute",
        )

    bin = ctx.actions.declare_file(
        ctx.label.name,
        sibling = entry_point,
    )

    nodejs_link(ctx, entry_point = entry_point, bin = bin)

    runfiles = ctx.runfiles(files = srcs + ctx.files.data)
    for dep in ctx.attr.deps:
        runfiles = runfiles.merge(ctx.runfiles(
            transitive_files = dep[JsLibraryInfo].deps,
        ))

    return [DefaultInfo(
        files = depset([bin]),
        executable = bin,
        runfiles = runfiles,
    )]

nodejs_binary = rule(
    _nodejs_binary_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".js"], mandatory = True),
        "entry_point": attr.label(allow_single_file = [".js"], mandatory = True),
        "data": attr.label_list(allow_files = True),
        "deps": attr.label_list(providers = [JsLibraryInfo]),
    },
    executable = True,
)

def _js_library_impl(ctx):
    return [JsLibraryInfo(deps = depset(
        ctx.files.srcs,
        transitive = [dep[JsLibraryInfo].deps for dep in ctx.attr.deps],
    ))]

js_library = rule(
    _js_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".js"]),
        "deps": attr.label_list(providers = [JsLibraryInfo]),
    },
    provides = [JsLibraryInfo],
)