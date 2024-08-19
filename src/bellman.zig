const std = @import("std");
const rates = @import("rates.zig");
const util = @import("util.zig");
const time = std.time;

fn negateLogarithmConvertor(gpa: std.mem.Allocator, graph: [][]const f64, dim: usize) ![][]const f64 {
    var ret = try gpa.alloc([]f64, dim);
    for (ret) |*row| {
        row.* = try gpa.alloc(f64, dim);
    }

    for (0..dim) |i| {
        for (0..dim) |j| {
            if (graph[i][j] == 0e0) {
                ret[i][j] = std.math.inf(f64);
            } else {
                ret[i][j] = std.math.log(f64, std.math.e, graph[i][j]);
            }
        }
    }

    return ret;
}

pub fn arbitrage(gpa: std.mem.Allocator, currency_rates: rates.Rates) !void {
    const dim = currency_rates.dim;
    const graph = currency_rates.graph;
    const inf = std.math.inf(f64);

    const trans_graph = try negateLogarithmConvertor(gpa, graph, dim);
    var min_dist = try gpa.alloc(f64, dim);
    var pre = try gpa.alloc(usize, dim);

    defer {
        for (trans_graph) |row| {
            gpa.free(row);
        }
        gpa.free(trans_graph);
        gpa.free(min_dist);
        gpa.free(pre);
    }

    for (0..dim) |i| {
        min_dist[i] = inf;
        pre[i] = undefined;
    }

    for (0..dim) |source| {
        min_dist[source] = 0;

        for (0..dim - 1) |_| {
            for (0..dim) |source_curr| {
                for (0..dim) |dest_curr| {
                    if (source_curr == dest_curr or trans_graph[source_curr][dest_curr] == inf) {
                        continue;
                    }
                    if (min_dist[dest_curr] > (min_dist[source_curr] + trans_graph[source_curr][dest_curr])) {
                        min_dist[dest_curr] = (min_dist[source_curr] + trans_graph[source_curr][dest_curr]);
                        pre[dest_curr] = source_curr;
                    }
                }
            }
        }

        var source_curr: usize = 0;
        for (0..dim) |i| {
            source_curr = i;

            for (0..dim) |dest_curr| {
                if (source_curr == dest_curr or trans_graph[source_curr][dest_curr] == inf) {
                    continue;
                }

                if (min_dist[dest_curr] > (min_dist[source_curr] + trans_graph[source_curr][dest_curr])) {
                    var print_cycle = std.ArrayList(usize).init(gpa);
                    defer print_cycle.deinit();

                    try print_cycle.append(dest_curr);
                    try print_cycle.append(source_curr);

                    while (!util.is_it_in(pre[source_curr], print_cycle.items)) {
                        source_curr = pre[source_curr];
                        try print_cycle.append(source_curr);
                    }

                    try print_cycle.append(pre[source_curr]);

                    if (print_cycle.items[0] == print_cycle.items[print_cycle.items.len - 1]) {
                        std.debug.print("Arbitrage opportunity:\n", .{});
                        const num = util.arr_len(print_cycle);
                        for (0..num) |x| {
                            if (x == num - 1) {
                                std.debug.print("{s}\n", .{currency_rates.currencies.items[print_cycle.items[x]]});
                                continue;
                            }
                            std.debug.print("{s} --->", .{currency_rates.currencies.items[print_cycle.items[x]]});
                        }
                    }
                }
            }
        }
    }
}

// negateLogarithmConvertor // Debug
//for (0..dim) |i| {  // Debug
//    std.debug.print("\n", .{});
//    for (0..dim) |j| {
//        std.debug.print("{} ", .{ret[i][j]});
//    }
//}
