const std = @import("std");

fn noopLog(comptime _: []const u8, _: anytype) void {}
const debugLog = noopLog;
//const debugLog = std.debug.print;

const Node = union(enum) {
    leaf: usize,
    node: struct {
        left: *Node,
        right: *Node,
    },
};

const Parser = struct {
    input: []u8,
    at: usize,
};

pub fn print_node(node: *Node, depth: usize) void {
    for (0..depth) |_| {
        debugLog("  ", .{});
    }
    switch (node.*) {
        .leaf => |u| {
            debugLog("{d}\n", .{u});
        },
        .node => |n| {
            debugLog("node:\n", .{});
            print_node(n.left, depth + 1);
            print_node(n.right, depth + 1);
        },
    }
}

pub fn parse(alloc: std.mem.Allocator, p: *Parser) *Node {
    const node = alloc.create(Node) catch @panic("oom");
    switch (p.input[p.at]) {
        '0'...'9' => {
            const start = p.at;
            while (p.input[p.at] >= '0' and p.input[p.at] <= '9') {
                p.at += 1;
            }
            const end = p.at;

            const num_str = p.input[start..end];
            const num = std.fmt.parseInt(usize, num_str, 10) catch @panic("bad format");

            node.* = .{ .leaf = num };
        },
        '(' => {
            p.at += 1;
            const left = parse(alloc, p);
            p.at += 1;
            const right = parse(alloc, p);
            p.at += 1;

            node.* = Node{ .node = .{
                .left = left,
                .right = right,
            } };
        },
        else => {
            p.at += 1;
        },
    }

    return node;
}

const biggus_modulus = 3318308475676071413;
const optimus_primus = 1499;

fn scan_n_hash(node: *Node, primes: []u128, hashes: *std.ArrayList(u128)) u128 {
    switch (node.*) {
        .leaf => |l| {
            const value = primes[l];
            hashes.append(value) catch @panic("oom");
            return value;
        },
        .node => |n| {
            const a = scan_n_hash(n.left, primes, hashes);
            const b = scan_n_hash(n.right, primes, hashes);
            const value = (a + b) % biggus_modulus;
            hashes.append(value) catch @panic("oom");
            return value;
        },
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var alloc = gpa.allocator();

    const cmd_buf = try alloc.alloc(u8, 1024 * 1024 * 6);
    const a_buf = try alloc.alloc(u8, 1024 * 1024 * 6);
    const b_buf = try alloc.alloc(u8, 1024 * 1024 * 6);
    var buffered = std.io.bufferedReaderSize(1024 * 1024, std.io.getStdIn().reader());
    const inp = buffered.reader();

    var slowOutput = std.io.getStdOut();
    var bufferedOutput = std.io.bufferedWriter(slowOutput.writer());
    const writer = bufferedOutput.writer();

    var primes: [100_001]u128 = undefined;
    var prime_acc: u128 = 1;
    for (&primes) |*prime| {
        prime.* = prime_acc;
        prime_acc = (prime_acc *% optimus_primus) % biggus_modulus;
    }

    // TODO: Do a swap remove.

    if (try inp.readUntilDelimiterOrEof(cmd_buf, '\n')) |_| {
        if (try inp.readUntilDelimiterOrEof(a_buf, '\n')) |a| {
            var a_parser = Parser{ .at = 0, .input = a };
            const a_node = parse(alloc, &a_parser);
            if (try inp.readUntilDelimiterOrEof(b_buf, '\n')) |b| {
                var b_parser = Parser{ .at = 0, .input = b };
                const b_node = parse(alloc, &b_parser);

                var a_hashes = std.ArrayList(u128).init(alloc);
                _ = scan_n_hash(a_node, &primes, &a_hashes);

                var b_hashes = std.ArrayList(u128).init(alloc);
                _ = scan_n_hash(b_node, &primes, &b_hashes);

                var hash_hash_map = std.AutoHashMap(u128, bool).init(alloc);

                //debugLog("A node:\n", .{});
                //print_node(a_node, 0);
                //debugLog("B node:\n", .{});
                //print_node(b_node, 0);
                for (a_hashes.items) |v| {
                    debugLog("A hash: {d}\n", .{v});
                    try hash_hash_map.put(v, true);
                }

                var matches: u64 = 0;
                for (b_hashes.items) |v| {
                    debugLog("B hash: {d}\n", .{v});
                    if (hash_hash_map.contains(v)) {
                        matches += 1;
                    }
                }
                debugLog("total matches: {d}\n", .{matches});
                _ = try writer.print("{d}\n", .{matches});
            }
        }
    }

    try bufferedOutput.flush();
}
