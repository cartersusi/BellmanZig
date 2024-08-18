const std = @import("std");
const testing = std.testing;

//const api = @import("api.zig");
//const parser = @import("parser.zig");
//const util = @import("util.zig");


export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}
