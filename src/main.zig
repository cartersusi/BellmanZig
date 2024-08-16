const std = @import("std");
const http = std.http;
const heap = std.heap;
const assert = std.debug.assert;

const Client = std.http.Client;
const Headers = std.http.Headers;
const RequestOptions = std.http.Client.RequestOptions;

const RatesMap = struct {
    name: []const u8,
    rate: f64,
};

// https://github.com/BrookJeynes/zig-fetch
const FetchReq = struct {
    const Self = @This();
    const Allocator = std.mem.Allocator;

    allocator: Allocator,
    client: std.http.Client,
    body: std.ArrayList(u8),

    pub fn init(allocator: Allocator) Self {
        const c = Client{ .allocator = allocator };
        return Self{
            .allocator = allocator,
            .client = c,
            .body = std.ArrayList(u8).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.client.deinit();
        self.body.deinit();
    }

    /// Blocking
    pub fn get(self: *Self, url: []const u8, headers: []http.Header) !Client.FetchResult {
        const fetch_options = Client.FetchOptions{
            .location = Client.FetchOptions.Location{
                .url = url,
            },
            .extra_headers = headers,
            .response_storage = .{ .dynamic = &self.body },
        };

        const res = try self.client.fetch(fetch_options);
        return res;
    }
};

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

fn stringToF64(input: []const u8) !f64 {
    return std.fmt.parseFloat(f64, input);
}

fn get_rate(line: []const u8) RatesMap {
    const line_len = line.len;

    // change if API res changes
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

    //std.debug.print("Name: |{s}|, Rate: |{s}|\n", .{name, rate_str}); // Debug

    const rate: f64 = stringToF64(rate_str) catch {
        std.log.err("Failed to parse rate. {s}\n", .{rate_str});
        return RatesMap{ .name = name, .rate = 0.0 };
    };

    return RatesMap{ .name = name, .rate = rate };
}

fn str_contains(haystack: []const u8, needle: u8) bool {
    var win = std.mem.window(u8, haystack, 1, 1);

    while (win.next()) |slice| {
        if (slice[0] == needle) {
            return true;
        }
    }
    return false;
}

// API TIME: 132360724ns | 131082µs
// PARSE TIME =  74459ns | 72µs | kinda spaghetti but good enough for now
pub fn main() !void {
    var gpa_aloc = heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa_aloc.deinit() == .leak) {
        std.log.warn("Memory leak detected.\n", .{});
    };
    const gpa = gpa_aloc.allocator();

    var req = FetchReq.init(gpa);
    defer req.deinit();

    // GET Req
    {
        const api_key: []const u8 = "YOUR_API_KEY";
        const link: []const u8 = "http://openexchangerates.org/api/latest.json?app_id=";

        const url_str = link ++ api_key;

        // std.debug.print("URL: {s}\n", .{url_str}); // Debug

        const res = try req.get(url_str, &.{});
        const body = try req.body.toOwnedSlice();
        defer req.allocator.free(body);

        if (res.status != .ok) {
            std.log.err("GET request failed - {s}\n", .{body});
            return;
        }

        //std.debug.print("Raw JSON: {s}\n", .{body}); // Debug

        var lines = std.mem.split(u8, body, "\n");

        const aloc = std.heap.page_allocator;
        var rmap = std.ArrayList(RatesMap).init(aloc);
        defer rmap.deinit();

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
                try rmap.append(rate);
                rate_count += 1;
            }
            i += 1;
        }

        assert(rate_count == 169);
        std.debug.print("Timestamp: {d}\n", .{timestamp});
        std.debug.print("Num Rates: {d}\n", .{rate_count});
    }
}
