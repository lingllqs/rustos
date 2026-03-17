#![no_std]
#![no_main]

use core::panic::PanicInfo;

#[unsafe(no_mangle)]
pub extern "C" fn _start() -> ! {
    let vga = 0xb8000 as *mut u16;

    unsafe {
        *vga.offset(0) = 0x0f48; // 'H'
        *vga.offset(1) = 0x0f69; // 'i'
    }

    loop {}
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}
