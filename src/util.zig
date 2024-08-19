const std = @import("std");
const assert = std.debug.assert;

const Config = struct {
    link: []const u8,
    targets: std.ArrayList([]const u8),
};

pub fn compareStrings(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.order(u8, lhs, rhs).compare(std.math.CompareOperator.lt);
}

pub fn str_contains(str: []const u8, ch: u8) bool {
    for (str) |c| {
        if (c == ch) {
            return true;
        }
    }
    return false;
}

pub fn is_it_in(n: usize, arr: []usize) bool {
    for (arr) |x| {
        if (x == n) {
            return true;
        }
    }
    return false;
}

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

        try arr.append(memval);
    }

    const link = try std.fmt.allocPrint(allocator, "{s}{s}", .{ arr.items[0], arr.items[1] });

    var targets = std.ArrayList([]const u8).init(allocator);
    // DO NOT DEFER

    var len: i8 = 0;
    var it = std.mem.split(u8, arr.items[2], ",");
    while (it.next()) |x| {
        try targets.append(x);
        len += 1;
    }

    assert(len > 2);

    return Config{ .link = link, .targets = targets };
}

// readConfigFile() // Debug
//std.debug.print("Line: |{s}|\n", .{memval}); // Debug
