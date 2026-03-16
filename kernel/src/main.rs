#![no_std]
#![no_main]

use core::panic::PanicInfo;

#[unsafe(no_mangle)]
extern "C" fn _start() -> ! {
    let vga = 0xb8000 as *mut u8;

    unsafe {
        *vga = b'H';
        *vga.offset(1) = 0x0f;
        *vga.offset(2) = b'i';
        *vga.offset(3) = 0x0f;
    }

    loop {}
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}
