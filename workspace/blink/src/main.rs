#![no_std]
#![no_main]

use esp_hal::{
    clock::ClockControl,
    delay::Delay,
    gpio::{Io, Level, Output},
    peripherals::Peripherals,
    prelude::*,
};
use esp_backtrace as _;
use esp_println::println;

#[entry]
fn main() -> ! {
    let peripherals = Peripherals::take();
    let system = peripherals.SYSTEM.split();
    let clocks = ClockControl::max(system.clock_control).freeze();
    let delay = Delay::new(&clocks);

    let io = Io::new(peripherals.GPIO, peripherals.IO_MUX);
    
    // Use a common GPIO pin for the integrated LED, such as GPIO8 on many ESP32-C3 boards.
    // Change this pin if your LED is connected to a different GPIO.
    let mut led = Output::new(io.pins.gpio8, Level::Low);

    println!("Blinky example started!");

    loop {
        led.toggle();
        println!("LED ON");
        delay.delay_millis(500);
        
        led.toggle();
        println!("LED OFF");
        delay.delay_millis(500);
    }
}