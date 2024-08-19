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
    currencies: [][]const u8,
    graph: [][]const f64,

    pub fn free(self: *Rates, allocator: std.mem.Allocator) void {
        for (self.graph) |row| {
            allocator.free(row);
        }
        allocator.free(self.graph);
    }

    pub fn print(self: *const Rates) void {
        std.debug.print("Dim: {d}\n", .{self.dim});
        std.debug.print("Currencies: {s}\n", .{self.currencies.items});
        for (self.graph) |row| {
            std.debug.print("{any}\n", .{row});
        }
    }
};

// PARSE TIME =  74459ns | 72µs | kinda spaghetti but good enough for now
pub fn parse_json(gpa: std.mem.Allocator, body: []const u8, targets: [][]const u8) !Rates {
    // ret value - DO NOT DEFER
    // had issues extracting to a function
    // error: access of union field 'Pointer' while field 'Struct' is active
    var graph = try gpa.alloc([]f64, targets.len);
    for (graph) |*row| {
        row.* = try gpa.alloc(f64, targets.len);
    }

    var lines = std.mem.split(u8, body, "\n");

    var timestamp: u64 = 0;
    var i: usize = 0;
    var rate_count: usize = 0;
    while (lines.next()) |line| {
        if (rate_count == targets.len) {
            break;
        }
        if (i > 170 and util.str_contains(line, '}')) {
            break;
        }
        if (i == 3) {
            timestamp = get_timestamp(line);
            assert(timestamp > 0);
        }
        if (i > 5) {
            // 3 char currency code 5..8
            if (std.mem.eql(u8, line[5..8], targets[rate_count])) {
                const rate = try get_rate(line);
                graph[0][rate_count] = rate;
                rate_count += 1;
            }
        }
        i += 1;
    }

    assert(rate_count > 0);
    std.debug.print("Timestamp: {?}\n", .{timestamp});
    std.debug.print("Num Rates: {?}\n", .{rate_count});

    for (0..rate_count) |j| {
        const base = graph[0][j];
        for (0..rate_count) |k| {
            graph[j][k] = graph[0][k] / base;
        }
    }

    return Rates{ .dim = rate_count, .currencies = targets, .graph = graph };
}

fn get_timestamp(line: []const u8) u64 {
    //what happened to @XtoY(y,x) ?
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

fn get_rate(line: []const u8) !f64 {
    const line_len = line.len;

    // dont feel like making a proper parser
    // change if API res changes format

    const rate_start = 11;
    const rate_end = line_len;

    var rate_str: []const u8 = undefined;

    if (line[rate_end - 1] == ',') {
        rate_str = line[rate_start .. rate_end - 1];
    } else {
        rate_str = line[rate_start..rate_end];
    }

    const rate = std.fmt.parseFloat(f64, rate_str) catch {
        std.log.err("Failed to parse rate.\n", .{});
        return 0.0;
    };

    return rate;
}
