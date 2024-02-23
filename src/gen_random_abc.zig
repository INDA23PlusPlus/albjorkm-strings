const std = @import("std");
pub fn main() !void {
    var prng = std.rand.DefaultPrng.init(0);
    var random = prng.random();
    const writer = std.io.getStdOut().writer();
    const char_count = 30_000;
    for (0..char_count) |_| {
        const c = random.intRangeAtMost(u8, 'a', 'z');
        _ = try writer.print("{c}", .{c});
    }

    const test_count = 100;
    _ = try writer.print("\n{d}\n", .{test_count});

    for (0..test_count) |_| {
        const n1 = random.intRangeAtMost(usize, 0, char_count - 1);
        const n2 = random.intRangeAtMost(usize, 0, char_count - 1);
        _ = try writer.print("{d} {d}\n", .{ @min(n1, n2), @max(n1, n2) + 1 });
    }
}
