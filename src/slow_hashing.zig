const std = @import("std");

fn noopLog(comptime _: []const u8, _: anytype) void {}
const debugLog = noopLog;
//const debugLog = std.debug.print;

fn computeHash(term: []u8, output: anytype) !void {
    // In the one line bible, we expect 4121
    // grep -aob God one_line_bible.txt | wc -l

    var hash: u64 = std.math.maxInt(u64) - term.len;
    for (term) |t| {
        hash *%= 31;
        hash +%= (t -% 'a');
    }
    debugLog("wanted_hash is: {x}\n", .{hash}); //std.debug.print("found: {d}, misses: {d}\n", .{ found, misses });

    _ = try output.print("{d}\n", .{hash});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();

    const cmd_buf = try alloc.alloc(u8, 1024 * 1024 * 6);
    const source_buf = try alloc.alloc(u8, 1024 * 1024 * 6);
    var buffered = std.io.bufferedReaderSize(1024 * 1024, std.io.getStdIn().reader());
    const inp = buffered.reader();

    var slowOutput = std.io.getStdOut();
    var bufferedOutput = std.io.bufferedWriter(slowOutput.writer());
    const writer = bufferedOutput.writer();

    if (try inp.readUntilDelimiterOrEof(source_buf, '\n')) |source| {
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

                try computeHash(source[a..b], writer);
            }
        }
    }

    try bufferedOutput.flush();
}
