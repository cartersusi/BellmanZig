const std = @import("std");
const mem = std.mem;
const log = std.log;

const dprint = std.debug.print;
const assert = std.debug.assert;

const util = @import("util.zig");

pub const Rates = struct {
    dim: usize,
    currencies: [][]const u8,
    graph: [][]const f64,

    pub fn free(self: *Rates, allocator: mem.Allocator) void {
        for (self.graph) |row| {
            allocator.free(row);
        }
        allocator.free(self.graph);
    }

    pub fn print(self: *const Rates) void {
        dprint("Dim: {d}\n", .{self.dim});
        dprint("Currencies: {s}\n", .{self.currencies.items});
        for (self.graph) |row| {
            dprint("{any}\n", .{row});
        }
    }
};

pub fn parse_json(gpa: mem.Allocator, body: []const u8, targets: [][]const u8) !Rates {
    var graph = try gpa.alloc([]f64, targets.len);
    for (graph) |*row| {
        row.* = try gpa.alloc(f64, targets.len);
    }

    var lines = mem.split(u8, body, "\n");

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
            // 3 char currency code 5..8, dependent on target being sorted
            if (mem.eql(u8, line[5..8], targets[rate_count])) {
                const rate = try get_rate(line);
                graph[0][rate_count] = rate;
                rate_count += 1;
            }
        }
        i += 1;
    }

    assert(rate_count > 0);
    dprint("Timestamp: {d}\n", .{timestamp});
    dprint("Num Rates: {any}\n", .{rate_count});

    for (0..rate_count) |j| {
        const base = graph[0][j];
        for (0..rate_count) |k| {
            graph[j][k] = graph[0][k] / base;
        }
    }

    return Rates{ .dim = rate_count, .currencies = targets, .graph = graph };
}

fn get_timestamp(line: []const u8) u64 { //what happened to @XtoY(y,x) ?
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

    log.err("Timestamp not found.\n", .{});
    return 0;
}

fn get_rate(line: []const u8) !f64 {
    const line_len = line.len;

    var rate_str: []const u8 = undefined;

    // floats start at 11
    if (line[line_len - 1] == ',') {
        rate_str = line[11 .. line_len - 1];
    } else {
        rate_str = line[11..line_len];
    }

    const rate = std.fmt.parseFloat(f64, rate_str) catch {
        log.err("Failed to parse rate.\n", .{});
        return 0.0;
    };

    return rate;
}
