const std = @import("std");

const parser = @import("parser.zig");

pub fn rates_matrix(gpa: std.mem.Allocator, rates_map: parser.Rates, targets: std.ArrayList([]const u8)) ![][]const f64 {
    var matrix = try gpa.alloc([]f64, rates_map.length);

    for (matrix) |*row| {
        row.* = try gpa.alloc(f64, rates_map.length);
    }

    for (0..rates_map.length) |i| {
        for (0..rates_map.length) |j| {
            matrix[i][j] = rates_map.values.get(targets.items[j]).?;
        }
    }

    return matrix;
}
