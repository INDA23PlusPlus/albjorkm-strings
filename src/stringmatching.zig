const std = @import("std");

fn noopLog(comptime _: []const u8, _: anytype) void {}
const debugLog = noopLog;
//const debugLog = std.debug.print;

fn findOccurances(term: []u8, source: []u8, output: anytype) !void {
    // In the one line bible, we expect 4121
    // grep -aob God one_line_bible.txt | wc -l

    const hash_offset = 7;

    var wanted_hash: u64 = 0;
    for (term) |t| {
        wanted_hash <<= 1;
        wanted_hash ^= (t +% hash_offset);
    }
    debugLog("wanted_hash is: {x}\n", .{wanted_hash});

    var misses: usize = 0;
    var found: usize = 0;

    var hash: u64 = 0;
    for (0..source.len) |i| {
        const t = source[i];
        if (i >= term.len and term.len < 64) {
            const first: u64 = @as(u8, source[i - term.len] +% hash_offset);
            const shift_by = term.len - 1;
            debugLog("trying to undo: {c} after adding {c}, shifted_by: {d}\n", .{ @as(u8, @truncate(first)), t, shift_by });
            hash ^= (first << @truncate(shift_by));
        }
        debugLog("before: {x}\n", .{hash});
        hash <<= 1;
        hash ^= (t +% hash_offset);
        debugLog("after: {x} at {d}\n", .{ hash, i });
        if (wanted_hash == hash) {
            const search_range = source[i + 1 - term.len .. i + 1];
            debugLog("possible match '{s}' and '{s}' at {d}\n", .{ search_range, term, i });
            if (i + 1 >= term.len) {
                if (term.len > 16 or std.mem.eql(u8, term, search_range)) {
                    debugLog("WE FOUND ONE, A REAL ONE!\n", .{});
                    _ = try output.print("{d} ", .{i + 1 - term.len});
                    //_ = try output.print("{d}:{s}\n", .{ i + 1 - term.len, term });
                    found += 1;
                } else {
                    misses += 1;
                }
            }
        }
    }

    _ = .{ found, misses };
    //std.debug.print("found: {d}, misses: {d}\n", .{ found, misses });

    _ = try output.writeAll("\n");
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();

    const term_buf = try alloc.alloc(u8, 1024 * 1024 * 6);
    const source_buf = try alloc.alloc(u8, 1024 * 1024 * 6);
    var buffered = std.io.bufferedReaderSize(1024 * 1024, std.io.getStdIn().reader());
    const inp = buffered.reader();

    var slowOutput = std.io.getStdOut();
    var bufferedOutput = std.io.bufferedWriter(slowOutput.writer());
    const writer = bufferedOutput.writer();

    while (try inp.readUntilDelimiterOrEof(term_buf, '\n')) |term| {
        if (term.len == 0) {
            break;
        }
        if (try inp.readUntilDelimiterOrEof(source_buf, '\n')) |source| {
            if (source.len == 0) {
                break;
            }
            try findOccurances(term, source, writer);
        }
    }
    try bufferedOutput.flush();
}
