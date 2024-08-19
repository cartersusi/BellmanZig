const std = @import("std");
const heap = std.heap;
const log = std.log;
const debug = std.debug;

const dprint = std.debug.print;

const api = @import("api.zig");
const rates = @import("rates.zig");
const util = @import("util.zig");
const bellmain = @import("bellman.zig");

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
    // slice config.targets
    const targets = config.targets.items;
    std.sort.insertion([]const u8, targets, {}, util.compareStrings);
    dprint("Targets: {s}\n", .{targets});

    const res = try req.get(config.link, &.{});
    const body = try req.body.toOwnedSlice();
    defer req.allocator.free(body);

    if (res.status != .ok) {
        log.err("GET request failed - {s}\n", .{body});
        return;
    }

    var currency_rates = try rates.parse_json(gpa, body, targets);
    defer currency_rates.free(gpa);

    try bellmain.arbitrage(gpa, currency_rates);
}

// debug.print("URL: |{s}|\n", .{config.link}); // Debug
// std.debug.print("Status: {s}\n", .{body}); // Debug
//std.debug.print("Targets: {s}\n", .{targets}); // Debug
//debug.print("Raw JSON: {s}\n", .{body}); // Debug
//currency_rates.print(); // Debug

//m1
//API TIME =  123ms
//PARSE TIME =  442µs
//ALG TIME =  783µs
