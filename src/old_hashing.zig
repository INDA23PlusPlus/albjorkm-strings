const std = @import("std");

fn noopLog(comptime _: []const u8, _: anytype) void {}
const debugLog = noopLog;
//const debugLog = std.debug.print;

pub fn computePrehashes(start: usize, prehashes: []usize, str: []u8) usize {
    if (start > prehashes.len) {
        const index = start - prehashes.len;
        if (index >= str.len) {
            return 0;
        }
        return str[index];
    } else {
        const a = computePrehashes(start * 2 + 1, prehashes, str);
        const b = computePrehashes(start * 2 + 2, prehashes, str);
        prehashes[start] = a + b;
    }
}

pub fn limitedHash(start: usize, end: usize, node: usize, len: usize, prehashes: []usize) {
    const  mid = prehashes.len / 2;
    if (start < mid) {
        limitedHash()
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();

    const cmd_buf = try alloc.alloc(u8, 1024 * 1024 * 6);
    const source_buf = try alloc.alloc(u8, 300_001);
    const hashes = try alloc.alloc(u64, 300_001);

    var buffered = std.io.bufferedReaderSize(1024 * 1024, std.io.getStdIn().reader());
    const inp = buffered.reader();

    var slowOutput = std.io.getStdOut();
    var bufferedOutput = std.io.bufferedWriter(slowOutput.writer());
    const writer = bufferedOutput.writer();

    var prehashes: [150000]usize = undefined;

    if (try inp.readUntilDelimiterOrEof(source_buf, '\n')) |source| {
        computePrehashes(0, &prehashes, source);
        var hash: u64 = 1;
        for (source, 0..) |c, i| {
            //std.debug.print("hashing: {c}\n", .{c});
            hash *= 31;
            hash += (c -% 'a');
            hashes[i] = hash;
        }

        if (try inp.readUntilDelimiterOrEof(cmd_buf, '\n')) |count_str| {
            const count = try std.fmt.parseInt(u64, count_str, 10);
            if (count == 0) {
                return;
            }
            const range_points = try inp.readUntilDelimiterOrEof(cmd_buf, 0) orelse @panic("could not read in time");
            var tokens = std.mem.tokenizeAny(u8, range_points, &std.ascii.whitespace);
            for (0..count) |_| {
                const a_str = tokens.next() orelse @panic("a");
                const b_str = tokens.next() orelse @panic("b");

                const a = try std.fmt.parseInt(u64, a_str, 10);
                const b = try std.fmt.parseInt(u64, b_str, 10);

                _ = try writer.print("{d}\n", .{hashes[a] +% (hashes[b] * 3) +% a +% b});
            }
        }
    }

    try bufferedOutput.flush();
}
