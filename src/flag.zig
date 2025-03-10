const std = @import("std");
const mem = std.mem;
const testing = std.testing;

pub const FlagParseError = error{
    NoNameSpecified,
    InvalidBool,
    InvalidInt,
    InvalidFloat,
    UnsupportedType,
};

pub fn Flag(comptime T: type) type {
    comptime switch (@typeInfo(T)) {
        .Int, .Float, .Bool, @typeInfo([*]const u8) => {},
        else => @compileError("unsupported type"),
    };

    return struct {
        short: ?[]const u8,
        long: ?[]const u8,
        description: []const u8,
        default: T,
        target: *T,

        const Self = @This();

        pub fn init(short: ?[]const u8, long: ?[]const u8, description: []const u8, default: T, target: *T) error{NoNameSpecified}!Self {
            if (short == null and long == null) {
                return error.NoNameSpecified;
            }

            return .{
                .short = short,
                .long = long,
                .description = description,
                .default = default,
                .target = target,
            };
        }

        pub fn parse(self: *Self, value: []const u8) !void {
            switch (@typeInfo(T)) {
                .Bool => {
                    if (mem.eql(u8, value, "true")) {
                        self.target.* = true;
                    } else if (mem.eql(u8, value, "false")) {
                        self.target.* = false;
                    } else {
                        return error.InvalidBool;
                    }
                },
                .Int => {
                    self.target.* = std.fmt.parseInt(T, value, 10) catch {
                        return error.InvalidInt;
                    };
                },
                .Float => {
                    self.target.* = std.fmt.parseFloat(T, value) catch {
                        return error.InvalidFloat;
                    };
                },
                .Pointer => {
                    self.target.* = value;
                },
                else => {
                    return error.UnsupportedType;
                },
            }
        }
    };
}

test "Flag.init - no name" {
    var target: bool = false;
    const result = Flag(bool).init(null, null, "test", false, &target);
    try testing.expectError(FlagParseError.NoNameSpecified, result);
}

test "Flag.init - short name" {
    var target: bool = false;
    const result = try Flag(bool).init("-t", null, "test", false, &target);
    try testing.expect(result.short != null and mem.eql(u8, result.short.?, "-t"));
}

test "Flag.init - long name" {
    var target: bool = false;
    const result = try Flag(bool).init(null, "--test", "test", false, &target);
    try testing.expect(result.long != null and mem.eql(u8, result.long.?, "--test"));
}

test "Flag.parse - bool true" {
    var target: bool = false;
    var flag = try Flag(bool).init("-t", null, "test", false, &target);
    try flag.parse("true");
    try testing.expect(target == true);
}

test "Flag.parse - bool false" {
    var target: bool = true;
    var flag = try Flag(bool).init("-t", null, "test", true, &target);
    try flag.parse("false");
    try testing.expect(target == false);
}

test "Flag.parse - bool invalid" {
    var target: bool = false;
    var flag = try Flag(bool).init("-t", null, "test", false, &target);
    const result = flag.parse("invalid");
    try testing.expectError(FlagParseError.InvalidBool, result);
}

test "Flag.parse - int valid" {
    var target: i32 = 0;
    var flag = try Flag(i32).init("-n", null, "number", 0, &target);
    try flag.parse("123");
    try testing.expect(target == 123);
}

test "Flag.parse - int invalid" {
    var target: i32 = 0;
    var flag = try Flag(i32).init("-n", null, "number", 0, &target);
    const result = flag.parse("invalid");
    try testing.expectError(FlagParseError.InvalidInt, result);
}

test "Flag.parse - float valid" {
    var target: f32 = 0.0;
    var flag = try Flag(f32).init("-f", null, "float", 0.0, &target);
    try flag.parse("1.23");
    try testing.expect(target == 1.23);
}

test "Flag.parse - float invalid" {
    var target: f32 = 0.0;
    var flag = try Flag(f32).init("-f", null, "float", 0.0, &target);
    const result = flag.parse("invalid");
    try testing.expectError(FlagParseError.InvalidFloat, result);
}

test "Flag.parse - string valid" {
    var target: []const u8 = "";
    var flag = try Flag([]const u8).init("-s", null, "string", "", &target);
    try flag.parse("hello");
    try testing.expect(mem.eql(u8, target, "hello"));
}
