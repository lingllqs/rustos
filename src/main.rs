#![no_std]
#![no_main]

use core::panic::PanicInfo;


mod vga_buffer;

#[unsafe(no_mangle)]
pub extern "C" fn _start() -> ! {
    use core::fmt::Write;

    vga_buffer::WRITER.lock().write_str("Hello World!\n").unwrap();
    write!(vga_buffer::WRITER.lock(), "Rust").unwrap();

    loop {}
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}
