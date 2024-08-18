const std = @import("std");
const assert = std.debug.assert;

pub const RatesMap = struct {
    name: []const u8,
    rate: f64,
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
pub fn parse_json(body: []const u8) !std.ArrayList(RatesMap) {
    var lines = std.mem.split(u8, body, "\n");

    const aloc = std.heap.page_allocator;
    var rmap = std.ArrayList(RatesMap).init(aloc);
    // DO NOT DEFER RMAP

    var timestamp: u64 = 0;

    var i: i16 = 0;
    var rate_count: i16 = 0;

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
            try rmap.append(rate);
            rate_count += 1;
        }
        i += 1;
    }

    assert(rate_count == 169);
    std.debug.print("Timestamp: {d}\n", .{timestamp});
    std.debug.print("Num Rates: {d}\n", .{rate_count});

    return rmap;
}
