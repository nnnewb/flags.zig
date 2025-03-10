const std = @import("std");
const mem = std.mem;
const heap = std.heap;
const testing = std.testing;
const flag = @import("flag.zig");

pub const Flags = struct {
    const GPA = std.heap.GeneralPurposeAllocator(.{});
    const UsageFunc = *const fn (allocator: mem.Allocator) void;

    usage: UsageFunc = defaultUsage,
    name: [:0]const u8 = "example",
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Flags {
        return .{
            .allocator = allocator,
        };
    }

    fn defaultUsage(allocator: mem.Allocator) void {
        var args = std.process.argsWithAllocator(allocator) catch {
            return;
        };
        defer args.deinit();

        if (args.next()) |arg| {
            std.io.getStdErr().writer().print("{s} [flags...] arguments...\n", .{arg}) catch {};
        }
    }
};

test {
    testing.refAllDeclsRecursive(@import("flag.zig"));
    testing.refAllDeclsRecursive(@import("iterator.zig"));
}

test "defaultUsage" {
    Flags.defaultUsage(testing.allocator);
}
