const std = @import("std");
const assert = std.debug.assert;

const Config = struct {
    link: []const u8,
    conversion: []const u8,
    targets: std.ArrayList([]const u8),
};

fn get_conf_var(line: []const u8) []const u8 {
    var i: usize = 0;
    while (line[i] != '=') {
        i += 1;
    }
    return line[i + 1 ..];
}

// ignore errors idc
pub fn readConfigFile(filename: []const u8) !Config {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [256]u8 = undefined;

    const allocator = std.heap.page_allocator;
    var arr = std.ArrayList([]const u8).init(allocator);
    defer arr.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const val = get_conf_var(line);

        const memval = try allocator.alloc(u8, val.len);
        std.mem.copyForwards(u8, memval, val);

        //std.debug.print("Line: |{s}|\n", .{memval}); // Debug
        try arr.append(memval);
    }

    const link = try std.fmt.allocPrint(allocator, "{s}{s}", .{ arr.items[0], arr.items[1] });
    const target = try std.fmt.allocPrint(allocator, "{s}", .{ arr.items[2] });

    var targets = std.ArrayList([]const u8).init(allocator);
    defer targets.deinit();

    var len: i8 = 0;
    var it = std.mem.split(u8, arr.items[3], ",");
        while (it.next()) |x| {
            try targets.append(x);
            len += 1;
        }

    assert(len > 2);

    return Config{ .link = link, .conversion = target, .targets = targets };
}
