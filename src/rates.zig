const std = @import("std");
const assert = std.debug.assert;
const heap = std.heap;
const log = std.log;

const util = @import("util.zig");

const RatesMap = struct {
    name: []const u8,
    rate: f64,
};

pub const Rates = struct {
    dim: usize,
    currencies: std.ArrayList([]const u8),
    map: std.StringHashMap(f64),
    graph: [][]const f64,

    pub fn free(self: *Rates, allocator: std.mem.Allocator) void {
        for (self.graph) |row| {
            allocator.free(row);
        }
        allocator.free(self.graph);

        self.map.deinit();
        self.currencies.deinit();
    }

    pub fn print(self: *const Rates) void {
        std.debug.print("Dim: {d}\n", .{self.dim});
        std.debug.print("Currencies: {s}\n", .{self.currencies.items});
        for (0..self.dim) |i| {
            std.debug.print("{s}: {?}\n", .{ self.currencies.items[i], self.map.get(self.currencies.items[i]).? });
        }
        for (self.graph) |row| {
            std.debug.print("{any}\n", .{row});
        }
    }
};

// PARSE TIME =  74459ns | 72µs | kinda spaghetti but good enough for now
pub fn parse_json(gpa: std.mem.Allocator, body: []const u8, targets: std.ArrayList([]const u8)) !Rates {
    var h = std.StringHashMap(f64).init(gpa);
    // ret value - DO NOT DEFER

    var lines = std.mem.split(u8, body, "\n");

    var timestamp: u64 = 0;
    var i: usize = 0;
    var rate_count: usize = 0;
    while (lines.next()) |line| {
        if (i > 170 and util.str_contains(line, '}')) {
            break;
        }
        if (i == 3) {
            timestamp = get_timestamp(line);
            assert(timestamp > 0);
        }
        if (i > 5) {
            const rate = get_rate(line);
            for (targets.items) |target| {
                if (std.mem.eql(u8, rate.name, target)) {
                    try h.put(rate.name, rate.rate);
                    rate_count += 1;
                }
            }
        }
        i += 1;
    }

    assert(rate_count > 0);
    std.debug.print("Timestamp: {?}\n", .{timestamp});
    std.debug.print("Num Rates: {?}\n", .{rate_count});

    // had issues extracting to a function
    // error: access of union field 'Pointer' while field 'Struct' is active
    // ret value - DO NOT DEFER
    var graph = try gpa.alloc([]f64, rate_count);
    for (graph) |*row| {
        row.* = try gpa.alloc(f64, rate_count);
    }

    for (0..rate_count) |j| {
        const base = h.get(targets.items[j]).?;
        for (0..rate_count) |k| {
            graph[j][k] = h.get(targets.items[k]).? / base;
        }
    }

    return Rates{ .dim = rate_count, .currencies = targets, .map = h, .graph = graph };
}

fn get_timestamp(line: []const u8) u64 {
    var timestamp: u64 = 0;
    var found = false;

    for (line) |c| {
        if (c >= '0' and c <= '9') {
            timestamp = timestamp * 10 + (c - '0');
            found = true;
        } else if (found) {
            break;
        }
    }

    if (found) {
        return timestamp;
    }

    std.log.err("Timestamp not found.\n", .{});
    return 0;
}

fn get_rate(line: []const u8) RatesMap {
    const line_len = line.len;

    // dont feel like making a proper parser
    // change if API res changes format
    const name_start = 5;
    const name_end = 8;

    const rate_start = 11;
    const rate_end = line_len;

    const name: []const u8 = line[name_start..name_end];

    var rate_str: []const u8 = undefined;

    if (line[rate_end - 1] == ',') {
        rate_str = line[rate_start .. rate_end - 1];
    } else {
        rate_str = line[rate_start..rate_end];
    }

    const rate: f64 = util.stringToF64(rate_str) catch {
        std.log.err("Failed to parse rate. {s}\n", .{rate_str});
        return RatesMap{ .name = name, .rate = 0.0 };
    };

    return RatesMap{ .name = name, .rate = rate };
}
