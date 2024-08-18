const std = @import("std");
const assert = std.debug.assert;
const heap = std.heap;
const log = std.log;

const RatesMap = struct {
    name: []const u8,
    rate: f64,
};

pub const Rates = struct {
    length: usize,
    values: std.StringHashMap(f64),
};

pub fn stringToF64(input: []const u8) !f64 {
    return std.fmt.parseFloat(f64, input);
}

pub fn str_contains(str: []const u8, ch: u8) bool {
    for (str) |c| {
        if (c == ch) {
            return true;
        }
    }
    return false;
}

pub fn get_timestamp(line: []const u8) u64 {
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

pub fn get_rate(line: []const u8) RatesMap {
    const line_len = line.len;

    // dont feel like to make a proper parser
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

    const rate: f64 = stringToF64(rate_str) catch {
        std.log.err("Failed to parse rate. {s}\n", .{rate_str});
        return RatesMap{ .name = name, .rate = 0.0 };
    };

    return RatesMap{ .name = name, .rate = rate };
}

// PARSE TIME =  74459ns | 72µs | kinda spaghetti but good enough for now
pub fn parse_json(gpa: std.mem.Allocator, body: []const u8, targets: std.ArrayList([]const u8)) !Rates {
    var h = std.StringHashMap(f64).init(gpa);
    // ret value - DO NOT DEFER

    var lines = std.mem.split(u8, body, "\n");

    var timestamp: u64 = 0;
    var i: usize = 0;
    var rate_count: usize = 0;
    while (lines.next()) |line| {
        if (i > 170 and str_contains(line, '}')) {
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
    std.debug.print("Timestamp: {d}\n", .{timestamp});
    std.debug.print("Num Rates: {d}\n", .{rate_count});

    return Rates{ .length = rate_count, .values = h };
}
