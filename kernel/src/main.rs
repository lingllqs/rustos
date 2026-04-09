#![no_std]  // 禁用标准库
#![no_main] // 不使用默认入口点

use core::panic::PanicInfo;

#[unsafe(no_mangle)]
pub extern "C" fn _start() -> ! {
    let vga = 0xb8000 as *mut u8;

    unsafe {
        *vga = b'K';
        *vga.add(1) = 0x0f;
    }

    loop {}
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}
