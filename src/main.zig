const std = @import("std");
const heap = std.heap;
const log = std.log;
const debug = std.debug;

const api = @import("api.zig");
const parser = @import("parser.zig");
const util = @import("util.zig");
const convert = @import("convert.zig");

pub fn main() !void {
    var gpa_aloc = heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa_aloc.deinit() == .leak) {
        log.warn("Memory leak detected.\n", .{});
    };
    const gpa = gpa_aloc.allocator();

    var req = api.FetchReq.init(gpa);
    defer req.deinit();

    const config = util.readConfigFile("conf.conf") catch {
        log.err("Failed to read config file.\n", .{});
        return;
    };

    debug.print("URL: |{s}|\n", .{config.link}); // Debug

    const res = try req.get(config.link, &.{});
    const body = try req.body.toOwnedSlice();
    defer req.allocator.free(body);

    // std.debug.print("Status: {s}\n", .{body}); // Debug

    if (res.status != .ok) {
        log.err("GET request failed - {s}\n", .{body});
        return;
    }

    //debug.print("Raw JSON: {s}\n", .{body}); // Debug

    var rates_map = try parser.parse_json(gpa, body, config.targets);
    defer rates_map.values.deinit();

    std.debug.print("N Rates: {d}\n", .{rates_map.length});
    for (config.targets.items) |target| {
        std.debug.print("{s}: {?}\n", .{ target, rates_map.values.get(target) });
    }

    const matrix = try convert.rates_matrix(gpa, rates_map, config.targets);
    defer {
        for (matrix) |*row| {
            gpa.free(row.*);
        }
        gpa.free(matrix);
    }

    for (matrix) |*row| {
        for (row.*) |val| {
            std.debug.print("{d} ", .{val});
        }
        std.debug.print("\n", .{});
    }
}
