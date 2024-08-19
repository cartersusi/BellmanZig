const std = @import("std");
const http = std.http;

const Client = std.http.Client;
const Headers = std.http.Headers;
const RequestOptions = std.http.Client.RequestOptions;

// ty @ https://github.com/BrookJeynes/zig-fetch
pub const FetchReq = struct {
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
