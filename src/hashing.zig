const std = @import("std");

fn noopLog(comptime _: []const u8, _: anytype) void {}
const debugLog = noopLog;
//const debugLog = std.debug.print;

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

    var hashes: [300_001]u128 = undefined;

    if (try inp.readUntilDelimiterOrEof(source_buf, '\n')) |source| {
        if (try inp.readUntilDelimiterOrEof(cmd_buf, '\n')) |count_str| {
            const count = try std.fmt.parseInt(u64, count_str, 10);
            if (count == 0) {
                return;
            }

            // Simon's Constants https://en.wikipedia.org/wiki/Simon's_Constants
            //const biggus_modulus = 12055296811267;
            //const optimus_primus = 769;

            //                     18446744073709551615 - u64 max
            const biggus_modulus = 3318308475676071413;
            const optimus_primus = 1499;

            var hash: u128 = 0;
            hashes[0] = 0;
            for (source, 1..) |c, i| {
                hash = ((hash *% optimus_primus) % biggus_modulus) + @as(u128, @as(u8, c -% 'a' +% 1)) % biggus_modulus;
                hashes[i] = hash;
                //std.debug.print("{c} at {d}: {d}\n", .{ c, i, hash });
            }

            var primes: [300_001]u128 = undefined;
            var prime_acc: u128 = 1;
            for (&primes) |*prime| {
                prime.* = prime_acc;
                prime_acc = (prime_acc *% optimus_primus) % biggus_modulus;
            }

            const range_points = try inp.readUntilDelimiterOrEof(cmd_buf, 0) orelse @panic("could not read in time");
            var tokens = std.mem.tokenizeAny(u8, range_points, &std.ascii.whitespace);
            for (0..count) |_| {
                const a_str = tokens.next() orelse @panic("a");
                const b_str = tokens.next() orelse @panic("b");

                const a = try std.fmt.parseInt(usize, a_str, 10);
                const b = try std.fmt.parseInt(usize, b_str, 10);

                //const factor = std.math.pow(u128, optimus_primus, b - a) % biggus_modulus;
                //overflows...

                const left = (primes[b - a] *% hashes[a]) % biggus_modulus;

                const wrapped_h = ((hashes[b] -% left +% biggus_modulus) % biggus_modulus);
                _ = try writer.print("{d}\n", .{wrapped_h});
            }
        }
    }

    try bufferedOutput.flush();
}
