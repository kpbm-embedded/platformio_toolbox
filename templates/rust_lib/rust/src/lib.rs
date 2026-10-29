//! box_rust: small no_std functions exported with the C ABI (see ../include/box_rust.h).
//! Built by ../scripts/cargo.py for the env's target (custom_rust_target in platformio.ini).
#![cfg_attr(not(test), no_std)]

/// Fletcher-16 checksum of `len` bytes at `data` (0 for a null pointer).
///
/// # Safety
/// `data` must point to `len` readable bytes or be null.
#[no_mangle]
pub unsafe extern "C" fn box_fletcher16(data: *const u8, len: usize) -> u16 {
    if data.is_null() {
        return 0;
    }
    fletcher16(core::slice::from_raw_parts(data, len))
}

pub fn fletcher16(bytes: &[u8]) -> u16 {
    let (mut sum1, mut sum2) = (0u16, 0u16);
    for &b in bytes {
        sum1 = (sum1 + u16::from(b)) % 255;
        sum2 = (sum2 + sum1) % 255;
    }
    (sum2 << 8) | sum1
}

/// Exponential moving average in integer maths: value += (sample - value) >> shift.
#[repr(C)]
pub struct BoxEma {
    pub value: i32,
    pub shift: u8,
    pub primed: bool,
}

/// # Safety
/// `ema` must point to a valid, writable `BoxEma` (or be null: returns `sample`).
#[no_mangle]
pub unsafe extern "C" fn box_ema_update(ema: *mut BoxEma, sample: i32) -> i32 {
    match ema.as_mut() {
        Some(e) => e.update(sample),
        None => sample,
    }
}

impl BoxEma {
    pub fn update(&mut self, sample: i32) -> i32 {
        if !self.primed {
            self.value = sample;
            self.primed = true;
        } else {
            let shift = u32::from(self.shift.min(30));
            self.value += (sample - self.value) >> shift;
        }
        self.value
    }
}

/// Saturating add of two i16 (no wrap-around in sensor sums).
#[no_mangle]
pub extern "C" fn box_sat_add_i16(a: i16, b: i16) -> i16 {
    a.saturating_add(b)
}

#[cfg(not(test))]
#[panic_handler]
fn panic(_: &core::panic::PanicInfo) -> ! {
    loop {}
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn fletcher_reference_values() {
        assert_eq!(fletcher16(b"abcde"), 0xC8F0);
        assert_eq!(fletcher16(b"abcdef"), 0x2057);
    }

    #[test]
    fn ema_converges() {
        let mut e = BoxEma { value: 0, shift: 2, primed: false };
        assert_eq!(e.update(100), 100);
        for _ in 0..50 {
            e.update(200);
        }
        assert!(e.value > 195 && e.value <= 200);
    }
}
