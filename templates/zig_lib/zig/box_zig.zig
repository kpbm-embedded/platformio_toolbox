//! box_zig: Zig functions exported with the C ABI (see ../include/box_zig.h), built as a static library
//! by ../scripts/zig.py for the env's target (custom_zig_target / custom_zig_cpu in platformio.ini).
const std = @import("std");

/// CRC-16/MODBUS (poly 0xA001 reflected, init 0xFFFF).
export fn box_crc16_modbus(data: ?[*]const u8, len: usize) u16 {
    const bytes = (data orelse return 0)[0..len];
    return crc16Modbus(bytes);
}

pub fn crc16Modbus(bytes: []const u8) u16 {
    var crc: u16 = 0xFFFF;
    for (bytes) |b| {
        crc ^= b;
        var bit: u4 = 0;
        while (bit < 8) : (bit += 1) {
            crc = if (crc & 1 != 0) (crc >> 1) ^ 0xA001 else crc >> 1;
        }
    }
    return crc;
}

/// Linear map of a raw ADC reading (0..adc_max) to millivolts (0..vref_mv), clamped.
export fn box_adc_to_mv(raw: u32, adc_max: u32, vref_mv: u32) u32 {
    if (adc_max == 0) return 0;
    const clamped = @min(raw, adc_max);
    return @intCast(@as(u64, clamped) * vref_mv / adc_max);
}

/// Counts the set bits of a 32-bit mask (e.g. active channels).
export fn box_popcount32(mask: u32) u8 {
    return @popCount(mask);
}

test "crc16 modbus reference value" {
    try std.testing.expectEqual(@as(u16, 0x4B37), crc16Modbus("123456789"));
}

test "adc mapping clamps" {
    try std.testing.expectEqual(@as(u32, 3300), box_adc_to_mv(5000, 4095, 3300));
    try std.testing.expectEqual(@as(u32, 1650), box_adc_to_mv(2048, 4096, 3300));
}
